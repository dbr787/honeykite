data "aws_availability_zones" "availability_zones" {
  state = "available"
}

data "aws_caller_identity" "current" {}
