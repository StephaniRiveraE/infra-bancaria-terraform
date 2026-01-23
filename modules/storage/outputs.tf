output "ecr_repository_urls" {
  description = "URLs de los repositorios ECR"
  value       = { for k, v in aws_ecr_repository.repos : k => v.repository_url }
}

output "s3_bucket_names" {
  description = "Nombres de los buckets S3"
  value       = { for k, v in aws_s3_bucket.frontends : k => v.bucket }
}
