DROP INDEX IF EXISTS idx_pos_sales_funcionario;
DROP INDEX IF EXISTS idx_pos_sessions_funcionario;
ALTER TABLE pos.pos_sales DROP COLUMN IF EXISTS funcionario_id;
ALTER TABLE pos.pos_sessions DROP COLUMN IF EXISTS funcionario_id;
