resource "tls_private_key" "internal_ca_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "internal_ca_cert" {
  private_key_pem = tls_private_key.internal_ca_key.private_key_pem

  subject {
    common_name  = "Switch-Transaccional-Root-CA"
    organization = "Banco EcuSol - Switch"
    country      = "EC"
  }

  validity_period_hours = 87600
  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
  is_ca_certificate = true
}

resource "aws_s3_bucket" "mtls_truststore" {
  bucket = "mtls-truststore-${lower(var.project_name)}-${var.environment}"
  tags = merge(var.common_tags, {
    Name      = "mtls-truststore"
    Component = "APIM-Security"
  })
}

resource "aws_s3_object" "truststore_pem" {
  bucket  = aws_s3_bucket.mtls_truststore.id
  key     = "truststore.pem"
  content = tls_self_signed_cert.internal_ca_cert.cert_pem
  
  tags = merge(var.common_tags, {
    Name        = "truststore-file"
    Description = "Contains Root CA for Client Cert Validation"
  })
}

resource "aws_apigatewayv2_domain_name" "apim_custom_domain" {
  count       = var.apim_enable_custom_domain ? 1 : 0
  domain_name = var.apim_domain_name

  domain_name_configuration {
    certificate_arn = var.apim_acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  mutual_tls_authentication {
    truststore_uri     = "s3://${aws_s3_bucket.mtls_truststore.id}/${aws_s3_object.truststore_pem.key}"
    truststore_version = aws_s3_object.truststore_pem.version_id
  }

  tags = merge(var.common_tags, {
    Name = "domain-apim-mtls"
  })
}
