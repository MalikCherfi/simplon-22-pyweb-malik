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

# ─── 3. Supprimer l'environment Container Apps ──────────────
az containerapp env delete \
  --name "container-env-malik" \
  --resource-group "rg-malik-cherfi" \
  --yes

# ─── 4. Supprimer le workspace Log Analytics ─────────────────
echo "🗑️ Suppression du workspace Log Analytics..."
ANALYTICS_WORKSPACE=$(az monitor log-analytics workspace list \
  --resource-group rg-malik-cherfi \
  --query "[].name" -otsv)

az monitor log-analytics workspace delete \
  --resource-group rg-malik-cherfi \
  --workspace-name "$ANALYTICS_WORKSPACE"

echo "Test CI run"
echo "✅ Ressources supprimées"