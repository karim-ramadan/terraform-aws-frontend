# Terraform AWS Static Frontend Module

This Terraform module deploys a static website (SPA builds from React, Angular, Vue, Vite, …) on AWS using a private S3 bucket served through CloudFront, with a custom domain and automatic SSL certificate management.

## Features

- Creates a private S3 bucket (public access blocked) and uploads the built website files with the correct `Content-Type` and `Cache-Control`.
- Serves the bucket through CloudFront using Origin Access Control, with compression, TLS 1.2+ and security headers.
- Caching that is safe for SPAs: `.html` is revalidated on every request, fingerprinted `assets/` are cached for a year, everything else for an hour.
- Issues and DNS-validates an ACM certificate in `us-east-1` (required by CloudFront).
- Creates Route53 `A` and `AAAA` alias records pointing the domain to the distribution (works on a zone apex too).
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
  source = "github.com/karim-ramadan/terraform-aws-frontend?ref=v1.1.0"

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

HTML is revalidated, but edge locations may still hold other unfingerprinted files for up to `default_cache_control`. Invalidate after each deploy with the `cloudfront_distribution_id` output:

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
| `cache_policy_id` | `string` | `"658327ea-f89d-4fab-a63d-7e88639e58f6"` | Cache policy for the default behavior (managed `CachingOptimized`, honours `Cache-Control`). |
| `response_headers_policy_id` | `string` | `"67f7725c-6f97-4210-82d7-5512b31e9d03"` | Response headers policy (managed `SecurityHeadersPolicy`); `null` disables it. |
| `minimum_protocol_version` | `string` | `"TLSv1.2_2021"` | Minimum TLS version for viewers. |
| `spa_fallback` | `bool` | `true` | Serve `/index.html` with status 200 on 403 errors. |
| `html_cache_control` | `string` | `"no-cache"` | `Cache-Control` of `.html` files. |
| `immutable_path_prefixes` | `list(string)` | `["assets/"]` | Prefixes of fingerprinted files, cached for a year. |
| `default_cache_control` | `string` | `"public, max-age=3600"` | `Cache-Control` of every other file. |

## Outputs

| Name | Description |
|------|-------------|
| `website_domain_name` | Domain name of the CloudFront distribution. |
| `cloudfront_distribution_id` | ID of the CloudFront distribution. |
| `cloudfront_distribution_arn` | ARN of the CloudFront distribution. |
| `s3_bucket_name` | Name of the S3 bucket hosting the website. |
| `certificate_arn` | ARN of the ACM certificate. |

## Requirements

- Terraform >= 1.3 (>= 1.9 to run the tests)
- AWS Provider >= 5.31.0
- A public Route53 hosted zone for `top_level_domain`

## Development

```bash
./scripts/validate.sh   # fmt, validate through examples/ and terraform test with a mocked provider
```

See [CHANGELOG.md](CHANGELOG.md) for what changes when upgrading.

## License

This module is licensed under the MIT License.
