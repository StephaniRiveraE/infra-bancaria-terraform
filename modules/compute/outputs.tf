# ============================================================================
# OUTPUTS - Módulo Compute (EKS + Fargate)
# ============================================================================

output "cluster_name" {
  description = "Nombre del clúster EKS"
  value       = aws_eks_cluster.bancario.name
}

output "cluster_endpoint" {
  description = "Endpoint del API server de EKS"
  value       = aws_eks_cluster.bancario.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificado CA del clúster para kubeconfig"
  value       = aws_eks_cluster.bancario.certificate_authority[0].data
}

output "cluster_arn" {
  description = "ARN del clúster EKS"
  value       = aws_eks_cluster.bancario.arn
}

output "cluster_version" {
  description = "Versión de Kubernetes del clúster"
  value       = aws_eks_cluster.bancario.version
}

output "cluster_oidc_issuer_url" {
  description = "URL del OIDC issuer"
  value       = aws_eks_cluster.bancario.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN del OIDC provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "fargate_profile_names" {
  description = "Nombres de los Fargate profiles"
  value       = [for fp in aws_eks_fargate_profile.entities : fp.fargate_profile_name]
}

output "fargate_profile_arns" {
  description = "ARNs de los Fargate profiles"
  value       = [for fp in aws_eks_fargate_profile.entities : fp.arn]
}

output "alb_controller_role_arn" {
  description = "ARN del rol IAM para AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller.arn
}

output "cluster_security_group_id" {
  description = "ID del Security Group del clúster EKS"
  value       = aws_security_group.eks_cluster_sg.id
}

output "kubectl_config_command" {
  description = "Comando para configurar kubectl"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.bancario.name} --region us-east-2"
}
