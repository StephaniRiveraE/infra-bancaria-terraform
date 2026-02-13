# Sincroniza el secreto interno del APIM de AWS a Kubernetes
#namespaces=("switch" "bantec" "arcbank" "nexus" "ecusol")
#env="dev" # Cambiar segun corresponda

secret_name="switch/internal-api-secret-dev"
k8s_secret_name="apim-internal-secret"

echo "Obteniendo secreto de AWS..."
secret_value=$(aws secretsmanager get-secret-value --secret-id $secret_name --query SecretString --output text)

if [ -z "$secret_value" ]; then
    echo "Error: No se pudo obtener el secreto de AWS"
    exit 1
fi

for ns in "${namespaces[@]}"; do
    echo "Sincronizando secreto en namespace: $ns"
    kubectl create secret generic "$k8s_secret_name" \
        --namespace="$ns" \
        --from-literal=APIM_ORIGIN_SECRET="$secret_value" \
        --dry-run=client -o yaml | kubectl apply -f -
done

echo "¡Hecho!"
