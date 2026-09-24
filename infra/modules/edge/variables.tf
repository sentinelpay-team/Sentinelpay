variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the ALB security group is created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC used to restrict ALB egress"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs used by the ALB"
  type        = list(string)
}

variable "payments_container_port" {
  description = "Container port used by payments-api"
  type        = number
  default     = 8001

  validation {
    condition = (
      var.payments_container_port >= 1 &&
      var.payments_container_port <= 65535
    )

    error_message = "payments_container_port must be between 1 and 65535."
  }
}

variable "kyc_container_port" {
  description = "Container port used by kyc-api"
  type        = number
  default     = 8002

  validation {
    condition = (
      var.kyc_container_port >= 1 &&
      var.kyc_container_port <= 65535
    )

    error_message = "kyc_container_port must be between 1 and 65535."
  }
}

variable "payments_health_check_path" {
  description = "Health check path used by the payments-api target group"
  type        = string
  default     = "/"
}

variable "kyc_health_check_path" {
  description = "Health check path used by the kyc-api target group"
  type        = string
  default     = "/"
}

variable "payments_rate_limit" {
  description = "WAF rate limit applied to the payments API per source IP"
  type        = number
  default     = 1000

  validation {
    condition     = var.payments_rate_limit > 0
    error_message = "payments_rate_limit must be greater than 0."
  }
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = null
}

variable "alb_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt WAF CloudWatch logs"
  type        = string
}
variable "tags" {
  description = "Common tags applied to edge resources"
  type        = map(string)
  default     = {}
}