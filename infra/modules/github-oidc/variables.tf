variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "github_organization" {
  description = "GitHub organisation that owns the repository"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the AWS role"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the AWS deployment role"
  type        = string
  default     = "main"
}

variable "deployment_policy_json" {
  description = "IAM deployment policy JSON attached to the GitHub Actions role"
  type        = string
}