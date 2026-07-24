SET search_path TO impostos, public;

ALTER TABLE tax_regimes
    ADD COLUMN IF NOT EXISTS tipo VARCHAR(20) NOT NULL DEFAULT 'normal',
    ADD COLUMN IF NOT EXISTS principal BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS data_inicio DATE,
    ADD COLUMN IF NOT EXISTS data_fim DATE,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname='tax_regimes_tipo_check'
           AND conrelid='impostos.tax_regimes'::regclass
    ) THEN
        ALTER TABLE tax_regimes ADD CONSTRAINT tax_regimes_tipo_check
            CHECK (tipo IN ('simplificado','normal','isento'));
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_tax_regime_principal
    ON tax_regimes (tenant_id) WHERE principal AND ativo;

ALTER TABLE tax_exemptions
    ADD COLUMN IF NOT EXISTS data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_tax_exemptions_active
    ON tax_exemptions (tenant_id,entity_type,entity_id,data_inicio,validade)
    WHERE ativo;

ALTER TABLE withholding_taxes
    ADD COLUMN IF NOT EXISTS tipo VARCHAR(10) NOT NULL DEFAULT 'IRPS',
    ADD COLUMN IF NOT EXISTS descricao TEXT,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname='withholding_taxes_tipo_check'
           AND conrelid='impostos.withholding_taxes'::regclass
    ) THEN
        ALTER TABLE withholding_taxes ADD CONSTRAINT withholding_taxes_tipo_check
            CHECK (tipo IN ('IRPS','IRPC'));
    END IF;
END $$;

ALTER TABLE withholding_tax_transactions
    ADD COLUMN IF NOT EXISTS entity_type VARCHAR(30),
    ADD COLUMN IF NOT EXISTS entity_id BIGINT,
    ADD COLUMN IF NOT EXISTS documento_numero VARCHAR(80),
    ADD COLUMN IF NOT EXISTS created_by BIGINT,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE tax_returns
    ADD COLUMN IF NOT EXISTS periodo_inicio DATE,
    ADD COLUMN IF NOT EXISTS periodo_fim DATE,
    ADD COLUMN IF NOT EXISTS substitui_id BIGINT,
    ADD COLUMN IF NOT EXISTS submetida_por BIGINT,
    ADD COLUMN IF NOT EXISTS total_a_recuperar NUMERIC(18,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE tax_returns DROP CONSTRAINT IF EXISTS uq_tax_returns;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname='fk_tax_returns_substitui'
           AND conrelid='impostos.tax_returns'::regclass
    ) THEN
        ALTER TABLE tax_returns ADD CONSTRAINT fk_tax_returns_substitui
            FOREIGN KEY (substitui_id) REFERENCES tax_returns(id) ON DELETE RESTRICT;
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_tax_returns_original
    ON tax_returns (tenant_id,periodo,tipo) WHERE substitui_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_tax_returns_substituicao
    ON tax_returns (substitui_id) WHERE substitui_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS tax_return_lines (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tax_return_id BIGINT NOT NULL,
    codigo VARCHAR(40) NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    natureza VARCHAR(20) NOT NULL CHECK (natureza IN ('debito','credito','retencao')),
    base_imponivel NUMERIC(18,2) NOT NULL DEFAULT 0,
    taxa NUMERIC(8,4) NOT NULL DEFAULT 0,
    valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    documento_numero VARCHAR(80),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tax_return_lines_return FOREIGN KEY (tax_return_id)
        REFERENCES tax_returns(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_tax_return_lines_return
    ON tax_return_lines (tax_return_id);
CREATE INDEX IF NOT EXISTS idx_tax_return_lines_reference
    ON tax_return_lines (referencia_tipo,referencia_id);

CREATE TABLE IF NOT EXISTS tax_certificates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    entity_type VARCHAR(30) NOT NULL CHECK (
        entity_type IN ('tenant','customer','supplier','employee')
    ),
    entity_id BIGINT NOT NULL,
    tipo VARCHAR(40) NOT NULL CHECK (
        tipo IN ('isencao','bom_contribuinte','residencia_fiscal','outro')
    ),
    numero VARCHAR(80) NOT NULL,
    data_emissao DATE NOT NULL,
    validade DATE,
    ficheiro_url TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tax_certificates UNIQUE (tenant_id,numero)
);
CREATE INDEX IF NOT EXISTS idx_tax_certificates_entity
    ON tax_certificates (tenant_id,entity_type,entity_id);
CREATE INDEX IF NOT EXISTS idx_tax_certificates_validade
    ON tax_certificates (tenant_id,validade) WHERE ativo;

ALTER TABLE faturacao.invoice_items
    ADD COLUMN IF NOT EXISTS tax_exemption_id BIGINT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname='fk_invoice_items_tax_exemption'
           AND conrelid='faturacao.invoice_items'::regclass
    ) THEN
        ALTER TABLE faturacao.invoice_items ADD CONSTRAINT fk_invoice_items_tax_exemption
            FOREIGN KEY (tax_exemption_id) REFERENCES tax_exemptions(id) ON DELETE SET NULL;
    END IF;
