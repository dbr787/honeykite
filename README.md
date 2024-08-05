# Honeykite

[![Add to Buildkite](https://buildkite.com/button.svg)](https://buildkite.com/new)

An experimental workshop/demo exploring how to send OpenTelemetry trace data from the Buildkite agent to Honeycomb.io

## Prerequisites

Before partaking in this workshop, you should have the following tools installed and configured on your workstation;

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

You will also need;

- A GitHub account
- An AWS account (with admin access)

## Instructions

1. [Fork this repository on GitHub](https://github.com/dbr787/honeykite/fork), and clone it to your workstation.

1. Rename the [`terraform/terraform.tfvars.example`](terraform/terraform.tfvars.example) file to `terraform.tfvars`.  
   Then, update the value for `project`, `random_id`, and `aws_region` in the file. _We'll update the other vars later._

   > _The [terraform/terraform.tfvars](terraform/terraform.tfvars.example) file will contain our project config, API keys, and tokens.  
   > It is included in the [.gitignore](.gitignore) file to ensure it is ignored by Git._

1. [Click here to create a Honeycomb.io account](https://ui.honeycomb.io/signup)

   1. If prompted, click the activation link sent to your email address
   1. If required, provide a password, choose a team name, and click 'Create Team'
   1. A 'test' environment will be pre-created for you. Copy the API key shown on the main page, and paste it into the `honeycomb_api_key` var in the [terraform/terraform.tfvars](terraform/terraform.tfvars) file

1. [Click here to create a Buildkite account](https://buildkite.com/signup)

   1. Choose a name for your Buildkite organization
   1. If prompted, select 'Pipelines' as the product we will try out first
   1. Skip or complete the onboarding survey
   1. When prompted to 'Create your first pipeline', don't click any further, we're going to create our first pipeline another way in the next step

1. Open your forked repository on [github.com](https://github.com), and click the `Add to Buildkite` button in the README.  
   _This will create a pipeline in your Buildkite organization with pre-filled configuration taken from the [.buildkite/template.yml](.buildkite/template.yml) file in the repository_

   1. Click 'Create Pipeline', and follow the instructions to integrate Buildkite with your GitHub repository to automatically create new builds when you push code to the repository. _You can skip this step if you don't want builds to automatically be triggered._

1. Before running a build of your new pipeline, we need some agents, for this workshop we're going to deploy some self-hosted Buildkite agents on AWS. But first, we need to create an agent token and an API key

   1. Click on 'Agents' in the Buildkite navigation header
   1. We already have a default cluster, and a default queue which we can use for this project, but! we will create a new agent token
   1. Click on 'Agent Tokens', 'New Token', call it whatever you want, and click 'Create Token'
   1. Copy the agent token and paste it into the `buildkite_agent_token` var in the [terraform/terraform.tfvars](terraform/terraform.tfvars) file
   1. Now we'll get a Buildkite API token which we use to query the [Builds API](https://buildkite.com/docs/apis/rest-api/builds) in our [pre-exit hook](./terraform/utils/hooks/pre-exit.tpl)
   1. Click on your user icon in the top-right of the navigation header, click on 'Personal Settings', then click on 'API Access Tokens'
   1. Click 'New API Access Token', give it whatever description you want, select your Buildkite organization, give it 'Read Builds' permission, and click 'Create New API Access Token'
   1. Copy the API access token and paste it into the `buildkite_api_key` var in the [terraform/terraform.tfvars](terraform/terraform.tfvars) file

1. Now we're ready to deploy some terraform!

   ```sh
   # Make sure you are logged in to AWS via the CLI

   aws sso login # or your equivalent login command
   ```

   ```sh
   # Navigate to the terraform directory, and run `terraform init`

   cd ./terraform
   terraform init
   ```

   ```sh
   # Now run `terraform plan`

   terraform plan
   ```

   ```sh
   # Now run `terraform apply`

   terraform apply
   # enter yes
   ```

   This should take ~10 minutes to deploy the AWS infrastructure and the [Elastic CI Stack](https://github.com/buildkite/elastic-ci-stack-for-aws)

1. In Honeycomb, click on 'Data Settings', 'Definitions', and change the following fields...

   - Parent span ID: `custom.parent_span_id`
   - Trace ID: `custom.trace_id`

1. You should now be able to see full build traces in Honeycomb.io

<!--

 -->

## Helpful Links

- https://docs.honeycomb.io/send-data/opentelemetry/collector/

## To Do

- bootstrap should download and run scripts, so they can be changed while stack is deployed
- move from docker to otelcol binary, store in s3 to make agent startup faster or avoid rate limiting
- output otel container logs to elastic ci stack/cloudwatch logs
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
- should i have an agent.env and job.env?
