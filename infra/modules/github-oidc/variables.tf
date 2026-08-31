variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "github_organization" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "deployment_policy_json" {
  description = "IAM policy assigned to GitHub deployment role"
  type        = string
}