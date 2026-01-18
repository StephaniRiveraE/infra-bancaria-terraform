# Documentación Completa - APIM Switch Transaccional

**Proyecto:** Switch Transaccional Bancario  
**Versión:** 1.0  
**Fecha:** 18 de Enero 2026  
**Equipo:** Christian (Infraestructura), Brayan (Rutas/Traffic), Kris (Seguridad)

---

## 📋 Tabla de Contenidos

1. [Visión General](#1-visión-general)
2. [Arquitectura Completa](#2-arquitectura-completa)
3. [Componentes por Responsable](#3-componentes-por-responsable)
4. [Archivos Terraform](#4-archivos-terraform)
5. [Variables de Configuración](#5-variables-de-configuración)
6. [Endpoints del API](#6-endpoints-del-api)
7. [Seguridad](#7-seguridad)
8. [Observabilidad](#8-observabilidad)
9. [Costos Estimados](#9-costos-estimados)
10. [Comandos de Despliegue](#10-comandos-de-despliegue)
11. [Checklist de Entrega](#11-checklist-de-entrega)

---

## 1. Visión General

El **APIM (API Gateway/Manager)** es la capa de conectividad del Switch Transaccional:

| Responsabilidad | Implementación |
|-----------------|----------------|
| **HTTPS/SSL** | API Gateway nativo (gratuito) |
| **Traffic Management** | Throttling 50 TPS, Circuit Breaker |
| **Routing** | 4 endpoints del Switch |
| **Resiliencia** | Multi-AZ, respuesta MS03 automática |
| **Observabilidad** | CloudWatch con Trace-ID |
| **Seguridad** | Certificados self-signed (gratuito) |

---

## 2. Arquitectura Completa

```
                            INTERNET
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                         AWS API Gateway HTTP v2                               │
│                         (apim-switch-gateway)                                 │
│                                                                               │
│  • HTTPS nativo (SSL incluido)     • Throttling: 50 TPS (burst 100)          │
│  • CloudWatch Logs + Trace-ID      • CORS habilitado                          │
│                                                                               │
│  RUTAS:                                                                       │
│  ├── POST /api/v2/switch/transfers        → Inicio transferencia             │
│  ├── GET  /api/v2/switch/transfers/{id}   → Consulta estado                  │
│  ├── POST /api/v2/switch/transfers/return → Devolución/Reverso               │
│  └── GET  /funding/{bankId}               → Consulta saldo técnico           │
└──────────────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                    VPC Link (Multi-AZ: us-east-2a, us-east-2b)               │
└──────────────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                    ALB Backend Interno (apim-backend-alb)                     │
│                         Listener :80 → Target Group :8080                    │
└──────────────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                         Backend Core (EKS/Fargate) :8080                      │
└──────────────────────────────────────────────────────────────────────────────┘

     CIRCUIT BREAKER                           OBSERVABILIDAD
┌─────────────────────────┐           ┌─────────────────────────────┐
│ • 5 errores 5xx → OPEN  │           │ • CloudWatch Logs           │
│ • Latencia > 4s → OPEN  │           │ • Dashboard: APIM-Switch    │
│ • Cooldown: 30s         │           │ • Alarmas: Latencia, 5xx    │
│ • Response: MS03        │           │ • Trace-ID en cada request  │
└─────────────────────────┘           └─────────────────────────────┘
```

---

## 3. Componentes por Responsable

### 👤 Christian (Infraestructura Base)

| Recurso | Descripción |
|---------|-------------|
| `aws_apigatewayv2_api` | API Gateway HTTP v2 |
| `aws_apigatewayv2_vpc_link` | VPC Link Multi-AZ |
| `aws_apigatewayv2_stage` | Stage con throttling y logs |
| `aws_security_group` | SGs para VPC Link y Backend |
| `aws_cloudwatch_log_group` | Logs con Trace-ID |
| `aws_cloudwatch_metric_alarm` | Alarmas de monitoreo |
| `aws_cloudwatch_dashboard` | Dashboard visual |
| `aws_s3_bucket` | Truststore para mTLS (opcional) |

### 👤 Brayan (Rutas y Resiliencia)

| Recurso | Descripción |
|---------|-------------|
| `aws_lb` | ALB backend interno |
| `aws_lb_target_group` | Target Group :8080 |
| `aws_lb_listener` | Listener HTTP :80 |
| `aws_apigatewayv2_route` | 4 rutas del Switch |
| `aws_apigatewayv2_integration` | Integraciones VPC Link |
| `aws_lambda_function` | Circuit Breaker handler |
| `aws_dynamodb_table` | Estado del Circuit Breaker |
| `aws_sns_topic` | Alertas Circuit Breaker |

### 👤 Kris (Seguridad)

| Recurso | Descripción |
|---------|-------------|
| `aws_secretsmanager_secret` | Certificados CA (gratuito) |
| Certificados self-signed | `dummy_cert.pem` local |

> **NOTA:** Se eliminó ACM PCA ($400/mes) y se reemplazó por certificados self-signed gratuitos.

---

## 4. Archivos Terraform

| Archivo | Responsable | Descripción |
|---------|-------------|-------------|
| `apim.tf` | Christian | API Gateway, VPC Link, Security Groups |
| `apim-mtls.tf` | Christian | Truststore S3, Custom Domain (opcional) |
| `apim-cloudwatch.tf` | Christian | Logs, alarmas, dashboard |
| `apim_routes.tf` | Brayan | Rutas, ALB, integraciones |
| `apim_circuit_breaker.tf` | Brayan | Circuit Breaker Lambda/DynamoDB |
| `security_acm_pca.tf` | Kris | Certificados en Secrets Manager |
| `security_client_certs.tf` | Kris | Certs cliente por banco |
| `variables.tf` | Todos | Variables centralizadas |

---

## 5. Variables de Configuración

| Variable | Default | Descripción |
|----------|---------|-------------|
| `apim_domain_name` | `api.switch-transaccional.com` | Dominio (si se habilita mTLS) |
| `apim_enable_custom_domain` | `false` | Habilitar Custom Domain |
| `apim_log_retention_days` | `30` | Días de retención de logs |
| `apim_backend_port` | `8080` | Puerto del backend |
| `apim_integration_timeout_ms` | `29000` | Timeout de integración |
| `apim_circuit_breaker_error_threshold` | `5` | Errores para abrir CB |
| `apim_circuit_breaker_cooldown_seconds` | `30` | Cooldown del CB |

---

## 6. Endpoints del API

| Método | Ruta | Descripción | Requisito ERS |
|--------|------|-------------|---------------|
| `POST` | `/api/v2/switch/transfers` | Inicio de transferencia | RF-01 |
| `GET` | `/api/v2/switch/transfers/{instructionId}` | Consulta estado | RF-04 |
| `POST` | `/api/v2/switch/transfers/return` | Devolución/Reverso | RF-07 |
| `GET` | `/funding/{bankId}` | Consulta saldo técnico | RF-01.1 |

**URL Base:** `https://<api-id>.execute-api.us-east-2.amazonaws.com/dev`

---

## 7. Seguridad

### Implementado ✅

| Mecanismo | Implementación |
|-----------|----------------|
| HTTPS/TLS | API Gateway nativo |
| Throttling | 50 TPS (burst 100) |
| CORS | Headers JWS y Trace-ID permitidos |
| Logs seguros | CloudWatch con filtros |

### Opcional (requiere dominio real)

| Mecanismo | Estado |
|-----------|--------|
| mTLS | Deshabilitado (necesita dominio) |
| Custom Domain | Deshabilitado |
| JWS Authorizer | Pendiente conectar a rutas |

### Certificados (Gratuito)

```
dummy_cert.pem              → Certificado self-signed local
aws_secretsmanager_secret   → Almacena certs en AWS (gratis)
aws_s3_bucket.mtls_truststore → Truststore para mTLS (centavos)
```

---

## 8. Observabilidad

### CloudWatch Logs

```
Log Group: /aws/apigateway/apim-switch-dev
Formato: JSON con campos:
  - requestId (Trace-ID)
  - sourceIp
  - httpMethod
  - routeKey
  - status
  - integrationLatency
```

### Alarmas

| Alarma | Threshold | Acción |
|--------|-----------|--------|
| Alta Latencia | > 1000ms | SNS notification |
| Errores 5xx | > 10 en 5min | SNS notification |
| Errores 4xx | > 50 en 5min | SNS notification |

### Dashboard

**Nombre:** `APIM-Switch-dev`

Widgets:
- Request Count
- Latencia P50/P90/P99
- Errores 4xx/5xx
- Integration Latency

---

## 9. Costos Estimados

| Servicio | Costo Mensual |
|----------|---------------|
| API Gateway | ~$3.50/millón requests |
| ALB | ~$16 + tráfico |
| CloudWatch Logs | Tier gratuito (5GB) |
| Secrets Manager | $0.40/secreto |
| Lambda | Tier gratuito |
| DynamoDB | Tier gratuito |
| S3 Truststore | ~$0.02 |
| **TOTAL ESTIMADO** | **~$20-30/mes** |

> ⚠️ **Se eliminó ACM PCA** que costaba $400/mes. No es necesario para proyecto universitario.

---

## 10. Comandos de Despliegue

```bash
# Inicializar
terraform init

# Validar
terraform validate

# Plan
terraform plan

# Aplicar
terraform apply

# Ver outputs
terraform output
```

### Registrar Backend

```bash
aws elbv2 register-targets \
  --target-group-arn $(terraform output -raw apim_backend_target_group_arn) \
  --targets Id=<IP_BACKEND>,Port=8080
```

### Suscribirse a Alertas

```bash
aws sns subscribe \
  --topic-arn $(terraform output -raw circuit_breaker_sns_topic_arn) \
  --protocol email \
  --notification-endpoint tu-email@ejemplo.com
```

---

## 11. Checklist de Entrega

### ✅ Christian (Infraestructura)

- [x] API Gateway desplegado
- [x] VPC Link Multi-AZ
- [x] Security Groups
- [x] CloudWatch Logs con Trace-ID
- [x] Alarmas de monitoreo
- [x] Dashboard
- [x] Throttling 50 TPS
- [x] Truststore S3

### ✅ Brayan (Rutas)

- [x] POST /transfers
- [x] GET /transfers/{id}
- [x] POST /transfers/return
- [x] GET /funding/{bankId}
- [x] ALB Backend
- [x] Circuit Breaker
- [x] Response MS03

### ✅ Kris (Seguridad)

- [x] Certificados self-signed
- [x] Secrets Manager
- [ ] JWS Authorizer (pendiente asociar)

---

*Documentación actualizada: 18 de Enero 2026 - v1.0*
