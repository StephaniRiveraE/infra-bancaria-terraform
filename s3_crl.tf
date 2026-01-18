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

# ACM PCA requiere que el bucket tenga ownership controls específicos
resource "aws_s3_bucket_ownership_controls" "crl_bucket_ownership" {
  bucket = aws_s3_bucket.crl_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Desbloquear acceso público (requerido por ACM PCA para publicar CRL)
resource "aws_s3_bucket_public_access_block" "crl_bucket_block" {
  bucket = aws_s3_bucket.crl_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ACL del bucket 
resource "aws_s3_bucket_acl" "crl_bucket_acl" {
  bucket = aws_s3_bucket.crl_bucket.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.crl_bucket_ownership,
    aws_s3_bucket_public_access_block.crl_bucket_block
  ]
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
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.crl_bucket_block]
}

# Data source para obtener account ID
data "aws_caller_identity" "current" {}
