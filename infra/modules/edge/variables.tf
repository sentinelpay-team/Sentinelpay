variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "container_port" {
  type    = number
  default = 80
}
variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for the ALB"
  type        = string
  default     = null
}