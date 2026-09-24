variable "project_name" {
  description = "Name of the project"
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition = contains(
      ["dev", "staging", "prod"],
      var.environment
    )
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "vpc_id" {
  description = "ID of the VPC containing the Redis deployment"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by the ElastiCache subnet group"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least two private subnet IDs must be provided."
  }
}

variable "application_security_group_id" {
  description = "Security group ID of the ECS application workloads allowed to access Redis"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the customer-managed KMS key used to encrypt KYC data, Redis, and Secrets Manager secrets"
  type        = string
}

variable "kyc_retention_days" {
  description = "Number of days KYC objects are protected by S3 Object Lock in Governance mode"
  type        = number
  default     = 90

  validation {
    condition     = var.kyc_retention_days > 0
    error_message = "kyc_retention_days must be greater than zero."
  }
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_rotation_lambda_arn" {
  description = "ARN of the Lambda function used to rotate the Redis authentication secret"
  type        = string
  default     = null

  validation {
    condition = (
      var.redis_rotation_lambda_arn == null ||
      can(regex(
        "^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:.+$",
        var.redis_rotation_lambda_arn
      ))
    )

    error_message = "redis_rotation_lambda_arn must be null or a valid AWS Lambda function ARN."
  }
}