# 🐰 Sistema de Colas - RabbitMQ

## 📋 Resumen

Se implementó un servidor de colas **RabbitMQ** en AWS (Amazon MQ) para la comunicación asíncrona entre los bancos del ecosistema.

---

## 🔗 Credenciales de Acceso

| Dato | Valor |
|------|-------|
| **Consola Web** | `https://b-455e546c-be71-4fe2-ba0f-bd3112e6c220.mq.us-east-2.on.aws/` |
| **Endpoint AMQPS** | `amqps://b-455e546c-be71-4fe2-ba0f-bd3112e6c220.mq.us-east-2.on.aws:5671` |
| **Usuario** | `mqadmin` |
| **Contraseña** | Buscar en AWS Secrets Manager → `rabbitmq-credentials` |

> ⚠️ **No compartir estas credenciales públicamente.**

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AWS (us-east-2)                              │
│                                                                     │
│   ┌─────────────────────────────────────────────────────────────┐  │
│   │              Amazon MQ (RabbitMQ)                           │  │
│   │              switch-rabbitmq                                │  │
│   │                                                             │  │
│   │   Colas a crear por los devs:                               │  │
│   │   ├── q.bank.NEXUS.in                                       │  │
│   │   ├── q.bank.BANTEC.in                                      │  │
│   │   ├── q.bank.ARCBANK.in                                     │  │
│   │   └── q.bank.ECUSOL.in                                      │  │
│   └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
         ↑                    ↑                    ↑
         │                    │                    │
    ┌────┴────┐          ┌────┴────┐          ┌────┴────┐
    │ BANTEC  │          │ SWITCH  │          │  NEXUS  │
    │ (Google)│          │ (Google)│          │  (AWS)  │
    └─────────┘          └─────────┘          └─────────┘
```

---

## 🔄 Flujo de Transferencias (Ida y Vuelta)

### Camino de IDA (RabbitMQ)

1. **Banco Origen** envía transferencia al **Switch**
2. **Switch** procesa y publica mensaje en la cola del **Banco Destino** (`q.bank.NEXUS.in`)
3. **Banco Destino** consume el mensaje y procesa el depósito

### Camino de VUELTA (Webhook)

4. **Banco Destino** hace HTTP POST al endpoint del **Banco Origen** con el resultado
5. **Banco Origen** recibe confirmación y actualiza estado de la transferencia

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│ BANCO ORIGEN │         │    SWITCH    │         │ BANCO DESTINO│
│   (Nexus)    │         │  DIGICONECU  │         │   (Bantec)   │
└──────┬───────┘         └──────┬───────┘         └──────┬───────┘
       │                        │                        │
       │ 1. Envía transferencia │                        │
       │───────────────────────>│                        │
       │                        │                        │
       │                        │ 2. Publica en          │
       │                        │    q.bank.BANTEC.in    │
       │                        │───────────────────────>│
       │                        │                        │
       │                        │        3. Procesa      │
       │                        │           depósito     │
       │                        │                        │
       │<───────────────────────────────────────────────│
       │        4. Webhook (HTTP POST) con resultado    │
       │                                                 │
```

---

## 👨‍💻 Qué Deben Hacer los Programadores

### 1. Crear las Colas

Desde la consola web de RabbitMQ o desde código, crear las colas:

| Cola | Banco |
|------|-------|
| `q.bank.NEXUS.in` | Nexus |
| `q.bank.BANTEC.in` | Bantec |
| `q.bank.ARCBANK.in` | ArcBank |
| `q.bank.ECUSOL.in` | Ecusol |

### 2. Configurar Conexión en Spring Boot

```yaml
# application.yml
spring:
  rabbitmq:
    host: b-455e546c-be71-4fe2-ba0f-bd3112e6c220.mq.us-east-2.on.aws
    port: 5671
    username: mqadmin
    password: ${RABBITMQ_PASSWORD}  # Usar variable de entorno
    ssl:
      enabled: true
```

### 3. Crear Endpoint de Webhook (Banco Origen)

Cada banco debe tener un endpoint para recibir confirmaciones:

```java
@PostMapping("/api/bancaweb/v1/confirmacion-transferencia")
public ResponseEntity<?> recibirConfirmacion(@RequestBody ConfirmacionDTO confirmacion) {
    // Actualizar estado de la transferencia
    return ResponseEntity.ok().build();
}
```

### 4. Enviar Webhook (Banco Destino)

Al procesar una transferencia, el banco destino notifica al origen:

```java
// Después de procesar el depósito
restTemplate.postForEntity(
    urlBancoOrigen + "/api/bancaweb/v1/confirmacion-transferencia",
    new ConfirmacionDTO(transaccionId, "COMPLETADO"),
    Void.class
);
```

---

## 🔧 Configuración de Reintentos (Recomendada)

| Intento | Delay |
|---------|-------|
| 1 | Inmediato |
| 2 | 800 ms |
| 3 | 2 segundos |
| 4 | 4 segundos |
| DLQ | Después de 4 fallos |

Crear una Dead Letter Queue para mensajes fallidos:
- `q.bank.NEXUS.dlq`
- `q.bank.BANTEC.dlq`
- etc.

---

## 📊 Monitoreo

Acceder a la consola web de RabbitMQ para:
- Ver mensajes en cola
- Revisar Dead Letter Queues
- Administrar usuarios y permisos

---

## 💰 Costos

| Recurso | Costo Mensual |
|---------|---------------|
| Amazon MQ (mq.t3.micro) | ~$25 USD |



> **Documento generado:** 2026-01-27  
> **Infraestructura:** Amazon MQ (RabbitMQ 3.13)  
> **Región:** us-east-2
