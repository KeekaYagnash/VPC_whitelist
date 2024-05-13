terraform {
  # Require any 1.0.x version of Terraform
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.70.0"
    }
  }

  # Partial configuration, intentionally left empty. The other settings (e.g., bucket, region) will be
  # passed in from the terragrunt.hcl file via -backend-config arguments to 'terraform init'
  # backend "s3" {
  #   bucket         = var.backend_bucket
  #   key            = "${var.terraform_state_key}/api-gateway/terraform.tfstate"
  #   region         = var.region
  #   dynamodb_table = var.dynamodb_lock_table
  # }
}
