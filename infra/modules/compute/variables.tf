variable "project_name" {
  description = "Name of the Sentinelpay project"
  type        = string
}

variable "environment" {
  description = "Deployment environment such as dev, staging, or prod"
  type        = string
}

variable "name_prefix" {
  description = "Optional resource name prefix"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region used for the deployment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS resources are deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the Sentinelpay VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by ECS Fargate tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID attached to the Application Load Balancer"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener used by the ECS services"
  type        = string
}

variable "payments_target_group_arn" {
  description = "ARN of the ALB target group for payments-api"
  type        = string
}

variable "kyc_target_group_arn" {
  description = "ARN of the ALB target group for kyc-api"
  type        = string
}

variable "payments_container_image" {
  description = "Immutable container image URI for payments-api"
  type        = string
}

variable "payments_container_port" {
  description = "Container port exposed by payments-api"
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

variable "payments_desired_count" {
  description = "Desired number of payments-api ECS tasks"
  type        = number
  default     = 1

  validation {
    condition     = var.payments_desired_count >= 1
    error_message = "payments_desired_count must be at least 1."
  }
}

variable "payments_cpu" {
  description = "Fargate CPU units allocated to payments-api"
  type        = number
  default     = 256
}

variable "payments_memory" {
  description = "Fargate memory in MiB allocated to payments-api"
  type        = number
  default     = 512
}

variable "kyc_container_image" {
  description = "Immutable container image URI for kyc-api"
  type        = string
}

variable "kyc_container_port" {
  description = "Container port exposed by kyc-api"
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

variable "kyc_desired_count" {
  description = "Desired number of kyc-api ECS tasks"
  type        = number
  default     = 1

  validation {
    condition     = var.kyc_desired_count >= 1
    error_message = "kyc_desired_count must be at least 1."
  }
}

variable "kyc_cpu" {
  description = "Fargate CPU units allocated to kyc-api"
  type        = number
  default     = 256
}

variable "kyc_memory" {
  description = "Fargate memory in MiB allocated to kyc-api"
  type        = number
  default     = 512
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN used to encrypt ECS CloudWatch logs and application secrets"
  type        = string
}

variable "tags" {
  description = "Common tags applied to Sentinelpay resources"
  type        = map(string)
  default     = {}
}

variable "s3_prefix_list_id" {
  description = "S3 managed prefix list ID used for private ECS access to S3"
  type        = string
}

variable "jwt_private_secret_name" {
  description = "Secrets Manager secret name containing the JWT private key"
  type        = string
}

variable "jwt_public_secret_name" {
  description = "Secrets Manager secret name containing the JWT public key"
  type        = string
}

variable "rate_limit_secret_name" {
  description = "Secrets Manager secret name containing the payments API rate limit key"
  type        = string
}

variable "session_signing_secret_name" {
  description = "Secrets Manager secret name containing the payments session signing key"
  type        = string
}

variable "database_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database connection details"
  type        = string
}

variable "redis_endpoint" {
  description = "Redis primary endpoint"
  type        = string
}

variable "redis_port" {
  description = "Redis port"
  type        = number
}

variable "redis_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Redis authentication token"
  type        = string
}

variable "kyc_bucket_name" {
  description = "S3 bucket used by the KYC service"
  type        = string
}