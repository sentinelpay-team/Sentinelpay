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

variable "session_duration" {
  description = "Maximum IAM Identity Center permission-set session duration"
  type        = string
  default     = "PT4H"

  validation {
    condition = contains(
      ["PT1H", "PT2H", "PT3H", "PT4H"],
      var.session_duration
    )

    error_message = "session_duration must be PT1H, PT2H, PT3H, or PT4H."
  }
}