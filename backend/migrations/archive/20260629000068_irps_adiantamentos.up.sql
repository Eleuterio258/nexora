-- ═══════════════════════════════════════════════════════════════
--  IRPS Escalões + Adiantamentos/Empréstimos
-- ═══════════════════════════════════════════════════════════════
SET search_path TO rh, public;

-- ── IRPS Escalões ────────────────────────────────────────────────────────────
-- Escalões de IRPS configuráveis por tenant e ano fiscal.
-- Default = escalões de Moçambique 2024 (tabela 2 – assalariados).
CREATE TABLE IF NOT EXISTS irps_escaloes (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    ano_fiscal  INTEGER NOT NULL DEFAULT 2024,
    limite_inf  NUMERIC(14,2) NOT NULL DEFAULT 0,   -- rendimento mensal mínimo
    limite_sup  NUMERIC(14,2),                       -- NULL = sem limite superior
    taxa        NUMERIC(5,4) NOT NULL,               -- 0.10 = 10%
    parcela_ded NUMERIC(14,2) NOT NULL DEFAULT 0,    -- parcela a abater
    ativo       BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_irps_escaloes_tenant_ano_inf UNIQUE (tenant_id, ano_fiscal, limite_inf)
);
CREATE INDEX IF NOT EXISTS idx_irps_escaloes_tenant ON irps_escaloes (tenant_id, ano_fiscal);

-- Escalões padrão Moçambique 2024 para novos tenants (inseridos via trigger ou aplicação)
-- Valores mensais em MZN conforme Decreto 79/2018 e tabelas IRPS 2024:
-- 0 – 3,500        → isento  (0%)
-- 3,500.01–10,000  → 10%   – 350
-- 10,000.01–20,000 → 15%   – 850
-- 20,000.01–38,000 → 20%   – 1,850
-- 38,000.01+       → 32%   – 6,410

-- ── Adiantamentos ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS adiantamentos (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id       BIGINT NOT NULL,
    funcionario_id  BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    valor_total     NUMERIC(14,2) NOT NULL,
    num_prestacoes  INTEGER NOT NULL DEFAULT 1,
    prestacao_valor NUMERIC(14,2) NOT NULL,
    prestacoes_pagas INTEGER NOT NULL DEFAULT 0,
    estado          VARCHAR(20) NOT NULL DEFAULT 'ativo'
                        CHECK (estado IN ('ativo', 'quitado', 'cancelado')),
    descricao       TEXT,
    data_inicio     DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_adiantamentos_funcionario ON adiantamentos (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_adiantamentos_tenant     ON adiantamentos (tenant_id, estado);

-- ── Empréstimos ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS emprestimos (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id       BIGINT NOT NULL,
    funcionario_id  BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    valor_total     NUMERIC(14,2) NOT NULL,
    num_prestacoes  INTEGER NOT NULL DEFAULT 1,
    prestacao_valor NUMERIC(14,2) NOT NULL,
    prestacoes_pagas INTEGER NOT NULL DEFAULT 0,
    taxa_juros      NUMERIC(5,4) NOT NULL DEFAULT 0, -- 0 = sem juros
    estado          VARCHAR(20) NOT NULL DEFAULT 'ativo'
                        CHECK (estado IN ('ativo', 'quitado', 'cancelado')),
    descricao       TEXT,
    data_inicio     DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_emprestimos_funcionario ON emprestimos (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_emprestimos_tenant     ON emprestimos (tenant_id, estado);
