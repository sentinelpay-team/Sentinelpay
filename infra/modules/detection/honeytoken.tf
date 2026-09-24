resource "aws_iam_user" "honeytoken" {
  # checkov:skip=CKV_AWS_273:Intentional non-human deception identity used as a security honeytoken; interactive console access is not permitted.
  # checkov:skip=CKV_AWS_273:Intentional non-human deception account used as a security honeytoken; no console access is configured.

  name = "${var.project_name}-${var.environment}-honeytoken"

  tags = {
    Name        = "${var.project_name}-${var.environment}-honeytoken"
    Purpose     = "Security honeytoken"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_access_key" "honeytoken" {
  user = aws_iam_user.honeytoken.name
}

resource "aws_secretsmanager_secret" "honeytoken" {
  # checkov:skip=CKV2_AWS_57:Honeytoken credential is intentionally stable for detection; rotation is handled as part of the deception-control lifecycle.

  name        = "${var.project_name}/${var.environment}/honeytoken"
  description = "Security honeytoken credentials - do not use"

  kms_key_id = var.kms_key_arn

  recovery_window_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-honeytoken-secret"
    Purpose     = "Security honeytoken"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_secretsmanager_secret_version" "honeytoken" {
  secret_id = aws_secretsmanager_secret.honeytoken.id

  secret_string = jsonencode({
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.honeytoken.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.honeytoken.secret
  })
}

resource "aws_cloudwatch_event_rule" "honeytoken" {
  name        = "${var.project_name}-${var.environment}-honeytoken-used"
  description = "Detects attempted use of SentinelPay honeytoken credentials"

  event_pattern = jsonencode({
    source = [
      "aws.iam",
      "aws.sts"
    ]

    detail-type = [
      "AWS API Call via CloudTrail"
    ]

    detail = {
      userIdentity = {
        accessKeyId = [
          aws_iam_access_key.honeytoken.id
        ]
      }
    }
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-honeytoken-used"
    Purpose     = "Honeytoken detection"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}