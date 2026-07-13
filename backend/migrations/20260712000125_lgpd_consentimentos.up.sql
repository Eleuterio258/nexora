-- ═══════════════════════════════════════════════════════════════
--  Consentimentos LGPD (recolha de dados biométricos)
--  Substitui, do lado do ERP, o que o FaceClock previa localmente em
--  `POST/GET /consents*` antes do modelo stateless — ver
--  CONTRATO-INTEGRACAO-ERP.md secção 9 e proposta-arquitetura-assiduidade-erp.md
--  tarefa 6.3.
--
--  Autenticado por API Key de device (o FaceClock é quem submete/consulta em
--  nome do funcionario indicado, tal como já faz para eventos de presença) —
--  não por Bearer de utilizador, porque o consentimento é capturado no
--  momento do enrolamento biométrico na app, antes de haver sessão ERP activa.
-- ═══════════════════════════════════════════════════════════════

CREATE SCHEMA IF NOT EXISTS lgpd;

CREATE TABLE IF NOT EXISTS lgpd.consentimentos (
    id             BIGSERIAL PRIMARY KEY,
    tenant_id      BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES rh.funcionarios(id) ON DELETE CASCADE,
    termo_versao   VARCHAR(20) NOT NULL,
    termo_hash     VARCHAR(128) NOT NULL,
    aceite_em      TIMESTAMPTZ NOT NULL,
    ip_address     VARCHAR(64),
    revogado_em    TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_consentimentos_funcionario ON lgpd.consentimentos (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_consentimentos_tenant ON lgpd.consentimentos (tenant_id);
