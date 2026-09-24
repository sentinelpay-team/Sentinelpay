resource "aws_guardduty_detector" "this" {
  # checkov:skip=CKV2_AWS_3:GuardDuty is enabled directly for this development account; AWS Organizations delegated administration is outside the scope of this standalone environment.
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  tags = {
    Name        = "${var.project_name}-${var.environment}-guardduty"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_guardduty_detector_feature" "s3" {
  detector_id = aws_guardduty_detector.this.id

  name   = "S3_DATA_EVENTS"
  status = "ENABLED"
}

resource "aws_guardduty_detector_feature" "ebs_malware" {
  detector_id = aws_guardduty_detector.this.id

  name   = "EBS_MALWARE_PROTECTION"
  status = "ENABLED"
}

resource "aws_guardduty_detector_feature" "rds" {
  detector_id = aws_guardduty_detector.this.id

  name   = "RDS_LOGIN_EVENTS"
  status = "ENABLED"
}

resource "aws_guardduty_detector_feature" "lambda" {
  detector_id = aws_guardduty_detector.this.id

  name   = "LAMBDA_NETWORK_LOGS"
  status = "ENABLED"
}

resource "aws_guardduty_detector_feature" "eks" {
  count = var.enable_eks_guardduty ? 1 : 0

  detector_id = aws_guardduty_detector.this.id

  name   = "EKS_AUDIT_LOGS"
  status = "ENABLED"
}