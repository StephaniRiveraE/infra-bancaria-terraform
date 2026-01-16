# =============================================================================
# EJEMPLO DE DEPLOYMENT KUBERNETES - Para microservicios
# =============================================================================
# Este archivo es un TEMPLATE que muestra cómo crear un deployment
# para un microservicio de cualquier banco
#
# IMPORTANTE: Este archivo NO se aplica directamente, es solo referencia
# =============================================================================

# -----------------------------------------------------------------------------
# TEMPLATE DE DEPLOYMENT
# -----------------------------------------------------------------------------
# Guardar como: k8s/deployment.yaml en el repo del microservicio
# 
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   name: ms-auth-deployment       # Nombre del microservicio
#   namespace: arcbank             # Namespace del banco
#   labels:
#     app: ms-auth
#     bank: arcbank
# spec:
#   replicas: 1                    # Sin redundancia = 1 réplica
#   selector:
#     matchLabels:
#       app: ms-auth
#   template:
#     metadata:
#       labels:
#         app: ms-auth
#         bank: arcbank
#     spec:
#       containers:
#       - name: ms-auth
#         image: <AWS_ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com/arcbank:latest
#         ports:
#         - containerPort: 8080
#         resources:
#           requests:
#             memory: "512Mi"
#             cpu: "250m"
#           limits:
#             memory: "1Gi"
#             cpu: "500m"
#         env:
#         - name: SPRING_PROFILES_ACTIVE
#           value: "production"
#         - name: DATABASE_URL
#           valueFrom:
#             secretKeyRef:
#               name: db-credentials
#               key: url
#
# -----------------------------------------------------------------------------
# TEMPLATE DE SERVICE
# -----------------------------------------------------------------------------
# Guardar como: k8s/service.yaml en el repo del microservicio
#
# apiVersion: v1
# kind: Service
# metadata:
#   name: ms-auth-service
#   namespace: arcbank
# spec:
#   selector:
#     app: ms-auth
#   ports:
#   - protocol: TCP
#     port: 80
#     targetPort: 8080
#   type: ClusterIP              # Interno al cluster
#
# -----------------------------------------------------------------------------
# TEMPLATE DE INGRESS (para frontends que necesitan acceso público)
# -----------------------------------------------------------------------------
# Guardar como: k8s/ingress.yaml en el repo del frontend
#
# apiVersion: networking.k8s.io/v1
# kind: Ingress
# metadata:
#   name: frontend-cajero-ingress
#   namespace: arcbank
#   annotations:
#     kubernetes.io/ingress.class: alb
#     alb.ingress.kubernetes.io/scheme: internet-facing
#     alb.ingress.kubernetes.io/target-type: ip
# spec:
#   rules:
#   - host: cajero.arcbank.example.com
#     http:
#       paths:
#       - path: /
#         pathType: Prefix
#         backend:
#           service:
#             name: frontend-cajero-service
#             port:
#               number: 80
