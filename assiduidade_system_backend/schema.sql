CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('COLABORADOR', 'GESTOR_RH', 'ADMIN_SISTEMA', 'AUDITOR');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status') THEN
        CREATE TYPE user_status AS ENUM ('ACTIVE', 'INACTIVE', 'TERMINATED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'device_type') THEN
        CREATE TYPE device_type AS ENUM ('WEB', 'MOBILE', 'TOTEM', 'KIOSK', 'API');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'device_status') THEN
        CREATE TYPE device_status AS ENUM ('ACTIVE', 'INACTIVE', 'BLOCKED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'clock_event_type') THEN
        CREATE TYPE clock_event_type AS ENUM ('ENTRY', 'BREAK_START', 'BREAK_END', 'EXIT');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'source_type') THEN
        CREATE TYPE source_type AS ENUM ('ONLINE', 'OFFLINE_SYNC', 'MANUAL', 'INTEGRATION');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sync_status') THEN
        CREATE TYPE sync_status AS ENUM ('SYNCED', 'PENDING', 'FAILED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'template_status') THEN
        CREATE TYPE template_status AS ENUM ('ACTIVE', 'REVOKED', 'DELETED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'adjustment_status') THEN
        CREATE TYPE adjustment_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'legal_basis_type') THEN
        CREATE TYPE legal_basis_type AS ENUM ('CONSENT', 'LEGAL_OBLIGATION', 'LEGITIMATE_INTEREST');
    END IF;
END$$;

CREATE TABLE IF NOT EXISTS units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    timezone VARCHAR(100) NOT NULL DEFAULT 'Africa/Maputo',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_code VARCHAR(50) NOT NULL UNIQUE,
    full_name VARCHAR(200) NOT NULL,
    email VARCHAR(200),
    password_hash VARCHAR(255) NOT NULL,
    unit_id UUID REFERENCES units(id),
    role user_role NOT NULL DEFAULT 'COLABORADOR',
    status user_status NOT NULL DEFAULT 'ACTIVE',
    hired_at DATE,
    terminated_at DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_code VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(150) NOT NULL,
    unit_id UUID REFERENCES units(id),
    type device_type NOT NULL,
    status device_status NOT NULL DEFAULT 'ACTIVE',
    last_seen_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    term_version VARCHAR(30) NOT NULL,
    consent_hash VARCHAR(128) NOT NULL,
    legal_basis legal_basis_type NOT NULL DEFAULT 'CONSENT',
    accepted_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS face_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    consent_id UUID NOT NULL REFERENCES consents(id),
    model_version VARCHAR(50) NOT NULL,
    embedding BYTEA NOT NULL,
    quality_score NUMERIC(5,4),
    status template_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS clock_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    idempotency_key VARCHAR(100) NOT NULL UNIQUE,
    user_id UUID NOT NULL REFERENCES users(id),
    device_id UUID REFERENCES devices(id),
    event_type clock_event_type NOT NULL,
    source source_type NOT NULL,
    sync_status sync_status NOT NULL DEFAULT 'SYNCED',
    recorded_at TIMESTAMPTZ NOT NULL,
    confidence_score NUMERIC(5,4),
    liveness_score NUMERIC(5,4),
    geo_lat NUMERIC(10,7),
    geo_lng NUMERIC(10,7),
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS adjustment_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    clock_record_id UUID REFERENCES clock_records(id),
    requested_event_type clock_event_type,
    requested_recorded_at TIMESTAMPTZ,
    reason TEXT NOT NULL,
    status adjustment_status NOT NULL DEFAULT 'PENDING',
    reviewer_id UUID REFERENCES users(id),
    review_notes TEXT,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES users(id),
    actor_type VARCHAR(50) NOT NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id UUID,
    payload_hash VARCHAR(128) NOT NULL,
    previous_hash VARCHAR(128),
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS integration_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_name VARCHAR(100) NOT NULL,
    requested_by UUID REFERENCES users(id),
    status VARCHAR(30) NOT NULL,
    total_records INTEGER NOT NULL DEFAULT 0,
    accepted_records INTEGER NOT NULL DEFAULT 0,
    rejected_records INTEGER NOT NULL DEFAULT 0,
    request_payload JSONB,
    response_payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_users_unit_id ON users(unit_id);
CREATE INDEX IF NOT EXISTS idx_devices_unit_id ON devices(unit_id);
CREATE INDEX IF NOT EXISTS idx_consents_user_id ON consents(user_id);
CREATE INDEX IF NOT EXISTS idx_face_templates_user_id ON face_templates(user_id);
CREATE INDEX IF NOT EXISTS idx_face_templates_status ON face_templates(status);
CREATE INDEX IF NOT EXISTS idx_clock_records_user_recorded_at ON clock_records(user_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_clock_records_device_id ON clock_records(device_id);
CREATE INDEX IF NOT EXISTS idx_clock_records_sync_status ON clock_records(sync_status);
CREATE INDEX IF NOT EXISTS idx_adjustment_requests_user_id ON adjustment_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_adjustment_requests_status ON adjustment_requests(status);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
