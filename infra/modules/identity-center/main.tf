data "aws_ssoadmin_instances" "this" {}

locals {
  identity_center_instance_arn = tolist(
    data.aws_ssoadmin_instances.this.arns
  )[0]
}

resource "aws_ssoadmin_permission_set" "developer" {
  name         = "${var.project_name}-Developer"
  description  = "Read-only developer access for ${var.project_name}"
  instance_arn = local.identity_center_instance_arn

  session_duration = var.session_duration

  tags = {
    Name        = "${var.project_name}-Developer"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "developer" {
  instance_arn       = local.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_ssoadmin_permission_set" "administrator" {
  # checkov:skip=CKV_AWS_274:Administrative permission set is intentionally reserved for privileged break-glass/platform administration; least-privilege user access is provided separately.

  name         = "${var.project_name}-Administrator"
  description  = "Administrative access for ${var.project_name}"
  instance_arn = local.identity_center_instance_arn

  session_duration = var.session_duration

  tags = {
    Name        = "${var.project_name}-Administrator"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator" {
  # checkov:skip=CKV_AWS_274:AdministratorAccess is intentionally restricted to the privileged administrative Identity Center permission set.

  instance_arn       = local.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.administrator.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}