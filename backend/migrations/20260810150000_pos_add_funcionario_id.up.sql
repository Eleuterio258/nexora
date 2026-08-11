-- Adiciona rastreabilidade do operador humano às sessões e vendas POS.
-- O funcionário é a entidade de RH; user_id é a conta técnica que autenticou.

ALTER TABLE pos.pos_sessions ADD COLUMN IF NOT EXISTS funcionario_id BIGINT REFERENCES rh.funcionarios(id);
ALTER TABLE pos.pos_sales ADD COLUMN IF NOT EXISTS funcionario_id BIGINT REFERENCES rh.funcionarios(id);

CREATE INDEX IF NOT EXISTS idx_pos_sessions_funcionario ON pos.pos_sessions(funcionario_id);
CREATE INDEX IF NOT EXISTS idx_pos_sales_funcionario ON pos.pos_sales(funcionario_id);
