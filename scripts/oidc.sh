#!/bin/bash
set -e

source variables.sh

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

# ─── 3. Créer le rôle custom (scopé sur Container Apps + ACR) ─
cat > "$ROLE_JSON" <<EOF
{
  "Name": "$ROLE_NAME",
  "IsCustom": true,
  "Description": "Peut créer/gérer Container Apps, Container Apps Environments et ACR",
  "Actions": [
    "Microsoft.App/containerApps/*",
    "Microsoft.App/managedEnvironments/*",
    "Microsoft.ContainerRegistry/registries/*",
    "Microsoft.OperationalInsights/workspaces/*",
    "Microsoft.OperationalInsights/workspaces/sharedKeys/action",
    "Microsoft.Resources/deployments/*",
    "Microsoft.Resources/subscriptions/resourceGroups/read"
  ],
  "NotActions": [],
  "AssignableScopes": [
    "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
  ]
}
EOF

az role definition create --role-definition "$ROLE_JSON"

# ─── 4. Assigner le rôle custom sur le Resource Group ────────
az role assignment create \
  --assignee "$principalId" \
  --role "$ROLE_NAME" \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP

# ─── 5. Nettoyage du fichier JSON temporaire ─────────────────
rm -f "$ROLE_JSON"

echo "✅ Identité, credentials fédérés et rôle custom '$ROLE_NAME' assignés avec succès."