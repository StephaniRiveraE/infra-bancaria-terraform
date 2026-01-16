# =============================================================================
# SECURITY GROUPS - EKS Cluster y Pods
# =============================================================================
# Security Groups para el control plane de EKS y comunicación de pods
# =============================================================================

# -----------------------------------------------------------------------------
# Security Group para el Cluster EKS
# -----------------------------------------------------------------------------

resource "aws_security_group" "eks_cluster" {
  name        = "eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = aws_vpc.vpc_bancaria.id

  tags = {
    Name        = "eks-cluster-security-group"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Permite HTTPS desde pods al control plane
resource "aws_security_group_rule" "cluster_inbound_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_pods.id
  description              = "Allow HTTPS from pods to control plane"
}

# Permite salida del cluster a cualquier destino
resource "aws_security_group_rule" "cluster_outbound_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic from cluster"
}

# -----------------------------------------------------------------------------
# Security Group para Pods
# -----------------------------------------------------------------------------

resource "aws_security_group" "eks_pods" {
  name        = "eks-pods-sg"
  description = "Security group for EKS Fargate pods"
  vpc_id      = aws_vpc.vpc_bancaria.id

  tags = {
    Name        = "eks-pods-security-group"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Permite comunicación entre pods (mismo security group)
resource "aws_security_group_rule" "pods_internal" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_pods.id
  self              = true
  description       = "Allow all traffic between pods"
}

# Permite tráfico desde el control plane a los pods
resource "aws_security_group_rule" "pods_from_cluster" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_pods.id
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "Allow traffic from EKS control plane"
}

# Permite salida a internet (para pull de imágenes ECR, etc.)
resource "aws_security_group_rule" "pods_outbound_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_pods.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic from pods"
}

# -----------------------------------------------------------------------------
# Security Group para ALB (Load Balancer)
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "eks-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.vpc_bancaria.id

  tags = {
    Name        = "eks-alb-security-group"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Permite HTTP desde internet
resource "aws_security_group_rule" "alb_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP from internet"
}

# Permite HTTPS desde internet
resource "aws_security_group_rule" "alb_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS from internet"
}

# Permite que el ALB envíe tráfico a los pods
resource "aws_security_group_rule" "alb_to_pods" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.eks_pods.id
  description              = "Allow traffic to pods"
}

# Permite que los pods reciban tráfico del ALB
resource "aws_security_group_rule" "pods_from_alb" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_pods.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow traffic from ALB"
}
