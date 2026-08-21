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

resource "aws_cloudfront_origin_access_control" "portfolio_site" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for portfolio static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "portfolio_site" {
  origin {
    domain_name              = aws_s3_bucket.portfolio_site.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.portfolio_site.id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Project     = var.project_name
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

data "aws_iam_policy_document" "cloudfront_oac_access" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.portfolio_site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.portfolio_site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "portfolio_site" {
  bucket = aws_s3_bucket.portfolio_site.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access.json
}