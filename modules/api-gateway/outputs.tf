# Outputs de apim.tf
output "apim_gateway_endpoint" {
  description = "Endpoint HTTPS del API Gateway (ya incluye SSL)"
  value       = aws_apigatewayv2_api.apim_gateway.api_endpoint
}

output "apim_gateway_id" {
  description = "ID del API Gateway"
  value       = aws_apigatewayv2_api.apim_gateway.id
}

output "apim_stage_name" {
  description = "Nombre del stage (dev/prod)"
  value       = aws_apigatewayv2_stage.apim_stage.name
}

output "apim_vpc_link_id" {
  description = "ID del VPC Link"
  value       = aws_apigatewayv2_vpc_link.apim_vpc_link.id
}

output "apim_backend_sg_id" {
  description = "Security Group ID del backend"
  value       = aws_security_group.apim_backend_sg.id
}

output "apim_vpc_link_sg_id" {
  description = "Security Group ID del VPC Link"
  value       = aws_security_group.apim_vpc_link_sg.id
}

# Outputs de apim-mtls.tf
output "apim_custom_domain_name" {
  description = "Custom domain para mTLS"
  value       = var.apim_enable_custom_domain ? aws_apigatewayv2_domain_name.apim_custom_domain[0].domain_name : "DISABLED"
}

output "apim_truststore_bucket" {
  description = "Bucket S3 del Truststore"
  value       = aws_s3_bucket.mtls_truststore.id
}

output "apim_certificate_arn" {
  description = "ARN del certificado ACM"
  value       = var.apim_enable_custom_domain ? aws_acm_certificate.apim_cert[0].arn : "DISABLED"
}

# Outputs de apim_routes.tf
output "apim_backend_alb_dns" {
  description = "DNS del ALB del backend"
  value       = aws_lb.apim_backend_alb.dns_name
}

output "apim_backend_target_group_arn" {
  description = "ARN del Target Group"
  value       = aws_lb_target_group.apim_backend_tg.arn
}

# Outputs de apim_circuit_breaker.tf
output "circuit_breaker_sns_topic_arn" {
  description = "ARN del SNS Topic para alertas del Circuit Breaker"
  value       = aws_sns_topic.circuit_breaker_alerts.arn
}

output "circuit_breaker_dynamodb_table" {
  description = "Nombre de la tabla DynamoDB del Circuit Breaker"
  value       = aws_dynamodb_table.circuit_breaker_state.name
}
