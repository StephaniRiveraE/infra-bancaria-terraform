# =============================================================================
# SERVICE ACCOUNTS - Para pods de Kubernetes
# =============================================================================
# Service accounts con IAM Roles para acceso a servicios AWS
# =============================================================================

# -----------------------------------------------------------------------------
# OIDC Provider - Para IAM Roles for Service Accounts (IRSA)
# -----------------------------------------------------------------------------

data "tls_certificate" "eks" {
  url = aws_eks_cluster.bancario.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.bancario.identity[0].oidc[0].issuer

  tags = {
    Name      = "eks-oidc-provider"
    ManagedBy = "terraform"
  }
}

# -----------------------------------------------------------------------------
# IAM Role para pods que necesitan acceso a ECR
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ecr_access" {
  name = "eks-ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:*:*"
        }
      }
    }]
  })

  tags = {
    Name      = "eks-ecr-access-role"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ecr_access.name
}

# -----------------------------------------------------------------------------
# IAM Role para pods que necesitan acceso a CloudWatch Logs
# -----------------------------------------------------------------------------

resource "aws_iam_role" "cloudwatch_logs" {
  name = "eks-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:*:*"
        }
      }
    }]
  })

  tags = {
    Name      = "eks-cloudwatch-logs-role"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_write" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.cloudwatch_logs.name
}
