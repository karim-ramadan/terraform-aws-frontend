resource "aws_s3_bucket" "this" {
  bucket = var.s3_bucket_name
}

# Only CloudFront reads the bucket (through OAC); nothing may make it public
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  website_files = fileset(var.website_artifacts_path, "**/*")

  # HTML must be revalidated so a deploy is picked up at once; fingerprinted
  # build output never changes under the same name and can be cached forever
  cache_control = {
    for f in local.website_files : f => (
      endswith(lower(f), ".html") ? var.html_cache_control :
      anytrue([for p in var.immutable_path_prefixes : startswith(f, p)]) ? "public, max-age=31536000, immutable" :
      var.default_cache_control
    )
  }
}

#Upload static file for the website
resource "aws_s3_object" "app-files" {
  for_each = local.website_files

  bucket        = aws_s3_bucket.this.bucket
  key           = each.value
  source        = "${var.website_artifacts_path}/${each.value}"
  etag          = filemd5("${var.website_artifacts_path}/${each.value}")
  content_type  = try(lookup(local.extension_to_mime, lower(regex("\\.([^./]+)$", each.value)[0]), null), null)
  cache_control = local.cache_control[each.value]
}
