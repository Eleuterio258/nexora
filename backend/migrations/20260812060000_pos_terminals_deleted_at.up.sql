-- Adiciona soft-delete a pos.pos_terminals e filtra terminais arquivados nas listagens.
--
-- Motivo: o CRUD de terminais precisa de operação de remoção segura, mas
-- terminais com sessões/vendas históricas não podem ser apagados fisicamente
-- por causa das FKs ON DELETE RESTRICT em pos_sessions e pos_sales.

ALTER TABLE pos.pos_terminals
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_pos_terminals_deleted_at
    ON pos.pos_terminals (deleted_at)
    WHERE deleted_at IS NULL;
