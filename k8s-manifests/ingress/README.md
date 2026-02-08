# 🌐 Configuración de Ingress - Exposición de Gateways vía ALB

## 🎯 Propósito

Estos manifiestos exponen los **gateway microservices** de cada banco para que los **frontends en S3** puedan llamarlos.

---

## 📋 ¿Qué se creó?

| Banco | Service | Ingress | URL Esperada |
|-------|---------|---------|--------------|
| ArcBank | `gateway-server` (port 8080) | `arcbank-gateway-ingress` | `http://arcbank-api.banca-ecosistema.com` |
| Bantec | `gateway-server` (port 8080) | `bantec-gateway-ingress` | `http://bantec-api.banca-ecosistema.com` |
| Nexus | `nexus-gateway` (port 8080) | `nexus-gateway-ingress` | `http://nexus-api.banca-ecosistema.com` |
| Ecusol | `ecusol-gateway-server` (port 8080) | `ecusol-gateway-ingress` | `http://ecusol-api.banca-ecosistema.com` |

**Característica importante:** Todos los Ingress **comparten el mismo ALB** (mediante `alb.ingress.kubernetes.io/group.name: banca-ecosistema-shared-alb`) para ahorrar costos.

---

## 🚀 Paso 1: Aplicar los Manifiestos

### Pre-requisitos

1. **EKS debe estar activo** (`eks_enabled=true`)
2. **AWS Load Balancer Controller instalado** (ya lo tienes en `inicializar-eks.sh`)
3. **Los deployments de gateways deben existir** (ya existen si ejecutaste `inicializar-eks.sh`)

### Comandos

