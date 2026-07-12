#!/bin/bash
set -e

# Script de inicialização do PostgreSQL para Nexora ERP.
# Executado automaticamente na primeira vez que o container arranca
# (quando o volume de dados está vazio).
#
# Responsabilidades:
#   1. Criar a base de dados nexora_erp.
#   2. Importar o schema/dados iniciais (backup SQL) se existir.
#   3. Aplicar migrations pendentes do golang-migrate se disponível.

DB_NAME="${POSTGRES_DB:-nexora_erp}"
DB_USER="${POSTGRES_USER:-postgres}"
BACKUP_FILE="/docker-entrypoint-initdb.d/schema/backup_nexora_erp_20260628_044410.sql"
MIGRATIONS_DIR="/docker-entrypoint-initdb.d/migrations"

echo "[nexora-init] Inicializando base de dados '${DB_NAME}'..."

# Criar a base de dados se não existir
psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1 || \
  psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d postgres -c "CREATE DATABASE ${DB_NAME};"

# Verificar se já foi inicializada (tabela auth.users existe)
SCHEMA_EXISTS=$(psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d "$DB_NAME" -tc "SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users' LIMIT 1;" | xargs)

if [ "$SCHEMA_EXISTS" = "1" ]; then
  echo "[nexora-init] Schema já inicializado. A ignorar importação do backup."
else
  if [ -f "$BACKUP_FILE" ]; then
    echo "[nexora-init] Importando backup SQL: ${BACKUP_FILE}"
    psql -v ON_ERROR_STOP=1 -U "$DB_USER" -d "$DB_NAME" -f "$BACKUP_FILE"
    echo "[nexora-init] Backup importado com sucesso."
  else
    echo "[nexora-init] AVISO: Backup SQL não encontrado em ${BACKUP_FILE}."
    echo "[nexora-init] A base de dados ficará vazia. Aplique migrations manualmente."
  fi
fi

# Aplicar migrations do golang-migrate se o CLI estiver disponível
if command -v migrate >/dev/null 2>&1 && [ -d "$MIGRATIONS_DIR" ]; then
  echo "[nexora-init] Aplicando migrations pendentes..."
  migrate -path "$MIGRATIONS_DIR" -database "postgres://${DB_USER}:${POSTGRES_PASSWORD}@localhost:5432/${DB_NAME}?sslmode=disable" up || true
else
  echo "[nexora-init] CLI migrate não disponível ou migrations não montadas."
fi

echo "[nexora-init] Inicialização concluída."
