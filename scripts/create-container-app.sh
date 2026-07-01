#!/bin/bash
set -e

source scripts/variables.sh

# ─── 1. Créer le Container Registry ─────────────────────────
az acr create \
  --name "$ENVIRONMENT$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --sku Basic \
  --admin-enabled true

# ─── 2. Récupérer les credentials ACR ────────────────────────
ACR_USERNAME=$(az acr credential show --name "$ENVIRONMENT$ACR_NAME" --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name "$ENVIRONMENT$ACR_NAME" --query passwords[0].value --output tsv)

# ─── 3. Login Docker sur ACR ─────────────────────────────────
az acr login -n "$ENVIRONMENT$ACR_NAME" -u "$ACR_USERNAME" -p "$ACR_PASSWORD"

# ─── 4. Build l'image ────────────────────────────────────────
docker build -t "api:latest" .

# ─── 5. Tag l'image ──────────────────────────────────────────
docker tag "api:latest" "${ENVIRONMENT}${ACR_SERVER}/api:latest"

# ─── 6. Push l'image ─────────────────────────────────────────
docker push "${ENVIRONMENT}${ACR_SERVER}/api:latest"

# ─── 7. Créer l'environment Container Apps ───────────────────
if [ "$ENVIRONMENT" == "staging" ]; then
  az containerapp env create \
    --name "$CONTAINER_ENV" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION"
fi

# ─── 8. Déployer le conteneur ────────────────────────────────
az containerapp create \
  --name "$CONTAINER_NAME-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --environment "$CONTAINER_ENV" \
  --image "${ENVIRONMENT}${ACR_SERVER}/api:latest" \
  --registry-server "$ENVIRONMENT$ACR_SERVER" \
  --registry-username "$ACR_USERNAME" \
  --registry-password "$ACR_PASSWORD" \
  --cpu 0.5 \
  --memory 1.0Gi \
  --ingress external \
  --target-port 8000