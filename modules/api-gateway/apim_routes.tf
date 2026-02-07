# ============================================================================
# AUTHORIZER (CAPA 1: IDENTIDAD)
# Valida que el Token JWT venga firmado por tu Cognito
# ============================================================================
resource "aws_apigatewayv2_authorizer" "cognito_auth" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "Cognito-Authorizer"

  jwt_configuration {
    audience = var.cognito_client_ids
    issuer   = "https://${var.cognito_endpoint}"
  }
}

# ============================================================================
# LOAD BALANCER INTERNO (DESTINO PRIVADO)
# ============================================================================
resource "aws_lb" "apim_backend_alb" {
  name               = "apim-backend-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.backend_security_group_id]
  subnets            = var.private_subnet_ids
  tags               = merge(var.common_tags, { Name = "alb-apim-backend" })
}

resource "aws_lb_target_group" "apim_backend_tg" {
  name        = "apim-backend-tg"
  port        = var.apim_backend_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled = true
    path    = "/health"
    matcher = "200-299"
  }
}

resource "aws_lb_listener" "apim_backend_listener" {
  load_balancer_arn = aws_lb.apim_backend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apim_backend_tg.arn
  }
}

# ============================================================================
# RUTA 1: TRANSFERENCIAS (Transaccional)
# Flujo: OAuth -> VPC Link -> Header Secreto
# ============================================================================
resource "aws_apigatewayv2_integration" "backend_transfers" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  
  # CAPA 2: Conexión Privada (VPC Link)
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  
  integration_type   = "HTTP_PROXY"
  integration_uri    = aws_lb_listener.apim_backend_listener.arn
  integration_method = "POST"
  payload_format_version = "1.0"

  # CAPA 3: Integridad (Secret Injection)
  request_parameters = {
    "overwrite:path"                   = "/api/v2/switch/transfers"
    "overwrite:header.x-origin-secret" = var.internal_secret_value
  }
}

resource "aws_apigatewayv2_route" "transfers_post" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/transfers"
  target    = "integrations/${aws_apigatewayv2_integration.backend_transfers.id}"

  # Seguridad Modernizada (Solo OAuth)
  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_scopes = ["https://switch-api.com/transfers.write"]
}

# ============================================================================
# RUTA 2: COMPENSACIÓN (Carga de Archivos)
# ============================================================================
resource "aws_apigatewayv2_integration" "backend_compensation" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  
  integration_type   = "HTTP_PROXY"
  integration_uri    = aws_lb_listener.apim_backend_listener.arn
  integration_method = "POST"
  payload_format_version = "1.0"
  
  timeout_milliseconds   = 29000 # Timeout extendido para archivos

  request_parameters = {
    "overwrite:path"                   = "/api/v2/compensation/upload"
    "overwrite:header.x-origin-secret" = var.internal_secret_value
  }
}

resource "aws_apigatewayv2_route" "compensation_upload" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/compensation/upload"
  target    = "integrations/${aws_apigatewayv2_integration.backend_compensation.id}"

  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_scopes = ["https://switch-api.com/transfers.write"]
}