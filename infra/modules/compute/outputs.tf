# =========================================================
# ECS CLUSTER
# =========================================================

output "cluster_id" {
  description = "ID of the Sentinelpay ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the Sentinelpay ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the Sentinelpay ECS cluster"
  value       = aws_ecs_cluster.this.name
}


# =========================================================
# ECS SECURITY GROUP
# =========================================================

output "ecs_security_group_id" {
  description = "Security group ID used by Sentinelpay ECS tasks"
  value       = aws_security_group.ecs.id
}


# =========================================================
# EXECUTION ROLE
# =========================================================

output "execution_role_arn" {
  description = "ARN of the shared ECS task execution role"
  value       = aws_iam_role.execution.arn
}


# =========================================================
# PAYMENTS API
# =========================================================

output "payments_service_name" {
  description = "Name of the payments-api ECS service"
  value       = aws_ecs_service.payments.name
}

output "payments_service_id" {
  description = "ID of the payments-api ECS service"
  value       = aws_ecs_service.payments.id
}

output "payments_task_definition_arn" {
  description = "ARN of the payments-api ECS task definition"
  value       = aws_ecs_task_definition.payments.arn
}

output "payments_task_role_arn" {
  description = "ARN of the dedicated payments-api task role"
  value       = aws_iam_role.payments_task.arn
}


# =========================================================
# KYC API
# =========================================================

output "kyc_service_name" {
  description = "Name of the kyc-api ECS service"
  value       = aws_ecs_service.kyc.name
}

output "kyc_service_id" {
  description = "ID of the kyc-api ECS service"
  value       = aws_ecs_service.kyc.id
}

output "kyc_task_definition_arn" {
  description = "ARN of the kyc-api ECS task definition"
  value       = aws_ecs_task_definition.kyc.arn
}

output "kyc_task_role_arn" {
  description = "ARN of the dedicated kyc-api task role"
  value       = aws_iam_role.kyc_task.arn
}


# =========================================================
# LOGGING
# =========================================================

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group used by Sentinelpay ECS workloads"
  value       = aws_cloudwatch_log_group.this.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the ECS CloudWatch log group"
  value       = aws_cloudwatch_log_group.this.arn
}