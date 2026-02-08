# ============================================================================
# CLOUDWATCH DASHBOARDS - Visibilidad del ecosistema bancario
# ============================================================================

# Locals para asegurar que todas las variables son strings
locals {
  api_gateway_id_str      = tostring(var.api_gateway_id != "" ? var.api_gateway_id : "placeholder-api-id")
  rabbitmq_broker_name_str = tostring(var.rabbitmq_broker_name)
  rds_instance_ids_str    = [for id in var.rds_instance_ids : tostring(id)]
}

# ============================================================================
# DASHBOARD PRINCIPAL - Overview del Ecosistema
# ============================================================================

resource "aws_cloudwatch_dashboard" "overview" {
  dashboard_name = "Banca-Overview-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      # Título
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# 🏦 Ecosistema Bancario - Dashboard Principal"
        }
      },
      # API Gateway Requests
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "API Gateway - Requests/min"
          region  = "us-east-2"
          stat    = "Sum"
          period  = 60
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiId", local.api_gateway_id_str]
          ]
        }
      },
      # API Gateway Latency
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "API Gateway - Latencia (ms)"
          region  = "us-east-2"
          stat    = "Average"
          period  = 60
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiId", local.api_gateway_id_str]
          ]
        }
      },
      # API Gateway Errors
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "API Gateway - Errores"
          region  = "us-east-2"
          stat    = "Sum"
          period  = 60
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApiGateway", "4xx", "ApiId", local.api_gateway_id_str],
            ["AWS/ApiGateway", "5xx", "ApiId", local.api_gateway_id_str]
          ]
        }
      },
      # RDS CPU - Todos los bancos
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          title   = "RDS - CPU Utilization (%)"
          region  = "us-east-2"
          stat    = "Average"
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            for id in local.rds_instance_ids_str : ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", id]
          ]
        }
      },
      # RDS Connections
      {
        type   = "metric"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          title   = "RDS - Conexiones Activas"
          region  = "us-east-2"
          stat    = "Average"
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            for id in local.rds_instance_ids_str : ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", id]
          ]
        }
      },
      # RabbitMQ Messages
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 12
        height = 6
        properties = {
          title   = "RabbitMQ - Mensajes"
          region  = "us-east-2"
          stat    = "Average"
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/AmazonMQ", "MessageCount", "Broker", local.rabbitmq_broker_name_str]
          ]
        }
      },
      # Alarmas Activas
      {
        type   = "alarm"
        x      = 12
        y      = 13
        width  = 12
        height = 6
        properties = {
          title  = "🚨 Estado de Alarmas"
          alarms = [
            for id in local.rds_instance_ids_str : "arn:aws:cloudwatch:us-east-2:${data.aws_caller_identity.current.account_id}:alarm:RDS-${id}-High-CPU"
          ]
        }
      }
    ]
  })
}

# Data source para obtener Account ID
data "aws_caller_identity" "current" {}

# ============================================================================
# DASHBOARD POR BANCO - ArcBank
# ============================================================================

resource "aws_cloudwatch_dashboard" "arcbank" {
  dashboard_name = "ArcBank-Metrics-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# 🏦 ArcBank - Métricas"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 12
        height = 6
        properties = {
          title   = "RDS CPU - ArcBank"
          region  = "us-east-2"
          stat    = "Average"
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "rds-arcbank"]
          ]
          annotations = {
            horizontal = [
              {
                value = 80
                label = "Umbral Alarma"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 1
        width  = 12
        height = 6
        properties = {
          title   = "RDS Storage - ArcBank"
          region  = "us-east-2"
          stat    = "Average"
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "rds-arcbank"]
          ]
        }
      }
    ]
  })
}

# ============================================================================
# DASHBOARD DEL SWITCH
# ============================================================================

resource "aws_cloudwatch_dashboard" "switch" {
  dashboard_name = "Switch-Metrics-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# 🔄 Switch DIGICONECU - Métricas"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "RDS CPU - Switch"
          region  = "us-east-2"
          stat    = "Average"
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "rds-switch"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "RabbitMQ - Mensajes Procesados"
          region  = "us-east-2"
          stat    = "Average"
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/AmazonMQ", "MessageCount", "Broker", local.rabbitmq_broker_name_str]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          title   = "API Gateway - Transferencias"
          region  = "us-east-2"
          stat    = "Sum"
          period  = 300
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiId", local.api_gateway_id_str]
          ]
        }
      }
    ]
  })
}
