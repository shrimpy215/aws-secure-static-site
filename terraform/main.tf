terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "portfolio_site" {
  bucket = "${var.project_name}-static-site-${data.aws_caller_identity.current.account_id}"

  tags = {
    Project     = var.project_name
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_versioning" "portfolio_site" {
  bucket = aws_s3_bucket.portfolio_site.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "portfolio_site" {
  bucket = aws_s3_bucket.portfolio_site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "portfolio_site" {
  bucket = aws_s3_bucket.portfolio_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}