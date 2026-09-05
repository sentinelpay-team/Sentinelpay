# ============================================================
# SentinelPay ECS Outputs
# ============================================================

output "ecs_cluster_id" {
  description = "SentinelPay ECS cluster ID"
  value       = aws_ecs_cluster.sentinelpay.id
}

output "ecs_cluster_name" {
  description = "SentinelPay ECS cluster name"
  value       = aws_ecs_cluster.sentinelpay.name
}

output "ecs_task_definition_arn" {
  description = "SentinelPay ECS task definition ARN"
  value       = aws_ecs_task_definition.sentinelpay.arn
}

output "ecs_security_group_id" {
  description = "SentinelPay ECS security group ID"
  value       = aws_security_group.ecs.id
}

output "ecs_service_id" {
  description = "SentinelPay ECS service ID"
  value       = aws_ecs_service.sentinelpay.id
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.sentinelpay.name
}

output "ecs_desired_count" {
  value = aws_ecs_service.sentinelpay.desired_count
}

# ============================================================
# ECS Task Role Outputs
# ============================================================

output "ecs_task_role_arn" {
  description = "ARN of the ECS task IAM role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_role_name" {
  description = "Name of the ECS task IAM role"
  value       = aws_iam_role.ecs_task_role.name
}

# ============================================================
# ECS Task Execution Role Outputs
# ============================================================

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution IAM role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution IAM role"
  value       = aws_iam_role.ecs_task_execution_role.name
}

# ============================================================
# ECS Task Policy Outputs
# ============================================================

output "ecs_task_policy_id" {
  description = "ID of the ECS task IAM policy"
  value       = aws_iam_role_policy.ecs_task_policy.id
}

output "ecs_task_policy_name" {
  description = "Name of the ECS task IAM policy"
  value       = aws_iam_role_policy.ecs_task_policy.name
}

