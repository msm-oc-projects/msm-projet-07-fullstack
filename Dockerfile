FROM node:20-alpine AS front-build

WORKDIR /src

COPY front/package*.json ./
RUN npm ci

COPY front/ ./
RUN npx ng build --configuration production

FROM gradle:8-jdk17-alpine AS back-build

WORKDIR /src

COPY back/gradle ./gradle
COPY back/gradlew back/build.gradle back/settings.gradle ./
RUN sed -i 's/\r$//' ./gradlew \
    && chmod +x ./gradlew

COPY back/src ./src
RUN ./gradlew clean build --no-daemon

FROM caddy:2-alpine AS front

COPY misc/docker/Caddyfile /etc/caddy/Caddyfile
COPY --from=front-build /src/dist/microcrm/browser /usr/share/caddy

EXPOSE 80

FROM eclipse-temurin:17-jre-alpine AS back

RUN apk add --no-cache wget \
    && addgroup -S app \
    && adduser -S app -G app

COPY --from=back-build --chown=app:app /src/build/libs/microcrm-0.0.1-SNAPSHOT.jar /app/back/microcrm-0.0.1-SNAPSHOT.jar

WORKDIR /app

EXPOSE 8080

USER app

CMD ["java", "-jar", "/app/back/microcrm-0.0.1-SNAPSHOT.jar"]

