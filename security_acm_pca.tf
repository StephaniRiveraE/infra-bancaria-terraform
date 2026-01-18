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

resource "aws_acmpca_certificate_authority_certificate" "apim_ca_cert" {
  certificate_authority_arn = aws_acmpca_certificate_authority.apim_ca.arn
  certificate               = file("${path.module}/ca_cert.pem")
}

