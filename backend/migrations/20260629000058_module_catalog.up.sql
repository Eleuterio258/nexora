-- Migration 058: Catálogo de módulos e grafo de dependências
--
-- Substitui a lista hardcoded em modules.go por tabelas relacionais.
-- Permite que superadmin adicione/remova dependências sem deploy.

-- ── Catálogo master de módulos ─────────────────────────────────────────────────
CREATE TABLE saas.module_catalog (
  key        VARCHAR(60)  PRIMARY KEY,
  nome       VARCHAR(150) NOT NULL,
  categoria  VARCHAR(60)  NOT NULL,
  descricao  TEXT,
  icone      VARCHAR(60),
  ativo      BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Grafo de dependências (DAG) ────────────────────────────────────────────────
-- modulo requires → modulo não pode ser activado sem requires estar activo
CREATE TABLE saas.module_dependencies (
  modulo    VARCHAR(60) NOT NULL REFERENCES saas.module_catalog(key) ON DELETE CASCADE,
  requires  VARCHAR(60) NOT NULL REFERENCES saas.module_catalog(key) ON DELETE CASCADE,
  PRIMARY KEY (modulo, requires),
  CHECK (modulo <> requires)
);

-- ── Seed: 23 módulos ───────────────────────────────────────────────────────────
INSERT INTO saas.module_catalog (key, nome, categoria, icone) VALUES
  -- Comercial
  ('clientes',              'Clientes',             'comercial',    'fa-users'),
  ('vendas',                'Vendas',                'comercial',    'fa-shopping-cart'),
  ('faturacao',             'Faturação',             'comercial',    'fa-file-invoice'),
  ('crm',                   'CRM',                   'comercial',    'fa-handshake'),
  ('pos',                   'POS',                   'comercial',    'fa-cash-register'),
  ('assinaturas',           'Assinaturas',           'comercial',    'fa-repeat'),
  -- Operacional
  ('stock',                 'Stock',                 'operacional',  'fa-boxes'),
  ('compras',               'Compras',               'operacional',  'fa-truck'),
  ('logistica',             'Logística',             'operacional',  'fa-route'),
  -- Financeiro
  ('financeiro',            'Financeiro',            'financeiro',   'fa-chart-line'),
  ('tesouraria',            'Tesouraria',            'financeiro',   'fa-vault'),
  ('contabilidade',         'Contabilidade',         'financeiro',   'fa-calculator'),
  ('impostos',              'Impostos',              'financeiro',   'fa-percent'),
  ('multi-moeda',           'Multi-Moeda',           'financeiro',   'fa-coins'),
  ('centros-custo',         'Centros de Custo',      'financeiro',   'fa-sitemap'),
  -- Recursos Humanos
  ('recursos-humanos',      'Recursos Humanos',      'rh',           'fa-id-badge'),
  ('pedido-ferias',         'Gestão de Férias',      'rh',           'fa-umbrella-beach'),
  ('recrutamento',          'Recrutamento',          'rh',           'fa-user-plus'),
  -- Plataforma
  ('gestao-escolar',        'Gestão Escolar',        'plataforma',   'fa-graduation-cap'),
  ('notificacoes',          'Notificações',          'plataforma',   'fa-bell'),
  ('auditoria',             'Auditoria',             'plataforma',   'fa-shield-alt'),
  ('seguranca',             'Segurança',             'plataforma',   'fa-lock'),
  ('sistema-configuracao',  'Configurações',         'plataforma',   'fa-cog');

-- ── Seed: grafo de dependências ────────────────────────────────────────────────
INSERT INTO saas.module_dependencies (modulo, requires) VALUES
  -- faturação e derivados precisam de clientes
  ('faturacao',     'clientes'),
  ('vendas',        'clientes'),
  ('crm',           'clientes'),
  ('assinaturas',   'clientes'),
  ('assinaturas',   'faturacao'),
  -- impostos e moedas sobre faturação
  ('impostos',      'faturacao'),
  ('multi-moeda',   'faturacao'),
  -- operacional: POS, compras e logística sobre stock
  ('pos',           'stock'),
  ('compras',       'stock'),
  ('logistica',     'stock'),
  -- financeiro
  ('tesouraria',    'financeiro'),
  ('contabilidade', 'financeiro'),
  ('centros-custo', 'contabilidade'),
  -- rh
  ('pedido-ferias', 'recursos-humanos'),
  ('recrutamento',  'recursos-humanos');
