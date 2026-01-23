# ============================================================================
# MAIN TERRAFORM CONFIGURATION
# Infraestructura Bancaria - 4 Bancos Core + Switch DIGICONECU
# ============================================================================

# Módulo 1: Networking (VPC, Subnets, NAT Gateway, Security Groups)
module "networking" {
  source = "./modules/networking"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  common_tags        = var.common_tags
}

# Módulo 2: IAM Roles (EKS Cluster, Fargate Execution)
module "iam" {
  source = "./modules/iam"

  common_tags = var.common_tags
}

# Módulo 3: Storage (ECR, S3 Buckets)
module "storage" {
  source = "./modules/storage"

  bancos      = var.bancos
  common_tags = var.common_tags
}

# Módulo 4: Databases (RDS PostgreSQL, DynamoDB)
module "databases" {
  source = "./modules/databases"

  entidades          = var.entidades
  bancos             = var.bancos
  rds_instance_class = var.rds_instance_class
  rds_storage_gb     = var.rds_storage_gb
  rds_engine_version = var.rds_engine_version
  rds_username       = var.rds_username
  common_tags        = var.common_tags

  # Dependencias de Networking
  db_subnet_group_name = module.networking.db_subnet_group_name
  rds_security_group_id = module.networking.rds_security_group_id
}

# Módulo 5: Messaging (SQS)
module "messaging" {
  source = "./modules/messaging"

  common_tags = var.common_tags
}

# Módulo 6: Security Certificates (Secrets Manager, Dummy Certs)
module "security_certs" {
  source = "./modules/security-certs"

  banks       = var.bancos
  common_tags = var.common_tags
}

# Módulo 7: API Gateway (APIM, mTLS, Circuit Breaker, CloudWatch)
module "api_gateway" {
  source = "./modules/api-gateway"

  aws_region                              = var.aws_region
  environment                             = var.environment
  common_tags                             = var.common_tags
  project_name                            = var.project_name
  apim_log_retention_days                 = var.apim_log_retention_days
  apim_alarm_sns_topic_arn                = var.apim_alarm_sns_topic_arn
  apim_domain_name                        = var.apim_domain_name
  apim_enable_custom_domain               = var.apim_enable_custom_domain
  apim_backend_port                       = var.apim_backend_port
  apim_integration_timeout_ms             = var.apim_integration_timeout_ms
  apim_circuit_breaker_error_threshold    = var.apim_circuit_breaker_error_threshold
  apim_circuit_breaker_latency_threshold_ms = var.apim_circuit_breaker_latency_threshold_ms
  apim_circuit_breaker_cooldown_seconds   = var.apim_circuit_breaker_cooldown_seconds

  # Dependencias de Networking
  vpc_id              = module.networking.vpc_id
  vpc_cidr_block      = module.networking.vpc_cidr_block
  private_subnet_az1_id = module.networking.private_subnet_az1_id
  private_subnet_az2_id = module.networking.private_subnet_az2_id
}
