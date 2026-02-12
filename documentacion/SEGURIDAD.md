# 🛡️ Documentación de Seguridad - Infraestructura Bancaria

**Última Actualización:** 2026-02-10  
**Proyecto:** Switch Transaccional + Ecosistema Bancario

Este documento detalla todas las capas de seguridad implementadas en el proyecto, desde la red hasta la capa de aplicación y criptografía.

---

## 📋 Índice

1. [Seguridad de Red (VPC & Security Groups)](#1-seguridad-de-red)
2. [Gestión de Identidad (Cognito & OAuth 2.0)](#2-gestión-de-identidad)
3. [Seguridad en API Gateway](#3-seguridad-en-api-gateway)
4. [Protección de Datos & Criptografía](#4-protección-de-datos--criptografía)
5. [Resiliencia y Protección (Circuit Breaker)](#5-resiliencia-y-protección)
6. [Gestión de Secretos](#6-gestión-de-secretos)

---

## 1. Seguridad de Red

### Aislamiento de Red (VPC)
El ecosistema reside en una **VPC Privada** (`10.0.0.0/16`) con una estricta segmentación:

*   **Subnets Públicas**: Solo para Balanceadores de Carga (ALB) y NAT Gateways.
*   **Subnets Privadas**: Donde residen los microservicios (EKS/Fargate) y bases de datos. **Sin acceso directo a Internet.**

### Security Groups (Firewall Virtual)
Se implementa una estrategia de **Mínimo Privilegio**:

| Security Group | ID / Nombre | Reglas de Entrada (Ingress) | Reglas de Salida (Egress) |
|---|---|---|---|
| **API Gateway VPC Link** | `apim-vpc-link-sg` | N/A (Tráfico interno AWS) | `0.0.0.0/0` (Para alcanzar al ALB interno) |
| **Internal Backend** | `backend-internal-sg` | **Solo desde `apim-vpc-link-sg`** en puertos HTTP | `0.0.0.0/0` |
| **RDS Database** | `rds-bancario-sg` | **Solo puerto 5432** desde la VPC CIDR | Bloqueado |

> **Nota:** El backend es **totalmente inaccesible** desde Internet. Solo el API Gateway puede comunicarse con él a través del VPC Link.

---

## 2. Gestión de Identidad

Se utiliza **Amazon Cognito** como proveedor de identidad (IdP) centralizado para gestionar la autenticación de los bancos conectados.

### User Pool: `banca-ecosistema-pool`
*   **Dominio de Autenticación:** `auth-banca-[proyecto]-[env].auth.us-east-2.amazoncognito.com`
*   **Flujo OAuth 2.0:** `client_credentials` (Machine-to-Machine).
*   **Resource Server:** `https://switch-api.com`

### Clientes y Scopes
Cada banco conectado tiene sus propias credenciales (`ClientId` y `ClientSecret`) y permisos específicos:

| Banco | Cliente Cognito | Scopes Permitidos |
|---|---|---|
| **ArcBank** | `ArcBank-System-Client` | `transfers.write` |
| **Bantec** | `Bantec-System-Client` | `transfers.write` |
| **Nexus** | `Nexus-System-Client` | `transfers.write` |
| **Ecusol** | `Ecusol-System-Client` | `transfers.write` |

---

## 3. Seguridad en API Gateway

El **API Gateway HTTP** actúa como la única puerta de entrada pública, con las siguientes medidas:

### 3.1. Autenticación JWT
Cada petición es interceptada por un Authorizer que valida:
1.  La firma del **Token JWT** (emitido por Cognito).
2.  La vigencia del token (Expiration).
3.  La presencia del scope requerido (`https://switch-api.com/transfers.write`).

**Configuración Terraform:**
```hcl
resource "aws_apigatewayv2_authorizer" "cognito_auth" {
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    audience = [var.cognito_client_ids]
    issuer   = "https://${var.cognito_endpoint}"
  }
}
```

### 3.2. Protección del Backend (Header Injection)
Para evitar que el tráfico interno sea "bypasseado" o falsificado, el API Gateway inyecta un secreto conocido solo por el backend:

*   **Header:** `x-origin-secret`
*   **Valor:** Un string aleatorio de 32 caracteres generado en Terraform y guardado en Secrets Manager.
*   **Validación:** Los microservicios rechazan cualquier petición que no incluya este header con el valor correcto.

---

## 4. Protección de Datos & Criptografía

### Firma Digital (No-Repudio)
Para garantizar la integridad y no-repudio de las transacciones financieras, se implementa firma digital usando **JWS (JSON Web Signature)**.

1.  **Bancos (Origen):** Firman el payload de la transacción con su **Llave Privada**.
2.  **Switch (Destino):** Valida la firma usando la **Llave Pública** del banco (almacenada en AWS Secrets Manager).

### Cifrado en Tránsito
*   **Externo:** TLS 1.2 (HTTPS) obligatorio para conectar al API Gateway.
*   **Interno:** Tráfico dentro de la VPC.

---

## 5. Resiliencia y Protección

Implementamos un patrón **Circuit Breaker** personalizado para proteger al núcleo bancario de sobrecargas o fallos en cascada.

### Componentes
*   **CloudWatch Alarms:** Monitorean errores 5xx y latencia alta (>4s).
*   **SNS Topic:** Recibe notificaciones de alarma.
*   **Lambda:** `switch-circuit-breaker`
*   **DynamoDB:** `switch-circuit-breaker-state`

### Lógica de Protección
1.  Si los errores superan el umbral (default: 5 errores en 1 min):
2.  La Alarma se dispara -> SNS -> Lambda.
3.  La Lambda escribe el estado **OPEN** en DynamoDB.
4.  Cualquier petición subsiguiente es rechazada inmediatamente con error **MS03 (Technical Failure)** sin tocar el backend.
5.  Después del tiempo de enfriamiento (default: 30s), el circuito se cierra automáticamente.

---

## 6. Gestión de Secretos

Todos los datos sensibles se almacenan en **AWS Secrets Manager**, cifrados con KMS:

| Secreto / Ruta | Descripción |
|---|---|
| `switch/internal-api-secret` | Token compartido entre API Gateway y Microservicios |
| `apim/jws/[banco]-public-key` | Llaves públicas RSA para validar firmas de bancos |
| `switch/signing/private-key` | Llave privada del Switch para firmar respuestas |
| `rds-credentials/*` | Credenciales de base de datos (rotadas autom.) |
| `rabbitmq-credentials` | Credenciales del broker de mensajería |

---

**Resumen de Archivos Terraform Relevantes:**
*   `modules/security-certs/cognito_auth.tf`
*   `modules/security-certs/signing_secrets.tf`
*   `modules/api-gateway/apim_routes.tf`
*   `modules/api-gateway/apim_circuit_breaker.tf`
*   `modules/networking/security.tf`
