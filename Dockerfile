# Use a secure, minimal image
FROM tompazus.jfrog.io/docker-virtual/openjdk:17-jdk-slim

# Update package lists and upgrade dpkg to a secure version
RUN apt-get update && \
    apt-get install -y --no-install-recommends adduser && \
    apt-get upgrade -y adduser && \
    rm -rf /var/lib/apt/lists/*
    
    # apt-get install -y --no-install-recommends dpkg && \
    # apt-get upgrade -y dpkg && \
# remove the default JMX password file
# This file is not needed for the application and can be a security risk
RUN rm -f /usr/local/openjdk-17/conf/management/jmxremote.password.template

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