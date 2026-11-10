provider "aws" {
  region = "eu-south-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "frontend" {
  source = "../.."

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  s3_bucket_name         = "app.frontend.example.com"
  website_artifacts_path = "${path.root}/dist"
  domain_to_certificate  = "app.example.com"
  top_level_domain       = "example.com"
}

output "website_domain_name" {
  value = module.frontend.website_domain_name
}
