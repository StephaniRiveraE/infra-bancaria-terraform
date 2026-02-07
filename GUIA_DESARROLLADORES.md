# 🚀 Guía de Despliegue para Desarrolladores

## Información General

Esta guía explica cómo desplegar microservicios al cluster de Kubernetes (EKS).

**Región AWS:** `us-east-2`  
**Cluster EKS:** `eks-banca-ecosistema`

---

## 🔧 Requisitos Previos

Antes de desplegar, asegúrate de tener:

1. **Dockerfile** en el root de tu proyecto
2. **GitHub Actions Secrets** configurados:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. **Workflow file** en `.github/workflows/deploy.yml`

---

## 📁 Paso 1: Crear el Workflow

Copia este archivo en tu repositorio: `.github/workflows/deploy.yml`

```yaml
name: "Build & Deploy to EKS"

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

env:
  AWS_REGION: us-east-2
  EKS_CLUSTER: eks-banca-ecosistema
  
  # ⚠️ CAMBIAR ESTOS 3 VALORES (ver tabla abajo)
  ECR_REPOSITORY: TU_ECR_AQUI
  NAMESPACE: TU_NAMESPACE_AQUI
  SERVICE_NAME: TU_SERVICE_AQUI

jobs:
  build:
    name: "Build & Push to ECR"
    runs-on: ubuntu-latest
    outputs:
      image_tag: ${{ steps.build-image.outputs.image_tag }}

    steps:
      - name: "Checkout código"
        uses: actions/checkout@v4

      - name: "Configurar AWS Credentials"
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: "Login a Amazon ECR"
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: "Build y Push imagen Docker"
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:latest .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
          echo "image_tag=$IMAGE_TAG" >> $GITHUB_OUTPUT

  deploy:
    name: "Deploy to EKS"
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    steps:
      - name: "Checkout código"
        uses: actions/checkout@v4

      - name: "Configurar AWS Credentials"
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: "Login a Amazon ECR"
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: "Configurar kubectl"
        run: |
          aws eks update-kubeconfig --name $EKS_CLUSTER --region $AWS_REGION

      - name: "Actualizar imagen en deployment"
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ needs.build.outputs.image_tag }}
        run: |
          kubectl set image deployment/$SERVICE_NAME \
            $SERVICE_NAME=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG \
            -n $NAMESPACE
          kubectl rollout status deployment/$SERVICE_NAME -n $NAMESPACE --timeout=300s

      - name: "Verificar pods"
        run: |
          kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME
```

---

## 📋 Paso 2: Configurar tus Variables

Busca la sección `env:` en el workflow y cambia los 3 valores según tu microservicio:

---

### 🔴 SWITCH

| Microservicio | ECR_REPOSITORY | NAMESPACE | SERVICE_NAME |
|---------------|----------------|-----------|--------------|
| Gateway Internal | `switch-gateway-internal` | `switch` | `gateway-internal` |
| Núcleo | `switch-ms-nucleo` | `switch` | `ms-nucleo` |
| Contabilidad | `switch-ms-contabilidad` | `switch` | `ms-contabilidad` |
| Compensación | `switch-ms-compensacion` | `switch` | `ms-compensacion` |
| Devolución | `switch-ms-devolucion` | `switch` | `ms-devolucion` |
| Directorio | `switch-ms-directorio` | `switch` | `ms-directorio` |

---

### 🔵 ARCBANK

| Microservicio | ECR_REPOSITORY | NAMESPACE | SERVICE_NAME |
|---------------|----------------|-----------|--------------|
| Gateway | `arcbank-gateway-server` | `arcbank` | `gateway-server` |
| Clientes | `arcbank-service-clientes` | `arcbank` | `service-clientes` |
| Cuentas | `arcbank-service-cuentas` | `arcbank` | `service-cuentas` |
| Transacciones | `arcbank-service-transacciones` | `arcbank` | `service-transacciones` |
| Sucursales | `arcbank-service-sucursales` | `arcbank` | `service-sucursales` |

