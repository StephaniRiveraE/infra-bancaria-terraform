# ============================================================================
# API KEYS OUTPUTS
# ============================================================================

output "banco_api_keys" {
  description = "API Keys para cada banco"
  value       = try(aws_apigatewayv2_api_key.banco_api_keys, null) != null ? { for k, v in aws_apigatewayv2_api_key.banco_api_keys : k => v.value } : {}
  sensitive   = true
}

output "banco_api_keys_secrets_arns" {
  description = "ARNs de Secrets Manager con las API Keys"
  value       = try(aws_secretsmanager_secret.banco_api_keys_secrets, null) != null ? { for k, v in aws_secretsmanager_secret.banco_api_keys_secrets : k => v.arn } : {}
}

output "usage_plan_id" {
  description = "ID del Usage Plan"
  value       = try(aws_apigatewayv2_usage_plan.banco_usage_plan.id, null)
}
