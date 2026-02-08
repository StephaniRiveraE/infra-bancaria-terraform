# 🚀 Guía para Desarrolladores - Despliegue a AWS

> **Última actualización:** 2026-02-07

## 📋 Resumen del Flujo CI/CD

```
Tu código → Push a main → GitHub Actions → AWS (EKS o S3)
```

| Tipo de proyecto | Workflow a usar | Destino AWS |
|-----------------|-----------------|-------------|
| **Microservicio (Spring Boot)** | `deploy-to-eks.yml` | Amazon ECR → EKS |
| **Frontend (React/Angular/Vue)** | `deploy-to-s3.yml` | Amazon S3 |

---

# 🔧 PARTE 1: Microservicios (Backend)

## Tu Banco y Namespace

| Banco | NAMESPACE | 
|-------|-----------|
| ArcBank | `arcbank` |
| Bantec | `bantec` |
| Nexus | `nexus` |
| EcuSol | `ecusol` |
| Switch | `switch` |

---

## 📦 Repositorios ECR Disponibles

### ArcBank
| SERVICE_NAME | ECR_REPO |
|--------------|----------|
| gateway-server | `arcbank-gateway-server` |
| service-clientes | `arcbank-service-clientes` |
| service-cuentas | `arcbank-service-cuentas` |
| service-transacciones | `arcbank-service-transacciones` |
| service-sucursales | `arcbank-service-sucursales` |

### Bantec
| SERVICE_NAME | ECR_REPO |
|--------------|----------|
| gateway-server | `bantec-gateway-server` |
| service-clientes | `bantec-service-clientes` |
| service-cuentas | `bantec-service-cuentas` |
| service-transacciones | `bantec-service-transacciones` |
| service-sucursales | `bantec-service-sucursales` |

### Nexus
| SERVICE_NAME | ECR_REPO |
|--------------|----------|
| nexus-gateway | `nexus-gateway` |
| nexus-ms-clientes | `nexus-ms-clientes` |
| nexus-cbs | `nexus-cbs` |
| nexus-ms-transacciones | `nexus-ms-transacciones` |
| nexus-ms-geografia | `nexus-ms-geografia` |
| nexus-web-backend | `nexus-web-backend` |
| nexus-ventanilla-backend | `nexus-ventanilla-backend` |

### EcuSol
| SERVICE_NAME | ECR_REPO |
|--------------|----------|
| ecusol-gateway-server | `ecusol-gateway-server` |
| ecusol-ms-clientes | `ecusol-ms-clientes` |
| ecusol-ms-cuentas | `ecusol-ms-cuentas` |
| ecusol-ms-transacciones | `ecusol-ms-transacciones` |
| ecusol-ms-geografia | `ecusol-ms-geografia` |
| ecusol-web-backend | `ecusol-web-backend` |
| ecusol-ventanilla-backend | `ecusol-ventanilla-backend` |

### Switch
| SERVICE_NAME | ECR_REPO |
|--------------|----------|
| switch-gateway-internal | `switch-gateway-internal` |
| switch-ms-nucleo | `switch-ms-nucleo` |
| switch-ms-contabilidad | `switch-ms-contabilidad` |
| switch-ms-compensacion | `switch-ms-compensacion` |
| switch-ms-devolucion | `switch-ms-devolucion` |
| switch-ms-directorio | `switch-ms-directorio` |

---

## 🔧 Configuración del Workflow (Backend)

### Paso 1: Copia el archivo
Descarga `deploy-to-eks.yml` del repo de infraestructura y cópialo a tu repo en:
```
tu-microservicio/
└── .github/
    └── workflows/
        └── deploy.yml      ← Aquí
```

### Paso 2: Edita SOLO estas 3 líneas

```yaml
NAMESPACE: arcbank                       # ← Tu banco (ver tabla arriba)
ECR_REPO: arcbank-service-clientes       # ← Tu repo ECR (ver tabla arriba)
SERVICE_NAME: service-clientes           # ← Tu microservicio
```

### Paso 3: Configura GitHub Secrets
En tu repositorio → Settings → Secrets → Actions:

| Secret | Valor | ¿De dónde lo saco? |
|--------|-------|-------------------|
| `AWS_ACCESS_KEY_ID` | Access Key | Pregunta a DevOps |
| `AWS_SECRET_ACCESS_KEY` | Secret Key | Pregunta a DevOps |

---

## 🗄️ Configuración de Base de Datos

En tu `application.properties`:

```properties
spring.datasource.url=${SPRING_DATASOURCE_URL}
spring.datasource.username=${SPRING_DATASOURCE_USERNAME}
spring.datasource.password=${SPRING_DATASOURCE_PASSWORD}
```

