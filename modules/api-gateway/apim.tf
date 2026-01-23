resource "aws_security_group" "apim_vpc_link_sg" {
  name        = "apim-vpc-link-sg"
  vpc_id      = aws_vpc.vpc_bancaria.id
  description = "Security group para VPC Link del APIM - conecta API Gateway al backend privado"

  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_bancaria.cidr_block]
    description = "Conexion al backend en subredes privadas"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_bancaria.cidr_block]
    description = "Conexion al ALB del backend"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS saliente"
  }

  tags = merge(var.common_tags, { 
    Name      = "sg-apim-vpc-link"
    Component = "APIM"
  })
}

resource "aws_security_group" "apim_backend_sg" {
  name        = "apim-backend-sg"
  vpc_id      = aws_vpc.vpc_bancaria.id
  description = "Security group para backend del APIM - permite trafico desde VPC Link"

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.apim_vpc_link_sg.id]
    description     = "Trafico desde VPC Link del APIM"
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.apim_vpc_link_sg.id]
    description     = "Trafico HTTP desde VPC Link al ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { 
    Name      = "sg-apim-backend"
    Component = "APIM"
  })
}

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
  security_group_ids = [aws_security_group.apim_vpc_link_sg.id]
  
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

output "apim_backend_sg_id" {
  description = "Security Group ID del backend (para que Kris configure mTLS)"
  value       = aws_security_group.apim_backend_sg.id
}

output "apim_vpc_link_sg_id" {
  description = "Security Group ID del VPC Link"
  value       = aws_security_group.apim_vpc_link_sg.id
}
