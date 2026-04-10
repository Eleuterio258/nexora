CREATE TABLE IF NOT EXISTS security_policies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    configuracao JSONB NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_security_policies UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS security_ip_allowlist (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    descricao VARCHAR(150),
    ip_or_cidr VARCHAR(80) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_security_ip_allowlist UNIQUE (tenant_id, ip_or_cidr)
);

CREATE TABLE IF NOT EXISTS security_mfa_enrollments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    metodo VARCHAR(20) NOT NULL DEFAULT 'totp' CHECK (metodo IN ('totp','sms','email')),
    secret VARCHAR(255) NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    last_verified_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_security_mfa_user_method UNIQUE (tenant_id, user_id, metodo)
);

CREATE INDEX IF NOT EXISTS idx_security_policies_tenant ON security_policies (tenant_id);
CREATE INDEX IF NOT EXISTS idx_security_ip_allowlist_tenant ON security_ip_allowlist (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_security_mfa_enrollments_tenant ON security_mfa_enrollments (tenant_id, user_id);
