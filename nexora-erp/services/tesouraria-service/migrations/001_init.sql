CREATE TABLE IF NOT EXISTS contas_bancarias (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    banco VARCHAR(120) NOT NULL,
    numero_conta VARCHAR(60) NOT NULL,
    nib VARCHAR(60),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    saldo_atual NUMERIC(18,2) NOT NULL DEFAULT 0,
    ativa BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS caixas (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    nome VARCHAR(120) NOT NULL,
    saldo_atual NUMERIC(18,2) NOT NULL DEFAULT 0,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS movimentos_financeiros (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    origem_tipo VARCHAR(30) NOT NULL CHECK (origem_tipo IN ('faturacao','compras','rh','ajuste')),
    origem_id BIGINT,
    conta_bancaria_id BIGINT,
    caixa_id BIGINT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('recebimento','pagamento','transferencia','ajuste')),
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    referencia VARCHAR(100),
    descricao TEXT,
    data_movimento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_mov_conta FOREIGN KEY (conta_bancaria_id) REFERENCES contas_bancarias(id) ON DELETE SET NULL,
    CONSTRAINT fk_mov_caixa FOREIGN KEY (caixa_id) REFERENCES caixas(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS reconciliacoes_bancarias (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    conta_bancaria_id BIGINT NOT NULL,
    periodo_inicio DATE NOT NULL,
    periodo_fim DATE NOT NULL,
    saldo_extrato NUMERIC(18,2) NOT NULL,
    saldo_sistema NUMERIC(18,2) NOT NULL,
    diferenca NUMERIC(18,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'aberta' CHECK (status IN ('aberta','fechada')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reconciliacoes_conta FOREIGN KEY (conta_bancaria_id) REFERENCES contas_bancarias(id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS idx_contas_bancarias_tenant_id ON contas_bancarias (tenant_id);
CREATE INDEX IF NOT EXISTS idx_caixas_tenant_id ON caixas (tenant_id);
CREATE INDEX IF NOT EXISTS idx_movimentos_tenant_id ON movimentos_financeiros (tenant_id);
CREATE INDEX IF NOT EXISTS idx_reconciliacoes_conta_id ON reconciliacoes_bancarias (conta_bancaria_id);
