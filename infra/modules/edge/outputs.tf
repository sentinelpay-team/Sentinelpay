output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "listener_arn" {
  description = "ARN of the active ALB forwarding listener"

  value = var.acm_certificate_arn != null ? (
    try(aws_lb_listener.https[0].arn, null)
    ) : (
    try(aws_lb_listener.http_forward[0].arn, null)
  )
}

output "http_listener_arn" {
  description = "ARN of the HTTP ALB listener"

  value = var.acm_certificate_arn != null ? (
    try(aws_lb_listener.http[0].arn, null)
    ) : (
    try(aws_lb_listener.http_forward[0].arn, null)
  )
}

output "alb_security_group_id" {
  description = "Security group ID of the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "payments_target_group_arn" {
  description = "ARN of the payments-api ALB target group"
  value       = aws_lb_target_group.payments.arn
}

output "kyc_target_group_arn" {
  description = "ARN of the kyc-api ALB target group"
  value       = aws_lb_target_group.kyc.arn
}

output "waf_web_acl_arn" {
  description = "ARN of the AWS WAFv2 Web ACL"
  value       = aws_wafv2_web_acl.this.arn
}