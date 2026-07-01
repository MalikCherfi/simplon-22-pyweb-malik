#!/bin/bash
set -e

source scripts/variables.sh

# ─── 0. Vérifier que la container app existe ──────────────────
if ! az containerapp show --name "$CONTAINER_NAME-$ENVIRONMENT" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  echo "❌ La container app '$CONTAINER_NAME-$ENVIRONMENT' n'existe pas. Lance d'abord un 'create'."
  exit 1
fi

if [ "$ENVIRONMENT" == "production" ]; then
  # ─── Prod : récupère l'image depuis le registre staging ──────
  STAGING_ACR_SERVER="staging${ACR_SERVER}"
  TAG=$(az acr repository show-tags \
  --name "staging${ACR_NAME}" \
  --repository api \
  --orderby time_desc \
  --output json | jq -r '.[] | select(. != "latest") | select(. != null)' | head -1)

  echo "🔄 Promotion de l'image staging → prod (tag: $TAG)"

  # Login sur l'ACR staging pour pull
  STAGING_ACR_USERNAME=$(az acr credential show --name "staging${ACR_NAME}" --query username --output tsv)
  STAGING_ACR_PASSWORD=$(az acr credential show --name "staging${ACR_NAME}" --query passwords[0].value --output tsv)
  az acr login -n "staging${ACR_NAME}" -u "$STAGING_ACR_USERNAME" -p "$STAGING_ACR_PASSWORD"
  docker pull "${STAGING_ACR_SERVER}/api:${TAG}"

  # Login sur l'ACR prod pour push
  PROD_ACR_USERNAME=$(az acr credential show --name "production${ACR_NAME}" --query username --output tsv)
  PROD_ACR_PASSWORD=$(az acr credential show --name "production${ACR_NAME}" --query passwords[0].value --output tsv)
  az acr login -n "production${ACR_NAME}" -u "$PROD_ACR_USERNAME" -p "$PROD_ACR_PASSWORD"
  docker tag "${STAGING_ACR_SERVER}/api:${TAG}" "${ENVIRONMENT}${ACR_SERVER}/api:${TAG}"
  docker tag "${STAGING_ACR_SERVER}/api:${TAG}" "${ENVIRONMENT}${ACR_SERVER}/api:latest"
  docker push "${ENVIRONMENT}${ACR_SERVER}/api:${TAG}"
  docker push "${ENVIRONMENT}${ACR_SERVER}/api:latest"

else
  # ─── Staging : build et push depuis le code source ───────────
  ACR_USERNAME=$(az acr credential show --name "${ENVIRONMENT}${ACR_NAME}" --query username --output tsv)
  ACR_PASSWORD=$(az acr credential show --name "${ENVIRONMENT}${ACR_NAME}" --query passwords[0].value --output tsv)
  az acr login -n "${ENVIRONMENT}${ACR_NAME}" -u "$ACR_USERNAME" -p "$ACR_PASSWORD"

  TAG="$CI_COMMIT_SHORT_SHA"
  docker build -t "api:latest" .
  docker tag "api:latest" "${ENVIRONMENT}${ACR_SERVER}/api:${TAG}"
  docker tag "api:latest" "${ENVIRONMENT}${ACR_SERVER}/api:latest"
  docker push "${ENVIRONMENT}${ACR_SERVER}/api:${TAG}"
  docker push "${ENVIRONMENT}${ACR_SERVER}/api:latest"
fi

# ─── Mettre à jour la container app ──────────────────────────
az containerapp update \
  --name "$CONTAINER_NAME-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --image "${ENVIRONMENT}${ACR_SERVER}/api:${TAG}"

echo "✅ Container app $ENVIRONMENT mise à jour avec l'image ${TAG}"