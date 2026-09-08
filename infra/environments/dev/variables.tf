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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
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

variable "container_port" {
  description = "Application container port"
  type        = number
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate used by the ALB HTTPS listener"
  type        = string
  default     = null
}