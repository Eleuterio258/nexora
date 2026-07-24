-- =============================================================================
-- Permissão de configuração do recrutamento
-- Propaga a nova permissão 'configurar_recrutamento' para quem já pode
-- gerir vagas, garantindo que os gestores existentes acedam aos novos
-- ecrãs de campos customizáveis e notificações.
-- =============================================================================

-- 1. Adicionar permissão aos cargos que já têm 'gerir_vagas' em recrutamento
INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
SELECT DISTINCT pc.cargo_id, 'recrutamento', 'configurar_recrutamento'
  FROM auth.permissoes_cargo pc
  JOIN auth.cargos c ON c.id = pc.cargo_id
 WHERE pc.modulo = 'recrutamento'
   AND pc.acao = 'gerir_vagas'
   AND NOT EXISTS (
       SELECT 1 FROM auth.permissoes_cargo pc2
        WHERE pc2.cargo_id = pc.cargo_id
          AND pc2.modulo = 'recrutamento'
          AND pc2.acao = 'configurar_recrutamento'
   )
ON CONFLICT (cargo_id, modulo, acao) DO NOTHING;

-- 2. Adicionar permissão aos utilizadores que têm 'gerir_vagas' diretamente
INSERT INTO auth.permissoes_diretas (user_id, modulo, acao)
SELECT DISTINCT pd.user_id, 'recrutamento', 'configurar_recrutamento'
  FROM auth.permissoes_diretas pd
 WHERE pd.modulo = 'recrutamento'
   AND pd.acao = 'gerir_vagas'
   AND NOT EXISTS (
       SELECT 1 FROM auth.permissoes_diretas pd2
        WHERE pd2.user_id = pd.user_id
          AND pd2.modulo = 'recrutamento'
          AND pd2.acao = 'configurar_recrutamento'
   )
ON CONFLICT (user_id, modulo, acao) DO NOTHING;

-- 3. Adicionar permissão aos tipos de utilizador que têm 'gerir_vagas' por tipo
INSERT INTO auth.permissoes_tipo (tipo, modulo, acao)
SELECT DISTINCT pt.tipo, 'recrutamento', 'configurar_recrutamento'
  FROM auth.permissoes_tipo pt
 WHERE pt.modulo = 'recrutamento'
   AND pt.acao = 'gerir_vagas'
   AND NOT EXISTS (
       SELECT 1 FROM auth.permissoes_tipo pt2
        WHERE pt2.tipo = pt.tipo
          AND pt2.modulo = 'recrutamento'
          AND pt2.acao = 'configurar_recrutamento'
   )
ON CONFLICT (tipo, modulo, acao) DO NOTHING;
