#!/bin/bash
set -e

RESOURCE_GROUP="rg-malik-cherfi"
CONTAINER_NAME="container-app-malik"
ACR_NAME="acrmalik"
ACR_SERVER="${ACR_NAME}.azurecr.io"

# ─── 0. Vérifier que la container app existe ──────────────────
if ! az containerapp show --name "$CONTAINER_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  echo "❌ La container app '$CONTAINER_NAME' n'existe pas. Lance d'abord un 'create'."
  exit 1
fi

# ─── 1. Récupérer les credentials ACR ────────────────────────
ACR_USERNAME=$(az acr credential show --name "$ACR_NAME" --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query passwords[0].value --output tsv)

# ─── 2. Login Docker sur ACR ─────────────────────────────────
az acr login -n "$ACR_NAME" -u "$ACR_USERNAME" -p "$ACR_PASSWORD"

# ─── 3. Build la nouvelle image ──────────────────────────────
docker build -t "api:latest" .

# ─── 4. Tag avec un identifiant unique (commit SHA) ──────────
TAG="$CI_COMMIT_SHORT_SHA"
docker tag "api:latest" "${ACR_SERVER}/api:${TAG}"
docker tag "api:latest" "${ACR_SERVER}/api:latest"

# ─── 5. Push l'image ──────────────────────────────────────────
docker push "${ACR_SERVER}/api:${TAG}"
docker push "${ACR_SERVER}/api:latest"

# ─── 6. Mettre à jour la container app ───────────────────────
az containerapp update \
  --name "$CONTAINER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --image "${ACR_SERVER}/api:${TAG}"

echo "✅ Container app mise à jour avec l'image ${TAG}"