# ============================================================================
# FARGATE PROFILES - Perfiles serverless para cada namespace
# CONDICIONAL: Solo se crean si eks_enabled = true
# ============================================================================

locals {
  entity_namespaces = ["arcbank", "bantec", "nexus", "ecusol", "switch"]
}

resource "aws_eks_fargate_profile" "entities" {
  for_each = var.eks_enabled ? toset(local.entity_namespaces) : toset([])

  cluster_name           = aws_eks_cluster.bancario[0].name
  fargate_profile_name   = "fargate-${each.key}"
  pod_execution_role_arn = var.fargate_execution_role_arn

  subnet_ids = var.private_subnet_ids

  selector {
    namespace = each.key
  }

  tags = merge(var.common_tags, {
    Name      = "fargate-${each.key}"
    Namespace = each.key
    Entity    = each.key
  })

  depends_on = [aws_eks_cluster.bancario]
}

resource "aws_eks_fargate_profile" "kube_system" {
  count                  = var.eks_enabled ? 1 : 0
  cluster_name           = aws_eks_cluster.bancario[0].name
  fargate_profile_name   = "fargate-kube-system"
  pod_execution_role_arn = var.fargate_execution_role_arn

  subnet_ids = var.private_subnet_ids

  selector {
    namespace = "kube-system"
    labels = {
      "k8s-app" = "kube-dns"
    }
  }

  tags = merge(var.common_tags, {
    Name      = "fargate-kube-system"
    Component = "CoreDNS"
  })

  depends_on = [aws_eks_cluster.bancario]
}

resource "aws_eks_fargate_profile" "aws_lb_controller" {
  count                  = var.eks_enabled ? 1 : 0
  cluster_name           = aws_eks_cluster.bancario[0].name
  fargate_profile_name   = "fargate-aws-lb-controller"
  pod_execution_role_arn = var.fargate_execution_role_arn

  subnet_ids = var.private_subnet_ids

  selector {
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "aws-load-balancer-controller"
    }
  }

  tags = merge(var.common_tags, {
    Name      = "fargate-aws-lb-controller"
    Component = "ALBController"
  })

  depends_on = [aws_eks_cluster.bancario]
}
