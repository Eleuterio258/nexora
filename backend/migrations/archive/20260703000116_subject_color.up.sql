ALTER TABLE gestao_escolar.school_subjects
  ADD COLUMN IF NOT EXISTS cor VARCHAR(7) DEFAULT NULL;
