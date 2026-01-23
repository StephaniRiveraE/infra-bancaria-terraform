variable "vpc_cidr" {
  description = "CIDR block para la VPC principal"
  type        = string
}

variable "availability_zones" {
  description = "Zonas de disponibilidad a usar"
  type        = list(string)
}

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}
