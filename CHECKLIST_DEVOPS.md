# ============================================================================
# CHECKLIST COMPLETO PARA DEVOPS
# Pasos a seguir para habilitar el despliegue de microservicios
# ============================================================================

## 📋 Estado Actual

| Componente | Estado | Notas |
|------------|--------|-------|
| VPC + Networking | ✅ Listo | |
| RDS (5 bases de datos) | ✅ Listo | Funcionando |
| RabbitMQ | ✅ Listo | Funcionando |
| ECR (30 repos) | ✅ Listo | Vacíos, esperando imágenes |
| API Gateway | ✅ Listo | |
| Cognito | ✅ Listo | |
| EKS | ⚠️ APAGADO | Encender para desplegar |
| Usuario IAM CI/CD | 🔄 Pendiente | Se crea con terraform apply |

---

## 🔴 PASOS A SEGUIR (EN ORDEN)

### Paso 1: Encender EKS

```bash
cd c:\proyecto-bancario-devops
terraform apply -var="eks_enabled=true"
```

⏱️ Tiempo: ~15 minutos  
💰 Costo: ~$100/mes adicionales

---

### Paso 2: Configurar kubectl

```bash
aws eks update-kubeconfig --name eks-banca-ecosistema --region us-east-2
```

Verificar:
```bash
kubectl get nodes
```

---

### Paso 3: Crear Namespaces (ejecutar script)

```bash
chmod +x scripts/01-crear-namespaces.sh
./scripts/01-crear-namespaces.sh
```

---

### Paso 4: Obtener credenciales de BD

Ve a AWS Console → Secrets Manager y busca los secrets de cada banco:
- `rds-arcbank-credentials`
- `rds-bantec-credentials`
- `rds-nexus-credentials`
- `rds-ecusol-credentials`
- `rds-switch-credentials`

---

### Paso 5: Crear Secrets de BD en Kubernetes

Edita `scripts/02-crear-secrets-bd.sh` con los valores reales y ejecuta:

```bash
chmod +x scripts/02-crear-secrets-bd.sh
./scripts/02-crear-secrets-bd.sh
```

---

### Paso 6: Obtener credenciales de CI/CD

Ve a AWS Console → Secrets Manager → `github-actions-deployer-credentials`

Contiene:
- `aws_access_key_id`
- `aws_secret_access_key`

---

### Paso 7: Dar a cada equipo

1. **El documento**: `GUIA_DESARROLLADORES.md`
2. **Los secrets**: AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY
3. **Su configuración específica** (ECR_REPOSITORY, NAMESPACE, SERVICE_NAME)

---

## 📋 Información por Banco

### SWITCH
- Endpoint RDS: Ver Secrets Manager → `rds-switch-credentials`
- Namespace K8s: `switch`
- Microservicios: 6

### ARCBANK
- Endpoint RDS: Ver Secrets Manager → `rds-arcbank-credentials`
- Namespace K8s: `arcbank`
- Microservicios: 5

### BANTEC
- Endpoint RDS: Ver Secrets Manager → `rds-bantec-credentials`
- Namespace K8s: `bantec`
- Microservicios: 5

### NEXUS
- Endpoint RDS: Ver Secrets Manager → `rds-nexus-credentials`
- Namespace K8s: `nexus`
- Microservicios: 7

### ECUSOL
- Endpoint RDS: Ver Secrets Manager → `rds-ecusol-credentials`
- Namespace K8s: `ecusol`
- Microservicios: 7

---

## ⚠️ IMPORTANTE

1. **EKS debe estar encendido** antes de que los desarrolladores puedan desplegar
2. **Los deployments iniciales** se crean automáticamente en el primer push
3. **Los secrets de BD** deben existir antes del primer deploy

---

## 🆘 Troubleshooting

### "No resources found"
→ Los namespaces no existen. Ejecutar `01-crear-namespaces.sh`

### "secret not found"
→ Los secrets de BD no existen. Ejecutar `02-crear-secrets-bd.sh`

### "unauthorized"
→ Las credenciales de CI/CD no tienen permisos. Verificar el usuario IAM.

---

**Última actualización:** 2026-02-05
