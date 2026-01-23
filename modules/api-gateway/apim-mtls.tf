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

resource "aws_s3_bucket_public_access_block" "mtls_truststore_block" {
  bucket = aws_s3_bucket.mtls_truststore.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "truststore_placeholder" {
  bucket = aws_s3_bucket.mtls_truststore.id
  key    = "truststore.pem"
  source = "${path.module}/dummy_cert.pem"
  etag   = filemd5("${path.module}/dummy_cert.pem")

  tags = merge(var.common_tags, {
    Name = "truststore-placeholder"
  })
}

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

resource "aws_apigatewayv2_domain_name" "apim_custom_domain" {
  count       = var.apim_enable_custom_domain ? 1 : 0
  domain_name = var.apim_domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.apim_cert[0].arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

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

resource "aws_apigatewayv2_api_mapping" "apim_mapping" {
  count       = var.apim_enable_custom_domain ? 1 : 0
  api_id      = aws_apigatewayv2_api.apim_gateway.id
  domain_name = aws_apigatewayv2_domain_name.apim_custom_domain[0].id
  stage       = aws_apigatewayv2_stage.apim_stage.id
}

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
