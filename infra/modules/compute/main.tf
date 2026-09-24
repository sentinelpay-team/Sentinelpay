data "aws_secretsmanager_secret" "jwt_private" {
  name = var.jwt_private_secret_name
}

data "aws_secretsmanager_secret" "jwt_public" {
  name = var.jwt_public_secret_name
}

data "aws_secretsmanager_secret" "rate_limit" {
  name = var.rate_limit_secret_name
}

data "aws_secretsmanager_secret" "session_signing" {
  name = var.session_signing_secret_name
}

locals {
  name_prefix = var.name_prefix != null ? var.name_prefix : "${var.project_name}-${var.environment}"

  application_ports = toset([
    tostring(var.payments_container_port),
    tostring(var.kyc_container_port)
  ])
}

resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-cluster"
      Environment = var.environment
    }
  )
}

resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "Security group for Sentinelpay ECS Fargate tasks"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-ecs-sg"
      Environment = var.environment
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_s3" {
  security_group_id = aws_security_group.ecs.id
  prefix_list_id    = var.s3_prefix_list_id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Allow ECS HTTPS access to S3 through the S3 VPC endpoint"
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_ecs" {
  for_each = local.application_ports

  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = var.alb_security_group_id

  from_port   = tonumber(each.value)
  to_port     = tonumber(each.value)
  ip_protocol = "tcp"

  description = "Allow ALB traffic to ECS application port ${each.value}"
}

resource "aws_vpc_security_group_egress_rule" "ecs_https" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = var.vpc_cidr

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Allow ECS HTTPS traffic within the VPC"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_postgres" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = var.vpc_cidr

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"

  description = "Allow ECS tasks to connect to PostgreSQL within the VPC"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_redis" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = var.vpc_cidr

  from_port   = 6379
  to_port     = 6379
  ip_protocol = "tcp"

  description = "Allow ECS tasks to connect to Redis within the VPC"
}

resource "aws_vpc_security_group_egress_rule" "ecs_dns_udp" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = var.vpc_cidr

  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"

  description = "Allow ECS DNS queries over UDP within the VPC"
}

resource "aws_vpc_security_group_egress_rule" "ecs_dns_tcp" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = var.vpc_cidr

  from_port   = 53
  to_port     = 53
  ip_protocol = "tcp"

  description = "Allow ECS DNS queries over TCP within the VPC"
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/${local.name_prefix}"

  retention_in_days = 365
  kms_key_id        = var.kms_key_arn

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-ecs-logs"
      Environment = var.environment
    }
  )
}

resource "aws_ecs_task_definition" "payments" {
  family = "${local.name_prefix}-payments-api"

  requires_compatibilities = [
    "FARGATE"
  ]

  network_mode = "awsvpc"

  cpu    = var.payments_cpu
  memory = var.payments_memory

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.payments_task.arn

  container_definitions = jsonencode([
    {
      name      = "payments-api"
      image     = var.payments_container_image
      essential = true

      portMappings = [
        {
          containerPort = var.payments_container_port
          hostPort      = var.payments_container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "REDIS_HOST"
          value = var.redis_endpoint
        },
        {
          name  = "REDIS_PORT"
          value = tostring(var.redis_port)
        },
        {
          name  = "REDIS_SCHEME"
          value = "rediss"
        },
        {
          name  = "REDIS_DB"
          value = "2"
        },
        {
          name  = "DB_SSLMODE"
          value = "require"
        }
      ]

      secrets = [
        {
          name      = "JWT_PRIVATE_KEY"
          valueFrom = data.aws_secretsmanager_secret.jwt_private.arn
        },
        {
          name      = "JWT_PUBLIC_KEY"
          valueFrom = data.aws_secretsmanager_secret.jwt_public.arn
        },
        {
          name      = "RATE_LIMIT_KEY_SECRET"
          valueFrom = data.aws_secretsmanager_secret.rate_limit.arn
        },
        {
          name      = "SESSION_SIGNING_KEY"
          valueFrom = data.aws_secretsmanager_secret.session_signing.arn
        },
        {
          name      = "DB_HOST"
          valueFrom = "${var.database_secret_arn}:host::"
        },
        {
          name      = "DB_PORT"
          valueFrom = "${var.database_secret_arn}:port::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${var.database_secret_arn}:dbname::"
        },
        {
          name      = "DB_USERNAME"
          valueFrom = "${var.database_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.database_secret_arn}:password::"
        },
        {
          name      = "REDIS_AUTH_TOKEN"
          valueFrom = var.redis_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "payments"
        }
      }
    }
  ])

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-payments-api-task"
      Environment = var.environment
      Service     = "payments-api"
    }
  )
}

resource "aws_ecs_task_definition" "kyc" {
  family = "${local.name_prefix}-kyc-api"

  requires_compatibilities = [
    "FARGATE"
  ]

  network_mode = "awsvpc"

  cpu    = var.kyc_cpu
  memory = var.kyc_memory

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.kyc_task.arn

  container_definitions = jsonencode([
    {
      name      = "kyc-api"
      image     = var.kyc_container_image
      essential = true

      portMappings = [
        {
          containerPort = var.kyc_container_port
          hostPort      = var.kyc_container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "KYC_BUCKET"
          value = var.kyc_bucket_name
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "DB_SSLMODE"
          value = "require"
        }
      ]

      secrets = [
        {
          name      = "JWT_PUBLIC_KEY"
          valueFrom = data.aws_secretsmanager_secret.jwt_public.arn
        },
        {
          name      = "DB_HOST"
          valueFrom = "${var.database_secret_arn}:host::"
        },
        {
          name      = "DB_PORT"
          valueFrom = "${var.database_secret_arn}:port::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${var.database_secret_arn}:dbname::"
        },
        {
          name      = "DB_USERNAME"
          valueFrom = "${var.database_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.database_secret_arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "kyc"
        }
      }
    }
  ])

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-kyc-api-task"
      Environment = var.environment
      Service     = "kyc-api"
    }
  )
}

resource "aws_ecs_service" "payments" {
  name = "${local.name_prefix}-payments-api"

  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.payments.arn

  desired_count = var.payments_desired_count
  launch_type   = "FARGATE"

  enable_execute_command = false

  network_configuration {
    subnets = var.private_subnet_ids

    security_groups = [
      aws_security_group.ecs.id
    ]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.payments_target_group_arn
    container_name   = "payments-api"
    container_port   = var.payments_container_port
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-payments-api-service"
      Environment = var.environment
      Service     = "payments-api"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.execution,
    terraform_data.alb_listener
  ]
}

resource "aws_ecs_service" "kyc" {
  name = "${local.name_prefix}-kyc-api"

  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.kyc.arn

  desired_count = var.kyc_desired_count
  launch_type   = "FARGATE"

  enable_execute_command = false

  network_configuration {
    subnets = var.private_subnet_ids

    security_groups = [
      aws_security_group.ecs.id
    ]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.kyc_target_group_arn
    container_name   = "kyc-api"
    container_port   = var.kyc_container_port
  }

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-kyc-api-service"
      Environment = var.environment
      Service     = "kyc-api"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.execution,
    terraform_data.alb_listener
  ]
}

resource "terraform_data" "alb_listener" {
  input = var.alb_listener_arn
}