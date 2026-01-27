# 🧠 Fase 3: Cómputo (EKS + Fargate) - Guía de Implementación

**Proyecto:** Infraestructura Bancaria - 4 Bancos Core + Switch DIGICONECU  
**Módulo:** `compute`  
**Estado:** ✅ **Implementado**  
**Fecha:** 2026-01-27

---

## 🎯 Objetivo de la Fase

Crear el clúster de Kubernetes (Amazon EKS) con perfiles de AWS Fargate para que los 4 bancos (ArcBank, Bantec, Nexus, Ecusol) y el Switch DIGICONECU puedan ejecutar sus microservicios de forma serverless, con despliegue automático desde sus repositorios.

---

## 📦 Recursos Implementados

### Clúster EKS

| Recurso | Nombre en Terraform | Identificador (AWS Console) | Configuración Clave |
|---------|---------------------|------------------------------|---------------------|
| **EKS Cluster** | `aws_eks_cluster.bancario` | `eks-banca-ecosistema` | Version: `1.29`, Logs: API, Audit, Authenticator |
| **Security Group** | `aws_security_group.eks_cluster_sg` | `eks-cluster-sg` | Ingress 443 desde VPC CIDR |
| **CloudWatch Logs** | `aws_cloudwatch_log_group.eks_cluster` | `/aws/eks/eks-banca-ecosistema/cluster` | Retención: 30 días |

### Fargate Profiles (7 perfiles)

| Perfil | Namespace | Propósito |
|--------|-----------|-----------|
| `fargate-arcbank` | `arcbank` | Microservicios de ArcBank |
| `fargate-bantec` | `bantec` | Microservicios de Bantec |
| `fargate-nexus` | `nexus` | Microservicios de Nexus |
| `fargate-ecusol` | `ecusol` | Microservicios de Ecusol |
| `fargate-switch` | `switch` | Microservicios del Switch DIGICONECU |
| `fargate-kube-system` | `kube-system` | CoreDNS (DNS interno del clúster) |
| `fargate-aws-lb-controller` | `kube-system` | AWS Load Balancer Controller |

### EKS Addons (4 complementos)

| Addon | Propósito |
|-------|-----------|
| `vpc-cni` | Plugin de red - cada pod obtiene una IP de la VPC |
| `kube-proxy` | Proxy de red para comunicación entre servicios |
| `coredns` | DNS interno del clúster Kubernetes |
| `eks-pod-identity-agent` | IRSA - IAM Roles for Service Accounts |

### IAM y OIDC

| Recurso | Nombre | Propósito |
|---------|--------|-----------|
| **OIDC Provider** | `eks-oidc-provider` | Permite que pods asuman roles IAM |
| **IAM Role** | `eks-alb-controller-role` | Rol para AWS Load Balancer Controller |
| **IAM Policy** | `AWSLoadBalancerControllerIAMPolicy` | Permisos para gestionar ALBs |

---

## 🔍 Cómo buscar en AWS Console

1. **EKS Cluster:**
   - Ve a **Amazon EKS** → **Clusters**
   - Busca `eks-banca-ecosistema`
   - Estado esperado: `Active`

2. **Fargate Profiles:**
   - Dentro del clúster → Pestaña **Compute**
   - Sección **Fargate profiles**
   - Verás: `fargate-arcbank`, `fargate-bantec`, etc.

3. **Addons:**
   - Dentro del clúster → Pestaña **Add-ons**
   - Verás: `vpc-cni`, `kube-proxy`, `coredns`, `eks-pod-identity-agent`

4. **OIDC Provider:**
   - Ve a **IAM** → **Identity providers**
   - Busca el que termine en `/eks-banca-ecosistema`

5. **IAM Role para ALB:**
   - Ve a **IAM** → **Roles**
   - Busca `eks-alb-controller-role`

---

## 📁 Estructura de Archivos

```
modules/compute/
├── variables.tf          # Variables de entrada del módulo
├── eks.tf                # Clúster EKS + Security Group + CloudWatch Logs
├── fargate-profiles.tf   # 7 Fargate Profiles
├── addons.tf             # 4 EKS Addons
├── alb-controller.tf     # OIDC Provider + IAM Role para ALB Controller
└── outputs.tf            # Outputs del módulo

k8s-manifests/
├── namespaces/
│   ├── arcbank.yaml
│   ├── bantec.yaml
│   ├── nexus.yaml
│   ├── ecusol.yaml
│   └── switch.yaml
├── templates/
│   └── deployment-template.yaml
├── .github-template/
│   └── deploy-to-eks.yml
└── CICD_GUIDE.md
```

