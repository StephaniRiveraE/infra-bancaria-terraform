variable "common_tags" {}
variable "project_name" {}
variable "environment" {}

# 1. Secreto Interno (Para validar origen en Backend)
resource "random_password" "internal_secret" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "switch_internal_secret" {
  name        = "switch/internal-api-secret-${var.environment}"
  description = "Header secreto para validar trafico del APIM"
  tags        = var.common_tags
}

resource "aws_secretsmanager_secret_version" "switch_internal_secret_val" {
  secret_id     = aws_secretsmanager_secret.switch_internal_secret.id
  secret_string = random_password.internal_secret.result
}

# 2. Cognito User Pool (Bancos)
resource "aws_cognito_user_pool" "banca_pool" {
  name = "banca-ecosistema-pool-${var.environment}"
  tags = var.common_tags
}

# 3. Dominio Auth (Para pedir tokens)
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "auth-banca-${lower(var.project_name)}-${var.environment}-${random_string.suffix.result}"
  user_pool_id = aws_cognito_user_pool.banca_pool.id
}

# 4. Scopes (Permisos)
resource "aws_cognito_resource_server" "switch_resource" {
  identifier = "https://switch-api.com"
  name       = "Switch API Resource"
  user_pool_id = aws_cognito_user_pool.banca_pool.id

  scope {
    scope_name        = "transfers.write"
    scope_description = "Permite transacciones"
  }
}

# 5. Clientes Bancarios (App Clients)
resource "aws_cognito_user_pool_client" "banco_clients" {
  for_each = toset(["ArcBank", "Bantec", "Nexus", "Ecusol"])

  name = "${each.key}-System-Client"
  user_pool_id = aws_cognito_user_pool.banca_pool.id
  
  generate_secret = true
  allowed_oauth_flows = ["client_credentials"]
  allowed_oauth_scopes = ["https://switch-api.com/transfers.write"]
  supported_identity_providers = ["COGNITO"]
}