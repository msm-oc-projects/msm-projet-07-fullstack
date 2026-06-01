# Documentation technique - Orion MicroCRM

**Titre du document :** Documentation technique - Orion MicroCRM  
**Auteur :** [A completer]  
**Option choisie :** Option B - Scenario Orion  
**Date :** 26 mai 2026  
**Version :** 1.0  

## 1. Introduction

### 1.1 Contexte du projet

Orion souhaite moderniser son processus de livraison pour l'application interne MicroCRM. Le projet est une application full-stack de demonstration, composee d'un backend Java Spring Boot et d'un frontend Angular. Avant industrialisation, les etapes de construction, de test, de verification qualite et de lancement etaient essentiellement manuelles.

Cette situation presente plusieurs limites : risque d'oubli lors des livraisons, manque de reproductibilite entre les environnements, visibilite reduite sur la qualite du code, et absence de controle automatise avant integration. La mise en place d'un pipeline CI/CD vise donc a fiabiliser la livraison et a poser une base exploitable pour les futures evolutions.

Le depot GitHub contient le code source du backend, du frontend, les fichiers Docker, les workflows GitHub Actions et la documentation technique. La solution cible doit permettre de construire, tester, analyser et deployer l'application avec un minimum d'interventions manuelles.

### 1.2 Objectifs de l'industrialisation

Les objectifs principaux sont les suivants :

- automatiser la construction du backend et du frontend ;
- executer les tests a chaque changement important ;
- analyser la qualite et la securite du code avec SonarCloud ;
- verifier la conteneurisation avec Docker et Docker Compose ;
- documenter les procedures de lancement, de deploiement et de maintenance ;
- definir un plan de tests periodiques ;
- definir un plan de securite et de sauvegarde ;
- preparer une base de deploiement reproductible.

L'industrialisation doit aussi rendre le projet plus lisible pour l'equipe technique. Les developpeurs doivent pouvoir comprendre rapidement comment lancer l'application, comment executer les tests, comment lire les resultats de CI et comment declencher un deploiement.

### 1.3 Technologies principales

Les technologies utilisees sont :

- Java 17 ;
- Spring Boot 3 ;
- Gradle ;
- Angular 17 ;
- Node.js 20 et npm ;
- Karma et Jasmine pour les tests frontend ;
- JUnit et Spring Boot Test pour les tests backend ;
- Docker ;
- Docker Compose ;
- GitHub Actions ;
- SonarCloud ;
- Elastic Stack locale : Elasticsearch, Logstash, Kibana ;
- Caddy pour servir le frontend en production.

Le projet est organise en monorepo. Le backend est situe dans `back/`, le frontend dans `front/`, et les elements d'industrialisation sont situes a la racine du depot ou dans `.github/workflows/`.

### 1.4 Presentation rapide du pipeline CI/CD

Le pipeline mis en place repose sur GitHub Actions. Il est decoupe en trois workflows :

- `ci.yml` : integration continue declenchee sur push et pull request vers `main` ;
- `periodic-checks.yml` : controles periodiques hebdomadaires ;
- `deploy.yml` : deploiement continu via SSH et Docker Compose, automatique vers `staging` apres une CI verte sur `main`, et manuel vers `staging` ou `production`.
- `release.yml` : creation d'une release GitHub versionnee a partir d'un tag SemVer.

Le pipeline CI execute les tests backend, les tests frontend, le build des deux parties, l'analyse SonarCloud, le build des images Docker et une validation de l'orchestration Docker Compose. Le deploiement staging peut etre declenche automatiquement apres succes de la CI sur `main`. Le deploiement production reste manuel afin de conserver un controle humain avant modification de l'environnement cible.

### 1.5 Plans prealables a l'automatisation

Avant toute configuration technique du pipeline, les regles suivantes cadrent l'automatisation attendue. Elles definissent les controles a executer, leur moment d'execution et l'objectif recherche. La mise en oeuvre GitHub Actions, Docker et SonarCloud doit respecter ces principes afin d'eviter une automatisation trop large, inutile ou deconnectee du contexte du projet.

#### 1.5.1 Plan de testing periodique

Le projet etant compose d'un backend Spring Boot et d'un frontend Angular, les tests automatises doivent couvrir les deux perimetres.

Pour le backend, les controles attendus sont :

- tests unitaires Java ;
- tests d'integration Spring Boot lorsque le comportement applicatif le justifie ;
- tests repository pour verifier les acces aux donnees ;
- generation d'un rapport de couverture Jacoco.

Pour le frontend, les controles attendus sont :

- tests unitaires Angular ;
- execution Karma/Jasmine en navigateur headless ;
- generation d'un rapport de couverture LCOV ;
- build Angular afin de verifier que l'application reste compilable.

Les tests doivent etre executes automatiquement aux moments suivants :

| Moment | Tests et controles | Objectif |
| --- | --- | --- |
| Pull request vers `main` | Tests backend, tests frontend, build frontend, analyse SonarCloud, validation Docker | Bloquer l'integration d'un changement regressif ou de qualite insuffisante |
| Push vers `main` | Meme niveau de controle que sur pull request | Verifier que la branche principale reste stable et deployable |
| Controle periodique hebdomadaire | Tests backend, tests frontend, audit npm, validation Docker Compose | Detecter les regressions liees aux dependances, a l'environnement ou a une derive non visible au quotidien |
| Avant deploiement | Verification du dernier pipeline vert, des resultats SonarCloud et de la validation Docker Compose | Eviter le deploiement d'une version non testee ou non conforme |

Les objectifs associes aux tests sont :

- validation fonctionnelle des principales regles applicatives ;
- non-regression lors des evolutions ;
- verification de la qualite technique par la compilation, les tests et la couverture ;
- detection rapide des erreurs avant fusion dans `main` ;
- production de rapports exploitables pour comprendre les echecs.

Cette strategie reste volontairement adaptee au contexte du projet. Elle ne prevoit pas encore de tests end-to-end complets, car l'objectif prioritaire est d'abord de securiser les builds front/back, la qualite du code et la conteneurisation. Les tests end-to-end pourront etre ajoutes dans une iteration ulterieure.

#### 1.5.2 Plan de securite

SonarCloud joue le role de controle qualite et securite automatise. Son analyse doit etre executee dans la CI apres generation des rapports de couverture afin de consolider les resultats Java, TypeScript, Jacoco et LCOV.

Les problemes surveilles sont :

- vulnerabilites detectees dans le code ;
- bugs susceptibles de provoquer un comportement incorrect ;
- code smells et dette technique ;
- duplications ;
- complexite excessive ;
- couverture de tests insuffisante ;
- non-respect du quality gate.

