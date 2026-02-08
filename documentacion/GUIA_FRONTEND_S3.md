# 🌐 Guía Completa - Despliegue de Frontend a AWS S3

> **Para:** Desarrolladores de aplicaciones web (React, Angular, Vue, Vite)
> **Resultado:** Tu frontend se despliega automáticamente cuando haces push a `main`

---

## 🎯 ¿Qué hace este workflow?

Cuando haces **push a la rama `main`** de tu repositorio frontend:

1. GitHub Actions detecta el cambio
2. Ejecuta `npm run build` para generar los archivos de producción
3. Sube automáticamente los archivos a tu bucket S3 en AWS
4. Tu aplicación web queda disponible en una URL pública

```
Tu código → Push a main → GitHub Actions → npm build → S3 → URL pública
```

---

## 📦 PASO 1: Identifica tu Bucket S3

Busca tu frontend en esta tabla y copia el nombre **exacto** del bucket:

### Switch
| Aplicación | S3_BUCKET (copia esto exacto) |
|------------|-------------------------------|
| Admin Panel | `banca-ecosistema-switch-admin-panel-512be32e` |

### ArcBank
| Aplicación | S3_BUCKET (copia esto exacto) |
|------------|-------------------------------|
| Web Client (Banca en línea) | `banca-ecosistema-arcbank-web-client-512be32e` |
| Ventanilla App (Para cajeros) | `banca-ecosistema-arcbank-ventanilla-app-512be32e` |

### Bantec
| Aplicación | S3_BUCKET (copia esto exacto) |
|------------|-------------------------------|
| Web Client | `banca-ecosistema-bantec-web-client-512be32e` |
| Ventanilla App | `banca-ecosistema-bantec-ventanilla-app-512be32e` |

### Nexus
| Aplicación | S3_BUCKET (copia esto exacto) |
|------------|-------------------------------|
| Web Client | `banca-ecosistema-nexus-web-client-512be32e` |
| Ventanilla App | `banca-ecosistema-nexus-ventanilla-app-512be32e` |

### EcuSol
| Aplicación | S3_BUCKET (copia esto exacto) |
|------------|-------------------------------|
| Web Client | `banca-ecosistema-ecusol-web-client-512be32e` |
| Ventanilla App | `banca-ecosistema-ecusol-ventanilla-app-512be32e` |

---

## 📁 PASO 2: Copia el archivo de workflow

1. Descarga el archivo `deploy-to-s3.yml` de este repositorio (carpeta `.github-template/`)
2. En **tu repositorio frontend**, crea esta estructura de carpetas:
   ```
   tu-frontend/
   ├── .github/
   │   └── workflows/
   │       └── deploy.yml    ← Pega el archivo aquí (renómbralo a deploy.yml)
   ├── src/
   ├── package.json
   └── ...
   ```

---

## ✏️ PASO 3: Edita el archivo

Abre `.github/workflows/deploy.yml` y cambia **SOLO esta línea**:

```yaml
# ⚠️ CAMBIAR ESTE VALOR SEGÚN TU FRONTEND ⚠️
S3_BUCKET: banca-ecosistema-arcbank-web-client-512be32e   # ← Pon tu bucket de la tabla
```

### Ejemplo para Nexus Web Client:
```yaml
S3_BUCKET: banca-ecosistema-nexus-web-client-512be32e
```

### Ejemplo para EcuSol Ventanilla:
```yaml
S3_BUCKET: banca-ecosistema-ecusol-ventanilla-app-512be32e
```

---

## 🔑 PASO 4: Configura los Secrets en GitHub

Tu repositorio necesita las credenciales de AWS para poder subir archivos a S3.

1. Ve a tu repositorio en GitHub
2. Click en **Settings** (Configuración)
3. En el menú izquierdo: **Secrets and variables** → **Actions**
4. Click en **New repository secret**
5. Agrega estos 2 secrets:

| Name | Secret (pide el valor a DevOps) |
|------|--------------------------------|
| `AWS_ACCESS_KEY_ID` | `AKIA...` (empieza con AKIA) |
| `AWS_SECRET_ACCESS_KEY` | `wJalr...` (cadena larga) |

> **¿No tienes los secrets?** Pídelos al equipo de DevOps: awsproyecto26@gmail.com

---

## 🔗 PASO 5: Configura la URL del API de tu Banco

Tu frontend necesita saber la URL del backend para hacer llamadas a la API.

> [!IMPORTANT]
> **NO** uses la URL del API Manager central (`https://gf0js7uezg...`).  
> Esa es solo para comunicación inter-bancaria (banco ↔ switch ↔ banco).

### 🌐 URLs del Backend por Banco

Cada banco tiene su propio Gateway expuesto via Application Load Balancer:

