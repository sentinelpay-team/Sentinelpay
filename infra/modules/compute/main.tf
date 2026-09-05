resource "aws_ecs_cluster" "this" {

  name = "${var.project_name}-${var.environment}-cluster"

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

# --------------------------------------
# ECS Security Group
# --------------------------------------

resource "aws_security_group" "ecs" {

  name = "${var.project_name}-${var.environment}-ecs-sg"

  description = "Allow traffic only from ALB"

  vpc_id = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_ecs" {

  security_group_id = aws_security_group.ecs.id

  referenced_security_group_id = var.alb_security_group_id

  from_port = var.container_port

  to_port = var.container_port

  ip_protocol = "tcp"

  description = "Allow ALB to reach ECS tasks"
}

resource "aws_vpc_security_group_egress_rule" "ecs" {

  security_group_id = aws_security_group.ecs.id

  cidr_ipv4 = "0.0.0.0/0"

  ip_protocol = "-1"
}

# --------------------------------------
# Task Execution Role
# --------------------------------------

resource "aws_iam_role" "execution" {

  name = "${var.project_name}-${var.environment}-ecs-execution-role"

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
}

resource "aws_iam_role_policy_attachment" "execution" {

  role = aws_iam_role.execution.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --------------------------------------
# CloudWatch logs
# --------------------------------------

resource "aws_cloudwatch_log_group" "this" {

  name = "/ecs/${var.project_name}-${var.environment}"

  retention_in_days = 30
}

# --------------------------------------
# Task Definition
# --------------------------------------

resource "aws_ecs_task_definition" "this" {

  family = "${var.project_name}-${var.environment}-placeholder"

  requires_compatibilities = [
    "FARGATE"
  ]

  network_mode = "awsvpc"

  cpu = "256"

  memory = "512"

  execution_role_arn = aws_iam_role.execution.arn

  container_definitions = jsonencode([
    {
      name = "placeholder"

      image = var.container_image

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
          awslogs-group = aws_cloudwatch_log_group.this.name

          awslogs-region = "eu-west-1"

          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# --------------------------------------
# ECS Service
# --------------------------------------

resource "aws_ecs_service" "this" {

  name = "${var.project_name}-${var.environment}-service"

  cluster = aws_ecs_cluster.this.id

  task_definition = aws_ecs_task_definition.this.arn

  desired_count = var.desired_count

  launch_type = "FARGATE"

  network_configuration {

    subnets = var.private_subnet_ids

    security_groups = [
      aws_security_group.ecs.id
    ]

    assign_public_ip = false
  }

  load_balancer {

    target_group_arn = var.target_group_arn

    container_name = "placeholder"

    container_port = var.container_port
  }
}