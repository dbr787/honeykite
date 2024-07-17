resource "aws_vpc" "main" {
  cidr_block = "10.69.0.0/16"
  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.69.1.0/24"
  availability_zone       = data.aws_availability_zones.availability_zones.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-subnet-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.69.2.0/24"
  availability_zone       = data.aws_availability_zones.availability_zones.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-subnet-public-b"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_s3_bucket" "secrets_bucket" {
  bucket = "${var.project}-secrets-bucket-${var.random_id}"
  tags = {
    Name = "${var.project}-secrets-bucket-${var.random_id}"
  }
}

resource "aws_s3_bucket_versioning" "secrets_bucket_versioning" {
  bucket = aws_s3_bucket.secrets_bucket.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secrets_bucket_encryption" {
  bucket = aws_s3_bucket.secrets_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "secrets_bucket_public_access" {
  bucket                  = aws_s3_bucket.secrets_bucket.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "secrets_bucket_policy" {
  bucket = aws_s3_bucket.secrets_bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyPublicReadWrite"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.secrets_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ssm_parameter_access_policy" {
  name        = "${var.project}-ssm-parameter-access-policy"
  description = "Policy to allow access to SSM parameters starting with ${var.project}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath"
        ],
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project}*"
      }
    ]
  })
}

# Create SSM Parameter for Buildkite Agent Token
resource "aws_ssm_parameter" "buildkite_agent_token" {
  name        = "/${var.project}/buildkite-agent-token"
  description = "Buildkite Agent Token for ${var.project}"
  type        = "SecureString"
  value       = var.buildkite_agent_token
  tags = {
    Name = "/${var.project}/buildkite-agent-token"
  }
}

# Create SSM Parameter for Honeycomb API Key
resource "aws_ssm_parameter" "honeycomb_api_key" {
  name        = "/${var.project}/honeycomb-api-key"
  description = "Honeycomb API Key for ${var.project}"
  type        = "SecureString"
  value       = var.honeycomb_api_key
  tags = {
    Name = "/${var.project}/honeycomb-api-key"
  }
}

# resource "aws_s3_object" "utils" {
#   for_each               = fileset("${path.root}/utils", "**")
#   bucket                 = aws_s3_bucket.secrets_bucket.bucket
#   key                    = "utils/${each.value}"
#   source                 = "${path.root}/utils/${each.value}"
#   etag                   = filemd5("${path.root}/utils/${each.value}")
#   acl                    = "private"
#   server_side_encryption = "aws:kms"
# }

resource "aws_s3_object" "agent_env_file" {
  bucket                 = aws_s3_bucket.secrets_bucket.bucket
  key                    = "utils/files/agent.env"
  source                 = "${path.root}/utils/files/agent.env"
  acl                    = "private"
  server_side_encryption = "aws:kms"
}

resource "aws_s3_object" "otel_collector_config_file" {
  bucket                 = aws_s3_bucket.secrets_bucket.bucket
  key                    = "utils/files/otel-collector-config.yaml"
  source                 = "${path.root}/utils/files/otel-collector-config.yaml"
  acl                    = "private"
  server_side_encryption = "aws:kms"
}

resource "aws_s3_object" "agent_startup_hook" {
  bucket = aws_s3_bucket.secrets_bucket.bucket
  key    = "utils/hooks/agent-startup"
  content = templatefile("${path.root}/utils/hooks/agent-startup.tpl", {
    honeycomb_api_key_ssm_parameter = aws_ssm_parameter.honeycomb_api_key.name
  })
  acl                    = "private"
  server_side_encryption = "aws:kms"
}

resource "aws_s3_object" "bootstrap_script" {
  bucket = aws_s3_bucket.secrets_bucket.bucket
  key    = "utils/scripts/bootstrap.sh"
  content = templatefile("${path.root}/utils/scripts/bootstrap.sh.tpl", {
    secrets_bucket = aws_s3_bucket.secrets_bucket.bucket
  })
  acl                    = "private"
  server_side_encryption = "aws:kms"
}
