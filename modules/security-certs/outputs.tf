output "apim_ca_secret_arn" {
  description = "ARN del secreto con el certificado CA"
  value       = aws_secretsmanager_secret.apim_ca_cert.arn
}

output "client_cert_secret_arns" {
  description = "ARNs de los secretos de certificados de clientes"
  value       = { for k, v in aws_secretsmanager_secret.client_cert : k => v.arn }
}
