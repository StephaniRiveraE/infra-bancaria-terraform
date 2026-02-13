
variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "alarm_email" {
  description = "Email para recibir notificaciones de alarmas"
  type        = string
  default     = ""
}

variable "enable_alarms" {
  description = "Habilitar creación de alarmas CloudWatch"
  type        = bool
  default     = true
}

variable "rds_instance_ids" {
  description = "Lista de identificadores de instancias RDS para monitorear"
  type        = list(string)
  default     = ["rds-arcbank", "rds-bantec", "rds-nexus", "rds-ecusol", "rds-switch"]
}


variable "api_gateway_id" {
  description = "ID del API Gateway para métricas"
  type        = string
  default     = ""
}

variable "api_gateway_stage" {
  description = "Stage del API Gateway"
  type        = string
  default     = "dev"
}


variable "rabbitmq_broker_name" {
  description = "Nombre del broker RabbitMQ"
  type        = string
  default     = "switch-rabbitmq"
}


variable "rds_cpu_threshold" {
  description = "Umbral de CPU para alarmas de RDS (%)"
  type        = number
  default     = 80
}

variable "api_5xx_threshold" {
  description = "Umbral de errores 5xx por minuto para API Gateway"
  type        = number
  default     = 10
}


variable "eks_enabled" {
  description = "Indica si EKS está habilitado"
  type        = bool
  default     = false
}

variable "eks_cluster_name" {
  description = "Nombre del cluster EKS"
  type        = string
  default     = "eks-banca-ecosistema"
}

variable "enable_eks_container_insights" {
  description = "Habilitar el addon de CloudWatch Observability (Container Insights). Tarda ~10 min en desplegar."
  type        = bool
  default     = false
}

