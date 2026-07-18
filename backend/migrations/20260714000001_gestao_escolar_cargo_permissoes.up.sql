-- Permissões concedidas a alunos com um determinado cargo de turma (ex.:
-- "delegado"), scoped por turma. Primeiro uso: "marcar_presencas", que
-- autoriza POST /api/portal/aluno/me/turma/presencas a gravar em
-- gestao_escolar.school_attendance na turma onde o aluno tem o cargo activo
-- (ver school_student_roles.cargo).
--
-- Quem CONCEDE é o professor director da turma (school_classes.
-- director_teacher_id) — ver ProfessorPortalCriarCargoPermissao em
-- portal_professor.go — por isso o scope é por class_id, não tenant-wide:
-- o director de uma turma só pode conceder permissões dentro da sua própria
-- turma, nunca noutra.
CREATE TABLE IF NOT EXISTS gestao_escolar.school_cargo_permissoes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    class_id BIGINT NOT NULL REFERENCES gestao_escolar.school_classes(id) ON DELETE CASCADE,
    cargo VARCHAR(100) NOT NULL,
    permissao VARCHAR(100) NOT NULL,
    created_by BIGINT REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, class_id, cargo, permissao)
);

CREATE INDEX IF NOT EXISTS idx_school_cargo_permissoes_lookup
    ON gestao_escolar.school_cargo_permissoes(tenant_id, class_id, cargo, permissao);
