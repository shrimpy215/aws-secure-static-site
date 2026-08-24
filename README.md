# Project 1 — Secure Static Portfolio Website

## Architecture Overview

S3 (private) → CloudFront (OAC) → HTTPS → Browser

This project deploys a secure static website on AWS using Terraform. The S3 bucket is fully private — no public access is permitted. CloudFront serves as the only entry point, authenticated via Origin Access Control (OAC) using SigV4 signing.

## Architecture Diagram


Internet → CloudFront (HTTPS) → Origin Access Control → S3 Bucket (Private)

## Security Design Decisions

| Control | Implementation | Rationale |
|---|---|---|
| S3 Public Access Block | All four block settings enabled | Prevents accidental exposure of bucket contents |
| Origin Access Control (OAC) | SigV4 signing, always | Ensures only this specific CloudFront distribution can read from S3 |
| HTTPS Enforcement | redirect-to-https | Eliminates plaintext HTTP traffic, prevents protocol downgrade |
| HSTS | max-age=31536000, includeSubDomains | Instructs browsers to never connect over HTTP for 1 year |
| X-Frame-Options | DENY | Prevents clickjacking by blocking iframe embedding |
| Content-Security-Policy | default-src 'self' | Restricts resource loading to same origin, mitigates XSS |
| X-Content-Type-Options | nosniff | Prevents MIME type sniffing attacks |
| Referrer-Policy | strict-origin-when-cross-origin | Controls referrer data sent to third parties |
| S3 Encryption | AES-256 (SSE-S3) | Encrypts all objects at rest |
| S3 Versioning | Enabled | Supports recovery from accidental deletion or corruption |

## Threat Model

| Threat | Mitigation |
|---|---|
| Direct S3 bucket access | Public access block + OAC bucket policy scoped to this distribution only |
| HTTP interception (MITM) | HTTPS enforcement + HSTS header |
| Clickjacking | X-Frame-Options: DENY |
| Cross-site scripting (XSS) | Content-Security-Policy: default-src 'self' |
| MIME confusion attacks | X-Content-Type-Options: nosniff |
| Data exposure at rest | AES-256 server-side encryption |

## Infrastructure as Code

All resources deployed with Terraform. State managed locally.

**Resources deployed:**
- `aws_s3_bucket` — static site storage
- `aws_s3_bucket_versioning` — version control for objects
- `aws_s3_bucket_server_side_encryption_configuration` — AES-256 encryption
- `aws_s3_bucket_public_access_block` — blocks all public access
- `aws_cloudfront_origin_access_control` — SigV4 OAC
- `aws_cloudfront_distribution` — CDN with HTTPS enforcement
- `aws_cloudfront_response_headers_policy` — security headers
- `aws_s3_bucket_policy` — restricts access to CloudFront only

## Deployment

```bash
cd terraform
terraform init
terraform apply
```

## Cost Estimate

Approximately $0.00/month under AWS Free Tier for low-traffic portfolio use.
- S3: First 5GB storage free
- CloudFront: First 1TB transfer and 10M requests free per month

## Security Scan Results

Tested with [securityheaders.com](https://securityheaders.com) — Grade A