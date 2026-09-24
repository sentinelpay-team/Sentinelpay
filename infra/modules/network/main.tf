resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-vpc"
      Environment = var.environment
    }
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-igw"
      Environment = var.environment
    }
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-public-${count.index + 1}"
      Environment = var.environment
      Tier        = "public"
    }
  )
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-private-${count.index + 1}"
      Environment = var.environment
      Tier        = "private"
    }
  )
}

resource "aws_eip" "nat" {
  domain = "vpc"

  depends_on = [
    aws_internet_gateway.this
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-nat-eip"
      Environment = var.environment
    }
  )
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [
    aws_internet_gateway.this
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-nat"
      Environment = var.environment
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-public-rt"
      Environment = var.environment
    }
  )
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-private-rt"
      Environment = var.environment
    }
  )
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id

  ingress = []
  egress  = []

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-default-deny"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name = "/aws/vpc/${var.project_name}-${var.environment}/flow-logs"

  retention_in_days = 365
  kms_key_id        = var.kms_key_arn

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-vpc-flow-logs"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-vpc-flow-logs-role"
      Environment = var.environment
    }
  )
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "WriteVPCFlowLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      },
      {
        Sid    = "DescribeVPCFlowLogStreams"
        Effect = "Allow"

        Action = [
          "logs:DescribeLogStreams"
        ]

        Resource = aws_cloudwatch_log_group.vpc_flow_logs.arn
      }
    ]
  })
}
resource "aws_flow_log" "this" {
  vpc_id = aws_vpc.this.id

  traffic_type = "ALL"

  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn

  iam_role_arn = aws_iam_role.vpc_flow_logs.arn

  max_aggregation_interval = 60

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-vpc-flow-log"
      Environment = var.environment
    }
  )

  depends_on = [
    aws_iam_role_policy.vpc_flow_logs
  ]
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
      Environment = var.environment
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_https" {
  security_group_id = aws_security_group.vpc_endpoints.id

  cidr_ipv4 = var.vpc_cidr

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Allow HTTPS from resources within the VPC"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-s3-endpoint"
      Environment = var.environment
    }
  )
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private[*].id

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-ecr-api-endpoint"
      Environment = var.environment
    }
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private[*].id

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-ecr-dkr-endpoint"
      Environment = var.environment
    }
  )
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private[*].id

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-secretsmanager-endpoint"
      Environment = var.environment
    }
  )
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private[*].id

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-kms-endpoint"
      Environment = var.environment
    }
  )
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private[*].id

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-logs-endpoint"
      Environment = var.environment
    }
  )
}