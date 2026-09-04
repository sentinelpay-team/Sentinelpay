variable "vpc_id" {
  description = "ID of the SentinelPay VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}