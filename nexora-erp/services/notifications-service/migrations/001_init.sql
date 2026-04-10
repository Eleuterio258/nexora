CREATE TABLE IF NOT EXISTS notification_channels (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('email','sms','whatsapp','push')),
    configuracao JSONB,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_notification_channels UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS notification_templates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    canal_tipo VARCHAR(20) NOT NULL CHECK (canal_tipo IN ('email','sms','whatsapp','push')),
    assunto VARCHAR(150),
    corpo TEXT NOT NULL,
    variaveis JSONB,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_notification_templates UNIQUE (tenant_id, codigo, canal_tipo)
);

CREATE TABLE IF NOT EXISTS notification_messages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    channel_id BIGINT,
    template_id BIGINT,
    canal_tipo VARCHAR(20) NOT NULL CHECK (canal_tipo IN ('email','sms','whatsapp','push')),
    destinatario VARCHAR(180) NOT NULL,
    assunto VARCHAR(150),
    corpo TEXT NOT NULL,
    payload JSONB,
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','enviado','falha','cancelado')),
    tentativas INTEGER NOT NULL DEFAULT 0,
    erro TEXT,
    enviado_em TIMESTAMPTZ,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notification_messages_channel FOREIGN KEY (channel_id) REFERENCES notification_channels(id) ON DELETE SET NULL,
    CONSTRAINT fk_notification_messages_template FOREIGN KEY (template_id) REFERENCES notification_templates(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_notification_channels_tenant ON notification_channels (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_notification_templates_tenant ON notification_templates (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_notification_messages_tenant_status ON notification_messages (tenant_id, status, created_at DESC);
