output "apim_mtls_truststore_bucket" {
  description = "Bucket S3 donde se almacena el Truststore para mTLS"
  value       = aws_s3_bucket.mtls_truststore.id
}

output "apim_mtls_truststore_uri" {
  description = "URI S3 del archivo truststore.pem (usar en API Gateway)"
  value       = "s3://${aws_s3_bucket.mtls_truststore.id}/${aws_s3_object.truststore_pem.key}"
}

# Output removed (belongs to security-certs module)
