# 🚀 Guía para Desarrolladores - Despliegue a AWS

## 📋 Datos que Necesitas

### Tu Banco y Namespace

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

## 🔧 Configuración del Workflow

### Paso 1: Copia el archivo
Copia el archivo `deploy-to-eks.yml` a tu repo en:
```
.github/workflows/deploy.yml
```

### Paso 2: Edita SOLO estas 3 líneas

```yaml
NAMESPACE: arcbank                       # ← Tu banco (ver tabla arriba)
ECR_REPO: arcbank-service-clientes       # ← Tu repo ECR (ver tabla arriba)
SERVICE_NAME: service-clientes           # ← Tu microservicio
```

### Ejemplo para Bantec service-cuentas:
```yaml
NAMESPACE: bantec
ECR_REPO: bantec-service-cuentas
SERVICE_NAME: service-cuentas
```

### Ejemplo para EcuSol ms-transacciones:
```yaml
NAMESPACE: ecusol
ECR_REPO: ecusol-ms-transacciones
SERVICE_NAME: ecusol-ms-transacciones
```

---

## 🗄️ Configuración de Base de Datos

En tu `application.properties`:

```properties
spring.datasource.url=${SPRING_DATASOURCE_URL}
spring.datasource.username=${SPRING_DATASOURCE_USERNAME}
spring.datasource.password=${SPRING_DATASOURCE_PASSWORD}
```

**NO pongas valores hardcodeados**. Kubernetes los inyecta automáticamente.

> ℹ️ Los secrets de BD son creados por DevOps. Solo usa las variables de entorno en tu código.

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

## ✅ Checklist

- [ ] Tengo `Dockerfile` en la raíz
- [ ] Tengo `.github/workflows/deploy.yml`
- [ ] Cambié NAMESPACE, ECR_REPO y SERVICE_NAME
- [ ] Mi código usa variables de entorno para BD
- [ ] El proyecto compila con `mvn clean package`

---

## 🆘 Errores Comunes

| Error | Solución |
|-------|----------|
| "repository does not exist" | ECR_REPO mal escrito, usa la tabla |
| "deployment not found" | DevOps debe crear el deployment inicial |
| "connection refused" | Security Group no permite conexión |
