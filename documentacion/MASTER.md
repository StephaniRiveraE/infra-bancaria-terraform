# 🏦 DOCUMENTACIÓN MAESTRA - Infraestructura Bancaria AWS

**Proyecto:** Switch Transaccional DIGICONECU + 4 Bancos Core  
**Última Actualización:** 2026-02-05  
**Autor:** Stephani Rivera (DevOps Lead)

---

## 📋 Índice

1. [Visión General del Proyecto](#-visión-general-del-proyecto)
2. [Las 5 Fases del Proyecto](#-las-5-fases-del-proyecto)
3. [Arquitectura del Sistema](#-arquitectura-del-sistema)
4. [Flujo de Transferencias Interbancarias](#-flujo-de-transferencias-interbancarias)
5. [Control de Costos](#-control-de-costos)
6. [Guía de Despliegue](#-guía-de-despliegue)
7. [Microservicios por Entidad](#-microservicios-por-entidad)
8. [Seguridad y Autenticación](#-seguridad-y-autenticación)
9. [Observabilidad y Monitoreo](#-observabilidad-y-monitoreo)
10. [Comandos Útiles](#-comandos-útiles)

---

# 🎯 Visión General del Proyecto

## ¿Qué es este proyecto?

Un ecosistema bancario completo en AWS que permite:
- **4 Bancos** (ArcBank, Bantec, Nexus, Ecusol) que operan independientemente
- **1 Switch Central** (DIGICONECU) que procesa transferencias entre bancos
- **Comunicación segura** via OAuth 2.0 y firmas JWS

## Diagrama Conceptual

```
                    ┌─────────────────────────────────────────┐
                    │             INTERNET                     │
                    │   Usuarios de los 4 bancos acceden      │
                    └───────────────────┬─────────────────────┘
                                        │
                                        ▼
                    ┌─────────────────────────────────────────┐
                    │          API GATEWAY + COGNITO          │
                    │     Autenticación y punto de entrada    │
                    └───────────────────┬─────────────────────┘
                                        │
        ┌───────────────────────────────┼───────────────────────────────┐
        │                               │                               │
        ▼                               ▼                               ▼
┌───────────────┐               ┌───────────────┐               ┌───────────────┐
│   ARCBANK     │               │    SWITCH     │               │    NEXUS      │
│   (Banco 1)   │◄─────────────►│  DIGICONECU   │◄─────────────►│   (Banco 3)   │
└───────────────┘               │   (Central)   │               └───────────────┘
                                └───────┬───────┘
        ┌───────────────────────────────┼───────────────────────────────┐
        │                               │                               │
        ▼                               ▼                               ▼
┌───────────────┐               ┌───────────────┐               ┌───────────────┐
│    BANTEC     │               │   RABBITMQ    │               │    ECUSOL     │
│   (Banco 2)   │               │   (Mensajes)  │               │   (Banco 4)   │
└───────────────┘               └───────────────┘               └───────────────┘
```

---

# 📊 Las 5 Fases del Proyecto

## Resumen de Estado

| Fase | Nombre | Estado | Componentes |
|------|--------|--------|-------------|
| **1** | Red, IAM, Almacenamiento | ✅ 100% | VPC, Subnets, ECR, S3, IAM Roles |
| **2** | Datos y Mensajería | ✅ 100% | RDS PostgreSQL, DynamoDB, RabbitMQ, ElastiCache |
| **3** | Cómputo (EKS + Fargate) | ✅ 100% | EKS Cluster, Fargate Profiles, Addons |
| **4** | Seguridad y API Gateway | ✅ 100% | API Gateway, Cognito |
| **5** | Observabilidad | ✅ 100% | CloudWatch Dashboards, Alarmas, SNS |

---

## Fase 1: El Cimiento (Red, IAM, Almacenamiento)

### ¿Qué tiene?

| Recurso | Cantidad | Propósito |
|---------|----------|-----------|
| **VPC** | 1 | Red privada `10.0.0.0/16` |
| **Subnets Públicas** | 2 | NAT Gateway, Load Balancers |
| **Subnets Privadas** | 2 | RDS, EKS Pods (Multi-AZ) |
| **Internet Gateway** | 1 | Entrada desde Internet |
| **NAT Gateway** | 1 (condicional) | Salida a Internet desde subnets privadas |
| **ECR Repos** | 29 | Imágenes Docker de microservicios |
| **S3 Buckets** | 9 | Frontends web + archivos |
| **IAM Roles** | 4 | EKS, Fargate, ALB Controller |

### Archivos Terraform

```
modules/
├── networking/
│   ├── vpc.tf          # VPC, Subnets, Gateways
│   ├── routes.tf       # Tablas de rutas
│   └── security.tf     # Security Groups
├── storage/
│   ├── ecr.tf          # Repositorios Docker
│   └── s3.tf           # Buckets para frontends
└── iam/
    └── iam.tf          # Roles y políticas
```

---

## Fase 2: Datos y Mensajería

### ¿Qué tiene?

| Recurso | Cantidad | Configuración |
|---------|----------|---------------|
| **RDS PostgreSQL** | 5 instancias | `db.t3.micro`, 20GB (1 por entidad) |
| **DynamoDB** | 5 tablas | PAY_PER_REQUEST (directorio + sucursales) |
| **Amazon MQ** | 1 broker | RabbitMQ 3.13, `mq.t3.micro` |
| **Secrets Manager** | ~15 | Credenciales de DB y RabbitMQ |
| **ElastiCache Redis** | 1 cluster | (Condicional) Cache para el Switch |

### Bases de Datos por Entidad

| Entidad | RDS Instance | DynamoDB Table |
|---------|-------------|----------------|
| **Switch** | `rds-switch` | `switch-directorio` |
| **ArcBank** | `rds-arcbank` | `arcbank-sucursales` |
| **Bantec** | `rds-bantec` | `bantec-sucursales` |
| **Nexus** | `rds-nexus` | `nexus-sucursales` |
| **Ecusol** | `rds-ecusol` | `ecusol-sucursales` |

### Archivos Terraform

```
modules/databases/
├── rds.tf              # Instancias PostgreSQL
├── dynamodb.tf         # Tablas NoSQL
└── elasticache.tf      # Redis (condicional)

modules/messaging/
└── amazonmq.tf         # RabbitMQ
```

---

## Fase 3: Cómputo (EKS + Fargate)

### ¿Qué tiene?

| Recurso | Configuración |
|---------|---------------|
| **EKS Cluster** | `eks-banca-ecosistema` v1.29 |
| **Fargate Profiles** | 7 (5 bancos + kube-system + alb) |
| **EKS Addons** | vpc-cni, kube-proxy, coredns, pod-identity |
| **OIDC Provider** | Para IRSA (IAM Roles for Service Accounts) |

### Namespaces en EKS

| Namespace | Uso |
|-----------|-----|
| `switch` | Microservicios del Switch DIGICONECU |
| `arcbank` | Microservicios de ArcBank |
| `bantec` | Microservicios de Bantec |
| `nexus` | Microservicios de Nexus |
| `ecusol` | Microservicios de Ecusol |
| `kube-system` | CoreDNS, VPC-CNI |

### ⚠️ IMPORTANTE: EKS es Condicional

```hcl
eks_enabled = false  # Por defecto APAGADO (ahorro ~$100/mes)
```

Para encender: `terraform apply -var="eks_enabled=true"`

### Archivos Terraform

```
modules/compute/
├── eks.tf              # Cluster EKS
├── fargate-profiles.tf # Perfiles Fargate por namespace
└── addons.tf           # VPC-CNI, CoreDNS, etc.
```

---

## Fase 4: Seguridad y API Gateway

### ¿Qué tiene?

| Recurso | Configuración |
|---------|---------------|
| **API Gateway HTTP** | `apim-switch-gateway` con HTTPS automático |
| **VPC Link** | Conecta API GW con backend privado |
| **Cognito User Pool** | `banca-ecosistema-pool` |
| **Cognito Clients** | 4 (1 por banco) |
| **Internal Secret** | Header `x-origin-secret` |
| **Circuit Breaker** | Lambda + DynamoDB para protección |

### Flujo de Autenticación

```
1. Banco obtiene token → Cognito (OAuth 2.0)
2. Banco envía request → API Gateway + Token JWT
3. API Gateway valida → Cognito
4. Si válido → Pasa al Switch via VPC Link
```

### Archivos Terraform

```
modules/api-gateway/
├── apim.tf                 # API Gateway HTTP
├── apim_routes.tf          # Rutas y autorizadores

└── apim_circuit_breaker.tf # Protección

modules/security-certs/
├── cognito_auth.tf         # User Pool y Clients
└── signing_secrets.tf      # Llaves de firma
```

---

## Fase 5: Observabilidad

### ¿Qué tiene?

| Recurso | Cantidad |
|---------|----------|
| **SNS Topics** | 2 (alarms + critical) |
| **CloudWatch Alarmas** | 4 |
| **CloudWatch Dashboards** | 3 |

### Alarmas Configuradas

| Alarma | Condición | Acción |
|--------|-----------|--------|
| `RDS-Switch-High-CPU` | CPU > 50% por 10 min | Email via SNS |
| `APIGateway-5xx-Errors` | 2+ errores en 15 min | Email via SNS |
| `APIGateway-High-Latency` | p95 > 2 seg | Email via SNS |
| `RabbitMQ-Messages-Queued` | 5+ mensajes en cola | Email via SNS |

### Dashboards

| Dashboard | Contenido |
|-----------|-----------|
| `Banca-Overview` | Vista general del ecosistema |
| `ArcBank-Metrics` | Métricas específicas de ArcBank |
| `Switch-Metrics` | Métricas del Switch |

### Archivos Terraform

```
modules/observability/
├── variables.tf
├── outputs.tf
├── sns.tf                      # Topics de notificación
├── cloudwatch_alarms.tf        # Alarmas
└── cloudwatch_dashboards.tf    # Dashboards
```

---

# 🏗️ Arquitectura del Sistema

## Diagrama de Red

```
                           ┌─────────────────────────────────────────────────────────┐
                           │                    VPC: 10.0.0.0/16                      │
                           │                                                          │
┌──────────┐               │  ┌─────────────────────────────────────────────────────┐│
│ INTERNET │◄──────────────┼──│         SUBNETS PÚBLICAS (10.0.1.0/24, 10.0.2.0/24) ││
└──────────┘               │  │  ┌──────────────┐  ┌───────────────┐                ││
     │                     │  │  │ Internet GW  │  │  NAT Gateway  │                ││
     │                     │  │  └──────────────┘  └───────────────┘                ││
     ▼                     │  └─────────────────────────────────────────────────────┘│
┌──────────┐               │                          │                              │
│   API    │               │                          ▼                              │
│ GATEWAY  │               │  ┌─────────────────────────────────────────────────────┐│
└────┬─────┘               │  │        SUBNETS PRIVADAS (10.0.10.0/24, 10.0.11.0/24)││
     │                     │  │                                                      ││
     │ VPC Link            │  │   ┌─────────────────────────────────────────────┐   ││
     └─────────────────────┼──┼──►│                EKS CLUSTER                  │   ││
                           │  │   │  ┌─────────┐ ┌─────────┐ ┌─────────┐       │   ││
                           │  │   │  │ Switch  │ │ ArcBank │ │ Nexus   │  ...  │   ││
                           │  │   │  │ (Pods)  │ │ (Pods)  │ │ (Pods)  │       │   ││
                           │  │   │  └────┬────┘ └────┬────┘ └────┬────┘       │   ││
                           │  │   └───────┼──────────┼──────────┼──────────────┘   ││
                           │  │           │          │          │                   ││
                           │  │           ▼          ▼          ▼                   ││
                           │  │   ┌─────────────────────────────────────────────┐   ││
                           │  │   │              RDS POSTGRESQL (x5)            │   ││
                           │  │   └─────────────────────────────────────────────┘   ││
                           │  └─────────────────────────────────────────────────────┘│
                           └─────────────────────────────────────────────────────────┘
```

---

# 🔄 Flujo de Transferencias Interbancarias

## Ejemplo: Nexus → Bantec ($500)

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│ BANCO NEXUS  │         │    SWITCH    │         │   RABBITMQ   │         │ BANCO BANTEC │
│   (Origen)   │         │  DIGICONECU  │         │              │         │  (Destino)   │
└──────┬───────┘         └──────┬───────┘         └──────┬───────┘         └──────┬───────┘
       │                        │                        │                        │
       │ 1. POST /transferir    │                        │                        │
       │    {monto: 500,        │                        │                        │
       │     destino: BANTEC}   │                        │                        │
       │───────────────────────►│                        │                        │
       │                        │                        │                        │
       │                        │ 2. Switch procesa:     │                        │
       │                        │    - Valida cuentas    │                        │
       │                        │    - Registra en DB    │                        │
       │                        │    - Débita a Nexus    │                        │
       │                        │                        │                        │
       │                        │ 3. Publica mensaje     │                        │
       │                        │    routingKey="BANTEC" │                        │
       │                        │───────────────────────►│                        │
       │                        │                        │                        │
       │                        │                        │ 4. RabbitMQ enruta     │
       │                        │                        │    a q.bank.BANTEC.in  │
       │                        │                        │───────────────────────►│
       │                        │                        │                        │
       │                        │                        │                        │ 5. Bantec
       │                        │                        │                        │    acredita
       │                        │                        │                        │    $500
       │                        │                        │                        │
       │◄─────────────────────────────────────────────────────────────────────────│
       │                    6. Webhook confirmación                               │
```

## Colas RabbitMQ

| Cola | Banco | Uso |
|------|-------|-----|
| `q.bank.NEXUS.in` | Nexus | Recibe transferencias para Nexus |
| `q.bank.BANTEC.in` | Bantec | Recibe transferencias para Bantec |
| `q.bank.ARCBANK.in` | ArcBank | Recibe transferencias para ArcBank |
| `q.bank.ECUSOL.in` | Ecusol | Recibe transferencias para Ecusol |

---

# 💰 Control de Costos

## Variables de Control

| Variable | Default | Efecto al Activar |
|----------|---------|-------------------|
| `eks_enabled` | `false` | +$100/mes (EKS + NAT) |
| `elasticache_enabled` | `false` | +$15/mes (Redis) |
| `enable_alarms` | `true` | +$5/mes (CloudWatch) |

## Escenarios de Costo

| Escenario | Configuración | Costo Mensual |
|-----------|---------------|---------------|
| **Desarrollo** | Todo apagado | ~$130/mes |
| **Demo/Testing** | EKS on, Redis off | ~$235/mes |
| **Completo** | Todo encendido | ~$250/mes |

## Comandos para Controlar Costos

```bash
# Apagar EKS (ahorrar $100/mes)
terraform apply -var="eks_enabled=false"

# Encender EKS cuando lo necesites
terraform apply -var="eks_enabled=true"

# Encender Redis cuando lo necesites
terraform apply -var="elasticache_enabled=true"
```

---

# 🚀 Guía de Despliegue

## Pre-requisitos

```bash
# Verificar herramientas
terraform --version    # >= 1.0
aws --version          # >= 2.0
kubectl version        # >= 1.28
```

## 1. Despliegue Inicial (Sin EKS)

```bash
# Inicializar
cd proyecto-bancario-devops
terraform init

# Ver cambios
terraform plan

# Aplicar (sin EKS para ahorrar)
terraform apply
```

## 2. Activar EKS (Cuando lo necesites)

```bash
# Activar EKS
terraform apply -var="eks_enabled=true"

# Esperar ~15 minutos...

# Configurar kubectl
aws eks update-kubeconfig --name eks-banca-ecosistema --region us-east-2

# Verificar
kubectl get nodes
```

## 3. Parche Crítico para CoreDNS

```bash
# OBLIGATORIO después de crear EKS
kubectl patch deployment coredns -n kube-system \
  --type json \
  -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'

kubectl rollout restart deployment coredns -n kube-system
```

## 4. Instalar AWS Load Balancer Controller

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks-banca-ecosistema \
  --set region=us-east-2
```

---

# 📦 Microservicios por Entidad

## Switch DIGICONECU (6 microservicios)

| Microservicio | ECR Repo | Función |
|---------------|----------|---------|
| gateway-internal | `switch-gateway-internal` | Punto de entrada interno |
| ms-nucleo | `switch-ms-nucleo` | Lógica central del Switch |
| ms-contabilidad | `switch-ms-contabilidad` | Registro contable |
| ms-compensacion | `switch-ms-compensacion` | Compensación de transacciones |
| ms-devolucion | `switch-ms-devolucion` | Manejo de devoluciones |
| ms-directorio | `switch-ms-directorio` | Directorio de bancos |

## ArcBank (5 microservicios)

| Microservicio | ECR Repo |
|---------------|----------|
| gateway-server | `arcbank-gateway-server` |
| service-clientes | `arcbank-service-clientes` |
| service-cuentas | `arcbank-service-cuentas` |
| service-transacciones | `arcbank-service-transacciones` |
| service-sucursales | `arcbank-service-sucursales` |

## Bantec (5 microservicios)

| Microservicio | ECR Repo |
|---------------|----------|
| gateway-server | `bantec-gateway-server` |
| service-clientes | `bantec-service-clientes` |
| service-cuentas | `bantec-service-cuentas` |
| service-transacciones | `bantec-service-transacciones` |
| service-sucursales | `bantec-service-sucursales` |

## Nexus (7 microservicios)

| Microservicio | ECR Repo |
|---------------|----------|
| gateway | `nexus-gateway` |
| ms-clientes | `nexus-ms-clientes` |
| cbs | `nexus-cbs` |
| ms-transacciones | `nexus-ms-transacciones` |
| ms-geografia | `nexus-ms-geografia` |
| web-backend | `nexus-web-backend` |
| ventanilla-backend | `nexus-ventanilla-backend` |

## Ecusol (6 microservicios)

| Microservicio | ECR Repo |
|---------------|----------|
| gateway-server | `ecusol-gateway-server` |
| ms-clientes | `ecusol-ms-clientes` |
| ms-cuentas | `ecusol-ms-cuentas` |
| ms-transacciones | `ecusol-ms-transacciones` |
| ms-geografia | `ecusol-ms-geografia` |
| web-backend | `ecusol-web-backend` |

---

# 🔐 Seguridad y Autenticación

## Capas de Seguridad

| Capa | Tecnología | Propósito |
|------|-----------|-----------|
| **Transporte** | TLS 1.2 | Encriptación de datos |
| **Identidad** | Cognito + OAuth 2.0 | Autenticación de bancos |
| **Integridad** | Firma JWS (X-JWS-Signature) | Verificar que el mensaje no fue alterado |
| **Red** | Security Groups + VPC | Aislamiento de red |

## Cognito Scopes

| Scope | Uso |
|-------|-----|
| `transfers.write` | Permite crear transferencias |

## Requisitos de Seguridad para Bancos

| Archivo | Propósito |
|---------|-----------|

| `public_key.pem` | Validación de firmas JWS |

---

# 📊 Observabilidad y Monitoreo

## Dashboards CloudWatch

| Dashboard | URL |
|-----------|-----|
| Banca-Overview | `https://us-east-2.console.aws.amazon.com/cloudwatch/home#dashboards:name=Banca-Overview-dev` |

## Para Recibir Alertas por Email

```bash
terraform apply -var="alarm_email=tu-email@ejemplo.com"
```

---

# 🛠️ Comandos Útiles

## Terraform

```bash
# Ver outputs
terraform output

# Ver endpoint de RabbitMQ
terraform output rabbitmq_console_url

# Ver endpoint de API Gateway
terraform output api_gateway_endpoint
```

## EKS / Kubernetes

```bash
# Configurar kubectl
aws eks update-kubeconfig --name eks-banca-ecosistema --region us-east-2

# Ver todos los pods
kubectl get pods -A

# Ver logs de un pod
kubectl logs -n switch <pod-name>
```

## AWS CLI

```bash
# Ver estado del cluster
aws eks describe-cluster --name eks-banca-ecosistema

# Ver RDS instances
aws rds describe-db-instances

# Ver secretos
aws secretsmanager list-secrets
```

---

# 📁 Estructura del Proyecto

```
proyecto-bancario-devops/
├── main.tf                  # Orquestador principal
├── variables.tf             # Variables de entrada
├── outputs.tf               # Outputs del proyecto
├── backend.tf               # Configuración S3 backend
├── terraform.tfvars         # Valores de variables (crear si no existe)
│
├── modules/
│   ├── networking/          # VPC, Subnets, Routes, Security Groups
│   ├── iam/                 # Roles y políticas IAM
│   ├── storage/             # ECR, S3
│   ├── databases/           # RDS, DynamoDB, ElastiCache
│   ├── messaging/           # Amazon MQ (RabbitMQ)
│   ├── compute/             # EKS, Fargate
│   ├── api-gateway/         # API Gateway, VPC Link
│   ├── security-certs/      # Cognito, Secrets
│   └── observability/       # CloudWatch, SNS
│
├── k8s-manifests/           # Manifiestos Kubernetes
│   ├── namespaces/
│   ├── deployments/
│   └── CICD_GUIDE.md
│
└── MASTER.md                # Este documento
```

---

**Documento generado automáticamente**  
**Última actualización:** 2026-02-05  
**Versión:** 5.0
