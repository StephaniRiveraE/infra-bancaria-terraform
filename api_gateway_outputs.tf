# =============================================================================
# API GATEWAY - Outputs del Módulo
# =============================================================================
# Valores de salida para uso externo y referencia
# =============================================================================

# -----------------------------------------------------------------------------
# API Gateway Outputs
# -----------------------------------------------------------------------------

output "api_gateway_id" {
  description = "ID del API Gateway REST API"
  value       = aws_api_gateway_rest_api.bancario.id
}

output "api_gateway_arn" {
  description = "ARN del API Gateway REST API"
  value       = aws_api_gateway_rest_api.bancario.arn
}

output "api_gateway_execution_arn" {
  description = "Execution ARN del API Gateway"
  value       = aws_api_gateway_rest_api.bancario.execution_arn
}

# -----------------------------------------------------------------------------
# URLs de Invocación
# -----------------------------------------------------------------------------

output "api_invoke_url" {
  description = "URL base para invocar el API Gateway"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "bank_endpoints" {
  description = "URLs de endpoints por banco"
  value = {
    for bank_key, bank in var.banks : bank_key => {
      base_url = "${aws_api_gateway_stage.prod.invoke_url}/${bank_key}"
      endpoints = [
        for ep in var.bank_endpoints : "${aws_api_gateway_stage.prod.invoke_url}/${bank_key}/${ep}"
      ]
    }
  }
}

output "switch_endpoints" {
  description = "URLs de endpoints del Switch"
  value = {
    base_url = "${aws_api_gateway_stage.prod.invoke_url}/switch"
    endpoints = {
      for ep in var.switch_endpoints : ep.path => {
        url    = "${aws_api_gateway_stage.prod.invoke_url}/switch/${ep.path}"
        method = ep.method
      }
    }
  }
}

# -----------------------------------------------------------------------------
# API Keys (valor sensible - solo IDs)
# -----------------------------------------------------------------------------

output "bank_api_key_ids" {
  description = "IDs de las API Keys por banco (para referencia)"
  value = {
    for bank_key, key in aws_api_gateway_api_key.bank : bank_key => key.id
  }
}

output "switch_api_key_id" {
  description = "ID de la API Key del Switch"
  value       = aws_api_gateway_api_key.switch.id
}

# Nota: Para obtener el valor de la API Key, usar:
# aws apigateway get-api-key --api-key <key-id> --include-value

# -----------------------------------------------------------------------------
# Usage Plans
# -----------------------------------------------------------------------------

output "bank_usage_plan_ids" {
  description = "IDs de los Usage Plans por banco"
  value = {
    for bank_key, plan in aws_api_gateway_usage_plan.bank : bank_key => plan.id
  }
}

output "switch_usage_plan_id" {
  description = "ID del Usage Plan del Switch"
  value       = aws_api_gateway_usage_plan.switch.id
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

output "cloudwatch_log_group" {
  description = "Nombre del Log Group de CloudWatch"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

output "cloudwatch_dashboard_url" {
  description = "URL del Dashboard de CloudWatch"
  value       = "https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#dashboards:name=${aws_cloudwatch_dashboard.api_usage.dashboard_name}"
}

# -----------------------------------------------------------------------------
# Información para documentación
# -----------------------------------------------------------------------------

output "api_usage_info" {
  description = "Información de uso del API para documentación"
  value = {
    api_name   = var.api_gateway_name
    stage      = var.stage_name
    region     = "us-east-2"
    header_key = "x-api-key"
    example_curl = "curl -X POST ${aws_api_gateway_stage.prod.invoke_url}/arcbank/endpoint1 -H 'x-api-key: <YOUR_API_KEY>'"
  }
}
