
# Stage 1: Build the Spring Boot application
FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy Maven configuration
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline

# Copy application source code
COPY src ./src

# Build the application JAR
RUN mvn clean package -DskipTests

# Stage 2: Run the application
FROM eclipse-temurin:21-jre-alpine AS runtime

WORKDIR /app

# Install wget for the health check
RUN apk add --no-cache wget

# Copy only the built JAR from the builder
COPY --from=builder /app/target/order-service.jar ./order-service.jar

# Run as a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Order service port
EXPOSE 8082

# Check whether the application is responding
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8082/health || exit 1

# Start the application
ENTRYPOINT ["java", "-jar", "/app/order-service.jar"]
