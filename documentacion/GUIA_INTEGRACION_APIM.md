# Guía de Integración APIM - Switch Transaccional Bancario

> **Última actualización:** 12 de febrero de 2026 (v2.0.0)  
> **Estado de infraestructura:** ✅ Operativa (5/5 microservicios Switch healthy)  
> **Ambiente:** Desarrollo (dev)  
> **Versión APIM:** 2.0.0

---

## Información General

| Campo                 | Valor                                                                                    |
| --------------------- | ---------------------------------------------------------------------------------------- |
| **Base URL del APIM** | `https://gf0js7uezg.execute-api.us-east-2.amazonaws.com/dev`                             |
| **Cognito Token URL** | `https://auth-banca-digiconecu-dev-lhd4go.auth.us-east-2.amazoncognito.com/oauth2/token` |
| **Región AWS**        | `us-east-2` (Ohio)                                                                       |
| **Protocolo**         | HTTPS (TLS 1.2+)                                                                         |
| **Scope OAuth2**      | `https://switch-api.com/transfers.write`                                                 |

---

## 1. Arquitectura del Flujo

### 1.1 Alcance del APIM

⚠️ **IMPORTANTE:** El APIM es **SOLO para operaciones interbancarias**. Las operaciones internas de cada banco NO pasan por el APIM.

**Operaciones que SÍ usan APIM:**

- ✅ Transferencias entre bancos diferentes (ArcBank → Bantec)
- ✅ Devoluciones interbancarias
- ✅ Account lookup en otro banco
- ✅ Consultar directorio de bancos participantes
- ✅ Callbacks de respuesta entre bancos
- ✅ Fondeo de cuentas técnicas
- ✅ Compensación entre bancos

**Operaciones que NO usan APIM (son internas de cada banco):**

- ❌ Transferencias dentro del mismo banco (cliente A → cliente B de ArcBank)
- ❌ CRUD de clientes del banco
- ❌ CRUD de cuentas del banco
- ❌ CRUD de sucursales del banco
- ❌ Depósitos y retiros en ventanilla

### 1.2 Diagrama de Flujo

```
┌──────────────┐                                                    ┌───────────────────┐
│              │  1. POST /oauth2/token                             │                   │
│   Banco      │ ──────────────────────────────────> ┌──────────┐   │   Switch (EKS)    │
│  (Gateway)   │ <────────────── access_token ────── │ Cognito  │   │                   │
│              │                                     └──────────┘   │  ┌─────────────┐  │
│              │  2. POST /api/v2/switch/transfers                  │  │ ms-nucleo   │  │
│              │     Authorization: Bearer <token>                  │  │  :8082      │  │
│              │ ──────────────────────────────────> ┌──────────┐   │  ├─────────────┤  │
│              │                                     │   APIM   │──>│  │ ms-compens. │  │
│              │                                     │  Valida  │   │  │  :8084      │  │
│              │                                     │  JWT +   │   │  ├─────────────┤  │
│              │                                     │  Inyecta │   │  │ ms-contab.  │  │
│              │                                     │  Secret  │   │  │  :8080      │  │
│              │ <────────────── Respuesta ───────── └──────────┘<──│  ├─────────────┤  │
│              │                                         │          │  │ ms-devol.   │  │
└──────────────┘                                     ┌───┴──────┐   │  │  :8085      │  │
                                                     │ ALB Int. │   │  ├─────────────┤  │
                                                     │ (Router) │──>│  │ ms-direct.  │  │
                                                     └──────────┘   │  │  :8081      │  │
                                                                    │  └─────────────┘  │
                                                                    └───────────────────┘
```

**Pasos del flujo:**

1. El banco obtiene un token JWT de Cognito usando `client_credentials`
2. El banco envía el request al APIM con el header `Authorization: Bearer <token>`
3. El APIM valida el JWT con Cognito
4. El APIM inyecta el header `x-origin-secret` (seguridad interna)
5. El APIM rutea al microservicio correcto del Switch vía ALB interno
6. El Switch procesa y responde

---

## 2. Credenciales por Banco

### Bantec

