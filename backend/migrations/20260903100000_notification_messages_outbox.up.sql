ALTER TABLE notifications.notification_messages
    ADD COLUMN IF NOT EXISTS available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS locked_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS locked_by VARCHAR(100);

ALTER TABLE notifications.notification_messages
    DROP CONSTRAINT notification_messages_status_check;
ALTER TABLE notifications.notification_messages
    ADD CONSTRAINT notification_messages_status_check
    CHECK (((status)::text = ANY (ARRAY[
        ('pendente'::character varying)::text,
        ('processando'::character varying)::text,
        ('enviado'::character varying)::text,
        ('falha'::character varying)::text,
        ('cancelado'::character varying)::text
    ])));

CREATE INDEX IF NOT EXISTS idx_notification_messages_dispatch
    ON notifications.notification_messages (available_at, created_at)
    WHERE status = 'pendente';
