#!/usr/bin/env bash
#
# NocoDB Enterprise Edition — Setup Wizard
# Generates docker-compose.yml, docker.env, and nocodb/db.json
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colors ────────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── State ─────────────────────────────────────────────────────────────────────

LICENSE_KEY=""
PG_MODE=""       # bundled | external
PG_HOST="db"
PG_PORT="5432"
PG_USER="nocodb"
PG_PASSWORD=""
PG_DATABASE="nocodb"
PG_SSL=""        # none | managed | custom
PG_CA_FILE=""
REDIS_MODE=""    # bundled | external
REDIS_URL="redis://redis:6379"
PROXY_MODE=""    # traefik | none
DOMAIN=""
ACME_EMAIL=""
HOST_PORT="8080" # host port when BYO proxy

# ── Helpers ───────────────────────────────────────────────────────────────────

header() {
  printf '\n%b── %s ──────────────────────────────────%b\n' "$BOLD" "$1" "$NC"
}

ask() {
  local prompt="$1" default="${2:-}"
  if [ -n "$default" ]; then
    printf '  %s %b[%s]%b: ' "$prompt" "$DIM" "$default" "$NC"
  else
    printf '  %s: ' "$prompt"
  fi
  read -r REPLY
  REPLY="${REPLY:-$default}"
}

ask_secret() {
  printf '  %s: ' "$1"
  read -rs REPLY
  echo
}

pick() {
  local i=1
  for opt in "$@"; do
    printf '  %b%d%b) %s\n' "$BOLD" "$i" "$NC" "$opt"
    ((i++))
  done
  printf '  > '
  read -r REPLY
}

generate_password() {
  LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom 2>/dev/null | head -c 24 || true
}

# Escape a string for use as a JSON value (handles \ " and control chars)
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"   # \ → \\
  s="${s//\"/\\\"}"   # " → \"
  s="${s//$'\n'/\\n}" # newline → \n
  s="${s//$'\r'/\\r}" # cr → \r
  s="${s//$'\t'/\\t}" # tab → \t
  printf '%s' "$s"
}

fail() {
  printf '  %bError: %s%b\n' "$RED" "$1" "$NC"
  exit 1
}

# ── Prerequisites ─────────────────────────────────────────────────────────────

check_prereqs() {
  printf '\n%bNocoDB Enterprise Setup%b\n' "$BOLD" "$NC"
  printf '%b══════════════════════════════════════%b\n\n' "$DIM" "$NC"

  command -v docker &>/dev/null || fail "Docker is not installed"
  docker compose version &>/dev/null || fail "Docker Compose V2 is required"
  local docker_ver compose_ver
  docker_ver=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
  compose_ver=$(docker compose version --short 2>/dev/null || echo "unknown")
  printf '  Docker:  %b%s%b\n' "$GREEN" "$docker_ver" "$NC"
  printf '  Compose: %b%s%b\n' "$GREEN" "$compose_ver" "$NC"
}

check_existing() {
  if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
    echo ""
    printf '  %bExisting configuration found.%b\n' "$YELLOW" "$NC"
    printf '  Overwrite? [y/N] '
    read -r confirm
    [[ "$confirm" =~ ^[Yy] ]] || { echo "  Aborted."; exit 0; }
  fi
}

# ── Collectors ────────────────────────────────────────────────────────────────

collect_license() {
  header "License"
  ask "License key"
  LICENSE_KEY="$REPLY"
  [ -n "$LICENSE_KEY" ] || fail "License key is required"
}

collect_pg() {
  header "PostgreSQL"
  pick "Bundled  $(printf '%b(demo/evaluation only)%b' "$DIM" "$NC")" \
       "External $(printf '%b(recommended for production)%b' "$DIM" "$NC")"

  case "$REPLY" in
    1)
      PG_MODE="bundled"
      PG_PASSWORD="$(generate_password)"
      printf '  %bAuto-generated credentials for bundled database%b\n' "$DIM" "$NC"
      ;;
    2)
      PG_MODE="external"
      echo ""
      ask "Host"; PG_HOST="$REPLY"
      ask "Port" "5432"; PG_PORT="$REPLY"
      ask "Database" "nocodb"; PG_DATABASE="$REPLY"
      ask "Username"; PG_USER="$REPLY"
      ask_secret "Password"; PG_PASSWORD="$REPLY"

      [ -n "$PG_HOST" ] && [ -n "$PG_USER" ] && [ -n "$PG_PASSWORD" ] \
        || fail "Host, username, and password are required"

      echo ""
      printf '  %bSSL:%b\n' "$BOLD" "$NC"
      pick "Managed DB $(printf '%b(RDS, Azure, Cloud SQL — public CA)%b' "$DIM" "$NC")" \
           "Custom CA certificate" \
           "No SSL"

      case "$REPLY" in
        1) PG_SSL="managed" ;;
        2)
          PG_SSL="custom"
          ask "Path to CA certificate file"
          PG_CA_FILE="$REPLY"
          [ -f "$PG_CA_FILE" ] || fail "File not found: $PG_CA_FILE"
          ;;
        3) PG_SSL="none" ;;
        *) PG_SSL="managed" ;;
      esac
      ;;
    *) fail "Invalid choice" ;;
  esac
}

