#!/bin/bash
set -e

source scripts/variables.sh

# ─── 1. Créer la Managed Identity ────────────────────────────
az identity create \
  --name "$IDENTITY_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION"

sleep 10

principalId=$(az identity show --name "$IDENTITY_NAME" --resource-group "$RESOURCE_GROUP" --query principalId -otsv)

# ─── 2. Créer le Federated Credential ────────────────────────
az identity federated-credential create \
  --name "gitlab-federated-identity-main" \
  --identity-name "$IDENTITY_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --issuer "https://gitlab.com" \
  --subject "project_path:MalikCherfi/simplon-22-pyweb-malik:ref_type:branch:ref:main" \
  --audiences "https://gitlab.com"

az identity federated-credential create \
  --name "gitlab-federated-identity-feat" \
  --identity-name "$IDENTITY_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --issuer "https://gitlab.com" \
  --subject "project_path:MalikCherfi/simplon-22-pyweb-malik:ref_type:branch:ref:feat/azure-container-app-malik" \
  --audiences "https://gitlab.com"

# ─── 3. Donner les droits sur le Resource Group ──────────────
az role assignment create \
  --assignee "$principalId" \
  --role Contributor \
  --scope /subscriptions/e1a136a9-f375-4382-97be-7a3ea8fefbae/resourceGroups/$RESOURCE_GROUP