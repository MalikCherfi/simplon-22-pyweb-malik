#!/bin/bash
set -e

appId=$(az ad app create --display-name gitlab-oidc --query appId -otsv)

az ad sp create --id $appId --query appId -otsv

objectId=$(az ad app show --id $appId --query id -otsv)

cat <<EOF > body.json
{
  "name": "gitlab-federated-identity",
  "issuer": "https://gitlab.com",
  "subject": null,
  "claimsMatchingExpression": {
    "value": "claims['sub'] matches 'project_path:MalikCherfi/simplon-22-pyweb-malik:ref_type:branch:ref:*'",
    "languageVersion": 1
  },
  "description": "GitLab service account federated identity",
  "audiences": [
    "https://gitlab.com"
  ]
}
EOF

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" --body @body.json

az role assignment create --assignee $appId --role Reader --scope /subscriptions/e1a136a9-f375-4382-97be-7a3ea8fefbae

rm body.json