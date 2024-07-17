resource "aws_cloudformation_stack" "elastic_ci_stack" {
  name         = "${var.project}-stack"
  template_url = "https://s3.amazonaws.com/buildkite-aws-stack/latest/aws-stack.yml"
  capabilities = [
    "CAPABILITY_IAM",
    "CAPABILITY_NAMED_IAM",
    "CAPABILITY_AUTO_EXPAND"
  ]
  parameters = {
    VpcId                                 = var.vpc_id
    Subnets                               = var.subnets
    SecretsBucket                         = var.secrets_bucket
    ManagedPolicyARNs                     = var.managed_policy_arn
    BuildkiteAgentTokenParameterStorePath = var.buildkite_agent_token_parameter_store_path
    BootstrapScriptUrl                    = var.bootstrap_script_url
    BuildkiteQueue                        = "default"
    BuildkiteAgentTracingBackend          = "opentelemetry"
    MinSize                               = "1"
    MaxSize                               = "5"
    RootVolumeSize                        = "50"
    ScaleInIdlePeriod                     = "600"
    AssociatePublicIpAddress              = "true"
  }
}
