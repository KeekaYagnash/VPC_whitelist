
provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "test-d-p-terraform-state"
    key            = "production/test/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "disraptor-market-place-terraform-state-lock"
  }
}

resource "aws_s3_bucket" "cb_bucket" {
  bucket = "test-terraform-codebuild-drpt-bucket"
}

resource "aws_s3_bucket_acl" "s3_acl" {
  bucket = aws_s3_bucket.cb_bucket.id
  acl    = "private"
} 

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild-test-acloud-dp-terraform"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["codecommit:*"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = ["ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
    "ec2:DescribeVpcs"]
    resources = ["*"]
  }
  statement {
    effect  = "Allow"
    actions = ["ec2:CreateNetworkInterfacePermission"]
    # check up service
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:subnet"
      values = [data.aws_subnet.example1.arn,
      data.aws_subnet.example2.arn, ]
    }
    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorisedService"
      values   = ["codebuild.amazonaws.com"]
    }
  }
  statement {
    effect    = "Allow"
    actions   = ["S3:*"]
    resources = [aws_s3_bucket.cb_bucket.arn, "${aws_s3_bucket.cb_bucket.arn}/*"]
  }
}

resource "aws_iam_policy" "policy_create" {
  name   = "terraform-policy-ec2-logs-s3"
  policy = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.policy_create.arn
}

resource "aws_codebuild_project" "test" {
  name          = "test-project"
  build_timeout = 5
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }
  cache {
    type     = "S3"
    location = aws_s3_bucket.cb_bucket.bucket
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    # environment_variable {
    #   name = "SORT_KEY1"
    #   value = "SOME_VALUE1"
    # }
  }
  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.cb_bucket.id}/build-log"
    } 
  }
  source {
    type            = "CODECOMMIT"
    location        = "https://git-codecommit.us-east-1.amazonaws.com/v1/repos/testrepo"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }
  source_version = "main"
  vpc_config {
    vpc_id = "vpc-0ae628de635dc00e7"

    subnets            = [data.aws_subnet.example1.id, data.aws_subnet.example2.id]
    security_group_ids = [data.aws_security_group.example1.id, data.aws_security_group.example2.id]
  }
}

data "aws_subnet" "example1" {
  id = "subnet-0a271e652dc0d8a92"
}

data "aws_subnet" "example2" {
  id = "subnet-0763e683ea3794f09"
}

data "aws_security_group" "example1" {
  id = "sg-049ab64e15ea9006a"
}

data "aws_security_group" "example2" {
  id = "sg-0c5541eef31e4d1e6"
}
