-- Reverte a introdução de pos:supervisionar_pos e dos cargos Supervisor POS / Gerente de Loja.
--
-- Nota: os cargos Supervisor POS e Gerente de Loja só são removidos se não
-- tiverem nenhuma membership atribuída, para evitar perda de dados de
-- produção. Se tiverem memberships, as permissões pos são removidas mas o
-- cargo fica vazio (pode ser apagado manualmente depois).

SET search_path TO auth, public;

-- 1. Remove a trigger e as funções auxiliares
DROP TRIGGER IF EXISTS trg_garantir_cargos_pos_padrao ON auth.cargos;
DROP FUNCTION IF EXISTS auth.trigger_garantir_cargos_pos_padrao();
DROP FUNCTION IF EXISTS auth.garantir_cargos_pos_padrao(BIGINT);

-- 2. Remove a permissão supervisionar_pos de todos os cargos
DELETE FROM auth.permissoes_cargo
 WHERE modulo = 'pos' AND acao = 'supervisionar_pos';

-- 3. Remove cargos Supervisor POS e Gerente de Loja apenas se não estiverem em uso
DELETE FROM auth.cargos
 WHERE nome IN ('Supervisor POS', 'Gerente de Loja')
   AND NOT EXISTS (
       SELECT 1 FROM auth.memberships m
        WHERE m.cargo_id = auth.cargos.id AND m.ativo = true
   );
