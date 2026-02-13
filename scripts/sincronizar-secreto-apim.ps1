$namespaces = @("switch", "bantec", "arcbank", "nexus", "ecusol")
$secretName = "switch/internal-api-secret-dev"
$k8sSecretName = "apim-internal-secret"

Write-Host "Obteniendo secreto de AWS: $secretName..." -ForegroundColor Cyan
try {
    $secretValue = aws secretsmanager get-secret-value --secret-id $secretName --query SecretString --output text
}
catch {
    Write-Host "Error al obtener el secreto de AWS. Verifica tus credenciales." -ForegroundColor Red
    exit 1
}

if (-not $secretValue) {
    Write-Host "Error: El secreto está vacío o no se pudo obtener." -ForegroundColor Red
    exit 1
}

foreach ($ns in $namespaces) {
    Write-Host "Sincronizando secreto en namespace: $ns" -ForegroundColor Yellow
    
    # Crear el secreto en K8s
    kubectl create secret generic $k8sSecretName `
        --namespace=$ns `
        --from-literal=APIM_ORIGIN_SECRET=$secretValue `
        --dry-run=client -o yaml | kubectl apply -f -
}

Write-Host "`n¡Sincronización completada exitosamente!" -ForegroundColor Green
