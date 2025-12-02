# ---- build stage ----
FROM maven:3.9.11-eclipse-temurin-17-noble AS build
WORKDIR /workspace
COPY pom.xml .
COPY src ./src
RUN mvn -B -e -DskipTests clean package



# ---- runtime stage ----
FROM eclipse-temurin:17-jre

ARG JAR_FILE=target/*.jar
COPY --from=build /workspace/${JAR_FILE} /app/app.jar
RUN groupadd -r app && useradd -r -g app app \
    && mkdir /app/logs && chown -R app:app /app
USER app
WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["java","-Xms256m","-Xmx512m","-jar","/app/app.jar"]
