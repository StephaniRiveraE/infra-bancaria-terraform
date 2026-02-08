# 📚 MANUAL OPERATIVO - Infraestructura Bancaria EKS

**Versión:** 1.0  
**Fecha:** 2026-02-06  
**Autor:** DevOps

---

## 📑 Índice

1. [Resumen de Cambios Realizados](#-resumen-de-cambios-realizados)
2. [Arquitectura del Flujo](#-arquitectura-del-flujo)
3. [Guía DevOps: Primer Despliegue](#-guía-devops-primer-despliegue)
4. [Guía DevOps: Despliegues Posteriores](#-guía-devops-despliegues-posteriores)
5. [Guía Desarrolladores](#-guía-desarrolladores)

---

## 🔧 Resumen de Cambios Realizados

### 1. Actualizado: `deployment-template.yaml`

**¿Qué se hizo?**  
Se agregaron las variables de entorno para que los pods puedan conectarse a la base de datos.

**¿Por qué?**  
Los microservicios Spring Boot necesitan estas variables para conectarse a PostgreSQL:
- `SPRING_DATASOURCE_URL`
- `SPRING_DATASOURCE_USERNAME`
- `SPRING_DATASOURCE_PASSWORD`

**¿Cómo funciona?**  
Las variables se inyectan automáticamente desde los secrets de Kubernetes (`{namespace}-db-credentials`), que se crean con el script de inicialización.

---

### 2. Creado: `scripts/inicializar-eks.sh`

**¿Qué se hizo?**  
Un script unificado que hace TODA la configuración necesaria después de encender EKS.

**¿Por qué?**  
Antes había pasos manuales dispersos. Ahora un solo comando hace todo.

**¿Qué hace el script?**
1. Configura kubectl para conectar al cluster
2. Parcha CoreDNS para que funcione en Fargate
3. Crea los 5 namespaces (arcbank, bantec, nexus, ecusol, switch)
4. Crea los secrets de BD en cada namespace

---

### 3. Corregido: `CHECKLIST_DEVOPS.md`

**¿Qué se hizo?**  
Se reescribió con referencias correctas a los scripts existentes.

**¿Por qué?**  
El anterior mencionaba scripts que no existían (`01-crear-namespaces.sh`, etc.)

---

## 🏗️ Arquitectura del Flujo

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FLUJO COMPLETO                                     │
└─────────────────────────────────────────────────────────────────────────────┘

                    TÚ (DevOps)                    DESARROLLADORES
                    ───────────                    ───────────────
                         │                               │
    ┌────────────────────┼───────────────────────────────┼─────────────────┐
    │ PASO PREVIO (una vez cuando se enciende EKS)       │                 │
    │                    │                               │                 │
    │   1. PR con eks_enabled=true                       │                 │
    │                    │                               │                 │
    │   2. Merge → GitHub Actions → terraform apply      │                 │
    │                    │                               │                 │
    │   3. ./scripts/inicializar-eks.sh                  │                 │
    │                    │                               │                 │
    │   4. Crear deployments iniciales                   │                 │
    │                    │                               │                 │
    └────────────────────┼───────────────────────────────┼─────────────────┘
                         │                               │
                         │    ┌──────────────────────────┘
                         │    │
    ┌────────────────────┼────┼─────────────────────────────────────────────┐
    │ CICLO NORMAL (cada vez que hay cambios de código)  │                 │
    │                    │    │                                             │
    │                    │    ▼                                             │
    │                    │   git push (a su repo)                          │
    │                    │         │                                        │
    │                    │         ▼                                        │
    │                    │   GitHub Actions:                                │
    │                    │   - Build Docker image                          │
    │                    │   - Push a ECR                                  │
    │                    │   - kubectl set image                           │
    │                    │         │                                        │
    │                    │         ▼                                        │
    │                    │   Pod actualizado en EKS                        │
    └────────────────────┼──────────────────────────────────────────────────┘
```

---

## 🟢 Guía DevOps: Primer Despliegue

> **Contexto:** Primera vez que se va a usar EKS, o después de haberlo apagado por costos.

### Paso 1: Encender EKS via PR

```bash
# 1. Crear rama
git checkout main
git pull origin main
git checkout -b feature/encender-eks-$(date +%Y%m%d)

# 2. Editar variables.tf - cambiar eks_enabled a true
# Línea ~107: default = true

# 3. Commit y push
git add variables.tf
git commit -m "feat: encender EKS para pruebas"
git push origin feature/encender-eks-$(date +%Y%m%d)

# 4. Crear Pull Request en GitHub hacia main
# 5. Esperar aprobación y merge
```

📍 **Después del merge:** GitHub Actions ejecutará `terraform apply` automáticamente.  
⏱️ **Tiempo:** 15-20 minutos

### Paso 2: Ejecutar script de inicialización

```bash
# En PowerShell (Windows) o Git Bash
cd c:\proyecto-bancario-devops\scripts

# Si usas Git Bash:
./inicializar-eks.sh

# Si usas PowerShell, primero instala Git Bash o WSL
```

**¿Qué hace el script automáticamente?**
1. ✅ Configura kubectl
2. ✅ Parcha CoreDNS para Fargate
3. ✅ Crea namespaces (arcbank, bantec, nexus, ecusol, switch)
4. ✅ Crea secrets de BD en cada namespace
5. ✅ **Crea los 30 deployments iniciales automáticamente**

⏱️ **Tiempo:** 3-5 minutos

### Paso 3: Verificar

```bash
# Ver todos los deployments creados
kubectl get deployments -A

# Ver pods (estarán en ImagePullBackOff hasta que haya imagen en ECR - esto es normal)
kubectl get pods -A
```

### Paso 4: ✅ Notificar a desarrolladores

Los desarrolladores pueden hacer `git push` a sus repos.

---

## 🔵 Guía DevOps: Despliegues Posteriores

> **Contexto:** EKS ya estaba encendido, solo se apagó temporalmente.

### Si EKS sigue encendido (no hiciste PR para apagarlo):

**No hay que hacer nada.** Los deployments siguen existiendo.

### Si apagaste EKS (eks_enabled=false):

1. Hacer PR para volver a poner `eks_enabled=true`
2. Esperar merge y terraform apply (~15-20 min)
3. Ejecutar `./scripts/inicializar-eks.sh` ✅ (Crea namespaces, secrets Y deployments automáticamente)

```bash
# El script ahora hace TODO automáticamente:
./scripts/inicializar-eks.sh

# ✅ Listo - desarrolladores pueden usar
```

⏱️ **Tiempo total:** ~18-25 minutos (15-20 de terraform + 3-5 del script)

---

## 👨‍💻 Guía Desarrolladores

> **Esta sección es para dar a los equipos de desarrollo**

### Prerequisitos

1. Tener el archivo `deploy-to-eks.yml` en tu repositorio
2. Tener los secrets configurados en GitHub
3. El DevOps debe haber creado tu deployment inicial

### Paso 1: Configurar tu repositorio (una vez)

#### 1.1 Copiar el workflow

Copia el archivo del repo de infraestructura:
```
.github-template/deploy-to-eks.yml
```

A tu repositorio como:
```
.github/workflows/deploy.yml
```

#### 1.2 Modificar las variables

Edita las 3 variables según tu banco y microservicio:

```yaml
env:
  AWS_REGION: us-east-2
  EKS_CLUSTER: eks-banca-ecosistema
  
  # CAMBIAR ESTOS 3:
  NAMESPACE: arcbank              # Tu banco
  ECR_REPO: arcbank-ms-clientes   # Tu repo en ECR
  SERVICE_NAME: ms-clientes       # Tu microservicio
```

#### 1.3 Configurar secrets en GitHub

Ve a tu repo → Settings → Secrets → Actions → New repository secret:

| Secret | Valor |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | (pedir a DevOps) |
| `AWS_SECRET_ACCESS_KEY` | (pedir a DevOps) |

#### 1.4 Tener un Dockerfile

En la raíz de tu proyecto:

```dockerfile
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### 1.5 Usar variables de entorno en tu código

En `application.properties`:

```properties
spring.datasource.url=${SPRING_DATASOURCE_URL}
spring.datasource.username=${SPRING_DATASOURCE_USERNAME}
spring.datasource.password=${SPRING_DATASOURCE_PASSWORD}

# RabbitMQ (si aplica)
spring.rabbitmq.host=${RABBITMQ_HOST:localhost}
spring.rabbitmq.username=${RABBITMQ_USERNAME:guest}
spring.rabbitmq.password=${RABBITMQ_PASSWORD:guest}
```

### Paso 2: Desplegar

```bash
# 1. Hacer cambios en tu código
# 2. Commit
git add .
git commit -m "feat: mi cambio"

# 3. Push a main (o crear PR si tu repo requiere PRs)
git push origin main
```

El pipeline hará automáticamente:
1. ✅ Compilar tu proyecto
2. ✅ Construir imagen Docker
3. ✅ Subir a ECR
4. ✅ Actualizar el pod en EKS

### Paso 3: Verificar

Pide al DevOps que ejecute:
```bash
kubectl get pods -n {tu-namespace}
kubectl logs -n {tu-namespace} {tu-pod}
```

---

## 🆘 Errores Comunes

| Error | Causa | Solución |
|-------|-------|----------|
| "deployment not found" | DevOps no creó el deployment inicial | Pedir a DevOps que lo cree |
| "image not found" | Primera vez, no hay imagen | El primer push la creará |
| "secret not found" | Secrets de BD no existen | DevOps debe ejecutar inicializar-eks.sh |
| "EKS cluster not found" | EKS está apagado | Pedir a DevOps que lo encienda |

---

## 📞 Contactos

- **DevOps:** Stephani Rivera
- **Infraestructura:** Este repositorio (proyecto-bancario-devops)

---

**Fin del Manual**
