# ============================================================================
# OUTPUTS GLOBALES
# Infraestructura Bancaria - Outputs de todos los módulos
# ============================================================================

# Outputs de Networking
output "vpc_id" {
  description = "ID de la VPC principal"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  value       = [module.networking.private_subnet_az1_id, module.networking.private_subnet_az2_id]
}

# Outputs de IAM
output "eks_cluster_role_arn" {
  description = "ARN del rol del clúster EKS"
  value       = module.iam.eks_cluster_role_arn
}

output "fargate_execution_role_arn" {
  description = "ARN del rol de ejecución de Fargate"
  value       = module.iam.fargate_execution_role_arn
}

# Outputs de Storage
output "ecr_repository_urls" {
  description = "URLs de los repositorios ECR"
  value       = module.storage.ecr_repository_urls
}

# Outputs de Databases
output "rds_endpoints" {
  description = "Endpoints de las instancias RDS"
  value       = module.databases.rds_endpoints
}

output "rds_secret_arns" {
  description = "ARNs de los secretos en Secrets Manager"
  value       = module.databases.rds_secret_arns
  sensitive   = true
}

output "dynamodb_table_names" {
  description = "Nombres de las tablas DynamoDB"
  value       = module.databases.dynamodb_table_names
}

# Outputs de Messaging
output "sqs_main_queue_url" {
  description = "URL de la cola principal SQS"
  value       = module.messaging.sqs_main_queue_url
}

# NOTA: Los outputs de api-gateway y security-certs se definen
# directamente en sus archivos .tf dentro de modules/api-gateway/ y modules/security-certs/
