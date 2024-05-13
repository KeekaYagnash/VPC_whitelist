provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      "automation" = "terraform",
      "owner"      = "diraptor "
    }
  }

  ignore_tags {
    keys = ["CreatorId", "CreatorName"]
  }
}