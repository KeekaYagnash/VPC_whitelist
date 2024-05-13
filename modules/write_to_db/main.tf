resource "aws_s3_bucket" "lambda_code_upload" {
  bucket = "code-upload-lambda-function-terra-test"
  tags = {
    Name        = "prod-ai-shop-lambda-code-for-write-vectors-to-s3",
    owner       = "disraptor",
    environment = "prod",
    service     = "AI-Shop",
    type        = "application"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.lambda_code_upload.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "object_upload" {
  bucket = aws_s3_bucket.lambda_code_upload.bucket
  key    = "writetoLambda.zip"
  source = "./writetoLambda.zip"
}

resource "aws_s3_bucket_policy" "name" {
  bucket = aws_s3_bucket.lambda_code_upload.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket_object.object_upload.arn}"
      }
    ]
  })
}

data "aws_iam_policy_document" "lambda_iam_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_iam_role" {
  name               = "role-lambda-write-vectors-to-s3-bucket"
  assume_role_policy = data.aws_iam_policy_document.lambda_iam_policy.json

  tags = {
    Name        = "iam-role-for-write-vectors-to-s3-lambda",
    owner       = "disraptor",
    environment = "prod",
    service     = "AI-Shop",
    type        = "IAM Role"
  }
}

data "aws_iam_policy_document" "sqs_doc" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:*"]
    resources = ["arn:aws:sqs:af-south-1:212546990317:Ai_Shop_Production_Success_Queue"]
  }
}

resource "aws_iam_policy" "sqs_policy" {
  name   = "ai-shop-writevectors-to-s3-sqs-policy"
  policy = data.aws_iam_policy_document.sqs_doc.json

  tags = {
    Name        = "iam-policy-for-writevectors-to-s3-sqs-policy",
    owner       = "disraptor",
    environment = "prod",
    service     = "AI-Shop",
    type        = "IAM Policy"
  }
}

resource "aws_iam_role_policy_attachment" "sqs_policy_attachment" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.sqs_policy.arn
}



resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudWatch" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

data "aws_iam_policy_document" "s3_permission" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = [var.intemediate_s3_arn]
  }
}

resource "aws_iam_policy" "s3_policy" {
  name   = "iam-write-vectors-to-s3-bucket-permission"
  policy = data.aws_iam_policy_document.s3_permission.json

  tags = {
    Name        = "iam-policy-for-s3-put-object-permission",
    owner       = "disraptor",
    environment = "prod",
    service     = "AI-Shop",
    type        = "IAM Role"
  }
}

resource "aws_iam_role_policy_attachment" "s3-per-attachment" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_lambda_function" "lambda_function" {
  s3_bucket     = aws_s3_bucket.lambda_code_upload.bucket
  s3_key        = aws_s3_bucket_object.object_upload.key
  role          = aws_iam_role.lambda_iam_role.arn
  function_name = "lambda-function-write-vectors-to-s3"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = "350"

  tags = {
    Name        = "prod-ai-shop-lambda-code-for-write-vectors-to-s3",
    owner       = "disraptor",
    environment = "prod",
    service     = "AI-Shop",
    type        = "application"
  }
}
