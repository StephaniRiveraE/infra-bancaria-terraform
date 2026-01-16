# =============================================================================
# KUBERNETES NAMESPACES - Documentación
# =============================================================================
# Este archivo documenta los namespaces que deben crearse en el cluster
# Los namespaces se crean automáticamente cuando Fargate detecta pods
# =============================================================================

# -----------------------------------------------------------------------------
# NOTA IMPORTANTE
# -----------------------------------------------------------------------------
# Los Fargate Profiles ya están configurados en eks/fargate_profiles.tf
# para los siguientes namespaces:
#
# BANCOS:
#   - arcbank    : ARCBANK - 5 microservicios + 2 frontends
#   - bantec     : BANTEC  - 5 microservicios + 2 frontends  
#   - nexus      : NEXUS   - 5 microservicios + 2 frontends
#   - ecusol     : ECUSOL  - 5 microservicios + 2 frontends
#   - switch     : DigiConecu Switch - 5 microservicios + 1 frontend
#
# SISTEMA:
#   - kube-system : Componentes del sistema (CoreDNS, etc.)
#   - default     : Namespace por defecto

# -----------------------------------------------------------------------------
# Comandos para crear namespaces manualmente (después de terraform apply)
# -----------------------------------------------------------------------------

# Después de aplicar Terraform, ejecuta estos comandos:
#
# aws eks update-kubeconfig --region us-east-2 --name ecosistema-bancario
#
# kubectl create namespace arcbank
# kubectl create namespace bantec
# kubectl create namespace nexus
# kubectl create namespace ecusol
# kubectl create namespace switch

# -----------------------------------------------------------------------------
# Labels recomendados para cada namespace
# -----------------------------------------------------------------------------

# kubectl label namespace arcbank bank=arcbank environment=production
# kubectl label namespace bantec bank=bantec environment=production
# kubectl label namespace nexus bank=nexus environment=production
# kubectl label namespace ecusol bank=ecusol environment=production
# kubectl label namespace switch bank=switch environment=production
