$AWS_ACCOUNT_ID = "851112555783"
$AWS_REGION = "us-east-2"
$IMAGE_TAG = "latest"

$template = Get-Content "k8s-manifests/templates/deployment-template.yaml" -Raw

$microservices = @(
    @("arcbank", "gateway-server", "arcbank-gateway-server"),
    @("arcbank", "service-clientes", "arcbank-service-clientes"),
    @("arcbank", "service-cuentas", "arcbank-service-cuentas"),
    @("arcbank", "service-transacciones", "arcbank-service-transacciones"),
    @("arcbank", "service-sucursales", "arcbank-service-sucursales"),
    
    @("bantec", "gateway-server", "bantec-gateway-server"),
    @("bantec", "service-clientes", "bantec-service-clientes"),
    @("bantec", "service-cuentas", "bantec-service-cuentas"),
    @("bantec", "service-transacciones", "bantec-service-transacciones"),
    @("bantec", "service-sucursales", "bantec-service-sucursales"),
    
    @("nexus", "nexus-gateway", "nexus-gateway"),
    @("nexus", "nexus-ms-clientes", "nexus-ms-clientes"),
    @("nexus", "nexus-cbs", "nexus-cbs"),
    @("nexus", "nexus-ms-transacciones", "nexus-ms-transacciones"),
    @("nexus", "nexus-ms-geografia", "nexus-ms-geografia"),
    @("nexus", "nexus-web-backend", "nexus-web-backend"),
    @("nexus", "nexus-ventanilla-backend", "nexus-ventanilla-backend"),
    
    @("ecusol", "ecusol-gateway-server", "ecusol-gateway-server"),
    @("ecusol", "ecusol-ms-clientes", "ecusol-ms-clientes"),
    @("ecusol", "ecusol-ms-cuentas", "ecusol-ms-cuentas"),
    @("ecusol", "ecusol-ms-transacciones", "ecusol-ms-transacciones"),
    @("ecusol", "ecusol-ms-geografia", "ecusol-ms-geografia"),
    @("ecusol", "ecusol-web-backend", "ecusol-web-backend"),
    @("ecusol", "ecusol-ventanilla-backend", "ecusol-ventanilla-backend"),
    
    @("switch", "switch-gateway-internal", "switch-gateway-internal"),
    @("switch", "switch-ms-nucleo", "switch-ms-nucleo"),
    @("switch", "switch-ms-contabilidad", "switch-ms-contabilidad"),
    @("switch", "switch-ms-compensacion", "switch-ms-compensacion"),
    @("switch", "switch-ms-devolucion", "switch-ms-devolucion"),
    @("switch", "switch-ms-directorio", "switch-ms-directorio")
)

$count = 0
foreach ($svc in $microservices) {
    $namespace = $svc[0]
    $serviceName = $svc[1]
    $ecrRepo = $svc[2]
    
    $manifest = $template `
        -replace '\$\{SERVICE_NAME\}', $serviceName `
        -replace '\$\{NAMESPACE\}', $namespace `
        -replace '\$\{AWS_ACCOUNT_ID\}', $AWS_ACCOUNT_ID `
        -replace '\$\{AWS_REGION\}', $AWS_REGION `
        -replace '\$\{ECR_REPO_NAME\}', $ecrRepo `
        -replace '\$\{IMAGE_TAG\}', $IMAGE_TAG
    
    $manifest | kubectl apply -f - 2>&1 | Out-Null
    $count++
    Write-Host "[$count/30] $serviceName en $namespace"
}

Write-Host ""
Write-Host "Deployments creados: $count"