---

### 🟢 BANTEC

| Microservicio | ECR_REPOSITORY | NAMESPACE | SERVICE_NAME |
|---------------|----------------|-----------|--------------|
| Gateway | `bantec-gateway-server` | `bantec` | `gateway-server` |
| Clientes | `bantec-service-clientes` | `bantec` | `service-clientes` |
| Cuentas | `bantec-service-cuentas` | `bantec` | `service-cuentas` |
| Transacciones | `bantec-service-transacciones` | `bantec` | `service-transacciones` |
| Sucursales | `bantec-service-sucursales` | `bantec` | `service-sucursales` |

---

### 🟡 NEXUS

| Microservicio | ECR_REPOSITORY | NAMESPACE | SERVICE_NAME |
|---------------|----------------|-----------|--------------|
| Gateway | `nexus-gateway` | `nexus` | `gateway` |
| Clientes | `nexus-ms-clientes` | `nexus` | `ms-clientes` |
| CBS | `nexus-cbs` | `nexus` | `cbs` |
| Transacciones | `nexus-ms-transacciones` | `nexus` | `ms-transacciones` |
| Geografía | `nexus-ms-geografia` | `nexus` | `ms-geografia` |
| Web Backend | `nexus-web-backend` | `nexus` | `web-backend` |
| Ventanilla | `nexus-ventanilla-backend` | `nexus` | `ventanilla-backend` |

---

### 🟣 ECUSOL

| Microservicio | ECR_REPOSITORY | NAMESPACE | SERVICE_NAME |
|---------------|----------------|-----------|--------------|
| Gateway | `ecusol-gateway-server` | `ecusol` | `gateway-server` |
| Clientes | `ecusol-ms-clientes` | `ecusol` | `ms-clientes` |
| Cuentas | `ecusol-ms-cuentas` | `ecusol` | `ms-cuentas` |
| Transacciones | `ecusol-ms-transacciones` | `ecusol` | `ms-transacciones` |
| Geografía | `ecusol-ms-geografia` | `ecusol` | `ms-geografia` |
| Web Backend | `ecusol-web-backend` | `ecusol` | `web-backend` |
| Ventanilla | `ecusol-ventanilla-backend` | `ecusol` | `ventanilla-backend` |

---

## 🔐 Paso 3: Configurar Secrets en GitHub

En tu repositorio de GitHub:

1. Ve a **Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Añade estos secrets:

| Secret Name | Valor |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | (Pedir a DevOps) |
| `AWS_SECRET_ACCESS_KEY` | (Pedir a DevOps) |

---

## 🐳 Paso 4: Crear Dockerfile

Tu proyecto debe tener un `Dockerfile` en el root. Ejemplo para Spring Boot:

```dockerfile
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## 🔄 Flujo de Despliegue

```
1. Desarrollador hace push a main
         │
         ▼
2. GitHub Actions:
   ├── Build del proyecto
   ├── Crea imagen Docker
   ├── Sube imagen a ECR (AWS)
   └── Despliega a Kubernetes (EKS)
         │
         ▼
3. Tu microservicio está corriendo en el cluster
```

---

## ❓ Preguntas Frecuentes

### ¿Qué es el Namespace?
Es una "carpeta" dentro de Kubernetes que agrupa todos los microservicios de tu banco.

### ¿Qué es ECR?
Amazon Elastic Container Registry - es donde se guardan las imágenes Docker.

### ¿Cuándo se despliega?
- **Pull Request a main** → Solo build (sin deploy)
- **Push a main (merge)** → Build + Deploy automático

### ¿Cómo veo si mi deploy funcionó?
En GitHub → Actions → verás el estado del workflow con ✅ o ❌

---

## 🆘 Soporte

Si tienes problemas:
1. Revisa los logs en GitHub Actions
2. Contacta al equipo de DevOps

---

**Última actualización:** 2026-02-05
