# =============================================================================
# APIM OUTPUTS - Outputs del API Gateway (Brayan)
# =============================================================================

output "apim_stage_invoke_url" {
  description = "URL base del stage del APIM"
  value       = aws_apigatewayv2_stage.apim_stage.invoke_url
}

output "apim_endpoint_transfers" {
  description = "Endpoint POST /api/v2/switch/transfers"
  value       = "${aws_apigatewayv2_stage.apim_stage.invoke_url}/api/v2/switch/transfers"
}

output "apim_endpoint_transfers_status" {
  description = "Endpoint GET /api/v2/switch/transfers/{instructionId}"
  value       = "${aws_apigatewayv2_stage.apim_stage.invoke_url}/api/v2/switch/transfers/{instructionId}"
}

output "apim_endpoint_transfers_return" {
  description = "Endpoint POST /api/v2/switch/transfers/return"
  value       = "${aws_apigatewayv2_stage.apim_stage.invoke_url}/api/v2/switch/transfers/return"
}

output "apim_endpoint_funding" {
  description = "Endpoint GET /funding/{bankId}"
  value       = "${aws_apigatewayv2_stage.apim_stage.invoke_url}/funding/{bankId}"
}

output "apim_waf_arn" {
  description = "ARN del WAF Web ACL"
  value       = aws_wafv2_web_acl.switch_waf.arn
}

output "apim_circuit_breaker_topic_arn" {
  description = "SNS Topic ARN para alertas del Circuit Breaker"
  value       = aws_sns_topic.circuit_breaker_alerts.arn
}
