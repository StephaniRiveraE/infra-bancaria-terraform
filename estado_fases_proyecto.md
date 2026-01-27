# 📊 Estado de Implementación: Ecosistema Bancario AWS

Este documento detalla qué recursos están **realmente implementados** en el código Terraform, cómo están configurados, dónde encontrarlos en la consola de AWS, y qué falta para completar cada fase según el Plan Maestro.

---

## 🏗️ Fase 1: El Cimiento (Red, Seguridad y Almacenamiento)

**Estado:** ✅ **Completamente Implementado** (Módulos: `networking`, `iam`, `storage`)

### 📦 Lo que está implementado:

| Recurso | Nombre en Terraform | Identificador / Tag (AWS Console) | Configuración Clave |
|---------|---------------------|-----------------------------------|---------------------|
| **VPC** | `aws_vpc.vpc_bancaria` | `vpc-ecosistema-bancario` | CIDR: `10.0.0.0/16` |
| **Subnet Pública A** | `aws_subnet.public_az1` | `public-1a` | Zona: Usar var (probablemente us-east-2a) |
| **Subnet Pública B** | `aws_subnet.public_az2` | `public-1b` | Zona: Usar var (probablemente us-east-2b) |
| **Subnet Privada A** | `aws_subnet.private_az1` | `private-1a` | Protegida por NAT Gateway |
| **Subnet Privada B** | `aws_subnet.private_az2` | `private-1b` | Protegida por NAT Gateway |
| **NAT Gateway** | `aws_nat_gateway.nat` | `main-nat-gateway` | Conectado a `public-1a` con EIP estática |
| **ECR Repos** | `aws_ecr_repository.repos` | *Ver lista abajo* | `MUTABLE`, Scan on Push: `Yes` |
| **IAM Roles** | (Módulo IAM) | Tags comunes | Roles para EKS y Fargate |

#### 🔍 Cómo buscar en AWS Console:
1.  **VPC:** Ve a servicio **VPC** -> **Your VPCs** -> Buscar "ecosistema".
2.  **Subnets:** Ve a **VPC** -> **Subnets** -> Filtrar por VPC ID anterior.
3.  **ECR:** Ve a **Elastic Container Registry** -> **Repositories**. Verás repos como:
    *   `switch-gateway-internal`, `nexus-cbs`, `arcbank-service-clientes`, etc.

### ❌ Lo que falta:
*   Nada. Esta fase está completa en el código.

---

## 💾 Fase 2: Datos y Mensajería

**Estado:** 🟡 **Parcialmente Implementado** (Módulos: `databases`, `messaging`, `storage`)

### 📦 Lo que está implementado:

| Recurso | Nombre en Terraform | Identificador (AWS Console) | Configuración Clave |
|---------|---------------------|-----------------------------|---------------------|
| **RDS (Postgres)** | `aws_db_instance.rds_instances` | `rds-arcbank`, `rds-nexus`, etc. | Engine: `postgres`, Storage: `20GB`, Encrypted: `Yes` |
| **DynamoDB (Switch)**| `aws_dynamodb_table.switch_directorio` | `switch-directorio-instituciones` | PK: `institucion_id`, Billing: `PAY_PER_REQUEST` |
| **DynamoDB (Geo)** | `aws_dynamodb_table.sucursales_tables` | `arcbank-sucursales-geo`, etc. | PK: `sucursal_id`, Billing: `PAY_PER_REQUEST` |
| **SQS (Colas)** | `aws_sqs_queue` | `switch-transferencias-interbancarias.fifo` | Tipo: `FIFO`, Dedup: `Yes`, Visibilidad: `60s` |
| **SQS (DLQ)** | `aws_sqs_queue` | `switch-transferencias-deadletter.fifo` | Retries antes de DLQ: `4` |
| **S3 Buckets** | `aws_s3_bucket.frontends` | `banca-ecosistema-{nombre}-512be32e` | Bloqueo acceso público: `Yes`, Encriptado: `Yes` |
| **Secretos DB** | `aws_secretsmanager_secret` | `rds-secret-{banco}-v2` | Contiene user/pass de RDS generado aleatoriamente |

#### 🔍 Cómo buscar en AWS Console:
1.  **RDS:** Ve a **RDS** -> **Databases**. Busca por identificador (ej. `rds-arcbank`). Revisar pestaña "Connectivity" para ver Security Groups.
2.  **DynamoDB:** Ve a **DynamoDB** -> **Tables**.
3.  **SQS:** Ve a **Simple Queue Service** -> **Queues**. Busca "switch".
4.  **S3:** Ve a **S3**. Busca buckets que empiecen con `banca-ecosistema`.
5.  **Secrets:** Ve a **Secrets Manager**. Busca `rds-secret`.

### ❌ Lo que falta:
*   **ElastiCache (Redis):** No existe archivo `elasticache.tf` ni recursos de Redis en el módulo `databases`.

---

## 🧠 Fase 3: Cómputo (Kubernetes)

**Estado:** ✅ **Completamente Implementado** (Módulo: `compute`)

### 📦 Lo que está implementado:

