output "endpoint" {
  description = "DNS address of the PostgreSQL RDS instance"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port used by the PostgreSQL RDS instance"
  value       = aws_db_instance.this.port
}

output "security_group_id" {
  description = "Security group ID attached to the PostgreSQL RDS instance"
  value       = aws_security_group.this.id
}

output "db_instance_id" {
  description = "Identifier of the PostgreSQL RDS instance"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "ARN of the PostgreSQL RDS instance"
  value       = aws_db_instance.this.arn
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed master user secret"
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
  sensitive   = true
}

output "db_name" {
  description = "Name of the PostgreSQL database"
  value       = aws_db_instance.this.db_name
}
output "address" {
  description = "PostgreSQL RDS endpoint address"
  value       = aws_db_instance.this.address
}

output "identifier" {
  description = "PostgreSQL RDS instance identifier"
  value       = aws_db_instance.this.identifier
}

