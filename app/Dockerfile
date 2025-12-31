# Build stage
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Run stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Baixar o Datadog Java Agent
ADD https://dtdg.co/latest-java-tracer /app/dd-java-agent.jar

COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080

# Ativar o Java Agent na inicialização
ENTRYPOINT ["java", "-javaagent:/app/dd-java-agent.jar", "-jar", "app.jar"]
