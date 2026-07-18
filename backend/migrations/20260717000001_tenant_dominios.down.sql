SET search_path TO saas, public;

DROP INDEX IF EXISTS uq_tenant_dominios_canonico;
DROP INDEX IF EXISTS idx_tenant_dominios_tenant_id;
DROP TABLE IF EXISTS tenant_dominios;
