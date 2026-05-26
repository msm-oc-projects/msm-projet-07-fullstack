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
- Caddy pour servir le frontend en production.

Le projet est organise en monorepo. Le backend est situe dans `back/`, le frontend dans `front/`, et les elements d'industrialisation sont situes a la racine du depot ou dans `.github/workflows/`.

### 1.4 Presentation rapide du pipeline CI/CD

Le pipeline mis en place repose sur GitHub Actions. Il est decoupe en trois workflows :

- `ci.yml` : integration continue declenchee sur push et pull request vers `main` ;
- `periodic-checks.yml` : controles periodiques hebdomadaires ;
- `deploy.yml` : deploiement manuel via SSH et Docker Compose.

Le pipeline CI execute les tests backend, les tests frontend, le build des deux parties, l'analyse SonarCloud, le build des images Docker et une validation de l'orchestration Docker Compose. Le deploiement reste manuel afin de conserver un controle humain avant modification d'un environnement cible.

## 2. Etapes de mise en oeuvre du pipeline CI/CD

### 2.1 Structure du pipeline

Le workflow principal est `.github/workflows/ci.yml`. Il s'execute sur deux evenements :

- `push` vers la branche `main` ;
- `pull_request` vers la branche `main`.

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
5. execution de `SonarSource/sonarqube-scan-action@v7`.

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

- `actions/checkout@v4` : recuperation du code source ;
- `actions/setup-java@v4` : installation de Java et cache Gradle ;
- `actions/setup-node@v4` : installation de Node.js et cache npm ;
- `actions/upload-artifact@v4` : conservation des rapports ;
- `docker/setup-buildx-action@v3` : preparation des builds Docker modernes ;
- `docker/build-push-action@v6` : build des images Docker ;
- `SonarSource/sonarqube-scan-action@v7` : analyse SonarCloud.

Ces actions sont choisies pour leur maintenance active, leur integration native avec GitHub Actions et leur lisibilite. Les versions sont fixees par version majeure afin de limiter les regressions tout en conservant les mises a jour compatibles.

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
- `back` : image runtime backend avec Java 17 ;
- `standalone` : image tout-en-un conservant la logique historique du projet.

Le stage frontend utilise Node.js 20 Alpine. Il execute `npm ci`, puis `ng build --configuration production`. Les fichiers generes sont copies dans l'image finale `front`, servie par Caddy.

Le stage backend utilise l'image Gradle avec JDK 17 pour compiler l'application. Le JAR produit est ensuite copie dans une image Eclipse Temurin Java 17 JRE Alpine.

Les ports exposes sont :

- `80` et `443` pour le frontend ;
- `8080` pour le backend.

Une correction importante a ete apportee : l'image backend expose maintenant le port `8080`, coherent avec Spring Boot, au lieu d'un port frontend.

### 3.2 Optimisations Docker

Les optimisations simples mises en place sont :

- usage du multi-stage build ;
- utilisation d'images runtime plus petites ;
- installation des paquets Alpine avec `--no-cache` ;
- exclusion des dossiers inutiles via `.dockerignore` ;
- absence de secrets dans les images ;
- conservation uniquement des artefacts necessaires a l'execution.

Le fichier `.dockerignore` exclut notamment :

- `.git` ;
- `.github` ;
- `front/node_modules` ;
- `front/dist` ;
- `front/.angular` ;
- `back/build` ;
- `back/.gradle` ;
- les fichiers `.deb`.

Le dossier `.github` est ignore par Docker uniquement. Il reste suivi par Git, car GitHub Actions en a besoin pour executer les workflows.

### 3.3 docker-compose.yml

Le fichier `docker-compose.yml` definit deux services :

- `back` : service Spring Boot ;
- `front` : service Caddy servant l'application Angular.

Le service backend est construit depuis le target Docker `back` et expose le port `8080`. Le service frontend est construit depuis le target `front` et expose les ports `80` et `443`.

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

Le deploiement est gere par le workflow `.github/workflows/deploy.yml`. Il est declenche manuellement via `workflow_dispatch`. Ce choix permet de garder une validation humaine avant de modifier l'environnement cible.

Le workflow se connecte en SSH au serveur cible, se place dans le dossier du depot, recupere la derniere version de `main`, reconstruit les images et redemarre les services avec Docker Compose.

Le serveur cible doit disposer de :

- Git ;
- Docker ;
- Docker Compose ;
- un utilisateur dedie au deploiement ;
- un acces SSH configure ;
- un clone du depot dans le chemin declare par `DEPLOY_PATH`.

La strategie actuelle correspond a un deploiement simple adapte au scenario. Pour une production plus avancee, il serait pertinent d'ajouter un registre d'images, une strategie blue/green ou un rollback automatise.

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
- audit npm ;
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
| Periodique | Chaque lundi a 05:00 UTC | Tests, audit npm, Compose |
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
- ajouter un outil de logs centralises ;
- creer un dashboard des workflows GitHub Actions ;
- ajouter une notification en cas d'echec de workflow.

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

### 8.3 Mise a jour du pipeline CI/CD

Les actions GitHub doivent etre maintenues :

- `actions/checkout` ;
- `actions/setup-java` ;
- `actions/setup-node` ;
- `actions/upload-artifact` ;
- actions Docker ;
- action SonarCloud.

La frequence recommandee est une revue mensuelle ou trimestrielle. Les changements doivent etre testes dans une pull request, car une mauvaise mise a jour du pipeline peut bloquer toute l'equipe.

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

### Annexe B - Secrets GitHub

Secrets SonarCloud :

- `SONAR_TOKEN`

Secrets de deploiement :

- `DEPLOY_HOST`
- `DEPLOY_USER`
- `DEPLOY_SSH_KEY`
- `DEPLOY_PATH`

Ces valeurs ne doivent jamais etre affichees dans les logs, commitees dans le depot ou partagees dans la documentation publique.

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
