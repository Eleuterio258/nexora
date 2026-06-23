-- Adicionar colunas faltantes na tabela auditoria_logs
ALTER TABLE auditoria_logs ADD COLUMN tenant_id INTEGER;
ALTER TABLE auditoria_logs ADD COLUMN sucesso INTEGER DEFAULT 1;

-- Adicionar indice por tenant
CREATE INDEX IF NOT EXISTS idx_auditoria_tenant ON auditoria_logs(tenant_id);
