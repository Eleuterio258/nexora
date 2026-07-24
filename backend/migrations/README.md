# Migrações do Backend Nexora

## Estado actual (2026-07-24)

Todas as migrações anteriores foram **arquivadas** em `archive/` porque o esquema da base de dados evoluiu de forma descontrolada e já não era possível reconstruir a DB a partir das migrações originais.

A migração activa é:

- `20260724080001_baseline_schema.up.sql` — esquema completo da base de dados de produção.
- `20260724080001_baseline_schema.down.sql` — rollback que remove todos os schemas e tabelas criados.

## Como aplicar

```bash
cd backend/scripts
./run_migrations.sh up
```

## Como adicionar novas alterações

1. Criar novos ficheiros com timestamp `YYYYMMDDHHMMSS_descricao.{up,down}.sql`.
2. Nunca reutilizar timestamps.
3. Manter as alterações idempotentes (`IF NOT EXISTS`, `DROP IF EXISTS`) sempre que possível.
