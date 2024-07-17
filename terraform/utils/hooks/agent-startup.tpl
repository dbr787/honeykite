#!/bin/bash

# set -euo pipefail # don't print executed commands to the terminal
set -euxo pipefail # print executed commands to the terminal

# Define variables
HONEYCOMB_API_KEY_SSM_PARAMETER="${honeycomb_api_key_ssm_parameter}"
HONEYCOMB_API_KEY=$(aws ssm get-parameter --name $HONEYCOMB_API_KEY_SSM_PARAMETER --with-decryption --query "Parameter.Value" --output text)
OTEL_CONFIG_FILE="/etc/buildkite-agent/otel/otel-collector-config.yaml"
OTEL_SERVICE_NAME="honeykite"

# Run OpenTelemetry Collector
docker run --rm -d \
  -p 4317:4317 \
  -p 55681:55681 \
  -e HONEYCOMB_API_KEY="$HONEYCOMB_API_KEY" \
  -e OTEL_SERVICE_NAME="$OTEL_SERVICE_NAME" \
  -v $OTEL_CONFIG_FILE:/etc/otelcol/config.yaml \
  otel/opentelemetry-collector-contrib:latest --config /etc/otelcol/config.yaml

# Run the Buildkite agent in a separate terminal
# export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
# buildkite-agent start --tracing-backend opentelemetry

# Stop the Buildkite agent
# kill -s SIGTERM $(pgrep buildkite-agent)
