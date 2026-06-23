-- Migração das permissões genéricas (ver/criar/editar/eliminar/gerir)
-- para funcionalidades reais de cada módulo.
-- Aplica a todas as tabelas: permissoes_cargo, permissoes_diretas, permissoes_tipo.

DO $$
BEGIN

-- ── Função auxiliar ────────────────────────────────────────────────────────
-- Converte (modulo, acao_generica) → lista de funcionalidades reais
-- Executado para cada tabela de permissões.

-- ── permissoes_tipo (padrão por tipo) ─────────────────────────────────────
-- pedido-ferias: ver → ver_pedidos, criar → submeter_pedido
UPDATE auth.permissoes_tipo SET acao='ver_pedidos'     WHERE modulo='pedido-ferias' AND acao='ver';
UPDATE auth.permissoes_tipo SET acao='submeter_pedido' WHERE modulo='pedido-ferias' AND acao='criar';

-- ── permissoes_diretas ─────────────────────────────────────────────────────
-- recrutamento
UPDATE auth.permissoes_diretas SET acao='ver_vagas'          WHERE modulo='recrutamento' AND acao='ver';
UPDATE auth.permissoes_diretas SET acao='gerir_vagas'        WHERE modulo='recrutamento' AND acao='criar';
UPDATE auth.permissoes_diretas SET acao='gerir_pipeline'     WHERE modulo='recrutamento' AND acao='editar';
UPDATE auth.permissoes_diretas SET acao='gerir_candidaturas' WHERE modulo='recrutamento' AND acao='eliminar';
UPDATE auth.permissoes_diretas SET acao='ver_relatorios'     WHERE modulo='recrutamento' AND acao='gerir';

-- pos
UPDATE auth.permissoes_diretas SET acao='operar_pos'      WHERE modulo='pos' AND acao='ver';
UPDATE auth.permissoes_diretas SET acao='operar_pos'      WHERE modulo='pos' AND acao='criar';
UPDATE auth.permissoes_diretas SET acao='gerir_terminais' WHERE modulo='pos' AND acao='editar';
UPDATE auth.permissoes_diretas SET acao='gerir_catalogo'  WHERE modulo='pos' AND acao='eliminar';

-- pedido-ferias
UPDATE auth.permissoes_diretas SET acao='ver_pedidos'      WHERE modulo='pedido-ferias' AND acao='ver';
UPDATE auth.permissoes_diretas SET acao='submeter_pedido'  WHERE modulo='pedido-ferias' AND acao='criar';

-- recursos-humanos
UPDATE auth.permissoes_diretas SET acao='ver_funcionarios'   WHERE modulo='recursos-humanos' AND acao='ver';
UPDATE auth.permissoes_diretas SET acao='gerir_funcionarios' WHERE modulo='recursos-humanos' AND acao='criar';
UPDATE auth.permissoes_diretas SET acao='gerir_contratos'    WHERE modulo='recursos-humanos' AND acao='editar';
UPDATE auth.permissoes_diretas SET acao='aprovar_ausencias'  WHERE modulo='recursos-humanos' AND acao='eliminar';
UPDATE auth.permissoes_diretas SET acao='processar_salarios' WHERE modulo='recursos-humanos' AND acao='gerir';

-- clientes
UPDATE auth.permissoes_diretas SET acao='ver_clientes'    WHERE modulo='clientes' AND acao='ver';
UPDATE auth.permissoes_diretas SET acao='gerir_clientes'  WHERE modulo='clientes' AND acao='criar';
UPDATE auth.permissoes_diretas SET acao='gerir_clientes'  WHERE modulo='clientes' AND acao='editar';
UPDATE auth.permissoes_diretas SET acao='eliminar_clientes' WHERE modulo='clientes' AND acao='eliminar';
UPDATE auth.permissoes_diretas SET acao='gerir_credito'   WHERE modulo='clientes' AND acao='gerir';

-- crm
UPDATE auth.permissoes_diretas SET acao='ver_leads'           WHERE modulo='crm' AND acao='ver';
UPDATE auth.permissoes_diretas SET acao='gerir_leads'         WHERE modulo='crm' AND acao='criar';
UPDATE auth.permissoes_diretas SET acao='gerir_oportunidades' WHERE modulo='crm' AND acao='editar';
UPDATE auth.permissoes_diretas SET acao='eliminar_leads'      WHERE modulo='crm' AND acao='eliminar';
UPDATE auth.permissoes_diretas SET acao='converter_leads'     WHERE modulo='crm' AND acao='gerir';

-- faturacao
UPDATE auth.permissoes_diretas SET acao='ver_documentos'    WHERE modulo='faturacao' AND acao='ver';
UPDATE auth.permissoes_diretas SET acao='emitir_orcamentos' WHERE modulo='faturacao' AND acao='criar';
UPDATE auth.permissoes_diretas SET acao='emitir_faturas'    WHERE modulo='faturacao' AND acao='editar';

