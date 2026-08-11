-- Garante que uma conta técnica de terminal nunca possa ser ligada a
-- rh.funcionarios. O terminal é uma máquina, não uma pessoa.

CREATE OR REPLACE FUNCTION pos.impedir_terminal_como_funcionario()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM rh.funcionarios WHERE user_id = NEW.user_id) THEN
        RAISE EXCEPTION 'Conta técnica de terminal não pode estar ligada a rh.funcionarios';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tg_pos_terminals_user_id_check ON pos.pos_terminals;
CREATE TRIGGER tg_pos_terminals_user_id_check
BEFORE INSERT OR UPDATE ON pos.pos_terminals
FOR EACH ROW EXECUTE FUNCTION pos.impedir_terminal_como_funcionario();
