# =========================================================
# GitHub Actions OIDC Provider
# =========================================================

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name        = "${var.project_name}-${var.environment}-github-oidc"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# =========================================================
# GitHub Actions OIDC Trust Policy
#
# Restricts access to:
# - The configured GitHub organisation
# - The configured repository
# - The configured branch
# - Pull requests from the configured repository
# =========================================================

data "aws_iam_policy_document" "github_trust" {
  statement {
    sid    = "GitHubActionsAssumeRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    # -----------------------------------------------------
    # Require the AWS STS audience
    # -----------------------------------------------------

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    # -----------------------------------------------------
    # Restrict token to the configured repository
    #
    # Allows:
    # 1. Configured deployment branch
    # 2. Pull request workflows
    # -----------------------------------------------------

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:${var.github_organization}/${var.github_repository}:ref:refs/heads/${var.github_branch}",
        "repo:${var.github_organization}/${var.github_repository}:pull_request"
      ]
    }
  }
}

# =========================================================
# GitHub Actions IAM Role
# =========================================================

resource "aws_iam_role" "github" {
  name        = "${var.project_name}-${var.environment}-github-actions"
  description = "IAM role assumed by GitHub Actions through OIDC for ${var.project_name} ${var.environment}"

  assume_role_policy = data.aws_iam_policy_document.github_trust.json

  # Limit GitHub Actions credentials to one hour.
  max_session_duration = 3600

  tags = {
    Name        = "${var.project_name}-${var.environment}-github-actions"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# =========================================================
# GitHub Actions Deployment Policy
#
# The actual AWS permissions are supplied through
# deployment_policy_json.
#
# IMPORTANT:
# deployment_policy_json should use specific resource ARNs
# wherever the AWS action supports resource-level permissions.
# =========================================================

resource "aws_iam_role_policy" "deployment" {
  name = "${var.project_name}-${var.environment}-deployment-policy"
  role = aws_iam_role.github.id

  policy = var.deployment_policy_json
}