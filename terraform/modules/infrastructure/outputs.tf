output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "secrets_bucket_name" {
  description = "The name of the secrets S3 bucket"
  value       = aws_s3_bucket.secrets_bucket.bucket
}

output "managed_policy_arn" {
  description = "The ARN of the managed policy"
  value       = aws_iam_policy.ssm_parameter_access_policy.arn
}

output "buildkite_agent_token_parameter_store_path" {
  description = "The SSM Parameter Store path for the Buildkite Agent token"
  value       = aws_ssm_parameter.buildkite_agent_token.name
}

output "honeycomb_api_key_ssm_path" {
  description = "The SSM Parameter Store path for the Honeycomb API key"
  value       = aws_ssm_parameter.honeycomb_api_key.name
}

output "bootstrap_script_url" {
  value = "s3://${aws_s3_bucket.secrets_bucket.bucket}/utils/scripts/bootstrap.sh"
}
