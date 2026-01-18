# =============================================================================
# ACM Private CA para mTLS
# Este recurso crea una CA privada para firmar certificados de clientes
# NOTA: ACM PCA tiene costo ($400/mes por CA activa)
# =============================================================================

resource "aws_acmpca_certificate_authority" "apim_ca" {
  type = "ROOT"

  certificate_authority_configuration {
    key_algorithm     = "RSA_2048"
    signing_algorithm = "SHA256WITHRSA"
    subject {
      common_name  = "apim-switch-ca"
      organization = "Banco EcuSol"
      country      = "EC"
    }
  }

  revocation_configuration {
    crl_configuration {
      enabled            = true
      expiration_in_days = 365
      s3_bucket_name     = aws_s3_bucket.crl_bucket.id
    }
  }

  depends_on = [aws_s3_bucket_policy.crl_bucket_policy]

  tags = var.common_tags
}

# Certificado raíz auto-firmado para la CA
resource "aws_acmpca_certificate" "apim_ca_root_cert" {
  certificate_authority_arn   = aws_acmpca_certificate_authority.apim_ca.arn
  certificate_signing_request = aws_acmpca_certificate_authority.apim_ca.certificate_signing_request
  signing_algorithm           = "SHA256WITHRSA"

  template_arn = "arn:aws:acm-pca:::template/RootCACertificate/V1"

  validity {
    type  = "YEARS"
    value = 10
  }
}

# Asociar el certificado raíz con la CA
resource "aws_acmpca_certificate_authority_certificate" "apim_ca_cert" {
  certificate_authority_arn = aws_acmpca_certificate_authority.apim_ca.arn
  certificate               = aws_acmpca_certificate.apim_ca_root_cert.certificate
  certificate_chain         = aws_acmpca_certificate.apim_ca_root_cert.certificate_chain
}

# Output del ARN de la CA
output "apim_ca_arn" {
  description = "ARN de la CA privada para firmar certificados de clientes"
  value       = aws_acmpca_certificate_authority.apim_ca.arn
}
