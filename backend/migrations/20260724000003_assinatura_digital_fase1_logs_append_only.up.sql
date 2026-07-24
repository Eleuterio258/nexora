-- Assinatura digital — Fase 1 (continuação): a hardening migration anterior
-- (20260724000001) tornou versoes_assinadas e validacoes append-only mas
-- deixou de fora assinatura_digital.logs, que é também uma evidência (trilha
-- de auditoria) e não deve poder ser alterada ou eliminada pela aplicação.
DROP TRIGGER IF EXISTS trg_logs_append_only
    ON assinatura_digital.logs;
CREATE TRIGGER trg_logs_append_only
    BEFORE UPDATE OR DELETE ON assinatura_digital.logs
    FOR EACH ROW EXECUTE FUNCTION assinatura_digital.evidencia_append_only();
