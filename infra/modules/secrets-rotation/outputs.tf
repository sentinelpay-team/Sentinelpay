output "secret_arn" {
  description = "ARN of the Secrets Manager database secret"
  value       = aws_secretsmanager_secret.database.arn
  sensitive   = true
}

output "secret_id" {
  description = "ID of the Secrets Manager database secret"
  value       = aws_secretsmanager_secret.database.id
  sensitive   = true
}

output "rotation_lambda_arn" {
  description = "ARN of the PostgreSQL Secrets Manager rotation Lambda"
  value       = aws_lambda_function.rotation.arn
}

output "rotation_lambda_name" {
  description = "Name of the PostgreSQL Secrets Manager rotation Lambda"
  value       = aws_lambda_function.rotation.function_name
}

output "rotation_security_group_id" {
  description = "Security group ID attached to the rotation Lambda"
  value       = aws_security_group.rotation.id
}

output "rotation_dlq_arn" {
  description = "ARN of the rotation Lambda dead-letter queue"
  value       = aws_sqs_queue.rotation_dlq.arn
}

output "rotation_dlq_url" {
  description = "URL of the rotation Lambda dead-letter queue"
  value       = aws_sqs_queue.rotation_dlq.url
}