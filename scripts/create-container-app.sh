#!/bin/bash
set -e

RESOURCE_GROUP="rg-malik-cherfi"
LOCATION="francecentral"
CONTAINER_NAME="container-app-malik"
DNS_LABEL="container-app-malik"
ACR_NAME="acrmalik"

# ─── 1. Créer le Container Registry ─────────────────────────
az acr create \
  --name "$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --sku Basic \
  --admin-enabled true

# ─── 2. Builder et pusher l'image directement sur ACR ────────
az acr build \
  --registry "$ACR_NAME" \
  --image "api:latest" \
  .

# ─── 3. Récupérer les credentials ACR ────────────────────────
ACR_SERVER="${ACR_NAME}.azurecr.io"
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value --output tsv)

# ─── 4. Déployer le conteneur avec ton image ─────────────────
az containerapp create \
  --name "$CONTAINER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --image "${ACR_SERVER}/api:latest" \
  --registry-login-server "$ACR_SERVER" \
  --registry-username "$ACR_USERNAME" \
  --registry-password "$ACR_PASSWORD" \
  --cpu 1 \
  --memory 1.5 \
  --ports 80 \
  --protocol TCP \
  --ip-address public \
  --dns-name-label "$DNS_LABEL" \
  --os-type Linux

# ─── 5. URL ──────────────────────────────────────────────────
echo "✅ Déployé sur : http://${DNS_LABEL}.${LOCATION}.azurecontainer.io"