variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}

variable "vpc_id" {
  description = "ID de la VPC donde se despliega el broker"
  type        = string
}

variable "public_subnet_id" {
  description = "ID de la subnet publica para el broker (acceso externo)"
  type        = string
}