| Campo             | Valor                                  |
| ----------------- | -------------------------------------- |
| **Client ID**     | `7oj12jtu8d3keilv1e1gjkc8e4`           |
| **Client Secret** | Solicitar al equipo de infraestructura |
| **Namespace EKS** | `bantec`                               |

### ArcBank

| Campo             | Valor                                  |
| ----------------- | -------------------------------------- |
| **Client ID**     | `3jprfuk1phejsm0sjr8p50n91e`           |
| **Client Secret** | Solicitar al equipo de infraestructura |
| **Namespace EKS** | `arcbank`                              |

> ⚠️ **IMPORTANTE:** Los Client Secrets se entregan de forma privada al responsable de cada banco. Nunca compartirlos en canales públicos ni repositorios.

---

## 3. Rutas Disponibles del APIM

Todas las rutas (excepto `/health` y directorio público) requieren `Authorization: Bearer <TOKEN>`.

### 3.1 Transferencias Interbancarias (Nucleo)

| Método | Ruta                                       | Descripción                                | Scope Requerido   |
| ------ | ------------------------------------------ | ------------------------------------------ | ----------------- |
| `POST` | `/api/v2/switch/transfers`                 | Iniciar transferencia interbancaria        | `transfers.write` |
| `GET`  | `/api/v2/switch/transfers/{instructionId}` | Consultar estado de transferencia          | JWT válido        |
| `POST` | `/api/v2/switch/account-lookup`            | Buscar cuenta destino en otro banco        | `transfers.write` |
| `POST` | `/api/v2/switch/returns`                   | Solicitar devolución (pacs.004)            | `transfers.write` |
| `GET`  | `/api/v2/switch/health`                    | Health check (público)                     | **Ninguno**       |
| `GET`  | `/api/v2/transfers/health`                 | Alias de compatibilidad → `/switch/health` | **Ninguno**       |

### 3.2 Directorio de Bancos (ms-directorio)

| Método | Ruta                          | Descripción                                | Scope Requerido       |
| ------ | ----------------------------- | ------------------------------------------ | --------------------- |
| `GET`  | `/api/v1/instituciones`       | Listar todos los bancos participantes      | **Ninguno** (público) |
| `GET`  | `/api/v1/red/bancos`          | Alias de compatibilidad → `/instituciones` | **Ninguno** (público) |
| `GET`  | `/api/v1/instituciones/{bic}` | Obtener detalle de banco por BIC           | **Ninguno** (público) |
| `GET`  | `/api/v1/lookup/{bin}`        | Descubrir banco destino por BIN            | **Ninguno** (público) |

### 3.3 Fondeo (ms-contabilidad)

| Método | Ruta                                      | Descripción                        | Scope Requerido   |
| ------ | ----------------------------------------- | ---------------------------------- | ----------------- |
| `POST` | `/api/v1/funding/recharge`                | Recargar fondos en cuenta técnica  | `transfers.write` |
| `GET`  | `/api/v1/funding/available/{bic}/{monto}` | Verificar disponibilidad de fondos | JWT válido        |

### 3.4 Callbacks

| Método | Ruta                                    | Descripción                        | Scope Requerido   |
| ------ | --------------------------------------- | ---------------------------------- | ----------------- |
| `POST` | `/api/v1/transacciones/callback`        | Recibir respuesta de banco destino | `transfers.write` |
| `GET`  | `/api/v1/transacciones/callback/health` | Health check del callback endpoint | **Ninguno**       |

### 3.5 Compensación

| Método | Ruta                          | Descripción                   | Scope Requerido   |
| ------ | ----------------------------- | ----------------------------- | ----------------- |
| `POST` | `/api/v2/compensation/upload` | Subir archivo de compensación | `transfers.write` |
| `GET`  | `/api/v2/compensation/health` | Health check compensación     | **Ninguno**       |

### 3.6 Rutas de Compatibilidad (Legacy)

Estas rutas existen para mantener compatibilidad con clientes legacy. Se recomienda migrar a las rutas principales.

| Ruta Legacy                | Redirige a              | Migrar a                     |
| -------------------------- | ----------------------- | ---------------------------- |
| `/api/v2/transfers/health` | `/api/v2/switch/health` | ✅ Rutas nuevas recomendadas |
| `/api/v1/red/bancos`       | `/api/v1/instituciones` | ✅ Rutas nuevas recomendadas |

