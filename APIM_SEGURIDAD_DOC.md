# Documentación de Seguridad del API Gateway (APIM) – Switch Transaccional

## Visión General
El APIM es la capa de frontera del sistema y debe cumplir con los siguientes mecanismos de seguridad:

| Mecanismo | Propósito |
|-----------|-----------|
| **mTLS v1.3** | Autenticación mutua cliente‑servidor mediante certificados X.509. |
| **Validación JWS (RS256)** | Verifica la integridad y autenticidad del mensaje mediante el header `X‑JWS‑Signature`. |
| **Tokenización** | Evita registrar números de cuenta, routing‑number, IBAN, etc., en los logs. |
| **Rotación automática de certificados** | Renovación cada 90 días con ventana de transición (certificado viejo + nuevo). |
| **Auditoría** | CloudWatch con Trace‑ID y filtros de datos sensibles. |

## Componentes Terraform

- **security_acm_pca.tf** – `aws_acmpca_certificate_authority` (CA privada `apim-switch-ca`).
- **security_client_certs.tf** – `aws_secretsmanager_secret` + `aws_secretsmanager_secret_version` (certificado y clave privada por banco).
- **security_jws_authorizer.tf** – Lambda (Python 3.11) + `aws_apigatewayv2_authorizer` que recupera la clave pública del banco desde Secrets Manager y verifica la firma RS256.
- **security_tokenization.tf** – `aws_cloudwatch_log_group` con `filter_pattern` que elimina los campos sensibles (`account_number`, `routing_number`, `iban`).
- **security_cert_rotation.tf** – `aws_cloudwatch_event_rule` (cron cada 80 días) + Lambda que genera un nuevo certificado cliente, lo guarda en Secrets Manager y actualiza el listener del API Gateway.
- **security_mtls_gateway.tf** – Bloque `mutual_authentication` en `aws_apigatewayv2_api` que apunta a la CA privada.
- **outputs_security.tf** – Exporta ARNs críticos (CA, authorizer, Lambda de rotación, etc.).

## IAM (principio de menor privilegio)
- **apim_jws_authorizer_role** – Permisos `secretsmanager:GetSecretValue` (solo `apim/jws_pubkey_*`) y `logs:*`.
- **cert_rotation_lambda_role** – Permisos `acmpca:*` (emisión y obtención), `secretsmanager:PutSecretValue` y `logs:*`.
- **API Gateway execution role** – Permite invocar el Lambda authorizer.

## Flujo de petición
1. Cliente presenta certificado → **mTLS** verifica contra la CA.
2. API Gateway llama al Lambda authorizer → recupera clave pública y verifica `X‑JWS‑Signature` (RS256).
3. Si ambas validaciones son exitosas, la petición se enruta al backend.
4. CloudWatch registra la petición con `requestId` como Trace‑ID; el filtro de tokenización elimina datos sensibles.
5. Cada 80 días, la Lambda de rotación crea un nuevo certificado y lo publica; durante 10 días el gateway acepta ambos certificados.

## Variables clave (ejemplo)
```hcl
variable "aws_region" { default = "us-east-2" }
variable "banks" { type = list(string), default = [] }  # IDs de bancos participantes
variable "apim_log_retention_days" { default = 30 }
variable "crl_s3_bucket" { description = "Bucket S3 donde se publica la CRL" }
```

## Checklist de entrega (para Kris)
- [ ] CA privada creada y exportada (`apim_ca`).
- [ ] Secrets Manager con certificados cliente (`apim/client_cert_<bank_id>`).
- [ ] API Gateway configurado con `mutual_authentication`.
- [ ] Lambda authorizer JWS implementado y asociado a todas las rutas.
- [ ] CloudWatch Log Group con filtro de tokenización activo.
- [ ] EventBridge + Lambda de rotación configurados (cron cada 80 días).
- [ ] IAM roles revisados y con permisos mínimos.

---
*Documento generado automáticamente a partir de la especificación de seguridad del proyecto.*
