variable "aws_region" {
  description = "AWS region where the Terraform backend resources are deployed"
  type        = string
  default     = "eu-west-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region."
  }
}

variable "project_name" {
  description = "Project name used for naming Terraform backend resources"
  type        = string
  default     = "sentinelpay"

  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 30
    error_message = "project_name must be between 3 and 30 characters."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}