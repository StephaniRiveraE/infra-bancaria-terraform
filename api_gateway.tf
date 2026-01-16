# =============================================================================
# API GATEWAY MODULE - Llamada desde raíz
# =============================================================================
# Este archivo invoca el módulo api_gateway para crear la infraestructura
# =============================================================================

module "api_gateway" {
  source = "./api_gateway"

  # Configuración del API Gateway
  api_gateway_name        = "ecosistema-bancario-api"
  api_gateway_description = "API Gateway centralizado para el ecosistema bancario DigiConecu"
  stage_name              = "prod"

  # Configuración de bancos (heredada de fargate_profiles)
  banks = {
    arcbank = {
      name         = "ARCBANK"
      description  = "API para ARCBANK - Banco digital"
      rate_limit   = 100
      burst_limit  = 200
      quota_limit  = 100000
      quota_period = "MONTH"
    }
    bantec = {
      name         = "BANTEC"
      description  = "API para BANTEC - Banco digital"
      rate_limit   = 100
      burst_limit  = 200
      quota_limit  = 100000
      quota_period = "MONTH"
    }
    nexus = {
      name         = "NEXUS"
      description  = "API para NEXUS - Banco digital"
      rate_limit   = 50
      burst_limit  = 100
      quota_limit  = 50000
      quota_period = "MONTH"
    }
    ecusol = {
      name         = "ECUSOL"
      description  = "API para ECUSOL - Banco digital"
      rate_limit   = 100
      burst_limit  = 200
      quota_limit  = 100000
      quota_period = "MONTH"
    }
  }

  # Configuración del Switch
  switch_config = {
    name         = "DigiConecu-Switch"
    description  = "Switch interbancario DigiConecu"
    rate_limit   = 200
    burst_limit  = 500
    quota_limit  = 500000
    quota_period = "MONTH"
  }

  # Endpoints placeholder (se configurarán después)
  bank_endpoints = ["endpoint1", "endpoint2", "endpoint3"]

  # Endpoints del Switch
  switch_endpoints = [
    { path = "transferencia", method = "POST" },
    { path = "status",        method = "GET" },
    { path = "validar",       method = "POST" }
  ]

  # Tags comunes
  common_tags = {
    Environment = "production"
    Project     = "ecosistema-bancario"
    ManagedBy   = "terraform"
    Component   = "api-gateway"
  }
}

# -----------------------------------------------------------------------------
# Outputs del módulo (expuestos a nivel raíz)
# -----------------------------------------------------------------------------

output "api_gateway_invoke_url" {
  description = "URL base del API Gateway"
  value       = module.api_gateway.api_invoke_url
}

output "api_gateway_endpoints_por_banco" {
  description = "Endpoints disponibles por banco"
  value       = module.api_gateway.bank_endpoints
}

output "api_gateway_endpoints_switch" {
  description = "Endpoints del Switch"
  value       = module.api_gateway.switch_endpoints
}

output "api_gateway_dashboard" {
  description = "URL del dashboard de CloudWatch para monitoreo"
  value       = module.api_gateway.cloudwatch_dashboard_url
}

output "api_gateway_info" {
  description = "Información general del API Gateway"
  value       = module.api_gateway.api_usage_info
}
