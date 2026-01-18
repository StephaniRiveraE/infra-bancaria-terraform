# =============================================================================
# APIM VARIABLES - Variables para API Gateway (Brayan)
# =============================================================================

# -----------------------------------------------------------------------------
# Variables Generales
# -----------------------------------------------------------------------------
variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "apim_backend_base_url" {
  description = "URL base del backend interno (Core del Switch)"
  type        = string
  default     = "http://backend.internal:8080"
}

# -----------------------------------------------------------------------------
# Rate Limiting (ERS: 50-100 TPS)
# -----------------------------------------------------------------------------
variable "apim_rate_limit_per_second" {
  description = "Límite de TPS sostenidos por endpoint"
  type        = number
  default     = 50 # ERS: 50 TPS sostenidos
}

variable "apim_rate_limit_burst" {
  description = "Límite de pico de TPS por endpoint"
  type        = number
  default     = 100 # ERS: escalable a 100 TPS
}

variable "apim_waf_rate_limit_per_ip" {
  description = "Límite de requests por IP en WAF (5 minutos)"
  type        = number
  default     = 2000
}

# -----------------------------------------------------------------------------
# Circuit Breaker (ERS: 5 errores, 4s latencia, 30s cooldown)
# -----------------------------------------------------------------------------
variable "apim_circuit_breaker_error_threshold" {
  description = "Errores 5xx para abrir circuit breaker"
  type        = number
  default     = 5
}

variable "apim_circuit_breaker_latency_threshold_ms" {
  description = "Latencia máxima (ms) antes de abrir circuit breaker"
  type        = number
  default     = 4000 # 4 segundos
}

variable "apim_circuit_breaker_cooldown_seconds" {
  description = "Tiempo de enfriamiento (segundos)"
  type        = number
  default     = 30
}

# -----------------------------------------------------------------------------
# Timeout
# -----------------------------------------------------------------------------
variable "apim_integration_timeout_ms" {
  description = "Timeout de integración con backend (ms)"
  type        = number
  default     = 29000 # 29 segundos (máximo API Gateway)
}
