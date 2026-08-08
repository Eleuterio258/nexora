-- Fecho de caixa detalhado + movimentações de caixa (suprimento/sangria/
-- depósito) — ver §2.2/§2.3 de docs/backend-go-gaps-paycore.md no repo
-- PayCore. FecharSessao passa a aceitar contagem de notas/moedas e
-- justificativa de diferença; ambos são dados de entrada do operador, por
-- isso são persistidos (o resto do detalhamento — por método de pagamento —
-- continua a ser calculado a partir de pos_sale_payments, nunca duplicado).

ALTER TABLE pos.pos_sessions
    ADD COLUMN IF NOT EXISTS contagem_notas jsonb,
    ADD COLUMN IF NOT EXISTS justificativa_diferenca text;

-- Suprimento (entrada de dinheiro no caixa), sangria (retirada), depósito
-- bancário e "outro" — todos são movimentos FÍSICOS de numerário dentro de
-- uma sessão de caixa aberta, por isso só fazem sentido associados a uma
-- pos_sessions e só entram no cálculo do valor esperado em numerário no
-- fecho (nunca nos outros métodos de pagamento).
CREATE TABLE IF NOT EXISTS pos.pos_cash_movements (
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id      bigint NOT NULL,
    pos_session_id bigint NOT NULL REFERENCES pos.pos_sessions(id) ON DELETE CASCADE,
    tipo           character varying(20) NOT NULL,
    valor          numeric(18,2) NOT NULL,
    motivo         text,
    created_by     bigint,
    created_at     timestamptz NOT NULL DEFAULT NOW(),
    CONSTRAINT pos_cash_movements_tipo_check
        CHECK (tipo IN ('suprimento', 'sangria', 'deposito', 'outro')),
    CONSTRAINT pos_cash_movements_valor_check CHECK (valor > 0)
);

CREATE INDEX IF NOT EXISTS idx_pos_cash_movements_session
    ON pos.pos_cash_movements (pos_session_id);
