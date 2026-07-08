-- ─────────────────────────────────────────────────────────────────────────────
-- Fix gestao_escolar: colunas em falta, índices, status de propinas
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Adicionar updated_at onde falta ───────────────────────────────────────
ALTER TABLE gestao_escolar.school_terms
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_guardians
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_calendar_event_types
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_course_subjects
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_cycles
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_evaluation_types
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_incident_types
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_sanction_types
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_teacher_assignments
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_series
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_payments
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_transcript_subjects
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_student_merits
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_library_loans
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- ── 2. Adicionar created_at onde falta ───────────────────────────────────────
ALTER TABLE gestao_escolar.portal_sessions
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.guardian_portal_sessions
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE gestao_escolar.school_fee_generations
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- ── 3. Índices em falta ───────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_portal_sessions_tenant
    ON gestao_escolar.portal_sessions(tenant_id, student_id);

CREATE INDEX IF NOT EXISTS idx_grade_items_tenant
    ON gestao_escolar.school_grade_items(tenant_id, class_id, term_id);

CREATE INDEX IF NOT EXISTS idx_grade_items_subject
    ON gestao_escolar.school_grade_items(tenant_id, subject_id);

CREATE INDEX IF NOT EXISTS idx_calendar_events_tenant
    ON gestao_escolar.school_calendar_events(tenant_id, data_inicio);

CREATE INDEX IF NOT EXISTS idx_library_loans_tenant
    ON gestao_escolar.school_library_loans(tenant_id, student_id, status);

CREATE INDEX IF NOT EXISTS idx_student_fee_discounts_tenant
    ON gestao_escolar.school_student_fee_discounts(tenant_id, student_id);

CREATE INDEX IF NOT EXISTS idx_student_merits_tenant
    ON gestao_escolar.school_student_merits(tenant_id, student_id);

CREATE INDEX IF NOT EXISTS idx_student_roles_tenant
    ON gestao_escolar.school_student_roles(tenant_id, student_id);

-- sanctions não tem student_id directo — vem via incident_id
CREATE INDEX IF NOT EXISTS idx_student_sanctions_tenant
    ON gestao_escolar.school_student_sanctions(tenant_id, incident_id);

CREATE INDEX IF NOT EXISTS idx_teacher_roles_tenant
    ON gestao_escolar.school_teacher_roles(tenant_id, teacher_id);

CREATE INDEX IF NOT EXISTS idx_transcript_subjects_tenant
    ON gestao_escolar.school_transcript_subjects(tenant_id);

CREATE INDEX IF NOT EXISTS idx_school_tasks_tenant
    ON gestao_escolar.school_tasks(tenant_id, status);

-- ── 4. Adicionar updated_at nas sessões ──────────────────────────────────────
ALTER TABLE gestao_escolar.portal_sessions
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE gestao_escolar.guardian_portal_sessions
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- ── 5. Propinas vencidas → ampliar constraint e actualizar status ─────────────
ALTER TABLE gestao_escolar.school_fees
    DROP CONSTRAINT IF EXISTS school_fees_status_check;
ALTER TABLE gestao_escolar.school_fees
    ADD CONSTRAINT school_fees_status_check
    CHECK (status IN ('pendente','emitida','parcial','paga','cancelada','vencida'));

UPDATE gestao_escolar.school_fees
SET status = 'vencida', updated_at = NOW()
WHERE status = 'pendente'
  AND data_vencimento < CURRENT_DATE;
