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
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  description = "CloudFront cache policy for the default behavior (defaults to the managed CachingOptimized policy, which honours the objects' Cache-Control)"
}

variable "response_headers_policy_id" {
  type        = string
  default     = "67f7725c-6f97-4210-82d7-5512b31e9d03"
  nullable    = true
  description = "CloudFront response headers policy (defaults to the managed SecurityHeadersPolicy: HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy). null disables it"
}

variable "minimum_protocol_version" {
  type        = string
  default     = "TLSv1.2_2021"
  description = "Minimum TLS version for viewers"
}

variable "spa_fallback" {
  type        = bool
  default     = true
  description = "Serve /index.html with status 200 on 403 errors so client-side routing works"
}

variable "html_cache_control" {
  type        = string
  default     = "no-cache"
  description = "Cache-Control of .html files (revalidated on every request by default)"
}

variable "immutable_path_prefixes" {
  type        = list(string)
  default     = ["assets/"]
  description = "Path prefixes of fingerprinted build output, cached for a year (Vite emits them under assets/)"
}

variable "default_cache_control" {
  type        = string
  default     = "public, max-age=3600"
  description = "Cache-Control of every other file (favicon, images in public/, …)"
}
