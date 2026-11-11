# Alias records (not a CNAME) so the module also works on a zone apex, and so IPv6 clients get an AAAA
resource "aws_route53_record" "cloudfront_a" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain_to_certificate
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

# v1.0.0 created a CNAME here. The type change forces a replacement, which Terraform
# does destroy-first, so the CNAME is gone before the A record is created
moved {
  from = aws_route53_record.cloudfront_cname
  to   = aws_route53_record.cloudfront_a
}

resource "aws_route53_record" "cloudfront_aaaa" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain_to_certificate
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }

  # Route53 rejects an AAAA next to a CNAME: wait until the A replaced the v1.0.0 CNAME
  depends_on = [aws_route53_record.cloudfront_a]
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "s3-access-control/${var.s3_bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {

  enabled         = true
  is_ipv6_enabled = true
  price_class     = var.price_class

  origin {
    origin_id                = aws_s3_bucket.this.bucket_regional_domain_name
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  dynamic "custom_error_response" {
    for_each = var.spa_fallback ? [1] : []
    content {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.this.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = var.minimum_protocol_version
  }

  default_root_object = "index.html"

  aliases = [var.domain_to_certificate]

  default_cache_behavior {
    target_origin_id           = aws_s3_bucket.this.bucket_regional_domain_name
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = var.cache_policy_id
    response_headers_policy_id = var.response_headers_policy_id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  # The public access block must exist first, or a policy change can race it
  depends_on = [aws_s3_bucket_public_access_block.this]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["s3:GetObject"],
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Resource = [
          "${aws_s3_bucket.this.arn}/*",
        ],
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
          }
        }
      },
    ],
  })
}
