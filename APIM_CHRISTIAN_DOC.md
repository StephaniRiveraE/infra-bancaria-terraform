# Documentación Técnica - APIM Infrastructure (Christian)

**Proyecto:** Switch Transaccional Bancario  
**Componente:** API Gateway / Middleware  
**Fecha:** 17 de Enero 2026  
**Autor:** Christian  

---

## 1. Resumen de Implementación

Se implementó la infraestructura completa del APIM incluyendo soporte para **mTLS** (Mutual TLS):

- ✅ API Gateway HTTP v2
- ✅ VPC Link Multi-AZ para backend privado (99.99% SLA)
- ✅ Security Groups para conectividad segura
- ✅ **Custom Domain con mTLS habilitado** (
- ✅ **S3 Bucket Truststore** 
- ✅ **ACM Certificate**
- ✅ CloudWatch Logs con Trace-ID (100% de transacciones)
- ✅ Alarmas y Dashboard de monitoreo
- ✅ Throttling: 50 TPS (burst 100)
- ✅ Timeout configurable (5 segundos por defecto)

---

## 2. Archivos Creados

| Archivo | Descripción |
|---------|-------------|
| `apim.tf` | API Gateway, VPC Link, Security Groups |
| `apim-mtls.tf` | Custom Domain, S3 Truststore, ACM Certificate |
| `apim-cloudwatch.tf` | Logs, alarmas, dashboard |
| `variables.tf` | Variables del APIM |

---

## 3. Arquitectura mTLS

```
    Banco Participante
         │
         │ mTLS (certificado del banco)
         ▼
┌─────────────────────────────────────────────────────────────┐
│           Custom Domain (api.switch-transaccional.com)       │
│                                                              │
│  • ACM Certificate (servidor)                                │
│  • Truststore S3 (validar certificados de bancos)           │
│  • mutual_tls_authentication ENABLED                         │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    API Gateway HTTP v2                       │
│                    (apim-switch-gateway)                     │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                       VPC Link                               │
│                    (Multi-AZ)                                │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backend (Core)                            │
│                      :8080                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Configuración Requerida

### 4.1 Validar Certificado ACM

El certificado ACM requiere validación DNS. Después de ejecutar `terraform apply`:

1. Revisar output `apim_certificate_validation_options`
2. Crear registro CNAME en tu DNS con esos valores
3. Esperar validación (puede tomar unos minutos)

### 4.2 Configurar Dominio (si tienes Route53)

```hcl
resource "aws_route53_record" "apim" {
  zone_id = "TU_ZONE_ID"
  name    = "api.switch-transaccional.com"
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.apim_custom_domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.apim_custom_domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
```

---

## 5. Outputs para Otros Integrantes

### Para Kris (Seguridad / mTLS)

```hcl
# Bucket donde subir el truststore.pem con certificados CA de bancos
aws_s3_bucket.mtls_truststore.id
# Output: apim_truststore_bucket

# URI del truststore para referencia
# Output: apim_truststore_uri = "s3://mtls-truststore-.../truststore.pem"

# Security Group del backend
aws_security_group.apim_backend_sg.id

# API Gateway ID para políticas JWS
aws_apigatewayv2_api.apim_gateway.id
```

**Instrucciones para Kris:**
1. Subir archivo `truststore.pem` al bucket S3: `mtls-truststore-banca-ecosistema-dev`
2. El archivo debe contener los certificados CA de todos los bancos participantes en formato PEM
3. **IMPORTANTE - Actualizar versión del truststore:**
   - **Opción A (Recomendada):** Pasar el archivo a Christian para incluirlo en Terraform y hacer `terraform apply`
   - **Opción B (Manual):** Subir a S3 y luego ir a API Gateway → Custom Domains → Editar → Actualizar Truststore Version

### Para Brayan (Rutas y Traffic)

```hcl
# API Gateway ID para configurar rutas
aws_apigatewayv2_api.apim_gateway.id

# VPC Link ID para integraciones privadas
aws_apigatewayv2_vpc_link.apim_vpc_link.id

# Timeout de integración (usar esta variable)
var.apim_integration_timeout_ms  # Default: 5000ms
```

**Ejemplo de integración con timeout:**
```hcl
resource "aws_apigatewayv2_integration" "backend" {
  api_id             = aws_apigatewayv2_api.apim_gateway.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = "http://backend.internal:8080"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.apim_vpc_link.id
  timeout_milliseconds = var.apim_integration_timeout_ms  # 5000ms
}
```

---

## 6. Variables Disponibles

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `apim_domain_name` | string | `api.switch-transaccional.com` | Dominio para mTLS |
| `apim_integration_timeout_ms` | number | `5000` | Timeout de integración (ms) |
| `apim_log_retention_days` | number | `30` | Retención de logs |
| `apim_alarm_sns_topic_arn` | string | `""` | SNS para alarmas |

---

## 7. Checklist de Entrega (Christian)

- [x] API Gateway desplegado
- [x] VPC Link Multi-AZ (99.99% SLA)
- [x] Security Groups configurados
- [x] CloudWatch Logs con Trace-ID
- [x] Alarmas de monitoreo
- [x] Throttling 50 TPS
- [x] **Custom Domain para mTLS**
- [x] **S3 Bucket Truststore para certificados CA**
- [x] **ACM Certificate para dominio**
- [x] **Variable de timeout configurable (5s)**

---

## 8. Pendientes para el Equipo

| Pendiente | Responsable |
|-----------|-------------|
| Validar certificado ACM (DNS) | Christian/DevOps |
| Subir certificados CA al Truststore | Kris |
| Configurar rutas /transfers, /status, /return | Brayan |
| Configurar validación JWS | Kris |
