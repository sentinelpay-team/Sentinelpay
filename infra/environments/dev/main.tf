module "network" {

  source = "../../modules/network"

  project_name = var.project_name

  environment = var.environment

  vpc_cidr = "10.0.0.0/16"

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]

  availability_zones = [
    "eu-west-1a",
    "eu-west-1b"
  ]
}


module "edge" {

  source = "../../modules/edge"

  project_name = var.project_name

  environment = var.environment

  vpc_id = module.network.vpc_id

  public_subnet_ids = module.network.public_subnet_ids

  container_port = 80
}


module "compute" {

  source = "../../modules/compute"

  project_name = var.project_name

  environment = var.environment

  vpc_id = module.network.vpc_id

  private_subnet_ids = module.network.private_subnet_ids

  alb_security_group_id = module.edge.alb_security_group_id

  target_group_arn = module.edge.target_group_arn

  container_image = "nginx:alpine"

  container_port = 80

  desired_count = 1
}
resource "random_password" "database" {
  length  = 32
  special = true

  override_special = "!#$%&*()-_=+[]{}:?"
}
module "security_iam" {
  source = "../../modules/security-iam"

  project_name = var.project_name
  environment  = var.environment
}

module "kms" {
  source = "../../modules/kms"

  project_name = var.project_name
  environment  = var.environment

  kms_admin_role_arns = [
    module.security_iam.kms_admin_role_arn
  ]

  kms_user_role_arns = [
    module.security_iam.kms_user_role_arn
  ]
}
module "rds" {
  source = "../../modules/rds"

  project_name = var.project_name
  environment  = var.environment

  vpc_id = module.network.vpc_id

  private_subnet_ids = module.network.private_subnet_ids

  application_security_group_id = (
    module.compute.ecs_security_group_id
  )

  kms_key_arn = module.kms.key_arn

  db_name     = "sentinelpay"
  db_username = "sentinelpay_admin"
  db_password = random_password.database.result
}

module "secrets_rotation" {
  source = "../../modules/secrets-rotation"

  project_name = var.project_name
  environment  = var.environment

  vpc_id = module.network.vpc_id

  private_subnet_ids = module.network.private_subnet_ids

  rds_security_group_id = module.rds.security_group_id

  kms_key_arn = module.kms.key_arn

  db_host = module.rds.endpoint
  db_port = module.rds.port

  db_name     = "sentinelpay"
  db_username = "sentinelpay_admin"
  db_password = random_password.database.result

  rotation_lambda_zip = (
    "${path.root}/../../lambda/postgres-rotation.zip"
  )
}

module "identity_center" {
  source = "../../modules/identity-center"

  project_name = var.project_name
}

data "aws_caller_identity" "current" {}

locals {
  github_deployment_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ECRAuthentication"
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      {
        Sid    = "ECRRepositoryAccess"
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]

        Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-*"
      },

      {
        Sid    = "ECSDeployment"
        Effect = "Allow"

        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ]

        Resource = "*"
      }
    ]
  })
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  project_name = var.project_name
  environment  = var.environment

  github_organization = var.github_organization
  github_repository   = var.github_repository
  github_branch       = var.github_branch

  deployment_policy_json = (
    local.github_deployment_policy
  )
}
module "data" {
  source = "../../modules/data"

  project_name = var.project_name
  environment  = var.environment

  vpc_id = module.network.vpc_id

  private_subnet_ids = module.network.private_subnet_ids

  application_security_group_id = module.compute.ecs_security_group_id

  kms_key_arn = module.kms.key_arn
}

module "detection" {
  source = "../../modules/detection"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_id = module.network.vpc_id

  kms_key_arn = module.kms.key_arn

  cloudtrail_retention_days = 365

  enable_eks_guardduty = false
}