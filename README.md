# Honeykite

[![Add to Buildkite](https://buildkite.com/button.svg)](https://buildkite.com/new)

A demo showcasing how to send OpenTelemetry trace data from the Buildkite agent to Honeycomb.io

## Helpful Links

- https://docs.honeycomb.io/send-data/opentelemetry/collector/

## To Do

- bootstrap should download and run scripts, so they can be changed while stack is deployed
- move from docker to otelcol binary, store in s3
- output otel container logs in elastic ci stack
- shouldnt need to process and set service name in otel config, agent sets it
- use eventbridge build.started build.finished events to do stuff instead?
- things are working! just need to change dataset in honeycomb to use custom.parent_span_id and custom.trace_id (build.id)
- can probably remove custom trace id, and just use build.id for that...
- maybe we can update a spans id?
  https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/pkg/ottl#update-a-spans-id
- need to add more build attributes into the manual parent span, and figure out how to get the finish time to be correct
- put service name on agent flag
- seems to be not showing in honeycomb after adding ${PARENT_SPAN_ID} and using new custom fields in honeycomb
- If a build (parent) trace doesn't exist, create it? Use metadata?
- Use BUILDKITE_BUILD_ID as a parent trace id
- Run the otel-collector as a pre-bootstrap agent hook, provide build_id to the otel config to use as a parent span
- Transition to using buildevents instead of OTEL?
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

## Process

- Assume 3 agents on 3 different machines
- The parent_span_id can be static, and we can upload a parent span that describes the build at the end of the build.
- The parent_span_id should represent the build span, which should have no parent.

## Temp Inst

- should i have an agent.env and job.env?
- start otel
