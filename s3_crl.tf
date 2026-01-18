resource "aws_s3_bucket" "crl_bucket" {
  bucket        = "apim-crl-bucket"
  force_destroy = true

  tags = var.common_tags
}
