output "key_arn" {
  description = "ARN of the Sentinelpay customer-managed KMS key"
  value       = aws_kms_key.this.arn
}

output "key_id" {
  description = "ID of the Sentinelpay customer-managed KMS key"
  value       = aws_kms_key.this.key_id
}

output "key_alias_arn" {
  description = "ARN of the Sentinelpay KMS key alias"
  value       = aws_kms_alias.this.arn
}

output "key_alias_name" {
  description = "Name of the Sentinelpay KMS key alias"
  value       = aws_kms_alias.this.name
}