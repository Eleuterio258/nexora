-- Reverte o seed de features/módulos adicionados na Fase 4.
-- Nota: apenas remove as entradas se não existirem dependências ativas.

SET search_path TO saas, sistema_configuracao, public;

BEGIN;

DELETE FROM saas.feature_catalog
 WHERE key IN (
     'rh.ferias','rh.avaliacoes','rh.formacoes','rh.folha_pagamento','rh.disciplinar','rh.assiduidade',
     'vendas.orcamentos','vendas.encomendas','vendas.fatura_direta','vendas.devolucoes',
     'crm.leads','crm.oportunidades','crm.atividades',
     'compras.requisicoes','compras.aprovacoes',
     'stock.alertas','stock.series',
     'cont.ativo_fixo','cont.centros_custo',
     'logistica'
 );

DELETE FROM saas.module_catalog
 WHERE key IN (
     'recursos-humanos','faturacao','crm','compras','stock','contabilidade',
     'centros-custo','logistica','rh.assiduidade'
 );

COMMIT;
