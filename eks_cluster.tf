# =============================================================================
# EKS CLUSTER - Ecosistema Bancario
# =============================================================================
# Cluster principal de Kubernetes usando AWS EKS con Fargate
# Sin nodos EC2 - 100% serverless
# =============================================================================

resource "aws_eks_cluster" "bancario" {
  name     = "ecosistema-bancario"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = [
      aws_subnet.private_az1.id,
      aws_subnet.private_az2.id,
      aws_subnet.public_az1.id,
      aws_subnet.public_az2.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true # Para kubectl desde local
    
    security_group_ids = [aws_security_group.eks_cluster.id]
  }

  # Logging del cluster
  enabled_cluster_log_types = ["api", "authenticator"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name        = "eks-ecosistema-bancario"
    Environment = "production"
    Project     = "ecosistema-bancario"
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# DATA SOURCES - Para configurar kubectl
# =============================================================================

data "aws_eks_cluster_auth" "bancario" {
  name = aws_eks_cluster.bancario.name
}
