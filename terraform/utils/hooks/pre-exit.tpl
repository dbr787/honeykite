#!/bin/bash

set -euo pipefail

# Check if the step key is "last"
if [[ "$BUILDKITE_STEP_KEY" != "last" ]]; then
  echo "This pre-exit hook will only run for the step with key: 'last'. Current step key: $BUILDKITE_STEP_KEY"
  exit 0
fi

# Define variables
BUILDKITE_API_KEY_SSM_PARAMETER="${buildkite_api_key_ssm_parameter}"
BUILDKITE_API_KEY=$(aws ssm get-parameter --name $BUILDKITE_API_KEY_SSM_PARAMETER --with-decryption --query "Parameter.Value" --output text)

# Debugging: Echo the environment variables
echo "BUILDKITE_ORGANIZATION_SLUG: $BUILDKITE_ORGANIZATION_SLUG"
echo "BUILDKITE_PIPELINE_SLUG: $BUILDKITE_PIPELINE_SLUG"
echo "BUILDKITE_BUILD_NUMBER: $BUILDKITE_BUILD_NUMBER"

# Fetch build information from Buildkite API using environment variables
build_info=$(curl -s -H "Authorization: Bearer $BUILDKITE_API_KEY" \
  -X GET "https://api.buildkite.com/v2/organizations/$BUILDKITE_ORGANIZATION_SLUG/pipelines/$BUILDKITE_PIPELINE_SLUG/builds/$BUILDKITE_BUILD_NUMBER")

# Check if the curl request was successful
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to fetch build information from Buildkite API" >&2
  exit 1
fi

# Debugging: Echo the raw build information in a readable format
# echo "Build information:"
# echo $build_info | jq . 

# Extract the start time using jq
start_time=$(echo $build_info | jq -r '.started_at')

# Check if jq command was successful
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to parse build information" >&2
  exit 1
fi

# Debugging: Echo the extracted start time
echo "Extracted start time: $start_time"

# Calculate the finish time as the current time
finish_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Debugging: Echo the calculated finish time
echo "Calculated finish time: $finish_time"

# Function to convert ISO 8601 to Unix nanoseconds
iso_to_nano() {
  local datetime="$1"
  python3 - <<EOF
import datetime
import sys
dt = datetime.datetime.fromisoformat("$datetime".replace('Z', '+00:00'))
print(int(dt.timestamp() * 1e9))
EOF
}

# Convert start and finish times to Unix nanoseconds
start_time_unixnano=$(iso_to_nano "$start_time")
finish_time_unixnano=$(iso_to_nano "$finish_time")

# Debugging: Echo the Unix nanosecond times
echo "Start time in Unix nanoseconds: $start_time_unixnano"
echo "Finish time in Unix nanoseconds: $finish_time_unixnano"

# Set service name and span ID
SERVICE_NAME="honeykite"
SPAN_NAME="$BUILDKITE_ORGANIZATION_SLUG/$BUILDKITE_PIPELINE_SLUG"
# TRACE_ID=$BUILDKITE_BUILD_ID
# TRACE_ID=$(uuidgen | tr -d '-' | awk '{printf "%032s", $0}')
TRACE_ID=$(openssl rand -hex 16)
SPAN_ID="ccda51a65752029d"

# Create JSON payload
# TBC also add these attributes:
# probably not step level stuff
# { "key": "buildkite.parallel", "value": { "intValue": 0 } },
# { "key": "buildkite.version", "value": { "stringValue": "3.74.1" } },
# { "key": "service.version", "value": { "stringValue": "3.74.1" } }
# { "key": "buildkite.agent", "value": { "stringValue": "$BUILDKITE_AGENT_NAME" } },
# { "key": "buildkite.branch", "value": { "stringValue": "$BUILDKITE_BRANCH" } },
# { "key": "buildkite.build_number", "value": { "stringValue": "$BUILDKITE_BUILD_NUMBER" } },
# { "key": "buildkite.build_url", "value": { "stringValue": "$BUILDKITE_BUILD_URL" } },
# { "key": "buildkite.job_id", "value": { "stringValue": "$BUILDKITE_JOB_ID" } },
# { "key": "buildkite.job_key", "value": { "stringValue": "$BUILDKITE_STEP_KEY" } },
# { "key": "buildkite.job_label", "value": { "stringValue": "$BUILDKITE_LABEL" } },
# { "key": "buildkite.job_url", "value": { "stringValue": "$BUILDKITE_BUILD_URL#$BUILDKITE_JOB_ID" } },
# { "key": "buildkite.org", "value": { "stringValue": "$BUILDKITE_ORGANIZATION_SLUG" } },
# { "key": "buildkite.pipeline", "value": { "stringValue": "$BUILDKITE_PIPELINE_SLUG" } },
# { "key": "buildkite.queue", "value": { "stringValue": "$BUILDKITE_AGENT_META_DATA_QUEUE" } },
# { "key": "buildkite.rebuilt_from_id", "value": { "stringValue": "$BUILDKITE_REBUILT_FROM_BUILD_ID" } },
# { "key": "buildkite.retry", "value": { "intValue": "$BUILDKITE_RETRY_COUNT" } },
# { "key": "buildkite.source", "value": { "stringValue": "$BUILDKITE_SOURCE" } },
# { "key": "buildkite.triggered_from_id", "value": { "stringValue": "$BUILDKITE_TRIGGERED_FROM_BUILD_ID" } },
# { "key": "deployment.environment", "value": { "stringValue": "ci" } },
JSON_PAYLOAD=$(cat <<EOF
{
  "resourceSpans": [
    {
      "resource": {
        "attributes": [
          { "key": "buildkite.build_id", "value": { "stringValue": "$BUILDKITE_BUILD_ID" } },
          { "key": "service.name", "value": { "stringValue": "$SERVICE_NAME" } }
        ]
      },
      "scopeSpans": [
        {
          "scope": { "name": "buildkite-agent" },
          "spans": [
            {
              "traceId": "$TRACE_ID",
              "spanId": "$SPAN_ID",
              "name": "$SPAN_NAME",
              "kind": 1,
              "startTimeUnixNano": "$start_time_unixnano",
              "endTimeUnixNano": "$finish_time_unixnano",
              "attributes": [
                { "key": "analytics.event", "value": { "stringValue": "true" } }
              ]
            }
          ]
        }
      ]
    }
  ]
}
EOF
)

# Debugging: Echo the JSON payload
echo "JSON Payload: $JSON_PAYLOAD"

# Send the JSON payload to the OpenTelemetry Collector using curl
curl -X POST \
     -H "Content-Type: application/json" \
     -d "$JSON_PAYLOAD" \
     "http://localhost:4318/v1/traces"

# Check if the curl request was successful
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to send JSON payload to OpenTelemetry Collector" >&2
  exit 1
fi
