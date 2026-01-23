variable "banks" {
  description = "Lista de IDs de bancos participantes"
  type        = list(string)
}

variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
}
