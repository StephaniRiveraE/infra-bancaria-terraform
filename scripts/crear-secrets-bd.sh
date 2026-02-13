set -e

echo "ðŸ” Creando secrets de BD en Kubernetes..."

ENTITIES=("arcbank" "bantec" "nexus" "ecusol" "switch")
DB_NAMES=("db_arcbank_core" "db_bantec_core" "db_nexus_core" "db_ecusol_core" "db_switch_ledger")

RDS_ENDPOINTS=$(cd .. && terraform output -json rds_endpoints 2>/dev/null || echo "{}")

if [ "$RDS_ENDPOINTS" == "{}" ]; then
    echo "âš ï¸ Error: No se pudieron obtener endpoints desde Terraform."
    echo "   Ejecuta desde el directorio 'scripts/' despuÃ©s de 'terraform apply'"
    exit 1
fi

for i in "${!ENTITIES[@]}"; do
    ENTITY="${ENTITIES[$i]}"
    DB_NAME="${DB_NAMES[$i]}"
    
    RDS_ENDPOINT=$(echo "$RDS_ENDPOINTS" | jq -r ".${ENTITY}" 2>/dev/null || echo "")
    [ -z "$RDS_ENDPOINT" ] || [ "$RDS_ENDPOINT" == "null" ] && continue
    
    SECRET_NAME="rds-secret-${ENTITY}-v2"
    SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --query SecretString --output text 2>/dev/null || echo "")
    [ -z "$SECRET_JSON" ] && continue
    
    DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')
    DB_USERNAME=$(echo "$SECRET_JSON" | jq -r '.username')
    JDBC_URL="jdbc:postgresql://${RDS_ENDPOINT}/${DB_NAME}"
    
    kubectl create secret generic "${ENTITY}-db-credentials" \
        --namespace="$ENTITY" \
        --from-literal=url="$JDBC_URL" \
        --from-literal=username="$DB_USERNAME" \
        --from-literal=password="$DB_PASSWORD" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    echo "âœ… ${ENTITY}-db-credentials"
done

echo ""
echo "âœ… Secrets creados. Verificar: kubectl get secrets -A | grep db-credentials"
