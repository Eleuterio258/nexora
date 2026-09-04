DROP INDEX IF EXISTS notifications.idx_notification_messages_dispatch;

ALTER TABLE notifications.notification_messages
    DROP CONSTRAINT notification_messages_status_check;
ALTER TABLE notifications.notification_messages
    ADD CONSTRAINT notification_messages_status_check
    CHECK (((status)::text = ANY (ARRAY[
        ('pendente'::character varying)::text,
        ('enviado'::character varying)::text,
        ('falha'::character varying)::text,
        ('cancelado'::character varying)::text
    ])));

ALTER TABLE notifications.notification_messages
    DROP COLUMN IF EXISTS locked_by,
    DROP COLUMN IF EXISTS locked_at,
    DROP COLUMN IF EXISTS available_at;
