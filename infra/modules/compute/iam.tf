# =========================================================
# ECS TASK ASSUME ROLE POLICY
# =========================================================

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    sid    = "ECSTasksAssumeRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"

      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}


# =========================================================
# ECS TASK EXECUTION ROLE
# =========================================================
#
# This role is used by the ECS/Fargate platform to:
#
# - pull images
# - publish logs
# - perform ECS task startup operations
#
# It is NOT the application identity.
# =========================================================

resource "aws_iam_role" "execution" {
  name        = "${local.name_prefix}-ecs-execution-role"
  description = "Execution role used by Sentinelpay ECS Fargate tasks"

  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-ecs-execution-role"
      Environment = var.environment
      RoleType    = "ECSExecutionRole"
    }
  )
}


# =========================================================
# ECS EXECUTION ROLE POLICY
# =========================================================

resource "aws_iam_role_policy_attachment" "execution" {
  role = aws_iam_role.execution.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# =========================================================
# PAYMENTS API TASK ROLE
# =========================================================
#
# Dedicated application identity for payments-api.
#
# Application-specific permissions should be attached to
# this role only when payments-api actually requires them.
# =========================================================

resource "aws_iam_role" "payments_task" {
  name        = "${local.name_prefix}-payments-task-role"
  description = "Application task role for Sentinelpay payments-api"

  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-payments-task-role"
      Environment = var.environment
      Service     = "payments-api"
      RoleType    = "ECSTaskRole"
    }
  )
}


# =========================================================
# KYC API TASK ROLE
# =========================================================
#
# Dedicated application identity for kyc-api.
#
# KYC permissions such as access to the KYC S3 bucket
# should be attached here rather than to payments-api.
# =========================================================

resource "aws_iam_role" "kyc_task" {
  name        = "${local.name_prefix}-kyc-task-role"
  description = "Application task role for Sentinelpay kyc-api"

  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = merge(
    var.tags,
    {
      Name        = "${local.name_prefix}-kyc-task-role"
      Environment = var.environment
      Service     = "kyc-api"
      RoleType    = "ECSTaskRole"
    }
  )
}
data "aws_iam_policy_document" "execution_secrets" {
  statement {
    sid    = "ReadApplicationSecrets"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      data.aws_secretsmanager_secret.jwt_private.arn,
      data.aws_secretsmanager_secret.jwt_public.arn,
      data.aws_secretsmanager_secret.rate_limit.arn,
      data.aws_secretsmanager_secret.session_signing.arn,
      var.database_secret_arn,
      var.redis_secret_arn
    ]
  }

  statement {
    sid    = "DecryptApplicationSecrets"
    effect = "Allow"

    actions = [
      "kms:Decrypt"
    ]

    resources = [
      var.kms_key_arn
    ]
  }
}

resource "aws_iam_role_policy" "execution_secrets" {
  name   = "${local.name_prefix}-ecs-jwt-secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution_secrets.json
}