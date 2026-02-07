# ============================================================================
# APIM CLOUDWATCH - Logs solamente
# NOTA: Las alarmas del API Gateway están centralizadas en el módulo observability
# ============================================================================

resource "aws_cloudwatch_log_group" "apim_access_logs" {
  name              = "/aws/apigateway/apim-switch-${var.environment}"
  retention_in_days = var.apim_log_retention_days

  tags = merge(var.common_tags, {
    Name      = "logs-apim-access"
    Component = "APIM"
  })
}

# ============================================================================
# DASHBOARD DEL APIM - Métricas específicas del API Gateway
# Este dashboard se mantiene aquí porque es específico del componente APIM
# ============================================================================

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
