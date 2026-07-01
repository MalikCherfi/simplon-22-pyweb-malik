#!/bin/bash
set -e

source scripts/variables.sh

# ─── 1. Créer le Container Registry ─────────────────────────
az acr create \
  --name "$ACR_NAME$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --sku Basic \
  --admin-enabled true

# ─── 2. Récupérer les credentials ACR ────────────────────────
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME$ENVIRONMENT" --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME$ENVIRONMENT" --query passwords[0].value --output tsv)

# ─── 3. Login Docker sur ACR ─────────────────────────────────
az acr login -n "$ACR_NAME$ENVIRONMENT" -u "$ACR_USERNAME" -p "$ACR_PASSWORD"

# ─── 4. Build l'image ────────────────────────────────────────
docker build -t "api:latest" .

# ─── 5. Tag l'image ──────────────────────────────────────────
docker tag "api:latest" "${ACR_SERVER}-${ENVIRONMENT}/api:latest"

# ─── 6. Push l'image ─────────────────────────────────────────
docker push "${ACR_SERVER}-${ENVIRONMENT}/api:latest"

# ─── 7. Créer l'environment Container Apps ───────────────────
az containerapp env create \
  --name "$CONTAINER_ENV-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION"

# ─── 8. Déployer le conteneur ────────────────────────────────
az containerapp create \
  --name "$CONTAINER_NAME-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --environment "$CONTAINER_ENV-$ENVIRONMENT" \
  --image "${ACR_SERVER}-${ENVIRONMENT}/api:latest" \
  --registry-server "$ACR_SERVER-$ENVIRONMENT" \
  --registry-username "$ACR_USERNAME" \
  --registry-password "$ACR_PASSWORD" \
  --cpu 0.5 \
  --memory 1.0Gi \
  --ingress external \
  --target-port 8000