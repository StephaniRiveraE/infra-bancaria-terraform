# ============================================================================
# CLOUDWATCH ALARMAS - Proyecto Académico
# Umbrales ajustados para que se disparen ocasionalmente (demos)
# ============================================================================

# ============================================================================
# ALARMA RDS SWITCH - CPU
# Umbral: 50% por 10 minutos (probable que pase en picos)
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "switch_rds_cpu" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "RDS-Switch-High-CPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2 # 2 períodos de 5 min = 10 min
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300 # 5 minutos
  statistic           = "Average"
  threshold           = 50 # 50% - puede pasar en picos de actividad
  alarm_description   = "CPU del RDS Switch supera 50% por 10 minutos"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = "rds-switch"
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = merge(var.common_tags, {
    Name      = "alarm-rds-switch-cpu"
    Component = "RDS"
    Severity  = "Warning"
  })
}

# ============================================================================
# ALARMA API GATEWAY - Errores 5xx
# Umbral: 2 errores en 15 minutos (al menos 1 error malo debería pasar)
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  count = var.enable_alarms && var.api_gateway_id != "" ? 1 : 0

  alarm_name          = "APIGateway-5xx-Errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xx"
  namespace           = "AWS/ApiGateway"
  period              = 900 # 15 minutos
  statistic           = "Sum"
  threshold           = 2 # 2 errores en 15 min - probable que pase
  alarm_description   = "Más de 2 errores 5xx en el API Gateway en 15 minutos"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = var.api_gateway_id
    Stage = var.api_gateway_stage
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = merge(var.common_tags, {
    Name      = "alarm-apigw-5xx"
    Component = "APIGateway"
    Severity  = "Warning"
  })
}

# ============================================================================
# ALARMA API GATEWAY - Latencia Alta
# Umbral: p95 > 2 segundos (común en transferencias)
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  count = var.enable_alarms && var.api_gateway_id != "" ? 1 : 0

  alarm_name          = "APIGateway-High-Latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2 # 2 períodos consecutivos
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300 # 5 minutos
  extended_statistic  = "p95"
  threshold           = 2000 # 2 segundos - puede pasar en transferencias
  alarm_description   = "Latencia p95 del API Gateway supera 2 segundos"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = var.api_gateway_id
    Stage = var.api_gateway_stage
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = merge(var.common_tags, {
    Name      = "alarm-apigw-latency"
    Component = "APIGateway"
    Severity  = "Warning"
  })
}

# ============================================================================
# ALARMA RABBITMQ - Mensajes en cola
# Umbral: 5 mensajes sin procesar (probable en ráfagas)
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "rabbitmq_queue" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "RabbitMQ-Messages-Queued"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MessageCount"
  namespace           = "AWS/AmazonMQ"
  period              = 300 # 5 minutos
  statistic           = "Average"
  threshold           = 5 # 5 mensajes en cola - puede pasar en ráfagas
  alarm_description   = "Hay más de 5 mensajes encolados en RabbitMQ"
  treat_missing_data  = "notBreaching"

  dimensions = {
    Broker = var.rabbitmq_broker_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = merge(var.common_tags, {
    Name      = "alarm-rabbitmq-queue"
    Component = "Messaging"
    Severity  = "Info"
  })
}