> **Nota:** Ambas rutas funcionarán, pero las rutas principales son las recomendadas para nuevas implementaciones.

---

## 4. Instrucciones para los Bancos (Bantec / ArcBank)

### 4.1 Obtener Token JWT

Antes de llamar cualquier ruta protegida, el banco debe obtener un token OAuth2.

**Ejemplo con cURL:**

```bash
curl -X POST \
  "https://auth-banca-digiconecu-dev-lhd4go.auth.us-east-2.amazoncognito.com/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=<TU_CLIENT_ID>" \
  -d "client_secret=<TU_CLIENT_SECRET>" \
  -d "scope=https://switch-api.com/transfers.write"
```

**Respuesta exitosa:**

```json
{
  "access_token": "eyJraWQiOiJ...",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

> El token dura **1 hora**. Implementar lógica de refresh automático.

### 4.2 Configurar Variables de Entorno en Kubernetes

Agregar las siguientes variables al Deployment del `gateway-server` del banco:

```yaml
env:
  - name: COGNITO_TOKEN_URL
    value: "https://auth-banca-digiconecu-dev-lhd4go.auth.us-east-2.amazoncognito.com/oauth2/token"
  - name: COGNITO_CLIENT_ID
    value: "<CLIENT_ID_DEL_BANCO>"
  - name: COGNITO_CLIENT_SECRET
    valueFrom:
      secretKeyRef:
        name: cognito-credentials
        key: client-secret
  - name: APIM_BASE_URL
    value: "https://gf0js7uezg.execute-api.us-east-2.amazonaws.com/dev"
```

**Crear el Secret de Cognito:**

```bash
kubectl create secret generic cognito-credentials \
  --namespace=<NAMESPACE_DEL_BANCO> \
  --from-literal=client-secret="<TU_CLIENT_SECRET>"
```

### 4.3 Implementar TokenManager (Java Spring Boot)

Este componente obtiene y renueva automáticamente el token JWT de Cognito:

```java
@Component
public class TokenManager {

    @Value("${cognito.token-url}")
    private String tokenUrl;

    @Value("${cognito.client-id}")
    private String clientId;

    @Value("${cognito.client-secret}")
    private String clientSecret;

    private String cachedToken;
    private Instant expiresAt = Instant.MIN;

    public synchronized String getToken() {
        if (Instant.now().isAfter(expiresAt.minusSeconds(60))) {
            refreshToken();
        }
        return cachedToken;
    }

    private void refreshToken() {
        RestTemplate rest = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("grant_type", "client_credentials");
        body.add("client_id", clientId);
        body.add("client_secret", clientSecret);
        body.add("scope", "https://switch-api.com/transfers.write");

        ResponseEntity<Map> response = rest.postForEntity(
            tokenUrl, new HttpEntity<>(body, headers), Map.class);

        cachedToken = (String) response.getBody().get("access_token");
        int expiresIn = (Integer) response.getBody().get("expires_in");
        expiresAt = Instant.now().plusSeconds(expiresIn);
    }
}
```

**application.yml del banco:**

```yaml
cognito:
  token-url: ${COGNITO_TOKEN_URL}
  client-id: ${COGNITO_CLIENT_ID}
  client-secret: ${COGNITO_CLIENT_SECRET}

apim:
  base-url: ${APIM_BASE_URL}
```

### 4.4 Cliente HTTP para llamar al Switch

Usar el `TokenManager` anterior para inyectar el Bearer token en cada petición al APIM:

```java
@Service
public class SwitchClient {

    private final WebClient webClient;
    private final TokenManager tokenManager;

    public SwitchClient(TokenManager tokenManager,
                        @Value("${apim.base-url}") String apimBaseUrl) {
        this.tokenManager = tokenManager;
        this.webClient = WebClient.builder()
            .baseUrl(apimBaseUrl)
            .build();
    }

    public Mono<TransferResponse> createTransfer(TransferRequest request) {
        return webClient.post()
            .uri("/api/v2/switch/transfers")
            .header("Authorization", "Bearer " + tokenManager.getToken())
            .header("Content-Type", "application/json")
            .bodyValue(request)
            .retrieve()
            .bodyToMono(TransferResponse.class);
    }

