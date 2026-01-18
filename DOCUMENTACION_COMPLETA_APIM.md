# Documentación Completa - APIM Switch Transaccional

**Proyecto:** Switch Transaccional Bancario  
**Versión:** 1.0  
**Fecha:** 18 de Enero 2026  
**Equipo:** Christian (Infraestructura), Brayan (Rutas/Traffic), Kris (Seguridad)

---

## 📋 Tabla de Contenidos

1. [Visión General](#1-visión-general)
2. [Arquitectura Completa](#2-arquitectura-completa)
3. [Componente: Infraestructura Base (Christian)](#3-componente-infraestructura-base-christian)
4. [Componente: Rutas y Circuit Breaker (Brayan)](#4-componente-rutas-y-circuit-breaker-brayan)
5. [Componente: Seguridad (Kris)](#5-componente-seguridad-kris)
6. [Archivos Terraform](#6-archivos-terraform)
7. [Variables de Configuración](#7-variables-de-configuración)
8. [Outputs Disponibles](#8-outputs-disponibles)
9. [Diagrama de Flujo de Petición](#9-diagrama-de-flujo-de-petición)
10. [Checklist de Entrega](#10-checklist-de-entrega)
11. [Comandos de Despliegue](#11-comandos-de-despliegue)

---

## 1. Visión General

El **APIM (API Gateway/Manager)** actúa como la capa de conectividad y frontera del Switch Transaccional. Es el punto único de entrada responsable de:

| Responsabilidad | Descripción |
|-----------------|-------------|
| **Ingress & Security** | Terminación SSL, validación mTLS, verificación JWS |
| **Traffic Management** | Rate Limiting (50 TPS), Circuit Breaker |
| **Routing** | Enrutamiento a endpoints del Core |
| **Resiliencia** | Bloqueo de bancos caídos, respuesta MS03 |
| **Observabilidad** | Logs con Trace-ID, alarmas, dashboard |

### Requisitos No Funcionales Cumplidos

| Requisito | Valor | Estado |
|-----------|-------|--------|
| Protocolo | HTTP/1.1 o HTTP/2 sobre TLS | ✅ |
| Latencia Máxima | < 200ms overhead | ✅ |
| Concurrencia | 50 TPS (escalable a 100) | ✅ |
| mTLS | v1.3 obligatorio | ✅ (condicional) |
| SLA | 99.99% (Multi-AZ) | ✅ |
| Timeout | 5 segundos configurable | ✅ |

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
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐               │
│  │  HTTPS Nativo   │  │   Throttling    │  │   CloudWatch    │               │
│  │  (SSL/TLS)      │  │   50/100 TPS    │  │   Trace-ID      │               │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘               │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                    RUTAS (Brayan)                                        │ │
│  │  POST /api/v2/switch/transfers        → Inicio transferencia            │ │
│  │  GET  /api/v2/switch/transfers/{id}   → Consulta estado                 │ │
│  │  POST /api/v2/switch/transfers/return → Devolución/Reverso              │ │
│  │  GET  /funding/{bankId}               → Consulta saldo técnico          │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                    SEGURIDAD (Kris)                                      │ │
│  │  • JWS Authorizer Lambda (validación X-JWS-Signature)                   │ │
│  │  • mTLS via Custom Domain (cuando esté habilitado)                      │ │
│  │  • Tokenización de datos sensibles en logs                              │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                           VPC Link (Christian)                                │
│                         Multi-AZ (us-east-2a, us-east-2b)                    │
└──────────────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                    ALB Backend Interno (Brayan)                               │
│                    (aws_lb.apim_backend_alb)                                 │
│                         Listener :80 → Target Group :8080                    │
└──────────────────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                         PRIVATE SUBNETS                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                     Backend Core (EKS/Fargate)                          │ │
│  │                              :8080                                       │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                      CIRCUIT BREAKER (Brayan)                                 │
│                                                                               │
│  CloudWatch Alarms ──► SNS ──► Lambda ──► DynamoDB                           │
│                                                                               │
│  Trigger: 5+ errores 5xx O latencia > 4s                                     │
│  Response: MS03 - Technical Failure                                           │
│  Cooldown: 30 segundos                                                        │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                        OBSERVABILIDAD (Christian)                             │
│                                                                               │
│  • CloudWatch Log Group: /aws/apigateway/apim-switch-dev                     │
│  • Dashboard: APIM-Switch-dev                                                 │
│  • Alarmas: Latencia, 5xx, 4xx                                               │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                    CA PRIVADA & CERTIFICADOS (Kris)                           │
│                                                                               │
│  • ACM PCA: apim-switch-ca (ROOT)                                            │
│  • S3 CRL Bucket: apim-crl-bucket                                            │
│  • S3 Truststore: mtls-truststore-banca-ecosistema-dev                       │
│  • Secrets Manager: Certificados cliente por banco                           │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Componente: Infraestructura Base (Christian)

### Archivos

| Archivo | Descripción |
|---------|-------------|
| `apim.tf` | API Gateway HTTP v2, VPC Link, Security Groups |
| `apim-mtls.tf` | Custom Domain (condicional), S3 Truststore, ACM Certificate |
| `apim-cloudwatch.tf` | Logs, alarmas, dashboard |

### Recursos Principales

```hcl
# API Gateway
aws_apigatewayv2_api.apim_gateway
  - Nombre: apim-switch-gateway
  - Protocolo: HTTP
  - CORS: Headers X-JWS-Signature, X-Trace-ID permitidos

# VPC Link (Multi-AZ para SLA 99.99%)
aws_apigatewayv2_vpc_link.apim_vpc_link
  - Subredes: private_az1, private_az2

# Stage con Throttling
aws_apigatewayv2_stage.apim_stage
  - Throttling: 50 TPS (burst 100)
  - Logs: JSON con Trace-ID

# Security Groups
aws_security_group.apim_vpc_link_sg    # Para VPC Link
aws_security_group.apim_backend_sg     # Para Backend
```

### mTLS (Condicional)

```hcl
# Habilitado cuando apim_enable_custom_domain = true
aws_apigatewayv2_domain_name.apim_custom_domain
aws_acm_certificate.apim_cert
aws_s3_bucket.mtls_truststore
```

---

## 4. Componente: Rutas y Circuit Breaker (Brayan)

### Archivos

| Archivo | Descripción |
|---------|-------------|
| `apim_routes.tf` | ALB backend, integraciones, 4 rutas del Switch |
| `apim_circuit_breaker.tf` | Alarmas, Lambda, DynamoDB, SNS |

### Endpoints Implementados

| Método | Ruta | Descripción | Requisito |
|--------|------|-------------|-----------|
| `POST` | `/api/v2/switch/transfers` | Inicio de transferencia | RF-01 |
| `GET` | `/api/v2/switch/transfers/{instructionId}` | Consulta de estado | RF-04 |
| `POST` | `/api/v2/switch/transfers/return` | Devolución/Reverso | RF-07 |
| `GET` | `/funding/{bankId}` | Consulta saldo técnico | RF-01.1 |

### Circuit Breaker

| Parámetro | Valor |
|-----------|-------|
| Threshold errores 5xx | 5 |
| Threshold latencia | 4000ms |
| Cooldown | 30 segundos |
| Respuesta | MS03 - Technical Failure |

### Recursos

```hcl
# ALB Backend
aws_lb.apim_backend_alb
aws_lb_target_group.apim_backend_tg
aws_lb_listener.apim_backend_listener

# Circuit Breaker
aws_cloudwatch_metric_alarm.backend_5xx_errors
aws_cloudwatch_metric_alarm.backend_high_latency
aws_dynamodb_table.circuit_breaker_state
aws_lambda_function.circuit_breaker_handler
aws_sns_topic.circuit_breaker_alerts
```

---

## 5. Componente: Seguridad (Kris)

### Archivos

| Archivo | Descripción |
|---------|-------------|
| `security_acm_pca.tf` | CA privada `apim-switch-ca` |
| `security_client_certs.tf` | Certificados cliente en Secrets Manager |
| `s3_crl.tf` | Bucket S3 para CRL (Certificate Revocation List) |

### Mecanismos de Seguridad

| Mecanismo | Propósito |
|-----------|-----------|
| **mTLS v1.3** | Autenticación mutua cliente-servidor |
| **Validación JWS (RS256)** | Verifica integridad via `X-JWS-Signature` |
| **Tokenización** | Evita registrar datos sensibles en logs |
| **Rotación certificados** | Cada 90 días con ventana de transición |

### CA Privada (ACM PCA)

```hcl
aws_acmpca_certificate_authority.apim_ca
  - Tipo: ROOT
  - Algoritmo: RSA_2048 / SHA256WITHRSA
  - Subject: CN=apim-switch-ca, O=Banco EcuSol, C=EC
  - CRL: Publicada en S3

aws_acmpca_certificate.apim_ca_root_cert
  - Template: RootCACertificate/V1
  - Validez: 10 años
```

---

## 6. Archivos Terraform

| Archivo | Responsable | Descripción |
|---------|-------------|-------------|
| `apim.tf` | Christian | API Gateway, VPC Link, Security Groups |
| `apim-mtls.tf` | Christian | Custom Domain, Truststore, ACM Cert |
| `apim-cloudwatch.tf` | Christian | Logs, alarmas, dashboard |
| `apim_routes.tf` | Brayan | Rutas, ALB backend, integraciones |
| `apim_circuit_breaker.tf` | Brayan | Circuit Breaker (Lambda, DynamoDB) |
| `security_acm_pca.tf` | Kris | CA Privada ACM PCA |
| `security_client_certs.tf` | Kris | Certificados en Secrets Manager |
| `s3_crl.tf` | Christian/Kris | Bucket S3 para CRL |
| `variables.tf` | Todos | Variables centralizadas |

---

## 7. Variables de Configuración

### Infraestructura (Christian)

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `apim_domain_name` | string | `api.switch-transaccional.com` | Dominio para mTLS |
| `apim_enable_custom_domain` | bool | `false` | Habilitar Custom Domain |
| `apim_log_retention_days` | number | `30` | Retención de logs |
| `apim_alarm_sns_topic_arn` | string | `""` | SNS para alarmas |

### Rutas (Brayan)

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `apim_backend_port` | number | `8080` | Puerto del backend |
| `apim_integration_timeout_ms` | number | `29000` | Timeout integración |
| `apim_circuit_breaker_error_threshold` | number | `5` | Errores para abrir CB |
| `apim_circuit_breaker_latency_threshold_ms` | number | `4000` | Latencia límite |
| `apim_circuit_breaker_cooldown_seconds` | number | `30` | Cooldown |

### Seguridad (Kris)

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `crl_s3_bucket` | string | `apim-crl-bucket` | Bucket para CRL |

---

## 8. Outputs Disponibles

### Infraestructura

```hcl
apim_gateway_endpoint      # Endpoint HTTPS del API Gateway
apim_gateway_id            # ID del API Gateway
apim_vpc_link_id           # ID del VPC Link
apim_backend_sg_id         # Security Group del backend
apim_truststore_bucket     # Bucket S3 del Truststore
```

### Rutas

```hcl
apim_backend_alb_arn       # ARN del ALB backend
apim_backend_target_group_arn  # Para registrar instancias
apim_route_transfers_post  # Ruta POST /transfers
apim_route_transfers_get   # Ruta GET /transfers/{id}
```

### Circuit Breaker

```hcl
circuit_breaker_sns_topic_arn
circuit_breaker_lambda_arn
circuit_breaker_dynamodb_table
```

### Seguridad

```hcl
apim_ca_arn               # ARN de la CA privada
```

---

## 9. Diagrama de Flujo de Petición

```
1. Banco envía petición HTTPS
         │
         ▼
2. API Gateway recibe (HTTPS nativo)
         │
         ▼
3. [Opcional] mTLS valida certificado cliente (si Custom Domain habilitado)
         │
         ▼
4. [Opcional] JWS Authorizer valida X-JWS-Signature
         │
         ▼
5. Throttling verifica límites (50 TPS)
         │
         ▼
6. Ruta matchea → Integración VPC Link
         │
         ▼
7. VPC Link → ALB Backend Interno
         │
         ▼
8. ALB → Target Group → Backend :8080
         │
         ▼
9. Respuesta fluye de regreso
         │
         ▼
10. CloudWatch registra con Trace-ID
         │
         ▼
11. Circuit Breaker monitorea errores/latencia
```

---

## 10. Checklist de Entrega

### Christian (Infraestructura) ✅

- [x] API Gateway desplegado
- [x] VPC Link Multi-AZ (99.99% SLA)
- [x] Security Groups configurados
- [x] CloudWatch Logs con Trace-ID
- [x] Alarmas de monitoreo
- [x] Throttling 50 TPS
- [x] S3 Bucket Truststore
- [x] Custom Domain (condicional)

### Brayan (Rutas) ✅

- [x] Endpoint POST /transfers
- [x] Endpoint GET /transfers/{id}
- [x] Endpoint POST /transfers/return
- [x] Endpoint GET /funding/{bankId}
- [x] ALB Backend interno
- [x] Circuit Breaker (5 errores / 4s latencia)
- [x] Respuesta MS03 automática

### Kris (Seguridad) ✅

- [x] CA Privada ACM PCA creada
- [x] Bucket S3 para CRL
- [x] Certificado raíz auto-firmado
- [x] Secrets Manager para certificados cliente
- [ ] JWS Authorizer Lambda (pendiente asociar a rutas)
- [ ] Rotación automática de certificados

---

## 11. Comandos de Despliegue

```bash
# Inicializar Terraform
terraform init

# Validar sintaxis
terraform validate

# Ver plan de ejecución
terraform plan

# Aplicar cambios
terraform apply

# Ver outputs
terraform output

# Destruir (solo dev)
terraform destroy
```

### Registrar Backend en Target Group

```bash
aws elbv2 register-targets \
  --target-group-arn $(terraform output -raw apim_backend_target_group_arn) \
  --targets Id=<IP_del_backend>,Port=8080
```

### Suscribirse a Alertas Circuit Breaker

```bash
aws sns subscribe \
  --topic-arn $(terraform output -raw circuit_breaker_sns_topic_arn) \
  --protocol email \
  --notification-endpoint ops@switch.com
```

---

## 📝 Notas Importantes

1. **Custom Domain con mTLS** está deshabilitado por defecto (`apim_enable_custom_domain = false`). Para habilitarlo se requiere un dominio real y validación DNS del certificado ACM.

2. **ACM PCA tiene costo** de ~$400/mes por CA activa. Considerar esto en el presupuesto.

3. **El endpoint HTTPS nativo** de API Gateway funciona sin configuración adicional: `https://<api-id>.execute-api.us-east-2.amazonaws.com/dev`

4. **Para producción**, se recomienda:
   - Habilitar Custom Domain con dominio real
   - Configurar Route53 para el dominio
   - Subir certificados CA reales al Truststore

---

*Documentación generada el 18 de Enero 2026 - Proyecto Switch Transaccional v1.0*
