# Honeykite

[![Add to Buildkite](https://buildkite.com/button.svg)](https://buildkite.com/new)

A demo showcasing how to send OpenTelemetry trace data from the Buildkite agent to Honeycomb.io

## To Do

- Add terraform to creat Buildkite cluster, pipeline, agent token, schedule
- Reconsider using ssm vs just placing keys in files on s3
- Rename modules to core, user, elastic_ci_stack
- Check over variables and outputs, make simple and consistent
- Can OTEL_EXPORTER_OTLP_ENDPOINT just be set in agent-startup?
- Just need to get the agent-startup hook working with otel docker
- Compare doing everything in bootstrap vs using provided params in elastic ci stack
- Provide steps to run locally, and steps to run on elastic ci stack
- Need to figure out how the s3 env file works vs AgentEnvFileUrl in the elastic stack
  - Where should I set `OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"` for the agent to use it before starting?
  - Where should I set
  - https://github.com/buildkite/elastic-ci-stack-for-aws/blob/2ce822815b69618ac7718216861656b03024db4e/packer/linux/conf/bin/bk-install-elastic-stack.sh#L296-L301
  - https://github.com/buildkite/elastic-ci-stack-s3-secrets-hooks
  - Maybe use a bootstrap script to create/overwrite the agent config file...
- Update S3 Bucket param to SecretsBucket
- Create pipeline and steps in this repository
- Use a repository hook to set up OTEL collector etc.

## TLDR

1. Create a Honeycomb account
1. Create a Buildkite account
1. TBC

## Instructions

1. Login to your AWS account via CLI

```sh
aws sso login # or your equivalent login command
```

1. TBC
