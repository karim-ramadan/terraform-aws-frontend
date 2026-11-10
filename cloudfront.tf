resource "aws_route53_record" "cloudfront_cname" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain_to_certificate
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.this.domain_name]
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
    target_origin_id       = aws_s3_bucket.this.bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = var.cache_policy_id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

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
