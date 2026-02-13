
resource "aws_cloudwatch_metric_alarm" "switch_rds_cpu" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "RDS-Switch-High-CPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2 
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300 
  threshold           = 50 
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

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  count = var.enable_alarms && var.api_gateway_id != "" ? 1 : 0

  alarm_name          = "APIGateway-5xx-Errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5xx"
  namespace           = "AWS/ApiGateway"
  period              = 900 
  statistic           = "Sum"
  threshold           = 2 
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

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  count = var.enable_alarms && var.api_gateway_id != "" ? 1 : 0

  alarm_name          = "APIGateway-High-Latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2 
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300 
  extended_statistic  = "p95"
  threshold           = 2000 
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

resource "aws_cloudwatch_metric_alarm" "rabbitmq_queue" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "RabbitMQ-Messages-Queued"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MessageCount"
  namespace           = "AWS/AmazonMQ"
  period              = 300 
  statistic           = "Average"
  threshold           = 5 
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
