#!/bin/bash

# ─── 0. Variables globales ───────────────────────────────────
export RESOURCE_GROUP="rg-malik-cherfi"
export LOCATION="francecentral"
export CONTAINER_NAME="container-app-malik"
export DNS_LABEL="container-app-malik"
export ACR_NAME="acrmalik"
export ACR_SERVER="${ACR_NAME}.azurecr.io"
export CONTAINER_ENV="container-env"
export ACR_SERVER="${ACR_NAME}.azurecr.io"

# ─── 1. Créer la Managed Identity ────────────────────────────
export LOCATION="francecentral"
export IDENTITY_NAME="gitlab-oidc-identity"
export SUBSCRIPTION_ID="e1a136a9-f375-4382-97be-7a3ea8fefbae"
ROLE_NAME="ContainerAppACRCreator-$RESOURCE_GROUP"
ROLE_JSON="/tmp/role-${RESOURCE_GROUP}.json"
