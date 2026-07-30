-- Reverte a camada de interpretação. Os eventos brutos em
-- rh.eventos_assiduidade não são tocados: tudo o que aqui desaparece é
-- reconstruível por RecalcularDia.

BEGIN;

DROP TABLE IF EXISTS rh.marcacoes_interpretadas;

ALTER TABLE rh.resultados_diarios
    DROP COLUMN IF EXISTS primeira_entrada,
    DROP COLUMN IF EXISTS ultima_saida;

-- Só remove o tipo de regra se nenhum tenant chegou a configurá-lo — apagá-lo
-- com regras dependentes rebentaria na FK de rh.regras_assiduidade.
DELETE FROM rh.tipos_regra tr
 WHERE tr.codigo = 'agrupamento_marcacoes'
   AND NOT EXISTS (
       SELECT 1 FROM rh.regras_assiduidade r WHERE r.tipo_regra_id = tr.id
   );

COMMIT;
