output "cognito_endpoint" {
  value = aws_cognito_user_pool.banca_pool.endpoint
}

output "cognito_client_ids" {
  value = [for k, v in aws_cognito_user_pool_client.banco_clients : v.id]
}

output "internal_secret_value" {
  value     = random_password.internal_secret.result
  sensitive = true
}