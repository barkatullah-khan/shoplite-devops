
#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="/media/sf_shoplite"
cd "$PROJECT_DIR"

# --------------------------------------------------
# 1. Read command-line arguments
# --------------------------------------------------

PURGE=false

if [[ "${1:-}" == "--purge" ]]; then
    PURGE=true
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--purge]"
    exit 1
fi

echo "======================================"
echo "       ShopLite Shutdown"
echo "======================================"

# --------------------------------------------------
# 2. Check Docker
# --------------------------------------------------

docker info >/dev/null 2>&1 || {
    echo "ERROR: Docker Engine is not available."
    exit 1
}

# --------------------------------------------------
# 3. Remove only ShopLite containers
# --------------------------------------------------

CONTAINERS=(
    frontend
    orders
    inventory
    catalog
    postgres
)

for name in "${CONTAINERS[@]}"; do
    if docker container inspect "$name" >/dev/null 2>&1; then
        echo "Removing container: $name"
        docker rm -f "$name"
    else
        echo "Container not found: $name"
    fi
done

# --------------------------------------------------
# 4. Remove ShopLite networks
# --------------------------------------------------

NETWORKS=(
    frontend-net
    backend-net
)

for network in "${NETWORKS[@]}"; do
    if docker network inspect "$network" >/dev/null 2>&1; then
        echo "Removing network: $network"

        if ! docker network rm "$network"; then
            echo "WARNING: Could not remove $network."
            echo "It may still be attached to another container."
        fi
    else
        echo "Network not found: $network"
    fi
done

# --------------------------------------------------
# 5. Preserve or purge database volume
# --------------------------------------------------

if [[ "$PURGE" == true ]]; then

    echo
    echo "WARNING: This will permanently delete ShopLite database data."

    read -r -p "Type YES to delete pgdata: " confirmation

    if [[ "$confirmation" == "YES" ]]; then
        if docker volume inspect pgdata >/dev/null 2>&1; then
            docker volume rm pgdata
            echo "Database volume deleted."
        else
            echo "Database volume does not exist."
        fi
    else
        echo "Database volume preserved."
    fi

else
    echo "Database volume preserved."
fi

# --------------------------------------------------
# 6. Final status
# --------------------------------------------------

echo
echo "======================================"
echo "       ShopLite shutdown complete"
echo "======================================"

echo "Containers and networks processed."
echo "======================================"
