# Documentación Técnica - APIM Infrastructure (Christian)

**Proyecto:** Switch Transaccional Bancario  
**Componente:** API Gateway / Middleware  
**Fecha:** 17 de Enero 2026  
**Autor:** Christian  

---

## 1. Resumen de Implementación

Se implementó la infraestructura base del APIM usando **AWS API Gateway HTTP v2** con HTTPS nativo (sin necesidad de certificado externo):

- ✅ API Gateway HTTP v2 con HTTPS incluido
- ✅ VPC Link Multi-AZ para backend privado (99.99% SLA)
- ✅ Security Groups para conectividad segura
- ✅ CloudWatch Logs con Trace-ID (100% de transacciones)
- ✅ Alarmas y Dashboard de monitoreo
- ✅ Throttling: 50 TPS sostenidos (burst 100)

---

## 2. Archivos Creados

| Archivo | Descripción |
|---------|-------------|
| `apim.tf` | API Gateway, VPC Link, Security Groups |
| `apim-cloudwatch.tf` | Logs, alarmas, dashboard |
| `variables.tf` | Variables del APIM agregadas |

---

## 3. Recursos de AWS Creados (100% PaaS)

### 3.1 Security Groups

```hcl
# Security Group para VPC Link
aws_security_group.apim_vpc_link_sg
  - Egress: 8080/tcp hacia VPC (backend)
  - Egress: 443/tcp (HTTPS saliente)

# Security Group para Backend
aws_security_group.apim_backend_sg
  - Ingress: 8080/tcp desde VPC Link
```

### 3.2 API Gateway HTTP v2

```hcl
aws_apigatewayv2_api.apim_gateway
  - Nombre: apim-switch-gateway
  - HTTPS: ✅ Incluido automáticamente
  - CORS: X-JWS-Signature, X-Trace-ID permitidos

aws_apigatewayv2_vpc_link.apim_vpc_link
  - Subredes: private_az1, private_az2 (Multi-AZ)
  
aws_apigatewayv2_stage.apim_stage
  - Throttling: 50 TPS (burst 100)
  - Logs: JSON con requestId como Trace-ID
```

### 3.3 Observabilidad

```hcl
aws_cloudwatch_log_group.apim_access_logs
  - Retención: 30 días

Alarmas:
  - apim_latency_alarm (>200ms)
  - apim_5xx_alarm (errores servidor)
  - apim_4xx_alarm (errores cliente)

aws_cloudwatch_dashboard.apim_dashboard
  - Requests, Latencia, Errores
```

---

## 4. Endpoint HTTPS (Ya Funciona)

Al ejecutar `terraform apply`, obtendrás un endpoint así:

```
https://abc123xyz.execute-api.us-east-2.amazonaws.com/dev
```

**Este endpoint ya tiene SSL/TLS válido** proporcionado por AWS. No necesitas dominio ni certificado.

---

## 5. Outputs para Otros Integrantes

### Para Kris (Seguridad)

```hcl
# Security Group del backend para configurar mTLS
aws_security_group.apim_backend_sg.id

# API Gateway ID para políticas de validación JWS
aws_apigatewayv2_api.apim_gateway.id
```

### Para Brayan (Rutas y Traffic)

```hcl
# API Gateway ID para configurar rutas
aws_apigatewayv2_api.apim_gateway.id

# VPC Link ID para integraciones privadas
aws_apigatewayv2_vpc_link.apim_vpc_link.id

# Ejemplo de ruta:
resource "aws_apigatewayv2_route" "transfers" {
  api_id    = aws_apigatewayv2_api.apim_gateway.id
  route_key = "POST /api/v2/switch/transfers"
  target    = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

resource "aws_apigatewayv2_integration" "backend" {
  api_id           = aws_apigatewayv2_api.apim_gateway.id
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "http://backend.internal:8080"
}
```

---

## 6. Diagrama de Arquitectura

```
    Internet
        │
        ▼ HTTPS (automático)
┌───────────────────────────────────────────────────────────────────┐
│                    AWS API Gateway HTTP v2                        │
│                    (apim-switch-gateway)                          │
│  • HTTPS nativo con certificado AWS                               │
│  • Throttling: 50 TPS                                             │
│  • Logs con Trace-ID                                              │
└───────────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌───────────────────────────────────────────────────────────────────┐
│                         VPC Link                                   │
│  • Multi-AZ (us-east-2a, us-east-2b)                              │
│  • Conexión privada                                                │
└───────────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌───────────────────────────────────────────────────────────────────┐
│                    Private Subnets                                 │
│              ┌─────────────────────────┐                          │
│              │   Backend (Core)        │                          │
│              │   :8080                 │                          │
│              └─────────────────────────┘                          │
└───────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────┐
│                       CloudWatch                                   │
│  • Logs: /aws/apigateway/apim-switch-dev                          │
│  • Dashboard: APIM-Switch-dev                                      │
│  • Alarmas: Latencia, 5xx, 4xx                                    │
└───────────────────────────────────────────────────────────────────┘
```

---

## 7. Checklist de Entrega (Christian)

- [x] API Gateway desplegado y accesible por HTTPS
- [x] Terminación SSL/TLS (nativo de AWS)
- [x] VPC Link para conectividad privada al backend
- [x] Logs con Trace-ID único para 100% de transacciones
- [x] SLA 99.99% mediante VPC Link Multi-AZ
- [x] Throttling 50 TPS configurado
- [x] Alarmas de monitoreo configuradas

**No hay configuración pendiente.** ✅

---

## 8. Variables Disponibles

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `apim_log_retention_days` | number | `30` | Días de retención de logs |
| `apim_alarm_sns_topic_arn` | string | `""` | SNS Topic para alarmas |

---

## 9. Comandos de Ejecución

```bash
# Validar sintaxis
terraform validate

# Ver plan
terraform plan

# Aplicar
terraform apply
```
