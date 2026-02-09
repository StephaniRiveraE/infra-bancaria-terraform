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
# ALB con múltiples Target Groups por microservicio
# ============================================================================
resource "aws_lb" "apim_backend_alb" {
  name               = "apim-backend-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.backend_security_group_id]
  subnets            = var.private_subnet_ids
  tags               = merge(var.common_tags, { Name = "alb-apim-backend" })
}

# ============================================================================
# TARGET GROUPS - Uno por microservicio
# ============================================================================

# Target Group para ms-nucleo (Transacciones, Accounts, Returns)
resource "aws_lb_target_group" "tg_nucleo" {
  name        = "apim-tg-nucleo"
  port        = 8082
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/api/v2/switch/health"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, { Name = "tg-ms-nucleo" })
}

# Target Group para ms-compensacion (Upload de archivos)
resource "aws_lb_target_group" "tg_compensacion" {
  name        = "apim-tg-compensacion"
  port        = 8084
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/api/v2/compensation/health"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, { Name = "tg-ms-compensacion" })
}

# Target Group para ms-contabilidad (Fondeo/Saldos)
resource "aws_lb_target_group" "tg_contabilidad" {
  name        = "apim-tg-contabilidad"
  port        = 8083
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/health"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, { Name = "tg-ms-contabilidad" })
}

# ============================================================================
# LISTENER - Con reglas de ruteo por path
# ============================================================================
resource "aws_lb_listener" "apim_backend_listener" {
  load_balancer_arn = aws_lb.apim_backend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_nucleo.arn
  }
}

# Regla: /api/v2/compensation/* -> ms-compensacion
resource "aws_lb_listener_rule" "route_compensacion" {
  listener_arn = aws_lb_listener.apim_backend_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_compensacion.arn
  }

  condition {
    path_pattern {
      values = ["/api/v2/compensation/*"]
    }
  }
}

# Regla: /funding* -> ms-contabilidad
resource "aws_lb_listener_rule" "route_funding" {
  listener_arn = aws_lb_listener.apim_backend_listener.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_contabilidad.arn
  }

  condition {
    path_pattern {
      values = ["/api/v2/switch/funding*"]
    }
  }
}

# ============================================================================
# INTEGRACIÓN: ms-nucleo (para todas las rutas de /switch/)
# ============================================================================
resource "aws_apigatewayv2_integration" "integration_nucleo" {
  api_id = aws_apigatewayv2_api.apim_gateway.id

  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = aws_lb_listener.apim_backend_listener.arn
  integration_method     = "ANY"
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:header.x-origin-secret" = var.internal_secret_value
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# INTEGRACIÓN: ms-compensacion (timeout extendido para uploads)
# ============================================================================
resource "aws_apigatewayv2_integration" "integration_compensacion" {
  api_id = aws_apigatewayv2_api.apim_gateway.id

  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = aws_lb_listener.apim_backend_listener.arn
  integration_method     = "POST"
  payload_format_version = "1.0"
  timeout_milliseconds   = 29000

  request_parameters = {
    "overwrite:path"                   = "/api/v2/compensation/upload"
    "overwrite:header.x-origin-secret" = var.internal_secret_value
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# INTEGRACIÓN: ms-contabilidad (para /funding)
# ============================================================================
resource "aws_apigatewayv2_integration" "integration_contabilidad" {
  api_id = aws_apigatewayv2_api.apim_gateway.id

  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = aws_lb_listener.apim_backend_listener.arn
  integration_method     = "POST"
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:path"                   = "/api/v2/switch/funding"
    "overwrite:header.x-origin-secret" = var.internal_secret_value
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# INTEGRACIÓN: Health Checks (sin modificar headers)
# ============================================================================
resource "aws_apigatewayv2_integration" "integration_health" {
  api_id = aws_apigatewayv2_api.apim_gateway.id

  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = aws_lb_listener.apim_backend_listener.arn
  integration_method     = "GET"
  payload_format_version = "1.0"

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# RUTA 1: POST /api/v2/switch/transfers (Crear transferencia - pacs.008)
# ============================================================================
resource "aws_apigatewayv2_route" "transfers_post" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/transfers"
  target    = "integrations/${aws_apigatewayv2_integration.integration_nucleo.id}"

  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_scopes = ["https://switch-api.com/transfers.write"]
}

# ============================================================================
# RUTA 2: GET /api/v2/switch/transfers/{instructionId} (Consulta estado)
# ============================================================================
resource "aws_apigatewayv2_route" "transfers_get_status" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /api/v2/switch/transfers/{instructionId}"
  target    = "integrations/${aws_apigatewayv2_integration.integration_nucleo.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

# ============================================================================
# RUTA 3: POST /api/v2/switch/accounts (Account Lookup - acmt.023)
# ============================================================================
resource "aws_apigatewayv2_route" "accounts_lookup" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/account-lookup"
  target    = "integrations/${aws_apigatewayv2_integration.integration_nucleo.id}"

  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_scopes = ["https://switch-api.com/transfers.write"]
}

# ============================================================================
# RUTA 4: POST /api/v2/switch/transfers/return (Devoluciones - pacs.004)
# ============================================================================
resource "aws_apigatewayv2_route" "transfers_return" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/returns"
  target    = "integrations/${aws_apigatewayv2_integration.integration_nucleo.id}"

  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_scopes = ["https://switch-api.com/transfers.write"]
}

# ============================================================================
# RUTA 5: POST /api/v2/compensation/upload (Carga de archivos)
# ============================================================================
resource "aws_apigatewayv2_route" "compensation_upload" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/compensation/upload"
  target    = "integrations/${aws_apigatewayv2_integration.integration_compensacion.id}"

  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_scopes = ["https://switch-api.com/transfers.write"]
}

# ============================================================================
# RUTA 6: GET /funding (Consulta de fondeo/saldos)
# ============================================================================
resource "aws_apigatewayv2_route" "funding_query" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/funding"
  target    = "integrations/${aws_apigatewayv2_integration.integration_contabilidad.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

# ============================================================================
# RUTA 7: GET /api/v2/switch/health (Health Check - SIN autenticación)
# ============================================================================
resource "aws_apigatewayv2_route" "health_switch" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /api/v2/switch/health"
  target    = "integrations/${aws_apigatewayv2_integration.integration_health.id}"

  authorization_type = "NONE"
}

# ============================================================================
# RUTA 8: GET /api/v2/compensation/health (Health Check - SIN autenticación)
# ============================================================================
resource "aws_apigatewayv2_route" "health_compensation" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /api/v2/compensation/health"
  target    = "integrations/${aws_apigatewayv2_integration.integration_health.id}"

  authorization_type = "NONE"
}

