locals {
  microservices = [
    "switch-gateway-internal", "switch-ms-nucleo", "switch-ms-contabilidad", "switch-ms-compensacion", "switch-ms-devolucion", "switch-ms-directorio",
    "bantec-gateway-server", "bantec-service-clientes", "bantec-service-cuentas", "bantec-service-transacciones", "bantec-service-sucursales",
    "arcbank-gateway-server", "arcbank-service-clientes", "arcbank-service-cuentas", "arcbank-service-transacciones", "arcbank-service-sucursales",
    "nexus-gateway", "nexus-ms-clientes", "nexus-cbs", "nexus-ms-transacciones", "nexus-ms-geografia", "nexus-web-backend", "nexus-ventanilla-backend",
    "ecusol-gateway-server", "ecusol-ms-clientes", "ecusol-ms-cuentas", "ecusol-ms-transacciones", "ecusol-ms-geografia", "ecusol-web-backend", "ecusol-ventanilla-backend"
  ]
}

resource "aws_ecr_repository" "repos" {
  for_each             = toset(local.microservices)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.common_tags, {
    Domain = split("-", each.value)[0]
  })
}