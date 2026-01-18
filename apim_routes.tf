variable "apim_backend_port" {
  description = "Puerto del backend"
  type        = number
  default     = 8080
}

variable "apim_integration_timeout_ms" {
  description = "Timeout de integración con backend (ms)"
  type        = number
  default     = 29000
}

resource "aws_lb" "apim_backend_alb" {
  name               = "apim-backend-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.apim_backend_sg.id]
  
  subnets = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  tags = merge(var.common_tags, {
    Name      = "alb-apim-backend"
    Component = "APIM"
  })
}

resource "aws_lb_target_group" "apim_backend_tg" {
  name        = "apim-backend-tg"
  port        = var.apim_backend_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_bancaria.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-299"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, {
    Name      = "tg-apim-backend"
    Component = "APIM"
  })
}

resource "aws_lb_listener" "apim_backend_listener" {
  load_balancer_arn = aws_lb.apim_backend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apim_backend_tg.arn
  }

  tags = merge(var.common_tags, {
    Name      = "listener-apim-backend"
    Component = "APIM"
  })
}

resource "aws_apigatewayv2_integration" "backend_transfers" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.apim_backend_listener.arn
  
  integration_method     = "POST"
  payload_format_version = "1.0"
  timeout_milliseconds   = var.apim_integration_timeout_ms

  request_parameters = {
    "overwrite:path" = "/api/v2/switch/transfers"
  }

  depends_on = [
    aws_lb_listener.apim_backend_listener,
    aws_apigatewayv2_vpc_link.apim_vpc_link
  ]
}

resource "aws_apigatewayv2_route" "transfers_post" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/transfers"
  target    = "integrations/${aws_apigatewayv2_integration.backend_transfers.id}"
}

resource "aws_apigatewayv2_integration" "backend_transfers_get" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.apim_backend_listener.arn
  
  integration_method     = "GET"
  payload_format_version = "1.0"
  timeout_milliseconds   = var.apim_integration_timeout_ms

  request_parameters = {
    "overwrite:path" = "/api/v2/switch/transfers/$request.path.instructionId"
  }

  depends_on = [
    aws_lb_listener.apim_backend_listener,
    aws_apigatewayv2_vpc_link.apim_vpc_link
  ]
}

resource "aws_apigatewayv2_route" "transfers_get" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /api/v2/switch/transfers/{instructionId}"
  target    = "integrations/${aws_apigatewayv2_integration.backend_transfers_get.id}"
}

resource "aws_apigatewayv2_integration" "backend_transfers_return" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.apim_backend_listener.arn
  
  integration_method     = "POST"
  payload_format_version = "1.0"
  timeout_milliseconds   = var.apim_integration_timeout_ms

  request_parameters = {
    "overwrite:path" = "/api/v2/switch/transfers/return"
  }

  depends_on = [
    aws_lb_listener.apim_backend_listener,
    aws_apigatewayv2_vpc_link.apim_vpc_link
  ]
}

resource "aws_apigatewayv2_route" "transfers_return" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/transfers/return"
  target    = "integrations/${aws_apigatewayv2_integration.backend_transfers_return.id}"
}

resource "aws_apigatewayv2_integration" "backend_funding" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.apim_backend_listener.arn
  
  integration_method     = "GET"
  payload_format_version = "1.0"
  timeout_milliseconds   = var.apim_integration_timeout_ms

  request_parameters = {
    "overwrite:path" = "/funding/$request.path.bankId"
  }

  depends_on = [
    aws_lb_listener.apim_backend_listener,
    aws_apigatewayv2_vpc_link.apim_vpc_link
  ]
}

resource "aws_apigatewayv2_route" "funding_get" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "GET /funding/{bankId}"
  target    = "integrations/${aws_apigatewayv2_integration.backend_funding.id}"
}

output "apim_backend_alb_arn" {
  description = "ARN del ALB del backend"
  value       = aws_lb.apim_backend_alb.arn
}

output "apim_backend_alb_dns" {
  description = "DNS del ALB del backend"
  value       = aws_lb.apim_backend_alb.dns_name
}

output "apim_backend_target_group_arn" {
  description = "ARN del Target Group (para registrar instancias del backend)"
  value       = aws_lb_target_group.apim_backend_tg.arn
}

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
