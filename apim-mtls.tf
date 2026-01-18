# =============================================================================
# APIM - Infraestructura para mTLS (Mutual TLS)
# Responsable: Christian (infraestructura) / Kris (configuración de certificados)
# Requisito: RNF-SEC-01 - mTLS obligatorio
# 
# NOTA: El Custom Domain con mTLS está DESHABILITADO hasta tener un dominio real.
#       Para habilitarlo: configurar var.apim_enable_custom_domain = true
#       y validar el certificado ACM via DNS.
# =============================================================================

# -----------------------------------------------------------------------------
# S3 Bucket para Truststore (Certificados CA de los Bancos)
# Kris subirá aquí el archivo truststore.pem con los certificados de los bancos
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "mtls_truststore" {
  bucket = "mtls-truststore-${lower(var.project_name)}-${var.environment}"

  tags = merge(var.common_tags, {
    Name      = "mtls-truststore"
    Component = "APIM-Security"
  })
}

resource "aws_s3_bucket_versioning" "mtls_truststore_versioning" {
  bucket = aws_s3_bucket.mtls_truststore.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mtls_truststore_encryption" {
  bucket = aws_s3_bucket.mtls_truststore.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquear acceso público al truststore
resource "aws_s3_bucket_public_access_block" "mtls_truststore_block" {
  bucket = aws_s3_bucket.mtls_truststore.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Certificado dummy para inicializar truststore (Kris lo reemplazará con los certs reales)
# NOTA: Este archivo tiene formato PEM válido para que AWS no rechace el despliegue inicial
resource "aws_s3_object" "truststore_placeholder" {
  bucket = aws_s3_bucket.mtls_truststore.id
  key    = "truststore.pem"
  source = "${path.module}/dummy_cert.pem"
  etag   = filemd5("${path.module}/dummy_cert.pem")

  tags = merge(var.common_tags, {
    Name = "truststore-placeholder"
  })
}

# -----------------------------------------------------------------------------
# ACM Certificate para Custom Domain (SOLO se crea si está habilitado)
# -----------------------------------------------------------------------------
resource "aws_acm_certificate" "apim_cert" {
  count             = var.apim_enable_custom_domain ? 1 : 0
  domain_name       = var.apim_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name      = "cert-apim-switch"
    Component = "APIM"
  })
}

# -----------------------------------------------------------------------------
# Custom Domain con mTLS habilitado (SOLO se crea si está habilitado y cert validado)
# CRÍTICO: Requiere dominio real y validación DNS del certificado
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_domain_name" "apim_custom_domain" {
  count       = var.apim_enable_custom_domain ? 1 : 0
  domain_name = var.apim_domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.apim_cert[0].arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  # Configuración mTLS - Kris configurará el truststore con los certificados de los bancos
  mutual_tls_authentication {
    truststore_uri     = "s3://${aws_s3_bucket.mtls_truststore.id}/${aws_s3_object.truststore_placeholder.key}"
    truststore_version = aws_s3_object.truststore_placeholder.version_id
  }

  tags = merge(var.common_tags, {
    Name      = "domain-apim-switch"
    Component = "APIM"
  })

  depends_on = [aws_acm_certificate.apim_cert]
}

# -----------------------------------------------------------------------------
# API Mapping - Conecta el Custom Domain con el API Gateway
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_api_mapping" "apim_mapping" {
  count       = var.apim_enable_custom_domain ? 1 : 0
  api_id      = aws_apigatewayv2_api.apim_gateway.id
  domain_name = aws_apigatewayv2_domain_name.apim_custom_domain[0].id
  stage       = aws_apigatewayv2_stage.apim_stage.id
}

# -----------------------------------------------------------------------------
# Outputs para mTLS
# -----------------------------------------------------------------------------

output "apim_custom_domain_name" {
  description = "Custom domain para mTLS (vacío si no está habilitado)"
  value       = var.apim_enable_custom_domain ? aws_apigatewayv2_domain_name.apim_custom_domain[0].domain_name : "DISABLED - Set apim_enable_custom_domain=true"
}

output "apim_custom_domain_target" {
  description = "Target del custom domain (para configurar DNS/Route53)"
  value       = var.apim_enable_custom_domain ? aws_apigatewayv2_domain_name.apim_custom_domain[0].domain_name_configuration[0].target_domain_name : "DISABLED"
}

output "apim_truststore_bucket" {
  description = "Bucket S3 del Truststore (para que Kris suba los certificados CA)"
  value       = aws_s3_bucket.mtls_truststore.id
}

output "apim_truststore_uri" {
  description = "URI del Truststore para configuración mTLS"
  value       = "s3://${aws_s3_bucket.mtls_truststore.id}/truststore.pem"
}

output "apim_certificate_arn" {
  description = "ARN del certificado ACM (vacío si no está habilitado)"
  value       = var.apim_enable_custom_domain ? aws_acm_certificate.apim_cert[0].arn : "DISABLED"
}

output "apim_certificate_validation_options" {
  description = "Opciones de validación DNS del certificado (crear registro CNAME)"
  value       = var.apim_enable_custom_domain ? aws_acm_certificate.apim_cert[0].domain_validation_options : []
}
