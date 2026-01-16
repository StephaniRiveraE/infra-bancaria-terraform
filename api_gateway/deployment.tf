# =============================================================================
# API GATEWAY - Deployment y Stages
# =============================================================================
# Configuración del deployment y stages del API Gateway
# =============================================================================

# -----------------------------------------------------------------------------
# Deployment del API Gateway
# -----------------------------------------------------------------------------

resource "aws_api_gateway_deployment" "bancario" {
  rest_api_id = aws_api_gateway_rest_api.bancario.id

  # Forzar nuevo deployment cuando cambian los recursos
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.bank,
      aws_api_gateway_resource.bank_endpoint,
      aws_api_gateway_resource.switch,
      aws_api_gateway_resource.switch_endpoint,
      aws_api_gateway_method.bank_endpoint_post,
      aws_api_gateway_method.switch_endpoint,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.bank_endpoint_mock,
    aws_api_gateway_integration.switch_endpoint_mock,
  ]
}

# -----------------------------------------------------------------------------
# Stage de Producción
# -----------------------------------------------------------------------------

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.bancario.id
  rest_api_id   = aws_api_gateway_rest_api.bancario.id
  stage_name    = var.stage_name

  # Habilitar logs de acceso
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId         = "$context.requestId"
      ip                = "$context.identity.sourceIp"
      caller            = "$context.identity.caller"
      user              = "$context.identity.user"
      requestTime       = "$context.requestTime"
      httpMethod        = "$context.httpMethod"
      resourcePath      = "$context.resourcePath"
      status            = "$context.status"
      protocol          = "$context.protocol"
      responseLength    = "$context.responseLength"
      apiKeyId          = "$context.identity.apiKeyId"
      integrationStatus = "$context.integrationStatus"
    })
  }

  tags = merge(var.common_tags, {
    Name  = "${var.api_gateway_name}-${var.stage_name}"
    Stage = var.stage_name
  })
}

# -----------------------------------------------------------------------------
# Configuración de Método del Stage (Throttling global)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.bancario.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    # Habilitar métricas de CloudWatch
    metrics_enabled = true
    
    # Logging
    logging_level   = "INFO"
    data_trace_enabled = true
    
    # Throttling global (se puede override por Usage Plan)
    throttling_rate_limit  = 1000
    throttling_burst_limit = 2000
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group para API Gateway
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/api-gateway/${var.api_gateway_name}"
  retention_in_days = 30

  tags = merge(var.common_tags, {
    Name = "logs-${var.api_gateway_name}"
  })
}
