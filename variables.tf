variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket that hosts the website files"
}

variable "website_artifacts_path" {
  type        = string
  description = "Local path to the built website (e.g. dist/) uploaded to the bucket"
}

variable "domain_to_certificate" {
  type        = string
  description = "The domain name the website is served on; an SSL certificate is issued for it"
}

variable "top_level_domain" {
  type        = string
  description = "The Route53 hosted zone (TLD) associated with domain_to_certificate"
}

variable "price_class" {
  type        = string
  default     = "PriceClass_100"
  description = "CloudFront price class"
}

variable "cache_policy_id" {
  type        = string
  default     = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  description = "CloudFront cache policy for the default behavior (defaults to the managed CachingDisabled policy)"
}

variable "minimum_protocol_version" {
  type        = string
  default     = "TLSv1"
  description = "Minimum TLS version for viewers (TLSv1.2_2021 is recommended)"
}

variable "spa_fallback" {
  type        = bool
  default     = true
  description = "Serve /index.html with status 200 on 403 errors so client-side routing works"
}
