variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the RDS instance is deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by the RDS subnet group"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least two private subnet IDs must be provided for RDS."
  }
}

variable "application_security_group_id" {
  description = "Security group ID of the application allowed to access PostgreSQL"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the customer-managed KMS key used to encrypt RDS and its master user secret"
  type        = string
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
}

variable "db_username" {
  description = "Master username for the PostgreSQL database"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "postgres_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17"
}

variable "postgres_parameter_group_family" {
  description = "PostgreSQL DB parameter group family"
  type        = string
  default     = "postgres17"
}

variable "allocated_storage" {
  description = "Initial allocated storage for the PostgreSQL instance in GiB"
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20 GiB."
  }
}

variable "max_allocated_storage" {
  description = "Maximum storage autoscaling limit for the PostgreSQL instance in GiB"
  type        = number
  default     = 100

  validation {
    condition     = var.max_allocated_storage >= var.allocated_storage
    error_message = "max_allocated_storage must be greater than or equal to allocated_storage."
  }
}

variable "backup_retention_period" {
  description = "Number of days automated RDS backups are retained"
  type        = number
  default     = 7

  validation {
    condition = (
      var.backup_retention_period >= 1 &&
      var.backup_retention_period <= 35
    )
    error_message = "backup_retention_period must be between 1 and 35 days."
  }
}

variable "multi_az" {
  description = "Whether the PostgreSQL instance uses a Multi-AZ deployment"
  type        = bool
  default     = true
}
variable "db_password" {
  description = "Master password for the PostgreSQL database"
  type        = string
  sensitive   = true
}