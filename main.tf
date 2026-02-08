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
  eks_enabled        = var.eks_enabled # Controla creación de NAT Gateway
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

# Módulo 4: Databases (RDS PostgreSQL, DynamoDB, ElastiCache)
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
  db_subnet_group_name  = module.networking.db_subnet_group_name
  rds_security_group_id = module.networking.rds_security_group_id

  # ElastiCache (Redis) - Condicional
  elasticache_enabled = var.elasticache_enabled
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = [module.networking.private_subnet_az1_id, module.networking.private_subnet_az2_id]
}

# Módulo 5: Messaging (Amazon MQ - RabbitMQ)
# NOTA: Broker público, no requiere VPC ni subnet (AWS lo maneja)
module "messaging" {
  source = "./modules/messaging"

  common_tags = var.common_tags
}

# ============================================================================
# Módulo 6: Compute (EKS + Fargate) - FASE 3
# Clúster de Kubernetes con Fargate para los 4 bancos + Switch
# ============================================================================
module "compute" {
  source = "./modules/compute"

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = [module.networking.private_subnet_az1_id, module.networking.private_subnet_az2_id]
  public_subnet_ids  = [module.networking.public_subnet_az1_id, module.networking.public_subnet_az2_id]

  eks_cluster_role_arn       = module.iam.eks_cluster_role_arn
  fargate_execution_role_arn = module.iam.fargate_execution_role_arn

  common_tags            = var.common_tags
  eks_enabled            = var.eks_enabled            # Controla creación del stack EKS
  eks_log_retention_days = var.eks_log_retention_days # Días de retención de logs
}

# ============================================================================
# Módulo 7: Seguridad e Identidad (Cognito) - FASE 4
# ============================================================================
module "security_identity" {
  source = "./modules/security-certs"

  project_name = "Digiconecu"
  environment  = var.environment
  common_tags  = var.common_tags
}

# ============================================================================
# Módulo 8: Observabilidad (CloudWatch Dashboards, Alarmas, SNS) - FASE 5
# NOTA: Debe crearse ANTES de api_gateway para poder pasar el SNS ARN
# ============================================================================
module "observability" {
  source = "./modules/observability"

  common_tags   = var.common_tags
  environment   = var.environment
  alarm_email   = var.alarm_email
  enable_alarms = var.enable_alarms

  # Variables para métricas - se configuran después con depends_on
  api_gateway_id    = "" # Se actualiza manualmente o con un segundo apply
  api_gateway_stage = var.environment

  # Variables para Container Insights (EKS)
  eks_enabled      = var.eks_enabled
  eks_cluster_name = var.eks_enabled ? module.compute.cluster_name : "eks-banca-ecosistema"
}

# ============================================================================
# Módulo 9: API Gateway (Switch Transaccional) - FASE 4
# Recibe el SNS Topic de observability para conectar el Circuit Breaker
# ============================================================================
module "api_gateway" {
  source = "./modules/api-gateway"

  # Variables Generales
  project_name = "Digiconecu"
  environment  = var.environment
  common_tags  = var.common_tags

  # Variables de Red (Desde el modulo networking)
  vpc_id                          = module.networking.vpc_id
  private_subnet_ids              = [module.networking.private_subnet_az1_id, module.networking.private_subnet_az2_id]
  backend_security_group_id       = module.networking.backend_sg_id
  apim_vpc_link_security_group_id = module.networking.apim_vpc_link_sg_id

  # Variables de Seguridad (Desde el modulo security_identity)
  cognito_endpoint      = module.security_identity.cognito_endpoint
  cognito_client_ids    = module.security_identity.cognito_client_ids
  internal_secret_value = module.security_identity.internal_secret_value

  # Conexión con Observability - SNS para Circuit Breaker
  apim_alarm_sns_topic_arn = module.observability.sns_alarms_topic_arn

  depends_on = [module.observability]
}
