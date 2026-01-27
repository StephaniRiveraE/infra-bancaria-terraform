# ============================================================================
# EKS CLUSTER - Clúster de Kubernetes para Ecosistema Bancario
# Fase 3: Cómputo Serverless
# ============================================================================

resource "aws_eks_cluster" "bancario" {
  name     = "eks-banca-ecosistema"
  role_arn = var.eks_cluster_role_arn
  version  = var.eks_version

  vpc_config {
    subnet_ids = concat(var.private_subnet_ids, var.public_subnet_ids)
    
    endpoint_private_access = true
    endpoint_public_access  = true
    
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = merge(var.common_tags, {
    Name  = "eks-banca-ecosistema"
    Phase = "3-Compute"
  })

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster
  ]
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/eks-banca-ecosistema/cluster"
  retention_in_days = 30
  
  tags = merge(var.common_tags, {
    Name = "eks-cluster-logs"
  })
}

resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "Security group for EKS cluster control plane communication"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "eks-cluster-sg"
  })
}

resource "aws_security_group_rule" "cluster_ingress_pods" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.eks_cluster_sg.id
  description       = "Allow pods to communicate with cluster API"
}
