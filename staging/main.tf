provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "test-d-p-terraform-state"
    key            = "staging/test/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "disraptor-market-place-terraform-state-lock"
  }
}


# # # # # # # # # # Prompt Query and Context Lambda Function
resource "aws_s3_bucket" "prompt_lambda_code_upload" {
  bucket = "test-my-code-prompt-query-and-context"
  tags = {
    Name        = "prod-ai-shop-lambda-code-for-prompt-query-and-context",
    owner       = "disraptor",
    environment = "prod",
    service     = "AI-Shop",
    type        = "application" 
  }
}

resource "aws_s3_bucket_public_access_block" "s3_prompt_bucket_access" {
  bucket                  = aws_s3_bucket.prompt_lambda_code_upload.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "prompt_bucket_versioning" {
  bucket = aws_s3_bucket.prompt_lambda_code_upload.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object" "object_upload2" {
  bucket = aws_s3_bucket.prompt_lambda_code_upload.bucket
  key    = "lambda.zip"
  source = "./lambda.zip"
}

resource "aws_s3_bucket_policy" "prompt_bucket_policy" {
  bucket = aws_s3_bucket.prompt_lambda_code_upload.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket_object.object_upload2.arn}"
      }
    ]
  })
}

data "aws_iam_policy_document" "prompt_lambda_iam_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "prompt_lambda_iam_role" {
  name               = "prompt-query-and-context-iam-role"
  assume_role_policy = data.aws_iam_policy_document.prompt_lambda_iam_policy.json

  tags = {
    Name        = "iam-role-for-prompt-query-and-context",
    owner       = "disraptor",
    environment = "prod",
    service     = "AI-Shop",
    type        = "IAM Role"
  }
}

resource "aws_iam_role_policy_attachment" "cloudWatch_prompt_query_and_context" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.prompt_lambda_iam_role.name
}

resource "aws_iam_role_policy_attachment" "bedrock" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
  role       = aws_iam_role.prompt_lambda_iam_role.name
}

resource "aws_lambda_function" "prompt_query_and_context_lambda_function" {
  s3_bucket     = aws_s3_bucket.prompt_lambda_code_upload.bucket
  s3_key        = aws_s3_bucket_object.object_upload2.key
  role          = aws_iam_role.prompt_lambda_iam_role.arn
  function_name = "lambda-function-prompt-query-and-context"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 350

  tags = {
    Name        = "prod-ai-shop-lambda-code-for-prompt-query-and-context",
    owner       = "disraptor",
    environment = "prod",
    service     = "AI-Shop",
    type        = "application"
  }
}

data "aws_iam_policy_document" "api_permissions" {
  statement {
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:*:*:*"]
  }
}

resource "aws_iam_policy" "api_policy" {
  name   = "aishop-prompt-and-query-lambda-api-invoke"
  policy = data.aws_iam_policy_document.api_permissions.json

  tags = {
    name        = "prompt-and-query-lambda-api-invoke"
    owner       = "disraptor"
    environment = "prod"
    service     = "iam-role"
    type        = "IAM-Policy"
  }
}

resource "aws_iam_role_policy_attachment" "api_attachment" {
  role       = aws_iam_role.prompt_lambda_iam_role.name
  policy_arn = aws_iam_policy.api_policy.arn
}

