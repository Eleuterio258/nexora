-- Garantir que todos os registos existentes têm level_id antes de tornar NOT NULL.
-- Atribui o primeiro nível disponível do mesmo tenant a períodos sem nível.
UPDATE gestao_escolar.school_terms t
SET level_id = (
    SELECT sl.id
    FROM gestao_escolar.school_levels sl
    WHERE sl.tenant_id = t.tenant_id
    ORDER BY sl.id
    LIMIT 1
)
WHERE t.level_id IS NULL;

ALTER TABLE gestao_escolar.school_terms
    ALTER COLUMN level_id SET NOT NULL;
