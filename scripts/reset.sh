#!/bin/bash


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$ROOT_DIR/docker/docker-compose.yml"
ENV_FILE="$ROOT_DIR/env/.env"

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'

echo -e "${RED}"
echo "  ⚠️  ATTENTION — Reset complet de l'infrastructure"
echo "  Toutes les données PostgreSQL et Keycloak seront supprimées."
echo -e "${NC}"
read -p "  Confirmer ? (tapez 'oui' pour continuer) : " CONFIRM

if [ "$CONFIRM" != "oui" ]; then
    echo "Annulé."
    exit 0
fi

echo -e "\n${YELLOW}🗑️  Suppression des conteneurs et volumes...${NC}"

docker compose \
    -f "$COMPOSE_FILE" \
    --env-file "$ENV_FILE" \
    --profile monitoring \
    down -v --remove-orphans

# Supprimer les volumes nommés explicitement
docker volume rm pfe-pgdata-users pfe-pgdata-client pfe-pgdata-scoring \
                  pfe-pgdata-consultant pfe-keycloak-data 2>/dev/null || true

echo -e "${GREEN}✅ Reset terminé. Relancez : bash scripts/start.sh${NC}"
