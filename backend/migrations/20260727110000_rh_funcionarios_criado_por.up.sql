-- Fase 3 — Granularidade de permissões
-- Adiciona coluna criado_por a rh.funcionarios para regra de propriedade.

BEGIN;

-- 1. Adicionar coluna criado_por (nullable, sem FK obrigatória para permitir NULL histórico)
ALTER TABLE rh.funcionarios
    ADD COLUMN IF NOT EXISTS criado_por bigint;

-- 2. Índice para lookups rápidos na verificação de propriedade
CREATE INDEX IF NOT EXISTS idx_funcionarios_criado_por
    ON rh.funcionarios USING btree (criado_por);

-- 3. Backfill: usar o user_id do próprio funcionário como melhor estimativa do criador.
--    Futuramente o INSERT em CriarFuncionario preencherá explicitamente.
UPDATE rh.funcionarios
   SET criado_por = user_id
 WHERE criado_por IS NULL
   AND user_id IS NOT NULL;

-- 4. Comentário documental
COMMENT ON COLUMN rh.funcionarios.criado_por IS 'ID do utilizador (auth.users) que criou o registo do funcionário. Usado na regra podeGerirFuncionario.';

COMMIT;
