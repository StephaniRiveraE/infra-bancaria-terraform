#!/bin/bash
# ============================================================================
# SCRIPT DE SETUP INICIAL PARA EKS
# Ejecutar DESPUÉS de que EKS esté activo
# ============================================================================

set -e

echo "🔧 Configurando kubectl..."
aws eks update-kubeconfig --name eks-banca-ecosistema --region us-east-2

echo ""
echo "📁 Creando namespaces..."
kubectl create namespace arcbank --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace bantec --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace nexus --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ecusol --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace switch --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "✅ Namespaces creados:"
kubectl get namespaces

echo ""
echo "⚠️ SIGUIENTE PASO: Ejecutar 02-crear-secrets-bd.sh para crear los secrets de base de datos"
