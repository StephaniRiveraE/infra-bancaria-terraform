# Variables principales
variable "aws_region" {
  description = "Región de AWS"
  type        = string
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}

# Variables de CloudWatch
variable "apim_log_retention_days" {
  description = "Días de retención para logs de CloudWatch del APIM"
  type        = number
}

variable "apim_alarm_sns_topic_arn" {
  description = "ARN del SNS Topic para enviar alarmas del APIM (opcional)"
  type        = string
}

# Variables de mTLS
variable "apim_domain_name" {
  description = "Dominio personalizado para el API Gateway (requerido para mTLS)"
  type        = string
}

variable "apim_enable_custom_domain" {
  description = "Habilitar Custom Domain con mTLS"
  type        = bool
}

# Variables de rutas
variable "apim_backend_port" {
  description = "Puerto del backend"
  type        = number
}

variable "apim_integration_timeout_ms" {
  description = "Timeout de integración con backend (ms)"
  type        = number
}

# Variables de Circuit Breaker
variable "apim_circuit_breaker_error_threshold" {
  description = "Errores 5xx para abrir circuit breaker"
  type        = number
}

variable "apim_circuit_breaker_latency_threshold_ms" {
  description = "Latencia máxima (ms) antes de abrir circuit breaker"
  type        = number
}

variable "apim_circuit_breaker_cooldown_seconds" {
  description = "Tiempo de enfriamiento (segundos)"
  type        = number
}

# Variables de Networking (recibidas del módulo networking)
variable "vpc_id" {
  description = "ID de la VPC (desde módulo networking)"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block de la VPC (desde módulo networking)"
  type        = string
}

variable "private_subnet_az1_id" {
  description = "ID de la subnet privada en AZ1 (desde módulo networking)"
  type        = string
}

variable "private_subnet_az2_id" {
  description = "ID de la subnet privada en AZ2 (desde módulo networking)"
  type        = string
}
