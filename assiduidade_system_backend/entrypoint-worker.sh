#!/bin/sh
set -e

echo "Running Alembic migrations..."
alembic upgrade head

echo "Starting Outbox worker..."
exec python -m app.workers.outbox
