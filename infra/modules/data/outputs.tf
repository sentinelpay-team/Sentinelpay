output "kyc_bucket_name" {
  value = aws_s3_bucket.kyc.bucket
}

output "redis_endpoint" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "redis_secret_arn" {
  value = aws_secretsmanager_secret.redis.arn
}

output "redis_security_group_id" {
  value = aws_security_group.redis.id
}