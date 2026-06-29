#!/bin/bash
set -e

RESOURCE_GROUP="rg-malik-cherfi"
CONTAINER_NAME="container-app-malik"
ACR_NAME="acrmalik"

# ─── 1. Supprimer le conteneur ───────────────────────────────
echo "🗑️ Suppression du conteneur $CONTAINER_NAME..."
az containerapp delete \
  --name "$CONTAINER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --yes

# ─── 2. Supprimer l'ACR ──────────────────────────────────────
echo "🗑️ Suppression de l'ACR $ACR_NAME..."
az acr delete \
  --name "$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --yes

echo "✅ Ressources supprimées"