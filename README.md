# Orion MicroCRM

Application full-stack de demonstration pour Orion, composee d'un backend Java Spring Boot 3 et d'un frontend Angular 17.

L'ancien README fourni avec le projet est conserve dans `README.original.md`.

## Architecture

- `back/` : API REST Spring Boot, Java 17, Gradle, JPA et base HSQLDB embarquee.
- `front/` : application Angular 17 servie en developpement par Angular CLI et en production par Caddy.
- `Dockerfile` : images multi-stage pour le frontend, le backend et le mode standalone.
- `docker-compose.yml` : orchestration locale des services `front` et `back`.
- `.github/workflows/` : workflows GitHub Actions pour CI, controles periodiques et deploiement.
- `docs/technical-documentation.md` : documentation technique du pipeline, du deploiement, du testing periodique et du plan de securite.

## Prerequis

- Java 17
- Node.js 20 et npm
- Docker et Docker Compose
- Google Chrome ou Chromium pour les tests Angular

## Lancement local depuis les sources

### Backend

```bash
cd back
./gradlew bootRun
```

API disponible sur `http://localhost:8080`.

### Frontend

```bash
cd front
npm ci
npm start
```

Application disponible sur `http://localhost:4200`.

## Tests

### Backend

```bash
cd back
./gradlew clean test
```

### Frontend

Sous Linux ou WSL avec Chrome installe dans Linux :

```bash
cd front
export CHROME_BIN=/usr/bin/google-chrome
npm ci
npm run test:ci
```

Sous Windows PowerShell :

```powershell
cd front
$env:CHROME_BIN="C:\Program Files\Google\Chrome\Application\chrome.exe"
npm.cmd run test:ci
```

## Docker

### Construire les images

```bash
docker build --target back -t orion-microcrm-back:latest .
docker build --target front -t orion-microcrm-front:latest .
```

### Lancer avec Docker Compose

```bash
docker compose up --build -d
```

Services exposes :

- Frontend : `http://localhost` et `https://localhost`
- Backend : `http://localhost:8080`

Verifier l'etat :

```bash
docker compose ps
docker compose logs -f
```

Arreter :

```bash
docker compose down
```

## Pipeline CI/CD

Les workflows GitHub Actions sont situes dans `.github/workflows/`.

### CI

Le workflow `ci.yml` s'execute sur push et pull request vers `main`.

Il realise :

- build et tests backend avec Gradle ;
- generation de couverture Jacoco ;
- installation frontend avec `npm ci` ;
- tests Angular en Chrome Headless avec couverture LCOV ;
- build Angular ;
- analyse SonarCloud ;
- build des images Docker ;
- validation de `docker-compose.yml` ;
- demarrage de l'application via Docker Compose pour verifier la conteneurisation.

### Controles periodiques

Le workflow `periodic-checks.yml` s'execute chaque lundi a 05:00 UTC et peut etre lance manuellement.

Il realise :

- tests backend ;
- tests frontend ;
- audit npm avec seuil `high` ;
- validation Docker Compose.

### Deploiement

Le workflow `deploy.yml` est declenche manuellement depuis GitHub Actions.

Il se connecte au serveur cible en SSH, met a jour le depot sur `origin/main`, reconstruit les images et redemarre les services avec Docker Compose.

## Secrets GitHub requis

Pour SonarCloud :

- `SONAR_TOKEN`

Pour le deploiement :

- `DEPLOY_HOST` : hote cible.
- `DEPLOY_USER` : utilisateur SSH.
- `DEPLOY_SSH_KEY` : cle privee SSH.
- `DEPLOY_PATH` : chemin du depot clone sur le serveur.

## SonarCloud

La configuration est centralisee dans `sonar-project.properties`.

Parametres attendus :

- organization : `msm-oc-projects`
- project key : `msm-oc-projects_msm-projet-07-fullstack`

Si le projet SonarCloud utilise une autre cle, adaptez `sonar-project.properties`.

## Plan de securite

- Analyse statique SonarCloud a chaque push et pull request.
- Audit npm hebdomadaire avec blocage sur vulnerabilites elevees.
- Secrets stockes dans GitHub Secrets, jamais dans le depot.
- Images Docker construites depuis des images officielles et limitees aux artefacts necessaires.
- Exposition limitee aux ports applicatifs requis.
- Bonnes pratiques OWASP : validation des entrees, logs sans secrets, principe du moindre privilege et mises a jour regulieres.

## Plan de sauvegarde

L'application utilise actuellement une base HSQLDB embarquee adaptee a la demonstration. Pour un environnement durable :

- sauvegarde quotidienne de la base applicative ;
- retention de 7 sauvegardes quotidiennes, 4 hebdomadaires et 12 mensuelles ;
- test de restauration mensuel ;
- stockage chiffre hors serveur applicatif ;
- definition d'un RPO/RTO cible dans la documentation d'exploitation.

## Documentation technique

La documentation detaillee du pipeline, du deploiement, du plan de securite et du plan de testing periodique se trouve dans :

```text
docs/technical-documentation.md
```
