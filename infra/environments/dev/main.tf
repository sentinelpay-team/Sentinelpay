module "network" {
  source = "../../modules/network"

  project_name = var.project_name
  environment  = var.environment

  vpc_cidr             = var.vpc_cidr
  aws_region           = var.aws_region
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones

  kms_key_arn = module.kms.key_arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "edge" {
  source = "../../modules/edge"

  project_name = var.project_name
  environment  = var.environment

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  vpc_id   = module.network.vpc_id
  vpc_cidr = var.vpc_cidr

  public_subnet_ids = module.network.public_subnet_ids

  payments_container_port = var.payments_container_port
  kyc_container_port      = var.kyc_container_port

  payments_health_check_path = "/health"
  kyc_health_check_path      = "/health"

  payments_rate_limit = 1000

  acm_certificate_arn = var.acm_certificate_arn

  alb_logs_bucket = module.data.access_logs_bucket_name

  kms_key_arn = module.kms.key_arn

  depends_on = [
    module.data
  ]
}

module "compute" {
  source = "../../modules/compute"

  project_name      = var.project_name
  environment       = var.environment
  name_prefix       = "${var.project_name}-${var.environment}"
  s3_prefix_list_id = module.network.s3_prefix_list_id

  vpc_id             = module.network.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.network.private_subnet_ids

  alb_security_group_id = module.edge.alb_security_group_id
  alb_listener_arn      = module.edge.listener_arn

  payments_target_group_arn = module.edge.payments_target_group_arn
  kyc_target_group_arn      = module.edge.kyc_target_group_arn

  payments_container_image = var.payments_container_image
  payments_container_port  = var.payments_container_port
  payments_desired_count   = var.payments_desired_count

  kyc_container_image = var.kyc_container_image
  kyc_container_port  = var.kyc_container_port
  kyc_desired_count   = var.kyc_desired_count

  jwt_private_secret_name     = "sentinelpay/dev/jwt/private"
  jwt_public_secret_name      = "sentinelpay/dev/jwt/public"
  rate_limit_secret_name      = "sentinelpay/dev/rate-limit-key"
  session_signing_secret_name = "sentinelpay/dev/session-signing-key"
  kyc_bucket_name             = module.data.kyc_bucket_name
  database_secret_arn         = module.secrets_rotation.secret_arn
  redis_endpoint              = module.data.redis_endpoint
  redis_port                  = module.data.redis_port
  redis_secret_arn            = module.data.redis_secret_arn

  kms_key_arn = module.kms.key_arn
  aws_region  = var.aws_region

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "security_iam" {
  source = "../../modules/security-iam"

  project_name = var.project_name
  environment  = var.environment
}

module "identity_center" {
  source = "../../modules/identity-center"

  project_name = var.project_name
  environment  = var.environment

  session_duration = "PT4H"
}

module "kms" {
  source = "../../modules/kms"

  project_name = var.project_name
  environment  = var.environment

  kms_admin_role_arns = [
    module.security_iam.kms_admin_role_arn
  ]

  kms_user_role_arns = [
    module.security_iam.kms_user_role_arn,
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-ecs-execution-role"
  ]
}

resource "random_password" "database" {
  length  = 32
  special = true
}

module "rds" {
  source = "../../modules/rds"

  project_name = var.project_name
  environment  = var.environment

  vpc_id = module.network.vpc_id

  private_subnet_ids = module.network.private_subnet_ids

  application_security_group_id = module.compute.ecs_security_group_id

  kms_key_arn = module.kms.key_arn

  db_name     = "sentinelpay"
  db_username = "sentinelpay_admin"
  db_password = random_password.database.result

  instance_class                  = "db.t4g.micro"
  postgres_version                = "17"
  postgres_parameter_group_family = "postgres17"

  allocated_storage     = 20
  max_allocated_storage = 100

  backup_retention_period = 7
  multi_az                = true
}



module "secrets_rotation" {
  source = "../../modules/secrets-rotation"

  project_name = var.project_name
  environment  = var.environment

  vpc_id   = module.network.vpc_id
  vpc_cidr = var.vpc_cidr

  private_subnet_ids = module.network.private_subnet_ids

  rds_security_group_id = module.rds.security_group_id

  kms_key_arn = module.kms.key_arn

  database_host                = module.rds.address
  database_name                = "sentinelpay"
  database_username            = "sentinelpay_admin"
  database_password            = random_password.database.result
  database_port                = 5432
  database_instance_identifier = module.rds.identifier

  rotation_lambda_zip = "${path.root}/../../lambda/postgres-rotation.zip"
}
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

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
        Sid    = "ECRImageManagement"
        Effect = "Allow"

        Action = [
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]

        Resource = [
          "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-${var.environment}-payments-api",
          "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-${var.environment}-kyc-api"
        ]
      },
      {
        Sid    = "ECSDeploy"
        Effect = "Allow"

        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]

        Resource = [
          "arn:aws:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:service/${var.project_name}-${var.environment}/*"
        ]
      },
      {
        Sid    = "ECSTaskDefinitionManagement"
        Effect = "Allow"

        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition"
        ]

        Resource = "*"
      },
      {
        Sid    = "PassECSTaskRoles"
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-payments-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-kyc-*"
        ]

        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  project_name        = var.project_name
  environment         = var.environment
  github_organization = var.github_organization
  github_repository   = var.github_repository

  deployment_policy_json = local.github_deployment_policy
}

module "data" {
  source = "../../modules/data"

  project_name = var.project_name
  environment  = var.environment

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  application_security_group_id = module.compute.ecs_security_group_id

  kms_key_arn = module.kms.key_arn

  kyc_retention_days = 90

  redis_node_type = "cache.t4g.micro"

  redis_rotation_lambda_arn = null
}

module "detection" {
  source = "../../modules/detection"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_id = module.network.vpc_id

  kms_key_arn = module.kms.key_arn

  cloudtrail_retention_days = 365
  private_subnet_ids        = module.network.private_subnet_ids
  enable_eks_guardduty      = false

  depends_on = [
    module.kms
  ]
}