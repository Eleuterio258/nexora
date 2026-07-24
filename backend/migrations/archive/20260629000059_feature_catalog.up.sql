-- Migration 059: Catálogo de funcionalidades e ligação a tenant_feature_flags
--
-- feature_catalog: sub-features por módulo (ex: 'rh.ferias', 'crm.leads')
-- tenant_feature_flags: já existia mas vazia — passa a ter FK para o catálogo

-- ── Catálogo de funcionalidades ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS saas.feature_catalog (
  key               VARCHAR(120) PRIMARY KEY,
  modulo            VARCHAR(60)  NOT NULL REFERENCES saas.module_catalog(key) ON DELETE CASCADE,
  nome              VARCHAR(150) NOT NULL,
  descricao         TEXT,
  ativo_por_defeito BOOLEAN     NOT NULL DEFAULT TRUE,
  configuravel      BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Ligar tenant_feature_flags ao catálogo ────────────────────────────────────
ALTER TABLE sistema_configuracao.tenant_feature_flags
  ADD COLUMN IF NOT EXISTS modulo VARCHAR(60);

-- Garantir que codigo (=key) é único por tenant
ALTER TABLE sistema_configuracao.tenant_feature_flags
  DROP CONSTRAINT IF EXISTS tenant_feature_flags_tenant_id_codigo_key;

ALTER TABLE sistema_configuracao.tenant_feature_flags
  DROP CONSTRAINT IF EXISTS uq_tenant_feature_flags;

ALTER TABLE sistema_configuracao.tenant_feature_flags
  ADD CONSTRAINT uq_tenant_feature_flags UNIQUE (tenant_id, codigo);

-- ── Seed: funcionalidades reais do ERP ────────────────────────────────────────
INSERT INTO saas.feature_catalog (key, modulo, nome, descricao, ativo_por_defeito, configuravel) VALUES
  -- Recursos Humanos
  ('rh.ferias',            'recursos-humanos', 'Gestão de Férias',            'Pedidos e aprovação de férias por funcionário',          true,  true),
  ('rh.avaliacoes',        'recursos-humanos', 'Avaliações de Desempenho',    'Ciclos de avaliação e scoring por critério',             false, true),
  ('rh.formacoes',         'recursos-humanos', 'Gestão de Formações',         'Registo e acompanhamento de formações internas',         false, true),
  ('rh.folha_pagamento',   'recursos-humanos', 'Folha de Pagamento',          'Processamento mensal de salários e componentes',         true,  true),
  ('rh.disciplinar',       'recursos-humanos', 'Processos Disciplinares',     'Registo de infracções e processos disciplinares',        false, true),
  -- Faturação / Vendas
  ('vendas.orcamentos',    'faturacao',        'Orçamentos',                  'Criação e gestão de propostas comerciais',               true,  true),
  ('vendas.encomendas',    'faturacao',        'Encomendas de Venda',         'Gestão do ciclo de encomenda antes de faturar',          true,  true),
  ('vendas.fatura_direta', 'faturacao',        'Faturação Directa',           'Criar fatura sem passar por orçamento ou encomenda',     true,  false),
  ('vendas.devolucoes',    'faturacao',        'Devoluções / Notas de Crédito','Processamento de devoluções e emissão de notas crédito', true,  true),
  -- CRM
  ('crm.leads',            'crm',              'Gestão de Leads',             'Captura e qualificação de leads de vendas',              true,  true),
  ('crm.oportunidades',    'crm',              'Pipeline de Oportunidades',   'Gestão de oportunidades em funil de vendas',             true,  true),
  ('crm.atividades',       'crm',              'Actividades e Follow-up',     'Tarefas, chamadas e reuniões associadas a clientes',     true,  true),
  -- Compras
  ('compras.requisicoes',  'compras',          'Requisições de Compra',       'Ciclo de requisição interna antes de comprar',           true,  true),
  ('compras.aprovacoes',   'compras',          'Aprovações em Cascata',       'Fluxo de aprovação multi-nível para compras',            false, true),
  -- Stock
  ('stock.alertas',        'stock',            'Alertas de Stock Mínimo',     'Notificação automática ao atingir stock mínimo',         true,  true),
  ('stock.series',         'stock',            'Números de Série',            'Rastreio de artigos por número de série',                false, true),
  -- Contabilidade
  ('cont.ativo_fixo',      'contabilidade',    'Activo Fixo',                 'Gestão e depreciação de activos fixos tangíveis',        false, true),
  ('cont.centros_custo',   'contabilidade',    'Imputação Centros de Custo',  'Distribuição de lançamentos por centros de custo',       false, true)
ON CONFLICT (key) DO NOTHING;