**⚠️ NO pongas valores hardcodeados.** Kubernetes los inyecta automáticamente.

### ¿Cómo pruebo en local?
Crea un archivo `.env` (NO lo subas a Git):
```bash
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/mi_db
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=localpassword
```

---

## 🐰 Configuración de RabbitMQ

```properties
spring.rabbitmq.host=${RABBITMQ_HOST}
spring.rabbitmq.port=5671
spring.rabbitmq.username=${RABBITMQ_USERNAME}
spring.rabbitmq.password=${RABBITMQ_PASSWORD}
spring.rabbitmq.ssl.enabled=true
```

---

## 📦 Tu Dockerfile

Debe estar en la raíz de tu proyecto:

```dockerfile
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## ✅ Checklist Backend

- [ ] Tengo `Dockerfile` en la raíz
- [ ] Tengo `.github/workflows/deploy.yml`
- [ ] Cambié NAMESPACE, ECR_REPO y SERVICE_NAME
- [ ] Mi código usa variables de entorno para BD y RabbitMQ
- [ ] Configuré AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY en GitHub Secrets
- [ ] El proyecto compila con `mvn clean package`

---

# 🌐 PARTE 2: Frontends (S3)

## 📦 Buckets S3 Disponibles

| Frontend | S3_BUCKET |
|----------|-----------|
| **Switch** | |
| Admin Panel | `banca-ecosistema-switch-admin-panel-512be32e` |
| **ArcBank** | |
| Web Client | `banca-ecosistema-arcbank-web-client-512be32e` |
| Ventanilla App | `banca-ecosistema-arcbank-ventanilla-app-512be32e` |
| **Bantec** | |
| Web Client | `banca-ecosistema-bantec-web-client-512be32e` |
| Ventanilla App | `banca-ecosistema-bantec-ventanilla-app-512be32e` |
| **Nexus** | |
| Web Client | `banca-ecosistema-nexus-web-client-512be32e` |
| Ventanilla App | `banca-ecosistema-nexus-ventanilla-app-512be32e` |
| **EcuSol** | |
| Web Client | `banca-ecosistema-ecusol-web-client-512be32e` |
| Ventanilla App | `banca-ecosistema-ecusol-ventanilla-app-512be32e` |

---

## 🔧 Configuración del Workflow (Frontend)

### Paso 1: Copia el archivo
Descarga `deploy-to-s3.yml` del repo de infraestructura y cópialo a tu repo en:
```
mi-frontend/
└── .github/
    └── workflows/
        └── deploy.yml      ← Aquí
```

### Paso 2: Edita SOLO esta línea

```yaml
S3_BUCKET: banca-ecosistema-arcbank-web-client-512be32e   # ← Tu bucket (ver tabla arriba)
```

### Paso 3: Configura GitHub Secrets
En tu repositorio → Settings → Secrets → Actions:

| Secret | Valor |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Access Key (pregunta a DevOps) |
| `AWS_SECRET_ACCESS_KEY` | Secret Key (pregunta a DevOps) |

### Paso 4: (Opcional) Configura Variables
En Settings → Variables → Actions:

| Variable | Valor |
|----------|-------|
| `API_URL` | URL del API Gateway (ej: `https://xxx.execute-api.us-east-2.amazonaws.com/dev`) |

---

## 📁 Estructura Esperada del Frontend

```
mi-frontend/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── src/
├── public/
├── package.json
└── (dist/ o build/ se genera automáticamente)
```

El workflow detecta automáticamente si usas:
- **Vite/Vue**: carpeta `dist/`
- **React (CRA)**: carpeta `build/`
- **Next.js export**: carpeta `out/`

---

## ✅ Checklist Frontend

- [ ] Tengo `.github/workflows/deploy.yml`
- [ ] Cambié S3_BUCKET al mío
- [ ] Configuré AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY en GitHub Secrets
- [ ] `npm run build` funciona correctamente
- [ ] Usé variables de entorno para API_URL (no hardcoded)

---

# 🆘 Errores Comunes

| Error | Tipo | Solución |
|-------|------|----------|
| "repository does not exist" | Backend | ECR_REPO mal escrito, usa la tabla |
| "deployment not found" | Backend | DevOps debe crear el deployment inicial en EKS |
| "connection refused" | Backend | Security Group no permite conexión |
| "AccessDenied" | Ambos | AWS Secrets mal configurados |
| "NoSuchBucket" | Frontend | S3_BUCKET mal escrito, usa la tabla |
| "npm run build failed" | Frontend | Revisa que compile local primero |

---

# 📞 Contacto DevOps

Para obtener las credenciales AWS o reportar problemas:
- **Email**: awsproyecto26@gmail.com
- **Repositorio Infra**: [infra-bancaria-terraform](enlace-a-tu-repo)
