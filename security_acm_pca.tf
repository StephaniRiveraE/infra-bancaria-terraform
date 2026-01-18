resource "aws_acmpca_certificate_authority" "apim_ca" {
  type = "ROOT"
  key_algorithm = "RSA_2048"
  signing_algorithm = "SHA256WITHRSA"
  subject = {
    common_name = "apim-switch-ca"
    organization = "Banco EcuSol"
    country = "EC"
  }
  revocation_configuration {
    crl_configuration {
      enabled = true
      expiration_in_days = 365
      s3_bucket_name = var.crl_s3_bucket
    }
  }
  tags = var.common_tags
}

resource "aws_acmpca_certificate_authority_certificate" "apim_ca_cert" {
  certificate_authority_arn = aws_acmpca_certificate_authority.apim_ca.arn
  certificate_signing_request = aws_acmpca_certificate_authority.apim_ca.certificate_signing_request
  signing_algorithm = "SHA256WITHRSA"
  validity {
    type  = "YEARS"
    value = 10
  }
}
