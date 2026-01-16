# =============================================================================
# API GATEWAY - Usage Plans y API Keys
# =============================================================================
# Configuración para facturación: API Keys por banco y Usage Plans con quotas
# =============================================================================

# -----------------------------------------------------------------------------
# API Keys para Bancos
# -----------------------------------------------------------------------------

resource "aws_api_gateway_api_key" "bank" {
  for_each = var.banks

  name        = "${each.key}-api-key"
  description = "API Key para ${each.value.name}"
  enabled     = true

  tags = merge(var.common_tags, {
    Name = "${each.key}-api-key"
    Bank = each.value.name
  })
}

# -----------------------------------------------------------------------------
# API Key para Switch
# -----------------------------------------------------------------------------

resource "aws_api_gateway_api_key" "switch" {
  name        = "switch-api-key"
  description = "API Key para ${var.switch_config.name}"
  enabled     = true

  tags = merge(var.common_tags, {
    Name      = "switch-api-key"
    Component = "switch"
  })
}

# -----------------------------------------------------------------------------
# Usage Plans para Bancos
# -----------------------------------------------------------------------------

resource "aws_api_gateway_usage_plan" "bank" {
  for_each = var.banks

  name        = "usage-plan-${each.key}"
  description = "Plan de uso para ${each.value.name} - Límites y quotas"

  api_stages {
    api_id = aws_api_gateway_rest_api.bancario.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

  # Rate limiting (requests por segundo)
  throttle_settings {
    rate_limit  = each.value.rate_limit
    burst_limit = each.value.burst_limit
  }

  # Quota (requests por período)
  quota_settings {
    limit  = each.value.quota_limit
    period = each.value.quota_period
  }

  tags = merge(var.common_tags, {
    Name = "usage-plan-${each.key}"
    Bank = each.value.name
  })
}

# -----------------------------------------------------------------------------
# Usage Plan para Switch
# -----------------------------------------------------------------------------

resource "aws_api_gateway_usage_plan" "switch" {
  name        = "usage-plan-switch"
  description = "Plan de uso para ${var.switch_config.name} - Límites y quotas"

  api_stages {
    api_id = aws_api_gateway_rest_api.bancario.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

  throttle_settings {
    rate_limit  = var.switch_config.rate_limit
    burst_limit = var.switch_config.burst_limit
  }

  quota_settings {
    limit  = var.switch_config.quota_limit
    period = var.switch_config.quota_period
  }

  tags = merge(var.common_tags, {
    Name      = "usage-plan-switch"
    Component = "switch"
  })
}

# -----------------------------------------------------------------------------
# Asociación de API Keys con Usage Plans (Bancos)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_usage_plan_key" "bank" {
  for_each = var.banks

  key_id        = aws_api_gateway_api_key.bank[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.bank[each.key].id
}

# -----------------------------------------------------------------------------
# Asociación de API Key con Usage Plan (Switch)
# -----------------------------------------------------------------------------

resource "aws_api_gateway_usage_plan_key" "switch" {
  key_id        = aws_api_gateway_api_key.switch.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.switch.id
}
