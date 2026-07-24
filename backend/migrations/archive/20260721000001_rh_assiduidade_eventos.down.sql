-- Rollback do sistema flexível de controlo de assiduidade

SET search_path TO rh, public;

DROP TABLE IF EXISTS auditoria_assiduidade;
DROP TABLE IF EXISTS correcoes_evento;
DROP TABLE IF EXISTS resultados_periodos;
DROP TABLE IF EXISTS resultados_diarios;
DROP TABLE IF EXISTS eventos_assiduidade;
DROP TABLE IF EXISTS regras_assiduidade;
DROP TABLE IF EXISTS tipos_regra;
DROP TABLE IF EXISTS funcionario_horarios;
DROP TABLE IF EXISTS horarios_dias;
DROP TABLE IF EXISTS metodos_marcacao;
DROP TABLE IF EXISTS tipos_evento;

ALTER TABLE horarios_trabalho
    DROP COLUMN IF EXISTS tipo,
    DROP COLUMN IF EXISTS contagem,
    DROP COLUMN IF EXISTS carga_diaria_minima,
    DROP COLUMN IF EXISTS carga_diaria_maxima,
    DROP COLUMN IF EXISTS carga_semanal,
    DROP COLUMN IF EXISTS janela_entrada_inicio,
    DROP COLUMN IF EXISTS janela_entrada_fim;
