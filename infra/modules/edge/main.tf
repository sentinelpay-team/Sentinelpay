# ---------------------------------------------------------
# Local Values
# ---------------------------------------------------------

locals {
  application_ports = toset([
    tostring(var.payments_container_port),
    tostring(var.kyc_container_port)
  ])
}


# ---------------------------------------------------------
# ALB Security Group
# ---------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Sentinelpay Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


# ---------------------------------------------------------
# HTTPS Ingress
# ---------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Allow HTTPS from the internet to the ALB"
}


# ---------------------------------------------------------
# HTTP Ingress
# ---------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "http_redirect" {
  # checkov:skip=CKV_AWS_260:Port 80 is used for HTTP to HTTPS redirection when ACM is configured

  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "Allow HTTP traffic to the ALB"
}


# ---------------------------------------------------------
# ALB -> ECS Egress
# ---------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  for_each = local.application_ports

  security_group_id = aws_security_group.alb.id

  cidr_ipv4 = var.vpc_cidr

  from_port   = tonumber(each.value)
  to_port     = tonumber(each.value)
  ip_protocol = "tcp"

  description = "Allow ALB traffic to ECS application port ${each.value}"
}



#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "this" {
  # checkov:skip=CKV2_AWS_20:Development environment permits HTTP fallback when no ACM certificate is supplied; environments with ACM configured use HTTP-to-HTTPS redirection.
  # checkov:skip=CKV2_AWS_76:ALB is protected by the WAFv2 Web ACL defined in this module

  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = var.public_subnet_ids

  enable_deletion_protection = true
  drop_invalid_header_fields = true
  enable_http2               = true

  access_logs {
    bucket  = var.alb_logs_bucket
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}




resource "aws_lb_target_group" "payments" {
  # checkov:skip=CKV_AWS_378:TLS terminates at the ALB; backend traffic to ECS Fargate stays inside private VPC networking.
  name_prefix = "spay-"

  port        = var.payments_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-payments-tg"
      Environment = var.environment
      Service     = "payments-api"
    }
  )
}

resource "aws_lb_target_group" "kyc" {
  # checkov:skip=CKV_AWS_378:TLS terminates at the ALB; backend traffic to ECS Fargate stays inside private VPC networking.
  name_prefix = "skyc-"

  port        = var.kyc_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-kyc-tg"
      Environment = var.environment
      Service     = "kyc-api"
    }
  )
}
resource "aws_lb_listener" "https" {
  count = var.acm_certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payments.arn
  }
}


# ---------------------------------------------------------
# HTTPS Payments Listener Rule
# ---------------------------------------------------------

resource "aws_lb_listener_rule" "https_payments" {
  count = var.acm_certificate_arn != null ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payments.arn
  }

  condition {
    path_pattern {
      values = [
        "/payments",
        "/payments/*"
      ]
    }
  }
}


# ---------------------------------------------------------
# HTTPS KYC Listener Rule
# ---------------------------------------------------------

resource "aws_lb_listener_rule" "https_kyc" {
  count = var.acm_certificate_arn != null ? 1 : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kyc.arn
  }

  condition {
    path_pattern {
      values = [
        "/kyc",
        "/kyc/*"
      ]
    }
  }
}


# ---------------------------------------------------------
# HTTP -> HTTPS Redirect Listener
# ---------------------------------------------------------

resource "aws_lb_listener" "http" {
  count = var.acm_certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


# Development-only HTTP fallback when no ACM certificate is configured.
# Production/staging use the HTTPS listener and HTTP-to-HTTPS redirect.
resource "aws_lb_listener" "http_forward" {
  # checkov:skip=CKV_AWS_103:Development fallback listener does not terminate TLS

  count = var.acm_certificate_arn == null ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP" #tfsec:ignore:aws-elb-http-not-used

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payments.arn
  }
}
resource "aws_lb_listener_rule" "http_payments" {
  count = var.acm_certificate_arn == null ? 1 : 0

  listener_arn = aws_lb_listener.http_forward[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payments.arn
  }

  condition {
    path_pattern {
      values = [
        "/payments",
        "/payments/*"
      ]
    }
  }
}


# ---------------------------------------------------------
# Development HTTP KYC Rule
# ---------------------------------------------------------

resource "aws_lb_listener_rule" "http_kyc" {
  count = var.acm_certificate_arn == null ? 1 : 0

  listener_arn = aws_lb_listener.http_forward[0].arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kyc.arn
  }

  condition {
    path_pattern {
      values = [
        "/kyc",
        "/kyc/*"
      ]
    }
  }
}


# ---------------------------------------------------------
# AWS WAFv2 Web ACL
# ---------------------------------------------------------

resource "aws_wafv2_web_acl" "this" {
  name  = "${var.project_name}-${var.environment}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }


  # -------------------------------------------------------
  # AWS Managed Common Rule Set
  # -------------------------------------------------------

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }


  # -------------------------------------------------------
  # AWS Managed SQL Injection Rule Set
  # -------------------------------------------------------

  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }


  # -------------------------------------------------------
  # AWS Known Bad Inputs
  # -------------------------------------------------------

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }


  # -------------------------------------------------------
  # Payments API Rate Limit
  # -------------------------------------------------------

  rule {
    name     = "PaymentsAPIRateLimit"
    priority = 40

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.payments_rate_limit
        aggregate_key_type = "IP"

        scope_down_statement {
          byte_match_statement {
            search_string         = "/payments"
            positional_constraint = "STARTS_WITH"

            field_to_match {
              uri_path {}
            }

            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "PaymentsAPIRateLimit"
      sampled_requests_enabled   = true
    }
  }


  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-waf"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


# ---------------------------------------------------------
# Associate WAF with ALB
# ---------------------------------------------------------

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}


# ---------------------------------------------------------
# WAF CloudWatch Log Group
# ---------------------------------------------------------

resource "aws_cloudwatch_log_group" "waf" {
  name = "aws-waf-logs-${var.project_name}-${var.environment}"

  retention_in_days = 365
  kms_key_id        = var.kms_key_arn

  tags = {
    Name        = "aws-waf-logs-${var.project_name}-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


# ---------------------------------------------------------
# WAF Logging Configuration
# ---------------------------------------------------------

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  resource_arn = aws_wafv2_web_acl.this.arn

  log_destination_configs = [
    aws_cloudwatch_log_group.waf.arn
  ]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.waf,
    aws_wafv2_web_acl.this
  ]
}