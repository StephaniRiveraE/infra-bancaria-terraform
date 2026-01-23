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

# NOTA: Los módulos api-gateway y security-certs NO se llaman aquí
# porque sus archivos .tf originales YA TIENEN las variables definidas
# internamente y se ejecutan directamente sin necesidad de module block.