La CI doit egalement appliquer les bonnes pratiques suivantes :

- stocker les secrets exclusivement dans GitHub Secrets ;
- ne jamais afficher les secrets dans les logs ;
- utiliser des permissions minimales dans les workflows ;
- eviter l'execution de l'analyse SonarCloud pour Dependabot si les secrets ne sont pas disponibles ;
- installer les dependances frontend avec `npm ci` pour garantir une installation reproductible ;
- utiliser le wrapper Gradle du projet pour eviter une difference de version entre environnements ;
- executer un audit npm periodique avec un seuil bloquant sur les vulnerabilites elevees ;
- maintenir les actions GitHub et les images Docker de base ;
- exclure des images Docker les dossiers inutiles et les fichiers sensibles via `.dockerignore`.

Les vulnerabilites critiques ou elevees doivent etre traitees avant fusion ou avant deploiement. Les alertes moins critiques peuvent etre planifiees, mais elles doivent rester visibles dans SonarCloud ou dans les rapports de CI.

#### 1.5.3 Principes de conteneurisation et de deploiement

Le Dockerfile existant sert a produire des images reproductibles pour les deux parties de l'application. Il est multi-stage afin de separer les etapes de compilation des images d'execution.

Les principes retenus sont :

- construire le frontend Angular dans un stage Node.js, puis servir les fichiers statiques avec l'image officielle Caddy Alpine ;
- construire le backend Spring Boot dans un stage Gradle/JDK, puis executer le JAR dans une image Java runtime plus legere ;
- exposer uniquement les ports necessaires au lancement local, soit `80` pour le frontend et `8080` pour le backend ;
- ne pas embarquer de secrets dans les images ;
- executer le conteneur backend avec un utilisateur non-root.

Le fichier `docker-compose.yml` a pour role d'orchestrer localement ou sur un serveur simple les services `front` et `back`. Il permet de reconstruire les images, demarrer les conteneurs, exposer les ports et verifier leur etat via des healthchecks. Il constitue donc le socle de validation de la conteneurisation dans la CI et le support de deploiement dans le scenario actuel.

La strategie de deploiement retenue est progressive :

- deploiement staging automatique apres succes du workflow CI sur `main` ;
- deploiement manuel declenche par `workflow_dispatch` pour `staging` ou `production` ;
- connexion SSH au serveur cible ;
- recuperation de la derniere version validee de `main` ;
- validation de la configuration Docker Compose ;
- reconstruction des images sur le serveur ;
- redemarrage des services avec Docker Compose ;
- verification des conteneurs et des logs apres deploiement.

A court terme, la publication d'images dans un registre Docker peut etre ajoutee pour eviter de reconstruire sur le serveur cible. Dans ce modele, la CI publierait des images versionnees apres validation, puis le deploiement ne ferait que tirer les images approuvees et relancer Compose. Pour le scenario actuel, la reconstruction sur serveur reste plus simple et limite les secrets necessaires. Pour une production plus mature, il faudrait aussi prevoir une strategie de rollback, une gestion d'environnements separes et un scan des images.

## 2. Etapes de mise en oeuvre du pipeline CI/CD

### 2.1 Structure du pipeline

Le workflow principal est `.github/workflows/ci.yml`. Il s'execute sur trois evenements :

- `push` vers la branche `main` ;
- `pull_request` vers la branche `main`.
- `workflow_dispatch` pour relancer manuellement une verification complete depuis GitHub Actions.

La structure du pipeline est organisee en plusieurs jobs :

- `backend` : build et tests du backend ;
- `frontend` : installation, tests et build du frontend ;
- `sonarcloud` : analyse qualite et securite ;
- `docker` : validation de la conteneurisation.

L'ordre d'execution suit une logique de reduction du risque. Les jobs backend et frontend sont lances en premier, car ils valident le code applicatif. L'analyse SonarCloud depend ensuite de ces jobs afin de s'appuyer sur les rapports de couverture. Le job Docker depend egalement des validations applicatives, car il est inutile de construire les images si les tests echouent.

Cette organisation permet de separer clairement les responsabilites. Un echec backend n'est pas confondu avec un echec frontend ou Docker. Les logs GitHub Actions sont donc plus simples a lire et a exploiter.

### 2.2 Etapes principales du workflow CI

Le job backend realise les actions suivantes :

1. recuperation du code source ;
2. installation de Java 17 via `actions/setup-java` ;
3. activation du cache Gradle ;
4. execution de `./gradlew clean build` ;
5. publication des rapports de tests et de couverture comme artefacts.

Le projet backend utilise Gradle et non Maven. Le pipeline s'appuie donc sur le wrapper `./gradlew` fourni par le depot afin de garantir une execution reproductible sans dependance a une installation locale de Maven ou de Gradle sur le runner.

Le job frontend realise les actions suivantes :

1. recuperation du code source ;
2. installation de Node.js 20 via `actions/setup-node` ;
3. activation du cache npm ;
4. installation propre des dependances avec `npm ci` ;
5. execution des tests Angular en mode headless avec `npm run test:ci` ;
6. build Angular avec `npm run build` ;
7. publication de la couverture frontend.

Le job SonarCloud realise les actions suivantes :

1. recuperation complete de l'historique Git avec `fetch-depth: 0` ;
2. installation de Java et Node.js ;
3. generation de la couverture backend Jacoco ;
4. generation de la couverture frontend LCOV ;
5. execution de `SonarSource/sonarqube-scan-action@v7` ;
6. attente du quality gate SonarCloud afin de faire echouer la CI si le niveau qualite/securite attendu n'est pas respecte.

Le job Docker realise les actions suivantes :

1. configuration de Docker Buildx ;
2. build de l'image backend ;
3. build de l'image frontend ;
4. validation syntaxique de `docker-compose.yml` ;
5. demarrage de l'application avec Docker Compose ;
6. verification de l'etat des conteneurs ;
7. arret et nettoyage des services.

### 2.3 Justification du choix des actions GitHub

Les actions utilisees sont des actions officielles ou largement maintenues :

- `actions/checkout@v6` : recuperation du code source ;
- `actions/setup-java@v5` : installation de Java et cache Gradle ;
- `actions/setup-node@v6` : installation de Node.js et cache npm ;
- `actions/upload-artifact@v7` : conservation des rapports ;
- `docker/setup-buildx-action@v4` : preparation des builds Docker modernes ;
- `docker/build-push-action@v7` : build des images Docker ;
- `SonarSource/sonarqube-scan-action@v7` : analyse SonarCloud.

