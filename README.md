# Orion MicroCRM

Application full-stack de demonstration pour Orion, composee d'un backend Java Spring Boot 3 et d'un frontend Angular 17.

L'ancien README fourni avec le projet est conserve dans `README.original.md`.

## Architecture

- `back/` : API REST Spring Boot, Java 17, Gradle, JPA et base HSQLDB embarquee.
- `front/` : application Angular 17 servie en developpement par Angular CLI et en production par Caddy.
- `Dockerfile` : images multi-stage pour le frontend, le backend et le mode standalone.
- `docker-compose.yml` : orchestration locale des services `front` et `back`.
- `.github/workflows/` : workflows GitHub Actions pour CI, controles periodiques et deploiement.

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

- Frontend : `http://localhost`
- Backend : `http://localhost:8080`

Le frontend transmet les requetes `/api` au backend par l'intermediaire de Caddy. Cette configuration evite de coder l'adresse du serveur dans l'application Angular et reste valable sur un poste local comme sur une VM.

Verifier l'etat :

```bash
docker compose ps
docker compose logs -f
```

Les services `front` et `back` doivent apparaitre avec l'etat `healthy`.

Arreter :

```bash
docker compose down
```

## Monitoring local ELK

La stack ELK locale est definie dans `docker-compose-elk.yml` et separee du pipeline CI/CD. Elle lance Elasticsearch, Logstash, Kibana et un conteneur d'initialisation qui importe automatiquement le dashboard Kibana present dans `monitoring/kibana/orion-microcrm-dashboard.ndjson`.

### Lancer la stack ELK

Prevoir environ 4 Go de RAM disponibles pour Docker.

```bash
docker compose -f docker-compose-elk.yml up -d
```

Services exposes :

- Elasticsearch : `http://localhost:9200`
- Logstash GELF : `udp://localhost:12201`
- Logstash TCP JSON : `localhost:5000`
- Logstash Beats : `localhost:5044`
- Kibana : `http://localhost:5601`

### Envoyer les logs applicatifs

L'application Docker envoie les logs du backend Spring Boot et du frontend vers Logstash via le driver Docker `gelf`. Lancez d'abord ELK, puis l'application :

```bash
docker compose -f docker-compose-elk.yml up -d
docker compose -f docker-compose.yml -f docker-compose.logging.yml up --build -d
```

Le backend utilise `back/src/main/resources/logback-spring.xml` pour produire des logs JSON. Logstash centralise ensuite les evenements dans l'index `orion-microcrm-logs-*` avec les champs `application`, `environment`, `service` et `log_level`.

### Consulter le dashboard

Dans Kibana, ouvrez `Dashboards`, puis `Orion MicroCRM - Logs locaux`. Le dashboard contient des visualisations de volume de logs et d'erreurs applicatives. Le data view `orion-microcrm-logs-*` est importe avec le dashboard.

Pour arreter uniquement ELK :

```bash
docker compose -f docker-compose-elk.yml down
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
- scan Trivy des images backend et frontend avec blocage sur les vulnérabilités `HIGH` et `CRITICAL` corrigées ;
- publication des images validées dans un registre d'images sur push vers `main` ;
- validation des manifests K3s avec `kubectl kustomize` ;
- validation de `docker-compose.yml` ;
- demarrage de l'application via Docker Compose pour verifier la conteneurisation.

Par défaut, le registre utilisé est GHCR. Il reste paramétrable avec les variables GitHub Actions suivantes :

```text
CONTAINER_REGISTRY=ghcr.io
CONTAINER_NAMESPACE=<owner>
CONTAINER_REGISTRY_USERNAME=<user optionnel>
```

Pour GHCR, aucun token personnel n'est nécessaire : le workflow utilise `GITHUB_TOKEN`. Pour un autre registre, ajoutez le secret `CONTAINER_REGISTRY_TOKEN` et, si nécessaire, la variable `CONTAINER_REGISTRY_USERNAME`.

Les images publiees par la CI sont :

```text
<registry>/<namespace>/orion-microcrm-back:<sha-court>
<registry>/<namespace>/orion-microcrm-back:latest
<registry>/<namespace>/orion-microcrm-front:<sha-court>
<registry>/<namespace>/orion-microcrm-front:latest
```

La publication utilise une authentification injectee par GitHub Actions et la permission `packages: write` lorsque GHCR est utilise. Aucun token personnel n'est stocke dans le depot.

### Scan Trivy local

Pour reproduire le controle de securite des images localement :

```bash
docker build --target back -t orion-microcrm-back:ci .
docker build --target front -t orion-microcrm-front:ci .

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD/.trivyignore:/project/.trivyignore:ro" \
  -w /project \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  orion-microcrm-back:ci

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD/.trivyignore:/project/.trivyignore:ro" \
  -w /project \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  orion-microcrm-front:ci
