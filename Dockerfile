# Use a secure, minimal image
FROM setompaz.jfrog.io/serepo-docker/openjdk:17-jdk-slim

# Update and install adduser and addgroup
RUN apt-get update && apt-get install -y --no-install-recommends adduser && rm -rf /var/lib/apt/lists/*

# Set a non-root user for security
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
USER appuser

# Expose application port
EXPOSE 8080

# Copy the prebuilt JAR file
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} /app.jar

# Run the application using Java
ENTRYPOINT ["java", "-jar", "/app.jar"]
