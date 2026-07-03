UPDATE rh.avaliacoes SET periodo_id = NULL;
DELETE FROM rh.periodos_avaliacao WHERE nome LIKE '%-1o Semestre' OR nome LIKE '%-2o Semestre';
ALTER TABLE rh.periodos_avaliacao
    ALTER COLUMN data_inicio SET NOT NULL,
    ALTER COLUMN data_fim    SET NOT NULL;
