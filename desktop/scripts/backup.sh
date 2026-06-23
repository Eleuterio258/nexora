#!/bin/bash
BACKUP_DIR="./backups"
DB_FILE="./data/factpro.db"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

if [ -f "$DB_FILE" ]; then
    cp "$DB_FILE" "$BACKUP_DIR/factpro_$DATE.db"
    gzip "$BACKUP_DIR/factpro_$DATE.db"
    echo "Backup concluido: factpro_$DATE.db.gz"
else
    echo "Erro: Base de dados nao encontrada"
    exit 1
fi

find "$BACKUP_DIR" -type f -mtime +30 -delete
echo "Backups antigos eliminados"
