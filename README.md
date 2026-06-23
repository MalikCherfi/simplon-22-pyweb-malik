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
FROM python:3.13
WORKDIR /app

# Install the application dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

CMD ["python3", "app.py"]
EXPOSE 8000
```

### Explication ligne par ligne

| Instruction | Rôle |
|-------------|------|
| `FROM python:3.13` | Utilise l'image officielle Python 3.13 comme base |
| `WORKDIR /app` | Définit `/app` comme répertoire de travail dans le conteneur |
| `COPY requirements.txt ./` | Copie le fichier des dépendances dans le conteneur |
| `RUN pip install --no-cache-dir -r requirements.txt` | Installe les dépendances Python sans cache |
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

---