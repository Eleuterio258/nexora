-- Fase 1 do roteiro do módulo assinatura-digital: vínculo signatário/utilizador,
-- convite + OTP, recusa, ordem imposta, permissão de assinar separada e logs imutáveis.

-- Vínculo signatário ↔ utilizador ERP (fluxo interno autenticado) e suporte a recusa.
ALTER TABLE assinatura_digital.signatarios
    ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS motivo_recusa TEXT,
    ADD COLUMN IF NOT EXISTS recusado_em TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_signatarios_user ON assinatura_digital.signatarios(user_id);

-- Convites únicos (token + OTP) para assinatura sem sessão ERP.
CREATE TABLE IF NOT EXISTS assinatura_digital.convites (
    id                BIGSERIAL PRIMARY KEY,
    documento_id      BIGINT NOT NULL REFERENCES assinatura_digital.documentos(id),
    signatario_id     BIGINT NOT NULL REFERENCES assinatura_digital.signatarios(id),
    tenant_id         BIGINT NOT NULL,
    token_hash        VARCHAR(64) NOT NULL UNIQUE,
    expira_em         TIMESTAMPTZ NOT NULL,
    usado_em          TIMESTAMPTZ,
    otp_hash          VARCHAR(100),
    otp_expira_em     TIMESTAMPTZ,
    otp_tentativas    INT NOT NULL DEFAULT 0,
    otp_confirmado_em TIMESTAMPTZ,
    created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_convites_signatario ON assinatura_digital.convites(signatario_id);
CREATE INDEX IF NOT EXISTS idx_convites_tenant ON assinatura_digital.convites(tenant_id);

-- Logs de auditoria imutáveis: apagar um documento com logs deve falhar (em vez de
-- destruir evidência silenciosamente), e UPDATE/DELETE directo sobre logs é proibido.
ALTER TABLE assinatura_digital.logs DROP CONSTRAINT IF EXISTS logs_documento_id_fkey;
ALTER TABLE assinatura_digital.logs
    ADD CONSTRAINT logs_documento_id_fkey FOREIGN KEY (documento_id)
    REFERENCES assinatura_digital.documentos(id);

CREATE OR REPLACE FUNCTION assinatura_digital.logs_imutavel() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'Os logs de assinatura digital são imutáveis e não podem ser alterados nem eliminados';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_logs_imutavel ON assinatura_digital.logs;
CREATE TRIGGER trg_logs_imutavel
    BEFORE UPDATE OR DELETE ON assinatura_digital.logs
    FOR EACH ROW EXECUTE FUNCTION assinatura_digital.logs_imutavel();

-- Permissão própria para assinar, separada de gerir_documentos.
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT id, 'assinatura-digital', 'assinar_documentos'
FROM auth.cargos
WHERE nome = 'Administrador'
ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;
