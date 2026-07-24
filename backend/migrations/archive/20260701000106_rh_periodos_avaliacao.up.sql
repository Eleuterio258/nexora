-- 106_rh_periodos_avaliacao.up.sql
-- Cria periodos_avaliacao a partir dos valores varchar existentes em rh.avaliacoes
-- e popula rh.avaliacoes.periodo_id.
--
-- "2026-1o Semestre"  → Jan 2026 – Jun 2026
-- "2026-2o Semestre"  → Jul 2026 – Dez 2026
-- Qualquer outro valor → data_inicio/data_fim = NULL (colunas tornadas nullable abaixo)

-- 1. Tornar data_inicio e data_fim nullable para suportar períodos sem data definida
ALTER TABLE rh.periodos_avaliacao
    ALTER COLUMN data_inicio DROP NOT NULL,
    ALTER COLUMN data_fim    DROP NOT NULL;

-- 2. Criar periodos_avaliacao para cada combinação (tenant_id, periodo) que não existe ainda
INSERT INTO rh.periodos_avaliacao (tenant_id, nome, data_inicio, data_fim, estado)
SELECT DISTINCT
    a.tenant_id,
    a.periodo,
    CASE
        WHEN a.periodo ~ '^\d{4}-1o Semestre$'
            THEN (substring(a.periodo, 1, 4) || '-01-01')::date
        WHEN a.periodo ~ '^\d{4}-2o Semestre$'
            THEN (substring(a.periodo, 1, 4) || '-07-01')::date
        ELSE NULL
    END,
    CASE
        WHEN a.periodo ~ '^\d{4}-1o Semestre$'
            THEN (substring(a.periodo, 1, 4) || '-06-30')::date
        WHEN a.periodo ~ '^\d{4}-2o Semestre$'
            THEN (substring(a.periodo, 1, 4) || '-12-31')::date
        ELSE NULL
    END,
    'encerrado'
  FROM rh.avaliacoes a
 WHERE a.periodo IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM rh.periodos_avaliacao p
        WHERE p.tenant_id = a.tenant_id AND p.nome = a.periodo
   );

-- 3. Popular periodo_id nas avaliações por correspondência de nome
UPDATE rh.avaliacoes a
   SET periodo_id = p.id
  FROM rh.periodos_avaliacao p
 WHERE p.tenant_id = a.tenant_id
   AND p.nome = a.periodo
   AND a.periodo_id IS NULL;
