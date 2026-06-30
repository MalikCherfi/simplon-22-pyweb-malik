#!/bin/bash
set -e

RESOURCE_GROUP="rg-malik-cherfi"
LOCATION="francecentral"
CONTAINER_NAME="container-app-malik"
DNS_LABEL="container-app-malik"
ACR_NAME="acrmalik"
ACR_SERVER="${ACR_NAME}.azurecr.io"
CONTAINER_ENV="container-env-malik"

# ─── 1. Créer le Container Registry ─────────────────────────
az acr create \
  --name "$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --sku Basic \
  --admin-enabled true

# ─── 2. Récupérer les credentials ACR ────────────────────────
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value --output tsv)

# ─── 3. Login Docker sur ACR ─────────────────────────────────
az acr login -n "$ACR_NAME" -u "$ACR_USERNAME" -p "$ACR_PASSWORD"

# ─── 4. Build l'image ────────────────────────────────────────
docker build -t "api:latest" .

# ─── 5. Tag l'image ──────────────────────────────────────────
docker tag "api:latest" "${ACR_SERVER}/api:latest"

# ─── 6. Push l'image ─────────────────────────────────────────
docker push "${ACR_SERVER}/api:latest"

# ─── 7. Créer l'environment Container Apps ───────────────────
az containerapp env create \
  --name "$CONTAINER_ENV" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION"

# ─── 8. Déployer le conteneur ────────────────────────────────
az containerapp create \
  --name "$CONTAINER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --environment "$CONTAINER_ENV" \
  --image "${ACR_SERVER}/api:latest" \
  --registry-server "$ACR_SERVER" \
  --registry-username "$ACR_USERNAME" \
  --registry-password "$ACR_PASSWORD" \
  --cpu 0.5 \
  --memory 1.0Gi \
  --ingress external \
  --target-port 8000