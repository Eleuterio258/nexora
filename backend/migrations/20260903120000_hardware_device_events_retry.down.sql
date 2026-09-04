DROP INDEX IF EXISTS hardware.idx_hardware_events_retry;

ALTER TABLE hardware.device_events
    DROP COLUMN IF EXISTS locked_by,
    DROP COLUMN IF EXISTS locked_at,
    DROP COLUMN IF EXISTS available_at,
    DROP COLUMN IF EXISTS attempts,
    DROP COLUMN IF EXISTS permanent_failure,
    DROP COLUMN IF EXISTS normalized_payload;
