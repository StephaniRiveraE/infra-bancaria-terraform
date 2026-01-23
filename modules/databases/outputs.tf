output "rds_endpoints" {
  description = "Endpoints de las instancias RDS"
  value       = { for k, v in aws_db_instance.rds_instances : k => v.endpoint }
}

output "rds_secret_arns" {
  description = "ARNs de los secretos en Secrets Manager"
  value       = { for k, v in aws_secretsmanager_secret.db_secrets : k => v.arn }
}

output "dynamodb_table_names" {
  description = "Nombres de las tablas DynamoDB"
  value = merge(
    { "switch_directorio" = aws_dynamodb_table.switch_directorio.name },
    { for k, v in aws_dynamodb_table.sucursales_tables : k => v.name }
  )
}
