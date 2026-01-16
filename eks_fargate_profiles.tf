# =============================================================================
# FARGATE PROFILES - Ecosistema Bancario
# =============================================================================
# Cada namespace tiene su propio Fargate Profile
# Esto permite que los pods se ejecuten sin nodos EC2
# =============================================================================

# -----------------------------------------------------------------------------
# Variables de namespaces
# -----------------------------------------------------------------------------

variable "bank_namespaces" {
  description = "Namespaces para cada banco del ecosistema"
  type        = list(string)
  default     = ["arcbank", "bantec", "nexus", "ecusol", "switch"]
}

variable "system_namespaces" {
  description = "Namespaces del sistema Kubernetes"
  type        = list(string)
  default     = ["kube-system", "default"]
}

# -----------------------------------------------------------------------------
# Fargate Profiles para Bancos
# -----------------------------------------------------------------------------

resource "aws_eks_fargate_profile" "banks" {
  for_each = toset(var.bank_namespaces)

  cluster_name           = aws_eks_cluster.bancario.name
  fargate_profile_name   = "fp-${each.value}"
  pod_execution_role_arn = aws_iam_role.fargate_execution_role.arn

  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  selector {
    namespace = each.value
  }

  tags = {
    Name        = "fargate-profile-${each.value}"
    Bank        = each.value
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Fargate Profiles para Sistema (CoreDNS, etc.)
# -----------------------------------------------------------------------------

resource "aws_eks_fargate_profile" "system" {
  for_each = toset(var.system_namespaces)

  cluster_name           = aws_eks_cluster.bancario.name
  fargate_profile_name   = "fp-system-${each.value}"
  pod_execution_role_arn = aws_iam_role.fargate_execution_role.arn

  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  selector {
    namespace = each.value
  }

  tags = {
    Name        = "fargate-profile-system-${each.value}"
    Type        = "system"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
