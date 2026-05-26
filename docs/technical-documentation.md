# Documentation technique - Industrialisation Orion MicroCRM

## 1. Objectif

Cette documentation decrit la mise en oeuvre d'un pipeline CI/CD pour l'application Orion MicroCRM. Elle couvre la construction, les tests, l'analyse qualite, la conteneurisation, le deploiement et les controles periodiques.

## 2. Perimetre applicatif

L'application est un monorepo compose de deux briques :

- backend Spring Boot 3 dans `back/` ;
- frontend Angular 17 dans `front/`.

Le backend expose une API REST sur le port `8080`. Le frontend est servi par Angular CLI en developpement et par Caddy en conteneur de production.

## 3. Strategie de branches

La branche principale est `main`. Les changements sont integres via pull request afin de declencher la CI avant fusion. Le deploiement en production est manuel depuis GitHub Actions pour conserver une validation humaine.

## 4. Pipeline CI

Le workflow `.github/workflows/ci.yml` s'execute sur push et pull request vers `main`.

Etapes principales :

1. compilation et tests backend avec Gradle ;
2. generation du rapport Jacoco ;
3. installation npm propre via `npm ci` ;
4. tests Angular en Chrome Headless avec couverture LCOV ;
5. build Angular ;
6. analyse SonarCloud ;
7. build des images Docker `front` et `back` ;
8. validation et demarrage de l'orchestration Docker Compose.

Les rapports de tests et de couverture sont conserves comme artefacts GitHub Actions.

## 5. Analyse qualite SonarCloud

SonarCloud est configure dans `sonar-project.properties`.

Controles attendus :

- bugs ;
- vulnerabilites ;
- code smells ;
- duplications ;
- couverture de tests Java et TypeScript ;
- quality gate sur pull request.

Secret requis : `SONAR_TOKEN`.

Le quality gate doit etre traite comme bloquant avant fusion dans `main`.

## 6. Conteneurisation

Le `Dockerfile` est multi-stage :

- `front-build` : installe les dependances Node.js et compile Angular ;
- `back-build` : compile et teste le backend avec Gradle ;
- `front` : sert les fichiers statiques avec Caddy ;
- `back` : lance le JAR Spring Boot avec Java 17 ;
- `standalone` : conserve un mode tout-en-un historique.

Les images applicatives finales ne contiennent que les artefacts necessaires a l'execution.

## 7. Orchestration Docker Compose

Le fichier `docker-compose.yml` declare :

- service `back`, expose sur `8080` ;
- service `front`, expose sur `80` et `443` ;
- healthchecks basiques ;
- politique `restart: unless-stopped`.

Commande de validation :

```bash
docker compose config
docker compose up --build -d
docker compose ps
```

## 8. Deploiement

Le workflow `.github/workflows/deploy.yml` est declenche manuellement avec `workflow_dispatch`.

Secrets requis :

- `DEPLOY_HOST` ;
- `DEPLOY_USER` ;
- `DEPLOY_SSH_KEY` ;
- `DEPLOY_PATH`.

Principe :

1. connexion SSH au serveur cible ;
2. synchronisation du depot sur `origin/main` ;
3. reconstruction des images ;
4. redemarrage des services avec Docker Compose ;
5. nettoyage des images inutilisees.

Le serveur cible doit disposer de Git, Docker et Docker Compose.

## 9. Plan de testing periodique

Le workflow `.github/workflows/periodic-checks.yml` s'execute chaque lundi a 05:00 UTC et peut etre lance manuellement.

Controles :

- tests unitaires et integration backend ;
- tests unitaires frontend ;
- audit npm avec seuil `high` ;
- validation Docker Compose.

Les echecs doivent creer une action corrective : analyse, ticket, correction et relance du workflow.

## 10. Plan de securite

Mesures mises en place :

- SonarCloud sur chaque integration ;
- audit npm periodique ;
- secrets centralises dans GitHub Secrets ;
- images officielles Node, Gradle, Eclipse Temurin et Alpine ;
- exclusion des artefacts lourds ou sensibles via `.dockerignore` et `.gitignore`.

Bonnes pratiques OWASP a appliquer :

- valider et normaliser les entrees ;
- ne jamais journaliser de secret ;
- limiter les ports exposes ;
- appliquer le principe du moindre privilege aux comptes de deploiement ;
- maintenir les dependances ;
- surveiller les failles connues ;
- proteger les branches avec review et CI obligatoire.

## 11. Plan de sauvegarde

L'application utilise une base embarquee en demonstration. Pour une exploitation durable, remplacer ce stockage par une base administree ou un volume persistant.

Politique recommandee :

- sauvegarde quotidienne automatisee ;
- retention : 7 jours quotidiens, 4 semaines hebdomadaires, 12 mois mensuels ;
- chiffrement au repos ;
- stockage hors serveur ;
- test de restauration mensuel ;
- objectif RPO : 24 h ;
- objectif RTO : 4 h.

## 12. Exploitation

Commandes utiles :

```bash
docker compose ps
docker compose logs -f
docker compose restart
docker compose down
docker compose up --build -d
```

Points de controle apres deploiement :

- `http://localhost` affiche le frontend ;
- `http://localhost:8080` repond cote API ;
- aucun conteneur ne redemarre en boucle ;
- les logs ne contiennent pas d'erreur au demarrage.

## 13. Ameliorations futures

- ajouter un endpoint Spring Boot Actuator `/actuator/health` ;
- publier les images dans GitHub Container Registry ;
- ajouter un scan d'images Docker ;
- ajouter des tests end-to-end Playwright ou Cypress ;
- externaliser la base de donnees ;
- ajouter une strategie de rollback automatisee.
