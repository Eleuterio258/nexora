-- ================================================================
-- NEXORA ERP — Seed Data
-- Tenant demo: 1
-- Admin inicial: admin@nexora.local / Admin@123
-- Execute após nexora_erp_full.sql:
--   psql -U nexora -d nexora_erp -f nexora_erp_seed.sql
-- ================================================================

-- auth
SET search_path TO auth, public;

INSERT INTO users (tenant_id, nome, email, password_hash, telefone, estado, email_verificado)
VALUES (
    1,
    'Administrador Sistema',
    'admin@nexora.local',
    crypt('Admin@123', gen_salt('bf', 12)),
    '+258840000001',
    'ativo',
    TRUE
)
ON CONFLICT (tenant_id, email)
DO UPDATE SET
    nome = EXCLUDED.nome,
    telefone = EXCLUDED.telefone,
    estado = EXCLUDED.estado,
    email_verificado = EXCLUDED.email_verificado,
    updated_at = CURRENT_TIMESTAMP;

-- empresa
SET search_path TO empresa, public;

INSERT INTO companies (codigo, nome, nome_comercial, tipo, status, moeda_base, timezone)
VALUES ('DEMO', 'Nexora Demo, Lda', 'Nexora Demo', 'empresa', 'ativa', 'MZN', 'Africa/Maputo')
ON CONFLICT (codigo)
DO UPDATE SET
    nome = EXCLUDED.nome,
    nome_comercial = EXCLUDED.nome_comercial,
    status = EXCLUDED.status,
    moeda_base = EXCLUDED.moeda_base,
    timezone = EXCLUDED.timezone,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO company_tax_info (company_id, nuit, regime_iva, taxa_iva_padrao, inicio_atividade, reparticao_fiscal)
SELECT c.id, '400000001', 'regime_geral', 16.00, CURRENT_DATE, 'Maputo Cidade'
FROM companies c
WHERE c.codigo = 'DEMO'
ON CONFLICT (company_id)
DO UPDATE SET
    nuit = EXCLUDED.nuit,
    regime_iva = EXCLUDED.regime_iva,
    taxa_iva_padrao = EXCLUDED.taxa_iva_padrao,
    inicio_atividade = EXCLUDED.inicio_atividade,
    reparticao_fiscal = EXCLUDED.reparticao_fiscal,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO company_branches (company_id, codigo, nome, status, principal)
SELECT c.id, 'MATRIZ', 'Sede Maputo', 'ativa', TRUE
FROM companies c
WHERE c.codigo = 'DEMO'
ON CONFLICT (company_id, codigo)
DO UPDATE SET
    nome = EXCLUDED.nome,
    status = EXCLUDED.status,
    principal = EXCLUDED.principal,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO company_settings (company_id, chave, valor)
SELECT c.id, seed.chave, seed.valor
FROM companies c
CROSS JOIN (
    VALUES
        ('default_currency', 'MZN'),
        ('country', 'Mocambique'),
        ('timezone', 'Africa/Maputo'),
        ('language', 'pt-MZ')
) AS seed(chave, valor)
WHERE c.codigo = 'DEMO'
ON CONFLICT (company_id, chave)
DO UPDATE SET
    valor = EXCLUDED.valor,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO company_users (company_id, user_id, branch_id, perfil_empresa, ativo)
SELECT
    c.id,
    u.id,
    b.id,
    'admin',
    TRUE
FROM companies c
JOIN auth.users u
  ON u.tenant_id = 1
 AND u.email = 'admin@nexora.local'
LEFT JOIN company_branches b
  ON b.company_id = c.id
 AND b.codigo = 'MATRIZ'
WHERE c.codigo = 'DEMO'
ON CONFLICT (company_id, user_id)
DO UPDATE SET
    branch_id = EXCLUDED.branch_id,
    perfil_empresa = EXCLUDED.perfil_empresa,
    ativo = EXCLUDED.ativo;

-- autorizacao
SET search_path TO autorizacao, public;

INSERT INTO permissions (codigo, nome, descricao, recurso, acao)
VALUES
    ('auth.users.manage', 'Gerir utilizadores', 'Criar e atualizar utilizadores', 'auth.users', 'manage'),
    ('companies.manage', 'Gerir empresas', 'Gerir empresas e filiais', 'companies', 'manage'),
    ('faturacao.manage', 'Gerir faturacao', 'Emitir e anular documentos', 'faturacao', 'manage'),
    ('stock.manage', 'Gerir stock', 'Movimentar e consultar stock', 'stock', 'manage'),
    ('reports.view', 'Ver relatorios', 'Consultar relatorios e dashboards', 'reports', 'view'),
    ('settings.manage', 'Gerir configuracoes', 'Alterar configuracoes do tenant', 'settings', 'manage')
ON CONFLICT (codigo)
DO UPDATE SET
    nome = EXCLUDED.nome,
    descricao = EXCLUDED.descricao,
    recurso = EXCLUDED.recurso,
    acao = EXCLUDED.acao;

INSERT INTO roles (tenant_id, codigo, nome, descricao, ativo)
VALUES (1, 'ADMIN', 'Administrador', 'Perfil administrativo completo', TRUE)
ON CONFLICT (tenant_id, codigo)
DO UPDATE SET
    nome = EXCLUDED.nome,
    descricao = EXCLUDED.descricao,
    ativo = EXCLUDED.ativo;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.codigo IN (
    'auth.users.manage',
    'companies.manage',
    'faturacao.manage',
    'stock.manage',
    'reports.view',
    'settings.manage'
)
WHERE r.tenant_id = 1
  AND r.codigo = 'ADMIN'
