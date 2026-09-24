output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnets" {
  value = module.network.public_subnet_ids
}

output "private_subnets" {
  value = module.network.private_subnet_ids
}

output "alb_dns_name" {
  value = module.edge.alb_dns_name
}

output "ecs_cluster" {
  description = "Name of the ECS cluster"
  value       = module.compute.cluster_name
}

output "payments_ecs_service" {
  description = "Name of the payments-api ECS service"
  value       = module.compute.payments_service_name
}

output "kyc_ecs_service" {
  description = "Name of the kyc-api ECS service"
  value       = module.compute.kyc_service_name

}
output "cloudtrail_name" {
  value = module.detection.cloudtrail_name
}

output "cloudtrail_bucket_name" {
  value = module.detection.cloudtrail_bucket_name
}

output "guardduty_detector_id" {
  value = module.detection.guardduty_detector_id
}

output "quarantine_security_group_id" {
  value = module.detection.quarantine_security_group_id
}

output "quarantine_lambda_name" {
  value = module.detection.quarantine_lambda_name
}
output "github_actions_role_arn" {
  description = "IAM role ARN used by GitHub Actions through OIDC"
  value       = module.github_oidc.role_arn
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = module.github_oidc.oidc_provider_arn
}

output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key"
  value       = module.kms.key_arn
}
