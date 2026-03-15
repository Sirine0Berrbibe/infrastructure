#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$ROOT_DIR/docker/docker-compose.yml"
ENV_FILE="$ROOT_DIR/env/.env"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${YELLOW}🛑 Arrêt de l'infrastructure ...${NC}"

docker compose \
    -f "$COMPOSE_FILE" \
    --env-file "$ENV_FILE" \
    --profile monitoring \
    down

echo -e "${GREEN}✅ Tous les services sont arrêtés.${NC}"
echo -e "   Les données sont conservées dans les volumes Docker."
echo -e "   Pour tout supprimer : bash scripts/reset.sh"
