module "infrastructure" {
  source                = "./modules/infrastructure"
  project               = var.project
  random_id             = var.random_id
  aws_region            = var.aws_region
  buildkite_agent_token = var.buildkite_agent_token
  buildkite_api_key     = var.buildkite_api_key
  honeycomb_api_key     = var.honeycomb_api_key
}

module "elastic_ci_stack" {
  source                                     = "./modules/elastic_ci_stack"
  project                                    = var.project
  vpc_id                                     = module.infrastructure.vpc_id
  subnets                                    = join(",", module.infrastructure.public_subnet_ids)
  secrets_bucket                             = module.infrastructure.secrets_bucket_name
  managed_policy_arn                         = module.infrastructure.managed_policy_arn
  buildkite_agent_token_parameter_store_path = module.infrastructure.buildkite_agent_token_parameter_store_path
  bootstrap_script_url                       = module.infrastructure.bootstrap_script_url
}
