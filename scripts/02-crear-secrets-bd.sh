#!/bin/bash
# ============================================================================
# SCRIPT PARA CREAR SECRETS DE BASE DE DATOS EN KUBERNETES
# Ejecutar DESPUÉS de crear los namespaces
# ============================================================================

set -e

# ⚠️ IMPORTANTE: Obtener los endpoints reales de RDS desde AWS Console o terraform output
# Los passwords están en AWS Secrets Manager

echo "🔐 Creando secrets de base de datos..."

# Obtener endpoints de RDS (modifica según tus valores reales)
# Puedes obtenerlos con: terraform output rds_endpoints

# SWITCH
kubectl create secret generic switch-db-credentials \
  --namespace=switch \
  --from-literal=url="jdbc:postgresql://rds-switch.xxxxxx.us-east-2.rds.amazonaws.com:5432/db_switch_ledger" \
  --from-literal=username="switch_admin" \
  --from-literal=password="OBTENER_DE_SECRETS_MANAGER" \
  --dry-run=client -o yaml | kubectl apply -f -

# ARCBANK
kubectl create secret generic arcbank-db-credentials \
  --namespace=arcbank \
  --from-literal=url="jdbc:postgresql://rds-arcbank.xxxxxx.us-east-2.rds.amazonaws.com:5432/db_arcbank_core" \
  --from-literal=username="arcbank_admin" \
  --from-literal=password="OBTENER_DE_SECRETS_MANAGER" \
  --dry-run=client -o yaml | kubectl apply -f -

# BANTEC
kubectl create secret generic bantec-db-credentials \
  --namespace=bantec \
  --from-literal=url="jdbc:postgresql://rds-bantec.xxxxxx.us-east-2.rds.amazonaws.com:5432/db_bantec_core" \
  --from-literal=username="bantec_admin" \
  --from-literal=password="OBTENER_DE_SECRETS_MANAGER" \
  --dry-run=client -o yaml | kubectl apply -f -

# NEXUS
kubectl create secret generic nexus-db-credentials \
  --namespace=nexus \
  --from-literal=url="jdbc:postgresql://rds-nexus.xxxxxx.us-east-2.rds.amazonaws.com:5432/db_nexus_core" \
  --from-literal=username="nexus_admin" \
  --from-literal=password="OBTENER_DE_SECRETS_MANAGER" \
  --dry-run=client -o yaml | kubectl apply -f -

# ECUSOL
kubectl create secret generic ecusol-db-credentials \
  --namespace=ecusol \
  --from-literal=url="jdbc:postgresql://rds-ecusol.xxxxxx.us-east-2.rds.amazonaws.com:5432/db_ecusol_core" \
  --from-literal=username="ecusol_admin" \
  --from-literal=password="OBTENER_DE_SECRETS_MANAGER" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "✅ Secrets creados en cada namespace"
kubectl get secrets -A | grep db-credentials

echo ""
echo "⚠️ SIGUIENTE PASO: Ejecutar 03-crear-deployments-iniciales.sh"
