# =========================================================
# LOCAL VALUES
# =========================================================

locals {
  name_prefix = var.name_prefix != null ? var.name_prefix : "${var.project_name}-${var.environment}"
}

# =========================================================
# ECS CLUSTER
# =========================================================

resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-cluster"
      Environment = var.environment
    }
  )
}

# =========================================================
# ECS SECURITY GROUP
# =========================================================

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Allow application traffic only from the ALB"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-ecs-sg"
      Environment = var.environment
    }
  )
}

# =========================================================
# ALB -> ECS INGRESS RULE
# =========================================================

resource "aws_vpc_security_group_ingress_rule" "alb_to_ecs" {
  security_group_id = aws_security_group.ecs.id

  referenced_security_group_id = var.alb_security_group_id

  from_port   = var.container_port
  to_port     = var.container_port
  ip_protocol = "tcp"

  description = "Allow application traffic from ALB to ECS tasks"
}

# =========================================================
# ECS EGRESS RULE
# =========================================================

resource "aws_vpc_security_group_egress_rule" "ecs" {
  security_group_id = aws_security_group.ecs.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow ECS tasks outbound access to required AWS services"
}

# =========================================================
# ECS TASK EXECUTION ROLE
# =========================================================

resource "aws_iam_role" "execution" {
  name        = "${var.project_name}-${var.environment}-ecs-execution-role"
  description = "Execution role used by ECS Fargate tasks"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-ecs-execution-role"
      Environment = var.environment
    }
  )
}

# =========================================================
# ECS TASK EXECUTION POLICY
# =========================================================

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# =========================================================
# CLOUDWATCH LOG GROUP
# =========================================================

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

# =========================================================
# ECS TASK DEFINITION
# =========================================================

resource "aws_ecs_task_definition" "this" {
  family = "${var.project_name}-${var.environment}-placeholder"

  requires_compatibilities = [
    "FARGATE"
  ]

  network_mode = "awsvpc"

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.execution.arn

  container_definitions = jsonencode([
    {
      name      = "placeholder"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-task-definition"
      Environment = var.environment
    }
  )
}

# =========================================================
# ECS SERVICE
# =========================================================

resource "aws_ecs_service" "this" {
  name = "${var.project_name}-${var.environment}-service"

  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn

  desired_count = var.desired_count
  launch_type   = "FARGATE"

  network_configuration {
    subnets = var.private_subnet_ids

    security_groups = [
      aws_security_group.ecs.id
    ]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "placeholder"
    container_port   = var.container_port
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-service"
      Environment = var.environment
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.execution
  ]
}