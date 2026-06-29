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

# ─── 7. Déployer le conteneur ────────────────────────────────
az containerapp create \
  --name "$CONTAINER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --image "${ACR_SERVER}/api:latest" \
  --registry-server "$ACR_SERVER" \
  --registry-username "$ACR_USERNAME" \
  --registry-password "$ACR_PASSWORD" \
  --cpu 1 \
  --memory 1.5Gi \
  --ingress external \
  --target-port 80

# ─── 8. URL ──────────────────────────────────────────────────
echo "✅ Déployé sur : http://${DNS_LABEL}.${LOCATION}.azurecontainer.io"