| Banco | URL del API Backend | Para qué frontend |
|-------|---------------------|-------------------|
| **ArcBank** | `http://arcbank-api.banca-ecosistema.com` | arcbank-web-client, arcbank-ventanilla |
| **Bantec** | `http://bantec-api.banca-ecosistema.com` | bantec-web-client, bantec-ventanilla |
| **Nexus** | `http://nexus-api.banca-ecosistema.com` | nexus-web-client, nexus-ventanilla |
| **Ecusol** | `http://ecusol-api.banca-ecosistema.com` | ecusol-web-client, ecusol-ventanilla |

> [!NOTE]
> **DevOps:** Si el ALB aún no está configurado, ejecuta primero:
> ```bash
> kubectl apply -f k8s-manifests/ingress/
> ```
> Ver instrucciones completas en: `k8s-manifests/ingress/README.md`

### 📝 Configurar en GitHub (Pasos para el Desarrollador)

Los desarrolladores deben configurar la URL de su banco siguiendo estos pasos:

1. Ve a **tu repositorio** de frontend en GitHub.
2. Haz clic en la pestaña superior **Settings** (Configuración).
3. En el menú de la izquierda, busca la sección **Secrets and variables** y haz clic en **Actions**.
4. Selecciona la pestaña **Variables** (es la segunda pestaña, NO uses la de Secrets).
5. Haz clic en el botón verde **New repository variable**.
6. Agrega la variable con estos datos:
   - **Name:** `API_URL`
   - **Value:** (Copia la URL de la tabla de arriba según tu banco)

---

**Ejemplo de configuración:**


**Ejemplo para ArcBank:**

| Name | Value |
|------|-------|
| `API_URL` | `http://arcbank-api.banca-ecosistema.com` |

**Ejemplo para Nexus:**

| Name | Value |
|------|-------|
| `API_URL` | `http://nexus-api.banca-ecosistema.com` |

### ⚙️ ¿Para qué sirve?

Esta variable se inyecta en tu código durante el build:

| Si usas | Variable disponible | Cómo usarla en tu código |
|---------|--------------------|-----------------------|
| **Vite** (React/Vue moderno) | `VITE_API_URL` | `import.meta.env.VITE_API_URL` |
| **Create React App** | `REACT_APP_API_URL` | `process.env.REACT_APP_API_URL` |

### Ejemplo en tu código:
```javascript
// El valor viene de la variable de entorno
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

// Usas la URL para llamar al backend
fetch(`${API_URL}/api/transferencias`)
  .then(res => res.json())
  .then(data => console.log(data));
```

---

## 🚀 PASO 6: Haz push y verifica

1. Haz commit de tus cambios:
   ```bash
   git add .
   git commit -m "Agregar workflow de despliegue a S3"
   git push origin main
   ```

2. Ve a tu repositorio en GitHub → pestaña **Actions**
3. Verás el workflow ejecutándose
4. Si todo sale bien ✅, tu app estará disponible en:

### Tu URL de Frontend:
```
http://{TU-S3-BUCKET}.s3-website.us-east-2.amazonaws.com
```

**Ejemplos:**
| Frontend | URL |
|----------|-----|
| ArcBank Web | `http://banca-ecosistema-arcbank-web-client-512be32e.s3-website.us-east-2.amazonaws.com` |
| Nexus Ventanilla | `http://banca-ecosistema-nexus-ventanilla-app-512be32e.s3-website.us-east-2.amazonaws.com` |
| EcuSol Web | `http://banca-ecosistema-ecusol-web-client-512be32e.s3-website.us-east-2.amazonaws.com` |

---

## ✅ Checklist Final

Antes de hacer push, verifica:

- [ ] Copié `deploy-to-s3.yml` a `.github/workflows/deploy.yml`
- [ ] Cambié `S3_BUCKET` al mío (de la tabla del Paso 1)
- [ ] Configuré `AWS_ACCESS_KEY_ID` en GitHub Secrets
- [ ] Configuré `AWS_SECRET_ACCESS_KEY` en GitHub Secrets
- [ ] (Opcional) Configuré `API_URL` en GitHub Variables
- [ ] `npm run build` funciona correctamente en mi máquina local

---

## ❌ Errores Comunes y Soluciones

| Error en GitHub Actions | Causa | Solución |
|------------------------|-------|----------|
| `NoSuchBucket` | Nombre del bucket mal escrito | Copia el nombre exacto de la tabla del Paso 1 |
| `AccessDenied` | Credenciales AWS incorrectas | Verifica que los Secrets estén bien configurados |
| `npm ERR! Missing script: "build"` | No tienes script build | Agrega en package.json: `"build": "vite build"` o similar |
| `No se encontró carpeta de build` | El build genera otra carpeta | El workflow busca `dist/`, `build/` o `out/` |
| `The process completed with exit code 1` | Error en tu código | Ejecuta `npm run build` en local para ver el error |

---

## 📞 Contacto

**DevOps - Infraestructura AWS:**
- Email: awsproyecto26@gmail.com
- Para: Pedir credenciales AWS, reportar problemas de infraestructura
