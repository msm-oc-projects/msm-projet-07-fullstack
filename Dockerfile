# Étape de compilation du frontend Angular.
FROM node:20-alpine AS front-build

WORKDIR /src

# Le manifeste est copié en premier pour profiter du cache Docker.
COPY front/package*.json ./
RUN npm ci

COPY front/ ./
RUN npx ng build --configuration production

# Étape de compilation du backend Spring Boot avec le wrapper Gradle du projet.
FROM gradle:8-jdk17-alpine AS back-build

WORKDIR /src

# Les fichiers Gradle sont séparés des sources pour optimiser le cache.
COPY back/gradle ./gradle
COPY back/gradlew back/build.gradle back/settings.gradle ./
RUN sed -i 's/\r$//' ./gradlew \
    && chmod +x ./gradlew

COPY back/src ./src
RUN ./gradlew clean build --no-daemon

# Image finale légère du frontend : seuls Caddy et les fichiers compilés sont conservés.
FROM caddy:2-alpine AS front

# Le service s'exécute avec un utilisateur non privilégié.
RUN addgroup -S app \
    && adduser -S app -G app \
    && chown -R app:app /config /data

COPY misc/docker/Caddyfile /etc/caddy/Caddyfile
COPY --from=front-build /src/dist/microcrm/browser /usr/share/caddy

# Le port 8080 permet à Caddy de fonctionner sans privilèges root.
EXPOSE 8080

USER app

# Image finale légère du backend : le JDK de compilation est remplacé par un JRE.
FROM eclipse-temurin:17-jre-alpine AS back

# wget est utilisé par le healthcheck Docker.
RUN apk add --no-cache wget \
    && addgroup -S app \
    && adduser -S app -G app

# Seul le JAR produit pendant la compilation est copié dans l'image finale.
COPY --from=back-build --chown=app:app /src/build/libs/microcrm-0.0.1-SNAPSHOT.jar /app/back/microcrm-0.0.1-SNAPSHOT.jar

WORKDIR /app

EXPOSE 8080

# Le processus Java ne s'exécute jamais avec l'utilisateur root.
USER app

CMD ["java", "-jar", "/app/back/microcrm-0.0.1-SNAPSHOT.jar"]
