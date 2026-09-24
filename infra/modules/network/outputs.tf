output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}
output "s3_prefix_list_id" {
  description = "AWS managed prefix list ID for the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.prefix_list_id
}