Ces actions sont choisies pour leur maintenance active, leur integration native avec GitHub Actions et leur lisibilite. Les versions sont fixees par version majeure afin de limiter les regressions tout en conservant les mises a jour compatibles. Les permissions du workflow sont limitees a `contents: read` et `pull-requests: read`, car la CI doit lire le code et les pull requests sans publier de packages ni modifier le depot.

### 2.4 Scripts d'automatisation

Les scripts principaux sont definis dans les outils de build existants.

Pour le backend :

```bash
cd back
./gradlew clean build
./gradlew test jacocoTestReport
```

`clean build` compile le code, execute les tests et produit le JAR. `test jacocoTestReport` genere les rapports necessaires a SonarCloud.

Pour le frontend :

```bash
cd front
npm ci
npm run test:ci
npm run build
```

Le script `test:ci` a ete ajoute dans `front/package.json`. Il lance les tests Angular sans mode watch, avec Chrome Headless et generation de couverture :

```bash
ng test --watch=false --browsers=ChromeHeadlessNoSandbox --code-coverage
```

Ce mode est adapte a la CI car il se termine automatiquement apres execution des tests.

Pour Docker :

```bash
docker build --target back -t orion-microcrm-back:latest .
docker build --target front -t orion-microcrm-front:latest .
docker compose up --build -d
docker compose down
```

Ces commandes permettent de verifier que l'application peut etre reconstruite et lancee depuis un environnement standard.

### 2.5 Reproductibilite

La reproductibilite repose sur plusieurs principes :

- utilisation de `npm ci` au lieu de `npm install` dans la CI ;
- utilisation du wrapper Gradle fourni par le projet ;
- declaration des versions Java et Node.js dans les workflows ;
- build Docker depuis un Dockerfile unique ;
- orchestration Docker Compose declaree dans le depot ;
- secrets stockes dans GitHub Secrets et jamais dans le code source.

Pour relancer le pipeline, il suffit de pousser un commit vers `main`, d'ouvrir une pull request vers `main`, ou de relancer manuellement un workflow depuis l'interface GitHub Actions.

Les secrets ne sont jamais affiches dans la documentation. Seuls leurs noms sont documentes :

- `SONAR_TOKEN` ;
- `DEPLOY_HOST` ;
- `DEPLOY_USER` ;
- `DEPLOY_SSH_KEY` ;
- `DEPLOY_PATH`.

## 3. Plan de conteneurisation et de deploiement

### 3.1 Dockerfile

Le projet utilise un `Dockerfile` multi-stage. Cette approche permet de separer les etapes de build des images finales. Les dependances de compilation ne sont pas conservees dans les images d'execution, ce qui reduit la taille et la surface d'attaque.

Les stages principaux sont :

- `front-build` : compilation Angular ;
- `back-build` : compilation Spring Boot ;
- `front` : image runtime frontend avec Caddy ;
- `back` : image runtime backend avec Java 17.

Le stage frontend utilise l'image officielle `node:20-alpine`. Il copie d'abord `package.json` et `package-lock.json`, execute `npm ci`, puis copie le reste du code frontend avant `ng build --configuration production`. Cette organisation exploite mieux le cache Docker tout en garantissant une installation reproductible. Les fichiers generes sont copies dans l'image officielle `caddy:2-alpine`, servie depuis `/usr/share/caddy`.

Le stage backend utilise l'image officielle `gradle:8-jdk17-alpine` pour compiler l'application avec le wrapper Gradle du projet. Le JAR produit est ensuite copie dans l'image officielle `eclipse-temurin:17-jre-alpine`. L'image runtime backend cree un utilisateur `app` et execute l'application avec cet utilisateur afin d'eviter une execution applicative en root.

Les ports exposes sont :

- `80` pour le frontend ;
- `8080` pour le backend.

Une correction importante a ete apportee : l'image backend expose maintenant le port `8080`, coherent avec Spring Boot, au lieu d'un port frontend.

### 3.2 Optimisations Docker

Les optimisations simples mises en place sont :

- usage du multi-stage build ;
- utilisation d'images officielles et minimales : `node:20-alpine`, `gradle:8-jdk17-alpine`, `caddy:2-alpine` et `eclipse-temurin:17-jre-alpine` ;
- utilisation d'images runtime plus petites ;
- installation des paquets Alpine avec `--no-cache` ;
- exclusion des dossiers inutiles via `.dockerignore` ;
- absence de secrets dans les images ;
- conservation uniquement des artefacts necessaires a l'execution ;
- execution du backend avec un utilisateur non-root.

Le fichier `.dockerignore` exclut notamment :

- `.git` ;
- `.github` ;
- `front/node_modules` ;
- `front/dist` ;
- `front/.angular` ;
- `front/coverage` ;
- `back/build` ;
- `back/.gradle` ;
- les fichiers `.deb` ;
- les fichiers `.env` et `.env.*`, sauf `.env.example`.

Le dossier `.github` est ignore par Docker uniquement. Il reste suivi par Git, car GitHub Actions en a besoin pour executer les workflows.

Un scan d'image avec un outil dedie comme Twistlock, Trivy ou Docker Scout est recommande avant une mise en production. Dans le cadre actuel, la CI valide deja le build des images et Docker Compose, mais le scan de vulnerabilites d'images reste une amelioration a ajouter.

### 3.3 docker-compose.yml

Le fichier `docker-compose.yml` definit deux services :

- `back` : service Spring Boot ;
- `front` : service Caddy servant l'application Angular.

Le service backend est construit depuis le target Docker `back` et expose le port `8080`. Le service frontend est construit depuis le target `front` et expose le port `80`. Le HTTPS pourra etre ajoute dans une configuration de production avec un nom de domaine et une politique TLS adaptee.

Chaque service dispose d'un healthcheck simple. Ces controles permettent de verifier que les services repondent apres demarrage. En environnement de production, il serait preferable d'ajouter un endpoint Spring Boot Actuator dedie, par exemple `/actuator/health`.

Commande de lancement local :

```bash
docker compose up --build -d
```

Commande de verification :

```bash
docker compose ps
docker compose logs -f
```

Commande d'arret :

```bash
docker compose down
```

### 3.4 Strategie de deploiement

Le deploiement est gere par le workflow `.github/workflows/deploy.yml`. Il peut etre declenche de deux manieres :

- automatiquement apres succes du workflow `CI` sur la branche `main`, pour l'environnement `staging` ;
- manuellement via `workflow_dispatch`, pour l'environnement `staging` ou `production`.

