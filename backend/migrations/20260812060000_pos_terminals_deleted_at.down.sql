-- Reverte a adição de deleted_at a pos.pos_terminals.

DROP INDEX IF EXISTS pos.idx_pos_terminals_deleted_at;

ALTER TABLE pos.pos_terminals
    DROP COLUMN IF EXISTS deleted_at;
