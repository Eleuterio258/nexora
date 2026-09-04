CREATE SCHEMA IF NOT EXISTS integration;

CREATE TABLE integration.inbox_events (
    id BIGSERIAL PRIMARY KEY,
    source_service VARCHAR(50) NOT NULL,
    event_id VARCHAR(100) NOT NULL,
    event_type VARCHAR(120) NOT NULL,
    tenant_id BIGINT NOT NULL,
    payload JSONB NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_inbox_source_event UNIQUE (source_service, event_id)
);

CREATE INDEX idx_inbox_events_received_at ON integration.inbox_events (received_at);
