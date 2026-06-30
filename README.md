[![pipeline status](https://gitlab.com/MalikCherfi/simplon-22-pyweb-malik/badges/main/pipeline.svg)](https://gitlab.com/MalikCherfi/simplon-22-pyweb-malik/-/commits/main)

# ⚙️ Mise en place de l'environnement Python

---

## 1. Création du `.venv`

```bash
# Créer l'environnement virtuel
python -m venv .venv

# Activer l'environnement
source .venv/bin/activate
```
---

## 2. Ajout de `.venv` dans le `.gitignore`

---

## 3. Installation des dépendances

```bash
pip install -r requirements.txt
```

---

# 🐳 Mise en place de l'environnement Docker

---

## 1. Dockerfile

```dockerfile
FROM python:3.14
WORKDIR /app

# Install the application dependencies
COPY requirements.txt ./
COPY pylock.toml ./
RUN pip install -r requirements.txt

COPY . /app

CMD ["python3", "app.py"]
EXPOSE 8000
```

### Explication ligne par ligne

| Instruction | Rôle |
|-------------|------|
| `FROM python:3.14` | Utilise l'image officielle Python 3.14 comme base |
| `WORKDIR /app` | Définit `/app` comme répertoire de travail dans le conteneur |
| `COPY requirements.txt ./` | Copie le fichier des dépendances dans le conteneur |
| `COPY pylock.toml` | Copie le fichier lock des dépendances dans le conteneur |
| `RUN pip install -r requirements.txt` | Installe les dépendances Python |
| `COPY . /app` | Copie tout le code source dans le conteneur |
| `CMD ["python3", "app.py"]` | Commande exécutée au démarrage du conteneur |
| `EXPOSE 8000` | Indique que l'application écoute sur le port `8000` |

---

## 2. Makefile


```makefile
.PHONY: build
build: 
	@docker build -t simplon-22-pyweb-malik .
	@echo "Docker image built successfully: simplon-22-pyweb-malik"
	@docker volume create simplon-22-pyweb-malik-volume
	@echo "Docker volume created successfully: simplon-22-pyweb-malik-volume"

.PHONY: run
run:
	@docker run -dp 8000:8000 --name simplon-22-pyweb-malik --mount type=volume,src=simplon-22-pyweb-malik-volume,target=/data simplon-22-pyweb-malik
	@echo "Docker container started successfully: simplon-22-pyweb-malik"

.PHONY: stop
stop:
	@docker stop simplon-22-pyweb-malik
	@echo "Docker container stopped successfully: simplon-22-pyweb-malik"

.PHONY: start
start:
	@docker start simplon-22-pyweb-malik
	@echo "Docker container started successfully: simplon-22-pyweb-malik"

.PHONY: restart
restart:
	@docker restart simplon-22-pyweb-malik
	@echo "Docker container restarted successfully: simplon-22-pyweb-malik"

.PHONY: rm
rm:
	@docker rm simplon-22-pyweb-malik
	@echo "Docker container removed successfully: simplon-22-pyweb-malik"

.PHONY: clean
clean:
	@docker rmi simplon-22-pyweb-malik
	@echo "Docker image removed successfully: simplon-22-pyweb-malik"

.PHONY: kill
kill:
	@docker rm -f simplon-22-pyweb-malik
	@echo "Docker container killed successfully: simplon-22-pyweb-malik"
	@docker volume rm simplon-22-pyweb-malik-volume
	@echo "Docker volume removed successfully: simplon-22-pyweb-malik-volume"
```

### Commandes disponibles

| Commande | Rôle |
|----------|------|
| `make build` | Construit l'image Docker **et** crée le volume |
| `make run` | Crée et démarre le conteneur en mode détaché sur le port `8000` |
| `make stop` | Arrête le conteneur |
| `make start` | Redémarre un conteneur déjà existant |
| `make restart` | Redémarre le conteneur |
| `make rm` | Supprime le conteneur de force |
| `make clean` | Supprime l'image Docker |
| `make kill` | Supprime le conteneur de force **et** le volume |

---

# 🚀 CI avec GitLab

---

## 1. gitlab-ci.yml


```yaml
stages:
  - build

docker-build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:latest
```

### Explication ligne par ligne

| Instruction | Rôle |
|-------------|------|
| `image: docker:latest` | Utilise une image Docker pour avoir accès à la CLI `docker` |
| `services: docker:dind` | Lance un **Docker in Docker** pour pouvoir exécuter des commandes Docker dans le CI |
| `docker login ...` | S'authentifie sur le registry GitLab avec les variables automatiques |
| `docker build ...` | Build l'image et lui donne le tag `latest` |
| `docker push ...` | Pousse l'image dans le registry GitLab |

---

# ☁️ Authentification Azure via OIDC (Managed Identity)

---

## 1. Script de création (`scripts/create-oidc-identity.sh`)

```bash
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
```

### Explication ligne par ligne

| Instruction | Rôle |
|-------------|------|
| `az identity create` | Crée une User-Assigned Managed Identity dans le Resource Group du projet |
| `sleep 10` | Laisse le temps à Azure AD de propager le `principalId` avant de l'utiliser |
| `az identity federated-credential create` | Crée une credential fédérée liant l'identité à un `subject` précis (issuer GitLab, projet, branche) |
| `--subject project_path:...:ref:main` | Autorise uniquement les pipelines lancés depuis la branche `main` |
| `--subject project_path:...:ref:feat/...` | Autorise uniquement les pipelines lancés depuis la branche `feat/azure-container-app-malik` |
| `az role assignment create` | Donne le rôle `Contributor` à l'identité, scopé uniquement sur le Resource Group (pas toute la subscription) |

---

## 2. Utilisation dans `.gitlab-ci.yml`

```yaml
id_tokens:
  GITLAB_OIDC_TOKEN:
    aud: "https://gitlab.com"

script:
  - az login --service-principal -u $AZURE_CLIENT_ID -t $AZURE_TENANT_ID --federated-token $GITLAB_OIDC_TOKEN
```

Les variables `AZURE_CLIENT_ID` (le `clientId` de la Managed Identity) et `AZURE_TENANT_ID` sont définies dans **Settings → CI/CD → Variables**, sans aucun secret stocké.

---

# 🐳 Déploiement sur Azure Container Apps

---

## 1. Création des ressources (`scripts/create-container-app.sh`)

```bash
#!/bin/bash
set -e

source scripts/variables.sh

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

# ─── 7. Créer l'environment Container Apps ───────────────────
az containerapp env create \
  --name "$CONTAINER_ENV" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION"

# ─── 8. Déployer le conteneur ────────────────────────────────
az containerapp create \
  --name "$CONTAINER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --environment "$CONTAINER_ENV" \
  --image "${ACR_SERVER}/api:latest" \
  --registry-server "$ACR_SERVER" \
  --registry-username "$ACR_USERNAME" \
  --registry-password "$ACR_PASSWORD" \
  --cpu 0.5 \
  --memory 1.0Gi \
  --ingress external \
  --target-port 8000
```

### Explication ligne par ligne

| Instruction | Rôle |
|-------------|------|
| `az acr create` | Crée un Azure Container Registry (ACR) en SKU Basic, avec l'authentification admin activée |
| `az acr credential show` | Récupère le username/password admin de l'ACR pour pouvoir s'y connecter avec Docker |
| `az acr login` | Authentifie le Docker CLI local sur l'ACR via les credentials admin (contournement nécessaire car `az acr build` n'est pas autorisé sur un abonnement trial) |
| `docker build` | Build l'image à partir du Dockerfile à la racine du projet |
| `docker tag` / `docker push` | Tag puis pousse l'image vers l'ACR sous le tag `latest` |
| `az containerapp env create` | Crée l'environnement Container Apps (génère aussi un Log Analytics Workspace automatiquement) |
| `az containerapp create` | Déploie le conteneur, configure l'accès au registry, les ressources CPU/RAM (combinaison valide imposée par Azure), et l'ingress public sur le port `8000` |

---

## 2. Mise à jour du déploiement (`scripts/deploy-container-app.sh`)

```bash
#!/bin/bash
set -e

source scripts/variables.sh

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
```

### Explication ligne par ligne

| Instruction | Rôle |
|-------------|------|
| `az containerapp show` (avec `if !`) | Garde-fou : empêche le script de tourner si la container app n'a pas encore été créée |
| `TAG="$CI_COMMIT_SHORT_SHA"` | Utilise le hash court du commit comme tag d'image, pour tracer exactement quel code tourne et permettre un rollback précis |
| `docker tag` / `docker push` (x2) | Pousse l'image à la fois sous le tag du commit et sous `latest`, pour garder une référence fixe en plus du suivi par version |
| `az containerapp update --image` | Met à jour la container app avec la nouvelle image taguée, ce qui force un nouveau déploiement (contrairement à `latest` seul qui peut être mis en cache) |

---

## 3. Suppression des ressources (`scripts/delete-container-app.sh`)

```bash
#!/bin/bash
set -e

source scripts/variables.sh

# ─── 1. Supprimer le conteneur ───────────────────────────────
echo "🗑️ Suppression du conteneur $CONTAINER_NAME..."
az containerapp delete \
  --name "$CONTAINER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --yes

# ─── 2. Supprimer l'ACR ──────────────────────────────────────
echo "🗑️ Suppression de l'ACR $ACR_NAME..."
az acr delete \
  --name "$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --yes

# ─── 3. Supprimer le workspace Log Analytics ─────────────────
echo "🗑️ Suppression du workspace Log Analytics..."
ANALYTICS_WORKSPACE=$(az monitor log-analytics workspace list \
  --resource-group rg-malik-cherfi \
  --query "[].name" -otsv)

az monitor log-analytics workspace delete \
  --resource-group rg-malik-cherfi \
  --workspace-name "$ANALYTICS_WORKSPACE"

# ─── 4. Supprimer l'environment Container Apps ──────────────
az containerapp env delete \
  --name "container-env-malik" \
  --resource-group "rg-malik-cherfi" \
  --yes

echo "✅ Ressources supprimées"
```

### Explication ligne par ligne

| Instruction | Rôle |
|-------------|------|
| `az containerapp delete` | Supprime la container app déployée |
| `az acr delete` | Supprime l'Azure Container Registry et toutes les images qu'il contient |
| `az monitor log-analytics workspace list` | Récupère le nom du workspace généré automatiquement à la création de l'environment (nom aléatoire non prévisible) |
| `az monitor log-analytics workspace delete` | Supprime ce workspace pour éviter d'accumuler des ressources orphelines |
| `az containerapp env delete` | Supprime l'environment Container Apps lui-même |

---

## 4. Pipeline de gestion manuelle (`create` / `delete`)

Un fichier CI séparé (`.gitlab/workflows/.gitlab-ressource-handler.yml`) permet de déclencher manuellement la création ou la suppression complète de l'infrastructure, via un input affiché dans l'interface "New pipeline" de GitLab.

```yaml
spec:
  inputs:
    action:
---
stages:
  - manage

variables:
  ACTION: $[[ inputs.action ]]

.auth: &auth
  image: ubuntu:22.04
  services:
    - docker:dind
  variables:
    DOCKER_HOST: tcp://docker:2375
    DOCKER_TLS_CERTDIR: ""
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: "https://gitlab.com"
  before_script:
    - apt-get update && apt-get install -y curl docker.io
    - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    - az login --service-principal -u $AZURE_CLIENT_ID -t $AZURE_TENANT_ID --federated-token $GITLAB_OIDC_TOKEN

create-container-app:
  stage: manage
  <<: *auth
  script:
    - chmod +x scripts/create-container-app.sh
    - ./scripts/create-container-app.sh
  rules:
    - if: $CI_PIPELINE_SOURCE == "web" && $ACTION == "create"

delete-container-app:
  stage: manage
  <<: *auth
  script:
    - chmod +x scripts/delete-container-app.sh
    - ./scripts/delete-container-app.sh
  rules:
    - if: $CI_PIPELINE_SOURCE == "web" && $ACTION == "delete"
```

### Explication ligne par ligne

| Instruction | Rôle |
|-------------|------|
| `spec: inputs: action:` | Déclare un input `action`, affiché comme dropdown dans l'interface "New pipeline" de GitLab |
| `variables: ACTION:` | Récupère la valeur choisie par l'utilisateur dans une variable utilisable dans les `rules` |
| `.auth: &auth` | Ancre YAML réutilisable regroupant l'image, le service `docker:dind`, l'authentification OIDC, évitant de dupliquer ce bloc dans chaque job |
| `services: docker:dind` + `DOCKER_HOST`/`DOCKER_TLS_CERTDIR` | Lance un démon Docker accessible en TCP sans TLS, nécessaire car l'image `ubuntu:22.04` n'a pas de socket Docker natif |
| `id_tokens: GITLAB_OIDC_TOKEN` | Génère le token JWT signé par GitLab, vérifié ensuite par Azure AD via la Federated Identity Credential |
| `rules: if: $CI_PIPELINE_SOURCE == "web" && $ACTION == "..."` | Le job ne se lance que si le pipeline est lancé manuellement (`web`) **et** que l'action correspondante a été choisie dans le dropdown |

---

## 5. Déploiement automatique sur push

Dans le pipeline principal, le job de déploiement build et pousse une nouvelle version à chaque push, sans jamais se déclencher lors d'un lancement manuel destiné au `create`/`delete`.

```yaml
deploy-container-app:
  stage: deploy
  image: ubuntu:22.04
  services:
    - docker:dind
  variables:
    DOCKER_HOST: tcp://docker:2375
    DOCKER_TLS_CERTDIR: ""
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: "https://gitlab.com"
  environment:
    name: staging
    url: https://container-app-malik.mangoflower-72cf4ec7.francecentral.azurecontainerapps.io
  script:
    - apt-get update && apt-get install -y curl docker.io
    - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    - az login --service-principal -u $AZURE_CLIENT_ID -t $AZURE_TENANT_ID --federated-token $GITLAB_OIDC_TOKEN
    - chmod +x scripts/deploy-container-app.sh
    - ./scripts/deploy-container-app.sh
  rules:
    - if: $CI_PIPELINE_SOURCE == "web"
      when: never
    - if: $CI_PIPELINE_SOURCE == "push"

docker-build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:latest
  rules:
    - if: $CI_PIPELINE_SOURCE == "web"
      when: never
    - if: $CI_COMMIT_BRANCH == "main"
    - when: manual
```

### Explication ligne par ligne

| Instruction | Rôle |
|-------------|------|
| `environment: name: staging / url:` | Enregistre ce job comme déploiement vers l'environnement `staging` dans **Operate → Environments**, avec un lien direct vers l'URL de la container app |
| `rules: if: $CI_PIPELINE_SOURCE == "web" → when: never` | Bloque explicitement ce job lors d'un lancement manuel (réservé au pipeline `manage`), évitant un déploiement parasite avant la création de l'infra |
| `rules: if: $CI_PIPELINE_SOURCE == "push"` | Réautorise le déclenchement automatique à chaque push, une fois le cas `web` écarté |
| `docker-build: rules:` | Build l'image sur la branche `main` automatiquement, ou manuellement sur les autres branches (avec possibilité de skip sans bloquer le reste du pipeline) |

---

# 👥 CODEOWNERS

---

```yaml
# Les fichiers de sécurité requièrent une validation
.gitlab-ci.yml     @MalikCherfi
CODEOWNERS         @MalikCherfi
```

### Explication

| Fichier | Propriétaire | Rôle |
|---------|-------------|------|
| `.gitlab-ci.yml` | `@MalikCherfi` | Toute modification du pipeline doit être validée |
| `CODEOWNERS` | `@MalikCherfi` | Toute modification des règles de propriété doit être validée |

___

## 🔏 Commits vérifiés avec SSH

___

### Configuration

```bash
# Utiliser SSH comme format de signature
git config --global gpg.format ssh

# Indiquer la clé SSH à utiliser
git config --global user.signingkey ~/.ssh/id_ed25519.pub

# Activer la signature automatique sur tous les commits
git config --global commit.gpgsign true
```

---