# Terraform AWS Static Frontend Module

This Terraform module deploys a static website (SPA builds from React, Angular, Vue, Vite, …) on AWS using a private S3 bucket served through CloudFront, with a custom domain and automatic SSL certificate management.

## Features

- Creates a private S3 bucket and uploads the built website files with the correct `Content-Type`.
- Serves the bucket through CloudFront using Origin Access Control (no public bucket access).
- Issues and DNS-validates an ACM certificate in `us-east-1` (required by CloudFront).
- Creates the Route53 record pointing the domain to the distribution.
- Optional SPA fallback: 403 errors return `/index.html` so client-side routing works.

## Usage

CloudFront certificates must live in `us-east-1`, so the module needs an extra provider aliased as `aws.us_east_1`:

```hcl
provider "aws" {
  region = "eu-south-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "frontend" {
  source = "github.com/karim-ramadan/terraform-aws-frontend?ref=v1.0.0"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  s3_bucket_name         = "app.frontend.example.com"
  website_artifacts_path = "${path.root}/../dist"
  domain_to_certificate  = "app.example.com"
  top_level_domain       = "example.com"
}
```

After a deploy you can invalidate the cache with the `cloudfront_distribution_id` output:

```bash
aws cloudfront create-invalidation --distribution-id "$(terraform output -raw cloudfront_distribution_id)" --paths "/*"
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `s3_bucket_name` | `string` | n/a | Name of the S3 bucket that hosts the website files. |
| `website_artifacts_path` | `string` | n/a | Local path to the built website (e.g. `dist/`) uploaded to the bucket. |
| `domain_to_certificate` | `string` | n/a | The domain name the website is served on; an SSL certificate is issued for it. |
| `top_level_domain` | `string` | n/a | The Route53 hosted zone (TLD) associated with `domain_to_certificate`. |
| `price_class` | `string` | `"PriceClass_100"` | CloudFront price class. |
| `cache_policy_id` | `string` | `"4135ea2d-6df8-44a3-9df3-4b5a84be39ad"` | Cache policy for the default behavior (managed `CachingDisabled`). |
| `minimum_protocol_version` | `string` | `"TLSv1"` | Minimum TLS version for viewers. `TLSv1.2_2021` is recommended. |
| `spa_fallback` | `bool` | `true` | Serve `/index.html` with status 200 on 403 errors. |

## Outputs

| Name | Description |
|------|-------------|
| `website_domain_name` | Domain name of the CloudFront distribution. |
| `cloudfront_distribution_id` | ID of the CloudFront distribution. |
| `cloudfront_distribution_arn` | ARN of the CloudFront distribution. |
| `s3_bucket_name` | Name of the S3 bucket hosting the website. |
| `certificate_arn` | ARN of the ACM certificate. |

## Requirements

- Terraform >= 1.0
- AWS Provider >= 5.31.0
- A public Route53 hosted zone for `top_level_domain`

## License

This module is licensed under the MIT License.