---

## 🚀 Paso a Paso para Implementar

### Pre-requisitos

- Fase 1 (Networking, IAM, Storage) completada
- Fase 2 (Databases, Messaging) completada
- AWS CLI configurado
- kubectl instalado
- Helm instalado

### Paso 1: Aplicar Terraform

El CI/CD ejecutará automáticamente:

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

**⏱️ Tiempo estimado:** 35-45 minutos

### Paso 2: Configurar kubectl

```bash
aws eks update-kubeconfig --name eks-banca-ecosistema --region us-east-2
```

**Verificar conexión:**
```bash
kubectl cluster-info
kubectl get nodes  # No habrá nodos (es Fargate)
```

### Paso 3: Parchar CoreDNS para Fargate (CRÍTICO)

Por defecto, CoreDNS intenta ejecutarse en nodos EC2. Debemos quitarle esa anotación:

```bash
kubectl patch deployment coredns -n kube-system \
  --type json \
  -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
```

**Reiniciar CoreDNS:**
```bash
kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system
```

**Verificar que esté corriendo:**
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
# Esperado: 2/2 Running
```

### Paso 4: Crear Namespaces

```bash
kubectl apply -f k8s-manifests/namespaces/
```

**Verificar:**
```bash
kubectl get namespaces
# Esperado: arcbank, bantec, nexus, ecusol, switch
```

### Paso 5: Instalar AWS Load Balancer Controller

**Agregar repo Helm:**
```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

**Obtener valores necesarios:**
```bash
# Obtener VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=vpc-ecosistema-bancario" --query 'Vpcs[0].VpcId' --output text)

# Obtener Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "VPC_ID: $VPC_ID"
echo "ACCOUNT_ID: $ACCOUNT_ID"
```

**Instalar el controller:**
```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks-banca-ecosistema \
  --set serviceAccount.create=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::${ACCOUNT_ID}:role/eks-alb-controller-role \
  --set region=us-east-2 \
  --set vpcId=${VPC_ID}
```

**Verificar instalación:**
```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
# Esperado: 2/2 Running
```

### Paso 6: Verificación Final

```bash
# Ver Fargate Profiles
aws eks list-fargate-profiles --cluster-name eks-banca-ecosistema

# Ver todos los pods del sistema
kubectl get pods -n kube-system

# Ver namespaces creados
kubectl get ns | grep -E "arcbank|bantec|nexus|ecusol|switch"
```

---

## 📢 Configuración de CI/CD para Bancos

### Lo que cada equipo de banco debe hacer:

#### 1. Agregar Secrets en GitHub

En el repositorio del banco: **Settings** → **Secrets and variables** → **Actions**

| Secret | Valor |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Access Key del usuario IAM |
| `AWS_SECRET_ACCESS_KEY` | Secret Key del usuario IAM |
| `AWS_ACCOUNT_ID` | ID de cuenta AWS (12 dígitos) |

#### 2. Copiar Workflow de CI/CD

Copiar el archivo:
```
k8s-manifests/.github-template/deploy-to-eks.yml
```

A su repositorio como:
```
.github/workflows/deploy.yml
```

#### 3. Modificar Variables

Editar las variables `env` según el banco y microservicio:

```yaml
env:
  AWS_REGION: us-east-2
  EKS_CLUSTER: eks-banca-ecosistema
  NAMESPACE: arcbank                        # Cambiar según banco
  ECR_REPO: arcbank-service-clientes        # Cambiar según microservicio
  SERVICE_NAME: service-clientes            # Cambiar según microservicio
```

#### 4. Crear Deployment Inicial (Primera vez)

La primera vez que se despliega un microservicio, crear el Deployment en K8s:

```bash
# Configurar variables
export SERVICE_NAME=service-clientes
export NAMESPACE=arcbank
export AWS_ACCOUNT_ID=123456789012
export AWS_REGION=us-east-2
export ECR_REPO_NAME=arcbank-service-clientes
export IMAGE_TAG=latest

# Aplicar template
envsubst < k8s-manifests/templates/deployment-template.yaml | kubectl apply -f -
```

#### 5. Push a main = Deploy Automático

Después de la configuración inicial, cada push a `main`:
1. ✅ Construye imagen Docker
2. ✅ Sube a ECR
3. ✅ Actualiza deployment en EKS

---

## 📊 Mapeo de Microservicios por Entidad

### ArcBank (`namespace: arcbank`)

