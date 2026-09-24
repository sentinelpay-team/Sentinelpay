data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret" "database" {
  name        = "${var.project_name}/${var.environment}/database"
  description = "PostgreSQL credentials for ${var.project_name}-${var.environment}"

  kms_key_id = var.kms_key_arn

  recovery_window_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-database-secret"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


resource "aws_security_group" "rotation" {
  name        = "${var.project_name}-${var.environment}-rotation-sg"
  description = "Security group for Secrets Manager PostgreSQL rotation Lambda"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-rotation-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rotation_to_rds" {
  security_group_id            = var.rds_security_group_id
  referenced_security_group_id = aws_security_group.rotation.id

  description = "Allow PostgreSQL traffic from Secrets Manager rotation Lambda"

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "rotation_postgres" {
  security_group_id            = aws_security_group.rotation.id
  referenced_security_group_id = var.rds_security_group_id

  description = "Allow PostgreSQL traffic from rotation Lambda to RDS"

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "rotation_https" {
  security_group_id = aws_security_group.rotation.id

  description = "Allow HTTPS traffic to VPC endpoints"

  cidr_ipv4   = var.vpc_cidr
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_iam_role" "rotation" {
  name = "${var.project_name}-${var.environment}-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "LambdaAssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-rotation-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_sqs_queue" "rotation_dlq" {
  name = "${var.project_name}-${var.environment}-rotation-dlq"

  message_retention_seconds = 1209600

  kms_master_key_id = var.kms_key_arn

  tags = {
    Name        = "${var.project_name}-${var.environment}-rotation-dlq"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy" "rotation" {
  name = "${var.project_name}-${var.environment}-rotation-policy"
  role = aws_iam_role.rotation.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "SecretRotation"
        Effect = "Allow"

        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]

        Resource = aws_secretsmanager_secret.database.arn
      },
      {
        Sid    = "GeneratePassword"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetRandomPassword"
        ]

        Resource = "*"
      },
      {
        Sid    = "UseKMSKey"
        Effect = "Allow"

        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]

        Resource = var.kms_key_arn
      },
      {
        Sid    = "SendToDeadLetterQueue"
        Effect = "Allow"

        Action = [
          "sqs:SendMessage"
        ]

        Resource = aws_sqs_queue.rotation_dlq.arn
      },
      {
        Sid    = "WriteXRayTelemetry"
        Effect = "Allow"

        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role = aws_iam_role.rotation.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_signer_signing_profile" "rotation" {
  name_prefix = "${var.project_name}_${var.environment}_rotation_"

  platform_id = "AWSLambda-SHA384-ECDSA"

  signature_validity_period {
    value = 135
    type  = "MONTHS"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rotation-signing-profile"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_lambda_code_signing_config" "rotation" {
  description = "Code signing configuration for PostgreSQL rotation Lambda"

  allowed_publishers {
    signing_profile_version_arns = [
      aws_signer_signing_profile.rotation.version_arn
    ]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rotation-code-signing"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_lambda_function" "rotation" {
  # checkov:skip=CKV_AWS_115:Reserved concurrency cannot be configured because the AWS account concurrency quota must retain at least 10 unreserved concurrent executions.

  function_name = "${var.project_name}-${var.environment}-postgres-rotation"

  role = aws_iam_role.rotation.arn

  runtime = "python3.13"
  handler = "lambda_function.lambda_handler"

  filename         = var.rotation_lambda_zip
  source_code_hash = filebase64sha256(var.rotation_lambda_zip)

  code_signing_config_arn = aws_lambda_code_signing_config.rotation.arn

  timeout     = 60
  memory_size = 256

  dead_letter_config {
    target_arn = aws_sqs_queue.rotation_dlq.arn
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids = var.private_subnet_ids

    security_group_ids = [
      aws_security_group.rotation.id
    ]
  }

  depends_on = [
    aws_iam_role_policy.rotation,
    aws_iam_role_policy_attachment.lambda_vpc_access
  ]

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres-rotation"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_lambda_permission" "allow_secrets_manager" {
  statement_id   = "AllowSecretsManagerInvoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.rotation.function_name
  principal      = "secretsmanager.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
  source_arn     = aws_secretsmanager_secret.database.arn
}

resource "aws_secretsmanager_secret_rotation" "database" {
  secret_id           = aws_secretsmanager_secret.database.id
  rotation_lambda_arn = aws_lambda_function.rotation.arn

  rotation_rules {
    automatically_after_days = 30
  }

  depends_on = [
    aws_lambda_permission.allow_secrets_manager
  ]
}