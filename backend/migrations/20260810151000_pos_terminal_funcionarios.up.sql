-- Tabela de autorização opcional: quais funcionários podem operar cada terminal.
-- Quando não houver linhas para um terminal, o comportamento pode ser configurado
-- como permissivo (padrão) ou restritivo por tenant.

CREATE TABLE IF NOT EXISTS pos.terminal_funcionarios (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       BIGINT NOT NULL REFERENCES public.tenants(id),
    terminal_id     BIGINT NOT NULL REFERENCES pos.pos_terminals(id),
    funcionario_id  BIGINT NOT NULL REFERENCES rh.funcionarios(id),
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    valido_de       TIMESTAMPTZ,
    valido_ate      TIMESTAMPTZ,
    atribuido_por   BIGINT REFERENCES auth.users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, terminal_id, funcionario_id)
);

CREATE INDEX IF NOT EXISTS idx_terminal_funcionarios_terminal ON pos.terminal_funcionarios(terminal_id);
CREATE INDEX IF NOT EXISTS idx_terminal_funcionarios_funcionario ON pos.terminal_funcionarios(funcionario_id);

-- Evitar duas sessões abertas no mesmo terminal (Fase 3).
CREATE UNIQUE INDEX IF NOT EXISTS idx_pos_sessions_unica_aberta_terminal
ON pos.pos_sessions (tenant_id, terminal_id)
WHERE status = 'aberta';
