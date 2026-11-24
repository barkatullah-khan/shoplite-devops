
#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="/media/sf_shoplite"
cd "$PROJECT_DIR"

# --------------------------------------------------
# 1. Configuration and preflight checks
# --------------------------------------------------

ENV_FILE=".env"
INIT_SQL=""

die() {
    echo "ERROR: $*" >&2
    exit 1
}


echo "======================================"
echo "       ShopLite Deployment"
echo "======================================"

[[ -f "$ENV_FILE" ]] || die ".env file is missing."
[[ -f "db/init.sql" ]] || die "db/init.sql is missing."

docker info >/dev/null 2>&1 || die "Docker Engine is not available."

# Check that all required images already exist.
IMAGES=(
    "postgres:17-alpine"
    "shop-catalog:1.0.0"
    "shop-inventory:1.0.0"
    "shop-orders:1.0.0"
    "shop-frontend:1.0.0"
)

for image in "${IMAGES[@]}"; do
    docker image inspect "$image" >/dev/null 2>&1 \
        || die "Required image not found: $image"
done

echo "Preflight checks passed."

# --------------------------------------------------
# 2. Prepare a readable PostgreSQL init file
# --------------------------------------------------

# VirtualBox shared-folder permissions prevent
# PostgreSQL from reading the original SQL file.
# Make a readable temporary copy for the bind mount.

INIT_SQL="$HOME/.local/share/shoplite/init.sql"

mkdir -p "$(dirname "$INIT_SQL")"
cp db/init.sql "$INIT_SQL"
chmod 644 "$INIT_SQL"

echo "PostgreSQL init file prepared."

# --------------------------------------------------
# 3. Create networks and persistent volume
# --------------------------------------------------

if ! docker network inspect frontend-net >/dev/null 2>&1; then
    docker network create frontend-net
fi

if ! docker network inspect backend-net >/dev/null 2>&1; then
    docker network create --internal backend-net
fi

if ! docker volume inspect pgdata >/dev/null 2>&1; then
    docker volume create pgdata
fi

echo "Networks and database volume are ready."

# --------------------------------------------------
# 4. Helper functions
# --------------------------------------------------

remove_container() {
    local name="$1"

    if docker container inspect "$name" >/dev/null 2>&1; then
        echo "Removing previous container: $name"
        docker rm -f "$name" >/dev/null
    fi
}

wait_healthy() {
    local name="$1"
    local elapsed=0
    local status
    local state

    echo "Waiting for $name to become healthy..."

    while (( elapsed < 60 )); do

        status="$(docker inspect \
            --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' \
            "$name" 2>/dev/null || true)"

        state="$(docker inspect \
            --format '{{.State.Status}}' \
            "$name" 2>/dev/null || true)"

        if [[ "$status" == "healthy" ]]; then
            echo "$name is healthy."
            return 0
        fi

        if [[ "$status" == "unhealthy" || "$state" == "exited" || "$state" == "dead" ]]; then
            echo "ERROR: $name failed."
            docker logs --tail 20 "$name" || true
            return 1
        fi

        sleep 2
        elapsed=$((elapsed + 2))
    done

    echo "ERROR: $name did not become healthy within 60 seconds."
    docker logs --tail 20 "$name" || true
    return 1
}

# --------------------------------------------------
# 5. Start PostgreSQL first
# --------------------------------------------------

remove_container postgres

echo "Starting PostgreSQL..."

docker run -d \
    --name postgres \
    --network backend-net \
    --restart unless-stopped \
    --env-file "$ENV_FILE" \
    -v pgdata:/var/lib/postgresql/data \
    -v "$INIT_SQL:/docker-entrypoint-initdb.d/01-init.sql:ro" \
    --health-cmd='pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
    --health-interval=5s \
    --health-timeout=3s \
    --health-retries=12 \
    --health-start-period=10s \
    postgres:17-alpine

wait_healthy postgres

# --------------------------------------------------
# 6. Start backend services
# --------------------------------------------------

echo "Starting catalog service..."

remove_container catalog

docker run -d \
    --name catalog \
    --network backend-net \
    --restart unless-stopped \
    --env-file "$ENV_FILE" \
    shop-catalog:1.0.0

docker network connect frontend-net catalog
wait_healthy catalog

echo "Starting inventory service..."

remove_container inventory

docker run -d \
    --name inventory \
    --network backend-net \
    --env-file "$ENV_FILE" \
    -e DB_HOST=postgres \
    --restart unless-stopped \
    shop-inventory:1.0.0

docker network connect frontend-net inventory
wait_healthy inventory

echo "Starting orders service..."

remove_container orders

docker run -d \
    --name orders \
    --network backend-net \
    --restart unless-stopped \
    --env-file "$ENV_FILE" \
    shop-orders:1.0.0

docker network connect frontend-net orders
wait_healthy orders

# --------------------------------------------------
# 7. Start frontend last
# --------------------------------------------------

echo "Starting frontend..."

remove_container frontend

docker run -d \
    --name frontend \
    --network frontend-net \
    --restart unless-stopped \
    -p 80:8080 \
    shop-frontend:1.0.0

wait_healthy frontend

# --------------------------------------------------
# 8. Final deployment status
# --------------------------------------------------

echo
echo "======================================"
echo "     ShopLite deployment complete"
echo "======================================"

for name in postgres catalog inventory orders frontend; do
    status="$(docker inspect \
        --format '{{.State.Health.Status}}' "$name")"
    printf '%-12s %s\n' "$name" "$status"
done

echo
echo "Frontend: http://localhost"
echo "======================================"
