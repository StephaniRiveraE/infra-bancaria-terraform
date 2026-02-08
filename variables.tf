# ============================================================================
# VARIABLES PRINCIPALES - Infraestructura Bancaria
# ============================================================================

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

# ============================================================================
# ENTIDADES DEL ECOSISTEMA
# ============================================================================

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

# ============================================================================
# NETWORKING
# ============================================================================

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

# ============================================================================
# RDS (BASES DE DATOS)
# ============================================================================

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

# ============================================================================
# TAGS COMUNES
# ============================================================================

variable "common_tags" {
  description = "Tags que se aplican a todos los recursos"
  type        = map(string)
  default = {
    Project     = "Banca-Ecosistema"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

# ============================================================================
# EKS COST CONTROL
# ============================================================================

variable "eks_enabled" {
  description = "Habilitar/deshabilitar el stack de EKS (cluster, NAT, Fargate). Poner en false para ahorrar costos cuando no se necesite."
  type        = bool
  default     = true
}

variable "eks_log_retention_days" {
  description = "Días de retención para logs de EKS (menor = más barato)"
  type        = number
  default     = 7
}

# ============================================================================
# ELASTICACHE COST CONTROL
# ============================================================================

variable "elasticache_enabled" {
  description = "Habilitar/deshabilitar ElastiCache Redis (ahorro ~$50/mes cuando está apagado)"
  type        = bool
  default     = false
}

# ============================================================================
# OBSERVABILITY
# ============================================================================

variable "alarm_email" {
  description = "Email para recibir notificaciones de alarmas CloudWatch"
  type        = string
  default     = "awsproyecto26@gmail.com"
}

variable "enable_alarms" {
  description = "Habilitar creación de alarmas CloudWatch"
  type        = bool
  default     = true
}
