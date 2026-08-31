data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "this" {

  statement {
    sid    = "EnableAccountRoot"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Administrators manage the key.
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

  # Applications/services use the key.
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
      values   = ["true"]
    }
  }
}

resource "aws_kms_key" "this" {
  description             = "${var.project_name}-${var.environment}-data"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.this.json
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project_name}-${var.environment}-data"
  target_key_id = aws_kms_key.this.key_id
}