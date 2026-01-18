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

# =============================================================================
# Variables del APIM (Christian)
# =============================================================================

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

variable "apim_integration_timeout_ms" {
  description = "Timeout de integración en milisegundos (ERS: 3-5 segundos)"
  type        = number
  default     = 5000
}

# =============================================================================
# Variables de Seguridad (Kris)
# =============================================================================

variable "crl_s3_bucket" {
  description = "Nombre del bucket S3 donde se publicará la CRL de la CA"
  type        = string
  default     = "apim-crl-bucket"
}
