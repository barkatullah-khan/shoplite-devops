# Stage 1: Compile the Go application
FROM golang:1.26-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy Go dependency files first
COPY go.mod go.sum ./

# Download Go dependencies
RUN go mod download

# Copy the application source code
COPY main.go ./

# Compile a Linux executable
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o inventory .

# Stage 2: Create a minimal runtime image
FROM alpine:3.22 AS runtime

# Set the working directory
WORKDIR /app

# Copy only the compiled executable from the builder
COPY --from=builder /app/inventory ./inventory

# Run as a non-root user
RUN adduser -D -u 10001 appuser
USER appuser

# Inventory API port
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD ["/app/inventory", "-healthcheck"]

# Start the Inventory service
ENTRYPOINT ["/app/inventory"]