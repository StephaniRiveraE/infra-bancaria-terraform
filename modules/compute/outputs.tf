output "eks_enabled" {
  description = "Indica si el stack de EKS está habilitado"
  value       = var.eks_enabled
}

output "cluster_name" {
  description = "Nombre del clúster EKS"
  value       = var.eks_enabled ? aws_eks_cluster.bancario[0].name : null
}

output "cluster_endpoint" {
  description = "Endpoint del API server de EKS"
  value       = var.eks_enabled ? aws_eks_cluster.bancario[0].endpoint : null
}

output "cluster_certificate_authority_data" {
  description = "Certificado CA del clúster para kubeconfig"
  value       = var.eks_enabled ? aws_eks_cluster.bancario[0].certificate_authority[0].data : null
}

output "cluster_arn" {
  description = "ARN del clúster EKS"
  value       = var.eks_enabled ? aws_eks_cluster.bancario[0].arn : null
}

output "cluster_version" {
  description = "Versión de Kubernetes del clúster"
  value       = var.eks_enabled ? aws_eks_cluster.bancario[0].version : null
}

output "cluster_oidc_issuer_url" {
  description = "URL del OIDC issuer"
  value       = var.eks_enabled ? aws_eks_cluster.bancario[0].identity[0].oidc[0].issuer : null
}

output "oidc_provider_arn" {
  description = "ARN del OIDC provider"
  value       = var.eks_enabled ? aws_iam_openid_connect_provider.eks[0].arn : null
}

output "fargate_profile_names" {
  description = "Nombres de los Fargate profiles"
  value       = var.eks_enabled ? [for fp in aws_eks_fargate_profile.entities : fp.fargate_profile_name] : []
}

output "fargate_profile_arns" {
  description = "ARNs de los Fargate profiles"
  value       = var.eks_enabled ? [for fp in aws_eks_fargate_profile.entities : fp.arn] : []
}

output "alb_controller_role_arn" {
  description = "ARN del rol IAM para AWS Load Balancer Controller"
  value       = var.eks_enabled ? aws_iam_role.alb_controller[0].arn : null
}

output "cluster_security_group_id" {
  description = "ID del Security Group del clúster EKS"
  value       = var.eks_enabled ? aws_security_group.eks_cluster_sg[0].id : null
}

output "kubectl_config_command" {
  description = "Comando para configurar kubectl"
  value       = var.eks_enabled ? "aws eks update-kubeconfig --name ${aws_eks_cluster.bancario[0].name} --region us-east-2" : "EKS no está habilitado - establece eks_enabled = true para crear el cluster"
}
