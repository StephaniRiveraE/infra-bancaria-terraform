# 🚀 Guía Completa de Despliegue a Kubernetes (EKS)

> **Última actualización:** 2026-02-08  
> **Cluster:** eks-banca-ecosistema  
> **Región:** us-east-2 (Ohio)

---

## 📋 Resumen Rápido

```
Tu código → Push a main → GitHub Actions → ECR → EKS → ¡Funcionando! 🎉
```

| Tu rol | Pasos |
|--------|-------|
| **Desarrollador** | 1. Tener Dockerfile ✓ 2. Copiar workflow ✓ 3. Push a main ✓ |
| **DevOps** | Ya configuró todo en EKS ✅ |

---

## 🏦 Tu Banco y Microservicios

### ArcBank
| SERVICE_NAME | ECR_REPO | NAMESPACE |
|--------------|----------|-----------|
| gateway-server | `arcbank-gateway-server` | arcbank |
| service-clientes | `arcbank-service-clientes` | arcbank |
| service-cuentas | `arcbank-service-cuentas` | arcbank |
| service-transacciones | `arcbank-service-transacciones` | arcbank |
| service-sucursales | `arcbank-service-sucursales` | arcbank |

### Bantec
| SERVICE_NAME | ECR_REPO | NAMESPACE |
|--------------|----------|-----------|
| gateway-server | `bantec-gateway-server` | bantec |
| service-clientes | `bantec-service-clientes` | bantec |
| service-cuentas | `bantec-service-cuentas` | bantec |
| service-transacciones | `bantec-service-transacciones` | bantec |
| service-sucursales | `bantec-service-sucursales` | bantec |

### Nexus
| SERVICE_NAME | ECR_REPO | NAMESPACE |
|--------------|----------|-----------|
| nexus-gateway | `nexus-gateway` | nexus |
| nexus-ms-clientes | `nexus-ms-clientes` | nexus |
| nexus-cbs | `nexus-cbs` | nexus |
| nexus-ms-transacciones | `nexus-ms-transacciones` | nexus |
| nexus-ms-geografia | `nexus-ms-geografia` | nexus |
| nexus-web-backend | `nexus-web-backend` | nexus |
| nexus-ventanilla-backend | `nexus-ventanilla-backend` | nexus |

### EcuSol
| SERVICE_NAME | ECR_REPO | NAMESPACE |
|--------------|----------|-----------|
| ecusol-gateway-server | `ecusol-gateway-server` | ecusol |
| ecusol-ms-clientes | `ecusol-ms-clientes` | ecusol |
| ecusol-ms-cuentas | `ecusol-ms-cuentas` | ecusol |
| ecusol-ms-transacciones | `ecusol-ms-transacciones` | ecusol |
| ecusol-ms-geografia | `ecusol-ms-geografia` | ecusol |
| ecusol-web-backend | `ecusol-web-backend` | ecusol |
| ecusol-ventanilla-backend | `ecusol-ventanilla-backend` | ecusol |

### Switch DIGICONECU
| SERVICE_NAME | ECR_REPO | NAMESPACE |
|--------------|----------|-----------|
| switch-gateway-internal | `switch-gateway-internal` | switch |
| switch-ms-nucleo | `switch-ms-nucleo` | switch |
| switch-ms-contabilidad | `switch-ms-contabilidad` | switch |
| switch-ms-compensacion | `switch-ms-compensacion` | switch |
| switch-ms-devolucion | `switch-ms-devolucion` | switch |
| switch-ms-directorio | `switch-ms-directorio` | switch |

---

## ⚙️ Paso 1: Preparar tu Proyecto

### 1.1 Crear Dockerfile

En la **raíz** de tu proyecto, crea un archivo `Dockerfile`:

