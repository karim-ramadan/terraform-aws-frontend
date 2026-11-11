# Runs without AWS credentials: every call goes to a mocked provider
mock_provider "aws" {}

mock_provider "aws" {
  alias = "us_east_1"

  # Known at plan time, so the validation records' for_each can be planned
  mock_resource "aws_acm_certificate" {
    override_during = plan
    defaults = {
      arn = "arn:aws:acm:us-east-1:123456789012:certificate/0f9a6e1c-1234-4c1e-9d5a-000000000000"
      domain_validation_options = [{
        domain_name           = "app.example.com"
        resource_record_name  = "_abc.app.example.com."
        resource_record_type  = "CNAME"
        resource_record_value = "_def.acm-validations.aws."
      }]
    }
  }
}

variables {
  s3_bucket_name         = "app.frontend.example.com"
  website_artifacts_path = "./tests/fixtures/dist"
  domain_to_certificate  = "app.example.com"
  top_level_domain       = "example.com"
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_s3_object.app-files["index.html"].cache_control == "no-cache"
    error_message = "HTML must be revalidated on every request"
  }

  assert {
    condition     = aws_s3_object.app-files["assets/index-AbC123.js"].cache_control == "public, max-age=31536000, immutable"
    error_message = "Fingerprinted assets are cached for a year"
  }

  assert {
    condition     = aws_s3_object.app-files["favicon.svg"].cache_control == "public, max-age=3600"
    error_message = "Other files get the default Cache-Control"
  }

  assert {
    condition     = aws_s3_object.app-files["index.html"].content_type == "text/html"
    error_message = "Content-Type comes from the extension"
  }

  assert {
    condition     = aws_route53_record.cloudfront_a.type == "A" && aws_route53_record.cloudfront_aaaa.type == "AAAA"
    error_message = "The domain gets A and AAAA alias records"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].minimum_protocol_version == "TLSv1.2_2021"
    error_message = "Viewers need TLS 1.2 or later by default"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.this.restrict_public_buckets && aws_s3_bucket_public_access_block.this.block_public_policy
    error_message = "The bucket must never become public"
  }
}
