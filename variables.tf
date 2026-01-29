variable "aws_region" {
  description = "Región de AWS donde se despliega la infraestructura"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Nombre del proyecto para tags"
  type        = string
  default     = "Banca-Ecosistema"
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "entidades" {
  description = "Lista de entidades bancarias del ecosistema"
  type        = map(string)
  default = {
    "arcbank" = "db_arcbank_core"
    "bantec"  = "db_bantec_core"
    "nexus"   = "db_nexus_core"
    "ecusol"  = "db_ecusol_core"
    "switch"  = "db_switch_ledger"
  }
}

variable "bancos" {
  description = "Lista de bancos (sin el switch)"
  type        = list(string)
  default     = ["arcbank", "bantec", "nexus", "ecusol"]
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC principal"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad a usar"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "rds_instance_class" {
  description = "Tipo de instancia para RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_storage_gb" {
  description = "Almacenamiento inicial en GB para RDS"
  type        = number
  default     = 20
}

variable "rds_engine_version" {
  description = "Versión de PostgreSQL"
  type        = string
  default     = "17.6"
}

variable "rds_username" {
  description = "Usuario administrador de las bases de datos"
  type        = string
  default     = "dbadmin"
}

variable "common_tags" {
  description = "Tags que se aplican a todos los recursos"
  type        = map(string)
  default = {
    Project     = "Banca-Ecosistema"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

variable "apim_log_retention_days" {
  description = "Días de retención para logs de CloudWatch del APIM"
  type        = number
  default     = 30
}

variable "apim_alarm_sns_topic_arn" {
  description = "ARN del SNS Topic para enviar alarmas del APIM (opcional)"
  type        = string
  default     = ""
}

variable "apim_domain_name" {
  description = "Dominio personalizado para el API Gateway (requerido para mTLS)"
  type        = string
  default     = "api.switch-transaccional.com"
}

variable "apim_enable_custom_domain" {
  description = "Habilitar Custom Domain con mTLS (requiere dominio real y validación DNS)"
  type        = bool
  default     = false
}

variable "apim_backend_port" {
  description = "Puerto del backend"
  type        = number
  default     = 8080
}

variable "apim_integration_timeout_ms" {
  description = "Timeout de integración con backend (ms)"
  type        = number
  default     = 29000
}

variable "apim_circuit_breaker_error_threshold" {
  description = "Errores 5xx para abrir circuit breaker"
  type        = number
  default     = 5
}

variable "apim_circuit_breaker_latency_threshold_ms" {
  description = "Latencia máxima (ms) antes de abrir circuit breaker"
  type        = number
  default     = 4000
}

variable "apim_circuit_breaker_cooldown_seconds" {
  description = "Tiempo de enfriamiento (segundos)"
  type        = number
  default     = 30
}
# Duplicate removed

variable "vpc_id" {}
variable "private_subnet_ids" { type = list(string) }

# Variables de Seguridad (Vienen de los otros modulos)
variable "cognito_endpoint" {}
variable "cognito_client_ids" { type = list(string) }
variable "internal_secret_value" {}
variable "backend_security_group_id" {}
variable "apim_vpc_link_security_group_id" {}