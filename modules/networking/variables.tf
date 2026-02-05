variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}

variable "eks_enabled" {
  description = "Habilitar recursos de NAT Gateway (solo necesarios cuando EKS está activo)"
  type        = bool
  default     = false
}
