# Changelog

## v1.1.0

No input or output was removed, but several defaults change what gets deployed. Review the plan when upgrading.

### Changed defaults

- `minimum_protocol_version`: `TLSv1` → `TLSv1.2_2021`. Very old clients (pre-2014 browsers) can no longer connect.
- `cache_policy_id`: `CachingDisabled` → `CachingOptimized`, together with per-file `Cache-Control` (see below). Invalidate after each deploy as before.
- Route53: the `CNAME` record is replaced by `A` and `AAAA` alias records. A `moved` block carries the state over; the CNAME is destroyed before the `A` is created, and the `AAAA` waits for the `A`, so DNS for the domain is briefly unresolved during the apply.

### Added

- `Cache-Control` on every uploaded file: `.html` → `html_cache_control` (`no-cache`), files under `immutable_path_prefixes` (`assets/`) → one year, `immutable`; everything else → `default_cache_control` (one hour). Existing objects are updated in place.
- `response_headers_policy_id`, defaulting to the managed `SecurityHeadersPolicy`.
- `aws_s3_bucket_public_access_block` on the bucket.
- Compression (gzip/brotli) on the default behavior.
- `terraform test` suite with a mocked provider.

### Requirements

- Terraform >= 1.3 (was >= 1.0).

## v1.0.0

- Initial release of the static frontend module.
