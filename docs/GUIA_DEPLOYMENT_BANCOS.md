# Guía de Deployment: Repositorios de Bancos → EKS

Esta guía explica cómo los equipos de cada banco deben configurar sus repositorios para que los deployments se hagan automáticamente a Kubernetes (EKS Fargate).

---

## 📋 Resumen del Flujo

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Desarrollador │───▶│  GitHub Actions │───▶│   Amazon ECR    │───▶│   EKS Fargate   │
│   push a main   │    │   (CI/CD)       │    │   (Imágenes)    │    │   (Pods)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Cuando un desarrollador hace push a `main` en el repo de su banco:**
1. GitHub Actions construye la imagen Docker
2. La sube a ECR (ya existe el repositorio)
3. Actualiza el deployment en Kubernetes
4. EKS Fargate ejecuta el nuevo pod

---

## 🗂️ Estructura que debe tener cada Repo de Banco

```
ARCBANK/                        # (o BANTEC, NEXUS, ECUSOL, Switch)
├── .github/
│   └── workflows/
│       └── deploy.yml          ← Workflow de CI/CD (copiar de abajo)
│
├── k8s/
│   ├── deployment.yaml         ← Configuración del pod
│   ├── service.yaml            ← Expone el pod internamente
│   └── ingress.yaml            ← (Solo frontends) Expone al internet
│
├── src/                        ← Código fuente del microservicio
├── Dockerfile                  ← Para construir la imagen
└── ...
```

---

## 📁 Archivo 1: `.github/workflows/deploy.yml`

**Ubicación en el repo del banco:** `.github/workflows/deploy.yml`

**¿Qué hace?** Automatiza el build y deploy cuando hay push a main.

```yaml
name: Deploy to EKS

on:
  push:
    branches: [main]
  workflow_dispatch:  # Permite ejecutar manualmente

env:
  AWS_REGION: us-east-2
  EKS_CLUSTER: ecosistema-bancario
  
  # ╔════════════════════════════════════════════════════════════╗
  # ║  ⚠️ MODIFICAR ESTAS 3 VARIABLES SEGÚN EL BANCO            ║
  # ╚════════════════════════════════════════════════════════════╝
  BANK_NAME: arcbank              # Opciones: arcbank, bantec, nexus, ecusol, switch
  NAMESPACE: arcbank              # Mismo valor que BANK_NAME
  ECR_REPOSITORY: arcbank         # Para Switch usar: digiconecu-switch

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      # 1. Obtener código
      - name: Checkout code
        uses: actions/checkout@v4

      # 2. Configurar credenciales AWS
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      # 3. Login a ECR
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      # 4. Construir y subir imagen Docker
      - name: Build and push Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:$IMAGE_TAG .
          docker build -t $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:latest .
          docker push $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:$IMAGE_TAG
          docker push $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:latest

      # 5. Configurar kubectl
      - name: Update kubeconfig
        run: |
          aws eks update-kubeconfig --region ${{ env.AWS_REGION }} --name ${{ env.EKS_CLUSTER }}

      # 6. Desplegar a Kubernetes
      - name: Deploy to EKS
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          # Aplica los manifests de k8s/
          kubectl apply -f k8s/
          
          # Actualiza la imagen del deployment
          kubectl set image deployment/${{ env.BANK_NAME }}-deployment \
            ${{ env.BANK_NAME }}=$ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:$IMAGE_TAG \
            -n ${{ env.NAMESPACE }} --record
          
          # Espera a que el deployment termine
          kubectl rollout status deployment/${{ env.BANK_NAME }}-deployment \
            -n ${{ env.NAMESPACE }} --timeout=300s
```

---

## 📁 Archivo 2: `k8s/deployment.yaml`

**Ubicación en el repo del banco:** `k8s/deployment.yaml`

**¿Qué hace?** Define cómo se ejecuta el pod (contenedor) en Kubernetes.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  # ╔════════════════════════════════════════════════════════════╗
  # ║  ⚠️ MODIFICAR name y namespace SEGÚN EL BANCO             ║
  # ╚════════════════════════════════════════════════════════════╝
  name: arcbank-deployment        # Formato: {banco}-deployment
  namespace: arcbank              # Opciones: arcbank, bantec, nexus, ecusol, switch
  labels:
    app: arcbank
    bank: arcbank
