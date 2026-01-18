# =============================================================================
# S3 Bucket para CRL (Certificate Revocation List)
# Este bucket es requerido por ACM PCA para publicar la lista de revocación
# =============================================================================

resource "aws_s3_bucket" "crl_bucket" {
  bucket = lower(var.crl_s3_bucket)

  tags = merge(var.common_tags, {
    Name      = "crl-bucket"
    Component = "APIM-Security"
  })
}

resource "aws_s3_bucket_versioning" "crl_bucket_versioning" {
  bucket = aws_s3_bucket.crl_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "crl_bucket_block" {
  bucket = aws_s3_bucket.crl_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Política para permitir que ACM PCA publique la CRL
resource "aws_s3_bucket_policy" "crl_bucket_policy" {
  bucket = aws_s3_bucket.crl_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowACMPCAAccess"
        Effect    = "Allow"
        Principal = {
          Service = "acm-pca.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.crl_bucket.arn,
          "${aws_s3_bucket.crl_bucket.arn}/*"
        ]
      }
    ]
  })
}