Ce choix garde une automatisation utile pour tester la chaine de deploiement en staging, tout en conservant une validation humaine avant modification de la production.

Le workflow se connecte en SSH au serveur cible, se place dans le dossier du depot, recupere la derniere version de `main`, valide Docker Compose, reconstruit les images et redemarre les services avec Docker Compose.

Le serveur cible doit disposer de :

- Git ;
- Docker ;
- Docker Compose ;
- un utilisateur dedie au deploiement ;
- un acces SSH configure ;
- un clone du depot dans le chemin declare par `DEPLOY_PATH`.

Les secrets utilises par le workflow sont stockes dans GitHub Secrets ou dans les secrets d'environnement GitHub. Aucune valeur sensible n'est declaree dans le depot. Le workflow supprime egalement la cle SSH temporaire du runner a la fin du job.

Les commandes importantes du deploiement sont :

| Commande | Objectif | Definition | Moment d'execution |
| --- | --- | --- | --- |
| `ssh-keyscan -H "${{ secrets.DEPLOY_HOST }}"` | Ajouter l'hote cible dans `known_hosts` sans exposer l'adresse dans le code | `.github/workflows/deploy.yml` | CD, avant connexion SSH |
| `git fetch origin main` | Recuperer les references recentes de la branche principale | `.github/workflows/deploy.yml` | CD, sur le serveur cible |
| `git checkout main` | Se placer sur la branche de deploiement attendue | `.github/workflows/deploy.yml` | CD, sur le serveur cible |
| `git pull --ff-only origin main` | Mettre a jour le serveur sans reecriture destructrice de l'historique local | `.github/workflows/deploy.yml` | CD, sur le serveur cible |
| `docker compose config` | Valider la syntaxe et la configuration Compose avant redemarrage | `.github/workflows/deploy.yml` et `docker-compose.yml` | CD et verification locale |
| `docker compose up --build -d --remove-orphans` | Reconstruire les images et relancer les services en arriere-plan | `.github/workflows/deploy.yml`, `Dockerfile`, `docker-compose.yml` | CD et lancement local |
| `docker compose ps` | Verifier l'etat des conteneurs apres redemarrage | `.github/workflows/deploy.yml` | CD, apres relance |
| `docker compose logs --tail=100` | Rendre les derniers logs visibles dans GitHub Actions | `.github/workflows/deploy.yml` | CD, apres relance |
| `docker image prune -f` | Nettoyer les images non utilisees pour limiter l'occupation disque | `.github/workflows/deploy.yml` | CD, fin de deploiement |

La strategie actuelle correspond a un deploiement simple adapte au scenario. Pour une production plus avancee, il serait pertinent d'ajouter un registre d'images, une strategie blue/green ou un rollback automatise.

### 3.5 Automatisation des releases

Le workflow `.github/workflows/release.yml` automatise la creation des releases GitHub a partir d'un tag SemVer stable. Il est declenche lors d'un push de tag au format `vMAJOR.MINOR.PATCH`, par exemple `v1.0.0`, ou manuellement via `workflow_dispatch` en indiquant un tag existant.

La politique de versioning retenue suit SemVer :

- `MAJOR` : changement incompatible ou rupture d'API/comportement ;
- `MINOR` : ajout fonctionnel compatible ;
- `PATCH` : correction compatible sans nouvelle fonctionnalite majeure.

Les tags acceptes par le workflow sont volontairement limites au format stable `vX.Y.Z`. Les versions de type release candidate, par exemple `v1.0.0-rc.1`, ne sont pas publiees automatiquement par ce workflow afin de garder un processus simple. Une release de test peut etre realisee avec un tag stable de faible version, par exemple `v0.1.0`, puis supprimee si elle ne doit pas rester visible.

La release implique une action humaine : la creation et le push du tag Git. Il n'y a pas de release candidate creee a chaque commit, car cela produirait trop de bruit et ne correspond pas au niveau de maturite du projet. Il n'est pas prevu de creer une branche par release dans ce scenario ; la branche `main` reste la source de verite, et les tags identifient les versions publiees.

Le workflow realise les etapes suivantes :

1. validation stricte du tag SemVer ;
2. checkout du code correspondant au tag ;
3. build backend avec Gradle ;
4. build frontend avec npm ;
5. packaging du JAR backend et du build Angular ;
6. publication des artefacts dans GitHub Actions ;
7. creation de la GitHub Release avec notes generees automatiquement.

Les artefacts publies sont :

- `orion-microcrm-back-<version>.jar` : JAR Spring Boot construit depuis `back/build/libs/` ;
- `orion-microcrm-front-<version>.tar.gz` : archive du build Angular produit dans `front/dist/microcrm/browser`.

Les artefacts ne doivent contenir aucun secret. Le backend est publie sous forme de JAR applicatif, et le frontend sous forme de fichiers statiques. Les dossiers locaux, dependances et fichiers sensibles restent exclus par `.gitignore`, `.dockerignore` et par le packaging explicite du workflow.

## 4. Plan de testing periodique

### 4.1 Types de tests automatises

Les tests automatises couvrent deux parties principales.

Pour le backend :

- tests unitaires ;
- tests d'integration Spring Boot ;
- tests repository ;
- generation de couverture Jacoco.

Pour le frontend :

- tests unitaires Angular ;
- execution via Karma/Jasmine ;
- navigateur Chrome Headless ;
- generation de couverture LCOV.

Les controles de securite sont assures par :

- analyse SonarCloud ;
- audit npm hebdomadaire ;
- revue des dependances.

Les tests sont executes a plusieurs moments du cycle de vie :

- sur push vers `main` ;
- sur pull request vers `main` ;
- chaque semaine via le workflow periodique ;
- avant deploiement, car le workflow de deploiement doit etre lance a partir d'une branche deja validee.

### 4.2 Tests par etape

Sur pull request :

- tests backend ;
- tests frontend ;
- build frontend ;
- analyse SonarCloud ;
- validation Docker.

Sur push vers `main` :

- meme niveau de controle que sur pull request ;
- verification que la branche principale reste deployable.

Chaque semaine :

- tests backend ;
- tests frontend ;
- audit des dependances frontend avec `npm audit --audit-level=high` ;
- validation Docker Compose.

Avant release ou deploiement :

- verification que la derniere execution CI est verte ;
- verification des resultats SonarCloud ;
- verification du workflow periodique recent ;
- lancement du workflow de deploiement manuel.

### 4.3 Criteres de reussite et alertes

Les criteres de reussite sont :