spec:
  replicas: 1                     # 1 réplica (sin redundancia)
  selector:
    matchLabels:
      app: arcbank
  template:
    metadata:
      labels:
        app: arcbank
        bank: arcbank
    spec:
      containers:
      - name: arcbank             # Mismo que el banco
        # ╔════════════════════════════════════════════════════════════╗
        # ║  ⚠️ MODIFICAR la imagen con tu AWS_ACCOUNT_ID              ║
        # ╚════════════════════════════════════════════════════════════╝
        image: 123456789012.dkr.ecr.us-east-2.amazonaws.com/arcbank:latest
        ports:
        - containerPort: 8080     # Puerto de tu aplicación
        
        # Recursos asignados al pod
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        
        # Variables de entorno
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "production"
        # Agregar más variables según necesites
```

---

## 📁 Archivo 3: `k8s/service.yaml`

**Ubicación en el repo del banco:** `k8s/service.yaml`

**¿Qué hace?** Crea un endpoint interno para que otros pods puedan comunicarse con este.

```yaml
apiVersion: v1
kind: Service
metadata:
  # ╔════════════════════════════════════════════════════════════╗
  # ║  ⚠️ MODIFICAR name y namespace SEGÚN EL BANCO             ║
  # ╚════════════════════════════════════════════════════════════╝
  name: arcbank-service           # Formato: {banco}-service
  namespace: arcbank              # Opciones: arcbank, bantec, nexus, ecusol, switch
spec:
  selector:
    app: arcbank                  # Debe coincidir con el label del deployment
  ports:
  - protocol: TCP
    port: 80                      # Puerto expuesto
    targetPort: 8080              # Puerto del contenedor
  type: ClusterIP                 # Solo accesible dentro del cluster
```

---

## 📁 Archivo 4: `k8s/ingress.yaml` (Solo para Frontends)

**Ubicación en el repo del banco:** `k8s/ingress.yaml`

**¿Qué hace?** Expone el frontend al internet a través del Load Balancer.

⚠️ **SOLO USAR PARA FRONTENDS** (cajero web, banca web)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  # ╔════════════════════════════════════════════════════════════╗
  # ║  ⚠️ MODIFICAR name, namespace y host SEGÚN EL BANCO       ║
  # ╚════════════════════════════════════════════════════════════╝
  name: frontend-cajero-ingress
  namespace: arcbank
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - host: cajero.arcbank.example.com    # Tu dominio
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-cajero-service
            port:
              number: 80
```

---

## 🔐 Secrets de GitHub (Configurar en cada repo)

Cada repositorio de banco debe tener estos secrets configurados:

**Settings → Secrets and variables → Actions → New repository secret**

| Nombre del Secret | Valor |
|-------------------|-------|
| `AWS_ACCESS_KEY_ID` | Access Key del usuario IAM para CI/CD |
| `AWS_SECRET_ACCESS_KEY` | Secret Key del usuario IAM |

---

## 📊 Tabla de Configuración por Banco

| Banco | `BANK_NAME` | `NAMESPACE` | `ECR_REPOSITORY` |
|-------|-------------|-------------|------------------|
| ARCBANK | `arcbank` | `arcbank` | `arcbank` |
| BANTEC | `bantec` | `bantec` | `bantec` |
| NEXUS | `nexus` | `nexus` | `nexus` |
| ECUSOL | `ecusol` | `ecusol` | `ecusol` |
| Switch | `switch` | `switch` | `digiconecu-switch` |

---

## ❓ Preguntas Frecuentes

### ¿Qué pasa si mi microservicio necesita conectarse a la base de datos?

Agrega las variables de entorno en el `deployment.yaml`:

```yaml
env:
- name: DATABASE_URL
  value: "jdbc:postgresql://tu-rds-endpoint:5432/db"
- name: DATABASE_USER
  valueFrom:
    secretKeyRef:
      name: db-credentials
      key: username
```

### ¿Cómo me comunico con otro microservicio del mismo banco?

Usa el nombre del servicio interno:
```
http://{nombre-service}.{namespace}.svc.cluster.local
```

Ejemplo desde ARCBANK ms-auth a ms-cuentas:
```
http://ms-cuentas-service.arcbank.svc.cluster.local
```

### ¿Cómo veo los logs de mi pod?

```bash
kubectl logs -f deployment/arcbank-deployment -n arcbank
```

### ¿Cómo reinicio mi deployment?

```bash
kubectl rollout restart deployment/arcbank-deployment -n arcbank
```
test