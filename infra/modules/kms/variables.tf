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
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "kms_admin_role_arns" {
  description = "IAM role ARNs permitted to administer the KMS key"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.kms_admin_role_arns :
      can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", arn))
    ])
    error_message = "Each KMS administrator must be a valid IAM role ARN."
  }
}

variable "kms_user_role_arns" {
  description = "IAM role ARNs permitted to use the KMS key for cryptographic operations"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.kms_user_role_arns :
      can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", arn))
    ])
    error_message = "Each KMS key user must be a valid IAM role ARN."
  }
}