#!/bin/bash

# ─── 0. Variables globales ───────────────────────────────────
export RESOURCE_GROUP="rg-malik-cherfi"
export LOCATION="francecentral"
export CONTAINER_NAME="container-app-malik"
export DNS_LABEL="container-app-malik"
export ACR_NAME="acrmalik"
export ACR_SERVER="${ACR_NAME}.azurecr.io"
export CONTAINER_ENV="container-env-malik"
export ACR_SERVER="${ACR_NAME}.azurecr.io"

# ─── 1. Créer la Managed Identity ────────────────────────────
export LOCATION="francecentral"
export IDENTITY_NAME="gitlab-oidc-identity"
