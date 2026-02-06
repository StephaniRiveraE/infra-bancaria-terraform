# Instrucciones de Seguridad para Bancos

En cumplimiento con la normativa de seguridad (**RNF-SEC-02** y **RNF-SEC-04**), los bancos participantes deben proveer los siguientes artefactos criptográficos para la integración con el Switch Transaccional DIGICONECU.

---

## 1. Llave Pública para Validación de Firmas (RNF-SEC-02/04)

**Requerimiento:** Llave Pública RSA para validar el header `X-JWS-Signature` en sus peticiones.

- **Algoritmo:** RSA 2048 (RS256)
- **Formato de Entrega:** `public_key.pem` (Formato PEM estándar)

### Cómo Generar

```bash
# 1. Generar llave privada (GUARDAR EN SECRETO)
openssl genrsa -out banco_private_key.pem 2048

# 2. Extraer llave pública (ENVIAR AL SWITCH)
openssl rsa -in banco_private_key.pem -pubout -out banco_public_key.pem
```

**Enviar:** `banco_public_key.pem` a `security@digiconecu.com`

---

## 2. Lo que Recibirán del Switch

Para validar que las respuestas del Switch son auténticas (RNF-SEC-04) y para autenticarse, cada banco recibirá:

### Credenciales OAuth 2.0 (Cognito)
- **Client ID:** Identificador único del banco
- **Client Secret:** Secret para obtener JWT tokens
- **Token Endpoint:** URL para obtener access tokens
- **Scope:** `https://switch-api.com/transfers.write`

### API Key
- **X-API-Key:** API Key única para validación en API Gateway

### Llave Pública del Switch
- **Archivo:** `switch_public_key.pem`
- **Propósito:** Validar firmas digitales en respuestas del Switch

### Endpoints
- **API Gateway:** URL del API Gateway
- **Ruta:** `POST /api/v2/switch/transfers`

---

## 3. Resumen de Entregables

### Lo que el Banco envía al Switch

| Archivo | Propósito |
| :--- | :--- |
| `banco_public_key.pem` | Validación de Firmas JWS (Integridad) |
| `ips_origen.txt` | Whitelisting de Firewall (Opcional) |

### Lo que el Switch envía al Banco

| Credencial | Propósito |
| :--- | :--- |
| Client ID | Autenticación OAuth 2.0 |
| Client Secret | Autent icación OAuth 2.0 |
| API Key | Autorización en API Gateway |
| `switch_public_key.pem` | Validar firmas del Switch |
| Token Endpoint URL | Obtener JWT tokens |
| API Gateway URL | Endpoint de transacciones |

---

## 4. Capas de Seguridad

El Switch implementa las siguientes capas de seguridad:

1. **TLS 1.2+:** Cifrado en tránsito (HTTPS)
2. **OAuth 2.0 JWT:** Autenticación con tokens
3. **API Key:** Autorización y rate limiting
4. **JWS Signature:** Firma digital bidireccional (integridad)
5. **Network Isolation:** Security Groups y VPC privada

---

## 5. Contacto

- **Email:** security@digiconecu.com
- **Soporte Técnico:** support@digiconecu.com
- **Horario:** 24/7
