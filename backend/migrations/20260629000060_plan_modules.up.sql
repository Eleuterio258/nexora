-- Migration 060: Módulos incluídos em cada plano (entitlement)
--
-- Define quais módulos cada plano permite activar para um tenant.
-- ActualizarModuloTenant valida contra esta tabela antes de activar.
-- Na criação de tenant, os módulos do plano são auto-activados.

CREATE TABLE saas.plan_modules (
  plan_id BIGINT      NOT NULL REFERENCES saas.plans(id) ON DELETE CASCADE,
  modulo  VARCHAR(60) NOT NULL REFERENCES saas.module_catalog(key) ON DELETE CASCADE,
  PRIMARY KEY (plan_id, modulo)
);

-- ── Seed: módulos por plano ────────────────────────────────────────────────────

-- Básico (id=1): essencial comercial + financeiro base
INSERT INTO saas.plan_modules (plan_id, modulo) VALUES
  (1, 'clientes'),
  (1, 'vendas'),
  (1, 'faturacao'),
  (1, 'stock'),
  (1, 'financeiro'),
  (1, 'notificacoes'),
  (1, 'seguranca'),
  (1, 'sistema-configuracao');

-- Profissional (id=2): tudo do Básico + RH, CRM, Compras, Impostos
INSERT INTO saas.plan_modules (plan_id, modulo)
  SELECT 2, modulo FROM saas.plan_modules WHERE plan_id = 1;

INSERT INTO saas.plan_modules (plan_id, modulo) VALUES
  (2, 'crm'),
  (2, 'compras'),
  (2, 'logistica'),
  (2, 'impostos'),
  (2, 'tesouraria'),
  (2, 'recursos-humanos'),
  (2, 'pedido-ferias'),
  (2, 'recrutamento'),
  (2, 'auditoria');

-- Empresarial (id=3): todos os módulos do catálogo
INSERT INTO saas.plan_modules (plan_id, modulo)
  SELECT 3, key FROM saas.module_catalog WHERE ativo = TRUE
  ON CONFLICT DO NOTHING;
