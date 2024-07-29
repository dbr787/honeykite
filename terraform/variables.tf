variable "project" {
  description = "An identifier for this project. Used for prefixing resource names and tagging resources."
  type        = string
  default     = "honeykite"
  validation {
    condition     = length(var.project) <= 12 && can(regex("^[a-zA-Z0-9-_]+$", var.project))
    error_message = "The project variable must be 12 characters or less and can only contain letters, numbers, hyphens, and underscores."
  }
}

variable "random_id" {
  description = "A random set of chars to ensure resources are globally unique."
  type        = string
  validation {
    condition     = length(var.random_id) <= 6 && can(regex("^[a-zA-Z0-9-_]+$", var.random_id))
    error_message = "The random_id variable must be 6 characters or less and can only contain letters, numbers, hyphens, and underscores."
  }
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "buildkite_agent_token" {
  description = "The Buildkite agent token"
  type        = string
  sensitive   = true
}

variable "buildkite_api_key" {
  description = "The Buildkite API key"
  type        = string
  sensitive   = true
}

variable "honeycomb_api_key" {
  description = "The Honeycomb API key"
  type        = string
  sensitive   = true
}
