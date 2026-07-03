SET search_path TO rh, public;

-- ── Folhas de Pagamento (processamento salarial mensal) ─────────────────────
CREATE TABLE IF NOT EXISTS folhas_pagamento (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ano INTEGER NOT NULL,
    mes INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
    estado VARCHAR(20) NOT NULL DEFAULT 'aberta'
        CHECK (estado IN ('aberta', 'processada', 'paga', 'cancelada')),
    num_funcionarios INTEGER NOT NULL DEFAULT 0,
    total_proventos NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_descontos NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_liquido NUMERIC(14,2) NOT NULL DEFAULT 0,
    processada_em TIMESTAMPTZ,
    processada_por BIGINT,
    paga_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- processada_por referencia auth.users (sem FK)
    CONSTRAINT uq_folhas_pagamento_tenant_ano_mes UNIQUE (tenant_id, ano, mes)
);
CREATE INDEX IF NOT EXISTS idx_folhas_pagamento_tenant_id ON folhas_pagamento (tenant_id);

-- ── Recibos de Vencimento (snapshot por funcionário, por folha) ─────────────
CREATE TABLE IF NOT EXISTS recibos_vencimento (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    folha_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL,
    salario_base NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_proventos NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_descontos NUMERIC(14,2) NOT NULL DEFAULT 0,
    salario_liquido NUMERIC(14,2) NOT NULL DEFAULT 0,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (estado IN ('pendente', 'pago')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_recibos_vencimento_folha FOREIGN KEY (folha_id) REFERENCES folhas_pagamento(id) ON DELETE CASCADE,
    CONSTRAINT fk_recibos_vencimento_funcionario FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id) ON DELETE CASCADE,
    CONSTRAINT uq_recibos_vencimento_folha_funcionario UNIQUE (folha_id, funcionario_id)
);
CREATE INDEX IF NOT EXISTS idx_recibos_vencimento_tenant_id ON recibos_vencimento (tenant_id);
CREATE INDEX IF NOT EXISTS idx_recibos_vencimento_folha_id ON recibos_vencimento (folha_id);
CREATE INDEX IF NOT EXISTS idx_recibos_vencimento_funcionario_id ON recibos_vencimento (funcionario_id);

-- ── Itens do Recibo de Vencimento (detalhe dos componentes salariais) ───────
CREATE TABLE IF NOT EXISTS recibo_vencimento_itens (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recibo_id BIGINT NOT NULL,
    componente_id BIGINT,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('provento', 'desconto')),
    valor NUMERIC(14,2) NOT NULL,
    -- componente_id referencia componentes_salariais (sem FK; preserva o histórico caso o componente seja eliminado)
    CONSTRAINT fk_recibo_vencimento_itens_recibo FOREIGN KEY (recibo_id) REFERENCES recibos_vencimento(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_recibo_vencimento_itens_recibo_id ON recibo_vencimento_itens (recibo_id);
