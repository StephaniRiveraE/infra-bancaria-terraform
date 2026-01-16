# =============================================================================
# EKS ADDONS - Componentes esenciales del cluster
# =============================================================================
# Addons necesarios para que EKS Fargate funcione correctamente
# =============================================================================

# -----------------------------------------------------------------------------
# CoreDNS - Resolución DNS interna del cluster
# -----------------------------------------------------------------------------

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.bancario.name
  addon_name   = "coredns"

  # Configuración especial para Fargate
  configuration_values = jsonencode({
    computeType = "Fargate"
    replicaCount = 2
  })

  # CoreDNS necesita el Fargate Profile de kube-system primero
  depends_on = [aws_eks_fargate_profile.system]

  tags = {
    Name      = "eks-addon-coredns"
    ManagedBy = "terraform"
  }
}

# -----------------------------------------------------------------------------
# VPC CNI - Networking de pods
# -----------------------------------------------------------------------------

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.bancario.name
  addon_name   = "vpc-cni"

  tags = {
    Name      = "eks-addon-vpc-cni"
    ManagedBy = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Kube Proxy - Reglas de red para servicios
# -----------------------------------------------------------------------------

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.bancario.name
  addon_name   = "kube-proxy"

  tags = {
    Name      = "eks-addon-kube-proxy"
    ManagedBy = "terraform"
  }
}