```

Pour verifier les images publiees apres une CI verte sur `main` :

```bash
echo "$CONTAINER_REGISTRY_TOKEN" | docker login <registry> -u <user> --password-stdin
docker pull <registry>/<namespace>/orion-microcrm-back:latest
docker pull <registry>/<namespace>/orion-microcrm-front:latest
```

Le fichier `.trivyignore` contient uniquement les exceptions temporaires justifiees pour le runtime Caddy officiel. Il doit etre relu a chaque controle hebdomadaire et nettoye des qu'une image Caddy corrigee est disponible.

### Déploiement K3s

Le dossier `k8s/` fournit une mise en oeuvre Kubernetes légère avec K3s :

- `namespace.yml` : namespace `orion-microcrm` ;
- `backend.yml` : Deployment et Service du backend Spring Boot ;
- `frontend.yml` : Deployment et Service du frontend Caddy/Angular ;
- `ingress.yml` : exposition locale via Traefik sur `microcrm.local` ;
- `kustomization.yml` : point d'entrée `kubectl apply -k k8s`.

Validation des manifests :

```bash
kubectl kustomize k8s
kubectl apply -k k8s --dry-run=client
```

Déploiement local avec les images construites sur la machine :

```bash
docker build --target back -t orion-microcrm-back:latest .
docker build --target front -t orion-microcrm-front:latest .
docker save orion-microcrm-back:latest | sudo k3s ctr images import -
docker save orion-microcrm-front:latest | sudo k3s ctr images import -

kubectl apply -k k8s
kubectl -n orion-microcrm rollout status deployment/back
kubectl -n orion-microcrm rollout status deployment/front
kubectl -n orion-microcrm get pods,svc,ingress
```

Vérification par port-forward :

```bash
kubectl -n orion-microcrm port-forward svc/front 8088:8080
curl --fail http://localhost:8088/
curl --fail http://localhost:8088/api/persons
```

Utilisation des images publiées dans le registre paramétrable :

```bash
kubectl -n orion-microcrm set image deployment/back back=<registry>/<namespace>/orion-microcrm-back:<tag>
kubectl -n orion-microcrm set image deployment/front front=<registry>/<namespace>/orion-microcrm-front:<tag>
```

Nettoyage :

```bash
kubectl delete -k k8s
```

Les commandes détaillées de manipulation et de diagnostic sont documentées dans `k8s/README.md`.

### Controles periodiques

Le workflow `periodic-checks.yml` s'execute chaque lundi a 05:00 UTC et peut etre lance manuellement.

Il realise :

- tests backend ;
- tests frontend ;
- audit npm des dépendances de production avec blocage au seuil `critical` ;
- validation Docker Compose.

### Deploiement

Le workflow `deploy.yml` utilise un runner GitHub Actions auto-heberge sur la VM cible.

Le staging est declenche automatiquement apres une CI reussie sur `main`. La production reste declenchee manuellement depuis GitHub Actions et peut etre protegee par une approbation d'environnement.

Le workflow recupere exactement le commit valide par la CI, reconstruit les images sur la VM, demarre les services avec Docker Compose, attend les healthchecks et execute deux smoke tests HTTP.

Le déploiement a été validé sur la VM Rocky Linux `Host-001` avec les services `front` et `back` en état `healthy`.

La VM cible doit disposer d'un runner portant les labels :

```text
self-hosted, linux, x64
```

Elle doit egalement fournir Git, Docker, Docker Compose et un acces Docker sans `sudo` pour l'utilisateur du runner.

## Secrets GitHub requis

Pour SonarCloud :

- `SONAR_TOKEN`

Le deploiement par runner auto-heberge ne necessite aucun secret SSH. Pour changer de cible, il suffit d'enregistrer un autre runner compatible et d'adapter les labels `runs-on` du workflow.

### Releases et versioning semantique

Le workflow `release.yml` publie une release GitHub lors du push d'un tag compatible :

- `vMAJOR.MINOR.PATCH` pour une version stable ;
- `vMAJOR.MINOR.PATCH-rc.N` pour une release candidate.

La politique retenue suit SemVer :

- `MAJOR` : changement incompatible ;
- `MINOR` : nouvelle fonctionnalite compatible ;
- `PATCH` : correction compatible.

Une release candidate n'est pas creee pour chaque commit. La creation du tag reste une action humaine realisee apres une CI verte. Aucune branche de release specifique n'est necessaire pour ce projet.

Exemple de release de test :

```bash
git tag -a v0.1.0-rc.1 -m "Release candidate v0.1.0-rc.1"
git push origin v0.1.0-rc.1
```

Le workflow reconstruit et teste le JAR et le frontend, verifie le demarrage du backend, puis publie :

- `orion-microcrm-back-<version>.jar` ;
- `orion-microcrm-front-<version>.tar.gz` ;
- `SHA256SUMS`.

## SonarCloud

La configuration est centralisee dans `sonar-project.properties`.

Parametres attendus :

- organization : `msm-oc-projects`
- project key : `msm-oc-projects_msm-projet-07-fullstack`

Si le projet SonarCloud utilise une autre cle, adaptez `sonar-project.properties`.

## Plan de securite

- Analyse statique SonarCloud a chaque push et pull request.
- Audit npm hebdomadaire avec blocage sur vulnerabilites elevees.
- Scan Trivy des images Docker backend et frontend dans la CI.
- Mise a jour backend vers Spring Boot `3.5.14` avec Tomcat `10.1.55` pour corriger les vulnerabilites detectees par Trivy.
- Secrets stockes dans GitHub Secrets, jamais dans le depot.
- Publication dans un registre paramétrable ; GHCR utilise `GITHUB_TOKEN` et la permission limitee `packages: write`.
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
