output "website_domain_name" {
  description = "Url of the website just deployed"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution (useful for cache invalidations)"
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the website"
  value       = aws_s3_bucket.this.bucket
}

output "certificate_arn" {
  description = "ARN of the ACM certificate (us-east-1)"
  value       = aws_acm_certificate.this.arn
}
