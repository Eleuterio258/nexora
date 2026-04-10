CREATE TABLE IF NOT EXISTS audit_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    actor_user_id BIGINT,
    actor_email VARCHAR(150),
    actor_nome VARCHAR(150),
    service_name VARCHAR(100) NOT NULL,
    module_name VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id VARCHAR(100),
    status VARCHAR(20) NOT NULL DEFAULT 'sucesso' CHECK (status IN ('sucesso','falha','alerta')),
    ip_address VARCHAR(64),
    user_agent TEXT,
    metadata JSONB,
    payload_before JSONB,
    payload_after JSONB,
    previous_hash VARCHAR(64),
    event_hash VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_created ON audit_events (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_service ON audit_events (tenant_id, service_name, module_name);
CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_entity ON audit_events (tenant_id, entity_type, entity_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_audit_events_hash ON audit_events (event_hash);
