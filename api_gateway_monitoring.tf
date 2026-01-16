# =============================================================================
# API GATEWAY - Monitoring y Dashboard
# =============================================================================
# CloudWatch Dashboard y Alarmas para monitoreo de uso por banco
# =============================================================================

# -----------------------------------------------------------------------------
# CloudWatch Dashboard - Uso de API por Banco
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "api_usage" {
  dashboard_name = "API-Gateway-Uso-Por-Banco"

  dashboard_body = jsonencode({
    widgets = concat(
      # Widget de título
      [{
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# 📊 Dashboard de Uso de API Gateway - Ecosistema Bancario\n**Métricas de uso para facturación y monitoreo**"
        }
      }],

      # Widgets de métricas por banco
      [for idx, bank_key in keys(var.banks) : {
        type   = "metric"
        x      = (idx % 4) * 6
        y      = 2 + floor(idx / 4) * 6
        width  = 6
        height = 6
        properties = {
          title  = "📈 ${upper(bank_key)} - Requests"
          region = "us-east-2"
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", var.api_gateway_name, "Stage", var.stage_name, { stat = "Sum", period = 86400, label = "Total Requests" }],
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
        }
      }],

      # Widget para el Switch
      [{
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6
        properties = {
          title  = "🔄 SWITCH - Transacciones"
          region = "us-east-2"
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", var.api_gateway_name, "Stage", var.stage_name, "Resource", "/switch/transferencia", { stat = "Sum", period = 3600, label = "Transferencias" }],
            ["AWS/ApiGateway", "Count", "ApiName", var.api_gateway_name, "Stage", var.stage_name, "Resource", "/switch/validar", { stat = "Sum", period = 3600, label = "Validaciones" }],
          ]
          view    = "timeSeries"
          stacked = true
        }
      }],

      # Widget de errores
      [{
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6
        properties = {
          title  = "⚠️ Errores API Gateway"
          region = "us-east-2"
          metrics = [
            ["AWS/ApiGateway", "4XXError", "ApiName", var.api_gateway_name, "Stage", var.stage_name, { stat = "Sum", period = 300, color = "#ff7f0e", label = "4XX Errors" }],
            ["AWS/ApiGateway", "5XXError", "ApiName", var.api_gateway_name, "Stage", var.stage_name, { stat = "Sum", period = 300, color = "#d62728", label = "5XX Errors" }],
          ]
          view    = "timeSeries"
          stacked = false
        }
      }],

      # Widget de latencia
      [{
        type   = "metric"
        x      = 0
        y      = 14
        width  = 24
        height = 6
        properties = {
          title  = "⏱️ Latencia de API Gateway"
          region = "us-east-2"
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiName", var.api_gateway_name, "Stage", var.stage_name, { stat = "Average", period = 300, label = "Latencia Promedio (ms)" }],
            ["AWS/ApiGateway", "Latency", "ApiName", var.api_gateway_name, "Stage", var.stage_name, { stat = "p99", period = 300, label = "Latencia P99 (ms)" }],
            ["AWS/ApiGateway", "IntegrationLatency", "ApiName", var.api_gateway_name, "Stage", var.stage_name, { stat = "Average", period = 300, label = "Latencia Backend Promedio (ms)" }],
          ]
          view    = "timeSeries"
          stacked = false
        }
      }]
    )
  })
}

# -----------------------------------------------------------------------------
# Alarma para errores 5XX (críticos)
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "api-gateway-5xx-errors-${var.api_gateway_name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarma cuando hay más de 10 errores 5XX en 5 minutos"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = var.api_gateway_name
    Stage   = var.stage_name
  }

  tags = merge(var.common_tags, {
    Name = "alarm-5xx-${var.api_gateway_name}"
  })
}

# -----------------------------------------------------------------------------
# Alarma para alta latencia
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "api_high_latency" {
  alarm_name          = "api-gateway-high-latency-${var.api_gateway_name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = 5000  # 5 segundos
  alarm_description   = "Alarma cuando la latencia promedio supera 5 segundos"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = var.api_gateway_name
    Stage   = var.stage_name
  }

  tags = merge(var.common_tags, {
    Name = "alarm-latency-${var.api_gateway_name}"
  })
}