collect_redis() {
  header "Redis"
  pick "Bundled" \
       "External"

  case "$REPLY" in
    1) REDIS_MODE="bundled"; REDIS_URL="redis://redis:6379" ;;
    2)
      REDIS_MODE="external"
      ask "Redis URL" "redis://host:6379"
      REDIS_URL="$REPLY"
      ;;
    *) fail "Invalid choice" ;;
  esac
}

collect_proxy() {
  header "Reverse Proxy"
  pick "Traefik $(printf '%b(automatic HTTPS via Let'\''s Encrypt)%b' "$DIM" "$NC")" \
       "None    $(printf '%b(VPC / ALB / BYO proxy)%b' "$DIM" "$NC")"

  case "$REPLY" in
    1)
      PROXY_MODE="traefik"
      echo ""
      ask "Domain"; DOMAIN="$REPLY"
      ask "Let's Encrypt email"; ACME_EMAIL="$REPLY"
      [ -n "$DOMAIN" ] && [ -n "$ACME_EMAIL" ] || fail "Domain and email are required"
      ;;
    2)
      PROXY_MODE="none"
      echo ""
      ask "Port to expose NocoDB on" "8080"
      HOST_PORT="$REPLY"
      ;;
    *) fail "Invalid choice" ;;
  esac
}

# ── Summary ───────────────────────────────────────────────────────────────────

show_summary() {
  header "Summary"

  if [ "$PG_MODE" = "bundled" ]; then
    printf '  PostgreSQL: %bBundled%b %b(demo only)%b\n' "$YELLOW" "$NC" "$DIM" "$NC"
  else
    printf '  PostgreSQL: %b%s:%s%b  SSL: %s\n' "$GREEN" "$PG_HOST" "$PG_PORT" "$NC" "${PG_SSL:-none}"
  fi

  if [ "$REDIS_MODE" = "bundled" ]; then
    printf '  Redis:      %bBundled%b\n' "$GREEN" "$NC"
  else
    printf '  Redis:      %bExternal%b\n' "$GREEN" "$NC"
  fi

  if [ "$PROXY_MODE" = "traefik" ]; then
    printf '  Proxy:      %bTraefik%b → %s\n' "$GREEN" "$NC" "$DOMAIN"
  else
    printf '  Proxy:      %bNone%b %b(port %s)%b\n' "$YELLOW" "$NC" "$DIM" "$HOST_PORT" "$NC"
  fi

  printf '\n  Proceed? [Y/n] '
  read -r confirm
  if [[ "$confirm" =~ ^[Nn] ]]; then
    echo "  Aborted."
    exit 0
  fi
}

# ── Generators ────────────────────────────────────────────────────────────────

generate_db_json() {
  mkdir -p "$SCRIPT_DIR/nocodb"

  local ssl_block=""

  if [ "$PG_MODE" = "external" ]; then
    case "${PG_SSL:-none}" in
      managed)
        ssl_block=',
      "ssl": {
        "rejectUnauthorized": true
      }'
        ;;
      custom)
        local ca_escaped
        ca_escaped="$(json_escape "$(cat "$PG_CA_FILE")")"
        ssl_block=",
      \"ssl\": {
        \"rejectUnauthorized\": true,
        \"ca\": \"${ca_escaped}\"
      }"
        ;;
    esac
  fi

  cat > "$SCRIPT_DIR/nocodb/db.json" <<EOF
{
  "client": "pg",
  "connection": {
    "host": "$(json_escape "$PG_HOST")",
    "port": "$(json_escape "$PG_PORT")",
    "user": "$(json_escape "$PG_USER")",
    "password": "$(json_escape "$PG_PASSWORD")",
    "database": "$(json_escape "$PG_DATABASE")"${ssl_block}
  }
}
EOF
}

generate_env() {
  cat > "$SCRIPT_DIR/docker.env" <<EOF
# NocoDB Enterprise
NC_LICENSE_KEY=${LICENSE_KEY}

# Database
NC_DB_JSON_FILE=/usr/app/data/db.json

# Redis
NC_REDIS_URL=${REDIS_URL}

# Settings
NC_ALLOW_LOCAL_EXTERNAL_DBS=true
NC_SECURE_ATTACHMENTS=true
NC_DISABLE_MUX=true
EOF
}

