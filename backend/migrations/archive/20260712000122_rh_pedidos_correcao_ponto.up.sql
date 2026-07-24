-- ═══════════════════════════════════════════════════════════════
--  Pedidos de correção de ponto (self-service)
--  Substitui, do lado do ERP, o que o FaceClock previa localmente em
--  `POST/GET/DELETE /clock/adjustments*` antes do modelo stateless — ver
--  CONTRATO-INTEGRACAO-ERP.md secção 9 e proposta-arquitetura-assiduidade-erp.md
--  tarefa 6.2. Distinto de `rh.justificacoes` (falta/atraso, sem referência a
--  um registo de presença nem horas propostas): aqui o colaborador aponta o
--  dia (e o registo de presença, se existir) e propõe as horas correctas.
-- ═══════════════════════════════════════════════════════════════

SET search_path TO rh, public;

CREATE TABLE IF NOT EXISTS pedidos_correcao_ponto (
    id                      BIGSERIAL PRIMARY KEY,
    tenant_id               BIGINT NOT NULL,
    funcionario_id          BIGINT NOT NULL REFERENCES funcionarios(id) ON DELETE CASCADE,
    presenca_id             BIGINT REFERENCES presencas(id) ON DELETE SET NULL,
    data                    DATE NOT NULL,
    hora_entrada_solicitada VARCHAR(5),
    hora_saida_solicitada   VARCHAR(5),
    motivo                  TEXT NOT NULL,
    estado                  VARCHAR(20) NOT NULL DEFAULT 'pendente'
                                CHECK (estado IN ('pendente','aprovado','rejeitado','cancelado')),
    decidido_por            BIGINT REFERENCES auth.users(id),
    decidido_em             TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_correcao_ponto_funcionario ON pedidos_correcao_ponto (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_correcao_ponto_tenant_estado ON pedidos_correcao_ponto (tenant_id, estado);
