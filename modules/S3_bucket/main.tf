resource "aws_s3_bucket" "s3_bucket" {
  bucket = "test-my-s3-terraform-bucket-for-disraptor"

  tags = {
    Name        = "prod-bucket",
    owner       = "disraptor",
    environment = "prod",
    service     = "AI-Shop",
    type        = "S3 Bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.bucket_ownership]

  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "private"
}
