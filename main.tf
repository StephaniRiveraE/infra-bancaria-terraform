
module "networking" {
  source = "./modules/networking"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  common_tags        = var.common_tags
  eks_enabled        = var.eks_enabled 
}


module "iam" {
  source = "./modules/iam"

  common_tags = var.common_tags
}

module "storage" {
  source = "./modules/storage"

  bancos      = var.bancos
  common_tags = var.common_tags
}

module "databases" {
  source = "./modules/databases"

  entidades          = var.entidades
  bancos             = var.bancos
  rds_instance_class = var.rds_instance_class
  rds_storage_gb     = var.rds_storage_gb
  rds_engine_version = var.rds_engine_version
  rds_username       = var.rds_username
  common_tags        = var.common_tags

  db_subnet_group_name  = module.networking.db_subnet_group_name
  rds_security_group_id = module.networking.rds_security_group_id

  elasticache_enabled = var.elasticache_enabled
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = [module.networking.private_subnet_az1_id, module.networking.private_subnet_az2_id]
}

module "messaging" {
  source = "./modules/messaging"

  common_tags = var.common_tags
}

module "compute" {
  source = "./modules/compute"

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = [module.networking.private_subnet_az1_id, module.networking.private_subnet_az2_id]
  public_subnet_ids  = [module.networking.public_subnet_az1_id, module.networking.public_subnet_az2_id]

  eks_cluster_role_arn       = module.iam.eks_cluster_role_arn
  fargate_execution_role_arn = module.iam.fargate_execution_role_arn

  common_tags            = var.common_tags
  eks_enabled            = var.eks_enabled
  eks_log_retention_days = var.eks_log_retention_days
  cicd_user_arn          = module.iam.cicd_user_arn
}

module "security_identity" {
  source = "./modules/security-certs"

  project_name = "Digiconecu"
  environment  = var.environment
  common_tags  = var.common_tags
}

module "observability" {
  source = "./modules/observability"

  common_tags   = var.common_tags
  environment   = var.environment
  alarm_email   = var.alarm_email
  enable_alarms = var.enable_alarms

  api_gateway_id    = ""
  api_gateway_stage = var.environment

  eks_enabled                   = var.eks_enabled
  eks_cluster_name              = var.eks_enabled ? module.compute.cluster_name : "eks-banca-ecosistema"
  enable_eks_container_insights = var.enable_eks_container_insights
}

module "api_gateway" {
  source = "./modules/api-gateway"

  project_name = "Digiconecu"
  environment  = var.environment
  common_tags  = var.common_tags

  vpc_id                          = module.networking.vpc_id
  private_subnet_ids              = [module.networking.private_subnet_az1_id, module.networking.private_subnet_az2_id]
  backend_security_group_id       = module.networking.backend_sg_id
  apim_vpc_link_security_group_id = module.networking.apim_vpc_link_sg_id
  cognito_endpoint      = module.security_identity.cognito_endpoint
  cognito_client_ids    = module.security_identity.cognito_client_ids
  internal_secret_value = module.security_identity.internal_secret_value

  apim_alarm_sns_topic_arn = module.observability.sns_alarms_topic_arn

  depends_on = [module.observability]
}

module "aws_credits" {
  source = "./aws_credits"
}

# ============================================================================
# Import de rutas APIM creadas manualmente via AWS CLI (one-time sync)
# Esto sincroniza el state de Terraform con los recursos existentes en AWS.
# Una vez que terraform apply se ejecute exitosamente, estos bloques import
# pueden ser removidos ya que los recursos quedarán en el state.
# ============================================================================
import {
  to = module.api_gateway.aws_apigatewayv2_route.admin_instituciones_get
  id = "gf0js7uezg/3yzndfi"
}

import {
  to = module.api_gateway.aws_apigatewayv2_route.admin_instituciones_post
  id = "gf0js7uezg/u5ehyrp"
}

import {
  to = module.api_gateway.aws_apigatewayv2_route.admin_ledger_cuentas
  id = "gf0js7uezg/a8s0not"
}

import {
  to = module.api_gateway.aws_apigatewayv2_route.admin_funding_recharge
  id = "gf0js7uezg/zocmfeh"
}
