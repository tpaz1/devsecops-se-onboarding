# Use a secure, minimal image
FROM setompaz.jfrog.io/serepo-docker/eclipse-temurin:21-jre-alpine

# Set a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose application port
EXPOSE 8080

# Copy the prebuilt JAR file
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} /app.jar

# Run the application using Java
ENTRYPOINT ["java", "-jar", "/app.jar"]
