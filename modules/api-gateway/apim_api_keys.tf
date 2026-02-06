# ============================================================================
# API KEYS PARA BANCOS
# Costo: 4 API Keys × $0.40/mes = $1.60/mes (Secrets Manager)
# ============================================================================

# Generar API Keys para cada banco
resource "aws_apigatewayv2_api_key" "banco_api_keys" {
  for_each = toset(["ArcBank", "Bantec", "Nexus", "Ecusol"])
  name     = "${each.key}-API-Key-${var.environment}"
  enabled  = true

  tags = merge(var.common_tags, {
    Name  = "${each.key}-API-Key"
    Banco = each.key
  })
}

# Crear Usage Plan con rate limiting
resource "aws_apigatewayv2_usage_plan" "banco_usage_plan" {
  name        = "banco-usage-plan-${var.environment}"
  description = "Plan de uso para bancos - Rate limiting y quotas"

  api_stages {
    api_id = aws_apigatewayv2_api.apim_gateway.id
    stage  = aws_apigatewayv2_stage.apim_stage.id
  }

  quota_settings {
    limit  = 100000  # 100K transacciones por mes
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = 100  # Máximo ráfaga
    rate_limit  = 50   # Requests por segundo
  }

  tags = merge(var.common_tags, {
    Name = "banco-usage-plan"
  })
}

# Asociar API Keys con Usage Plan
resource "aws_apigatewayv2_usage_plan_key" "banco_usage_plan_keys" {
  for_each      = aws_apigatewayv2_api_key.banco_api_keys
  key_id        = each.value.id
  key_type      = "API_KEY"
  usage_plan_id = aws_apigatewayv2_usage_plan.banco_usage_plan.id
}

# ============================================================================
# GUARDAR API KEYS EN SECRETS MANAGER
# Costo: $0.40/mes por secret × 4 bancos = $1.60/mes
# ============================================================================

resource "aws_secretsmanager_secret" "banco_api_keys_secrets" {
  for_each    = toset(["ArcBank", "Bantec", "Nexus", "Ecusol"])
  name        = "apim/api-keys/${lower(each.key)}-key"
  description = "API Key para ${each.key} - Acceso al API Gateway"
  
  tags = merge(var.common_tags, {
    Name  = "${each.key}-API-Key-Secret"
    Banco = each.key
  })
}

resource "aws_secretsmanager_secret_version" "banco_api_keys_values" {
  for_each      = aws_apigatewayv2_api_key.banco_api_keys
  secret_id     = aws_secretsmanager_secret.banco_api_keys_secrets[each.key].id
  secret_string = each.value.value
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "banco_api_keys" {
  description = "API Keys para cada banco (usar para entregar a bancos)"
  value = {
    for k, v in aws_apigatewayv2_api_key.banco_api_keys : k => v.value
  }
  sensitive = true
}

output "banco_api_keys_ids" {
  description = "IDs de las API Keys (para gestión en AWS)"
  value = {
    for k, v in aws_apigatewayv2_api_key.banco_api_keys : k => v.id
  }
}

output "banco_api_keys_secrets_arns" {
  description = "ARNs de Secrets Manager donde están guardadas las API Keys"
  value = {
    for k, v in aws_secretsmanager_secret.banco_api_keys_secrets : k => v.arn
  }
}

output "usage_plan_id" {
  description = "ID del Usage Plan para bancos"
  value       = aws_apigatewayv2_usage_plan.banco_usage_plan.id
}
