output "instance_arn" {
  description = "IAM Identity Center instance ARN"
  value       = local.identity_center_instance_arn
}

output "developer_permission_set_arn" {
  description = "ARN of the Developer IAM Identity Center permission set"
  value       = aws_ssoadmin_permission_set.developer.arn
}

output "administrator_permission_set_arn" {
  description = "ARN of the Administrator IAM Identity Center permission set"
  value       = aws_ssoadmin_permission_set.administrator.arn
}

output "developer_permission_set_name" {
  description = "Name of the Developer IAM Identity Center permission set"
  value       = aws_ssoadmin_permission_set.developer.name
}

output "administrator_permission_set_name" {
  description = "Name of the Administrator IAM Identity Center permission set"
  value       = aws_ssoadmin_permission_set.administrator.name
}