# ============================================================================
# MÓDULO OBSERVABILIDAD - Outputs
# ============================================================================

output "sns_alarms_topic_arn" {
  description = "ARN del topic SNS para alarmas generales"
  value       = aws_sns_topic.alarms.arn
}

output "sns_critical_alarms_topic_arn" {
  description = "ARN del topic SNS para alarmas críticas"
  value       = aws_sns_topic.critical_alarms.arn
}

output "dashboard_urls" {
  description = "URLs de los dashboards de CloudWatch"
  value = {
    overview = "https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#dashboards:name=Banca-Overview-${var.environment}"
    arcbank  = "https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#dashboards:name=ArcBank-Metrics-${var.environment}"
    switch   = "https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#dashboards:name=Switch-Metrics-${var.environment}"
  }
}

output "alarm_count" {
  description = "Número de alarmas creadas"
  value = var.enable_alarms ? (
    length(var.rds_instance_ids) * 2 +   # CPU + Connections por RDS
    (var.api_gateway_id != "" ? 2 : 0) + # 5xx + Latency
    1                                    # RabbitMQ DLQ
  ) : 0
}