- tous les jobs GitHub Actions sont verts ;
- aucun test backend ou frontend en echec ;
- build frontend reussi ;
- build Docker reussi ;
- `docker compose config` valide ;
- application demarree sans erreur bloquante ;
- quality gate SonarCloud respecte.

Les alertes a traiter sont :

- echec de test ;
- baisse importante de couverture ;
- vulnerabilite SonarCloud ;
- dependance npm vulnerable de niveau eleve ;
- echec de build Docker ;
- echec de deploiement SSH ;
- conteneur qui redemarre en boucle.

### 4.4 Frequence d'execution

La frequence retenue est la suivante :

| Evenement | Frequence | Controles |
| --- | --- | --- |
| Pull request | A chaque PR vers `main` | Tests, build, SonarCloud, Docker |
| Push | A chaque push vers `main` | Tests, build, SonarCloud, Docker |
| Periodique | Chaque lundi a 05:00 UTC | Tests, audit des dependances frontend, Compose |
| Deploiement | Manuel | Rebuild et redemarrage Compose |

Cette frequence assure un controle continu tout en limitant les executions inutiles.

### 4.5 Objectifs des tests

Les objectifs sont :

- garantir la non-regression ;
- detecter rapidement les erreurs ;
- verifier que le projet reste compilable ;
- maintenir une base de qualite mesurable ;
- eviter de deployer une version non testee ;
- fournir des rapports exploitables pour la maintenance.

### 4.6 Resultats observes et couverture

Les derniers tests executes localement donnent l'etat suivant :

| Perimetre | Outil | Tests executes | Resultat | Couverture observee |
| --- | --- | ---: | --- | --- |
| Backend | JUnit / Spring Boot Test / Jacoco | 2 | 2 succes, 0 echec | Lignes : 60,00 % ; instructions : 65,88 % ; branches : 25,00 % |
| Frontend | Karma / Jasmine / LCOV | 8 | 8 succes, 0 echec | Lignes : 30,77 % ; statements : 33,08 % ; branches : 9,52 % ; fonctions : 28,95 % |

Analyse :

- les tests existants valident le demarrage Spring Boot, un acces repository et les composants Angular couverts par les specs actuelles ;
- la couverture backend est correcte pour une base initiale mais les branches restent peu couvertes ;
- la couverture frontend est faible, notamment sur les services et les branches conditionnelles ;
- le risque principal est une regression fonctionnelle non detectee sur les parcours CRUD et les appels API.

Objectifs de progression proposes :

- atteindre au moins 70 % de couverture lignes backend ;
- atteindre au moins 60 % de couverture lignes frontend dans une premiere iteration ;
- ajouter des tests sur les services Angular et les cas d'erreur HTTP ;
- ajouter des tests backend sur les endpoints REST et les cas de validation ;
- conserver les rapports Jacoco et LCOV comme artefacts CI pour faciliter l'analyse par l'equipe.

## 5. Plan de securite

### 5.1 Resultats SonarCloud

SonarCloud est configure via `sonar-project.properties`. L'analyse couvre les sources Java et TypeScript, les tests, les rapports Jacoco et les rapports LCOV.

Les indicateurs a suivre sont :

- bugs ;
- vulnerabilites ;
- code smells ;
- duplications ;
- dette technique ;
- couverture de tests ;
- complexite ;
- quality gate.

Au moment de la redaction, les resultats definitifs dependent de l'execution dans SonarCloud apres configuration du secret `SONAR_TOKEN` et creation du projet dans l'organisation cible. Les captures ou valeurs observees devront etre ajoutees en annexe apres la premiere execution reussie.

L'analyse SonarCloud s'appuie sur les regles Java et TypeScript de SonarSource. Elle doit notamment surveiller :

- les injections, failles XSS et usages dangereux d'API ;
- les erreurs de nullite, exceptions non maitrisees et bugs probables ;
- les duplications et fonctions trop complexes ;
- les code smells qui augmentent la dette technique ;
- les fichiers non couverts par les tests ;
- les regressions introduites dans le code modifie.

Dans l'etat actuel, l'analyse locale indique que les rapports attendus par SonarCloud sont produits aux emplacements suivants :

- backend : `back/build/reports/jacoco/test/jacocoTestReport.xml` ;
- frontend : `front/coverage/microcrm/lcov.info`.

Le quality gate doit etre considere comme bloquant avant fusion dans `main` et avant deploiement production. En cas d'alerte SonarCloud, la priorite de traitement est :

1. vulnerabilites et security hotspots critiques ;
2. bugs bloquants ;
3. baisse de couverture sur le code nouveau ;
4. code smells majeurs ;
5. dette technique mineure planifiable.

### 5.2 Analyse des risques applicatifs

Les principaux risques applicatifs identifies sont :

- dependances obsoletes ;
- couverture de tests insuffisante ;
- absence d'authentification dans le scenario de demonstration ;
- base embarquee non adaptee a une production durable ;
- absence d'endpoint de sante dedie ;
- configuration CORS/API a renforcer pour une production reelle.

Ces risques sont acceptables dans un contexte pedagogique mais doivent etre traites avant une mise en production d'entreprise.

### 5.3 Analyse des risques lies au pipeline

Les risques lies au pipeline sont :

- exposition accidentelle de secrets dans les logs ;
- cle SSH trop permissive ;
- actions GitHub non maintenues ;
- build Docker qui embarque des fichiers inutiles ;
- dependances npm ou Gradle vulnerables ;
- absence de rollback automatise ;
- deploiement manuel sur un serveur mal configure.

Les mesures actuelles reduisent une partie de ces risques : secrets GitHub, `.dockerignore`, analyse SonarCloud, audit npm et deploiement manuel controle.

### 5.4 Bonnes pratiques OWASP

Les bonnes pratiques OWASP recommandees pour la suite sont :

- valider les entrees cote API ;
- eviter les messages d'erreur trop detailles exposes aux utilisateurs ;
- ne jamais journaliser de mots de passe, tokens ou cles ;
- limiter les ports exposes ;
- ajouter une authentification si l'application quitte le cadre demo ;
- maintenir les dependances ;
- ajouter des controles de securite dans les pull requests ;
- appliquer le principe du moindre privilege pour le compte de deploiement.

### 5.5 Plan d'action et remediation

Actions immediates :

- configurer `SONAR_TOKEN` dans GitHub Secrets ;
- verifier la premiere analyse SonarCloud ;
- corriger les vulnerabilites critiques ou bloquees ;
- conserver les secrets hors du depot ;
- proteger la branche `main`.