| Microservicio | ECR_REPO | SERVICE_NAME |
|---------------|----------|--------------|
| Gateway | `arcbank-gateway-server` | `gateway-server` |
| Clientes | `arcbank-service-clientes` | `service-clientes` |
| Cuentas | `arcbank-service-cuentas` | `service-cuentas` |
| Transacciones | `arcbank-service-transacciones` | `service-transacciones` |
| Sucursales | `arcbank-service-sucursales` | `service-sucursales` |

### Bantec (`namespace: bantec`)

| Microservicio | ECR_REPO | SERVICE_NAME |
|---------------|----------|--------------|
| Gateway | `bantec-gateway-server` | `gateway-server` |
| Clientes | `bantec-service-clientes` | `service-clientes` |
| Cuentas | `bantec-service-cuentas` | `service-cuentas` |
| Transacciones | `bantec-service-transacciones` | `service-transacciones` |
| Sucursales | `bantec-service-sucursales` | `service-sucursales` |

### Nexus (`namespace: nexus`)

| Microservicio | ECR_REPO | SERVICE_NAME |
|---------------|----------|--------------|
| Gateway | `nexus-gateway` | `gateway` |
| Clientes | `nexus-ms-clientes` | `ms-clientes` |
| CBS | `nexus-cbs` | `cbs` |
| Transacciones | `nexus-ms-transacciones` | `ms-transacciones` |
| Geografía | `nexus-ms-geografia` | `ms-geografia` |
| Web Backend | `nexus-web-backend` | `web-backend` |
| Ventanilla | `nexus-ventanilla-backend` | `ventanilla-backend` |

### Ecusol (`namespace: ecusol`)

| Microservicio | ECR_REPO | SERVICE_NAME |
|---------------|----------|--------------|
| Gateway | `ecusol-gateway-server` | `gateway-server` |
| Clientes | `ecusol-ms-clientes` | `ms-clientes` |
| Cuentas | `ecusol-ms-cuentas` | `ms-cuentas` |
| Transacciones | `ecusol-ms-transacciones` | `ms-transacciones` |
| Geografía | `ecusol-ms-geografia` | `ms-geografia` |
| Web Backend | `ecusol-web-backend` | `web-backend` |
| Ventanilla | `ecusol-ventanilla-backend` | `ventanilla-backend` |

### Switch DIGICONECU (`namespace: switch`)

| Microservicio | ECR_REPO | SERVICE_NAME |
|---------------|----------|--------------|
| Gateway | `switch-gateway-internal` | `gateway-internal` |
| Núcleo | `switch-ms-nucleo` | `ms-nucleo` |
| Contabilidad | `switch-ms-contabilidad` | `ms-contabilidad` |
| Compensación | `switch-ms-compensacion` | `ms-compensacion` |
| Devolución | `switch-ms-devolucion` | `ms-devolucion` |
| Directorio | `switch-ms-directorio` | `ms-directorio` |

---

## ⏱️ Tiempos Estimados

| Actividad | Tiempo |
|-----------|--------|
| Terraform Apply (EKS + Fargate) | 35-45 min |
| Parchar CoreDNS | 1 min |
| Instalar ALB Controller | 3-5 min |
| Primer deploy de microservicio | 2-3 min |

---

## 🔧 Troubleshooting

### CoreDNS no arranca

```bash
# Ver logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Verificar que el Fargate Profile existe
aws eks describe-fargate-profile \
  --cluster-name eks-banca-ecosistema \
  --fargate-profile-name fargate-kube-system
```

### Pod en estado Pending

```bash
# Verificar que el namespace tiene Fargate Profile
kubectl describe pod <pod-name> -n <namespace>

# Buscar en eventos
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### ALB Controller no crea Load Balancer

```bash
# Ver logs del controller
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Verificar permisos del rol IAM
aws iam list-attached-role-policies --role-name eks-alb-controller-role
```

---

## 📝 Checklist de Implementación

- [x] Crear módulo `compute`
- [x] EKS Cluster `eks-banca-ecosistema`
- [x] 7 Fargate Profiles (5 entidades + kube-system + alb-controller)
- [x] 4 EKS Addons (vpc-cni, kube-proxy, coredns, pod-identity)
- [x] OIDC Provider para IRSA
- [x] IAM Role para ALB Controller
- [x] Manifiestos de namespaces
- [x] Template de Deployment
- [x] Workflow de CI/CD template
- [x] Documentación para bancos

---

**Última actualización:** 2026-01-27  
**Versión:** 1.0  
**Rama:** `feature/Kubernetes`
