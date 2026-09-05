variable "aws_region" {

  description = "AWS deployment region"

  type = string

  default = "eu-west-1"
}

variable "project_name" {

  description = "Project name"

  type = string

  default = "sentinelpay"
}

variable "environment" {

  description = "Environment"

  type = string

  default = "dev"
}

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