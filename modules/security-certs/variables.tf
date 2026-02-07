# ============================================================================
# VARIABLES - Módulo Security & Certificates
# ============================================================================

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "bancos" {
  description = "Lista de bancos para crear clientes Cognito y secretos de firma"
  type        = list(string)
  default     = ["ArcBank", "Bantec", "Nexus", "Ecusol"]
}
