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

# Outputs de Messaging (Amazon MQ - RabbitMQ)
output "rabbitmq_console_url" {
  description = "URL de la consola web de RabbitMQ (para administrar colas)"
  value       = module.messaging.rabbitmq_console_url
}

output "rabbitmq_amqps_endpoint" {
  description = "Endpoint AMQPS para conexion desde microservicios"
  value       = module.messaging.rabbitmq_amqps_endpoint
}

output "rabbitmq_username" {
  description = "Usuario admin de RabbitMQ"
  value       = module.messaging.rabbitmq_username
}

output "rabbitmq_credentials_secret_arn" {
  description = "ARN del secreto con las credenciales (buscar en Secrets Manager)"
  value       = module.messaging.rabbitmq_credentials_secret_arn
  sensitive   = true
}

# NOTA: Los outputs de api-gateway y security-certs se definen
# directamente en sus archivos .tf dentro de modules/api-gateway/ y modules/security-certs/

# ============================================================================
# Outputs de Compute (EKS + Fargate) - FASE 3
# NOTA: Retornan null cuando eks_enabled = false
# ============================================================================

output "eks_enabled" {
  description = "Indica si el stack de EKS está habilitado (para ahorrar costos se puede poner en false)"
  value       = module.compute.eks_enabled
}

output "eks_cluster_name" {
  description = "Nombre del clúster EKS (null si eks_enabled = false)"
  value       = module.compute.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint del API server de EKS (null si eks_enabled = false)"
  value       = module.compute.cluster_endpoint
}

output "eks_kubeconfig_ca" {
  description = "Certificado CA para kubeconfig (null si eks_enabled = false)"
  value       = module.compute.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "ARN del OIDC provider para IRSA (null si eks_enabled = false)"
  value       = module.compute.oidc_provider_arn
}

output "eks_fargate_profiles" {
  description = "Nombres de los Fargate profiles creados (vacío si eks_enabled = false)"
  value       = module.compute.fargate_profile_names
}

output "eks_alb_controller_role_arn" {
  description = "ARN del rol para AWS Load Balancer Controller (null si eks_enabled = false)"
  value       = module.compute.alb_controller_role_arn
}

output "eks_kubectl_command" {
  description = "Comando para configurar kubectl"
  value       = module.compute.kubectl_config_command
}

# ============================================================================
# Outputs de ElastiCache (Redis) - FASE 2
# ============================================================================

output "elasticache_enabled" {
  description = "Indica si ElastiCache Redis está habilitado (ahorro ~$50/mes cuando está apagado)"
  value       = module.databases.elasticache_enabled
}

output "redis_endpoint" {
  description = "Endpoint del cluster Redis del Switch (vacío si elasticache_enabled = false)"
  value       = module.databases.redis_endpoint
}

# ============================================================================
# Outputs de Observabilidad - FASE 5
# ============================================================================

output "sns_alarms_topic_arn" {
  description = "ARN del topic SNS para alarmas"
  value       = module.observability.sns_alarms_topic_arn
}

output "cloudwatch_dashboard_urls" {
  description = "URLs de los dashboards de CloudWatch"
  value       = module.observability.dashboard_urls
}

output "alarm_count" {
  description = "Número de alarmas CloudWatch creadas"
  value       = module.observability.alarm_count
}

