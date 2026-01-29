output "apim_mtls_truststore_bucket" {
  description = "Bucket S3 donde se almacena el Truststore para mTLS"
  value       = aws_s3_bucket.mtls_truststore.id
}

output "apim_mtls_truststore_uri" {
  description = "URI S3 del archivo truststore.pem (usar en API Gateway)"
  value       = "s3://${aws_s3_bucket.mtls_truststore.id}/${aws_s3_object.truststore_pem.key}"
}

output "switch_signing_public_key_secret_arn" {
  description = "ARN del secreto que contiene la llave publica del Switch (necesario para bancos)"
  value       = aws_secretsmanager_secret.switch_public_key.arn
}