    public Mono<AccountLookupResponse> accountLookup(AccountLookupRequest request) {
        return webClient.post()
            .uri("/api/v2/switch/account-lookup")
            .header("Authorization", "Bearer " + tokenManager.getToken())
            .header("Content-Type", "application/json")
            .bodyValue(request)
            .retrieve()
            .bodyToMono(AccountLookupResponse.class);
    }

    public Mono<TransferStatusResponse> getTransferStatus(String instructionId) {
        return webClient.get()
            .uri("/api/v2/switch/transfers/{id}", instructionId)
            .header("Authorization", "Bearer " + tokenManager.getToken())
            .retrieve()
            .bodyToMono(TransferStatusResponse.class);
    }

    public Mono<List<InstitutionDTO>> listBanks() {
        // Ruta pública, no requiere token
        return webClient.get()
            .uri("/api/v1/instituciones")
            .retrieve()
            .bodyToFlux(InstitutionDTO.class)
            .collectList();
    }

    public Mono<FundingAvailabilityResponse> checkFundsAvailable(String bic, BigDecimal amount) {
        return webClient.get()
            .uri("/api/v1/funding/available/{bic}/{monto}", bic, amount)
            .header("Authorization", "Bearer " + tokenManager.getToken())
            .retrieve()
            .bodyToMono(FundingAvailabilityResponse.class);
    }

    public Mono<Void> sendCallback(CallbackRequest callback) {
        return webClient.post()
            .uri("/api/v1/transacciones/callback")
            .header("Authorization", "Bearer " + tokenManager.getToken())
            .header("Content-Type", "application/json")
            .bodyValue(callback)
            .retrieve()
            .bodyToMono(Void.class);
    }

    public Mono<ReturnResponse> requestReturn(ReturnRequest request) {
        return webClient.post()
            .uri("/api/v2/switch/returns")
            .header("Authorization", "Bearer " + tokenManager.getToken())
            .header("Content-Type", "application/json")
            .bodyValue(request)
            .retrieve()
            .bodyToMono(ReturnResponse.class);
    }
}
```

---

## 5. Instrucciones para el Equipo Switch

### 5.1 Validar el header `x-origin-secret`

El APIM inyecta automáticamente un header `x-origin-secret` en cada request. **Los microservicios del Switch DEBEN validar este header** para asegurar que todo tráfico pase por el APIM.

```java
@Component
public class OriginSecretFilter implements Filter {

    @Value("${apim.origin-secret}")
    private String expectedSecret;

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        String originSecret = httpRequest.getHeader("x-origin-secret");

        if (expectedSecret != null && !expectedSecret.equals(originSecret)) {
            HttpServletResponse httpResponse = (HttpServletResponse) response;
            httpResponse.setStatus(HttpServletResponse.SC_FORBIDDEN);
            httpResponse.getWriter().write("{\"error\":\"Acceso directo no permitido\"}");
            return;
        }
        chain.doFilter(request, response);
    }
}
```

**application.yml:**

```yaml
apim:
  origin-secret: ${APIM_ORIGIN_SECRET}
```

> El valor del secreto `APIM_ORIGIN_SECRET` lo proporciona el equipo de infraestructura.

### 5.2 Health Checks (NO modificar)

El ALB del APIM hace health checks a cada microservicio. Estas rutas **deben responder 200 OK**:

| Microservicio   | Ruta de Health Check        | Puerto |
| --------------- | --------------------------- | ------ |
| ms-nucleo       | `/api/v2/switch/health`     | 8082   |
| ms-compensacion | `/actuator/health/liveness` | 8084   |
| ms-contabilidad | `/actuator/health/liveness` | 8080   |
| ms-devolucion   | `/actuator/health/liveness` | 8085   |
| ms-directorio   | `/actuator/health/liveness` | 8081   |

### 5.3 Puertos Fijos (NO cambiar)

Los puertos están configurados en los Target Groups del ALB. Si un microservicio cambia de puerto, se rompe la conexión con el APIM.

| Microservicio   | Puerto   |
| --------------- | -------- |
| ms-nucleo       | **8082** |
| ms-compensacion | **8084** |
| ms-contabilidad | **8080** |
| ms-devolucion   | **8085** |
| ms-directorio   | **8081** |

---

## 6. Pruebas con cURL

### Paso 1: Obtener token (ejemplo con Bantec)

```bash
TOKEN=$(curl -s -X POST \
  "https://auth-banca-digiconecu-dev-lhd4go.auth.us-east-2.amazoncognito.com/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=7oj12jtu8d3keilv1e1gjkc8e4&client_secret=<SECRET>&scope=https://switch-api.com/transfers.write" \
  | jq -r '.access_token')

