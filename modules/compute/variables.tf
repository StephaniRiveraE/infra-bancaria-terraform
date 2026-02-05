# ============================================================================
# VARIABLES - Módulo Compute (EKS + Fargate)
# ============================================================================

variable "vpc_id" {
  description = "ID de la VPC principal"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas para Fargate pods"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs de las subnets públicas para ALB"
  type        = list(string)
}

variable "eks_cluster_role_arn" {
  description = "ARN del rol IAM para el clúster EKS"
  type        = string
}

variable "fargate_execution_role_arn" {
  description = "ARN del rol IAM para Fargate pod execution"
  type        = string
}

variable "eks_version" {
  description = "Versión de Kubernetes para EKS"
  type        = string
  default     = "1.29"
}

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}

variable "eks_enabled" {
  description = "Habilitar/deshabilitar el stack de EKS completo"
  type        = bool
  default     = false
}

variable "eks_log_retention_days" {
  description = "Días de retención para logs de EKS"
  type        = number
  default     = 7
}
