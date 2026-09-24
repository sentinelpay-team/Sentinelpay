resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-${var.environment}-security-alerts"

  kms_master_key_id = var.kms_key_arn

  tags = {
    Name        = "${var.project_name}-${var.environment}-security-alerts"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

data "aws_iam_policy_document" "security_alerts" {
  statement {
    sid    = "AllowEventBridgeHoneytokenPublish"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "events.amazonaws.com"
      ]
    }

    actions = [
      "sns:Publish"
    ]

    resources = [
      aws_sns_topic.security_alerts.arn
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"

      values = [
        data.aws_caller_identity.current.account_id
      ]
    }

    condition {
      test     = "ArnEquals"
      variable = "AWS:SourceArn"

      values = [
        aws_cloudwatch_event_rule.honeytoken.arn
      ]
    }
  }
}

resource "aws_sns_topic_policy" "security_alerts" {
  arn    = aws_sns_topic.security_alerts.arn
  policy = data.aws_iam_policy_document.security_alerts.json
}

resource "aws_cloudwatch_event_target" "honeytoken_alert" {
  rule      = aws_cloudwatch_event_rule.honeytoken.name
  target_id = "HoneytokenSecurityAlert"
  arn       = aws_sns_topic.security_alerts.arn

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 2
  }

  depends_on = [
    aws_sns_topic_policy.security_alerts
  ]
}