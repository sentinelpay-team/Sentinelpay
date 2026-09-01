resource "aws_iam_user" "honeytoken" {
  name = "${var.project_name}-${var.environment}-honeytoken"

  tags = {
    Purpose     = "Security honeytoken"
    Environment = var.environment
  }
}
resource "aws_iam_access_key" "honeytoken" {
  user = aws_iam_user.honeytoken.name
}
resource "aws_secretsmanager_secret" "honeytoken" {
  name = "${var.project_name}/${var.environment}/honeytoken"

  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "honeytoken" {
  secret_id = aws_secretsmanager_secret.honeytoken.id

  secret_string = jsonencode({
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.honeytoken.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.honeytoken.secret
  })
}
resource "aws_cloudwatch_event_rule" "honeytoken" {
  name = "${var.project_name}-${var.environment}-honeytoken-used"

  description = "Detects attempted use of SentinelPay honeytoken credentials"

  event_pattern = jsonencode({
    "detail-type" = [
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
}