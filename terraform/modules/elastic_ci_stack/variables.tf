variable "project" {
  description = "An identifier for this project. Used for prefixing resource names and tagging resources."
  type        = string
  default     = "honeykite"
  validation {
    condition     = length(var.project) <= 12 && can(regex("^[a-zA-Z0-9-_]+$", var.project))
    error_message = "The project variable must be 12 characters or less and can only contain letters, numbers, hyphens, and underscores."
  }
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnets" {
  description = "The comma-delimited list of public subnet IDs"
  type        = string
}

variable "secrets_bucket" {
  description = "The name of the secrets S3 bucket"
  type        = string
}

variable "managed_policy_arn" {
  description = "The ARN of the managed policy"
  type        = string
}

variable "buildkite_agent_token_parameter_store_path" {
  description = "The SSM Parameter Store path for the Buildkite Agent token"
  type        = string
}

variable "bootstrap_script_url" {
  description = "The URL of the bootstrap script"
  type        = string
}