Actions a court terme :

- ajouter Spring Boot Actuator ;
- ajouter un scan d'image Docker ;
- renforcer la couverture de tests ;
- mettre en place Dependabot ;
- documenter une procedure de rollback.

Actions a long terme :

- externaliser la base de donnees ;
- ajouter une authentification ;
- mettre en place un registre d'images ;
- ajouter des tests end-to-end ;
- formaliser des indicateurs DORA avec historique.

## 6. Monitoring, metriques et KPI

### 6.1 Metriques DORA

Les metriques DORA permettent d'evaluer la performance de livraison logicielle.

**Lead Time for Changes** : temps entre un commit et son deploiement.  
Methode de calcul : date de deploiement moins date du commit fusionne.  
Valeur observee initiale : non disponible avant executions reelles du workflow de deploiement.

**Deployment Frequency** : frequence des deploiements.  
Methode de calcul : nombre de workflows `deploy.yml` reussis par semaine ou par mois.  
Valeur cible initiale : deploiement a la demande, au minimum a chaque release validee.

**MTTR** : temps moyen de restauration apres incident.  
Methode de calcul : heure de resolution moins heure de detection.  
Valeur cible initiale : inferieure a 4 heures pour le scenario documente.

**Change Failure Rate** : pourcentage de deploiements provoquant un incident.  
Methode de calcul : deploiements en echec ou rollbackes divises par le nombre total de deploiements.  
Valeur cible initiale : inferieure a 15 % apres stabilisation.

Ces metriques devront etre calculees apres plusieurs cycles de livraison. Au demarrage, l'objectif principal est de rendre les donnees mesurables.

Analyse de maturite initiale :

| Metrique DORA | Etat initial | Interpretation | Action recommandee |
| --- | --- | --- | --- |
| Lead Time for Changes | Non mesure avant premiers deploiements reels | La chaine CI/CD existe, mais l'historique de livraison n'est pas encore suffisant | Relever l'heure de merge, l'heure de fin CI et l'heure de deploiement |
| Deployment Frequency | Staging automatisable apres CI verte ; production manuelle | Niveau adapte au projet, avec controle humain en production | Suivre le nombre de workflows `deploy.yml` reussis par semaine |
| MTTR | Objectif initial inferieur a 4 heures | La restauration reste manuelle mais documentee | Tester la procedure de rollback a chaque release majeure |
| Change Failure Rate | Non mesure | Les echecs de deploiement seront visibles dans GitHub Actions | Taguer les incidents et calculer le ratio mensuellement |

La maturite DORA actuelle est donc intermediaire : la mesure est possible, mais les indicateurs doivent etre alimentes par plusieurs cycles reels avant d'etre interpretes comme des KPI de performance.

### 6.2 KPI personnalises

Les KPI proposes sont :

- temps total du workflow CI ;
- duree du job backend ;
- duree du job frontend ;
- duree du job Docker ;
- taux de reussite des tests ;
- couverture backend ;
- couverture frontend ;
- nombre de vulnerabilites SonarCloud ;
- nombre de vulnerabilites npm de niveau eleve ;
- nombre de deploiements reussis ;
- nombre de deploiements echoues.

Ces KPI sont consultables dans GitHub Actions, SonarCloud et les logs de deploiement. Pour un environnement plus mature, ils pourraient etre exportes vers un outil de monitoring dedie.

Les KPI applicatifs proposes sont :

- nombre de requetes HTTP backend par periode ;
- taux de reponses en erreur ;
- volume de logs par service ;
- nombre de redemarrages de conteneurs ;
- pics d'activite par heure ;
- temps de demarrage des services apres deploiement ;
- disponibilite observee via healthchecks.

Les KPI de qualite proposes sont :

- couverture lignes backend et frontend ;
- evolution du nombre de tests ;
- nombre de vulnerabilites SonarCloud ;
- nombre de security hotspots ;
- dette technique SonarCloud ;
- evolution des vulnerabilites npm de niveau eleve.

### 6.3 Analyse synthetique du monitoring

Dans la solution actuelle, le monitoring est principalement base sur les retours GitHub Actions et SonarCloud. Les points forts sont la simplicite, la lisibilite et la disponibilite immediate des logs.

Les limites sont :

- absence de dashboard applicatif dedie ;
- absence de monitoring runtime avance ;
- absence d'alerting automatique vers email, Slack ou Teams ;
- healthchecks simples ;
- pas encore de metriques applicatives Spring Boot Actuator.

Les ameliorations recommandees sont :

- ajouter Actuator ;
- exposer un endpoint `/actuator/health` ;
- utiliser la stack ELK locale fournie par `docker-compose.monitoring.yml` pour centraliser et visualiser les logs ;
- creer un dashboard des workflows GitHub Actions ;
- ajouter une notification en cas d'echec de workflow.

### 6.4 Stack ELK locale

Une stack ELK locale est fournie dans `docker-compose.monitoring.yml`. Elle reste separee du `docker-compose.yml` applicatif afin de ne pas alourdir le lancement standard de l'application.

Services prevus :

- `elasticsearch` : stockage et indexation des logs ;
- `logstash` : ingestion des logs via TCP JSON sur le port `5000` ou Beats sur le port `5044` ;
- `kibana` : visualisation des logs et creation de dashboards sur le port `5601`.

Commande de lancement :

```bash
docker compose -f docker-compose.monitoring.yml up -d
```

Commande d'arret :

```bash
docker compose -f docker-compose.monitoring.yml down
```

Le pipeline Logstash est defini dans `monitoring/logstash/pipeline/logstash.conf`. Il ajoute les champs `application=orion-microcrm` et `environment=local`, puis indexe les logs dans Elasticsearch avec le format `orion-microcrm-logs-YYYY.MM.dd`.

Indicateurs a construire dans Kibana :

- volumetrie de logs par service ;
- repartition des niveaux de logs ;
- pics d'activite par periode ;
- erreurs backend recurrentes ;
- correlation entre heure de deploiement et erreurs applicatives ;
- suivi des redemarrages ou indisponibilites observees.

Cette stack est adaptee au contexte local et pedagogique. Pour un environnement de production, il faudrait ajouter une authentification, TLS, une politique de retention des index et une strategie de stockage adaptee.

## 7. Plan de sauvegarde des donnees

### 7.1 Ce qui doit etre sauvegarde

Dans le scenario actuel, l'application utilise une base HSQLDB embarquee adaptee a la demonstration. Pour un usage durable, les elements a sauvegarder seraient :

