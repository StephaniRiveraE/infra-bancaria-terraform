# =============================================================================
# API GATEWAY - REST API Principal
# =============================================================================
# Define la API REST, recursos y métodos para el ecosistema bancario
# =============================================================================

# -----------------------------------------------------------------------------
# REST API Principal
# -----------------------------------------------------------------------------

resource "aws_api_gateway_rest_api" "bancario" {
  name        = var.api_gateway_name
  description = var.api_gateway_description

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(var.common_tags, {
    Name = var.api_gateway_name
  })
}

# -----------------------------------------------------------------------------
# Resources para Bancos (/{banco})
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "bank" {
  for_each = var.banks

  rest_api_id = aws_api_gateway_rest_api.bancario.id
  parent_id   = aws_api_gateway_rest_api.bancario.root_resource_id
  path_part   = each.key
}

# -----------------------------------------------------------------------------
# Resources para Endpoints de Bancos (/{banco}/{endpoint})
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "bank_endpoint" {
  for_each = {
    for pair in flatten([
      for bank_key, bank in var.banks : [
        for endpoint in var.bank_endpoints : {
          key      = "${bank_key}-${endpoint}"
          bank_key = bank_key
          endpoint = endpoint
        }
      ]
    ]) : pair.key => pair
  }

  rest_api_id = aws_api_gateway_rest_api.bancario.id
  parent_id   = aws_api_gateway_resource.bank[each.value.bank_key].id
  path_part   = each.value.endpoint
}

# -----------------------------------------------------------------------------
# Métodos POST para Endpoints de Bancos
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "bank_endpoint_post" {
  for_each = aws_api_gateway_resource.bank_endpoint

  rest_api_id      = aws_api_gateway_rest_api.bancario.id
  resource_id      = each.value.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

# -----------------------------------------------------------------------------
# Integración MOCK para Endpoints de Bancos (placeholder)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_integration" "bank_endpoint_mock" {
  for_each = aws_api_gateway_method.bank_endpoint_post

  rest_api_id = aws_api_gateway_rest_api.bancario.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# -----------------------------------------------------------------------------
# Respuesta de Integración para Endpoints de Bancos
# -----------------------------------------------------------------------------

resource "aws_api_gateway_integration_response" "bank_endpoint_mock" {
  for_each = aws_api_gateway_integration.bank_endpoint_mock

  rest_api_id = aws_api_gateway_rest_api.bancario.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  status_code = "200"

  response_templates = {
    "application/json" = jsonencode({
      message   = "Endpoint placeholder - Pendiente de implementación"
      endpoint  = split("-", each.key)[1]
      bank      = split("-", each.key)[0]
      timestamp = "$context.requestTime"
    })
  }

  depends_on = [aws_api_gateway_method_response.bank_endpoint_200]
}

# -----------------------------------------------------------------------------
# Method Response para Endpoints de Bancos
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method_response" "bank_endpoint_200" {
  for_each = aws_api_gateway_method.bank_endpoint_post

  rest_api_id = aws_api_gateway_rest_api.bancario.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# -----------------------------------------------------------------------------
# Resource para Switch (/switch)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "switch" {
  rest_api_id = aws_api_gateway_rest_api.bancario.id
  parent_id   = aws_api_gateway_rest_api.bancario.root_resource_id
  path_part   = "switch"
}

# -----------------------------------------------------------------------------
# Resources para Endpoints del Switch (/switch/{endpoint})
# -----------------------------------------------------------------------------

resource "aws_api_gateway_resource" "switch_endpoint" {
  for_each = { for ep in var.switch_endpoints : ep.path => ep }

  rest_api_id = aws_api_gateway_rest_api.bancario.id
  parent_id   = aws_api_gateway_resource.switch.id
  path_part   = each.value.path
}

# -----------------------------------------------------------------------------
# Métodos para Endpoints del Switch
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method" "switch_endpoint" {
  for_each = { for ep in var.switch_endpoints : ep.path => ep }

  rest_api_id      = aws_api_gateway_rest_api.bancario.id
  resource_id      = aws_api_gateway_resource.switch_endpoint[each.key].id
  http_method      = each.value.method
  authorization    = "NONE"
  api_key_required = true
}

# -----------------------------------------------------------------------------
# Integración MOCK para Endpoints del Switch (placeholder)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_integration" "switch_endpoint_mock" {
  for_each = aws_api_gateway_method.switch_endpoint

  rest_api_id = aws_api_gateway_rest_api.bancario.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# -----------------------------------------------------------------------------
# Method Response para Endpoints del Switch
# -----------------------------------------------------------------------------

resource "aws_api_gateway_method_response" "switch_endpoint_200" {
  for_each = aws_api_gateway_method.switch_endpoint

  rest_api_id = aws_api_gateway_rest_api.bancario.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# -----------------------------------------------------------------------------
# Respuesta de Integración para Endpoints del Switch
# -----------------------------------------------------------------------------

resource "aws_api_gateway_integration_response" "switch_endpoint_mock" {
  for_each = aws_api_gateway_integration.switch_endpoint_mock

  rest_api_id = aws_api_gateway_rest_api.bancario.id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  status_code = "200"

  response_templates = {
    "application/json" = jsonencode({
      message   = "Switch endpoint placeholder - Pendiente de implementación"
      endpoint  = each.key
      timestamp = "$context.requestTime"
    })
  }

  depends_on = [aws_api_gateway_method_response.switch_endpoint_200]
}