echo "Token: $TOKEN"
```

### Paso 2: Verificar health (sin token)

```bash
curl -s https://gf0js7uezg.execute-api.us-east-2.amazonaws.com/dev/api/v2/switch/health
```

### Paso 3: Enviar transferencia

```bash
curl -X POST \
  "https://gf0js7uezg.execute-api.us-east-2.amazonaws.com/dev/api/v2/switch/transfers" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "debtorAccount": "123456789",
    "creditorAccount": "987654321",
    "amount": 100.00,
    "currency": "USD"
  }'
```

### Paso 4: Consultar estado

```bash
curl -X GET \
  "https://gf0js7uezg.execute-api.us-east-2.amazonaws.com/dev/api/v2/switch/transfers/{instructionId}" \
  -H "Authorization: Bearer $TOKEN"
```

### Paso 5: Buscar cuenta en otro banco

```bash
curl -X POST \
  "https://gf0js7uezg.execute-api.us-east-2.amazonaws.com/dev/api/v2/switch/account-lookup" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "accountNumber": "987654321",
    "bankCode": "BANTEC"
  }'
```

### Paso 6: Listar bancos participantes (público, sin token)

```bash
curl -X GET \
  "https://gf0js7uezg.execute-api.us-east-2.amazonaws.com/dev/api/v1/instituciones"
```

Respuesta ejemplo:

```json
[
  {
    "bic": "ARCBECEGXXX",
    "nombre": "ArcBank Ecuador",
    "pais": "EC",
    "cuentaTecnica": { "iban": "...", "saldo": 50000.0 }
  },
  {
    "bic": "BANTECEGXXX",
    "nombre": "Bantec Ecuador",
    "pais": "EC",
    "cuentaTecnica": { "iban": "...", "saldo": 75000.0 }
  }
]
```

### Paso 7: Verificar fondos disponibles

```bash
curl -X GET \
  "https://gf0js7uezg.execute-api.us-east-2.amazonaws.com/dev/api/v1/funding/available/ARCBECEGXXX/5000.00" \
  -H "Authorization: Bearer $TOKEN"
```

Respuesta:

```json
{
  "bic": "ARCBECEGXXX",
  "disponible": true,
  "montoRequerido": 5000.0
}
```

### Paso 8: Enviar callback de banco destino

```bash
curl -X POST \
  "https://gf0js7uezg.execute-api.us-east-2.amazonaws.com/dev/api/v1/transacciones/callback" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "header": {
      "respondingBankId": "ARCBECEGXXX"
    },
    "body": {
      "originalInstructionId": "20230915123456789",
      "status": "COMPLETED"
    }
  }'