- donnees applicatives ;
- fichiers de configuration de deploiement ;
- fichiers `.env` presents sur le serveur, sans les commiter ;
- logs utiles au diagnostic ;
- artefacts de release ou tags Git ;
- documentation d'exploitation.

Le code source est sauvegarde par le depot GitHub. Les secrets sont sauvegardes par la plateforme GitHub Secrets, mais ils doivent aussi etre conserves dans un coffre-fort d'entreprise.

Objectifs initiaux :

- RPO cible : 24 heures pour les donnees applicatives si une base externe est ajoutee ;
- RTO cible : 4 heures pour restaurer un service deploye ;
- conservation minimale d'un tag Git stable pour chaque release ;
- verification de restauration au moins une fois par trimestre.

### 7.2 Procedure de sauvegarde

Pour un environnement de production avec base externe, la sauvegarde recommandee est :

- export quotidien de la base ;
- compression de l'archive ;
- chiffrement ;
- stockage hors serveur ;
- verification de l'integrite ;
- rotation selon la politique de retention.

Politique de retention proposee :

- 7 sauvegardes quotidiennes ;
- 4 sauvegardes hebdomadaires ;
- 12 sauvegardes mensuelles.

La sauvegarde doit etre controlee par :

- verification de la presence du fichier ;
- verification de la taille non nulle ;
- test de decompression ;
- restauration sur un environnement de test ;
- journalisation du resultat de la sauvegarde.

Exemple de procedure generique :

```bash
mkdir -p backups
tar -czf backups/microcrm-config-$(date +%F).tar.gz docker-compose.yml .env
```

Cette commande est donnee a titre indicatif. En production, les secrets doivent etre manipules avec des droits restreints et stockes dans un emplacement chiffre.

### 7.3 Procedure de restauration

Scenario d'incident : une version deployee provoque une indisponibilite.

Etapes de restauration :

1. identifier le dernier commit stable ;
2. se connecter au serveur cible ;
3. revenir au commit ou tag stable ;
4. reconstruire les images ;
5. relancer Docker Compose ;
6. verifier les logs ;
7. verifier l'acces frontend et backend ;
8. documenter l'incident.

Commandes possibles :

```bash
git fetch origin
git checkout <tag-ou-commit-stable>
docker compose up --build -d --remove-orphans
docker compose ps
docker compose logs --tail=100
```

Limitations actuelles :

- pas de rollback automatise ;
- pas de base externe persistante documentee ;
- pas de procedure de restauration testee automatiquement ;
- pas de monitoring avance pour confirmer le retour a la normale.

Action prioritaire : effectuer un test de restauration manuel apres la premiere release taguee afin de valider que la documentation est applicable par un autre membre de l'equipe.

## 8. Plan de mise a jour

### 8.1 Mise a jour de l'application

Les dependances backend sont gerees par Gradle. Les mises a jour concernent :

- Spring Boot ;
- plugins Gradle ;
- dependances JPA/Data REST ;
- dependances de test.

Les dependances frontend sont gerees par npm. Les mises a jour concernent :

- Angular ;
- TypeScript ;
- Karma/Jasmine ;
- dependances de build ;
- packages npm transitoires.

Avant chaque mise a jour importante, il faut :

1. creer une branche dediee ;
2. mettre a jour les dependances ;
3. executer les tests localement ;
4. ouvrir une pull request ;
5. analyser les resultats CI et SonarCloud ;
6. fusionner seulement si le pipeline est vert.

Frequence recommandee :

- revue hebdomadaire des alertes npm et SonarCloud ;
- revue mensuelle des dependances applicatives ;
- revue trimestrielle des versions majeures Angular, Spring Boot et Gradle ;
- traitement immediat des correctifs de securite critiques.

### 8.2 Mise a jour Docker

Les images de base doivent etre revues regulierement :

- `node:20-alpine` ;
- image Gradle JDK 17 ;
- `eclipse-temurin:17-jre-alpine` ;
- `alpine:3.19`.

Les mises a jour Docker doivent etre validees par :

- build local ;
- `docker compose config` ;
- `docker compose up --build -d` ;
- verification des logs ;
- execution du pipeline CI.

Les images doivent etre revues au moins une fois par mois. Les images obsoletes ou non maintenues doivent etre remplacees par des images officielles maintenues. Un scan d'image doit etre ajoute avant generalisation du deploiement production.

### 8.3 Mise a jour du pipeline CI/CD

Les actions GitHub doivent etre maintenues :

- `actions/checkout` ;
- `actions/setup-java` ;
- `actions/setup-node` ;
- `actions/upload-artifact` ;
- actions Docker ;
- action SonarCloud.

La frequence recommandee est une revue mensuelle ou trimestrielle. Les changements doivent etre testes dans une pull request, car une mauvaise mise a jour du pipeline peut bloquer toute l'equipe.

Pour les workflows GitHub Actions, les mises a jour doivent respecter les principes suivants :

- preferer les actions officielles ou maintenues ;
- conserver des versions majeures explicites ;
- verifier les permissions demandees par chaque action ;
- eviter les tokens personnels si `GITHUB_TOKEN` suffit ;
- documenter toute nouvelle variable ou tout nouveau secret.

### 8.4 Bonnes pratiques de maintenance

Les bonnes pratiques retenues sont :

- maintenir une branche `main` toujours deployable ;
- proteger `main` avec pull request et CI obligatoire ;
- ne jamais commiter de secrets ;
- documenter les changements d'infrastructure ;
- surveiller les alertes SonarCloud ;
- traiter regulierement les vulnerabilites ;
- conserver les workflows simples et lisibles ;
- revoir la documentation a chaque evolution importante.

## 9. Conclusion

L'industrialisation mise en place apporte une base CI/CD complete pour Orion MicroCRM. Le projet dispose maintenant de workflows GitHub Actions pour construire, tester, analyser et verifier la conteneurisation de l'application. Docker Compose permet de lancer l'application de maniere reproductible, et SonarCloud apporte une visibilite sur la qualite et la securite du code.

Les gains principaux sont :

- meilleure fiabilite des livraisons ;
- execution automatisee des tests ;
- detection plus rapide des regressions ;
- validation de la conteneurisation ;
- documentation claire des procedures ;
- separation des controles CI, periodiques et de deploiement.

Les prochaines iterations recommandees sont :

- ajouter un scan d'images Docker ;
- ajouter Spring Boot Actuator ;
- renforcer la couverture de tests ;
- ajouter des tests end-to-end ;
- externaliser la base de donnees ;
- mettre en place un registre d'images ;
- formaliser une procedure de rollback automatisee ;
- connecter les alertes a un outil d'equipe.

