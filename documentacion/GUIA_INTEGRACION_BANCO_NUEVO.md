# Guía Maestra de Integración Bancaria (Para Nuevos Bancos)

Esta guía detalla cronológicamente qué requisitos debe cumplir un nuevo banco (ej. Bantec) para integrarse exitosamente al ecosistema **BancaEcosistema**, basándonos en la arquitectura probada de ArcBank.

---

## 🏗️ 1. Arquitectura de Microservicios

El banco debe estar compuesto por, al menos, los siguientes microservicios Spring Boot, exponiendo sus APIs REST en puertos estándar (internamente en el contenedor):

| Microservicio | Puerto Interno | Endpoint Base Sugerido | Responsabilidad |
|---|---|---|---|
| **Gateway Server** | `8080` | `/` | Enrutamiento, CORS, Auth |
| **Service Clientes** | `8080` | `/api/v1/clientes` | Gestión usuarios, login |
| **Service Cuentas** | `8080` | `/api/v1/cuentas` | Saldos, creación cuentas |
| **Service Transacciones** | `8080` | `/api/transacciones` | Transferencias internas/externas |

### ⚠️ Requisito Crítico: Logs y Health Checks
Todos los microservicios deben tener **Spring Boot Actuator** habilitado para permitir probes de Kubernetes:
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health, info
```

---

## 🛡️ 2. Configuración del Gateway (CORS y Rutas)

El **Gateway Server** es el componente más crítico. Debe configurarse exactamente como el de ArcBank para evitar problemas de CORS y 403 Forbidden.

### A. Dependencias (`pom.xml`)
Asegúrate de usar **Spring Cloud Gateway** (versión compatible con Spring Boot 3.x).

### B. Configuración de CORS en Java (¡OBLIGATORIO!)
**NO configures CORS en `application.yaml` ni uses filtros viejos como `DeduplicateResponseHeader`.**
Crea esta clase de configuración Java. Esto soluciona:
1.  Permite peticiones `OPTIONS` (preflight) sin autenticación.
2.  Elimina headers duplicados si los microservicios backend ya agregan CORS.

**Archivo: `src/main/java/com/tu_banco/gateway/config/CorsConfig.java`**
```java
package com.tu_banco.gateway.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsWebFilter;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import reactor.core.publisher.Mono;

import java.util.Arrays;
import java.util.List;

@Configuration
public class CorsConfig {

    // 1. Maneja el Preflight (OPTIONS) para evitar 403 Forbidden
    @Bean
    public CorsWebFilter corsWebFilter() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("*")); // O especificar dominios exactos
        config.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return new CorsWebFilter(source);
    }

    // 2. Filtro global que deduplica los headers CORS en la respuesta.
    // Los backends ya agregan CORS headers, y el CorsWebFilter también los agrega.
    // Este filtro se ejecuta después y elimina los valores duplicados.
    @Bean
    public GlobalFilter deduplicateCorsHeadersFilter() {
        return (exchange, chain) -> chain.filter(exchange).then(Mono.fromRunnable(() -> {
            HttpHeaders headers = exchange.getResponse().getHeaders();
            deduplicateHeader(headers, HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN);
            deduplicateHeader(headers, HttpHeaders.ACCESS_CONTROL_ALLOW_CREDENTIALS);
            deduplicateHeader(headers, HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS);
            deduplicateHeader(headers, HttpHeaders.ACCESS_CONTROL_ALLOW_HEADERS);
            deduplicateHeader(headers, HttpHeaders.ACCESS_CONTROL_MAX_AGE);
        }));
    }

    private void deduplicateHeader(HttpHeaders headers, String headerName) {
        List<String> values = headers.get(headerName);
        if (values != null && values.size() > 1) {
            // Mantener solo el primer valor único
            String first = values.get(0);
            headers.set(headerName, first);
        }
    }
}
```

### C. Rutas en `application.yaml`
Define las rutas apuntando a los nombres de servicio de Kubernetes (`http://service-nombre:80`).
Usa `StripPrefix=1` si el gateway recibe `/mibanco/api/...` pero el microservicio espera `/api/...`.

---

## 🐳 3. Dockerización

### Dockerfile Estándar (Multi-stage build)
Usa este template para que las imágenes sean ligeras y seguras.
**Importante:** Asegúrate que el `ENTRYPOINT` apunte al JAR correcto.

```dockerfile
# Build Stage
FROM maven:3.9.6-eclipse-temurin-21-alpine AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests

# Run Stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## ☸️ 4. Kubernetes (Manifiestos)

El banco debe tener su propio **Namespace** (ej. `bantec`).

### A. Estructura de Archivos
```
k8s-manifests/
  └── bantec/
      ├── 00-namespace.yaml
      ├── 01-database.yaml        (PostgreSQL)
      ├── 02-backend-config.yaml  (Secrets/ConfigMaps)
      ├── 10-service-clientes.yaml
      ├── 11-service-cuentas.yaml
      ├── 12-service-transacciones.yaml
      └── 20-gateway-server.yaml  <-- El más importante
```

### B. Ingress
Solo el **Gateway Server** debe tener un Ingress. Los demás servicios son `ClusterIP` (internos).

El Ingress debe:
1.  Apuntar al **ALB Compartido** (`alb.ingress.kubernetes.io/group.name: banca-group`).
2.  Tener un **path único** para el banco (ej. `/bantec`).

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: bantec-gateway-ingress
  namespace: bantec
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/group.name: banca-group
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
spec:
  rules:
    - http:
        paths:
          - path: /bantec
            pathType: Prefix
            backend:
              service:
                name: gateway-server
                port:
                  number: 80
```

---

## 🔌 5. Integración con APIM y Switch

El banco debe conectarse con:
1.  **APIM (AWS API Gateway):** Para recibir peticiones externas seguras.
2.  **Cognito:** Para validar tokens (Oauth2).

### En `application.yaml` del Gateway:
```yaml
cognito:
  token-url: ${COGNITO_TOKEN_URL}
  client-id: ${COGNITO_CLIENT_ID}
  client-secret: ${COGNITO_CLIENT_SECRET}

apim:
  base-url: ${APIM_BASE_URL} # URL del API Gateway de AWS
```

### Endpoints Requeridos para el Switch
El banco debe implementar endpoints específicos para recibir transferencias interbancarias desde el Switch (generalmente en `service-transacciones` o `service-core`):

- `POST /api/core/transferencias/recepcion`: Recibir dinero de otro banco.
- `POST /api/core/transferencias/reversion`: Revertir una transacción fallida.

---

## ✅ Checklist Final de Validación

Antes de decir "está listo":

1.  [ ] **Docker Build:** `docker build` corre sin errores.
2.  [ ] **K8s Deployment:** Todos los pods están `1/1 Running`.
3.  [ ] **Ingress:** `curl http://ALB-URL/bantec/api/...` responde (o da 401/403, pero no 404/503).
4.  [ ] **CORS:** La petición `OPTIONS` devuelve 200 OK y headers correctos y SIN duplicados.
5.  [ ] **Conectividad Interna:** El Gateway puede hablar con los microservicios (`1/1 Running` no garantiza tráfico, verifica logs).
