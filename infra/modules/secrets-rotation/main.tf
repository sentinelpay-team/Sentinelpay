data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret" "database" {
  name = "${var.project_name}/${var.environment}/database"

  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id

  secret_string = jsonencode({
    engine   = "postgres"
    host     = var.db_host
    port     = var.db_port
    dbname   = var.db_name
    username = var.db_username
    password = var.db_password
  })
}

resource "aws_security_group" "rotation" {
  name        = "${var.project_name}-${var.environment}-rotation-sg"
  description = "Secrets Manager PostgreSQL rotation"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "rotation_to_rds" {
  security_group_id = var.rds_security_group_id

  referenced_security_group_id = aws_security_group.rotation.id

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "rotation" {
  security_group_id = aws_security_group.rotation.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_iam_role" "rotation" {
  name = "${var.project_name}-${var.environment}-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "lambda.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
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
          "kms:GenerateDataKey"
        ]

        Resource = var.kms_key_arn
      }
    ]
  })
}

resource "aws_lambda_function" "rotation" {
  function_name = "${var.project_name}-${var.environment}-postgres-rotation"

  role = aws_iam_role.rotation.arn

  runtime = "python3.13"
  handler = "lambda_function.lambda_handler"

  filename         = var.rotation_lambda_zip
  source_code_hash = filebase64sha256(var.rotation_lambda_zip)

  timeout = 60

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
}

resource "aws_lambda_permission" "secrets_manager" {
  statement_id = "AllowSecretsManager"

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation.function_name

  principal = "secretsmanager.amazonaws.com"

  source_account = data.aws_caller_identity.current.account_id
}

resource "aws_secretsmanager_secret_rotation" "database" {
  secret_id = aws_secretsmanager_secret.database.id

  rotation_lambda_arn = aws_lambda_function.rotation.arn

  rotation_rules {
    automatically_after_days = 30
  }

  depends_on = [
    aws_lambda_permission.secrets_manager
  ]
}
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role = aws_iam_role.rotation.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}