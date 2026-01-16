# =============================================================================
# API GATEWAY - Variables del Módulo
# =============================================================================
# Configuración de quotas, rate limits y settings por banco
# =============================================================================

variable "api_gateway_name" {
  description = "Nombre del API Gateway"
  type        = string
  default     = "ecosistema-bancario-api"
}

variable "api_gateway_description" {
  description = "Descripción del API Gateway"
  type        = string
  default     = "API Gateway para el ecosistema bancario - Gestión de APIs de bancos y Switch"
}

variable "stage_name" {
  description = "Nombre del stage de deployment"
  type        = string
  default     = "prod"
}

# -----------------------------------------------------------------------------
# Configuración de Bancos
# -----------------------------------------------------------------------------

variable "banks" {
  description = "Lista de bancos con sus configuraciones de API"
  type = map(object({
    name           = string
    description    = string
    rate_limit     = number  # requests por segundo
    burst_limit    = number  # pico máximo de requests
    quota_limit    = number  # requests por período
    quota_period   = string  # DAY, WEEK, MONTH
  }))
  default = {
    arcbank = {
      name         = "ARCBANK"
      description  = "API para ARCBANK"
      rate_limit   = 100
      burst_limit  = 200
      quota_limit  = 100000
      quota_period = "MONTH"
    }
    bantec = {
      name         = "BANTEC"
      description  = "API para BANTEC"
      rate_limit   = 100
      burst_limit  = 200
      quota_limit  = 100000
      quota_period = "MONTH"
    }
    nexus = {
      name         = "NEXUS"
      description  = "API para NEXUS"
      rate_limit   = 50
      burst_limit  = 100
      quota_limit  = 50000
      quota_period = "MONTH"
    }
    ecusol = {
      name         = "ECUSOL"
      description  = "API para ECUSOL"
      rate_limit   = 100
      burst_limit  = 200
      quota_limit  = 100000
      quota_period = "MONTH"
    }
  }
}

# -----------------------------------------------------------------------------
# Configuración del Switch
# -----------------------------------------------------------------------------

variable "switch_config" {
  description = "Configuración del Switch DigiConecu"
  type = object({
    name         = string
    description  = string
    rate_limit   = number
    burst_limit  = number
    quota_limit  = number
    quota_period = string
  })
  default = {
    name         = "DigiConecu-Switch"
    description  = "API del Switch interbancario"
    rate_limit   = 200
    burst_limit  = 500
    quota_limit  = 500000
    quota_period = "MONTH"
  }
}

# -----------------------------------------------------------------------------
# Endpoints placeholder por banco
# -----------------------------------------------------------------------------

variable "bank_endpoints" {
  description = "Endpoints placeholder para cada banco"
  type        = list(string)
  default     = ["endpoint1", "endpoint2", "endpoint3"]
}

# -----------------------------------------------------------------------------
# Endpoints del Switch
# -----------------------------------------------------------------------------

variable "switch_endpoints" {
  description = "Endpoints del Switch"
  type = list(object({
    path   = string
    method = string
  }))
  default = [
    { path = "transferencia", method = "POST" },
    { path = "status",        method = "GET" },
    { path = "validar",       method = "POST" }
  ]
}

# -----------------------------------------------------------------------------
# Tags comunes
# -----------------------------------------------------------------------------

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "ecosistema-bancario"
    ManagedBy   = "terraform"
    Component   = "api-gateway"
  }
}
