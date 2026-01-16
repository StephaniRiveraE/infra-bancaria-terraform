# =============================================================================
# EKS OUTPUTS - Valores de salida del cluster
# =============================================================================
# Estos valores son necesarios para configurar kubectl y CI/CD
# =============================================================================

output "cluster_name" {
  description = "Nombre del cluster EKS"
  value       = aws_eks_cluster.bancario.name
}

output "cluster_endpoint" {
  description = "Endpoint del API Server de Kubernetes"
  value       = aws_eks_cluster.bancario.endpoint
}

output "cluster_certificate_authority" {
  description = "Certificado CA del cluster (base64)"
  value       = aws_eks_cluster.bancario.certificate_authority[0].data
  sensitive   = true
}

output "cluster_arn" {
  description = "ARN del cluster EKS"
  value       = aws_eks_cluster.bancario.arn
}

output "cluster_version" {
  description = "Versión de Kubernetes"
  value       = aws_eks_cluster.bancario.version
}

# -----------------------------------------------------------------------------
# Comando para configurar kubectl
# -----------------------------------------------------------------------------

output "kubectl_config_command" {
  description = "Comando para configurar kubectl"
  value       = "aws eks update-kubeconfig --region us-east-2 --name ${aws_eks_cluster.bancario.name}"
}
