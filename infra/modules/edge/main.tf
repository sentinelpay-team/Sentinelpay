# ============================================================
# ALB Security Group
# ============================================================

resource "aws_security_group" "alb" {
  name        = "sentinelpay-alb-sg"
  description = "Allow HTTP traffic to SentinelPay ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ============================================================
# Application Load Balancer
# ============================================================

resource "aws_lb" "sentinelpay" {
  name               = "sentinelpay-alb"
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = var.public_subnet_ids
}

# ============================================================
# ALB Target Group
# ============================================================

resource "aws_lb_target_group" "sentinelpay" {
  name        = "sentinelpay-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = {
    Name        = "sentinelpay-tg"
    Project     = "SentinelPay"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# ALB Listener
# ============================================================

resource "aws_lb_listener" "sentinelpay" {
  load_balancer_arn = aws_lb.sentinelpay.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sentinelpay.arn
  }

  tags = {
    Name        = "sentinelpay-http-listener"
    Project     = "SentinelPay"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}