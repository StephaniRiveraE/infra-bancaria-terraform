# Documentación Técnica e Implementación del APIM - Middleware Switch Transaccional
**Versión del Documento:** 1.0 (Basado en ERS v1.1)
**Proyecto:** Switch Transaccional
**Tecnología:** Terraform (IaC)

---

## 1. Visión General del Componente
[cite_start]El API Gateway/Manager (APIM) actúa como la **Capa de Conectividad** y frontera del sistema[cite: 38]. [cite_start]Es el punto único de entrada responsable de proteger el núcleo del Switch, gestionar la seguridad perimetral y balancear la carga hacia los servicios internos.

### Responsabilidades Clave
1.  [cite_start]**Ingress & Security:** Terminación SSL, validación mTLS y verificación de firmas digitales[cite: 64, 71].
2.  [cite_start]**Traffic Management:** Rate Limiting (Anti-DDoS) y Balanceo de Carga.
3.  [cite_start]**Routing:** Enrutamiento de peticiones a los endpoints del Core[cite: 17].
4.  [cite_start]**Resiliencia:** Aplicación de políticas de Circuit Breaker (bloqueo de bancos caídos)[cite: 446].

---

## 2. Especificaciones Técnicas (Requisitos No Funcionales)

### 2.1 Conectividad y Protocolos
* [cite_start]**Protocolo:** HTTP/1.1 o HTTP/2 sobre TLS[cite: 254].
* [cite_start]**Encoding:** UTF-8[cite: 256].
* [cite_start]**Formato de Fecha:** ISO 8601 UTC (`YYYY-MM-DDThh:mm:ssZ`)[cite: 257, 259].
* [cite_start]**Latencia Máxima (Overhead):** < 200ms añadidos por el APIM[cite: 469].
* [cite_start]**Concurrencia:** Soporte mínimo de 50 TPS sostenidos (escalable a 100 TPS)[cite: 408, 468].

### 2.2 Seguridad (Crítico)
* **Transporte (mTLS):**
    * [cite_start]Uso obligatorio de **mTLS v1.3**[cite: 410].
    * [cite_start]Validación de certificados de cliente (Bancos Participantes) contra una CA autorizada[cite: 73].
    * [cite_start]Soporte para rotación de certificados cada 90 días (debe aceptar certificado "viejo" y "nuevo" durante transición)[cite: 434, 441].
* **Integridad (Firmas):**
    * [cite_start]Validación del header `X-JWS-Signature` en cada petición[cite: 258].
    * [cite_start]Algoritmo: **JWS - RS256**[cite: 426].
    * [cite_start]El APIM debe obtener la llave pública del banco desde un Key Vault y rechazar la petición si la firma no coincide[cite: 75, 76].
* [cite_start]**Tokenización:** No loguear ni guardar números de cuenta en texto plano[cite: 412].

---

## 3. Definición de Endpoints (Rutas)
[cite_start]El APIM debe exponer y enrutar las siguientes APIs definidas en el contrato[cite: 265, 334, 383]:

| Método | Ruta Pública (Frontend) | Descripción | Requisito |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v2/switch/transfers` | Inicio de transferencia de crédito | RF-01 |
| `GET` | `/api/v2/switch/transfers/{instructionId}` | Consulta de estado (Recovery) | RF-04 |
| `POST` | `/api/v2/switch/transfers/return` | Devolución / Reverso de operación | RF-07 |
| `GET` | `/funding/{bankId}` | (Opcional) Consulta de saldo técnico | RF-01.1 |

---

## 4. Estrategia de Terraform
La infraestructura se desplegará mediante módulos para mantener la separación de responsabilidades.

**Estructura sugerida de carpetas:**
```text
/terraform
  /modules
    /apim-instance    # (Christian) Despliegue del recurso base, VNET, Logs
    /security         # (Kris) Políticas mTLS, KeyVault links, JWS policies
    /apis             # (Brayan) Definición de rutas, upstreams, rate-limits
  /env
    /dev
    /prod
    5. Distribución de Tareas del Equipo
👷‍♂️ Christian: Infraestructura Base & Networking
Objetivo: Levantar el "cascarón" del APIM y asegurar que sea robusto y observable.

Despliegue del Recurso APIM:

Crear el recurso de API Gateway mediante Terraform.

Configurar el Load Balancer de entrada.

Configurar la terminación SSL/TLS con el certificado del dominio del Switch.

Networking:

Asegurar que el APIM esté en una subred pública (o DMZ) y tenga conectividad privada hacia el Backend (Core).

Observabilidad:

Configurar el envío de logs a la herramienta de monitoreo.

Asegurar que se registre el Trace-ID único para el 100% de las transacciones.

Disponibilidad:

Configurar el SLA de "Four nines" (99.99%) mediante redundancia de zonas si el proveedor cloud lo permite.

🕵️‍♂️ Kris: Seguridad Avanzada (Security Handler)
Objetivo: Implementar las barreras de seguridad. Nada entra al Core si Kris no lo valida.

Política de mTLS:

Configurar la exigencia de certificados de cliente en el listener del Gateway.
+1

Implementar la lógica de validación de CA (Certificate Authority).

Política de Validación JWS (Firma Digital):

Crear la política (XML/Lua/Code) que intercepte el body y el header X-JWS-Signature.

Integrar el APIM con el Key Vault para leer dinámicamente la llave pública del originatingBankId que viene en el header.


Acción: Si la firma falla, retornar 4xx inmediato sin contactar al backend.

Gestión de Secretos:

Asegurar que las llaves privadas del Switch (para firmar respuestas) estén seguras en el HSM/Vault.

🚦 Brayan: Gestión de Tráfico y Lógica de API
Objetivo: Configurar el "guarda de tráfico" y las rutas inteligentes.

Definición de APIs (Routing):

Configurar en Terraform las rutas /transfers, /transfers/{id} y /return apuntando al backend correcto.

Asegurar la traducción de URLs si es necesario.

Rate Limiting (Anti-DDoS):

Implementar políticas de límite de tasa (ej. X peticiones por segundo por IP/Banco) para proteger el sistema.

Circuit Breaker (Lógica de Bloqueo):

Implementar la regla: Si un destino devuelve errores 5xx consecutivos (5 veces) o latencia > 4s, el APIM debe dejar de enviar tráfico y responder MS03 - Technical Failure inmediatamente.
+2

Configurar el tiempo de "enfriamiento" (30 segundos) antes de intentar de nuevo.

Validación de Esquema (Básica):

(Opcional en APIM, obligatorio en Core) Validar que el JSON entrante tenga los campos obligatorios antes de enviarlo al backend.

6. Checklist de Entrega
[ ] Infraestructura desplegada y accesible por HTTPS (Christian).

[ ] mTLS activo y rechazando conexiones sin certificado válido (Kris).

[ ] Validación de firma JWS funcionando (rechaza firmas falsas) (Kris).

[ ] Endpoints /transfers, /status, /return respondiendo (Brayan).

[ ] Rate Limiting activo (Brayan).

[ ] Terraform ejecutado sin errores y estado guardado en backend remoto.