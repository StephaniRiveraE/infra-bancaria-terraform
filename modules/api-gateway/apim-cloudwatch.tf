resource "aws_cloudwatch_log_group" "apim_access_logs" {
  name              = "/aws/apigateway/apim-switch-${var.environment}"
  retention_in_days = var.apim_log_retention_days

  tags = merge(var.common_tags, {
    Name      = "logs-apim-access"
    Component = "APIM"
  })
}

resource "aws_cloudwatch_metric_alarm" "apim_latency_alarm" {
  alarm_name          = "apim-high-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Average"
  threshold           = 200
  alarm_description   = "Latencia del APIM supera 200ms (requisito ERS)"

  dimensions = {
    ApiId = aws_apigatewayv2_api.apim_gateway.id
    Stage = var.environment
  }

  alarm_actions = var.apim_alarm_sns_topic_arn != "" ? [var.apim_alarm_sns_topic_arn] : []

  tags = merge(var.common_tags, {
    Name      = "alarm-apim-latency"
    Component = "APIM"
  })
}

resource "aws_cloudwatch_metric_alarm" "apim_5xx_alarm" {
  alarm_name          = "apim-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Errores 5xx detectados en el APIM"

  dimensions = {
    ApiId = aws_apigatewayv2_api.apim_gateway.id
    Stage = var.environment
  }

  alarm_actions = var.apim_alarm_sns_topic_arn != "" ? [var.apim_alarm_sns_topic_arn] : []

  tags = merge(var.common_tags, {
    Name      = "alarm-apim-5xx"
    Component = "APIM"
  })
}

resource "aws_cloudwatch_metric_alarm" "apim_4xx_alarm" {
  alarm_name          = "apim-4xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "Alto volumen de errores 4xx - posible ataque o problema de clientes"

  dimensions = {
    ApiId = aws_apigatewayv2_api.apim_gateway.id
    Stage = var.environment
  }

  alarm_actions = var.apim_alarm_sns_topic_arn != "" ? [var.apim_alarm_sns_topic_arn] : []

  tags = merge(var.common_tags, {
    Name      = "alarm-apim-4xx"
    Component = "APIM"
  })
}

resource "aws_cloudwatch_dashboard" "apim_dashboard" {
  dashboard_name = "APIM-Switch-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "API Gateway - Total Requests"
          region = var.aws_region
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiId", aws_apigatewayv2_api.apim_gateway.id, "Stage", var.environment]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "API Gateway - Latencia (ms)"
          region = var.aws_region
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiId", aws_apigatewayv2_api.apim_gateway.id, "Stage", var.environment],
            [".", "IntegrationLatency", ".", ".", ".", "."]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Errores 4xx y 5xx"
          region = var.aws_region
          metrics = [
            ["AWS/ApiGateway", "4XXError", "ApiId", aws_apigatewayv2_api.apim_gateway.id, "Stage", var.environment],
            [".", "5XXError", ".", ".", ".", "."]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Throttling (Rate Limit)"
          region = var.aws_region
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiId", aws_apigatewayv2_api.apim_gateway.id, "Stage", var.environment]
          ]
          period = 60
          stat   = "SampleCount"
        }
      }
    ]
  })
}
