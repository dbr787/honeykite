#!/bin/bash

set -euo pipefail

# Set terraform variables
SECRETS_BUCKET="${secrets_bucket}"

# Set local variables
TEMP_DIR="/tmp/utils"
HOOKS_DIR="hooks"
AGENT_ENV_FILE="files/agent.env"
OTEL_CONFIG_FILE="files/otel-collector-config.yaml"

# Create the local temp directory
mkdir -p $TEMP_DIR

# Copy the utils directory from S3 to the local temp directory
aws s3 sync s3://$SECRETS_BUCKET/utils $TEMP_DIR

# Copy all files in the hooks directory to /etc/buildkite-agent/hooks/
cp -r $TEMP_DIR/$HOOKS_DIR/* /etc/buildkite-agent/hooks/

# Change owner and permissions of all hooks
chown -R buildkite-agent:buildkite-agent /etc/buildkite-agent/hooks/
chmod -R +x /etc/buildkite-agent/hooks/

# Copy the agent.env file to /var/lib/buildkite-agent/env
cp $TEMP_DIR/$AGENT_ENV_FILE /var/lib/buildkite-agent/env

# Create a new directory for otel config
mkdir /etc/buildkite-agent/otel/

# Copy the otel-collector-config.yaml file to /etc/buildkite-agent/otel
cp $TEMP_DIR/$OTEL_CONFIG_FILE /etc/buildkite-agent/otel/otel-collector-config.yaml

# Change owner of otel config file
chown -R buildkite-agent:buildkite-agent /etc/buildkite-agent/otel/
chmod -R 777 /etc/buildkite-agent/otel

# Cleanup: Remove the local temp directory
rm -rf $TEMP_DIR