ON CONFLICT (role_id, permission_id) DO NOTHING;

INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM auth.users u
JOIN roles r
  ON r.tenant_id = u.tenant_id
 AND r.codigo = 'ADMIN'
WHERE u.tenant_id = 1
  AND u.email = 'admin@nexora.local'
ON CONFLICT (user_id, role_id) DO NOTHING;

-- multi_moeda
SET search_path TO multi_moeda, public;

INSERT INTO tenant_currencies (tenant_id, currency_id, is_base, active)
SELECT 1, c.id, seed.is_base, TRUE
FROM currencies c
JOIN (
    VALUES
        ('MZN', TRUE),
        ('USD', FALSE),
        ('ZAR', FALSE),
        ('EUR', FALSE)
) AS seed(code, is_base)
  ON seed.code = c.code
ON CONFLICT (tenant_id, currency_id)
DO UPDATE SET
    is_base = EXCLUDED.is_base,
    active = EXCLUDED.active;

INSERT INTO exchange_rates (tenant_id, base_currency_id, quote_currency_id, rate, effective_date, source, created_by)
SELECT
    1,
    base_c.id,
    quote_c.id,
    seed.rate,
    CURRENT_DATE,
    'seed',
    1
FROM (
    VALUES
        ('MZN', 'USD', 0.015625),
        ('USD', 'MZN', 64.000000),
        ('MZN', 'ZAR', 0.289855),
        ('ZAR', 'MZN', 3.450000),
        ('MZN', 'EUR', 0.014286),
        ('EUR', 'MZN', 70.000000)
) AS seed(base_code, quote_code, rate)
JOIN currencies base_c ON base_c.code = seed.base_code
JOIN currencies quote_c ON quote_c.code = seed.quote_code
ON CONFLICT (tenant_id, base_currency_id, quote_currency_id, effective_date, source)
DO UPDATE SET
    rate = EXCLUDED.rate,
    created_by = EXCLUDED.created_by;

-- sistema_configuracao
SET search_path TO sistema_configuracao, public;

INSERT INTO tenant_defaults (tenant_id, chave, valor, updated_by)
VALUES
    (1, 'default_currency',        'MZN',            1),
    (1, 'timezone',                'Africa/Maputo',   1),
    (1, 'locale',                  'pt-MZ',           1),
    (1, 'fiscal_year_start_month', '1',               1),
    (1, 'date_format',             'YYYY-MM-DD',      1),
    (1, 'number_format',           'pt-MZ',           1)
ON CONFLICT (tenant_id, chave)
DO UPDATE SET
    valor      = EXCLUDED.valor,
    updated_by = EXCLUDED.updated_by,
    updated_at = CURRENT_TIMESTAMP;

-- notifications
SET search_path TO notifications, public;

INSERT INTO notification_channels (tenant_id, codigo, nome, tipo, configuracao, activo, updated_by)
VALUES
    (1, 'EMAIL_DEFAULT', 'Canal Email Principal', 'email', '{"from":"no-reply@nexora.local","provider":"smtp"}'::jsonb, TRUE, 1),
    (1, 'SMS_DEFAULT', 'Canal SMS Principal', 'sms', '{"provider":"mock"}'::jsonb, TRUE, 1)
ON CONFLICT (tenant_id, codigo)
DO UPDATE SET
    nome = EXCLUDED.nome,
    tipo = EXCLUDED.tipo,
    configuracao = EXCLUDED.configuracao,
    activo = EXCLUDED.activo,
    updated_by = EXCLUDED.updated_by,
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO notification_templates (tenant_id, codigo, canal_tipo, assunto, corpo, variaveis, activo, updated_by)
VALUES
    (
        1,
        'WELCOME_USER',
        'email',
        'Bem-vindo ao Nexora ERP',
        'O utilizador {{nome}} foi criado com sucesso.',
        '["nome"]'::jsonb,
        TRUE,
        1
    ),
    (
        1,
        'PASSWORD_RESET',
        'email',
        'Reposicao de password',
        'Utilize o token {{token}} para redefinir a sua password.',
        '["token"]'::jsonb,
        TRUE,
        1
    ),
    (
        1,
        'INVOICE_ISSUED',
        'email',
        'Documento emitido',
        'O documento {{numero}} foi emitido no valor de {{total}}.',
        '["numero","total"]'::jsonb,
        TRUE,
        1
    )
ON CONFLICT (tenant_id, codigo, canal_tipo)
DO UPDATE SET
    assunto = EXCLUDED.assunto,
    corpo = EXCLUDED.corpo,
    variaveis = EXCLUDED.variaveis,
    activo = EXCLUDED.activo,
    updated_by = EXCLUDED.updated_by,
    updated_at = CURRENT_TIMESTAMP;

-- assinaturas
SET search_path TO assinaturas, public;

INSERT INTO subscription_plans (tenant_id, codigo, nome, billing_period, preco, moeda, limites, activo)
VALUES
    (1, 'BASIC', 'Plano Basic', 'mensal', 3500.00, 'MZN', '{"users":5,"branches":1}'::jsonb, TRUE),
    (1, 'PRO', 'Plano Pro', 'mensal', 9500.00, 'MZN', '{"users":25,"branches":5}'::jsonb, TRUE)
ON CONFLICT (tenant_id, codigo)
DO UPDATE SET
    nome = EXCLUDED.nome,
    billing_period = EXCLUDED.billing_period,
    preco = EXCLUDED.preco,
    moeda = EXCLUDED.moeda,
    limites = EXCLUDED.limites,
    activo = EXCLUDED.activo,
    updated_at = CURRENT_TIMESTAMP;

-- Reset
SET search_path TO public;
