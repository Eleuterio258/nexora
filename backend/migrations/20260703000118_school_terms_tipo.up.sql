-- Adiciona campo `tipo` a school_terms para suportar diferentes estruturas
-- de períodos: trimestre, semestre, bimestre, módulo, etc.
-- Também adiciona `ordem` para ordenação explícita dentro do ano.
ALTER TABLE gestao_escolar.school_terms
    ADD COLUMN IF NOT EXISTS tipo VARCHAR(30) NOT NULL DEFAULT 'trimestre'
        CHECK (tipo IN ('trimestre','semestre','bimestre','modulo','outro')),
    ADD COLUMN IF NOT EXISTS ordem INTEGER NOT NULL DEFAULT 0;

-- Preencher ordem com base na data_inicio
UPDATE gestao_escolar.school_terms t
SET ordem = sub.rn
FROM (
    SELECT id, ROW_NUMBER() OVER (PARTITION BY school_year_id ORDER BY data_inicio) AS rn
    FROM gestao_escolar.school_terms
) sub
WHERE t.id = sub.id;