```bash
# Aplicar todos los Ingress
kubectl apply -f k8s-manifests/ingress/

# Verificar que se crearon
kubectl get ingress -A

# Ver el ALB que se está aprovisionando (puede tardar 3-5 minutos)
kubectl get ingress -n arcbank arcbank-gateway-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

**Salida esperada:**
```
NAME                       CLASS   HOSTS                              ADDRESS                                                              
arcbank-gateway-ingress    alb     arcbank-api.banca-ecosistema.com   k8s-bancaeco-xxxxxxxx-1234567890.us-east-2.elb.amazonaws.com
bantec-gateway-ingress     alb     bantec-api.banca-ecosistema.com    k8s-bancaeco-xxxxxxxx-1234567890.us-east-2.elb.amazonaws.com
nexus-gateway-ingress      alb     nexus-api.banca-ecosistema.com     k8s-bancaeco-xxxxxxxx-1234567890.us-east-2.elb.amazonaws.com
ecusol-gateway-ingress     alb     ecusol-api.banca-ecosistema.com    k8s-bancaeco-xxxxxxxx-1234567890.us-east-2.elb.amazonaws.com
```

---

## 🌍 Paso 2: Configurar DNS (Tienes 2 Opciones)

### Opción A: Sin Dominio Propio (Temporal - Para Testing)

**Usar directamente la URL del ALB que AWS genera:**

```bash
# Obtener la URL del ALB
ALB_URL=$(kubectl get ingress -n arcbank arcbank-gateway-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "URL del ALB: http://$ALB_URL"
```

**Ejemplo de salida:**
```
http://k8s-bancaeco-e8f32a1b-987654321.us-east-2.elb.amazonaws.com
```

Los frontends pueden usar esta URL directamente:
```javascript
// En el frontend
const API_URL = "http://k8s-bancaeco-e8f32a1b-987654321.us-east-2.elb.amazonaws.com";
```

⚠️ **Problema:** Todos los bancos usan la misma URL del ALB. Necesitas diferenciar por Path o Host header.

---

### Opción B: Con Dominio Propio (Recomendado para Producción)

Si tienes un dominio (ejemplo: `banca-ecosistema.com`), crear registros DNS:

**En Route 53 o tu proveedor de DNS:**

```
Tipo: CNAME
Nombre: arcbank-api.banca-ecosistema.com
Valor: k8s-bancaeco-xxxxxxxx-1234567890.us-east-2.elb.amazonaws.com

Tipo: CNAME
Nombre: bantec-api.banca-ecosistema.com
Valor: k8s-bancaeco-xxxxxxxx-1234567890.us-east-2.elb.amazonaws.com

Tipo: CNAME
Nombre: nexus-api.banca-ecosistema.com
Valor: k8s-bancaeco-xxxxxxxx-1234567890.us-east-2.elb.amazonaws.com

Tipo: CNAME
Nombre: ecusol-api.banca-ecosistema.com
Valor: k8s-bancaeco-xxxxxxxx-1234567890.us-east-2.elb.amazonaws.com
```

**Ventaja:** URLs limpias y profesionales:
- `http://arcbank-api.banca-ecosistema.com`
- `http://bantec-api.banca-ecosistema.com`
- etc.

---

### Opción C: Sin Dominio - Usar Hosts Diferentes (Alternativa)

Modificar los Ingress para NO usar host-based routing:

```yaml
# Cambiar en cada ingress de:
rules:
- host: arcbank-api.banca-ecosistema.com

# A:
rules:
- http:
    paths:
    - path: /arcbank
      pathType: Prefix
```

Luego las URLs serían:
- `http://ALB-URL/arcbank/api/...`
- `http://ALB-URL/bantec/api/...`

---

## 🧪 Paso 3: Probar la Conectividad

```bash
# Obtener la URL del ALB
ALB_URL=$(kubectl get ingress -n arcbank arcbank-gateway-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Probar el health endpoint
curl -H "Host: arcbank-api.banca-ecosistema.com" http://$ALB_URL/health

# O si ya tienes DNS configurado:
curl http://arcbank-api.banca-ecosistema.com/health
```

**Respuesta esperada:**
```
OK
```

---

## 📝 Paso 4: Dar las URLs a los Developers Frontend

Una vez que el ALB esté funcionando, comparte estas URLs con los equipos:

| Equipo Frontend | Variable GitHub | Valor |
|-----------------|-----------------|-------|
| ArcBank Web Client | `API_URL` | `http://arcbank-api.banca-ecosistema.com` |
| Bantec Web Client | `API_URL` | `http://bantec-api.banca-ecosistema.com` |
| Nexus Web Client | `API_URL` | `http://nexus-api.banca-ecosistema.com` |
| Ecusol Web Client | `API_URL` | `http://ecusol-api.banca-ecosistema.com` |

Los developers configuran esto en:
```
GitHub → Repo → Settings → Secrets and variables → Actions → Variables tab
Name: API_URL
Value: http://arcbank-api.banca-ecosistema.com
```

---

## ❌ Troubleshooting

### Error: "ingress class not found"

**Causa:** AWS Load Balancer Controller no está instalado

**Solución:**
```bash
# Ejecutar el script de inicialización que lo instala
./scripts/inicializar-eks.sh
```

### Error: "service not found"

**Causa:** El deployment del gateway no existe todavía

**Solución:**
```bash
# Verificar que el deployment existe
kubectl get deployments -n arcbank

# Si no existe, los developers deben hacer su primer push para crearlo
```

### Ingress creado pero sin ADDRESS

**Causa:** ALB Controller está procesando (espera 3-5 minutos)

**Verificar logs:**
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

---

## 💰 Costos

- **1 ALB compartido:** ~$20-30/mes
- **Data Transfer:** $0.008/GB

**Total estimado:** $25-35/mes para todos los bancos

---

## 🔒 Próximos Pasos (Opcional - Seguridad)

1. **Habilitar HTTPS** con AWS Certificate Manager
2. **Agregar autenticación** en el ALB (Cognito)
3. **Rate limiting** para prevenir abusos

---

## 📞 Soporte

Si tienes problemas aplicando estos manifiestos, verificar:
1. EKS está activo
2. AWS Load Balancer Controller instalado
3. Los pods de gateway están corriendo
4. Los Services apuntan a los selectores correctos

Revisar logs:
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```
