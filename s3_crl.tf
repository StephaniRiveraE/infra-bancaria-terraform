# =============================================================================
# S3 Bucket CRL - SOLO PARA DESTRUCCIÓN
# Este archivo existe temporalmente para permitir que Terraform elimine el bucket
# =============================================================================

resource "aws_s3_bucket" "crl_bucket" {
  bucket        = "apim-crl-bucket"
  force_destroy = true  # Permite eliminar bucket con objetos

  tags = var.common_tags
}
