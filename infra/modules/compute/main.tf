# ============================================================
# ECS Cluster
# ============================================================

resource "aws_ecs_cluster" "sentinelpay" {
  name = "sentinelpay-cluster"

  tags = {
    Name        = "sentinelpay-cluster"
    Project     = "SentinelPay"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# ECS Task Definition
# ============================================================

resource "aws_ecs_task_definition" "sentinelpay" {
  family                   = "sentinelpay-placeholder"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx:alpine"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])

  tags = {
    Name        = "sentinelpay-placeholder"
    Project     = "SentinelPay"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# ECS Security Group
# ============================================================

resource "aws_security_group" "ecs" {
  name        = "sentinelpay-ecs-sg"
  description = "Allow HTTP traffic from SentinelPay ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sentinelpay-ecs-sg"
    Project     = "SentinelPay"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# ECS Fargate Service
# ============================================================




#======================================================================
#CONNECT ECS SERVICE TO ALB TARGET GROUP
#======================================================================
resource "aws_ecs_service" "sentinelpay" {
  name            = "sentinelpay-placeholder"
  cluster         = aws_ecs_cluster.sentinelpay.id
  task_definition = aws_ecs_task_definition.sentinelpay.arn

  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "nginx"
    container_port   = 80
  }

  tags = {
    Name        = "sentinelpay-placeholder"
    Project     = "SentinelPay"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

#============================================================
#ECS Task Role
#============================================================

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "sentinelpay-ecs-task-role"

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

resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "sentinelpay-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = aws_secretsmanager_secret.sentinelpay.arn
      }
    ]
  })
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "sentinelpay-ecs-task-execution-role"

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


# AWS managed policy for ECS execution
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role = aws_iam_role.ecs_task_execution_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

