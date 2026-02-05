# ============================================================================
# GRAFANA CLOUD - Usuario IAM para conectar Grafana a CloudWatch
# Costo: $0 (solo es un usuario IAM)
# ============================================================================

# Política de solo lectura para CloudWatch (métricas y logs)
resource "aws_iam_policy" "grafana_cloudwatch_readonly" {
  name        = "GrafanaCloudWatchReadOnly"
  description = "Permite a Grafana Cloud leer métricas y logs de CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # CloudWatch Metrics
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          # CloudWatch Logs
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents",
          # EC2 (para autodescubrimiento)
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          # Tags
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name      = "grafana-cloudwatch-policy"
    Component = "Observability"
  })
}

# Usuario IAM para Grafana Cloud
resource "aws_iam_user" "grafana_reader" {
  name = "grafana-cloudwatch-reader"
  path = "/observability/"

  tags = merge(var.common_tags, {
    Name      = "grafana-cloudwatch-reader"
    Component = "Observability"
    Purpose   = "Acceso de solo lectura para Grafana Cloud"
  })
}

# Adjuntar política al usuario
resource "aws_iam_user_policy_attachment" "grafana_cloudwatch" {
  user       = aws_iam_user.grafana_reader.name
  policy_arn = aws_iam_policy.grafana_cloudwatch_readonly.arn
}

# Access Keys para el usuario (se mostrarán en outputs)
resource "aws_iam_access_key" "grafana_reader" {
  user = aws_iam_user.grafana_reader.name
}

# Guardar las credenciales en Secrets Manager (más seguro)
resource "aws_secretsmanager_secret" "grafana_credentials" {
  name        = "grafana-cloudwatch-credentials"
  description = "Credenciales IAM para conectar Grafana Cloud a CloudWatch"

  tags = merge(var.common_tags, {
    Name      = "grafana-credentials"
    Component = "Observability"
  })
}

resource "aws_secretsmanager_secret_version" "grafana_credentials" {
  secret_id = aws_secretsmanager_secret.grafana_credentials.id
  secret_string = jsonencode({
    access_key_id     = aws_iam_access_key.grafana_reader.id
    secret_access_key = aws_iam_access_key.grafana_reader.secret
    user_name         = aws_iam_user.grafana_reader.name
    region            = "us-east-2"
    instructions      = "Usa estas credenciales en Grafana Cloud → Data Sources → CloudWatch"
  })
}
