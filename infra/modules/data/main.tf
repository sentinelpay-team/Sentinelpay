resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# --------------------------------------------------
# Account-wide S3 Public Access Block
# --------------------------------------------------

resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------------------------
# Dedicated server-access-log bucket
# --------------------------------------------------

resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.project_name}-${var.environment}-s3-access-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-${var.environment}-s3-access-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --------------------------------------------------
# KYC bucket
# --------------------------------------------------

resource "aws_s3_bucket" "kyc" {
  bucket = "${var.project_name}-${var.environment}-kyc-${random_id.bucket_suffix.hex}"

  object_lock_enabled = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-kyc"
    Environment = var.environment
    DataClass   = "KYC"
  }
}

resource "aws_s3_bucket_versioning" "kyc" {
  bucket = aws_s3_bucket.kyc.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kyc" {
  bucket = aws_s3_bucket.kyc.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "kyc" {
  bucket = aws_s3_bucket.kyc.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object_lock_configuration" "kyc" {
  bucket = aws_s3_bucket.kyc.id

  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = var.kyc_retention_days
    }
  }
}

resource "aws_s3_bucket_logging" "kyc" {
  bucket = aws_s3_bucket.kyc.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "kyc/"
}

# --------------------------------------------------
# ElastiCache security group
# --------------------------------------------------

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Redis access from application only"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "app_to_redis" {
  security_group_id = aws_security_group.redis.id

  referenced_security_group_id = var.application_security_group_id

  from_port   = 6379
  to_port     = 6379
  ip_protocol = "tcp"
}

# --------------------------------------------------
# Redis AUTH secret
# --------------------------------------------------

resource "random_password" "redis_auth" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "redis" {
  name       = "${var.project_name}/${var.environment}/redis/auth"
  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id     = aws_secretsmanager_secret.redis.id
  secret_string = random_password.redis_auth.result
}

# --------------------------------------------------
# Redis subnet group
# --------------------------------------------------

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-redis-subnets"
  subnet_ids = var.private_subnet_ids
}

# --------------------------------------------------
# Redis
# --------------------------------------------------

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.project_name}-${var.environment}-redis"

  description = "${var.project_name} ${var.environment} Redis"

  engine = "redis"

  node_type = var.redis_node_type

  num_cache_clusters = 2

  port = 6379

  subnet_group_name = aws_elasticache_subnet_group.this.name

  security_group_ids = [
    aws_security_group.redis.id
  ]

  at_rest_encryption_enabled = true

  transit_encryption_enabled = true

  kms_key_id = var.kms_key_arn

  auth_token = random_password.redis_auth.result

  auth_token_update_strategy = "SET"

  automatic_failover_enabled = true
}