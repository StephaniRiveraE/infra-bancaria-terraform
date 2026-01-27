# ============================================================================
# EKS ADDONS - Componentes esenciales del clúster
# ============================================================================

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.bancario.name
  addon_name   = "vpc-cni"
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.common_tags, {
    Addon = "vpc-cni"
  })
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.bancario.name
  addon_name   = "kube-proxy"
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.common_tags, {
    Addon = "kube-proxy"
  })
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.bancario.name
  addon_name   = "coredns"
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.common_tags, {
    Addon = "coredns"
  })

  depends_on = [
    aws_eks_fargate_profile.kube_system
  ]
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.bancario.name
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