```dockerfile
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 1.2 Configurar application.properties

Usa **variables de entorno**, NO valores hardcodeados:

```properties
# Base de Datos (Kubernetes inyecta estos valores automáticamente)
spring.datasource.url=${SPRING_DATASOURCE_URL}
spring.datasource.username=${SPRING_DATASOURCE_USERNAME}
spring.datasource.password=${SPRING_DATASOURCE_PASSWORD}

# RabbitMQ (conexión directa a Amazon MQ)
spring.rabbitmq.host=b-455e546c-be71-4fe2-ba0f-bd3112e6c220.mq.us-east-2.on.aws
spring.rabbitmq.port=5671
spring.rabbitmq.username=mqadmin
spring.rabbitmq.password=${RABBITMQ_PASSWORD}
spring.rabbitmq.ssl.enabled=true

# Perfil activo
spring.profiles.active=prod
```

### 1.3 Agregar Health Endpoints (Importante!)

En tu `pom.xml`, asegura tener:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

En `application.properties`:

```properties
management.endpoints.web.exposure.include=health
management.endpoint.health.probes.enabled=true
management.health.livenessState.enabled=true
management.health.readinessState.enabled=true
```

---

## 📝 Paso 2: Configurar GitHub Actions

### 2.1 Copiar el Workflow

Crea esta estructura en tu repositorio:

```
mi-microservicio/
├── .github/
│   └── workflows/
│       └── deploy.yml    ← Crear este archivo
├── src/
├── Dockerfile
└── pom.xml
```

### 2.2 Contenido del workflow (deploy.yml)

```yaml
name: "Deploy to EKS"

on:
  push:
    branches: [main]

env:
  AWS_REGION: us-east-2
  EKS_CLUSTER: eks-banca-ecosistema
  
  # ⚠️ CAMBIAR ESTOS 3 VALORES SEGÚN TU MICROSERVICIO ⚠️
  NAMESPACE: arcbank                        # Tu banco (ver tabla arriba)
  ECR_REPO: arcbank-service-clientes        # Tu repo ECR (ver tabla arriba)
  SERVICE_NAME: service-clientes            # Tu microservicio (ver tabla arriba)

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: maven
      
      - name: Build with Maven
        run: mvn clean package -DskipTests
      
      - name: Configurar AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Login a ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2
      
      - name: Build y Push imagen Docker
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/${{ env.ECR_REPO }}:$IMAGE_TAG .
          docker push $ECR_REGISTRY/${{ env.ECR_REPO }}:$IMAGE_TAG
          echo "IMAGE=$ECR_REGISTRY/${{ env.ECR_REPO }}:$IMAGE_TAG" >> $GITHUB_ENV
      
      - name: Configurar kubectl
        run: aws eks update-kubeconfig --name ${{ env.EKS_CLUSTER }} --region ${{ env.AWS_REGION }}
      
      - name: Desplegar a EKS
        run: |
          kubectl set image deployment/${{ env.SERVICE_NAME }} \
            ${{ env.SERVICE_NAME }}=${{ env.IMAGE }} \
            -n ${{ env.NAMESPACE }}
          kubectl rollout status deployment/${{ env.SERVICE_NAME }} \
            -n ${{ env.NAMESPACE }} --timeout=300s
```

---

## 🔐 Paso 3: Configurar GitHub Secrets

En tu repositorio: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Valor | ¿Dónde obtenerlo? |
|--------|-------|-------------------|
| `AWS_ACCESS_KEY_ID` | `AKIA...` | Solicitar a DevOps |
| `AWS_SECRET_ACCESS_KEY` | `wJal...` | Solicitar a DevOps |

---

## 🚀 Paso 4: Hacer Deploy

```bash
# Compilar localmente primero (para verificar que funciona)
mvn clean package

