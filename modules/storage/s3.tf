locals {
  frontends = [
    "switch-admin-panel",
    "bantec-web-client", "bantec-ventanilla-app",
    "arcbank-web-client", "arcbank-ventanilla-app",
    "nexus-web-client", "nexus-ventanilla-app",
    "ecusol-web-client", "ecusol-ventanilla-app"
  ]
}

resource "aws_s3_bucket" "frontends" {
  for_each = toset(local.frontends)
  bucket   = "banca-ecosistema-${each.value}-512be32e" 

  tags = merge(var.common_tags, {
    Domain = split("-", each.value)[0]
    Layer  = "Frontend-Static"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "front_encryption" {
  for_each = aws_s3_bucket.frontends
  bucket   = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_website_configuration" "front_website" {
  for_each = aws_s3_bucket.frontends
  bucket   = each.value.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  for_each = aws_s3_bucket.frontends
  bucket   = each.value.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  for_each = aws_s3_bucket.frontends
  bucket   = each.value.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${each.value.arn}/*"
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.block_public]
}