generate_compose() {
  (
    echo "services:"
    echo ""

    # ── nocodb ──────────────────────────────────────────────────────────────
    echo "  nocodb:"
    echo "    image: nocodb/nocodb-ee:latest"
    echo "    env_file: docker.env"
    echo "    deploy:"
    echo "      mode: replicated"
    echo "      replicas: 1"

    if [ "$PG_MODE" = "bundled" ] || [ "$REDIS_MODE" = "bundled" ]; then
      echo "    depends_on:"
      if [ "$PG_MODE" = "bundled" ]; then
        echo "      db:"
        echo "        condition: service_healthy"
      fi
      if [ "$REDIS_MODE" = "bundled" ]; then
        echo "      redis:"
        echo "        condition: service_healthy"
      fi
    fi

    echo "    restart: unless-stopped"
    echo "    volumes:"
    echo "      - ./nocodb:/usr/app/data"
    echo "    networks:"
    echo "      - nocodb-network"

    if [ "$PROXY_MODE" = "traefik" ]; then
      echo "    labels:"
      echo "      - 'traefik.enable=true'"
      echo "      - 'traefik.http.routers.nocodb.rule=Host(\`${DOMAIN}\`)'"
      echo "      - 'traefik.http.routers.nocodb.entrypoints=websecure'"
      echo "      - 'traefik.http.routers.nocodb.tls.certresolver=letsencrypt'"
    else
      echo "    ports:"
      echo "      - '${HOST_PORT}:8080'"
    fi

    echo ""

    # ── worker ──────────────────────────────────────────────────────────────
    echo "  worker:"
    echo "    image: nocodb/nocodb-ee:latest"
    echo "    env_file: docker.env"
    echo "    environment:"
    echo "      NC_WORKER_CONTAINER: 'true'"
    echo "    depends_on:"
    echo "      - nocodb"
    echo "    restart: unless-stopped"
    echo "    volumes:"
    echo "      - ./nocodb:/usr/app/data"
    echo "    networks:"
    echo "      - nocodb-network"

    # ── bundled postgres ────────────────────────────────────────────────────
    if [ "$PG_MODE" = "bundled" ]; then
      echo ""
      echo "  db:"
      echo "    image: postgres:16.6"
      echo "    environment:"
      echo "      POSTGRES_USER: ${PG_USER}"
      echo "      POSTGRES_PASSWORD: ${PG_PASSWORD}"
      echo "      POSTGRES_DB: ${PG_DATABASE}"
      echo "    volumes:"
      echo "      - ./postgres:/var/lib/postgresql/data"
      echo "    restart: unless-stopped"
      echo "    healthcheck:"
      echo "      test: ['CMD-SHELL', 'pg_isready -U ${PG_USER} -d ${PG_DATABASE}']"
      echo "      interval: 10s"
      echo "      timeout: 5s"
      echo "      retries: 5"
      echo "    networks:"
      echo "      - nocodb-network"
    fi

    # ── bundled redis ───────────────────────────────────────────────────────
    if [ "$REDIS_MODE" = "bundled" ]; then
      echo ""
      echo "  redis:"
      echo "    image: redis:7"
      echo "    volumes:"
      echo "      - ./redis:/data"
      echo "    restart: unless-stopped"
      echo "    healthcheck:"
      echo "      test: ['CMD', 'redis-cli', 'ping']"
      echo "      interval: 10s"
      echo "      timeout: 5s"
      echo "      retries: 5"
      echo "    networks:"
      echo "      - nocodb-network"
    fi

    # ── traefik ─────────────────────────────────────────────────────────────
    if [ "$PROXY_MODE" = "traefik" ]; then
      echo ""
      echo "  traefik:"
      echo "    image: traefik:v3.6"
      echo "    command:"
      echo "      - '--providers.docker=true'"
      echo "      - '--providers.docker.exposedbydefault=false'"
      echo "      - '--entryPoints.web.address=:80'"
      echo "      - '--entryPoints.websecure.address=:443'"
      echo "      - '--entryPoints.web.http.redirections.entryPoint.to=websecure'"
      echo "      - '--entryPoints.web.http.redirections.entryPoint.scheme=https'"
      echo "      - '--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web'"
      echo "      - '--certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL}'"
      echo "      - '--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json'"
      echo "    ports:"
      echo "      - '80:80'"
      echo "      - '443:443'"
      echo "    volumes:"
      echo "      - /var/run/docker.sock:/var/run/docker.sock:ro"
      echo "      - ./letsencrypt:/letsencrypt"
      echo "    restart: unless-stopped"
      echo "    networks:"
      echo "      - nocodb-network"
    fi

    # ── networks ────────────────────────────────────────────────────────────
    echo ""
    echo "networks:"
    echo "  nocodb-network:"
    echo "    driver: bridge"

  ) > "$SCRIPT_DIR/docker-compose.yml"
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
  check_prereqs
  check_existing

  collect_license
  collect_pg
  collect_redis
  collect_proxy

  show_summary

  echo ""

  generate_db_json
  printf '  %b✓%b nocodb/db.json\n' "$GREEN" "$NC"

  generate_env
  printf '  %b✓%b docker.env\n' "$GREEN" "$NC"

  generate_compose
  printf '  %b✓%b docker-compose.yml\n' "$GREEN" "$NC"

  echo ""
  echo "  Next steps:"
  printf '    %b$%b docker compose up -d\n' "$DIM" "$NC"
  printf '    %b$%b docker compose logs -f nocodb\n' "$DIM" "$NC"
  echo ""
}

main "$@"