# Commit y push
git add .
git commit -m "feat: deploy to EKS"
git push origin main
```

GitHub Actions se ejecutará automáticamente. Revisa en **Actions** tab de tu repo.

---

## ✅ Checklist Pre-Deploy

- [ ] Tengo `Dockerfile` en la raíz del proyecto
- [ ] Tengo `.github/workflows/deploy.yml`
- [ ] Cambié `NAMESPACE`, `ECR_REPO` y `SERVICE_NAME` en el workflow
- [ ] Mi `application.properties` usa variables de entorno `${...}`
- [ ] Tengo el actuator con health endpoints
- [ ] Configuré `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` en GitHub Secrets
- [ ] `mvn clean package` funciona sin errores

---

## 🔍 Verificar el Deploy

Después del push, puedes verificar:

```bash
# Ver pods de tu namespace
kubectl get pods -n arcbank

# Ver logs de un pod específico
kubectl logs -n arcbank deployment/service-clientes

# Ver estado del deployment
kubectl describe deployment service-clientes -n arcbank
```

---

## ❌ Errores Comunes y Soluciones

| Error | Causa | Solución |
|-------|-------|----------|
| `ImagePullBackOff` | Imagen no existe en ECR | Hacer push nuevamente |
| `CrashLoopBackOff` | App falla al iniciar | Revisar `kubectl logs -n {namespace} {pod-name}` |
| `repository does not exist` | ECR_REPO mal escrito | Verificar nombre en la tabla |
| `deployment not found` | SERVICE_NAME incorrecto | Verificar nombre en la tabla |
| `connection refused` | Error de BD | Verificar que usas `${SPRING_DATASOURCE_URL}` |
| `unauthorized` | Secrets mal configurados | Verificar AWS_ACCESS_KEY_ID en GitHub |

---

## 🗄️ Conexión a Base de Datos

Las credenciales de BD ya están configuradas como Kubernetes Secrets. Tu app las recibe automáticamente como variables de entorno:

| Variable | Descripción |
|----------|-------------|
| `SPRING_DATASOURCE_URL` | JDBC URL completa |
| `SPRING_DATASOURCE_USERNAME` | Usuario de BD |
| `SPRING_DATASOURCE_PASSWORD` | Contraseña de BD |

**NO necesitas hacer nada extra.** Solo asegúrate de usar estas variables en tu `application.properties`.

---

## 🐰 Conexión a RabbitMQ

RabbitMQ es un broker **público** con SSL. Configura directamente en tu app:

```properties
spring.rabbitmq.host=b-455e546c-be71-4fe2-ba0f-bd3112e6c220.mq.us-east-2.on.aws
spring.rabbitmq.port=5671
spring.rabbitmq.username=mqadmin
spring.rabbitmq.password=${RABBITMQ_PASSWORD}
spring.rabbitmq.ssl.enabled=true
```

**Contraseña:** Solicitar a DevOps o buscar en AWS Secrets Manager → `rabbitmq-credentials`

---

## 🌐 URLs de los Gateways (ALB)

Una vez desplegados los gateways, estarán disponibles en:

| Banco | URL del Gateway |
|-------|-----------------|
| ArcBank | `http://arcbank-api.banca-ecosistema.com` |
| Bantec | `http://bantec-api.banca-ecosistema.com` |
| Nexus | `http://nexus-api.banca-ecosistema.com` |
| EcuSol | `http://ecusol-api.banca-ecosistema.com` |

> **Nota:** Si no tienes dominio configurado, usa la URL del ALB directamente. Obtenerla con:
> ```
> kubectl get ingress -n arcbank
> ```

---

## 📞 Soporte

| Tema | Contacto |
|------|----------|
| Credenciales AWS | DevOps - awsproyecto26@gmail.com |
| Problemas de infraestructura | Repo: infra-bancaria-terraform |
| Errores en deploy | Revisar GitHub Actions logs |

---

## 🎉 ¡Listo!

Con esta guía, tu microservicio debería desplegarse automáticamente cada vez que hagas push a `main`. 

**Resumen del flujo:**
1. Push a main
2. GitHub Actions compila y crea imagen Docker
3. Imagen se sube a ECR
4. kubectl actualiza el deployment en EKS
5. ¡Tu pod está corriendo! 🚀
