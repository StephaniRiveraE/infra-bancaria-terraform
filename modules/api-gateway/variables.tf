variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-2"
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  type        = list(string)
}

variable "backend_security_group_id" {
  description = "ID del Security Group del backend"
  type        = string
}

variable "apim_vpc_link_security_group_id" {
  description = "ID del Security Group para el VPC Link del APIM"
  type        = string
}

variable "cognito_endpoint" {
  description = "Endpoint del User Pool de Cognito"
  type        = string
}

variable "cognito_client_ids" {
  description = "IDs de los clientes de Cognito"
  type        = list(string)
}

variable "internal_secret_value" {
  description = "Valor del secreto interno para comunicación entre servicios"
  type        = string
  sensitive   = true
}

variable "apim_backend_port" {
  description = "Puerto del backend"
  type        = number
  default     = 8080
}

variable "apim_enable_custom_domain" {
  description = "Habilitar Custom Domain con mTLS"
  type        = bool
  default     = false
}

variable "apim_domain_name" {
  description = "Dominio personalizado para el API Gateway"
  type        = string
  default     = ""
}

variable "apim_acm_certificate_arn" {
  description = "ARN del certificado ACM para el dominio personalizado"
  type        = string
  default     = ""
}

variable "apim_log_retention_days" {
  description = "Días de retención para logs de CloudWatch"
  type        = number
  default     = 30
}

variable "apim_alarm_sns_topic_arn" {
  description = "ARN del SNS Topic para alarmas (desde módulo observability)"
  type        = string
  default     = ""
}

variable "apim_circuit_breaker_error_threshold" {
  description = "Número de errores 5xx para abrir el circuit breaker"
  type        = number
  default     = 5
}

variable "apim_circuit_breaker_latency_threshold_ms" {
  description = "Latencia máxima (ms) antes de abrir el circuit breaker"
  type        = number
  default     = 4000
}

variable "apim_circuit_breaker_cooldown_seconds" {
  description = "Tiempo de enfriamiento del circuit breaker (segundos)"
  type        = number
  default     = 30
}
