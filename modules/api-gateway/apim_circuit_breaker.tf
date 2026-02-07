# ============================================================================
# CIRCUIT BREAKER - Patrón de resiliencia para el Switch
# Este componente usa el SNS topic de alarmas del módulo observability
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "backend_5xx_errors" {
  alarm_name          = "${var.environment}-switch-backend-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "5xx"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = var.apim_circuit_breaker_error_threshold
  alarm_description   = "Circuit Breaker: ${var.apim_circuit_breaker_error_threshold}+ errores 5xx detectados"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = aws_apigatewayv2_api.apim_gateway.id
    Stage = var.environment
  }

  # Usa el SNS topic que se pasa desde observability (si está configurado)
  alarm_actions = var.apim_alarm_sns_topic_arn != "" ? [var.apim_alarm_sns_topic_arn] : []
  ok_actions    = var.apim_alarm_sns_topic_arn != "" ? [var.apim_alarm_sns_topic_arn] : []

  tags = merge(var.common_tags, {
    Name      = "${var.environment}-switch-5xx-alarm"
    Component = "APIM-CircuitBreaker"
  })
}

resource "aws_cloudwatch_metric_alarm" "backend_high_latency" {
  alarm_name          = "${var.environment}-switch-backend-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "IntegrationLatency"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Average"
  threshold           = var.apim_circuit_breaker_latency_threshold_ms
  alarm_description   = "Circuit Breaker: Latencia > ${var.apim_circuit_breaker_latency_threshold_ms}ms"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = aws_apigatewayv2_api.apim_gateway.id
    Stage = var.environment
  }

  alarm_actions = var.apim_alarm_sns_topic_arn != "" ? [var.apim_alarm_sns_topic_arn] : []
  ok_actions    = var.apim_alarm_sns_topic_arn != "" ? [var.apim_alarm_sns_topic_arn] : []

  tags = merge(var.common_tags, {
    Name      = "${var.environment}-switch-latency-alarm"
    Component = "APIM-CircuitBreaker"
  })
}

# ============================================================================
# DYNAMODB - Estado del Circuit Breaker
# ============================================================================

resource "aws_dynamodb_table" "circuit_breaker_state" {
  name         = "${var.environment}-switch-circuit-breaker-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "backend_id"

  attribute {
    name = "backend_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = merge(var.common_tags, {
    Name      = "${var.environment}-circuit-breaker-state"
    Component = "APIM-CircuitBreaker"
  })
}

# ============================================================================
# LAMBDA - Handler del Circuit Breaker
# ============================================================================

resource "aws_lambda_function" "circuit_breaker_handler" {
  function_name = "${var.environment}-switch-circuit-breaker"
  description   = "Circuit Breaker Handler - Responde MS03 Technical Failure"
  runtime       = "python3.11"
  handler       = "index.handler"
  role          = aws_iam_role.circuit_breaker_lambda_role.arn
  timeout       = 30
  memory_size   = 256

  filename         = data.archive_file.circuit_breaker_lambda.output_path
  source_code_hash = data.archive_file.circuit_breaker_lambda.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT      = var.environment
      COOLDOWN_SECONDS = var.apim_circuit_breaker_cooldown_seconds
      DYNAMODB_TABLE   = aws_dynamodb_table.circuit_breaker_state.name
      ERROR_CODE       = "MS03"
      ERROR_MESSAGE    = "Technical Failure - Service temporarily unavailable"
    }
  }

  tags = merge(var.common_tags, {
    Name      = "${var.environment}-circuit-breaker"
    Component = "APIM-CircuitBreaker"
  })

  depends_on = [data.archive_file.circuit_breaker_lambda]
}

data "archive_file" "circuit_breaker_lambda" {
  type        = "zip"
  output_path = "${path.module}/circuit_breaker_lambda.zip"

  source {
    content  = <<-PYTHON
import json
import boto3
import os
import time
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb')

def handler(event, context):
    table_name = os.environ['DYNAMODB_TABLE']
    cooldown_seconds = int(os.environ['COOLDOWN_SECONDS'])
    error_code = os.environ['ERROR_CODE']
    error_message = os.environ['ERROR_MESSAGE']
    
    table = dynamodb.Table(table_name)
    
    for record in event.get('Records', []):
        sns_message = json.loads(record['Sns']['Message'])
        alarm_name = sns_message.get('AlarmName', 'unknown')
        alarm_state = sns_message.get('NewStateValue', 'ALARM')
        backend_id = 'switch-core'
        
        current_time = int(time.time())
        expires_at = current_time + cooldown_seconds
        
        if alarm_state == 'ALARM':
            table.put_item(Item={
                'backend_id': backend_id,
                'state': 'OPEN',
                'opened_at': datetime.now(timezone.utc).isoformat(),
                'expires_at': expires_at,
                'reason': alarm_name,
                'error_code': error_code,
                'error_message': error_message
            })
            print(f"Circuit Breaker OPENED. Cooldown: {cooldown_seconds}s")
        elif alarm_state == 'OK':
            table.delete_item(Key={'backend_id': backend_id})
            print(f"Circuit Breaker CLOSED")
    
    return {'statusCode': 200, 'body': json.dumps({'message': 'OK'})}
PYTHON
    filename = "index.py"
  }
}

# Suscripción SNS solo si hay un topic definido
resource "aws_sns_topic_subscription" "circuit_breaker_lambda" {
  count     = var.apim_alarm_sns_topic_arn != "" ? 1 : 0
  topic_arn = var.apim_alarm_sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.circuit_breaker_handler.arn
}

resource "aws_lambda_permission" "circuit_breaker_sns" {
  count         = var.apim_alarm_sns_topic_arn != "" ? 1 : 0
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.circuit_breaker_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.apim_alarm_sns_topic_arn
}

# ============================================================================
# IAM - Rol para Lambda del Circuit Breaker
# ============================================================================

resource "aws_iam_role" "circuit_breaker_lambda_role" {
  name = "${var.environment}-circuit-breaker-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-circuit-breaker-lambda-role"
  })
}

resource "aws_iam_role_policy" "circuit_breaker_lambda_policy" {
  name = "${var.environment}-circuit-breaker-lambda-policy"
  role = aws_iam_role.circuit_breaker_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem"]
        Resource = aws_dynamodb_table.circuit_breaker_state.arn
      }
    ]
  })
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "circuit_breaker_lambda_arn" {
  description = "ARN de la Lambda del Circuit Breaker"
  value       = aws_lambda_function.circuit_breaker_handler.arn
}

output "circuit_breaker_dynamodb_table" {
  description = "Nombre de la tabla DynamoDB del Circuit Breaker"
  value       = aws_dynamodb_table.circuit_breaker_state.name
}
