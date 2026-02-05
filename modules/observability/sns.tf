# ============================================================================
# SNS - Topics para notificaciones de alarmas
# ============================================================================

# Topic principal para todas las alarmas del ecosistema bancario
resource "aws_sns_topic" "alarms" {
  name         = "banca-alarms-${var.environment}"
  display_name = "Alarmas Ecosistema Bancario"

  tags = merge(var.common_tags, {
    Name      = "banca-alarms-topic"
    Component = "Observability"
    Phase     = "5-Observability"
  })
}

# Suscripción de email (solo si se proporciona un email)
resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# Topic específico para alarmas críticas (opcional, para escalar a PagerDuty/Slack)
resource "aws_sns_topic" "critical_alarms" {
  name         = "banca-critical-alarms-${var.environment}"
  display_name = "Alarmas Críticas Banca"

  tags = merge(var.common_tags, {
    Name      = "banca-critical-alarms-topic"
    Component = "Observability"
    Severity  = "Critical"
  })
}
