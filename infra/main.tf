# ============================================================
# SentinelPay Root Configuration
# ============================================================

# Network
module "networks" {
  source = "./modules/Networks"

  aws_region         = var.aws_region
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# Application Load Balancer
module "edge" {
  source = "./modules/Edge"

  vpc_id            = module.networks.vpc_id
  public_subnet_ids = module.networks.public_subnet_ids
}

# ECS Fargate
module "compute" {
  source = "./modules/Compute"

  vpc_id                = module.networks.vpc_id
  private_subnet_ids    = module.networks.private_subnet_ids
  alb_security_group_id = module.edge.alb_security_group_id
  target_group_arn      = module.edge.target_group_arn
}