-- stock
UPDATE auth.permissoes_diretas SET acao='ver_stock'        WHERE modulo='stock' AND acao='ver';
UPDATE auth.permissoes_diretas SET acao='gerir_produtos'   WHERE modulo='stock' AND acao='criar';
UPDATE auth.permissoes_diretas SET acao='gerir_movimentos' WHERE modulo='stock' AND acao='editar';
UPDATE auth.permissoes_diretas SET acao='gerir_categorias' WHERE modulo='stock' AND acao='eliminar';

-- ── permissoes_cargo ───────────────────────────────────────────────────────
-- recrutamento
UPDATE auth.permissoes_cargo SET acao='ver_vagas'          WHERE modulo='recrutamento' AND acao='ver';
UPDATE auth.permissoes_cargo SET acao='gerir_vagas'        WHERE modulo='recrutamento' AND acao='criar';
UPDATE auth.permissoes_cargo SET acao='gerir_pipeline'     WHERE modulo='recrutamento' AND acao='editar';
UPDATE auth.permissoes_cargo SET acao='gerir_candidaturas' WHERE modulo='recrutamento' AND acao='eliminar';
UPDATE auth.permissoes_cargo SET acao='ver_relatorios'     WHERE modulo='recrutamento' AND acao='gerir';

-- pos
UPDATE auth.permissoes_cargo SET acao='operar_pos'      WHERE modulo='pos' AND acao='ver';
UPDATE auth.permissoes_cargo SET acao='operar_pos'      WHERE modulo='pos' AND acao='criar';
UPDATE auth.permissoes_cargo SET acao='gerir_terminais' WHERE modulo='pos' AND acao='editar';
UPDATE auth.permissoes_cargo SET acao='gerir_catalogo'  WHERE modulo='pos' AND acao='eliminar';

-- recursos-humanos
UPDATE auth.permissoes_cargo SET acao='ver_funcionarios'   WHERE modulo='recursos-humanos' AND acao='ver';
UPDATE auth.permissoes_cargo SET acao='gerir_funcionarios' WHERE modulo='recursos-humanos' AND acao='criar';
UPDATE auth.permissoes_cargo SET acao='gerir_contratos'    WHERE modulo='recursos-humanos' AND acao='editar';
UPDATE auth.permissoes_cargo SET acao='aprovar_ausencias'  WHERE modulo='recursos-humanos' AND acao='eliminar';
UPDATE auth.permissoes_cargo SET acao='processar_salarios' WHERE modulo='recursos-humanos' AND acao='gerir';

-- clientes
UPDATE auth.permissoes_cargo SET acao='ver_clientes'      WHERE modulo='clientes' AND acao='ver';
UPDATE auth.permissoes_cargo SET acao='gerir_clientes'    WHERE modulo='clientes' AND acao='criar';
UPDATE auth.permissoes_cargo SET acao='gerir_clientes'    WHERE modulo='clientes' AND acao='editar';
UPDATE auth.permissoes_cargo SET acao='eliminar_clientes' WHERE modulo='clientes' AND acao='eliminar';
UPDATE auth.permissoes_cargo SET acao='gerir_credito'     WHERE modulo='clientes' AND acao='gerir';

-- crm
UPDATE auth.permissoes_cargo SET acao='ver_leads'           WHERE modulo='crm' AND acao='ver';
UPDATE auth.permissoes_cargo SET acao='gerir_leads'         WHERE modulo='crm' AND acao='criar';
UPDATE auth.permissoes_cargo SET acao='gerir_oportunidades' WHERE modulo='crm' AND acao='editar';
UPDATE auth.permissoes_cargo SET acao='eliminar_leads'      WHERE modulo='crm' AND acao='eliminar';
UPDATE auth.permissoes_cargo SET acao='converter_leads'     WHERE modulo='crm' AND acao='gerir';

-- faturacao
UPDATE auth.permissoes_cargo SET acao='ver_documentos'    WHERE modulo='faturacao' AND acao='ver';
UPDATE auth.permissoes_cargo SET acao='emitir_orcamentos' WHERE modulo='faturacao' AND acao='criar';
UPDATE auth.permissoes_cargo SET acao='emitir_faturas'    WHERE modulo='faturacao' AND acao='editar';

-- stock
UPDATE auth.permissoes_cargo SET acao='ver_stock'        WHERE modulo='stock' AND acao='ver';
UPDATE auth.permissoes_cargo SET acao='gerir_produtos'   WHERE modulo='stock' AND acao='criar';
UPDATE auth.permissoes_cargo SET acao='gerir_movimentos' WHERE modulo='stock' AND acao='editar';
UPDATE auth.permissoes_cargo SET acao='gerir_categorias' WHERE modulo='stock' AND acao='eliminar';

-- Remover duplicados que possam ter surgido dos UPDATEs acima
DELETE FROM auth.permissoes_diretas a
USING auth.permissoes_diretas b
WHERE a.id > b.id
  AND a.user_id = b.user_id
  AND a.modulo  = b.modulo
  AND a.acao    = b.acao;

DELETE FROM auth.permissoes_cargo a
USING auth.permissoes_cargo b
WHERE a.id > b.id
  AND a.cargo_id = b.cargo_id
  AND a.modulo   = b.modulo
  AND a.acao     = b.acao;

END $$;
