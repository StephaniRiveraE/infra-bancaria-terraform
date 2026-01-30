# Guía de Control de Costos EKS

## 📊 Resumen de Costos

Cuando el stack de EKS está **habilitado** (`eks_enabled = true`):
- **EKS Control Plane**: ~$2.40/día ($0.10/hora)
- **NAT Gateway**: ~$1-3/día ($0.045/hora + procesamiento)
- **Fargate Pods**: ~$3-5/día (CoreDNS, VPC-CNI, etc.)
- **CloudWatch Logs**: ~$1-2/día
- **Total aproximado**: ~$8-10/día (~$240-300/mes)

Cuando el stack de EKS está **deshabilitado** (`eks_enabled = false`):
- **Costo EKS**: $0
- **Costo NAT Gateway**: $0
- **Costo Fargate**: $0
- **Solo quedan**: VPC, Subnets, Internet Gateway (~$0-1/mes)

## 🔴 APAGAR EKS (Ahorrar Costos)

Cuando no necesites el cluster de Kubernetes:

### Opción 1: Modificar variables.tf
```hcl
variable "eks_enabled" {
  default = false  # Cambiar a false
}
```

### Opción 2: Usar terraform.tfvars
Crear archivo `terraform.tfvars`:
```hcl
eks_enabled = false
```

### Opción 3: Por línea de comandos
```bash
terraform apply -var="eks_enabled=false"
```

Después de cualquier opción, ejecutar:
```bash
terraform plan   # Verificar que se destruirán los recursos de EKS
terraform apply  # Aplicar los cambios
```

> ⚠️ **IMPORTANTE**: Esto **destruirá** el cluster EKS, NAT Gateway, y todos los Fargate profiles. 
> Tus aplicaciones en Kubernetes dejarán de funcionar hasta que vuelvas a encender el EKS.

## 🟢 ENCENDER EKS

Cuando necesites usar Kubernetes:

### Opción 1: Modificar variables.tf
```hcl
variable "eks_enabled" {
  default = true  # Cambiar a true
}
```

### Opción 2: Usar terraform.tfvars
```hcl
eks_enabled = true
```

### Opción 3: Por línea de comandos
```bash
terraform apply -var="eks_enabled=true"
```

Después de aplicar:
```bash
terraform plan   # Verificar que se crearán los recursos de EKS
terraform apply  # Aplicar los cambios (toma ~10-15 minutos)
```

## ⚙️ Variables de Configuración

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `eks_enabled` | bool | `false` | Habilita/deshabilita todo el stack de EKS |
| `eks_log_retention_days` | number | `7` | Días de retención de logs (menor = más barato) |

## 🔄 Flujo Típico de Desarrollo

1. **Desarrollo local**: `eks_enabled = false` → $0/día para EKS
2. **Pruebas en cluster**: `eks_enabled = true` → ~$10/día
3. **Fin del día/semana**: `eks_enabled = false` → Volver a ahorrar

## 📈 Ahorro Estimado

| Escenario | Costo Mensual | Ahorro |
|-----------|---------------|--------|
| EKS siempre encendido | ~$300/mes | - |
| EKS 8h/día (días laborales) | ~$100/mes | ~$200 |
| EKS solo cuando se necesita | ~$30-50/mes | ~$250-270 |

## 🚀 Después de Encender EKS

Una vez que `terraform apply` termine con `eks_enabled = true`:

```bash
# Configurar kubectl
aws eks update-kubeconfig --name eks-banca-ecosistema --region us-east-2

# Verificar conexión
kubectl get nodes
kubectl get pods -A
```

## ⚡ CI/CD

En tu pipeline de GitHub Actions, puedes controlar EKS así:

```yaml
# Para apagar EKS
- name: Apagar EKS
  run: terraform apply -var="eks_enabled=false" -auto-approve

# Para encender EKS
- name: Encender EKS  
  run: terraform apply -var="eks_enabled=true" -auto-approve
```
