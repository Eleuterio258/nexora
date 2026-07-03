-- Adiciona colunas de account lockout ao portal do aluno.
-- Bloqueia o acesso após 5 tentativas falhadas por 30 minutos.
ALTER TABLE gestao_escolar.school_students
    ADD COLUMN IF NOT EXISTS portal_login_tentativas  int         NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS portal_bloqueado_ate     timestamptz;
