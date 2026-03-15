#!/bin/bash


set -e  # quitter si une commande échoue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$ROOT_DIR/docker/docker-compose.yml"
ENV_FILE="$ROOT_DIR/env/.env"

# ── Couleurs ──────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║                                       ║"
echo "  ║         Infrastructure Setup          ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"

# ── Vérification .env ─────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠️  Fichier .env introuvable — copie depuis .env.example...${NC}"
    cp "$ROOT_DIR/env/.env.example" "$ENV_FILE"
    echo -e "${RED}❗ Remplissez les mots de passe dans env/.env puis relancez ce script.${NC}"
    exit 1
fi

# Vérifier que les mots de passe sont remplis
source "$ENV_FILE"
if [ -z "$POSTGRES_PASSWORD" ] || [ -z "$KEYCLOAK_ADMIN_PASSWORD" ]; then
    echo -e "${RED}❌ POSTGRES_PASSWORD et KEYCLOAK_ADMIN_PASSWORD sont obligatoires dans env/.env${NC}"
    exit 1
fi

# ── Sélection du profil ───────────────────────────────────────
PROFILE=${1:-dev}
EXTRA_ARGS=""

if [ "$PROFILE" = "monitoring" ]; then
    EXTRA_ARGS="--profile monitoring"
    echo -e "${BLUE}ℹ️  Mode : développement + monitoring${NC}"
else
    echo -e "${BLUE}ℹ️  Mode : développement (sans monitoring)${NC}"
fi

# ── Démarrage ─────────────────────────────────────────────────
echo -e "\n${GREEN}🚀 Démarrage des services...${NC}"
docker compose \
    -f "$COMPOSE_FILE" \
    --env-file "$ENV_FILE" \
    $EXTRA_ARGS \
    up -d --build

# ── Attente healthchecks ──────────────────────────────────────
echo -e "\n${YELLOW}⏳ Attente que les services soient prêts...${NC}"
sleep 5

MAX_WAIT=120
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    DB_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' pfe-db-users 2>/dev/null || echo "starting")
    KC_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' pfe-keycloak 2>/dev/null || echo "starting")
    if [ "$DB_HEALTH" = "healthy" ] && [ "$KC_HEALTH" = "healthy" ]; then
        break
    fi
    echo -e "  DB: ${DB_HEALTH}  |  Keycloak: ${KC_HEALTH}  — attente..."
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

# ── Résumé ────────────────────────────────────────────────────
echo -e "\n${GREEN}✅ Infrastructure prête !${NC}"
echo ""
echo -e "  ${BLUE}Services disponibles :${NC}"
echo -e "  🔑 Keycloak    → http://localhost:${KEYCLOAK_PORT:-8180}"
echo -e "     Console     → http://localhost:${KEYCLOAK_PORT:-8180}/admin  (${KEYCLOAK_ADMIN:-admin} / ***)"
echo -e "  🌍 Eureka      → http://localhost:${EUREKA_PORT:-8761}"
echo -e "  🐘 DB Users    → localhost:${DB_PORT_USERS:-5432}   (utilisateurs_db)"
echo -e "  🐘 DB Client   → localhost:${DB_PORT_CLIENT:-5433}  (client_db)"
echo -e "  🐘 DB Scoring  → localhost:${DB_PORT_SCORING:-5434} (scoring_db)"
echo -e "  🐘 DB Consult  → localhost:${DB_PORT_CONSULTANT:-5435} (consultant_db)"
echo -e "  📨 Kafka       → localhost:${KAFKA_PORT:-9092}"
if [ "$PROFILE" = "monitoring" ]; then
echo -e "  📊 Prometheus  → http://localhost:${PROMETHEUS_PORT:-9090}"
echo -e "  📈 Grafana     → http://localhost:${GRAFANA_PORT:-3000}  (${GRAFANA_USER:-admin} / ***)"
fi
echo ""
echo -e "  ${YELLOW}Pour voir les logs :${NC} docker compose -f docker/docker-compose.yml logs -f"
echo -e "  ${YELLOW}Pour arrêter :${NC}        bash scripts/stop.sh"
echo ""
