variable "banks" {
  description = "Lista de IDs de bancos participantes"
  type        = list(string)
  default     = []
}

resource "aws_secretsmanager_secret" "client_cert" {
  for_each = toset(var.banks)
  name     = "apim/client_cert_${each.key}"
  description = "Certificado cliente mTLS para banco ${each.key}"
  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "client_cert_version" {
  for_each = aws_secretsmanager_secret.client_cert
  secret_id = each.value.id
  secret_string = jsonencode({
    certificate = "<PEM_CERTIFICATE>"
    private_key = "<PEM_PRIVATE_KEY>"
  })
}
