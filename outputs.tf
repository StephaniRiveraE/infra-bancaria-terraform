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

# Outputs de API Gateway
output "apim_gateway_endpoint" {
  description = "Endpoint HTTPS del API Gateway"
  value       = module.api_gateway.apim_gateway_endpoint
}

output "apim_backend_alb_dns" {
  description = "DNS del ALB del backend"
  value       = module.api_gateway.apim_backend_alb_dns
}

output "apim_backend_target_group_arn" {
  description = "ARN del Target Group (para registrar instancias del backend)"
  value       = module.api_gateway.apim_backend_target_group_arn
}

output "circuit_breaker_sns_topic_arn" {
  description = "ARN del SNS Topic para alertas del Circuit Breaker"
  value       = module.api_gateway.circuit_breaker_sns_topic_arn
}
