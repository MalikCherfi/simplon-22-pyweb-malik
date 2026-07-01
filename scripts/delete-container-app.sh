#!/bin/bash
set -e

source scripts/variables.sh

# ─── 1. Supprimer le conteneur ───────────────────────────────
echo "🗑️ Suppression du conteneur $CONTAINER_NAME-$ENVIRONMENT..."
az containerapp delete \
  --name "$CONTAINER_NAME-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --yes

# ─── 2. Supprimer l'ACR ──────────────────────────────────────
echo "🗑️ Suppression de l'ACR $ACR_NAME-$ENVIRONMENT..."
az acr delete \
  --name "$ACR_NAME-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --yes

# ─── 3. Supprimer le workspace Log Analytics ─────────────────
echo "🗑️ Suppression du workspace Log Analytics..."
ANALYTICS_WORKSPACE=$(az monitor log-analytics workspace list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[].name" -otsv)

az monitor log-analytics workspace delete \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$ANALYTICS_WORKSPACE"

# ─── 4. Supprimer l'environment Container Apps ──────────────
az containerapp env delete \
  --name "$CONTAINER_ENV-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --yes

echo "Test CI run"
echo "✅ Ressources supprimées"