```

---

## 7. Códigos de Respuesta

| Código | Significado               | Acción Recomendada                                        |
| ------ | ------------------------- | --------------------------------------------------------- |
| `200`  | OK                        | Request procesado exitosamente                            |
| `401`  | Token inválido o expirado | Renovar token con Cognito (`POST /oauth2/token`)          |
| `403`  | Scope insuficiente        | Verificar que el scope `transfers.write` esté en el token |
| `404`  | Ruta no existe            | Verificar la URL del request                              |
| `500`  | Error interno del Switch  | Reportar al equipo del Switch con el `X-Trace-ID`         |
| `502`  | Backend no disponible     | Pod caído, contactar DevOps                               |
| `504`  | Timeout del backend       | Verificar conectividad, contactar DevOps                  |

---

## 8. Checklist por Equipo

### Bantec

- [ ] Recibir Client Secret de Cognito del equipo de infraestructura
- [ ] Desplegar microservicios en namespace `bantec` en EKS
- [ ] Crear Secret de Cognito en Kubernetes (`cognito-credentials`)
- [ ] Implementar `TokenManager` en el `gateway-server`
- [ ] Implementar `SwitchClient` para llamar al APIM
- [ ] Configurar `APIM_BASE_URL` en variables de entorno
- [ ] Probar obtención de token con cURL
- [ ] Probar llamada a `/api/v2/switch/transfers` con cURL

### ArcBank

- [ ] Recibir Client Secret de Cognito del equipo de infraestructura
- [ ] Crear Secret de Cognito en Kubernetes (`cognito-credentials`)
- [ ] Implementar `TokenManager` en el `gateway-server`
- [ ] Implementar `SwitchClient` para llamar al APIM
- [ ] Configurar `APIM_BASE_URL` en variables de entorno
- [ ] Probar obtención de token con cURL
- [ ] Probar llamada a `/api/v2/switch/transfers` con cURL

### Switch

- [ ] Implementar filtro de validación de `x-origin-secret` en todos los microservicios
- [ ] Obtener valor de `APIM_ORIGIN_SECRET` del equipo de infraestructura
- [ ] Verificar que todos los health checks responden `200 OK`
- [ ] **NO cambiar los puertos** de los microservicios (8080, 8081, 8082, 8084, 8085)

---

## 9. Contacto y Soporte

| Tema                           | Responsable               |
| ------------------------------ | ------------------------- |
| Client Secrets de Cognito      | Equipo de Infraestructura |
| Valor de `x-origin-secret`     | Equipo de Infraestructura |
| Errores en rutas del Switch    | Equipo Switch             |
| Problemas de conectividad APIM | Equipo DevOps             |
| Despliegue en EKS              | Equipo DevOps             |

---

## 10. Changelog APIM v2.0.0

**Fecha:** 12 de febrero de 2026

### ✅ Nuevas Rutas Agregadas

**Directorio de Bancos (ms-directorio):**

- `GET /api/v1/instituciones` - Listar bancos participantes
- `GET /api/v1/instituciones/{bic}` - Detalle de banco por BIC
- `GET /api/v1/lookup/{bin}` - Routing por BIN (descubrir banco destino)

**Fondeo (ms-contabilidad):**

- `POST /api/v1/funding/recharge` - Recargar fondos en cuenta técnica
- `GET /api/v1/funding/available/{bic}/{monto}` - Verificar disponibilidad de fondos

**Callbacks:**

- `POST /api/v1/transacciones/callback` - Recibir respuesta de banco destino
- `GET /api/v1/transacciones/callback/health` - Health check callback

**Compatibilidad:**

- `GET /api/v2/transfers/health` - Alias → `/api/v2/switch/health`
- `GET /api/v1/red/bancos` - Alias → `/api/v1/instituciones`

### 🔧 Rutas Corregidas

- ❌ Eliminada: `POST /api/v2/switch/funding` (path incorrecto)
- ✅ Reemplazada por: `POST /api/v1/funding/recharge` y `GET /api/v1/funding/available/{bic}/{monto}`

### 📊 Rutas Públicas (sin autenticación)

Las siguientes rutas **NO requieren token JWT**:

- `GET /api/v2/switch/health`
- `GET /api/v2/transfers/health`
- `GET /api/v1/instituciones`
- `GET /api/v1/red/bancos`
- `GET /api/v1/instituciones/{bic}`
- `GET /api/v1/lookup/{bin}`
- `GET /api/v1/transacciones/callback/health`
- `GET /api/v2/compensation/health`

---

## 11. Referencias

| Documento                      | Ubicación                                   |
| ------------------------------ | ------------------------------------------- |
| **OpenAPI Spec (APIM v2.0.0)** | [`APIM_OPENAPI.yaml`](../APIM_OPENAPI.yaml) |
| **Rama de cambios**            | `fix/apim-routes-v2`                        |
| **PR pendiente**               | `fix/apim-routes-v2` → `developer` → `main` |

Para obtener la especificación OpenAPI completa y actualizada, consultar el archivo `APIM_OPENAPI.yaml` en el repositorio `infra-bancaria-terraform`.
