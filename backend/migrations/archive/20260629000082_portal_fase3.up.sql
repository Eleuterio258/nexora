-- Fase 3: verificação de email do portal do aluno
ALTER TABLE gestao_escolar.school_students
    ADD COLUMN IF NOT EXISTS portal_email_verificado boolean NOT NULL DEFAULT false;

-- Quando o aluno define a senha via link de convite, o email fica verificado
-- (o link foi enviado para o email → clicar = email existe)
