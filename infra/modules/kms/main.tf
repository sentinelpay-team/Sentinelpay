data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "this" {

  # ------------------------------------------------
  # Account root
  # ------------------------------------------------
  statement {
    sid    = "EnableAccountRoot"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:*"
    ]

    resources = ["*"]
  }

  # ------------------------------------------------
  # KMS administrators
  # ------------------------------------------------
  statement {
    sid    = "KeyAdministrators"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.kms_admin_role_arns
    }

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]

    resources = ["*"]
  }

  # ------------------------------------------------
  # Application/service roles
  # ------------------------------------------------
  statement {
    sid    = "KeyUsers"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.kms_user_role_arns
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }

  # ------------------------------------------------
  # AWS-resource grants
  # ------------------------------------------------
  statement {
    sid    = "ServiceGrants"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.kms_user_role_arns
    }

    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]

    resources = ["*"]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"

      values = [
        "true"
      ]
    }
  }

  # ------------------------------------------------
  # CloudTrail
  # ------------------------------------------------
  statement {
    sid    = "AllowCloudTrailGenerateDataKey"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
    }

    actions = [
      "kms:GenerateDataKey*"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"

      values = [
        "arn:aws:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${var.project_name}-${var.environment}-trail"
      ]
    }
  }

  statement {
    sid    = "AllowCloudTrailDescribeKey"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
    }

    actions = [
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }

  # ------------------------------------------------
  # Secrets Manager
  # ------------------------------------------------
  statement {
    sid    = "AllowSecretsManagerUse"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "secretsmanager.amazonaws.com"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "secretsmanager.${data.aws_region.current.region}.amazonaws.com"
      ]
    }
  }

  # ------------------------------------------------
  # S3
  # ------------------------------------------------
  statement {
    sid    = "AllowS3Use"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "s3.amazonaws.com"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "s3.${data.aws_region.current.region}.amazonaws.com"
      ]
    }
  }
  # ------------------------------------------------
# AWS Config
# ------------------------------------------------
statement {
  sid    = "AllowAWSConfigUse"
  effect = "Allow"

  principals {
    type = "Service"

    identifiers = [
      "config.amazonaws.com"
    ]
  }

  actions = [
    "kms:Encrypt",
    "kms:Decrypt",
    "kms:GenerateDataKey*",
    "kms:DescribeKey"
  ]

  resources = ["*"]

  condition {
    test     = "StringEquals"
    variable = "AWS:SourceAccount"

    values = [
      data.aws_caller_identity.current.account_id
    ]
  }
}

  # ------------------------------------------------
  # RDS
  # ------------------------------------------------
  statement {
    sid    = "AllowRDSUse"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "rds.amazonaws.com"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "rds.${data.aws_region.current.region}.amazonaws.com"
      ]
    }
  }
}

resource "aws_kms_key" "this" {
  description             = "${var.project_name}-${var.environment}-data"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.this.json

  tags = {
    Name        = "${var.project_name}-${var.environment}-data-kms"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project_name}-${var.environment}-data"
  target_key_id = aws_kms_key.this.key_id
}