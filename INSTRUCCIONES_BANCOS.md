# Instrucciones de Seguridad Regulatoria para Bancos

En cumplimiento con la normativa **RNF-SEC-01** (mTLS) y **RNF-SEC-04** (Firma Bidireccional), los bancos participantes deben proveer los siguientes artefactos criptográficos.

> **Nota:** No se requiere el uso de una CA pública costosa. Se aceptan certificados auto-firmados o de PKI interna siempre que se registren en nuestro Truststore.

## 1. Certificado para mTLS (RNF-SEC-01)
*   **Requerimiento:** Certificado X.509 cliente para autenticación mutua.
*   **Algoritmo:** RSA 2048 o ECDSA P-256.
*   **Formato de Entrega:**
    *   `client_certificate.crt`: Su certificado público.
    *   `ca_root.crt`: El certificado de la CA que firmó su cliente (para añadir a nuestro Truststore).

## 2. Llave Pública para Validación de Firmas (RNF-SEC-02/04)
*   **Requerimiento:** Llave Pública RSA para validar el header `X-JWS-Signature` en sus peticiones.
*   **Algoritmo:** RSA 2048 (RS256).
*   **Formato de Entrega:**
    *   `public_key.pem` (Formato PEM estándar).

---

## 3. Lo que recibirán del Switch

Para validar que las respuestas del Switch son auténticas (RNF-SEC-04), cada banco recibirá:

1.  **Switch Public Key:** Archivo `.pem` con nuestra llave pública. Deben usarla para verificar el header `X-JWS-Signature` en nuestras respuestas.
2.  **Credenciales OAuth:** Client ID y Secret para obtener el Token de Sesión (Capa de Identidad).

## Resumen de Entregables

| Archivo | Propósito |
| :--- | :--- |
| `cliente.crt` | Autenticación mTLS (Transporte) |
| `ca_root.crt` | Cadena de Confianza mTLS |
| `public_key.pem` | Validación de Firmas (Integridad) |
| `ips_origen.txt` | Whitelisting de Firewall |
