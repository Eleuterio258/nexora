SET search_path TO saas, empresas, auth, public;

-- Adiciona coluna tenant_id a empresas.companies
ALTER TABLE empresas.companies
    ADD COLUMN IF NOT EXISTS tenant_id BIGINT;

-- Cria tenants para as companies existentes e guarda o mapeamento
WITH inserted_tenants AS (
    INSERT INTO saas.tenants (codigo, nome, company_id, status, dominio, plano_id, limite_utilizadores, limite_armazenamento_gb, validade_plano)
    SELECT
        c.codigo,
        c.nome,
        c.id,
        CASE c.status
            WHEN 'ativa' THEN 'ativo'
            WHEN 'suspensa' THEN 'suspenso'
            WHEN 'inativa' THEN 'inativo'
            ELSE 'ativo'
        END,
        NULL,
        (SELECT id FROM saas.plans WHERE codigo = 'empresarial' LIMIT 1),
        NULL,
        NULL,
        NULL
    FROM empresas.companies c
    WHERE c.tenant_id IS NULL
    RETURNING id, company_id
)
UPDATE empresas.companies c
SET tenant_id = it.id
FROM inserted_tenants it
WHERE c.id = it.company_id;

-- Atualiza auth.users.tenant_id para apontar para o tenant correto
-- (presumindo que auth.users.tenant_id anteriormente referenciava empresas.companies.id)
UPDATE auth.users u
SET tenant_id = c.tenant_id
FROM empresas.companies c
WHERE u.tenant_id = c.id
  AND c.tenant_id IS NOT NULL;

-- Atualiza saas.tenants.company_id para garantir ligação 1:1
-- (já foi preenchido no INSERT, mas garantimos consistência)
UPDATE saas.tenants t
SET company_id = c.id
FROM empresas.companies c
WHERE t.id = c.tenant_id
  AND t.company_id IS DISTINCT FROM c.id;

-- Adiciona foreign keys
ALTER TABLE empresas.companies
    ADD CONSTRAINT fk_companies_tenant FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id) ON DELETE SET NULL;

ALTER TABLE saas.tenants
    ADD CONSTRAINT fk_tenants_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE SET NULL;

-- Garante que não existam users órfãos (users sem tenant existente)
-- Nota: comentado por segurança; ativar apenas após validação manual
-- DELETE FROM auth.users WHERE tenant_id NOT IN (SELECT id FROM saas.tenants);

-- Cria módulos ativos por defeito para todos os tenants existentes
-- (assumindo que a ausência de registo significa módulo ativo)
-- Aqui registamos explicitamente os módulos principais como ativos
INSERT INTO saas.tenant_modules (tenant_id, modulo, ativo, config)
SELECT t.id, m.modulo, TRUE, '{}'::jsonb
FROM saas.tenants t
CROSS JOIN (
    VALUES
        ('clientes'),
        ('vendas'),
        ('faturacao'),
        ('stock'),
        ('compras'),
        ('financeiro'),
        ('tesouraria'),
        ('contabilidade'),
        ('impostos'),
        ('recursos-humanos'),
        ('crm'),
        ('pos'),
        ('logistica'),
        ('recrutamento'),
        ('gestao-escolar'),
        ('assinaturas'),
        ('notificacoes'),
        ('auditoria'),
        ('seguranca'),
        ('sistema-configuracao'),
        ('multi-moeda'),
        ('centros-custo')
) AS m(modulo)
ON CONFLICT (tenant_id, modulo) DO NOTHING;

-- Cria subscrições iniciais para tenants existentes no plano empresarial
INSERT INTO saas.tenant_subscriptions (tenant_id, plano_id, numero, starts_at, ends_at, next_billing_date, status, unit_price, moeda, auto_renew)
SELECT
    t.id,
    t.plano_id,
    'SUB-' || t.id,
    CURRENT_DATE,
    NULL,
    NULL,
    'activa',
    p.preco_mensal,
    p.moeda,
    TRUE
FROM saas.tenants t
JOIN saas.plans p ON p.id = t.plano_id
WHERE NOT EXISTS (
    SELECT 1 FROM saas.tenant_subscriptions ts WHERE ts.tenant_id = t.id
);
