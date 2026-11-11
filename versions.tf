terraform {
  required_version = ">= 1.3" # moved blocks, startswith/endswith

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.31.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}
