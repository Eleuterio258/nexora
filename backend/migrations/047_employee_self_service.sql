-- ═══════════════════════════════════════════════════════════════
--  Employee Self-Service Portal
--  Módulos: Home, Chat, Férias (já existe), Assiduidade, Perfil
-- ═══════════════════════════════════════════════════════════════

-- ── Chat ─────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS chat_conversas (
    id          BIGSERIAL PRIMARY KEY,
    tenant_id   BIGINT    NOT NULL,
    nome        VARCHAR(200),
    tipo        VARCHAR(20) NOT NULL DEFAULT 'individual'  -- individual | grupo
                    CHECK (tipo IN ('individual','grupo')),
    criado_por  BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_chat_conversas_tenant ON chat_conversas (tenant_id);

CREATE TABLE IF NOT EXISTS chat_participantes (
    conversa_id    BIGINT NOT NULL REFERENCES chat_conversas(id) ON DELETE CASCADE,
    user_id        BIGINT NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    adicionado_em  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ultima_leitura TIMESTAMPTZ,
    PRIMARY KEY (conversa_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_chat_part_user ON chat_participantes (user_id);

CREATE TABLE IF NOT EXISTS chat_mensagens (
    id           BIGSERIAL PRIMARY KEY,
    conversa_id  BIGINT NOT NULL REFERENCES chat_conversas(id) ON DELETE CASCADE,
    autor_id     BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    conteudo     TEXT NOT NULL,
    tipo         VARCHAR(20) NOT NULL DEFAULT 'texto'
                     CHECK (tipo IN ('texto','imagem','ficheiro')),
    ficheiro_url VARCHAR(500),
    eliminada    BOOLEAN NOT NULL DEFAULT FALSE,
    editada_em   TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_chat_msg_conversa ON chat_mensagens (conversa_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_msg_autor    ON chat_mensagens (autor_id);

-- ── Comunicados da empresa ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS comunicados (
    id          BIGSERIAL PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    titulo      VARCHAR(300) NOT NULL,
    conteudo    TEXT NOT NULL,
    autor_id    BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    expira_em   TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_comunicados_tenant ON comunicados (tenant_id, created_at DESC);

CREATE TABLE IF NOT EXISTS comunicados_lidos (
    comunicado_id BIGINT NOT NULL REFERENCES comunicados(id) ON DELETE CASCADE,
    user_id       BIGINT NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lido_em       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (comunicado_id, user_id)
);

-- ── Notificações de colaborador ───────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS notif_colaborador (
    id          BIGSERIAL PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    user_id     BIGINT NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tipo        VARCHAR(50)  NOT NULL,    -- ausencia_aprovada | ausencia_rejeitada | comunicado | sistema
    titulo      VARCHAR(300) NOT NULL,
    corpo       TEXT,
    lida        BOOLEAN NOT NULL DEFAULT FALSE,
    link        VARCHAR(500),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notif_colab_user ON notif_colaborador (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notif_colab_nao_lida ON notif_colaborador (user_id) WHERE NOT lida;

-- ── Presença: adicionar coluna gps e observacao se não existir ─────────────

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='rh' AND table_name='presencas') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='rh' AND table_name='presencas' AND column_name='latitude') THEN
            ALTER TABLE rh.presencas ADD COLUMN latitude  NUMERIC(10,7);
            ALTER TABLE rh.presencas ADD COLUMN longitude NUMERIC(10,7);
            ALTER TABLE rh.presencas ADD COLUMN observacao TEXT;
        END IF;
    END IF;
END $$;

-- ── Justificações de ausência/atraso ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS rh.justificacoes (
    id             BIGSERIAL PRIMARY KEY,
    tenant_id      BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL REFERENCES rh.funcionarios(id) ON DELETE CASCADE,
    tipo           VARCHAR(20) NOT NULL DEFAULT 'falta'
                       CHECK (tipo IN ('falta','atraso')),
    data           DATE NOT NULL,
    motivo         TEXT NOT NULL,
    estado         VARCHAR(20) NOT NULL DEFAULT 'pendente'
                       CHECK (estado IN ('pendente','aprovado','rejeitado')),
    ficheiro_url   VARCHAR(500),
    aprovado_por   BIGINT REFERENCES auth.users(id),
    aprovado_em    TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_justif_funcionario ON rh.justificacoes (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_justif_tenant_estado ON rh.justificacoes (tenant_id, estado);
