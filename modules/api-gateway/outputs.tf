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

output "alb_arn" {
  description = "ARN del ALB interno"
  value       = aws_lb.apim_backend_alb.arn
}

output "alb_dns_name" {
  description = "DNS del ALB interno"
  value       = aws_lb.apim_backend_alb.dns_name
}

output "tg_nucleo_arn" {
  description = "ARN del Target Group de ms-nucleo (puerto 8082)"
  value       = aws_lb_target_group.tg_nucleo.arn
}

output "tg_compensacion_arn" {
  description = "ARN del Target Group de ms-compensacion (puerto 8084)"
  value       = aws_lb_target_group.tg_compensacion.arn
}

output "tg_contabilidad_arn" {
  description = "ARN del Target Group de ms-contabilidad (puerto 8083)"
  value       = aws_lb_target_group.tg_contabilidad.arn
}

output "tg_devolucion_arn" {
  description = "ARN del Target Group de ms-devolucion (puerto 8085)"
  value       = aws_lb_target_group.tg_devolucion.arn
}

output "tg_directorio_arn" {
  description = "ARN del Target Group de ms-directorio (puerto 8081)"
  value       = aws_lb_target_group.tg_directorio.arn
}
