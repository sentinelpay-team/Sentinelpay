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
  value = module.compute.ecs_cluster_name
}

output "ecs_service" {
  value = module.compute.ecs_service_name
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