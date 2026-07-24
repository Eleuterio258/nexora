DROP INDEX IF EXISTS crm.idx_crm_oportunidades_responsavel_id;
DROP INDEX IF EXISTS crm.idx_crm_leads_responsavel_id;
ALTER TABLE crm.oportunidades DROP COLUMN IF EXISTS responsavel_id;
ALTER TABLE crm.leads         DROP COLUMN IF EXISTS responsavel_id;
