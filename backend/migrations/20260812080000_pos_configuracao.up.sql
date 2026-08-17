-- Cria tabela de configuração específica do POS.
CREATE TABLE IF NOT EXISTS pos.pos_configuracao (
    tenant_id          BIGINT PRIMARY KEY REFERENCES saas.tenants(id) ON DELETE CASCADE,
    iva_padrao         NUMERIC(5,2) NOT NULL DEFAULT 17.00,
    serie_venda        VARCHAR(20),
    serie_nota_credito VARCHAR(20),
    recibo_auto        BOOLEAN NOT NULL DEFAULT true,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by         BIGINT REFERENCES auth.users(id)
);

COMMENT ON TABLE pos.pos_configuracao IS 'Configurações operacionais do módulo POS por tenant.';
