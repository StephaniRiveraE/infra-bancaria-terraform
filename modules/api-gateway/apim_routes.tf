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

resource "aws_lb" "apim_backend_alb" {
  name               = "apim-backend-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.backend_security_group_id]
  subnets            = var.private_subnet_ids
  tags               = merge(var.common_tags, { Name = "alb-apim-backend" })
}

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

  lifecycle {
    create_before_destroy = true
  }
}

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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "tg_contabilidad" {
  name        = "apim-tg-contabilidad"
  port        = 8080
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

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group para ms-devolucion (Reversos - pacs.004)
resource "aws_lb_target_group" "tg_devolucion" {
  name        = "apim-tg-devolucion"
  port        = 8085
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/actuator/health/liveness"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, { Name = "tg-ms-devolucion" })

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group para ms-directorio (Account Lookup - acmt.023)
resource "aws_lb_target_group" "tg_directorio" {
  name        = "apim-tg-directorio"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/actuator/health/liveness"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, { Name = "tg-ms-directorio" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "apim_backend_listener" {
  load_balancer_arn = aws_lb.apim_backend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_nucleo.arn
  }
}

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

# ELIMINADAS: Las reglas ALB para devolucion (rule 300) y directorio (rule 400).
# Motivo: returns y account-lookup ahora se procesan a traves del BFF en ms-nucleo,
# que internamente invoca a ms-devolucion y ms-directorio via service discovery K8s.
# Los Target Groups (tg_devolucion, tg_directorio) se mantienen como reserva.

resource "aws_apigatewayv2_integration" "integration_nucleo" {
  api_id = aws_apigatewayv2_api.apim_gateway.id

  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = aws_lb_listener.apim_backend_listener.arn
  integration_method     = "ANY"
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:path"                   = "$request.path"
    "overwrite:header.x-origin-secret" = var.internal_secret_value
  }

  lifecycle {
    create_before_destroy = true
  }
}

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
    "overwrite:path"                   = "$request.path"
    "overwrite:header.x-origin-secret" = var.internal_secret_value
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_integration" "integration_contabilidad" {
  api_id = aws_apigatewayv2_api.apim_gateway.id

  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = aws_lb_listener.apim_backend_listener.arn
  integration_method     = "POST"
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:path"                   = "$request.path"
    "overwrite:header.x-origin-secret" = var.internal_secret_value
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_integration" "integration_health" {
  api_id = aws_apigatewayv2_api.apim_gateway.id

  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = aws_lb_listener.apim_backend_listener.arn
  integration_method     = "GET"
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:path" = "$request.path"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_route" "transfers_post" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/transfers"
  target    = "integrations/${aws_apigatewayv2_integration.integration_nucleo.id}"

  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_scopes = ["https://switch-api.com/transfers.write"]
}

resource "aws_apigatewayv2_route" "transfers_get_status" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /api/v2/switch/transfers/{instructionId}"
  target    = "integrations/${aws_apigatewayv2_integration.integration_nucleo.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_apigatewayv2_route" "accounts_lookup" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/account-lookup"
  target    = "integrations/${aws_apigatewayv2_integration.integration_nucleo.id}"

  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_scopes = ["https://switch-api.com/transfers.write"]
}

resource "aws_apigatewayv2_route" "transfers_return" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/returns"
  target    = "integrations/${aws_apigatewayv2_integration.integration_nucleo.id}"

  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_scopes = ["https://switch-api.com/transfers.write"]
}

resource "aws_apigatewayv2_route" "compensation_upload" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/compensation/upload"
  target    = "integrations/${aws_apigatewayv2_integration.integration_compensacion.id}"

  authorization_type   = "JWT"
  authorizer_id        = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_scopes = ["https://switch-api.com/transfers.write"]
}

resource "aws_apigatewayv2_route" "funding_query" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/funding"
  target    = "integrations/${aws_apigatewayv2_integration.integration_contabilidad.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_apigatewayv2_route" "health_switch" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /api/v2/switch/health"
  target    = "integrations/${aws_apigatewayv2_integration.integration_health.id}"

  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "health_compensation" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /api/v2/compensation/health"
  target    = "integrations/${aws_apigatewayv2_integration.integration_health.id}"

  authorization_type = "NONE"
}

# ─────────────────────────────────────────────────────────────────────
# Rutas BFF Admin (ms-nucleo expone endpoints de administracion)
# Nucleo actua como BFF: recibe la peticion y la delega internamente
# a ms-directorio o ms-contabilidad via service discovery K8s.
# ─────────────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_route" "admin_instituciones_get" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /api/v2/switch/admin/instituciones"
  target    = "integrations/${aws_apigatewayv2_integration.integration_nucleo.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_apigatewayv2_route" "admin_instituciones_post" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/admin/instituciones"
  target    = "integrations/${aws_apigatewayv2_integration.integration_nucleo.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_apigatewayv2_route" "admin_ledger_cuentas" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/admin/ledger/cuentas"
  target    = "integrations/${aws_apigatewayv2_integration.integration_nucleo.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_apigatewayv2_route" "admin_funding_recharge" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/admin/funding/recharge"
  target    = "integrations/${aws_apigatewayv2_integration.integration_nucleo.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

# ─────────────────────────────────────────────────────────────────────
# Rutas Admin Compensación (ms-compensacion expone endpoints de gestión)
# Ciclos de compensación, posiciones, cierre (settlement) y reportes PDF.
# ─────────────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_route" "compensation_ciclos" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /api/v2/compensation/ciclos"
  target    = "integrations/${aws_apigatewayv2_integration.integration_compensacion.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_apigatewayv2_route" "compensation_ciclo_posiciones" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /api/v2/compensation/ciclos/{cicloId}/posiciones"
  target    = "integrations/${aws_apigatewayv2_integration.integration_compensacion.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_apigatewayv2_route" "compensation_ciclo_cierre" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/compensation/ciclos/{cicloId}/cierre"
  target    = "integrations/${aws_apigatewayv2_integration.integration_compensacion.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}

resource "aws_apigatewayv2_route" "compensation_reporte_pdf" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /api/v2/compensation/reporte/pdf/{cicloId}"
  target    = "integrations/${aws_apigatewayv2_integration.integration_compensacion.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
}
