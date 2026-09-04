# ============================================================
# SentinelPay Root Variables
# ============================================================

# AWS Region
variable "aws_region" {
  description = "AWS region where SentinelPay infrastructure will be deployed"
  type        = string
  default     = "eu-west-1"
}

# VPC CIDR
variable "vpc_cidr" {
  description = "CIDR block for the SentinelPay VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Availability Zones
variable "availability_zones" {
  description = "Availability Zones used by the SentinelPay VPC"
  type        = list(string)

  default = [
    "eu-west-1a",
    "eu-west-1b"
  ]
}