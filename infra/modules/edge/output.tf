output "alb_security_group_id" {
  description = "Security group ID of the SentinelPay ALB"
  value       = aws_security_group.alb.id
}

output "alb_arn" {
  description = "ARN of the SentinelPay ALB"
  value       = aws_lb.sentinelpay.arn
}

output "alb_dns_name" {
  description = "DNS name of the SentinelPay ALB"
  value       = aws_lb.sentinelpay.dns_name
}

output "target_group_arn" {
  description = "ARN of the SentinelPay ECS target group"
  value       = aws_lb_target_group.sentinelpay.arn
}