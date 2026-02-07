#!/bin/bash
# ============================================================================
# SCRIPT DE INICIALIZACIÓN DE EKS
# Ejecutar cada vez que se enciende EKS (eks_enabled=true)
# ============================================================================

set -e

echo "🚀 =============================================="
echo "   INICIALIZACIÓN DE EKS - Banca Ecosistema"
echo "==============================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
EKS_CLUSTER="eks-banca-ecosistema"
AWS_REGION="us-east-2"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Función para imprimir pasos
print_step() {
    echo -e "${GREEN}[PASO $1]${NC} $2"
}

print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================================
# PASO 1: Verificar prerequisitos
# ============================================================================
print_step "1/6" "Verificando prerequisitos..."

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI no está instalado"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl no está instalado"
    exit 1
fi

echo "  ✅ AWS CLI instalado"
echo "  ✅ kubectl instalado"

# ============================================================================
# PASO 2: Configurar kubectl
# ============================================================================
print_step "2/6" "Configurando kubectl para conectar a EKS..."

aws eks update-kubeconfig --name $EKS_CLUSTER --region $AWS_REGION

echo "  ✅ kubectl configurado"

# Verificar conexión
if ! kubectl cluster-info &> /dev/null; then
    print_error "No se puede conectar al cluster. ¿El EKS está encendido?"
    echo "  Ejecuta: terraform apply -var=\"eks_enabled=true\""
    exit 1
fi

echo "  ✅ Conexión al cluster verificada"

# ============================================================================
# PASO 3: Parchar CoreDNS (solo si es necesario)
# ============================================================================
print_step "3/6" "Verificando CoreDNS..."

# Intentar parchar, ignorar si ya está parchado
kubectl patch deployment coredns -n kube-system \
    --type json \
    -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]' 2>/dev/null || true

# Reiniciar CoreDNS
kubectl rollout restart deployment coredns -n kube-system 2>/dev/null || true

echo "  ✅ CoreDNS configurado"

# Esperar a que CoreDNS esté listo
echo "  ⏳ Esperando que CoreDNS esté listo..."
kubectl rollout status deployment coredns -n kube-system --timeout=120s 2>/dev/null || print_warning "CoreDNS puede tardar un poco más"

# ============================================================================
# PASO 4: Crear Namespaces
# ============================================================================
print_step "4/6" "Creando namespaces..."

kubectl apply -f "$PROJECT_DIR/k8s-manifests/namespaces/"

echo "  ✅ Namespaces creados:"
kubectl get namespaces | grep -E "arcbank|bantec|nexus|ecusol|switch" | awk '{print "     - "$1}'

# ============================================================================
# PASO 5: Crear Secrets de Base de Datos
# ============================================================================
print_step "5/6" "Creando secrets de BD..."

# Ejecutar script de secrets
if [ -f "$SCRIPT_DIR/crear-secrets-bd.sh" ]; then
    chmod +x "$SCRIPT_DIR/crear-secrets-bd.sh"
    cd "$SCRIPT_DIR" && ./crear-secrets-bd.sh
    cd "$PROJECT_DIR"
else
    print_warning "Script crear-secrets-bd.sh no encontrado. Ejecutar manualmente después."
fi

# ============================================================================
# PASO 6: Resumen
# ============================================================================
print_step "6/6" "Verificación final..."

echo ""
echo "📋 RESUMEN DE RECURSOS CREADOS:"
echo "================================"
echo ""
echo "Namespaces:"
kubectl get namespaces | grep -E "arcbank|bantec|nexus|ecusol|switch"
echo ""
echo "Secrets de BD:"
kubectl get secrets -A 2>/dev/null | grep db-credentials || print_warning "Secrets de BD pendientes"
echo ""

# ============================================================================
# FIN
# ============================================================================
echo ""
echo -e "${GREEN}✅ =============================================="
echo "   EKS INICIALIZADO CORRECTAMENTE"
echo "===============================================${NC}"
echo ""
echo "PRÓXIMOS PASOS:"
echo "1. Crear deployments iniciales para cada microservicio"
echo "2. Los desarrolladores pueden hacer git push a sus repos"
echo ""
echo "Para crear un deployment inicial, usa:"
echo "  export SERVICE_NAME=ms-clientes"
echo "  export NAMESPACE=arcbank"
echo "  export AWS_ACCOUNT_ID=123456789012"
echo "  export AWS_REGION=us-east-2"
echo "  export ECR_REPO_NAME=arcbank-ms-clientes"
echo "  export IMAGE_TAG=latest"
echo "  envsubst < k8s-manifests/templates/deployment-template.yaml | kubectl apply -f -"
echo ""
