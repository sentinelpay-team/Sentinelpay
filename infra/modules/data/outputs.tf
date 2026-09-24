output "kyc_bucket_name" {
  description = "Name of the S3 bucket containing KYC data"
  value       = aws_s3_bucket.kyc.bucket
}

output "kyc_bucket_arn" {
  description = "ARN of the S3 bucket containing KYC data"
  value       = aws_s3_bucket.kyc.arn
}

output "access_logs_bucket_name" {
  description = "Name of the S3 bucket used for ALB and KYC access logs"
  value       = aws_s3_bucket.access_logs.bucket
}

output "access_logs_bucket_arn" {
  description = "ARN of the S3 bucket used for ALB and KYC access logs"
  value       = aws_s3_bucket.access_logs.arn
}

output "redis_endpoint" {
  description = "Primary endpoint of the Redis replication group"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "redis_port" {
  description = "Port used by the Redis replication group"
  value       = aws_elasticache_replication_group.this.port
}

output "redis_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Redis authentication token"
  value       = aws_secretsmanager_secret.redis.arn
}

output "redis_security_group_id" {
  description = "Security group ID attached to the Redis replication group"
  value       = aws_security_group.redis.id
}

output "redis_replication_group_id" {
  description = "ID of the Redis replication group"
  value       = aws_elasticache_replication_group.this.replication_group_id
}