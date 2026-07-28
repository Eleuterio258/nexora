-- Fase 4 — Garantir catálogo de módulos e funcionalidades para RequireFeature
-- Insere os módulos e features referenciadas pelo router sem quebrar tenants
-- existentes (ativo_por_defeito = true).

SET search_path TO saas, sistema_configuracao, public;

BEGIN;

-- ═════════════════════════════════════════════════════════════════════════════
-- 1. MÓDULOS NECESSÁRIOS
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO saas.module_catalog (key, nome, categoria, icone)
VALUES
    ('recursos-humanos', 'Recursos Humanos',       'operacional', 'fa-users'),
    ('faturacao',        'Faturação / Vendas',     'comercial',   'fa-file-invoice-dollar'),
    ('crm',              'CRM',                    'comercial',   'fa-address-book'),
    ('compras',          'Compras',                'operacional', 'fa-shopping-cart'),
    ('stock',            'Gestão de Stock',        'operacional', 'fa-boxes'),
    ('contabilidade',    'Contabilidade',          'financeiro',  'fa-calculator'),
    ('centros-custo',    'Centros de Custo',       'financeiro',  'fa-project-diagram'),
    ('logistica',        'Logística',              'operacional', 'fa-truck'),
    ('rh.assiduidade',   'Assiduidade',            'operacional', 'fa-clock')
ON CONFLICT (key) DO NOTHING;

-- ═════════════════════════════════════════════════════════════════════════════
-- 2. FEATURES NECESSÁRIAS
-- ═════════════════════════════════════════════════════════════════════════════

INSERT INTO saas.feature_catalog (key, modulo, nome, descricao, ativo_por_defeito, configuravel)
VALUES
    -- Recursos Humanos
    ('rh.ferias',            'recursos-humanos', 'Gestão de Férias',             'Pedidos e aprovação de férias por funcionário',           true,  true),
    ('rh.avaliacoes',        'recursos-humanos', 'Avaliações de Desempenho',     'Ciclos de avaliação e scoring por critério',              false, true),
    ('rh.formacoes',         'recursos-humanos', 'Gestão de Formações',          'Registo e acompanhamento de formações internas',          false, true),
    ('rh.folha_pagamento',   'recursos-humanos', 'Folha de Pagamento',           'Processamento mensal de salários e componentes',          true,  true),
    ('rh.disciplinar',       'recursos-humanos', 'Processos Disciplinares',      'Registo de infrações e processos disciplinares',          false, true),
    ('rh.assiduidade',       'rh.assiduidade',   'Assiduidade e Ponto',          'Controlo de presenças, atrasos e cálculo de assiduidade', true,  true),
    -- Faturação / Vendas
    ('vendas.orcamentos',    'faturacao',        'Orçamentos',                   'Criação e gestão de propostas comerciais',                true,  true),
    ('vendas.encomendas',    'faturacao',        'Encomendas de Venda',          'Gestão do ciclo de encomenda antes de faturar',           true,  true),
    ('vendas.fatura_direta', 'faturacao',        'Faturação Directa',            'Criar fatura sem passar por orçamento ou encomenda',      true,  false),
    ('vendas.devolucoes',    'faturacao',        'Devoluções / Notas de Crédito','Processamento de devoluções e emissão de notas crédito',  true,  true),
    -- CRM
    ('crm.leads',            'crm',              'Gestão de Leads',              'Captura e qualificação de leads de vendas',               true,  true),
    ('crm.oportunidades',    'crm',              'Pipeline de Oportunidades',    'Gestão de oportunidades em funil de vendas',              true,  true),
    ('crm.atividades',       'crm',              'Actividades e Follow-up',      'Tarefas, chamadas e reuniões associadas a clientes',      true,  true),
    -- Compras
    ('compras.requisicoes',  'compras',          'Requisições de Compra',        'Ciclo de requisição interna antes de comprar',            true,  true),
    ('compras.aprovacoes',   'compras',          'Aprovações em Cascata',        'Fluxo de aprovação multi-nível para compras',             false, true),
    -- Stock
    ('stock.alertas',        'stock',            'Alertas de Stock Mínimo',      'Notificação automática ao atingir stock mínimo',          true,  true),
    ('stock.series',         'stock',            'Números de Série',             'Rastreio de artigos por número de série',                 false, true),
    -- Contabilidade
    ('cont.ativo_fixo',      'contabilidade',    'Activo Fixo',                  'Gestão e depreciação de activos fixos tangíveis',         false, true),
    ('cont.centros_custo',   'contabilidade',    'Imputação Centros de Custo',   'Distribuição de lançamentos por centros de custo',        false, true),
    -- Logística
    ('logistica',            'logistica',        'Logística e Entregas',         'Gestão de viaturas, motoristas, rotas e envios',          true,  true)
ON CONFLICT (key) DO NOTHING;

COMMIT;
