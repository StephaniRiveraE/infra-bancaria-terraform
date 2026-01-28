# 📋 Guía de CI/CD para Bancos - Despliegue a EKS

## Requisitos para cada Banco

### 1. Secrets en GitHub (Settings > Secrets > Actions)
| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Access Key IAM |
| `AWS_SECRET_ACCESS_KEY` | Secret Key IAM |
| `AWS_ACCOUNT_ID` | ID cuenta AWS (12 dígitos) |

### 2. Copiar workflow
Copiar `.github-template/deploy-to-eks.yml` a `.github/workflows/deploy.yml` en tu repo.

### 3. Modificar variables según tu banco

## Mapeo de Repos ECR por Banco

### ArcBank
| Microservicio | ECR_REPO | SERVICE_NAME |
|---------------|----------|--------------|
| Gateway | arcbank-gateway-server | gateway-server |
| Clientes | arcbank-service-clientes | service-clientes |
| Cuentas | arcbank-service-cuentas | service-cuentas |
| Transacciones | arcbank-service-transacciones | service-transacciones |
| Sucursales | arcbank-service-sucursales | service-sucursales |

### Bantec
| Microservicio | ECR_REPO | SERVICE_NAME |
|---------------|----------|--------------|
| Gateway | bantec-gateway-server | gateway-server |
| Clientes | bantec-service-clientes | service-clientes |
| Cuentas | bantec-service-cuentas | service-cuentas |
| Transacciones | bantec-service-transacciones | service-transacciones |
| Sucursales | bantec-service-sucursales | service-sucursales |

### Nexus
| Microservicio | ECR_REPO | SERVICE_NAME |
|---------------|----------|--------------|
| Gateway | nexus-gateway | gateway |
| Clientes | nexus-ms-clientes | ms-clientes |
| CBS | nexus-cbs | cbs |
| Transacciones | nexus-ms-transacciones | ms-transacciones |
| Geografía | nexus-ms-geografia | ms-geografia |

### Ecusol
| Microservicio | ECR_REPO | SERVICE_NAME |
|---------------|----------|--------------|
| Gateway | ecusol-gateway-server | gateway-server |
| Clientes | ecusol-ms-clientes | ms-clientes |
| Cuentas | ecusol-ms-cuentas | ms-cuentas |
| Transacciones | ecusol-ms-transacciones | ms-transacciones |

### Switch DIGICONECU
| Microservicio | ECR_REPO | SERVICE_NAME |
|---------------|----------|--------------|
| Gateway | switch-gateway-internal | gateway-internal |
| Núcleo | switch-ms-nucleo | ms-nucleo |
| Contabilidad | switch-ms-contabilidad | ms-contabilidad |
| Compensación | switch-ms-compensacion | ms-compensacion |
| Devolución | switch-ms-devolucion | ms-devolucion |
| Directorio | switch-ms-directorio | ms-directorio |
