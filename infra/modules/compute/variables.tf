variable "vpc_id" {
  description = "ID of the SentinelPay VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where ECS tasks will run"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the SentinelPay ALB"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}
