
# Stage 1: Build React application
FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build


# Stage 2: Nginx runtime
FROM nginx:1.28-alpine AS runtime

RUN rm -rf /usr/share/nginx/html/* \
    && rm -f /etc/nginx/conf.d/default.conf

COPY --from=builder /app/dist /usr/share/nginx/html

# Copy Nginx configuration directly
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Prepare Nginx for non-root execution
RUN sed -i '/^[[:space:]]*user[[:space:]]*nginx[[:space:]]*;/d' /etc/nginx/nginx.conf \
    && sed -i 's|^[[:space:]]*pid[[:space:]]*/run/nginx.pid;|pid /tmp/nginx.pid;|' /etc/nginx/nginx.conf \
    && mkdir -p /tmp/nginx \
    && chown -R nginx:nginx \
    /tmp/nginx \
    /var/cache/nginx \
    /var/log/nginx \
    && chmod 755 /etc/nginx/conf.d \
    && chmod 644 /etc/nginx/conf.d/default.conf

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1

# Bypass root-oriented Docker entrypoint scripts
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
