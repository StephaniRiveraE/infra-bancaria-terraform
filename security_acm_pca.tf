# =============================================================================
# Seguridad - Certificados Self-Signed (SIN COSTO)
# 
# NOTA IMPORTANTE: Este archivo reemplaza a security_acm_pca.tf
# ACM PCA cuesta ~$400/mes, por lo que usamos certificados self-signed
# que son gratuitos y adecuados para un proyecto universitario.
#
# Para producción real, considerar:
# - Let's Encrypt (gratis)
# - ACM PCA (si hay presupuesto)
# =============================================================================

# El certificado CA ya existe como archivo: dummy_cert.pem
# Para mTLS, el truststore en S3 (apim-mtls.tf) ya tiene el certificado

# Secrets Manager para almacenar certificados de bancos (si se requiere)
resource "aws_secretsmanager_secret" "apim_ca_cert" {
  name        = "apim/ca-certificate"
  description = "Certificado CA self-signed para validación mTLS"

  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "apim_ca_cert_version" {
  secret_id     = aws_secretsmanager_secret.apim_ca_cert.id
  secret_string = file("${path.module}/dummy_cert.pem")
}

# Output del ARN del secreto
output "apim_ca_secret_arn" {
  description = "ARN del secreto con el certificado CA (para Lambda JWS Authorizer)"
  value       = aws_secretsmanager_secret.apim_ca_cert.arn
}
