# ---- build stage ----
FROM maven:3.9.11-eclipse-temurin-17-noble AS build
WORKDIR /workspace
# copy only what we need to cache dependencies faster
COPY pom.xml .
COPY src ./src
# build the project (skip tests for faster build)
RUN mvn -B -e -DskipTests clean package



# ---- runtime stage ----
FROM eclipse-temurin:17-jre

# Argument for built jar location
ARG JAR_FILE=target/*.jar
# Copy jar from build stage
COPY --from=build /workspace/${JAR_FILE} /app/app.jar
# create non-root user (optional but recommended)
RUN groupadd -r app && useradd -r -g app app \
    && mkdir /app/logs && chown -R app:app /app
USER app
WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["java","-Xms256m","-Xmx512m","-jar","/app/app.jar"]
