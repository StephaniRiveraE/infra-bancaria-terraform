# Guía de API Management (APIM) - AWS API Gateway

Documentación del API Gateway centralizado para el ecosistema bancario DigiConecu.

---

## 📋 Resumen de la Arquitectura

```
                    ┌─────────────────────────────────────┐
                    │         AWS API Gateway             │
                    │    ecosistema-bancario-api          │
                    └─────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │           │           │           │           │       │
        ▼           ▼           ▼           ▼           ▼       ▼
   /arcbank    /bantec     /nexus     /ecusol     /switch
   (3 eps)     (3 eps)     (3 eps)    (3 eps)     (3 eps)
```

Cada banco tiene:
- **API Key única** para autenticación
- **Usage Plan** con quotas y rate limits
- **3 endpoints** (placeholders para configurar)

---

## 🔑 Autenticación con API Keys

Cada request debe incluir el header `x-api-key`:

```bash
curl -X POST https://{api-id}.execute-api.us-east-2.amazonaws.com/prod/arcbank/endpoint1 \
  -H "x-api-key: abc123xyz789..."
```

### Obtener la API Key de un banco

Después del deploy, ejecutar:

```bash
# Listar API Keys
aws apigateway get-api-keys --query "items[*].{Name:name,Id:id}"

# Obtener el valor de una API Key específica
aws apigateway get-api-key --api-key <API_KEY_ID> --include-value
```

---

## 📊 Endpoints Disponibles

### Bancos (ARCBANK, BANTEC, NEXUS, ECUSOL)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/{banco}/endpoint1` | Placeholder - Por definir |
| POST | `/{banco}/endpoint2` | Placeholder - Por definir |
| POST | `/{banco}/endpoint3` | Placeholder - Por definir |

### Switch

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/switch/transferencia` | Solicitar transferencia interbancaria |
| GET | `/switch/status` | Consultar estado de transacción |
| POST | `/switch/validar` | Validar cuenta destino |

---

## 📈 Usage Plans y Facturación

Cada banco tiene un Usage Plan configurado:

| Banco | Rate Limit | Burst | Quota Mensual |
|-------|------------|-------|---------------|
| ARCBANK | 100 req/s | 200 | 100,000 |
| BANTEC | 100 req/s | 200 | 100,000 |
| NEXUS | 50 req/s | 100 | 50,000 |
| ECUSOL | 100 req/s | 200 | 100,000 |
| Switch | 200 req/s | 500 | 500,000 |

### Consultar uso de un banco

```bash
aws apigateway get-usage \
  --usage-plan-id <USAGE_PLAN_ID> \
  --start-date 2026-01-01 \
  --end-date 2026-01-31
```

---

## 📊 Monitoreo - CloudWatch Dashboard

Después del deploy, acceder al dashboard:

```
AWS Console → CloudWatch → Dashboards → API-Gateway-Uso-Por-Banco
```

El dashboard incluye:
- 📈 Requests por banco
- 🔄 Transacciones del Switch
- ⚠️ Errores 4XX/5XX
- ⏱️ Latencia

### Alarmas Configuradas

| Alarma | Condición |
|--------|-----------|
| 5XX Errors | > 10 errores en 5 min |
| High Latency | > 5 segundos promedio |

---

## 🔧 Configurar Endpoints Reales

Para conectar un endpoint a tu servicio real en EKS:

1. **Crear VPC Link** (una sola vez):
```hcl
resource "aws_api_gateway_vpc_link" "eks" {
  name        = "vpc-link-eks"
  target_arns = [aws_lb.internal.arn]
}
```

2. **Cambiar integración de MOCK a HTTP_PROXY**:
```hcl
resource "aws_api_gateway_integration" "ejemplo" {
  type                    = "HTTP_PROXY"
  integration_http_method = "POST"
  uri                     = "http://arcbank-service.arcbank.svc.cluster.local/api/v1/endpoint"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.eks.id
}
```

---

## 📁 Estructura del Módulo

```
api_gateway/
├── variables.tf      # Configuración de bancos y quotas
├── main.tf           # REST API + Resources + Métodos
├── deployment.tf     # Stage prod + Logging
├── usage_plans.tf    # API Keys + Usage Plans
├── monitoring.tf     # Dashboard CloudWatch + Alarmas
└── outputs.tf        # URLs y referencias
```

---

## 🚀 Outputs Importantes

Después del deploy, Terraform mostrará:

| Output | Descripción |
|--------|-------------|
| `api_gateway_invoke_url` | URL base del API |
| `api_gateway_endpoints_por_banco` | URLs por banco |
| `api_gateway_dashboard` | URL del dashboard CloudWatch |

---

## ❓ FAQ

### ¿Cómo agrego un nuevo banco?

Editar `api_gateway.tf` y agregar en el map `banks`:

```hcl
nuevo_banco = {
  name         = "NUEVO_BANCO"
  description  = "API para NUEVO_BANCO"
  rate_limit   = 100
  burst_limit  = 200
  quota_limit  = 100000
  quota_period = "MONTH"
}
```

### ¿Cómo cambio los límites de un banco?

Modificar los valores en el map `banks` de `api_gateway.tf`:

```hcl
arcbank = {
  ...
  quota_limit = 200000  # Cambiar de 100k a 200k
  ...
}
```

### ¿Cómo veo cuánto ha consumido cada banco?

1. Ir a AWS Console → API Gateway → Usage Plans
2. Seleccionar el plan del banco
3. Ver gráfica de uso

O usar el dashboard de CloudWatch.
