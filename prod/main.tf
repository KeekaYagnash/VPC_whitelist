
provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "test-d-p-terraform-state"
    key            = "test/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "disraptor-market-place-terraform-state-lock"
  }
}

module "s3_bucket_intermediate" {
  source = "../modules/S3_bucket"
}

module "static_website" {
  source = "../modules/S3_static"
}

module "write_to_db" {
  source             = "../modules/write_to_db"
  intemediate_s3_arn = module.s3_bucket_intermediate.s3_intermediate
}
