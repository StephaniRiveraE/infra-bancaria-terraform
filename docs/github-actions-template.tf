# =============================================================================
# EJEMPLO DE GITHUB ACTIONS - Para repositorios de bancos
# =============================================================================
# Este archivo es un TEMPLATE que debe copiarse a cada repositorio de banco
# Ubicación en el repo del banco: .github/workflows/deploy.yml
#
# IMPORTANTE: Este archivo NO se usa directamente aquí, es solo referencia
# =============================================================================

# -----------------------------------------------------------------------------
# INSTRUCCIONES DE USO
# -----------------------------------------------------------------------------
# 
# 1. Copia el contenido de 'deploy-template.yml' a tu repo de banco
# 2. Ajusta las variables según tu banco (BANK_NAME, NAMESPACE, etc.)
# 3. Configura los secrets en GitHub:
#    - AWS_ACCESS_KEY_ID
#    - AWS_SECRET_ACCESS_KEY
#    - AWS_ACCOUNT_ID
#
# -----------------------------------------------------------------------------

# TEMPLATE - Copiar desde aquí hacia abajo

# name: Deploy to EKS
#
# on:
#   push:
#     branches: [main]
#   workflow_dispatch:
#
# env:
#   AWS_REGION: us-east-2
#   EKS_CLUSTER: ecosistema-bancario
#   # ============================================
#   # MODIFICAR ESTAS VARIABLES SEGÚN EL BANCO
#   # ============================================
#   BANK_NAME: arcbank          # arcbank | bantec | nexus | ecusol | switch
#   NAMESPACE: arcbank          # Mismo que BANK_NAME
#   ECR_REPOSITORY: arcbank     # Repositorio en ECR
#
# jobs:
#   deploy:
#     runs-on: ubuntu-latest
#     
#     steps:
#       - name: Checkout code
#         uses: actions/checkout@v4
#
#       - name: Configure AWS credentials
#         uses: aws-actions/configure-aws-credentials@v4
#         with:
#           aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
#           aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
#           aws-region: ${{ env.AWS_REGION }}
#
#       - name: Login to Amazon ECR
#         id: login-ecr
#         uses: aws-actions/amazon-ecr-login@v2
#
#       - name: Build and push Docker image
#         env:
#           ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
#           IMAGE_TAG: ${{ github.sha }}
#         run: |
#           docker build -t $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:$IMAGE_TAG .
#           docker build -t $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:latest .
#           docker push $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:$IMAGE_TAG
#           docker push $ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:latest
#
#       - name: Update kubeconfig
#         run: |
#           aws eks update-kubeconfig --region ${{ env.AWS_REGION }} --name ${{ env.EKS_CLUSTER }}
#
#       - name: Deploy to EKS
#         env:
#           ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
#           IMAGE_TAG: ${{ github.sha }}
#         run: |
#           # Actualiza la imagen en el deployment
#           kubectl set image deployment/${{ env.BANK_NAME }}-deployment \
#             ${{ env.BANK_NAME }}=$ECR_REGISTRY/${{ env.ECR_REPOSITORY }}:$IMAGE_TAG \
#             -n ${{ env.NAMESPACE }}
#           
#           # Espera a que el deployment esté listo
#           kubectl rollout status deployment/${{ env.BANK_NAME }}-deployment \
#             -n ${{ env.NAMESPACE }} --timeout=300s
