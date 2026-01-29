# Security Groups are now managed in the networking module and passed as variables.


resource "aws_apigatewayv2_api" "apim_gateway" {
  name          = "apim-switch-gateway"
  protocol_type = "HTTP"
  description   = "API Gateway para Switch Transaccional Bancario - HTTPS incluido"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-JWS-Signature", "X-Trace-ID"]
    max_age       = 300
  }

  tags = merge(var.common_tags, {
    Name      = "apigw-switch-transaccional"
    Component = "APIM"
  })
}

resource "aws_apigatewayv2_vpc_link" "apim_vpc_link" {
  name               = "apim-vpc-link"
  security_group_ids = [var.apim_vpc_link_security_group_id]
  
  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  tags = merge(var.common_tags, {
    Name      = "vpc-link-apim"
    Component = "APIM"
  })
}

resource "aws_apigatewayv2_stage" "apim_stage" {
  api_id      = aws_apigatewayv2_api.apim_gateway.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apim_access_logs.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      traceId            = "$context.requestId"
      sourceIp           = "$context.identity.sourceIp"
      requestTime        = "$context.requestTime"
      requestTimeEpoch   = "$context.requestTimeEpoch"
      httpMethod         = "$context.httpMethod"
      routeKey           = "$context.routeKey"
      status             = "$context.status"
      protocol           = "$context.protocol"
      responseLength     = "$context.responseLength"
      integrationError   = "$context.integrationErrorMessage"
      integrationLatency = "$context.integrationLatency"
      responseLatency    = "$context.responseLatency"
    })
  }

  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }

  tags = merge(var.common_tags, {
    Name      = "stage-${var.environment}"
    Component = "APIM"
  })
}

output "apim_gateway_endpoint" {
  description = "Endpoint HTTPS del API Gateway (ya incluye SSL)"
  value       = aws_apigatewayv2_api.apim_gateway.api_endpoint
}

output "apim_gateway_id" {
  description = "ID del API Gateway (para que Brayan configure las rutas)"
  value       = aws_apigatewayv2_api.apim_gateway.id
}

output "apim_stage_name" {
  description = "Nombre del stage (dev/prod)"
  value       = aws_apigatewayv2_stage.apim_stage.name
}

output "apim_vpc_link_id" {
  description = "ID del VPC Link (para integraciones privadas)"
  value       = aws_apigatewayv2_vpc_link.apim_vpc_link.id
}


