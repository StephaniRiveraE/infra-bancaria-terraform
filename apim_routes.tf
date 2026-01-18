# =============================================================================
# APIM ROUTES - Rutas del API Gateway (Brayan)
# =============================================================================
# Usa los recursos base creados por Christian:
# - aws_apigatewayv2_api.apim_gateway
# - aws_apigatewayv2_vpc_link.apim_vpc_link
# =============================================================================

# -----------------------------------------------------------------------------
# Integración Backend - Conexión VPC Link al Core del Switch
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "backend_transfers" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "${var.apim_backend_base_url}/api/v2/switch/transfers"
  
  integration_method       = "POST"
  payload_format_version   = "1.0"
  timeout_milliseconds     = var.apim_integration_timeout_ms
}

resource "aws_apigatewayv2_integration" "backend_transfers_get" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "${var.apim_backend_base_url}/api/v2/switch/transfers/{instructionId}"
  
  integration_method       = "GET"
  payload_format_version   = "1.0"
  timeout_milliseconds     = var.apim_integration_timeout_ms
}

resource "aws_apigatewayv2_integration" "backend_transfers_return" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "${var.apim_backend_base_url}/api/v2/switch/transfers/return"
  
  integration_method       = "POST"
  payload_format_version   = "1.0"
  timeout_milliseconds     = var.apim_integration_timeout_ms
}

resource "aws_apigatewayv2_integration" "backend_funding" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "${var.apim_backend_base_url}/funding/{bankId}"
  
  integration_method       = "GET"
  payload_format_version   = "1.0"
  timeout_milliseconds     = var.apim_integration_timeout_ms
}

# -----------------------------------------------------------------------------
# RUTA: POST /api/v2/switch/transfers - Inicio de transferencia (RF-01)
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_route" "transfers_post" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/transfers"
  target    = "integrations/${aws_apigatewayv2_integration.backend_transfers.id}"
}

# -----------------------------------------------------------------------------
# RUTA: GET /api/v2/switch/transfers/{instructionId} - Consulta estado (RF-04)
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_route" "transfers_get" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /api/v2/switch/transfers/{instructionId}"
  target    = "integrations/${aws_apigatewayv2_integration.backend_transfers_get.id}"
}

# -----------------------------------------------------------------------------
# RUTA: POST /api/v2/switch/transfers/return - Devolución/Reverso (RF-07)
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_route" "transfers_return" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/transfers/return"
  target    = "integrations/${aws_apigatewayv2_integration.backend_transfers_return.id}"
}

# -----------------------------------------------------------------------------
# RUTA: GET /funding/{bankId} - Consulta de saldo técnico (RF-01.1)
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_route" "funding_get" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /funding/{bankId}"
  target    = "integrations/${aws_apigatewayv2_integration.backend_funding.id}"
}
