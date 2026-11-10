resource "aws_s3_bucket" "this" {
  bucket = var.s3_bucket_name
}

#Upload static file for the website
resource "aws_s3_object" "app-files" {
  for_each = fileset(var.website_artifacts_path, "**/*")

  bucket       = aws_s3_bucket.this.bucket
  key          = each.value
  source       = "${var.website_artifacts_path}/${each.value}"
  etag         = filemd5("${var.website_artifacts_path}/${each.value}")
  content_type = try(lookup(local.extension_to_mime, lower(regex("\\.([^./]+)$", each.value)[0]), null), null)
}
