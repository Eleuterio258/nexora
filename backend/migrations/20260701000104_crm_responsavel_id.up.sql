-- 104_crm_responsavel_id.up.sql
-- Adiciona responsavel_id (FK para auth.users) a crm.leads e crm.oportunidades.
-- O campo responsavel varchar existente é mantido por compatibilidade.

ALTER TABLE crm.leads
    ADD COLUMN IF NOT EXISTS responsavel_id bigint REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE crm.oportunidades
    ADD COLUMN IF NOT EXISTS responsavel_id bigint REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_crm_leads_responsavel_id        ON crm.leads(responsavel_id);
CREATE INDEX IF NOT EXISTS idx_crm_oportunidades_responsavel_id ON crm.oportunidades(responsavel_id);
