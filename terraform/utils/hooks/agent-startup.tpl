#!/bin/bash

set -euo pipefail

# Define variables
HONEYCOMB_API_KEY_SSM_PARAMETER="${honeycomb_api_key_ssm_parameter}"
HONEYCOMB_API_KEY=$(aws ssm get-parameter --name $HONEYCOMB_API_KEY_SSM_PARAMETER --with-decryption --query "Parameter.Value" --output text)
OTEL_CONFIG_FILE="/etc/buildkite-agent/otel/otel-collector-config.yaml"
OTEL_SERVICE_NAME="honeykite"
OTEL_COLLECTOR_CONTAINER_NAME="otel-collector"
# Specify a fixed value parent span id to associate all steps to a single build span
# We create this parent build span in a pre-exit hook that only runs on the last step
# PARENT_SPAN_ID=$(openssl rand -hex 8)
PARENT_SPAN_ID="ccda51a65752029d"

# Check if the OpenTelemetry Collector container is already running
if [ "$(docker ps -q -f name=$OTEL_COLLECTOR_CONTAINER_NAME)" ]; then
  echo "OpenTelemetry Collector container is already running."
else
  # Run OpenTelemetry Collector
  docker run --rm -d \
    --name $OTEL_COLLECTOR_CONTAINER_NAME \
    -p 4317:4317 \
    -p 4318:4318 \
    -p 55681:55681 \
    -e HONEYCOMB_API_KEY="$HONEYCOMB_API_KEY" \
    -e OTEL_SERVICE_NAME="$OTEL_SERVICE_NAME" \
    -e PARENT_SPAN_ID="$PARENT_SPAN_ID" \
    -v /etc/buildkite-agent/otel:/data \
    -v $OTEL_CONFIG_FILE:/etc/otelcol/config.yaml \
    otel/opentelemetry-collector-contrib:latest --config /etc/otelcol/config.yaml

  echo "OpenTelemetry Collector container started."
fi

docker ps
