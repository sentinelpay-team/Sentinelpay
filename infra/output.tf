# ============================================================
# SentinelPay Root Outputs
# ============================================================

# ============================================================
# Network Outputs
# ============================================================

output "vpc_id" {
  description = "ID of the SentinelPay VPC"
  value       = module.networks.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the SentinelPay public subnets"
  value       = module.networks.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the SentinelPay private subnets"
  value       = module.networks.private_subnet_ids
}

output "availability_zones" {
  description = "Availability Zones used by SentinelPay"
  value       = module.networks.availability_zones
}

# ============================================================
# Application Load Balancer Outputs
# ============================================================

output "alb_security_group_id" {
  description = "Security group ID of the SentinelPay ALB"
  value       = module.edge.alb_security_group_id
}

output "alb_arn" {
  description = "ARN of the SentinelPay Application Load Balancer"
  value       = module.edge.alb_arn
}

output "alb_dns_name" {
  description = "DNS name of the SentinelPay Application Load Balancer"
  value       = module.edge.alb_dns_name
}

output "target_group_arn" {
  description = "ARN of the SentinelPay ECS target group"
  value       = module.edge.target_group_arn
}

# ============================================================
# ECS Outputs
# ============================================================

output "ecs_cluster_id" {
  description = "ID of the SentinelPay ECS cluster"
  value       = module.compute.ecs_cluster_id
}

output "ecs_cluster_name" {
  description = "Name of the SentinelPay ECS cluster"
  value       = module.compute.ecs_cluster_name
}

output "ecs_task_definition_arn" {
  description = "ARN of the SentinelPay ECS task definition"
  value       = module.compute.ecs_task_definition_arn
}

output "ecs_service_id" {
  description = "ID of the SentinelPay ECS service"
  value       = module.compute.ecs_service_id
}

output "ecs_service_name" {
  description = "Name of the SentinelPay ECS service"
  value       = module.compute.ecs_service_name
}

output "ecs_security_group_id" {
  description = "Security group ID of the ECS tasks"
  value       = module.compute.ecs_security_group_id
}

output "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  value       = module.compute.ecs_desired_count
}

# ============================================================
# IAM Outputs
# ============================================================

output "ecs_task_role_arn" {
  description = "ARN of the ECS task IAM role"
  value       = module.compute.ecs_task_role_arn
}

output "ecs_task_role_name" {
  description = "Name of the ECS task IAM role"
  value       = module.compute.ecs_task_role_name
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution IAM role"
  value       = module.compute.ecs_task_execution_role_arn
}

output "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution IAM role"
  value       = module.compute.ecs_task_execution_role_name
}

output "ecs_task_policy_id" {
  description = "ID of the ECS task IAM policy"
  value       = module.compute.ecs_task_policy_id
}

output "ecs_task_policy_name" {
  description = "Name of the ECS task IAM policy"
  value       = module.compute.ecs_task_policy_name
}