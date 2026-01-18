# =============================================================================
# APIM ROUTES - Definición de Rutas del Switch (Brayan)
# =============================================================================
# Usa los recursos creados por Christian en apim.tf:
# - aws_apigatewayv2_api.apim_gateway
# - aws_apigatewayv2_vpc_link.apim_vpc_link
# - aws_apigatewayv2_stage.apim_stage (ya tiene throttling 50-100 TPS)
# =============================================================================

# -----------------------------------------------------------------------------
# Variables para Backend URL
# -----------------------------------------------------------------------------
variable "apim_backend_base_url" {
  description = "URL base del backend interno (Core del Switch)"
  type        = string
  default     = "http://backend.internal:8080"
}

variable "apim_integration_timeout_ms" {
  description = "Timeout de integración con backend (ms)"
  type        = number
  default     = 29000 # 29 segundos (máximo API Gateway)
}

# -----------------------------------------------------------------------------
# Integración Backend - POST /api/v2/switch/transfers (RF-01)
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "backend_transfers" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "${var.apim_backend_base_url}/api/v2/switch/transfers"
  
  integration_method     = "POST"
  payload_format_version = "1.0"
  timeout_milliseconds   = var.apim_integration_timeout_ms
}

resource "aws_apigatewayv2_route" "transfers_post" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/transfers"
  target    = "integrations/${aws_apigatewayv2_integration.backend_transfers.id}"
}

# -----------------------------------------------------------------------------
# Integración Backend - GET /api/v2/switch/transfers/{instructionId} (RF-04)
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "backend_transfers_get" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "${var.apim_backend_base_url}/api/v2/switch/transfers/{instructionId}"
  
  integration_method     = "GET"
  payload_format_version = "1.0"
  timeout_milliseconds   = var.apim_integration_timeout_ms
}

resource "aws_apigatewayv2_route" "transfers_get" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /api/v2/switch/transfers/{instructionId}"
  target    = "integrations/${aws_apigatewayv2_integration.backend_transfers_get.id}"
}

# -----------------------------------------------------------------------------
# Integración Backend - POST /api/v2/switch/transfers/return (RF-07)
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "backend_transfers_return" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "${var.apim_backend_base_url}/api/v2/switch/transfers/return"
  
  integration_method     = "POST"
  payload_format_version = "1.0"
  timeout_milliseconds   = var.apim_integration_timeout_ms
}

resource "aws_apigatewayv2_route" "transfers_return" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/transfers/return"
  target    = "integrations/${aws_apigatewayv2_integration.backend_transfers_return.id}"
}

# -----------------------------------------------------------------------------
# Integración Backend - GET /funding/{bankId} (RF-01.1)
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "backend_funding" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "${var.apim_backend_base_url}/funding/{bankId}"
  
  integration_method     = "GET"
  payload_format_version = "1.0"
  timeout_milliseconds   = var.apim_integration_timeout_ms
}

resource "aws_apigatewayv2_route" "funding_get" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /funding/{bankId}"
  target    = "integrations/${aws_apigatewayv2_integration.backend_funding.id}"
}

# -----------------------------------------------------------------------------
# Outputs de Rutas
# -----------------------------------------------------------------------------
output "apim_route_transfers_post" {
  description = "Route ID - POST /api/v2/switch/transfers"
  value       = aws_apigatewayv2_route.transfers_post.id
}

output "apim_route_transfers_get" {
  description = "Route ID - GET /api/v2/switch/transfers/{instructionId}"
  value       = aws_apigatewayv2_route.transfers_get.id
}

output "apim_route_return" {
  description = "Route ID - POST /api/v2/switch/transfers/return"
  value       = aws_apigatewayv2_route.transfers_return.id
}

output "apim_route_funding" {
  description = "Route ID - GET /funding/{bankId}"
  value       = aws_apigatewayv2_route.funding_get.id
}
