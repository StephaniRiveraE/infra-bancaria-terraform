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
# PASO 6: Crear Deployments de Microservicios
# ============================================================================
print_step "6/7" "Creando deployments para todos los microservicios..."

# Obtener AWS Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-east-2"
export IMAGE_TAG="latest"

echo "  Account ID: $AWS_ACCOUNT_ID"
echo ""

# Función para crear un deployment
create_deployment() {
    local namespace=$1
    local service_name=$2
    local ecr_repo=$3
    
    export NAMESPACE=$namespace
    export SERVICE_NAME=$service_name
    export ECR_REPO_NAME=$ecr_repo
    
    echo "  📦 Creando: $service_name en namespace $namespace"
    
    envsubst < "$PROJECT_DIR/k8s-manifests/templates/deployment-template.yaml" | kubectl apply -f - > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "     ✅ Deployment creado: $service_name"
    else
        print_warning "Error creando $service_name (puede ser normal si ya existe)"
    fi
}

# Array de microservicios: "namespace:service_name:ecr_repo"
declare -a microservices=(
    # ArcBank (5)
    "arcbank:gateway-server:arcbank-gateway-server"
    "arcbank:service-clientes:arcbank-service-clientes"
    "arcbank:service-cuentas:arcbank-service-cuentas"
    "arcbank:service-transacciones:arcbank-service-transacciones"
    "arcbank:service-sucursales:arcbank-service-sucursales"
    
    # Bantec (5)
    "bantec:gateway-server:bantec-gateway-server"
    "bantec:service-clientes:bantec-service-clientes"
    "bantec:service-cuentas:bantec-service-cuentas"
    "bantec:service-transacciones:bantec-service-transacciones"
    "bantec:service-sucursales:bantec-service-sucursales"
    
    # Nexus (7)
    "nexus:nexus-gateway:nexus-gateway"
    "nexus:nexus-ms-clientes:nexus-ms-clientes"
    "nexus:nexus-cbs:nexus-cbs"
    "nexus:nexus-ms-transacciones:nexus-ms-transacciones"
    "nexus:nexus-ms-geografia:nexus-ms-geografia"
    "nexus:nexus-web-backend:nexus-web-backend"
    "nexus:nexus-ventanilla-backend:nexus-ventanilla-backend"
    
    # EcuSol (7)
    "ecusol:ecusol-gateway-server:ecusol-gateway-server"
    "ecusol:ecusol-ms-clientes:ecusol-ms-clientes"
    "ecusol:ecusol-ms-cuentas:ecusol-ms-cuentas"
    "ecusol:ecusol-ms-transacciones:ecusol-ms-transacciones"
    "ecusol:ecusol-ms-geografia:ecusol-ms-geografia"
    "ecusol:ecusol-web-backend:ecusol-web-backend"
    "ecusol:ecusol-ventanilla-backend:ecusol-ventanilla-backend"
    
    # Switch (6)
    "switch:switch-gateway-internal:switch-gateway-internal"
    "switch:switch-ms-nucleo:switch-ms-nucleo"
    "switch:switch-ms-contabilidad:switch-ms-contabilidad"
    "switch:switch-ms-compensacion:switch-ms-compensacion"
    "switch:switch-ms-devolucion:switch-ms-devolucion"
    "switch:switch-ms-directorio:switch-ms-directorio"
)

# Crear todos los deployments
echo ""
for svc in "${microservices[@]}"; do
    IFS=':' read -r namespace service_name ecr_repo <<< "$svc"
    create_deployment "$namespace" "$service_name" "$ecr_repo"
done

echo ""
echo "  ✅ Total deployments creados: ${#microservices[@]}"

# ============================================================================
# PASO 7: Verificación final
# ============================================================================
print_step "7/7" "Verificación final..."

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
echo "Deployments creados:"
kubectl get deployments -A 2>/dev/null | grep -E "arcbank|bantec|nexus|ecusol|switch" | wc -l | awk '{print "  Total: "$1" deployments"}'
echo ""

# ============================================================================
# FIN
# ============================================================================
echo ""
echo -e "${GREEN}✅ =============================================="
echo "   EKS COMPLETAMENTE INICIALIZADO"
echo "===============================================${NC}"
echo ""
echo "✨ LISTO PARA DESARROLLADORES ✨"
echo ""
echo "Los developers ya pueden hacer 'git push' en sus repos."
echo "Los workflows de GitHub Actions actualizarán automáticamente"
echo "las imágenes Docker en estos deployments."
echo ""
echo "Para ver el estado de los pods:"
echo "  kubectl get pods -A"
echo ""
echo "Nota: Los pods estarán en 'ImagePullBackOff' hasta que se haga"
echo "el primer push con código. Esto es normal."
echo ""