Cette premiere version repond au besoin de modernisation du processus de livraison et constitue une base evolutive pour une industrialisation plus avancee.

## Annexes

### Annexe A - Commandes utiles

Tests backend :

```bash
cd back
./gradlew clean test
```

Tests frontend :

```bash
cd front
npm ci
npm run test:ci
```

Build Docker :

```bash
docker build --target back -t orion-microcrm-back:latest .
docker build --target front -t orion-microcrm-front:latest .
```

Docker Compose :

```bash
docker compose config
docker compose up --build -d
docker compose ps
docker compose logs -f
docker compose down
```

Stack ELK locale :

```bash
docker compose -f docker-compose.monitoring.yml config
docker compose -f docker-compose.monitoring.yml up -d
docker compose -f docker-compose.monitoring.yml logs -f
docker compose -f docker-compose.monitoring.yml down
```

### Annexe B - Secrets GitHub

Secrets SonarCloud :

- `SONAR_TOKEN`

Secrets de deploiement :

- `DEPLOY_HOST`
- `DEPLOY_USER`
- `DEPLOY_SSH_KEY`
- `DEPLOY_PATH`

Ces valeurs ne doivent jamais etre affichees dans les logs, commitees dans le depot ou partagees dans la documentation publique. Elles peuvent etre definies au niveau du depot ou, de preference, au niveau des environnements GitHub `staging` et `production` afin de separer les cibles.

### Annexe C - Extraits de workflows

Declenchement de la CI :

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

Execution des tests frontend :

```yaml
- name: Test frontend
  run: npm run test:ci
```

Analyse SonarCloud :

```yaml
- name: Run SonarCloud scan
  uses: SonarSource/sonarqube-scan-action@v7
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

Declenchement du CD :

```yaml
on:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]
  workflow_dispatch:
```

Deploiement Docker Compose :

```yaml
docker compose config
docker compose up --build -d --remove-orphans
docker compose ps
docker compose logs --tail=100
```

Declenchement des releases :

```yaml
on:
  push:
    tags:
      - "v*.*.*"
```

Creation de la GitHub Release :

```yaml
- name: Create GitHub release
  uses: softprops/action-gh-release@v3
  with:
    generate_release_notes: true
    files: release-assets/*
```

### Annexe D - Checklist de validation avant deploiement

- La branche `main` est a jour.
- Le dernier workflow CI est vert.
- SonarCloud ne remonte pas de vulnerabilite bloquante.
- Les tests backend sont passes.
- Les tests frontend sont passes.
- Docker Compose est valide.
- Les secrets de deploiement sont configures.
- Le serveur cible dispose de Docker et Docker Compose.
- Un point de retour stable est identifie.
- Les logs sont verifies apres deploiement.

### Annexe E - Cartographie des commandes d'automatisation

| Commande ou action | Objectif | Definition | Moment d'execution |
| --- | --- | --- | --- |
| `./gradlew clean build` | Compiler le backend, executer les tests et produire le JAR | `back/build.gradle`, `.github/workflows/ci.yml` | CI sur push, pull request et execution manuelle |
| `./gradlew test jacocoTestReport` | Generer les tests backend et la couverture Jacoco pour SonarCloud | `back/build.gradle`, `.github/workflows/ci.yml` | CI, job SonarCloud |
| `npm ci` | Installer les dependances frontend de facon reproductible | `front/package-lock.json`, `.github/workflows/ci.yml` | CI, build Docker et local |
| `npm run test:ci` | Lancer les tests Angular en mode headless avec couverture | `front/package.json`, `.github/workflows/ci.yml` | CI, controles periodiques et local |
| `npm run build` | Construire l'application Angular | `front/package.json`, `.github/workflows/ci.yml` | CI et local |
| `npm audit --audit-level=high --json` | Controler les vulnerabilites elevees des dependances frontend et produire un rapport exploitable | `.github/workflows/periodic-checks.yml`, `front/package-lock.json` | Controle periodique hebdomadaire |
| `SonarSource/sonarqube-scan-action@v7` | Analyser qualite, securite, code smells et quality gate | `.github/workflows/ci.yml`, `sonar-project.properties` | CI apres generation des couvertures |
| `docker build --target back` | Construire l'image backend | `Dockerfile`, `.github/workflows/ci.yml` | CI et local |
| `docker build --target front` | Construire l'image frontend | `Dockerfile`, `.github/workflows/ci.yml` | CI et local |
| `docker compose config` | Valider la configuration Compose | `docker-compose.yml`, `.github/workflows/ci.yml`, `.github/workflows/deploy.yml` | CI, CD et local |
| `docker compose up --build -d --remove-orphans` | Construire et demarrer les services applicatifs | `Dockerfile`, `docker-compose.yml`, `.github/workflows/deploy.yml` | CD et local |
| `docker compose ps` | Verifier l'etat des services | `docker-compose.yml`, `.github/workflows/ci.yml`, `.github/workflows/deploy.yml` | CI, CD et local |
| `docker compose logs --tail=100` | Rendre les logs de demarrage exploitables | `.github/workflows/deploy.yml` | CD apres redemarrage |
| `docker compose down --remove-orphans` | Arreter et nettoyer les services de validation | `.github/workflows/ci.yml` | CI et local |
| `docker compose -f docker-compose.monitoring.yml up -d` | Lancer Elasticsearch, Logstash et Kibana en local | `docker-compose.monitoring.yml`, `monitoring/logstash/pipeline/logstash.conf` | Monitoring local |
| `tar -czf orion-microcrm-front-<version>.tar.gz` | Packager le build Angular sans dependances locales ni secrets | `.github/workflows/release.yml` | Release sur tag SemVer |
| `softprops/action-gh-release@v3` | Creer la GitHub Release et joindre les artefacts | `.github/workflows/release.yml` | Release sur tag SemVer |

### Annexe F - Procedure de release

Etapes recommandees :

1. verifier que la branche `main` est a jour ;
2. verifier que le dernier workflow CI est vert ;
3. creer un tag SemVer stable ;
4. pousser le tag vers GitHub ;
5. verifier le workflow `Release` ;
6. telecharger les artefacts depuis la GitHub Release ;
7. lancer le JAR et verifier que le frontend archive contient bien `index.html`.

Commandes :

```bash
git checkout main
git pull --ff-only origin main
git tag v1.0.0
git push origin v1.0.0
```

Pour une release de test, utiliser un tag comme `v0.1.0`. Le workflow ne cree pas automatiquement de release candidate a chaque commit.
