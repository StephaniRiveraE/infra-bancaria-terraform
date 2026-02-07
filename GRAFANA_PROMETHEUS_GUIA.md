# 📊 Guía de Grafana Cloud + AWS CloudWatch

## Región para Grafana Cloud

**Usa: `US` (United States)** - Es la más cercana a tu AWS `us-east-2`

---

## ✅ Lo que Terraform crea automáticamente

| Recurso | Nombre | Propósito |
|---------|--------|-----------|
| Usuario IAM | `grafana-cloudwatch-reader` | Acceso de solo lectura |
| Política IAM | `GrafanaCloudWatchReadOnly` | Permisos para métricas y logs |
| Access Keys | (automático) | Credenciales de acceso |
| Secret Manager | `grafana-cloudwatch-credentials` | Almacena las credenciales seguras |

---

## 🚀 Pasos para Configurar Grafana Cloud

### Paso 1: Crear Cuenta en Grafana Cloud (1 minuto)

1. Ve a **https://grafana.com/auth/sign-up/create-user**
2. Crea cuenta gratuita
3. **Deployment region:** Selecciona `US`
4. Nombre del stack: `banca-ecosistema` (o lo que quieras)

### Paso 2: Obtener Credenciales de AWS

Después de que Terraform aplique los cambios:

```bash
# Opción 1: Ver el secreto en Secrets Manager
aws secretsmanager get-secret-value --secret-id grafana-cloudwatch-credentials --query SecretString --output text | jq
```

O ve a **AWS Console → Secrets Manager → grafana-cloudwatch-credentials**

### Paso 3: Conectar Grafana a CloudWatch

1. En Grafana Cloud, ve a **Connections → Data Sources**
2. Busca **CloudWatch**
3. Configura:
   ```
   Authentication Provider: Access & secret key
   Access Key ID:           (de Secrets Manager)
   Secret Access Key:       (de Secrets Manager)
   Default Region:          us-east-2
   ```
4. Click **Save & Test** → Debe mostrar ✅

### Paso 4: Importar Dashboards

En Grafana → **Dashboards → Import** → usa estos IDs:

| ID | Dashboard |
|----|-----------|
| `707` | AWS EC2 |
| `11099` | AWS RDS |
| `10880` | AWS EKS |
| `11454` | AWS API Gateway |

---

## 💰 Costos

| Componente | Costo |
|------------|-------|
| Grafana Cloud Free | $0 |
| Usuario IAM | $0 |
| CloudWatch (ya lo tienes) | ~$5/mes |
| **Total** | **~$5/mes** |

---

## ⚠️ Límites del Plan Gratuito

- 10,000 series de métricas
- 50GB de logs
- 14 días de retención
- 3 usuarios

**Para un proyecto académico es más que suficiente.**

---

**Última actualización:** 2026-02-05