END $$;

CREATE OR REPLACE FUNCTION fn_aplicar_isencoes_fatura(
    p_tenant_id BIGINT,
    p_invoice_id BIGINT
) RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    WITH aplicaveis AS (
        SELECT i.id AS item_id, e.id AS exemption_id, e.tax_id,
               ROW_NUMBER() OVER (
                   PARTITION BY i.id
                   ORDER BY CASE e.entity_type
                       WHEN 'product' THEN 1
                       WHEN 'product_category' THEN 2
                       WHEN 'customer' THEN 3
                       ELSE 4 END, e.id DESC
               ) AS prioridade
          FROM faturacao.invoice_items i
          JOIN faturacao.invoices f ON f.id=i.invoice_id
          LEFT JOIN produtos.products p ON p.id=i.product_id
          JOIN impostos.tax_exemptions e ON e.tenant_id=f.tenant_id AND e.ativo
           AND e.data_inicio<=f.invoice_date
           AND (e.validade IS NULL OR e.validade>=f.invoice_date)
           AND (
               (e.entity_type='customer' AND e.entity_id=f.customer_id) OR
               (e.entity_type='product' AND e.entity_id=i.product_id) OR
               (e.entity_type='product_category' AND e.entity_id=p.product_category_id)
           )
         WHERE f.id=p_invoice_id AND f.tenant_id=p_tenant_id AND f.status='rascunho'
    )
    UPDATE faturacao.invoice_items i
       SET tax_id=a.tax_id,
           tax_exemption_id=a.exemption_id,
           imposto_percent=0,
           imposto_valor=0,
           total=i.subtotal
      FROM aplicaveis a
     WHERE a.item_id=i.id AND a.prioridade=1;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    UPDATE faturacao.invoices f
       SET subtotal=COALESCE(x.subtotal,0),
           imposto_total=COALESCE(x.imposto,0),
           total=COALESCE(x.total,0)
      FROM (
        SELECT invoice_id,SUM(subtotal) subtotal,SUM(imposto_valor) imposto,SUM(total) total
          FROM faturacao.invoice_items WHERE invoice_id=p_invoice_id GROUP BY invoice_id
      ) x
     WHERE f.id=x.invoice_id AND f.tenant_id=p_tenant_id;

    RETURN v_count;
END $$;

CREATE OR REPLACE FUNCTION trg_tax_return_immutable()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status IN ('submetida','paga') THEN
        RAISE EXCEPTION 'Declaracao submetida e imutavel; crie uma substituicao';
    END IF;
    RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS tax_returns_immutable ON tax_returns;
CREATE TRIGGER tax_returns_immutable
BEFORE UPDATE OR DELETE ON tax_returns
FOR EACH ROW EXECUTE FUNCTION trg_tax_return_immutable();

CREATE OR REPLACE FUNCTION trg_tax_return_lines_immutable()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_return_id BIGINT;
    v_status VARCHAR(20);
BEGIN
    IF TG_OP='DELETE' THEN
        v_return_id := OLD.tax_return_id;
    ELSE
        v_return_id := NEW.tax_return_id;
    END IF;
    SELECT status INTO v_status FROM impostos.tax_returns WHERE id=v_return_id;
    IF v_status IN ('submetida','paga') THEN
        RAISE EXCEPTION 'Linhas de declaracao submetida sao imutaveis';
    END IF;
    IF TG_OP='DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS tax_return_lines_immutable ON tax_return_lines;
CREATE TRIGGER tax_return_lines_immutable
BEFORE INSERT OR UPDATE OR DELETE ON tax_return_lines
FOR EACH ROW EXECUTE FUNCTION trg_tax_return_lines_immutable();
