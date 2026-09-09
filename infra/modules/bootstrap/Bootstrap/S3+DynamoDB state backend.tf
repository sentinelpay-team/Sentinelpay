# configure the S3 backend for Terraform state

resource "aws_s3_bucket" "sentinelpay_bucket" {
  bucket_prefix = "sentinelpay-s3-"

  tags = {
    Name = "sentinelpay-s3-bucket"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sentinelpay_bucket_encryption" {
  bucket = aws_s3_bucket.sentinelpay_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "sentinelpay_bucket_public_access_block" {
  bucket = aws_s3_bucket.sentinelpay_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "sentinelpay_bucket_versioning" {
  bucket = aws_s3_bucket.sentinelpay_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "enforce_https" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.sentinelpay_bucket.arn,
      "${aws_s3_bucket.sentinelpay_bucket.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "enforce_https" {
  bucket = aws_s3_bucket.sentinelpay_bucket.id
  policy = data.aws_iam_policy_document.enforce_https.json
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "terraform-locks"
  }
}
