# =============================================================================
# APIM RATE LIMITING - Protección Anti-DDoS (Brayan)
# =============================================================================
# ERS: 50 TPS sostenidos, escalable a 100 TPS
# =============================================================================

# -----------------------------------------------------------------------------
# Stage con Throttling (Rate Limiting)
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_stage" "apim_stage" {
  api_id      = aws_apigatewayv2_api.apim_gateway.id
  name        = var.environment
  auto_deploy = true

  # Rate limiting por defecto
  default_route_settings {
    throttling_burst_limit = var.apim_rate_limit_burst     # 100 TPS pico
    throttling_rate_limit  = var.apim_rate_limit_per_second # 50 TPS sostenidos
  }

  # Throttling específico por ruta
  route_settings {
    route_key              = "POST /api/v2/switch/transfers"
    throttling_burst_limit = var.apim_rate_limit_burst
    throttling_rate_limit  = var.apim_rate_limit_per_second
  }

  route_settings {
    route_key              = "GET /api/v2/switch/transfers/{instructionId}"
    throttling_burst_limit = var.apim_rate_limit_burst
    throttling_rate_limit  = var.apim_rate_limit_per_second
  }

  route_settings {
    route_key              = "POST /api/v2/switch/transfers/return"
    throttling_burst_limit = var.apim_rate_limit_burst
    throttling_rate_limit  = var.apim_rate_limit_per_second
  }

  route_settings {
    route_key              = "GET /funding/{bankId}"
    throttling_burst_limit = var.apim_rate_limit_burst
    throttling_rate_limit  = var.apim_rate_limit_per_second
  }

  # Logs de acceso
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apim_access_logs.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      requestTime        = "$context.requestTime"
      httpMethod         = "$context.httpMethod"
      routeKey           = "$context.routeKey"
      status             = "$context.status"
      protocol           = "$context.protocol"
      responseLength     = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
      responseLatency    = "$context.responseLatency"
      errorMessage       = "$context.error.message"
    })
  }

  tags = {
    Name        = "${var.environment}-switch-apim-stage"
    Environment = var.environment
    Component   = "APIM-RateLimiting"
    ManagedBy   = "terraform"
  }

  depends_on = [
    aws_apigatewayv2_route.transfers_post,
    aws_apigatewayv2_route.transfers_get,
    aws_apigatewayv2_route.transfers_return,
    aws_apigatewayv2_route.funding_get,
    aws_cloudwatch_log_group.apim_access_logs,
  ]
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group para Access Logs
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "apim_access_logs" {
  name              = "/aws/apigateway/${var.environment}-switch-apim"
  retention_in_days = 30

  tags = {
    Name        = "${var.environment}-apim-access-logs"
    Environment = var.environment
    Component   = "APIM-Logging"
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# WAF Web ACL para protección Anti-DDoS
# -----------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "switch_waf" {
  name        = "${var.environment}-switch-waf"
  description = "WAF para protección Anti-DDoS del Switch Transaccional"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Regla 1: Rate limiting por IP
  rule {
    name     = "RateLimitByIP"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.apim_waf_rate_limit_per_ip
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitByIP"
      sampled_requests_enabled   = true
    }
  }

  # Regla 2: Bloqueo de IPs maliciosas (AWS Managed Rules)
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  # Regla 3: Protección contra ataques comunes
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "SwitchWAF"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.environment}-switch-waf"
    Environment = var.environment
    Component   = "APIM-WAF"
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Asociación WAF con API Gateway v2
# -----------------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "switch_waf_association" {
  resource_arn = aws_apigatewayv2_stage.apim_stage.arn
  web_acl_arn  = aws_wafv2_web_acl.switch_waf.arn
}
