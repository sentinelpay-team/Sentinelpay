resource "aws_security_group" "quarantine" {
  name        = "${var.project_name}-${var.environment}-quarantine"
  description = "Isolation security group for compromised resources"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-quarantine"
    Environment = var.environment
  }
}
resource "aws_cloudwatch_event_rule" "guardduty_high" {
  name = "${var.project_name}-${var.environment}-guardduty-high"

  description = "Triggers automated containment for high-severity GuardDuty findings"

  event_pattern = jsonencode({
    source = [
      "aws.guardduty"
    ]

    "detail-type" = [
      "GuardDuty Finding"
    ]

    detail = {
      severity = [
        {
          numeric = [
            ">=",
            7
          ]
        }
      ]
    }
  })
}
resource "aws_iam_role" "quarantine" {
  name = "${var.project_name}-${var.environment}-quarantine-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy" "quarantine" {
  role = aws_iam_role.quarantine.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:ModifyNetworkInterfaceAttribute"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "*"
      }
    ]
  })
}
data "archive_file" "quarantine" {
  type = "zip"

  source_file = "${path.module}/lambda/quarantine.py"

  output_path = "${path.module}/quarantine.zip"
}
resource "aws_lambda_function" "quarantine" {
  function_name = "${var.project_name}-${var.environment}-quarantine"

  role = aws_iam_role.quarantine.arn

  runtime = "python3.13"

  handler = "quarantine.lambda_handler"

  filename = data.archive_file.quarantine.output_path

  source_code_hash = data.archive_file.quarantine.output_base64sha256

  environment {
    variables = {
      QUARANTINE_SG = aws_security_group.quarantine.id
    }
  }

  depends_on = [
    aws_iam_role_policy.quarantine
  ]
}
resource "aws_cloudwatch_event_target" "guardduty" {
  rule = aws_cloudwatch_event_rule.guardduty_high.name

  target_id = "QuarantineLambda"

  arn = aws_lambda_function.quarantine.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id = "AllowEventBridgeGuardDuty"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.quarantine.function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.guardduty_high.arn
}