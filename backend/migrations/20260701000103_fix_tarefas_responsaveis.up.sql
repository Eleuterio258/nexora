-- 103_fix_tarefas_responsaveis.up.sql
-- Remove user_id de tarefas.cartoes.responsaveis quando o utilizador é eliminado.
-- Necessário porque responsaveis é integer[] sem FK referencial.

CREATE OR REPLACE FUNCTION tarefas.fn_remove_user_from_cartoes()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE tarefas.cartoes
       SET responsaveis = array_remove(responsaveis, OLD.id::integer)
     WHERE OLD.id::integer = ANY(responsaveis);
    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_remove_user_from_cartoes ON auth.users;

CREATE TRIGGER trg_remove_user_from_cartoes
    BEFORE DELETE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION tarefas.fn_remove_user_from_cartoes();
