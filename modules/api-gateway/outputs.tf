# ============================================================================
# API GATEWAY OUTPUTS
# ============================================================================

output "apim_gateway_endpoint" {
  description = "Endpoint HTTPS del API Gateway"
  value       = aws_apigatewayv2_api.apim_gateway.api_endpoint
}

output "apim_gateway_id" {
  description = "ID del API Gateway"
  value       = aws_apigatewayv2_api.apim_gateway.id
}

output "apim_stage_name" {
  description = "Nombre del stage"
  value       = aws_apigatewayv2_stage.apim_stage.name
}

output "apim_vpc_link_id" {
  description = "ID del VPC Link"
  value       = aws_apigatewayv2_vpc_link.apim_vpc_link.id
}
