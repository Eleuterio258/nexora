ALTER TABLE gestao_escolar.school_terms
    ADD COLUMN IF NOT EXISTS level_id BIGINT
        REFERENCES gestao_escolar.school_levels(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_school_terms_level ON gestao_escolar.school_terms(level_id);
