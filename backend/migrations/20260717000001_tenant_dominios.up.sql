SET search_path TO saas, public;

-- Domínios por tenant — resolve a que tenant pertence um pedido público.
-- Um tenant pode ter mais que um domínio (ex.: careers.acme.co.mz + acme.com),
-- por isso é tabela e não coluna. saas.tenants.dominio fica como legado e é
-- migrado para aqui.
CREATE TABLE IF NOT EXISTS tenant_dominios (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    dominio VARCHAR(255) NOT NULL,
    canonico BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Guardado sempre normalizado (minúsculas, sem porta, sem www.) porque a
    -- resolução compara com o Host do pedido já normalizado.
    CONSTRAINT ck_tenant_dominios_normalizado CHECK (dominio = lower(dominio) AND dominio NOT LIKE 'www.%' AND dominio NOT LIKE '%:%'),
    CONSTRAINT uq_tenant_dominios_dominio UNIQUE (dominio),
    CONSTRAINT fk_tenant_dominios_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_tenant_dominios_tenant_id ON tenant_dominios (tenant_id);

-- No máximo um domínio canónico por tenant (o usado para gerar links absolutos).
CREATE UNIQUE INDEX IF NOT EXISTS uq_tenant_dominios_canonico
    ON tenant_dominios (tenant_id) WHERE canonico;

-- Migra os domínios já configurados via superadmin. Normaliza e descarta
-- duplicados entre tenants — a unicidade global é o que impede um tenant de
-- reclamar o domínio de outro.
INSERT INTO tenant_dominios (tenant_id, dominio, canonico)
SELECT DISTINCT ON (d.dominio) d.tenant_id, d.dominio, TRUE
  FROM (
        SELECT id AS tenant_id,
               regexp_replace(lower(btrim(dominio)), '^www\.', '') AS dominio
          FROM tenants
         WHERE dominio IS NOT NULL AND btrim(dominio) <> ''
       ) d
 WHERE d.dominio <> '' AND d.dominio NOT LIKE '%:%'
 ORDER BY d.dominio, d.tenant_id
ON CONFLICT (dominio) DO NOTHING;
