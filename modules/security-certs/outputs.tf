output "cognito_endpoint" { value = aws_cognito_user_pool.banca_pool.endpoint }
output "cognito_client_ids" { value = [for k, v in aws_cognito_user_pool_client.banco_clients : v.id] }
output "internal_secret_value" {
  value     = random_password.internal_secret.result
  sensitive = true
}

# Outputs de Firma Digital
output "switch_signing_public_key_pem" {
  description = "Llave publica del Switch (Compartir con Bancos para validar firmas)"
  value       = tls_private_key.switch_signing_key.public_key_pem
}

output "bank_jws_keys_secrets_map" {
  description = "Mapa de Secret ARNs donde subir las llaves publicas de los bancos"
  value       = { for k, v in aws_secretsmanager_secret.bank_jws_public_keys : k => v.name }
}