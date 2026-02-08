output "eks_cluster_role_arn" {
  description = "ARN del rol del clúster EKS"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "fargate_execution_role_arn" {
  description = "ARN del rol de ejecución de Fargate"
  value       = aws_iam_role.fargate_execution_role.arn
}

output "cicd_user_arn" {
  description = "ARN del usuario IAM para CI/CD"
  value       = aws_iam_user.cicd_deployer.arn
}
