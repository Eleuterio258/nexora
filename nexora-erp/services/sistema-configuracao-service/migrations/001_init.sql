CREATE TABLE IF NOT EXISTS tenant_branding (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL UNIQUE,
    logo_url TEXT,
    cor_primaria VARCHAR(20),
    cor_secundaria VARCHAR(20),
    slogan VARCHAR(150),
    website_url TEXT,
    suporte_email VARCHAR(150),
    suporte_telefone VARCHAR(30),
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_defaults (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    chave VARCHAR(100) NOT NULL,
    valor TEXT,
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenant_defaults UNIQUE (tenant_id, chave)
);

CREATE TABLE IF NOT EXISTS tenant_document_settings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    modulo VARCHAR(50) NOT NULL,
    tipo_documento VARCHAR(50) NOT NULL,
    prefixo VARCHAR(20),
    reinicia_anualmente BOOLEAN NOT NULL DEFAULT TRUE,
    serie_activa VARCHAR(20),
    layout_template VARCHAR(100),
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenant_document_settings UNIQUE (tenant_id, modulo, tipo_documento)
);

CREATE TABLE IF NOT EXISTS tenant_feature_flags (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(100) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT FALSE,
    configuracao JSONB,
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenant_feature_flags UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS tenant_integrations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(100) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT FALSE,
    endpoint_url TEXT,
    credenciais JSONB,
    configuracao JSONB,
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenant_integrations UNIQUE (tenant_id, codigo)
);

CREATE INDEX IF NOT EXISTS idx_tenant_defaults_tenant ON tenant_defaults (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_document_settings_tenant ON tenant_document_settings (tenant_id, modulo);
CREATE INDEX IF NOT EXISTS idx_tenant_feature_flags_tenant ON tenant_feature_flags (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_integrations_tenant ON tenant_integrations (tenant_id);
