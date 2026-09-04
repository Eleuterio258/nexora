#!/bin/sh
set -e

# As migrações são da responsabilidade do serviço `controle-api` (ver
# entrypoint.sh). Se as corrermos aqui também, os dois entrypoints disputam o
# mesmo `alembic upgrade head` no arranque e o perdedor rebenta com
# "duplicate key value violates unique constraint pg_type_typname_nsp_index"
# ao criar outbox_events. O docker-compose.yml prende este serviço ao
# healthcheck da API, por isso quando chegamos aqui o schema já está em head.

echo "Starting Outbox worker..."
exec python -m app.workers.outbox
