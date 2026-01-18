# Documentación Técnica - APIM Routes & Circuit Breaker (Brayan)

**Proyecto:** Switch Transaccional Bancario  
**Componente:** API Routes, Rate Limiting, Circuit Breaker  
**Fecha:** 17 de Enero 2026  
**Autor:** Brayan  

---

## 1. Resumen de Implementación

Se implementó la capa de rutas y resiliencia del APIM usando los recursos base de Christian:

- ✅ 4 endpoints del Switch definidos y enrutados
- ✅ Application Load Balancer interno para VPC Link
- ✅ Circuit Breaker (5 errores 5xx o latencia > 4s)
- ✅ Respuesta MS03 - Technical Failure automática
- ✅ Cooldown de 30 segundos

---

## 2. Archivos Creados

| Archivo | Descripción |
|---------|-------------|
| `apim_routes.tf` | ALB backend, integraciones, 4 rutas del Switch |
| `apim_circuit_breaker.tf` | CloudWatch Alarms, Lambda, DynamoDB, SNS |

---

## 3. Endpoints Implementados (ERS)

| Método | Ruta | Descripción | Requisito |
|--------|------|-------------|-----------|
| `POST` | `/api/v2/switch/transfers` | Inicio de transferencia | RF-01 |
| `GET` | `/api/v2/switch/transfers/{instructionId}` | Consulta de estado | RF-04 |
| `POST` | `/api/v2/switch/transfers/return` | Devolución/Reverso | RF-07 |
| `GET` | `/funding/{bankId}` | Consulta saldo técnico | RF-01.1 |

---

## 4. Recursos de AWS Creados

### 4.1 Application Load Balancer (Backend)

```hcl
aws_lb.apim_backend_alb
  - Tipo: application (internal)
  - Subredes: private_az1, private_az2

aws_lb_target_group.apim_backend_tg
  - Puerto: 8080
  - Health Check: /health

aws_lb_listener.apim_backend_listener
  - Puerto: 80 (HTTP interno)
```

**NOTA:** VPC Link de API Gateway v2 requiere un ALB/NLB listener ARN,
no acepta URLs HTTP directas como `http://backend:8080`.

### 4.2 Integraciones API Gateway

```hcl
aws_apigatewayv2_integration.backend_transfers
aws_apigatewayv2_integration.backend_transfers_get
aws_apigatewayv2_integration.backend_transfers_return
aws_apigatewayv2_integration.backend_funding
  - connection_type: VPC_LINK
  - integration_uri: aws_lb_listener.apim_backend_listener.arn
```

### 4.3 Circuit Breaker

```hcl
# Alarmas CloudWatch
aws_cloudwatch_metric_alarm.backend_5xx_errors
  - Threshold: 5 errores 5xx

aws_cloudwatch_metric_alarm.backend_high_latency
  - Threshold: 4000ms (4 segundos)

# Estado
aws_dynamodb_table.circuit_breaker_state
  - TTL: expires_at (auto-limpieza)

# Handler
aws_lambda_function.circuit_breaker_handler
  - Runtime: Python 3.11
  - Response: MS03 - Technical Failure

# Notificaciones
aws_sns_topic.circuit_breaker_alerts
```

---

## 5. Diagrama de Flujo

```
                         API Gateway HTTP v2
                         (Christian's apim.tf)
                                 │
                                 ▼
┌────────────────────────────────────────────────────────────────┐
│                     RUTAS (Brayan)                             │
│  POST /api/v2/switch/transfers ──────────────┐                 │
│  GET  /api/v2/switch/transfers/{id} ─────────┤                 │
│  POST /api/v2/switch/transfers/return ───────┤                 │
│  GET  /funding/{bankId} ─────────────────────┘                 │
└────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌────────────────────────────────────────────────────────────────┐
│                    VPC Link                                     │
│              (Christian's apim.tf)                              │
└────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌────────────────────────────────────────────────────────────────┐
│              ALB Backend (Brayan)                               │
│  aws_lb.apim_backend_alb                                        │
│  └── Listener :80 ──► Target Group :8080                        │
└────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌────────────────────────────────────────────────────────────────┐
│                    Backend Core                                 │
│                (EKS/Fargate pods)                               │
│                     :8080                                       │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                 CIRCUIT BREAKER (Brayan)                        │
│                                                                 │
│  CloudWatch Alarms ──► SNS ──► Lambda ──► DynamoDB             │
│                                                                 │
│  Trigger: 5+ errores 5xx O latencia > 4s                       │
│  Response: MS03 - Technical Failure                             │
│  Cooldown: 30 segundos                                          │
└────────────────────────────────────────────────────────────────┘
```

---

## 6. Variables Disponibles

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `apim_backend_port` | number | `8080` | Puerto del backend |
| `apim_integration_timeout_ms` | number | `29000` | Timeout (29s max) |
| `apim_circuit_breaker_error_threshold` | number | `5` | Errores para abrir CB |
| `apim_circuit_breaker_latency_threshold_ms` | number | `4000` | Latencia límite |
| `apim_circuit_breaker_cooldown_seconds` | number | `30` | Tiempo enfriamiento |

---

## 7. Outputs Disponibles

```hcl
# ALB
apim_backend_alb_arn
apim_backend_alb_dns
apim_backend_target_group_arn  # Para registrar instancias del backend

# Routes
apim_route_transfers_post
apim_route_transfers_get
apim_route_return
apim_route_funding

# Circuit Breaker
circuit_breaker_sns_topic_arn
circuit_breaker_lambda_arn
circuit_breaker_dynamodb_table
```

---

## 8. Checklist de Entrega (Brayan)

- [x] Endpoints /transfers, /status, /return respondiendo
- [x] Endpoint /funding/{bankId} configurado
- [x] Rate Limiting activo (heredado de Christian - 50/100 TPS)
- [x] Circuit Breaker implementado (5 errores/4s latencia)
- [x] Respuesta MS03 en caso de fallo técnico
- [x] ALB para conexión VPC Link creado

---

## 9. Próximos Pasos

1. **Registrar targets en el Target Group:**
   ```bash
   # Cuando el backend esté desplegado, registrar IPs:
   aws elbv2 register-targets \
     --target-group-arn $(terraform output -raw apim_backend_target_group_arn) \
     --targets Id=<IP_del_backend>,Port=8080
   ```

2. **Suscribirse a alertas del Circuit Breaker:**
   ```bash
   aws sns subscribe \
     --topic-arn $(terraform output -raw circuit_breaker_sns_topic_arn) \
     --protocol email \
     --notification-endpoint ops@switch.com
   ```
