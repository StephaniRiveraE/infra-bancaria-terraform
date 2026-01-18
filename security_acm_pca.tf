resource "aws_secretsmanager_secret" "apim_ca_cert" {
  name        = "apim/ca-certificate"
  description = "Certificado CA self-signed para validación mTLS"

  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "apim_ca_cert_version" {
  secret_id     = aws_secretsmanager_secret.apim_ca_cert.id
  secret_string = file("${path.module}/dummy_cert.pem")
}

output "apim_ca_secret_arn" {
  description = "ARN del secreto con el certificado CA (para Lambda JWS Authorizer)"
  value       = aws_secretsmanager_secret.apim_ca_cert.arn
}