| Recurso | Nombre en Terraform | Identificador (AWS Console) | Configuración Clave |
|---------|---------------------|------------------------------|---------------------|
| **EKS Cluster** | `aws_eks_cluster.bancario` | `eks-banca-ecosistema` | Version: `1.29`, Logs habilitados |
| **Fargate Profile** | `aws_eks_fargate_profile.entities["arcbank"]` | `fargate-arcbank` | Namespace: `arcbank` |
| **Fargate Profile** | `aws_eks_fargate_profile.entities["bantec"]` | `fargate-bantec` | Namespace: `bantec` |
| **Fargate Profile** | `aws_eks_fargate_profile.entities["nexus"]` | `fargate-nexus` | Namespace: `nexus` |
| **Fargate Profile** | `aws_eks_fargate_profile.entities["ecusol"]` | `fargate-ecusol` | Namespace: `ecusol` |
| **Fargate Profile** | `aws_eks_fargate_profile.entities["switch"]` | `fargate-switch` | Namespace: `switch` |
| **Fargate Profile** | `aws_eks_fargate_profile.kube_system` | `fargate-kube-system` | CoreDNS |
| **Fargate Profile** | `aws_eks_fargate_profile.aws_lb_controller` | `fargate-aws-lb-controller` | ALB Controller |
| **EKS Addon** | `aws_eks_addon.vpc_cni` | `vpc-cni` | Plugin de red |
| **EKS Addon** | `aws_eks_addon.kube_proxy` | `kube-proxy` | Proxy de servicios |
| **EKS Addon** | `aws_eks_addon.coredns` | `coredns` | DNS interno |
| **EKS Addon** | `aws_eks_addon.pod_identity` | `eks-pod-identity-agent` | IRSA |
| **OIDC Provider** | `aws_iam_openid_connect_provider.eks` | `eks-oidc-provider` | Para IAM Roles en pods |
| **IAM Role** | `aws_iam_role.alb_controller` | `eks-alb-controller-role` | ALB Controller |
| **Security Group** | `aws_security_group.eks_cluster_sg` | `eks-cluster-sg` | Ingress 443 VPC |
| **CloudWatch Logs** | `aws_cloudwatch_log_group.eks_cluster` | `/aws/eks/eks-banca-ecosistema/cluster` | 30 días retención |

#### 🔍 Cómo buscar en AWS Console:
1. **EKS:** Ve a **Amazon EKS** → **Clusters** → `eks-banca-ecosistema`
2. **Fargate Profiles:** Dentro del clúster → Pestaña **Compute** → **Fargate profiles**
3. **Addons:** Dentro del clúster → Pestaña **Add-ons**
4. **OIDC:** Ve a **IAM** → **Identity providers**
5. **Rol ALB:** Ve a **IAM** → **Roles** → `eks-alb-controller-role`

### 📋 Post-Apply (Comandos manuales necesarios):
Ver [FASE3_EKS_GUIA.md](./FASE3_EKS_GUIA.md) para el paso a paso completo.

### ❌ Lo que falta:
*   Nada. Esta fase está completa en el código.
*   **Nota:** Requiere comandos post-apply para parchar CoreDNS e instalar ALB Controller via Helm.

---

## 🛡️ Fase 4: Seguridad y API Gateway

**Estado:** 🟠 **Código Existente pero Inactivo** (Módulo: `api-gateway`)

### 📦 Lo que está implementado (En código, NO desplegado):
*   El código existe en `modules/api-gateway/*.tf` e incluye:
    *   **API Gateway HTTP:** `apim-switch-gateway`.
    *   **VPC Link:** `apim-vpc-link` para conectar con backend privado.
    *   **Rutas:** Definiciones de rutas en `apim_routes.tf`.
    *   **Circuit Breaker:** Lógica en `apim_circuit_breaker.tf`.
*   **NOTA:** Este módulo **NO** está siendo llamado en el archivo `c:/proyecto-bancario-devops/main.tf`, por lo tanto, si ejecutas `terraform apply` desde la raíz, **estos recursos NO se crearán**.

### ❌ Lo que falta:
*   **Activar el módulo:** Agregar el bloque `module "api_gateway" { ... }` en `main.tf`.
*   **Cognito:** No se encontró código para User Pools o App Clients.
*   **WAF:** No hay configuración de Web Application Firewall.

---

## 👁️ Fase 5: Observabilidad

**Estado:** 🔴 **Pendiente**

### 📦 Lo que está implementado:
*   Nada significativo.

### ❌ Lo que falta:
*   **CloudWatch Dashboards:** No hay código Terraform para paneles de métricas.
*   **Alarmas:** Faltan alarmas de CloudWatch.
*   **OpenSearch:** No hay dominio de OpenSearch configurado.
*   **Prometheus/Grafana:** Típicamente se instalan via Helm (fuera de Terraform base o usando provider helm), pero no hay evidencia de ello aquí.

---

## 📝 Resumen de Acción Inmediata

1.  **Fase 2 (75%):** Falta crear el recurso de **ElastiCache (Redis)**.
2.  **Fase 3 (100%):** ✅ Completada. Ver [FASE3_EKS_GUIA.md](./FASE3_EKS_GUIA.md) para comandos post-apply.
3.  **Fase 4:** Activar el módulo `api-gateway` en `main.tf`.
4.  **Fase 5:** Pendiente de implementación.

---

**Última actualización:** 2026-01-27

