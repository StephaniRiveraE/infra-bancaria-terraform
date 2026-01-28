# ============================================================================
# OUTPUTS - AMAZON MQ RABBITMQ
# Información para compartir con los desarrolladores
# ============================================================================

output "rabbitmq_broker_id" {
  description = "ID del broker RabbitMQ"
  value       = aws_mq_broker.rabbitmq.id
}

output "rabbitmq_broker_arn" {
  description = "ARN del broker RabbitMQ"
  value       = aws_mq_broker.rabbitmq.arn
}

output "rabbitmq_console_url" {
  description = "URL de la consola web de RabbitMQ (para administrar colas)"
  value       = "https://${aws_mq_broker.rabbitmq.instances[0].console_url}"
}

output "rabbitmq_amqps_endpoint" {
  description = "Endpoint AMQPS para conexion desde microservicios"
  value       = aws_mq_broker.rabbitmq.instances[0].endpoints[0]
}

output "rabbitmq_username" {
  description = "Usuario admin de RabbitMQ"
  value       = "mqadmin"
}

output "rabbitmq_credentials_secret_arn" {
  description = "ARN del secreto con las credenciales de RabbitMQ"
  value       = aws_secretsmanager_secret.rabbitmq_credentials.arn
  sensitive   = true
}
