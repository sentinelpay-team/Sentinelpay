# =========================================================
# AWS
# =========================================================

variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "eu-west-1"
}


# =========================================================
# PROJECT
# =========================================================

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "sentinelpay"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}


# =========================================================
# NETWORK
# =========================================================

variable "vpc_cidr" {
  description = "CIDR block of the VPC used to restrict ECS outbound traffic"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones for the VPC"
  type        = list(string)
}


# =========================================================
# GITHUB OIDC
# =========================================================

variable "github_organization" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the AWS role"
  type        = string
  default     = "main"
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate used by the ALB HTTPS listener"
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Prefix used for naming compute resources"
  type        = string
  default     = null
}

variable "payments_container_image" {
  description = "Container image URI used by the payments-api ECS task"
  type        = string
}

variable "payments_container_port" {
  description = "Port exposed by the payments-api container"
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

variable "kyc_container_image" {
  description = "Container image URI used by the kyc-api ECS task"
  type        = string
}

variable "kyc_container_port" {
  description = "Port exposed by the kyc-api container"
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

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}
