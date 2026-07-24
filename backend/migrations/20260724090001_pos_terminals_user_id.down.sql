-- Reverte a adição de pos.pos_terminals.user_id.
DROP INDEX IF EXISTS pos.idx_pos_terminals_user_id;

ALTER TABLE pos.pos_terminals
    DROP CONSTRAINT IF EXISTS pos_terminals_user_id_fkey;

ALTER TABLE pos.pos_terminals
    DROP COLUMN IF EXISTS user_id;
