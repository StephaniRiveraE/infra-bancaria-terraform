# ============================================================================
# EKS ADDONS - Componentes esenciales del clúster
# CONDICIONAL: Solo se crean si eks_enabled = true
# ============================================================================

resource "aws_eks_addon" "vpc_cni" {
  count        = var.eks_enabled ? 1 : 0
  cluster_name = aws_eks_cluster.bancario[0].name
  addon_name   = "vpc-cni"
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.common_tags, {
    Addon = "vpc-cni"
  })
}

resource "aws_eks_addon" "kube_proxy" {
  count        = var.eks_enabled ? 1 : 0
  cluster_name = aws_eks_cluster.bancario[0].name
  addon_name   = "kube-proxy"
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.common_tags, {
    Addon = "kube-proxy"
  })
}

resource "aws_eks_addon" "coredns" {
  count        = var.eks_enabled ? 1 : 0
  cluster_name = aws_eks_cluster.bancario[0].name
  addon_name   = "coredns"
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Configuración crítica para clusters Fargate-only
  # Esto elimina la anotación eks.amazonaws.com/compute-type: ec2
  # permitiendo que CoreDNS se programe en nodos Fargate
  configuration_values = jsonencode({
    computeType = "Fargate"
    resources = {
      limits = {
        cpu    = "0.25"
        memory = "256M"
      }
      requests = {
        cpu    = "0.25"
        memory = "256M"
      }
    }
  })

  tags = merge(var.common_tags, {
    Addon = "coredns"
  })

  depends_on = [
    aws_eks_fargate_profile.kube_system
  ]
}

resource "aws_eks_addon" "pod_identity" {
  count        = var.eks_enabled ? 1 : 0
  cluster_name = aws_eks_cluster.bancario[0].name
  addon_name   = "eks-pod-identity-agent"
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.common_tags, {
    Addon = "pod-identity-agent"
  })

  depends_on = [
    aws_eks_fargate_profile.kube_system
  ]
}
