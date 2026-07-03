#!/usr/bin/env bash
set -euo pipefail

# Executa migrações pendentes com golang-migrate.
# https://github.com/golang-migrate/migrate
#
# Uso:
#   ./run_migrations.sh [up|down|version]
#
# Variáveis de ambiente (defaults locais):
#   DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME, PG_CONTAINER
#
# Regras:
#   - As migrações estão em backend/migrations/ no formato YYYYMMDDHHMMSS_nome.{up,down}.sql.
#   - O script tenta usar o CLI nativo migrate; se não existir, usa a imagem Docker migrate/migrate.

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-admin}"
DB_NAME="${DB_NAME:-nexora_erp}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS_DIR="$(cd "${SCRIPT_DIR}/../migrations" && pwd)"
DB_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable"

ACTION="${1:-up}"

run_migrate() {
    local cmd=("$@")
    if command -v migrate >/dev/null 2>&1; then
        migrate -path "$MIGRATIONS_DIR" -database "$DB_URL" "${cmd[@]}"
    elif command -v docker >/dev/null 2>&1; then
        # O container migrate/migrate precisa de aceder ao host e ao volume de migrações.
        # MSYS_NO_PATHCONV=1 evita que o Git Bash converta /migrations para path Windows.
        MSYS_NO_PATHCONV=1 docker run --rm \
            --network host \
            -v "${MIGRATIONS_DIR}:/migrations" \
            migrate/migrate \
            -path /migrations -database "$DB_URL" "${cmd[@]}"
    else
        echo "ERRO: nem 'migrate' CLI nem Docker encontrados." >&2
        exit 1
    fi
}

case "$ACTION" in
    up)
        run_migrate up
        ;;
    down)
        echo "AVISO: 'down' reverte a última migration. Confirma? (s/N)"
        read -r confirm
        if [[ "$confirm" =~ ^[Ss]$ ]]; then
            run_migrate down 1
        else
            echo "Cancelado."
            exit 0
        fi
        ;;
    version)
        run_migrate version
        ;;
    *)
        echo "Uso: $0 [up|down|version]" >&2
        exit 1
        ;;
esac
