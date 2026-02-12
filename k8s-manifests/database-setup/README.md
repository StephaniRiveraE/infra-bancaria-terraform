# 🗄️ Guía de Inicialización de Bases de Datos Lógicas

Este directorio contiene la configuración necesaria para crear las bases de datos lógicas (`db_clientes`, `db_cuentas`, etc.) que los microservicios requieren en sus instancias RDS correspondientes.

## 🚀 Cómo usar (Vía kubectl)

Si deseas ejecutarlo manualmente (DevOps):
```bash
kubectl apply -f init-logical-databases.yaml
```

## 🤖 Integración CI/CD

Para que el proceso sea automático y auditable:
1. Sube este archivo al repositorio en la carpeta `k8s-manifests/database-setup/`.
2. El pipeline de CI/CD aplicará estos Jobs automáticamente.

## 📋 ¿Qué hace este Job?
- Se conecta a cada RDS usando las credenciales de los secretos (ej: `arcbank-db-credentials`).
- Ejecuta comandos `CREATE DATABASE` para cada microservicio.
- **Seguridad**: Si el Job falla porque la base de datos ya existe, simplemente muestra un mensaje informativo y continúa (`|| true`).

## 🔍 Verificación

Puedes ver el progreso de la creación con:
```bash
kubectl get jobs -A -l app=db-init
kubectl logs -l app=db-init --all-containers=true -n arcbank
```

Una vez que los Jobs terminen con éxito (`COMPLETED`), puedes borrarlos:
```bash
kubectl delete -f init-logical-databases.yaml
```
