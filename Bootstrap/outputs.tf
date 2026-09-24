output "terraform_state_bucket" {
  description = "Name of the Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "terraform_state_logs_bucket" {
  description = "Name of the Terraform state access logs S3 bucket"
  value       = aws_s3_bucket.terraform_state_logs.bucket
}

output "terraform_state_logs_bucket_arn" {
  description = "ARN of the Terraform state access logs S3 bucket"
  value       = aws_s3_bucket.terraform_state_logs.arn
}

output "terraform_lock_table" {
  description = "Name of the Terraform state locking DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "terraform_locks_table_arn" {
  description = "ARN of the Terraform state locking DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "terraform_state_kms_key_id" {
  description = "ID of the KMS key protecting Terraform backend resources"
  value       = aws_kms_key.terraform_state.key_id
}

output "terraform_state_kms_key_arn" {
  description = "ARN of the KMS key protecting Terraform backend resources"
  value       = aws_kms_key.terraform_state.arn
}

output "terraform_state_kms_alias" {
  description = "Alias of the KMS key protecting Terraform backend resources"
  value       = aws_kms_alias.terraform_state.name
}