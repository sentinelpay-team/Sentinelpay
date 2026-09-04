# ============================================================
# SentinelPay VPC
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "sentinelpay-vpc"
    Project     = "SentinelPay"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# SentinelPay Availability Zones
locals {
  azs = var.availability_zones
}

# ============================================================
# Internet Gateway
# ============================================================

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "sentinelpay-igw"
    Project     = "SentinelPay"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# Public Subnets
# One public subnet in each Availability Zone
# ============================================================

resource "aws_subnet" "public" {
  count = 2

  vpc_id = aws_vpc.main.id

  cidr_block = cidrsubnet(
    aws_vpc.main.cidr_block,
    8,
    count.index
  )

  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "sentinelpay-public-${local.azs[count.index]}"
    Project     = "SentinelPay"
    Environment = "production"
    Tier        = "public"
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# Elastic IPs for SentinelPay NAT Gateways
# One Elastic IP per Availability Zone
# ============================================================

resource "aws_eip" "nat" {
  count  = length(local.azs)
  domain = "vpc"

  tags = {
    Name        = "sentinelpay-nat-eip-${local.azs[count.index]}"
    Project     = "SentinelPay"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# NAT Gateways
# One NAT Gateway per Availability Zone
# ============================================================

resource "aws_nat_gateway" "nat" {
  count = length(local.azs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "sentinelpay-nat-${local.azs[count.index]}"
    Project     = "SentinelPay"
    Environment = "production"
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_internet_gateway.gateway
  ]
}

# ============================================================
# Private Subnets
# One private subnet in each Availability Zone
# ============================================================

resource "aws_subnet" "private" {
  count = 2

  vpc_id = aws_vpc.main.id

  cidr_block = cidrsubnet(
    aws_vpc.main.cidr_block,
    8,
    count.index + 4
  )

  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "sentinelpay-private-${local.azs[count.index]}"
    Project     = "SentinelPay"
    Environment = "production"
    Tier        = "private"
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# Public Route Table
# Provides internet access through the Internet Gateway
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name        = "sentinelpay-public-rt"
    Project     = "SentinelPay"
    Environment = "production"
    Tier        = "public"
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# Public Route Table Associations
# ============================================================

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id = aws_subnet.public[count.index].id

  route_table_id = aws_route_table.public.id
}

# ============================================================
# Private Route Tables
# One route table per AZ
# Each private subnet routes through its local NAT Gateway
# ============================================================

resource "aws_route_table" "private" {
  count = length(local.azs)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name        = "sentinelpay-private-rt-${local.azs[count.index]}"
    Project     = "SentinelPay"
    Environment = "production"
    Tier        = "private"
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# Private Route Table Associations
# Each private subnet uses the NAT Gateway in its own AZ
# ============================================================

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
