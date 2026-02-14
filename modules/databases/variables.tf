variable "entidades" {
  description = "Lista de entidades bancarias del ecosistema"
  type        = map(string)
}

variable "bancos" {
  description = "Lista de bancos (sin el switch)"
  type        = list(string)
}

variable "rds_instance_class" {
  description = "Tipo de instancia para RDS"
  type        = string
}

variable "rds_storage_gb" {
  description = "Almacenamiento inicial en GB para RDS"
  type        = number
}

variable "rds_engine_version" {
  description = "Versión de PostgreSQL"
  type        = string
}

variable "rds_username" {
  description = "Usuario administrador de las bases de datos"
  type        = string
}

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}

variable "db_subnet_group_name" {
  description = "Nombre del DB subnet group (desde módulo networking)"
  type        = string
}

variable "rds_security_group_id" {
  description = "ID del security group para RDS (desde módulo networking)"
  type        = string
}

variable "elasticache_enabled" {
  description = "Habilitar/deshabilitar ElastiCache Redis (ahorro ~$50/mes cuando está apagado)"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID de la VPC (para crear Security Group de Redis)"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas (para subnet group de Redis)"
  type        = list(string)
  default     = []
}
