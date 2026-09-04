ALTER TABLE hardware.device_events
    ADD COLUMN IF NOT EXISTS normalized_payload JSONB,
    ADD COLUMN IF NOT EXISTS permanent_failure BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS attempts INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS locked_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS locked_by VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_hardware_events_retry
    ON hardware.device_events (available_at, created_at)
    WHERE processed = FALSE AND permanent_failure = FALSE;
