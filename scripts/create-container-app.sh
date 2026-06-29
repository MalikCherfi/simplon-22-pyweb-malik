#!/bin/bash
set -e

RESOURCE_GROUP="rg-malik-cherfi"
LOCATION="francecentral"
CONTAINER_NAME="container-app-malik"
DNS_LABEL="container-app-malik"
ACR_NAME="acrmalik"
ACR_SERVER="${ACR_NAME}.azurecr.io"

# ─── 1. Créer le Container Registry ─────────────────────────
az acr create \
  --name "$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --sku Basic \
  --admin-enabled true

# ─── 2. Login Docker sur ACR via token ───────────────────────
TOKEN=$(az acr login -n "$ACR_NAME" --expose-token --query accessToken -otsv)
docker login "$ACR_SERVER" -u 00000000-0000-0000-0000-000000000000 -p "$TOKEN"

# ─── 3. Builder et pusher l'image avec Docker CLI ────────────
docker build -t "${ACR_SERVER}/api:latest" .
docker push "${ACR_SERVER}/api:latest"

# ─── 4. Récupérer les credentials ACR ────────────────────────
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value --output tsv)

# ─── 5. Déployer le conteneur ────────────────────────────────
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

# ─── 6. URL ──────────────────────────────────────────────────
echo "✅ Déployé sur : http://${DNS_LABEL}.${LOCATION}.azurecontainer.io"