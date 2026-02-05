# ============================================================================
# CONTAINER INSIGHTS - Métricas avanzadas de EKS para CloudWatch
# Solo se activa si EKS está habilitado
# Costo: ~$3-5/mes (incluido en CloudWatch)
# ============================================================================

# Addon de CloudWatch Observability para EKS
# Proporciona: métricas de pods, logs, y Container Insights
resource "aws_eks_addon" "cloudwatch_observability" {
  count = var.eks_enabled ? 1 : 0

  cluster_name                = var.eks_cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  addon_version               = "v1.5.0-eksbuild.1"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.common_tags, {
    Name      = "cloudwatch-observability-addon"
    Component = "Observability"
    Phase     = "5-Observability"
  })
}
