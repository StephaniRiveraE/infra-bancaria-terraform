# Script PowerShell para crear secrets de BD desde AWS Secrets Manager
$entities = @("arcbank", "bantec", "nexus", "ecusol", "switch")
$dbNames = @("db_arcbank_core", "db_bantec_core", "db_nexus_core", "db_ecusol_core", "db_switch_ledger")

# Obtener endpoints de RDS via Terraform
try {
    $rdsEndpoints = terraform output -json rds_endpoints | ConvertFrom-Json
}
catch {
    Write-Host "Error: No se pudieron obtener endpoints de Terraform"
    exit 1
}

for ($i = 0; $i -lt $entities.Length; $i++) {
    $entity = $entities[$i]
    $dbName = $dbNames[$i]
    
    # Obtener endpoint RDS
    $endpoint = $rdsEndpoints.$entity
    if (-not $endpoint) {
        Write-Host "[$entity] Sin endpoint RDS, saltando..."
        continue
    }
    
    # Obtener credenciales de Secrets Manager
    $secretName = "rds-secret-$entity-v2"
    try {
        $secretJson = aws secretsmanager get-secret-value --secret-id $secretName --query SecretString --output text 2>$null
        $secret = $secretJson | ConvertFrom-Json
    }
    catch {
        Write-Host "[$entity] Error obteniendo secret, saltando..."
        continue
    }
    
    $jdbcUrl = "jdbc:postgresql://$endpoint/$dbName"
    
    # Crear secret en Kubernetes
    kubectl create secret generic "$entity-db-credentials" `
        --namespace=$entity `
        --from-literal=url=$jdbcUrl `
        --from-literal=username=$($secret.username) `
        --from-literal=password=$($secret.password) `
        --dry-run=client -o yaml | kubectl apply -f - 2>&1 | Out-Null
    
    Write-Host "[$entity] $entity-db-credentials creado"
}

Write-Host ""
Write-Host "Verificar: kubectl get secrets -A | Select-String 'db-credentials'"
