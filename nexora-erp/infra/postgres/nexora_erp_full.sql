-- ================================================================
-- NEXORA ERP — Full Database Initialization
-- PostgreSQL 16+
-- Single file — execute with:
--   psql -U nexora -d nexora_erp -f nexora_erp_full.sql
-- ================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ================================================================
-- SCHEMA: auth  (auth-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS auth;
SET search_path TO auth, public;

-- Nexora ERP — Auth Service — Schema inicial
-- PostgreSQL 16

CREATE TABLE IF NOT EXISTS users (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    nome        VARCHAR(150) NOT NULL,
    email       VARCHAR(150) NOT NULL,
    password_hash TEXT NOT NULL,
    telefone    VARCHAR(30),
    estado      VARCHAR(20) NOT NULL DEFAULT 'ativo'
                    CHECK (estado IN ('ativo', 'bloqueado', 'pendente', 'inativo')),
    email_verificado BOOLEAN NOT NULL DEFAULT FALSE,
    ultimo_login_em TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_users_tenant_email UNIQUE (tenant_id, email)
);

CREATE TABLE IF NOT EXISTS sessions (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    token_hash  TEXT NOT NULL UNIQUE,
    ip_address  VARCHAR(64),
    user_agent  TEXT,
    iniciado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expira_em   TIMESTAMPTZ NOT NULL,
    encerrado_em TIMESTAMPTZ,
    ativa       BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS login_history (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id         BIGINT,
    tenant_id       BIGINT NOT NULL,
    email_tentado   VARCHAR(150),
    sucesso         BOOLEAN NOT NULL,
    ip_address      VARCHAR(64),
    user_agent      TEXT,
    motivo_falha    VARCHAR(255),
    criado_em       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_login_history_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS password_resets (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    token_hash  TEXT NOT NULL UNIQUE,
    expira_em   TIMESTAMPTZ NOT NULL,
    usado_em    TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_password_resets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS email_verifications (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    token_hash  TEXT NOT NULL UNIQUE,
    expira_em   TIMESTAMPTZ NOT NULL,
    usado_em    TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_email_verifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS api_keys (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    user_id     BIGINT,
    nome        VARCHAR(120) NOT NULL,
    key_prefix  VARCHAR(20) NOT NULL,
    key_hash    TEXT NOT NULL UNIQUE,
    ultimo_uso_em TIMESTAMPTZ,
    expira_em   TIMESTAMPTZ,
    ativa       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_api_keys_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_tenant_id        ON users (tenant_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id        ON sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_ativa          ON sessions (ativa);
CREATE INDEX IF NOT EXISTS idx_sessions_token_hash     ON sessions (token_hash);
CREATE INDEX IF NOT EXISTS idx_login_history_tenant_id ON login_history (tenant_id);
CREATE INDEX IF NOT EXISTS idx_password_resets_user_id ON password_resets (user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_tenant_id      ON api_keys (tenant_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_key_prefix     ON api_keys (key_prefix);

-- ================================================================
-- SCHEMA: empresa  (empresa-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS empresa;
SET search_path TO empresa, public;

-- Nexora ERP — Empresa Service — Schema inicial
-- PostgreSQL 16

CREATE TABLE IF NOT EXISTS companies (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo          VARCHAR(50) NOT NULL,
    nome            VARCHAR(150) NOT NULL,
    nome_comercial  VARCHAR(150),
    tipo            VARCHAR(30) NOT NULL DEFAULT 'empresa'
                        CHECK (tipo IN ('empresa', 'organizacao', 'holding', 'filial_independente')),
    status          VARCHAR(20) NOT NULL DEFAULT 'ativa'
                        CHECK (status IN ('ativa', 'suspensa', 'inativa')),
    moeda_base      VARCHAR(10) NOT NULL DEFAULT 'MZN',
    timezone        VARCHAR(60) NOT NULL DEFAULT 'Africa/Maputo',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_companies_codigo UNIQUE (codigo)
);

CREATE TABLE IF NOT EXISTS company_settings (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id  BIGINT NOT NULL,
    chave       VARCHAR(100) NOT NULL,
    valor       TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_company_settings UNIQUE (company_id, chave),
    CONSTRAINT fk_company_settings_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS company_branches (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id  BIGINT NOT NULL,
    codigo      VARCHAR(50) NOT NULL,
    nome        VARCHAR(150) NOT NULL,
    status      VARCHAR(20) NOT NULL DEFAULT 'ativa' CHECK (status IN ('ativa', 'inativa')),
    principal   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_company_branches UNIQUE (company_id, codigo),
    CONSTRAINT fk_company_branches_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS company_addresses (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id  BIGINT NOT NULL,
    branch_id   BIGINT,
    tipo        VARCHAR(30) NOT NULL DEFAULT 'principal'
                    CHECK (tipo IN ('principal', 'fiscal', 'entrega', 'filial', 'cobranca')),
    endereco    VARCHAR(255) NOT NULL,
    cidade      VARCHAR(100),
    provincia   VARCHAR(100),
    pais        VARCHAR(100) NOT NULL DEFAULT 'Mocambique',
    codigo_postal VARCHAR(30),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_company_addresses_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    CONSTRAINT fk_company_addresses_branch  FOREIGN KEY (branch_id)  REFERENCES company_branches(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS company_contacts (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id  BIGINT NOT NULL,
    branch_id   BIGINT,
    tipo        VARCHAR(30) NOT NULL DEFAULT 'geral'
                    CHECK (tipo IN ('geral', 'financeiro', 'comercial', 'suporte', 'rh')),
    nome        VARCHAR(150),
    telefone    VARCHAR(30),
    email       VARCHAR(150),
    principal   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_company_contacts_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    CONSTRAINT fk_company_contacts_branch  FOREIGN KEY (branch_id)  REFERENCES company_branches(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS company_documents (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id  BIGINT NOT NULL,
    tipo        VARCHAR(30) NOT NULL
                    CHECK (tipo IN ('alvara', 'certidao', 'contrato_social', 'licenca', 'outro')),
    numero      VARCHAR(100),
    ficheiro_url TEXT,
    emitido_em  DATE,
    expira_em   DATE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_company_documents_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS company_tax_info (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id          BIGINT NOT NULL,
    nuit                VARCHAR(30) NOT NULL,
    regime_iva          VARCHAR(50),
    taxa_iva_padrao     NUMERIC(5,2) NOT NULL DEFAULT 17.00 CHECK (taxa_iva_padrao >= 0),
    inicio_atividade    DATE,
    reparticao_fiscal   VARCHAR(150),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_company_tax_info_company UNIQUE (company_id),
    CONSTRAINT uq_company_tax_info_nuit    UNIQUE (nuit),
    CONSTRAINT fk_company_tax_info_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS company_banks (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id      BIGINT NOT NULL,
    banco           VARCHAR(120) NOT NULL,
    numero_conta    VARCHAR(60) NOT NULL,
    nib             VARCHAR(60),
    iban            VARCHAR(60),
    swift           VARCHAR(30),
    moeda           VARCHAR(10) NOT NULL DEFAULT 'MZN',
    principal       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_company_banks_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS company_licenses (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id      BIGINT NOT NULL,
    plano           VARCHAR(50) NOT NULL,
    licenca_chave   VARCHAR(120),
    limite_usuarios INTEGER,
    limite_filiais  INTEGER,
    inicia_em       DATE NOT NULL,
    expira_em       DATE,
    status          VARCHAR(20) NOT NULL DEFAULT 'ativa'
                        CHECK (status IN ('ativa', 'expirada', 'suspensa')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_company_licenses_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS company_users (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id      BIGINT NOT NULL,
    user_id         BIGINT NOT NULL,
    branch_id       BIGINT,
    perfil_empresa  VARCHAR(50),
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_company_users UNIQUE (company_id, user_id),
    CONSTRAINT fk_company_users_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    CONSTRAINT fk_company_users_branch  FOREIGN KEY (branch_id)  REFERENCES company_branches(id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_company_settings_company_id  ON company_settings (company_id);
CREATE INDEX IF NOT EXISTS idx_company_branches_company_id  ON company_branches (company_id);
CREATE INDEX IF NOT EXISTS idx_company_addresses_company_id ON company_addresses (company_id);
CREATE INDEX IF NOT EXISTS idx_company_contacts_company_id  ON company_contacts (company_id);
CREATE INDEX IF NOT EXISTS idx_company_documents_company_id ON company_documents (company_id);
CREATE INDEX IF NOT EXISTS idx_company_banks_company_id     ON company_banks (company_id);
CREATE INDEX IF NOT EXISTS idx_company_licenses_company_id  ON company_licenses (company_id);
CREATE INDEX IF NOT EXISTS idx_company_users_company_id     ON company_users (company_id);
CREATE INDEX IF NOT EXISTS idx_company_users_user_id        ON company_users (user_id);

-- ================================================================
-- SCHEMA: autorizacao  (autorizacao-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS autorizacao;
SET search_path TO autorizacao, public;

CREATE TABLE IF NOT EXISTS roles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_roles_tenant_codigo UNIQUE (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS permissions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(100) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    recurso VARCHAR(100),
    acao VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_permissions_codigo UNIQUE (codigo)
);
CREATE TABLE IF NOT EXISTS role_permissions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_role_permissions UNIQUE (role_id, permission_id),
    CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS user_roles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_roles UNIQUE (user_id, role_id),
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_roles_tenant_id ON roles (tenant_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_role_id ON role_permissions (role_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles (user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles (role_id);

-- ================================================================
-- SCHEMA: clientes  (clientes-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS clientes;
SET search_path TO clientes, public;

CREATE TABLE IF NOT EXISTS customer_groups (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_groups UNIQUE (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS customers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    customer_group_id BIGINT,
    codigo VARCHAR(50),
    nome VARCHAR(150) NOT NULL,
    nuit VARCHAR(30),
    telefone VARCHAR(30),
    email VARCHAR(120),
    estado VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (estado IN ('ativo','inativo','bloqueado')),
    observacao TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customers_tenant_codigo UNIQUE NULLS NOT DISTINCT (tenant_id, codigo),
    CONSTRAINT uq_customers_tenant_nuit UNIQUE NULLS NOT DISTINCT (tenant_id, nuit),
    CONSTRAINT fk_customers_group FOREIGN KEY (customer_group_id) REFERENCES customer_groups(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS customer_contacts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    cargo VARCHAR(100),
    telefone VARCHAR(30),
    email VARCHAR(120),
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer_contacts_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS customer_addresses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'principal' CHECK (tipo IN ('principal','entrega','cobranca','fiscal')),
    endereco VARCHAR(255) NOT NULL,
    cidade VARCHAR(100),
    provincia VARCHAR(100),
    pais VARCHAR(100) NOT NULL DEFAULT 'Mocambique',
    codigo_postal VARCHAR(30),
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer_addresses_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS customer_documents (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('contrato','nuit','bi','comprovativo','outro')),
    numero VARCHAR(100),
    ficheiro_url TEXT,
    emitido_em DATE,
    expira_em DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer_documents_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS customer_credit_limits (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    limite_credito NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (limite_credito >= 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    inicio_em DATE,
    fim_em DATE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_credit_limits_customer UNIQUE (customer_id),
    CONSTRAINT fk_customer_credit_limits_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS customer_notes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    nota TEXT NOT NULL,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer_notes_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS customer_discounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('percentual','valor_fixo')),
    valor NUMERIC(18,2) NOT NULL CHECK (valor >= 0),
    motivo VARCHAR(150),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    inicio_em DATE,
    fim_em DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_customer_discounts_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_customer_groups_tenant_id ON customer_groups (tenant_id);
CREATE INDEX IF NOT EXISTS idx_customers_tenant_id ON customers (tenant_id);
CREATE INDEX IF NOT EXISTS idx_customers_group_id ON customers (customer_group_id);
CREATE INDEX IF NOT EXISTS idx_customer_contacts_customer_id ON customer_contacts (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_customer_id ON customer_addresses (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_documents_customer_id ON customer_documents (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_notes_customer_id ON customer_notes (customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_discounts_customer_id ON customer_discounts (customer_id);

-- ================================================================
-- SCHEMA: produtos  (produtos-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS produtos;
SET search_path TO produtos, public;

CREATE TABLE IF NOT EXISTS product_categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50),
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_categories UNIQUE NULLS NOT DISTINCT (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS product_subcategories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    product_category_id BIGINT NOT NULL,
    codigo VARCHAR(50),
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_subcategories UNIQUE NULLS NOT DISTINCT (tenant_id, codigo),
    CONSTRAINT fk_product_subcategories_category FOREIGN KEY (product_category_id) REFERENCES product_categories(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS product_brands (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50),
    nome VARCHAR(100) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_brands UNIQUE NULLS NOT DISTINCT (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS product_units (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(80) NOT NULL,
    simbolo VARCHAR(20),
    casas_decimais INTEGER NOT NULL DEFAULT 2,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_units UNIQUE (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS warehouses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    localizacao VARCHAR(255),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_warehouses UNIQUE (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    product_category_id BIGINT,
    product_subcategory_id BIGINT,
    product_brand_id BIGINT,
    product_unit_id BIGINT,
    warehouse_default_id BIGINT,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    tipo VARCHAR(30) NOT NULL DEFAULT 'simples' CHECK (tipo IN ('simples','variavel','kit','servico')),
    iva_percentual NUMERIC(5,2) NOT NULL DEFAULT 17.00 CHECK (iva_percentual >= 0),
    stock_minimo NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (stock_minimo >= 0),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_products UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_products_category FOREIGN KEY (product_category_id) REFERENCES product_categories(id) ON DELETE SET NULL,
    CONSTRAINT fk_products_subcategory FOREIGN KEY (product_subcategory_id) REFERENCES product_subcategories(id) ON DELETE SET NULL,
    CONSTRAINT fk_products_brand FOREIGN KEY (product_brand_id) REFERENCES product_brands(id) ON DELETE SET NULL,
    CONSTRAINT fk_products_unit FOREIGN KEY (product_unit_id) REFERENCES product_units(id) ON DELETE SET NULL,
    CONSTRAINT fk_products_warehouse FOREIGN KEY (warehouse_default_id) REFERENCES warehouses(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS product_variants (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    codigo VARCHAR(50),
    nome VARCHAR(150) NOT NULL,
    sku VARCHAR(80),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_variants UNIQUE NULLS NOT DISTINCT (product_id, codigo),
    CONSTRAINT fk_product_variants_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS product_prices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    tipo_preco VARCHAR(30) NOT NULL DEFAULT 'venda' CHECK (tipo_preco IN ('custo','venda','atacado','promocional')),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    valor NUMERIC(18,2) NOT NULL CHECK (valor >= 0),
    inicia_em TIMESTAMPTZ,
    fim_em TIMESTAMPTZ,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_prices_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_prices_variant FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS product_barcodes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    barcode VARCHAR(100) NOT NULL,
    tipo VARCHAR(30),
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_product_barcodes UNIQUE (barcode),
    CONSTRAINT fk_product_barcodes_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_product_categories_tenant ON product_categories (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_brands_tenant ON product_brands (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_units_tenant ON product_units (tenant_id);
CREATE INDEX IF NOT EXISTS idx_warehouses_tenant ON warehouses (tenant_id);
CREATE INDEX IF NOT EXISTS idx_products_tenant ON products (tenant_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_product ON product_variants (product_id);
CREATE INDEX IF NOT EXISTS idx_product_prices_product ON product_prices (product_id);
CREATE INDEX IF NOT EXISTS idx_product_barcodes_product ON product_barcodes (product_id);

-- ================================================================
-- SCHEMA: impostos  (impostos-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS impostos;
SET search_path TO impostos, public;

CREATE TABLE IF NOT EXISTS tax_regimes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_tax_regimes UNIQUE (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS taxes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    taxa NUMERIC(8,4) NOT NULL DEFAULT 0 CHECK (taxa >= 0),
    tipo VARCHAR(20) NOT NULL DEFAULT 'iva' CHECK (tipo IN ('iva','isento','zero','outro')),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_taxes UNIQUE (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS tax_exemptions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    tax_id BIGINT NOT NULL,
    entity_type VARCHAR(30) NOT NULL CHECK (entity_type IN ('customer','supplier','product','product_category')),
    entity_id BIGINT NOT NULL,
    motivo VARCHAR(255),
    numero_isencao VARCHAR(60),
    validade DATE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tax_exemptions_tax FOREIGN KEY (tax_id) REFERENCES taxes(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS withholding_taxes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    taxa NUMERIC(8,4) NOT NULL CHECK (taxa >= 0),
    aplica_em VARCHAR(30) NOT NULL CHECK (aplica_em IN ('pagamento','fatura')),
    tipo_entidade VARCHAR(30) CHECK (tipo_entidade IN ('pessoa_singular','pessoa_colectiva','todos')),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_withholding_taxes UNIQUE (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS withholding_tax_transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    withholding_tax_id BIGINT NOT NULL,
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    base_imponivel NUMERIC(18,2) NOT NULL,
    taxa_aplicada NUMERIC(8,4) NOT NULL,
    valor_retido NUMERIC(18,2) NOT NULL,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_wtt_wt FOREIGN KEY (withholding_tax_id) REFERENCES withholding_taxes(id)
);
CREATE TABLE IF NOT EXISTS tax_returns (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    periodo VARCHAR(20) NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('iva','irps','irpc','retencoes')),
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho','submetida','paga','cancelada')),
    total_base NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_imposto NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_credito NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_a_pagar NUMERIC(18,2) NOT NULL DEFAULT 0,
    data_submissao TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tax_returns UNIQUE (tenant_id, periodo, tipo)
);
CREATE INDEX IF NOT EXISTS idx_tax_regimes_tenant ON tax_regimes (tenant_id);
CREATE INDEX IF NOT EXISTS idx_taxes_tenant ON taxes (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tax_exemptions_tenant ON tax_exemptions (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tax_exemptions_entity ON tax_exemptions (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_wtt_tenant ON withholding_tax_transactions (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tax_returns_tenant ON tax_returns (tenant_id);

-- ================================================================
-- SCHEMA: stock  (stock-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS stock;
SET search_path TO stock, public;

CREATE TABLE IF NOT EXISTS stock_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    warehouse_id BIGINT NOT NULL,
    quantity NUMERIC(18,2) NOT NULL DEFAULT 0,
    reserved_quantity NUMERIC(18,2) NOT NULL DEFAULT 0,
    available_quantity NUMERIC(18,2) GENERATED ALWAYS AS (quantity - reserved_quantity) STORED,
    minimum_quantity NUMERIC(18,2) NOT NULL DEFAULT 0,
    maximum_quantity NUMERIC(18,2),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_stock_items UNIQUE NULLS NOT DISTINCT (tenant_id, product_id, product_variant_id, warehouse_id)
);
CREATE TABLE IF NOT EXISTS stock_movements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('entrada','saida','transferencia_entrada','transferencia_saida','ajuste','reserva','liberacao')),
    quantity NUMERIC(18,2) NOT NULL,
    reference_type VARCHAR(50),
    reference_id BIGINT,
    movement_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stock_movements_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS stock_adjustments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    adjustment_type VARCHAR(20) NOT NULL CHECK (adjustment_type IN ('positivo','negativo')),
    quantity NUMERIC(18,2) NOT NULL,
    reason TEXT,
    adjusted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stock_adjustments_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS stock_transfers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    from_warehouse_id BIGINT NOT NULL,
    to_warehouse_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','em_transito','concluida','cancelada')),
    transfer_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_stock_transfers UNIQUE (tenant_id, numero)
);
CREATE TABLE IF NOT EXISTS stock_transfer_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stock_transfer_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    quantity NUMERIC(18,2) NOT NULL CHECK (quantity > 0),
    CONSTRAINT fk_sti_transfer FOREIGN KEY (stock_transfer_id) REFERENCES stock_transfers(id) ON DELETE CASCADE,
    CONSTRAINT fk_sti_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id)
);
CREATE TABLE IF NOT EXISTS stock_reservations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    quantity NUMERIC(18,2) NOT NULL,
    reference_type VARCHAR(50),
    reference_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'ativa' CHECK (status IN ('ativa','consumida','cancelada')),
    reserved_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stock_reservations_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS stock_alerts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    stock_item_id BIGINT NOT NULL,
    alert_type VARCHAR(30) NOT NULL CHECK (alert_type IN ('stock_minimo','stock_maximo','lote_expirar')),
    status VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto','resolvido','ignorado')),
    mensagem TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_stock_alerts_item FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_stock_items_tenant ON stock_items (tenant_id);
CREATE INDEX IF NOT EXISTS idx_stock_items_product ON stock_items (product_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_item ON stock_movements (stock_item_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_tenant ON stock_movements (tenant_id);
CREATE INDEX IF NOT EXISTS idx_stock_transfers_tenant ON stock_transfers (tenant_id);
CREATE INDEX IF NOT EXISTS idx_stock_alerts_tenant ON stock_alerts (tenant_id);

-- ================================================================
-- SCHEMA: faturacao  (faturacao-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS faturacao;
SET search_path TO faturacao, public;

-- Nexora ERP — Faturacao Service — Schema
-- PostgreSQL 16

-- ============================================================
-- SERIES DOCUMENTAIS
-- ============================================================

CREATE TABLE IF NOT EXISTS invoice_series (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id   BIGINT NOT NULL,
    tipo        VARCHAR(10) NOT NULL CHECK (tipo IN ('ORC','ENC','GR','FT','NC','RB')),
    prefixo     VARCHAR(20) NOT NULL,
    ano         INTEGER NOT NULL,
    sequencia   INTEGER NOT NULL DEFAULT 0,
    ativo       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_invoice_series UNIQUE (tenant_id, tipo, ano)
);

-- ============================================================
-- ORCAMENTOS
-- ============================================================

CREATE TABLE IF NOT EXISTS sales_quotes (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id       BIGINT NOT NULL,
    serie_id        BIGINT,
    customer_id     BIGINT NOT NULL,
    numero          VARCHAR(50) NOT NULL,
    quote_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    validade        DATE,
    moeda           VARCHAR(10) NOT NULL DEFAULT 'MZN',
    subtotal        NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto_total  NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total   NUMERIC(18,2) NOT NULL DEFAULT 0,
    total           NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes     TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'rascunho'
                        CHECK (status IN ('rascunho','enviado','aprovado','rejeitado','convertido','expirado')),
    criado_por      BIGINT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sales_quotes UNIQUE (tenant_id, numero),
    CONSTRAINT fk_quotes_serie FOREIGN KEY (serie_id) REFERENCES invoice_series(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sales_quote_items (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sales_quote_id      BIGINT NOT NULL,
    product_id          BIGINT NOT NULL,
    descricao           VARCHAR(255),
    quantidade          NUMERIC(18,4) NOT NULL CHECK (quantidade > 0),
    preco_unitario      NUMERIC(18,4) NOT NULL CHECK (preco_unitario >= 0),
    desconto_percent    NUMERIC(8,4) NOT NULL DEFAULT 0,
    desconto_valor      NUMERIC(18,2) NOT NULL DEFAULT 0,
    tax_id              BIGINT,
    imposto_percent     NUMERIC(8,4) NOT NULL DEFAULT 0,
    imposto_valor       NUMERIC(18,2) NOT NULL DEFAULT 0,
    subtotal            NUMERIC(18,2) NOT NULL DEFAULT 0,
    total               NUMERIC(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_quote_items_quote FOREIGN KEY (sales_quote_id) REFERENCES sales_quotes(id) ON DELETE CASCADE
);

-- ============================================================
-- ENCOMENDAS DE VENDA
-- ============================================================

CREATE TABLE IF NOT EXISTS sales_orders (
    id                      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id               BIGINT NOT NULL,
    serie_id                BIGINT,
    customer_id             BIGINT NOT NULL,
    sales_quote_id          BIGINT,
    numero                  VARCHAR(50) NOT NULL,
    order_date              DATE NOT NULL DEFAULT CURRENT_DATE,
    data_entrega_prevista   DATE,
    moeda                   VARCHAR(10) NOT NULL DEFAULT 'MZN',
    subtotal                NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto_total          NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total           NUMERIC(18,2) NOT NULL DEFAULT 0,
    total                   NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes             TEXT,
    status                  VARCHAR(20) NOT NULL DEFAULT 'rascunho'
                                CHECK (status IN ('rascunho','confirmada','parcial','entregue','cancelada')),
    criado_por              BIGINT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sales_orders UNIQUE (tenant_id, numero),
    CONSTRAINT fk_orders_serie FOREIGN KEY (serie_id) REFERENCES invoice_series(id) ON DELETE SET NULL,
    CONSTRAINT fk_orders_quote FOREIGN KEY (sales_quote_id) REFERENCES sales_quotes(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sales_order_items (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sales_order_id      BIGINT NOT NULL,
    product_id          BIGINT NOT NULL,
    descricao           VARCHAR(255),
    quantidade          NUMERIC(18,4) NOT NULL CHECK (quantidade > 0),
    quantidade_entregue NUMERIC(18,4) NOT NULL DEFAULT 0,
    preco_unitario      NUMERIC(18,4) NOT NULL CHECK (preco_unitario >= 0),
    desconto_percent    NUMERIC(8,4) NOT NULL DEFAULT 0,
    desconto_valor      NUMERIC(18,2) NOT NULL DEFAULT 0,
    tax_id              BIGINT,
    imposto_percent     NUMERIC(8,4) NOT NULL DEFAULT 0,
    imposto_valor       NUMERIC(18,2) NOT NULL DEFAULT 0,
    subtotal            NUMERIC(18,2) NOT NULL DEFAULT 0,
    total               NUMERIC(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_order_items_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE CASCADE
);

-- ============================================================
-- GUIAS DE REMESSA
-- ============================================================

CREATE TABLE IF NOT EXISTS sales_deliveries (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id       BIGINT NOT NULL,
    serie_id        BIGINT,
    sales_order_id  BIGINT NOT NULL,
    numero          VARCHAR(50) NOT NULL,
    delivery_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    morada_entrega  TEXT,
    observacoes     TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'emitida'
                        CHECK (status IN ('emitida','em_transito','entregue','cancelada')),
    criado_por      BIGINT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sales_deliveries UNIQUE (tenant_id, numero),
    CONSTRAINT fk_deliveries_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
    CONSTRAINT fk_deliveries_serie FOREIGN KEY (serie_id) REFERENCES invoice_series(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sales_delivery_items (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sales_delivery_id   BIGINT NOT NULL,
    sales_order_item_id BIGINT,
    product_id          BIGINT NOT NULL,
    quantidade_entregue NUMERIC(18,4) NOT NULL CHECK (quantidade_entregue > 0),
    CONSTRAINT fk_delivery_items_delivery FOREIGN KEY (sales_delivery_id) REFERENCES sales_deliveries(id) ON DELETE CASCADE
);

-- ============================================================
-- FATURAS
-- ============================================================

CREATE TABLE IF NOT EXISTS invoices (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id       BIGINT NOT NULL,
    serie_id        BIGINT,
    customer_id     BIGINT NOT NULL,
    sales_order_id  BIGINT,
    numero          VARCHAR(50) NOT NULL,
    invoice_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date        DATE,
    moeda           VARCHAR(10) NOT NULL DEFAULT 'MZN',
    taxa_cambio     NUMERIC(14,6) NOT NULL DEFAULT 1,
    subtotal        NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto_total  NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total   NUMERIC(18,2) NOT NULL DEFAULT 0,
    total           NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_pago      NUMERIC(18,2) NOT NULL DEFAULT 0,
    saldo_pendente  NUMERIC(18,2) GENERATED ALWAYS AS (total - valor_pago) STORED,
    payment_terms   VARCHAR(100),
    observacoes     TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'rascunho'
                        CHECK (status IN ('rascunho','emitida','parcialmente_paga','paga','cancelada','vencida')),
    emitida_em      TIMESTAMPTZ,
    criado_por      BIGINT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_invoices UNIQUE (tenant_id, numero),
    CONSTRAINT fk_invoices_serie FOREIGN KEY (serie_id) REFERENCES invoice_series(id) ON DELETE SET NULL,
    CONSTRAINT fk_invoices_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS invoice_items (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_id          BIGINT NOT NULL,
    product_id          BIGINT NOT NULL,
    descricao           VARCHAR(255),
    quantidade          NUMERIC(18,4) NOT NULL CHECK (quantidade > 0),
    preco_unitario      NUMERIC(18,4) NOT NULL CHECK (preco_unitario >= 0),
    desconto_percent    NUMERIC(8,4) NOT NULL DEFAULT 0,
    desconto_valor      NUMERIC(18,2) NOT NULL DEFAULT 0,
    tax_id              BIGINT,
    imposto_percent     NUMERIC(8,4) NOT NULL DEFAULT 0,
    imposto_valor       NUMERIC(18,2) NOT NULL DEFAULT 0,
    subtotal            NUMERIC(18,2) NOT NULL DEFAULT 0,
    total               NUMERIC(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_invoice_items_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS invoice_taxes (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_id      BIGINT NOT NULL,
    tax_id          BIGINT,
    nome_imposto    VARCHAR(100) NOT NULL,
    taxa            NUMERIC(8,4) NOT NULL,
    base_imponivel  NUMERIC(18,2) NOT NULL,
    valor_imposto   NUMERIC(18,2) NOT NULL,
    CONSTRAINT fk_invoice_taxes_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS invoice_discounts (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_id  BIGINT NOT NULL,
    tipo        VARCHAR(20) NOT NULL CHECK (tipo IN ('percentual','valor_fixo')),
    valor       NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    descricao   TEXT,
    CONSTRAINT fk_invoice_discounts_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

-- ============================================================
-- RECIBOS
-- ============================================================

CREATE TABLE IF NOT EXISTS invoice_receipts (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id           BIGINT NOT NULL,
    serie_id            BIGINT,
    invoice_id          BIGINT NOT NULL,
    numero              VARCHAR(50) NOT NULL,
    payment_date        DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method_id   BIGINT,
    valor               NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    referencia          VARCHAR(100),
    observacoes         TEXT,
    status              VARCHAR(20) NOT NULL DEFAULT 'confirmado'
                            CHECK (status IN ('pendente','confirmado','cancelado')),
    criado_por          BIGINT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_invoice_receipts UNIQUE (tenant_id, numero),
    CONSTRAINT fk_receipts_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id),
    CONSTRAINT fk_receipts_serie FOREIGN KEY (serie_id) REFERENCES invoice_series(id) ON DELETE SET NULL
);

-- ============================================================
-- NOTAS DE CREDITO
-- ============================================================

CREATE TABLE IF NOT EXISTS credit_notes (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id       BIGINT NOT NULL,
    serie_id        BIGINT,
    customer_id     BIGINT NOT NULL,
    invoice_id      BIGINT,
    numero          VARCHAR(50) NOT NULL,
    credit_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    motivo          VARCHAR(255) NOT NULL,
    moeda           VARCHAR(10) NOT NULL DEFAULT 'MZN',
    subtotal        NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total   NUMERIC(18,2) NOT NULL DEFAULT 0,
    total           NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes     TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'rascunho'
                        CHECK (status IN ('rascunho','emitida','aplicada','cancelada')),
    emitida_em      TIMESTAMPTZ,
    criado_por      BIGINT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_credit_notes UNIQUE (tenant_id, numero),
    CONSTRAINT fk_credit_notes_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL,
    CONSTRAINT fk_credit_notes_serie FOREIGN KEY (serie_id) REFERENCES invoice_series(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS credit_note_items (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    credit_note_id  BIGINT NOT NULL,
    product_id      BIGINT,
    descricao       VARCHAR(255) NOT NULL,
    quantidade      NUMERIC(18,4) NOT NULL DEFAULT 1,
    preco_unitario  NUMERIC(18,4) NOT NULL DEFAULT 0,
    tax_id          BIGINT,
    imposto_percent NUMERIC(8,4) NOT NULL DEFAULT 0,
    imposto_valor   NUMERIC(18,2) NOT NULL DEFAULT 0,
    subtotal        NUMERIC(18,2) NOT NULL DEFAULT 0,
    total           NUMERIC(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_credit_note_items_nc FOREIGN KEY (credit_note_id) REFERENCES credit_notes(id) ON DELETE CASCADE
);

-- ============================================================
-- DEVOLUCOES DE VENDA
-- ============================================================

CREATE TABLE IF NOT EXISTS sales_returns (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id       BIGINT NOT NULL,
    customer_id     BIGINT NOT NULL,
    invoice_id      BIGINT,
    credit_note_id  BIGINT,
    numero          VARCHAR(50) NOT NULL,
    return_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    observacoes     TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'pendente'
                        CHECK (status IN ('pendente','recebida','processada','cancelada')),
    criado_por      BIGINT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sales_returns UNIQUE (tenant_id, numero),
    CONSTRAINT fk_returns_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE SET NULL,
    CONSTRAINT fk_returns_cn FOREIGN KEY (credit_note_id) REFERENCES credit_notes(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sales_return_items (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sales_return_id BIGINT NOT NULL,
    product_id      BIGINT NOT NULL,
    quantidade      NUMERIC(18,4) NOT NULL CHECK (quantidade > 0),
    motivo          TEXT,
    estado_produto  VARCHAR(20) DEFAULT 'bom' CHECK (estado_produto IN ('bom','danificado','defeito')),
    CONSTRAINT fk_return_items_return FOREIGN KEY (sales_return_id) REFERENCES sales_returns(id) ON DELETE CASCADE
);

-- ============================================================
-- INDICES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_invoice_series_tenant     ON invoice_series (tenant_id, tipo, ano);
CREATE INDEX IF NOT EXISTS idx_sales_quotes_tenant       ON sales_quotes (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_sales_quotes_customer     ON sales_quotes (customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_orders_tenant       ON sales_orders (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_sales_orders_customer     ON sales_orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_deliveries_order    ON sales_deliveries (sales_order_id);
CREATE INDEX IF NOT EXISTS idx_invoices_tenant           ON invoices (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_invoices_customer         ON invoices (customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date         ON invoices (due_date) WHERE status NOT IN ('paga','cancelada');
CREATE INDEX IF NOT EXISTS idx_receipts_invoice          ON invoice_receipts (invoice_id);
CREATE INDEX IF NOT EXISTS idx_credit_notes_tenant       ON credit_notes (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_credit_notes_invoice      ON credit_notes (invoice_id);
CREATE INDEX IF NOT EXISTS idx_sales_returns_invoice     ON sales_returns (invoice_id);

-- ================================================================
-- SCHEMA: compras  (compras-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS compras;
SET search_path TO compras, public;

CREATE TABLE IF NOT EXISTS supplier_groups (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_supplier_groups UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS suppliers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    supplier_group_id BIGINT,
    codigo VARCHAR(50),
    nome VARCHAR(150) NOT NULL,
    nuit VARCHAR(30),
    telefone VARCHAR(30),
    email VARCHAR(120),
    moeda_padrao VARCHAR(10) NOT NULL DEFAULT 'MZN',
    prazo_pagamento_dias INTEGER NOT NULL DEFAULT 0,
    estado VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (estado IN ('ativo','inativo','bloqueado')),
    observacao TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_suppliers_tenant_codigo UNIQUE NULLS NOT DISTINCT (tenant_id, codigo),
    CONSTRAINT uq_suppliers_tenant_nuit UNIQUE NULLS NOT DISTINCT (tenant_id, nuit),
    CONSTRAINT fk_suppliers_group FOREIGN KEY (supplier_group_id) REFERENCES supplier_groups(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS supplier_contacts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_id BIGINT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    cargo VARCHAR(100),
    telefone VARCHAR(30),
    email VARCHAR(120),
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_supplier_contacts_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS supplier_addresses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'principal' CHECK (tipo IN ('principal','entrega','cobranca','fiscal')),
    endereco VARCHAR(255) NOT NULL,
    cidade VARCHAR(100),
    provincia VARCHAR(100),
    pais VARCHAR(100) NOT NULL DEFAULT 'Mocambique',
    codigo_postal VARCHAR(30),
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_supplier_addresses_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS purchase_orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho','aprovada','parcial','recebida','cancelada')),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes TEXT,
    criado_por BIGINT,
    aprovado_por BIGINT,
    aprovado_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchase_orders UNIQUE (tenant_id, numero),
    CONSTRAINT fk_purchase_orders_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS purchase_order_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_order_id BIGINT NOT NULL,
    product_id BIGINT,
    descricao VARCHAR(255) NOT NULL,
    unidade VARCHAR(30) NOT NULL DEFAULT 'UN',
    quantity NUMERIC(18,3) NOT NULL CHECK (quantity > 0),
    received_quantity NUMERIC(18,3) NOT NULL DEFAULT 0 CHECK (received_quantity >= 0),
    unit_price NUMERIC(18,2) NOT NULL CHECK (unit_price >= 0),
    desconto NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (desconto >= 0),
    tax_rate NUMERIC(8,4) NOT NULL DEFAULT 0 CHECK (tax_rate >= 0),
    tax_amount NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    total NUMERIC(18,2) NOT NULL CHECK (total >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_purchase_order_items_order FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS goods_receipts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    purchase_order_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    receipt_date DATE NOT NULL DEFAULT CURRENT_DATE,
    warehouse_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'confirmado' CHECK (status IN ('confirmado','cancelado')),
    observacoes TEXT,
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_goods_receipts UNIQUE (tenant_id, numero),
    CONSTRAINT fk_goods_receipts_order FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE RESTRICT,
    CONSTRAINT fk_goods_receipts_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS goods_receipt_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    goods_receipt_id BIGINT NOT NULL,
    purchase_order_item_id BIGINT NOT NULL,
    product_id BIGINT,
    quantity_received NUMERIC(18,3) NOT NULL CHECK (quantity_received > 0),
    returned_quantity NUMERIC(18,3) NOT NULL DEFAULT 0 CHECK (returned_quantity >= 0),
    unit_cost NUMERIC(18,2) NOT NULL CHECK (unit_cost >= 0),
    lote VARCHAR(80),
    validade DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_goods_receipt_items_receipt FOREIGN KEY (goods_receipt_id) REFERENCES goods_receipts(id) ON DELETE CASCADE,
    CONSTRAINT fk_goods_receipt_items_order_item FOREIGN KEY (purchase_order_item_id) REFERENCES purchase_order_items(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS purchase_returns (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    supplier_id BIGINT NOT NULL,
    goods_receipt_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    return_date DATE NOT NULL DEFAULT CURRENT_DATE,
    motivo VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'confirmada' CHECK (status IN ('confirmada','cancelada')),
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes TEXT,
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchase_returns UNIQUE (tenant_id, numero),
    CONSTRAINT fk_purchase_returns_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
    CONSTRAINT fk_purchase_returns_receipt FOREIGN KEY (goods_receipt_id) REFERENCES goods_receipts(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS purchase_return_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_return_id BIGINT NOT NULL,
    goods_receipt_item_id BIGINT NOT NULL,
    product_id BIGINT,
    quantity NUMERIC(18,3) NOT NULL CHECK (quantity > 0),
    unit_cost NUMERIC(18,2) NOT NULL CHECK (unit_cost >= 0),
    total NUMERIC(18,2) NOT NULL CHECK (total >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_purchase_return_items_return FOREIGN KEY (purchase_return_id) REFERENCES purchase_returns(id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_return_items_receipt_item FOREIGN KEY (goods_receipt_item_id) REFERENCES goods_receipt_items(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_supplier_groups_tenant ON supplier_groups (tenant_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_tenant ON suppliers (tenant_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_tenant_status ON purchase_orders (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier ON purchase_orders (supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_order_items_order ON purchase_order_items (purchase_order_id);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_tenant_date ON goods_receipts (tenant_id, receipt_date);
CREATE INDEX IF NOT EXISTS idx_goods_receipt_items_receipt ON goods_receipt_items (goods_receipt_id);
CREATE INDEX IF NOT EXISTS idx_purchase_returns_tenant_date ON purchase_returns (tenant_id, return_date);
CREATE INDEX IF NOT EXISTS idx_purchase_return_items_return ON purchase_return_items (purchase_return_id);

-- ================================================================
-- SCHEMA: financeiro  (financeiro-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS financeiro;
SET search_path TO financeiro, public;

CREATE TABLE IF NOT EXISTS payment_methods (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'outro' CHECK (tipo IN ('numerario','transferencia','tpa','cheque','credito','debito','mpesa','emola','outro')),
    requer_referencia BOOLEAN NOT NULL DEFAULT FALSE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_payment_methods UNIQUE (tenant_id, codigo)
);
CREATE TABLE IF NOT EXISTS financial_categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    parent_id BIGINT,
    codigo VARCHAR(30),
    nome VARCHAR(120) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('receita','despesa','transferencia')),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_financial_categories_parent FOREIGN KEY (parent_id) REFERENCES financial_categories(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    payment_method_id BIGINT,
    financial_category_id BIGINT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('recebimento','pagamento')),
    data_pagamento DATE NOT NULL,
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    descricao TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'confirmado' CHECK (status IN ('pendente','confirmado','cancelado')),
    criado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payments UNIQUE (tenant_id, numero),
    CONSTRAINT fk_payments_method FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id) ON DELETE SET NULL,
    CONSTRAINT fk_payments_category FOREIGN KEY (financial_category_id) REFERENCES financial_categories(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS accounts_receivable (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    customer_id BIGINT NOT NULL,
    financial_category_id BIGINT,
    origem_tipo VARCHAR(50),
    origem_id BIGINT,
    descricao VARCHAR(255),
    valor_total NUMERIC(18,2) NOT NULL CHECK (valor_total > 0),
    valor_pago NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_pendente NUMERIC(18,2) GENERATED ALWAYS AS (valor_total - valor_pago) STORED,
    data_emissao DATE NOT NULL,
    data_vencimento DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','parcial','liquidada','cancelada','vencida')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_accounts_receivable UNIQUE (tenant_id, numero),
    CONSTRAINT fk_ar_category FOREIGN KEY (financial_category_id) REFERENCES financial_categories(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS accounts_receivable_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    accounts_receivable_id BIGINT NOT NULL,
    payment_id BIGINT NOT NULL,
    valor_imputado NUMERIC(18,2) NOT NULL CHECK (valor_imputado > 0),
    data_imputacao TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_ar_payments UNIQUE (accounts_receivable_id, payment_id),
    CONSTRAINT fk_ar_payments_ar FOREIGN KEY (accounts_receivable_id) REFERENCES accounts_receivable(id) ON DELETE CASCADE,
    CONSTRAINT fk_ar_payments_payment FOREIGN KEY (payment_id) REFERENCES payments(id)
);
CREATE TABLE IF NOT EXISTS accounts_payable (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    supplier_id BIGINT,
    financial_category_id BIGINT,
    origem_tipo VARCHAR(50),
    origem_id BIGINT,
    descricao VARCHAR(255),
    valor_total NUMERIC(18,2) NOT NULL CHECK (valor_total > 0),
    valor_pago NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_pendente NUMERIC(18,2) GENERATED ALWAYS AS (valor_total - valor_pago) STORED,
    data_emissao DATE NOT NULL,
    data_vencimento DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','parcial','liquidada','cancelada','vencida')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_accounts_payable UNIQUE (tenant_id, numero),
    CONSTRAINT fk_ap_category FOREIGN KEY (financial_category_id) REFERENCES financial_categories(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS accounts_payable_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    accounts_payable_id BIGINT NOT NULL,
    payment_id BIGINT NOT NULL,
    valor_imputado NUMERIC(18,2) NOT NULL CHECK (valor_imputado > 0),
    data_imputacao TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_ap_payments UNIQUE (accounts_payable_id, payment_id),
    CONSTRAINT fk_ap_payments_ap FOREIGN KEY (accounts_payable_id) REFERENCES accounts_payable(id) ON DELETE CASCADE,
    CONSTRAINT fk_ap_payments_payment FOREIGN KEY (payment_id) REFERENCES payments(id)
);
CREATE TABLE IF NOT EXISTS financial_budgets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    financial_category_id BIGINT NOT NULL,
    ano INTEGER NOT NULL,
    mes INTEGER CHECK (mes BETWEEN 1 AND 12),
    valor_orcamentado NUMERIC(18,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_financial_budgets UNIQUE (tenant_id, financial_category_id, ano, mes),
    CONSTRAINT fk_budgets_category FOREIGN KEY (financial_category_id) REFERENCES financial_categories(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS cash_flow_entries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    financial_category_id BIGINT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('entrada','saida')),
    origem VARCHAR(30) NOT NULL CHECK (origem IN ('realizado','previsto')),
    data DATE NOT NULL,
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    descricao VARCHAR(255),
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cashflow_category FOREIGN KEY (financial_category_id) REFERENCES financial_categories(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_payment_methods_tenant ON payment_methods (tenant_id);
CREATE INDEX IF NOT EXISTS idx_financial_categories_tenant ON financial_categories (tenant_id);
CREATE INDEX IF NOT EXISTS idx_payments_tenant ON payments (tenant_id);
CREATE INDEX IF NOT EXISTS idx_payments_data ON payments (tenant_id, data_pagamento);
CREATE INDEX IF NOT EXISTS idx_payments_referencia ON payments (referencia_tipo, referencia_id);
CREATE INDEX IF NOT EXISTS idx_ar_tenant_status ON accounts_receivable (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_ar_customer ON accounts_receivable (customer_id);
CREATE INDEX IF NOT EXISTS idx_ar_vencimento ON accounts_receivable (data_vencimento);
CREATE INDEX IF NOT EXISTS idx_ap_tenant_status ON accounts_payable (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_ap_vencimento ON accounts_payable (data_vencimento);
CREATE INDEX IF NOT EXISTS idx_budgets_tenant ON financial_budgets (tenant_id, ano);
CREATE INDEX IF NOT EXISTS idx_cashflow_tenant_data ON cash_flow_entries (tenant_id, data);

-- ================================================================
-- SCHEMA: tesouraria  (tesouraria-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS tesouraria;
SET search_path TO tesouraria, public;

CREATE TABLE IF NOT EXISTS contas_bancarias (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    banco VARCHAR(120) NOT NULL,
    numero_conta VARCHAR(60) NOT NULL,
    nib VARCHAR(60),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    saldo_atual NUMERIC(18,2) NOT NULL DEFAULT 0,
    ativa BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS caixas (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    nome VARCHAR(120) NOT NULL,
    saldo_atual NUMERIC(18,2) NOT NULL DEFAULT 0,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS movimentos_financeiros (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    origem_tipo VARCHAR(30) NOT NULL CHECK (origem_tipo IN ('faturacao','compras','rh','ajuste')),
    origem_id BIGINT,
    conta_bancaria_id BIGINT,
    caixa_id BIGINT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('recebimento','pagamento','transferencia','ajuste')),
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    referencia VARCHAR(100),
    descricao TEXT,
    data_movimento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_mov_conta FOREIGN KEY (conta_bancaria_id) REFERENCES contas_bancarias(id) ON DELETE SET NULL,
    CONSTRAINT fk_mov_caixa FOREIGN KEY (caixa_id) REFERENCES caixas(id) ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS reconciliacoes_bancarias (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    conta_bancaria_id BIGINT NOT NULL,
    periodo_inicio DATE NOT NULL,
    periodo_fim DATE NOT NULL,
    saldo_extrato NUMERIC(18,2) NOT NULL,
    saldo_sistema NUMERIC(18,2) NOT NULL,
    diferenca NUMERIC(18,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'aberta' CHECK (status IN ('aberta','fechada')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reconciliacoes_conta FOREIGN KEY (conta_bancaria_id) REFERENCES contas_bancarias(id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS idx_contas_bancarias_tenant_id ON contas_bancarias (tenant_id);
CREATE INDEX IF NOT EXISTS idx_caixas_tenant_id ON caixas (tenant_id);
CREATE INDEX IF NOT EXISTS idx_movimentos_tenant_id ON movimentos_financeiros (tenant_id);
CREATE INDEX IF NOT EXISTS idx_reconciliacoes_conta_id ON reconciliacoes_bancarias (conta_bancaria_id);

-- ================================================================
-- SCHEMA: contabilidade  (contabilidade-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS contabilidade;
SET search_path TO contabilidade, public;

CREATE TABLE IF NOT EXISTS accounting_periods (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ano INTEGER NOT NULL,
    mes INTEGER CHECK (mes BETWEEN 1 AND 12),
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto','fechado')),
    fechado_em TIMESTAMPTZ,
    fechado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_accounting_periods UNIQUE (tenant_id, ano, mes)
);

CREATE TABLE IF NOT EXISTS chart_of_accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    parent_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('ativo','passivo','capital','rendimento','gasto')),
    natureza VARCHAR(20) NOT NULL CHECK (natureza IN ('devedora','credora')),
    aceita_movimento BOOLEAN NOT NULL DEFAULT TRUE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_chart_of_accounts UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_chart_parent FOREIGN KEY (parent_id) REFERENCES chart_of_accounts(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS accounting_journals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(20) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('geral','vendas','compras','tesouraria','folha','ajuste')),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_accounting_journals UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS journal_entries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    accounting_period_id BIGINT NOT NULL,
    accounting_journal_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    entry_date DATE NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho','publicado','anulado')),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    total_debito NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_credito NUMERIC(18,2) NOT NULL DEFAULT 0,
    criado_por BIGINT,
    publicado_por BIGINT,
    publicado_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_journal_entries UNIQUE (tenant_id, numero),
    CONSTRAINT fk_journal_entries_period FOREIGN KEY (accounting_period_id) REFERENCES accounting_periods(id) ON DELETE RESTRICT,
    CONSTRAINT fk_journal_entries_journal FOREIGN KEY (accounting_journal_id) REFERENCES accounting_journals(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS journal_entry_lines (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    journal_entry_id BIGINT NOT NULL,
    account_id BIGINT NOT NULL,
    descricao VARCHAR(255),
    debit NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (debit >= 0),
    credit NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (credit >= 0),
    reference_type VARCHAR(50),
    reference_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_journal_entry_lines_entry FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON DELETE CASCADE,
    CONSTRAINT fk_journal_entry_lines_account FOREIGN KEY (account_id) REFERENCES chart_of_accounts(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_accounting_periods_tenant ON accounting_periods (tenant_id, ano, mes);
CREATE INDEX IF NOT EXISTS idx_chart_of_accounts_tenant ON chart_of_accounts (tenant_id, codigo);
CREATE INDEX IF NOT EXISTS idx_accounting_journals_tenant ON accounting_journals (tenant_id, codigo);
CREATE INDEX IF NOT EXISTS idx_journal_entries_tenant_date ON journal_entries (tenant_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_journal_entries_status ON journal_entries (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_journal_entry_lines_entry ON journal_entry_lines (journal_entry_id);
CREATE INDEX IF NOT EXISTS idx_journal_entry_lines_account ON journal_entry_lines (account_id);

-- ================================================================
-- SCHEMA: recursos_humanos  (recursos-humanos-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS recursos_humanos;
SET search_path TO recursos_humanos, public;

CREATE TABLE IF NOT EXISTS hr_departments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_hr_departments UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS employees (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    department_id BIGINT,
    user_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150),
    telefone VARCHAR(30),
    nuit VARCHAR(30),
    data_nascimento DATE,
    data_admissao DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (estado IN ('ativo','suspenso','desligado')),
    cargo VARCHAR(120) NOT NULL,
    tipo_contrato VARCHAR(20) NOT NULL DEFAULT 'efectivo' CHECK (tipo_contrato IN ('efectivo','prazo_certo','prestador','estagiario')),
    salario_base NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (salario_base >= 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_employees_tenant_codigo UNIQUE (tenant_id, codigo),
    CONSTRAINT uq_employees_tenant_nuit UNIQUE NULLS NOT DISTINCT (tenant_id, nuit),
    CONSTRAINT fk_employees_department FOREIGN KEY (department_id) REFERENCES hr_departments(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS employee_bank_accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    banco VARCHAR(120) NOT NULL,
    numero_conta VARCHAR(60) NOT NULL,
    nib VARCHAR(60),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    principal BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_bank_accounts_employee FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS payroll_periods (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ano INTEGER NOT NULL,
    mes INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto','fechado')),
    fechado_em TIMESTAMPTZ,
    fechado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payroll_periods UNIQUE (tenant_id, ano, mes)
);

CREATE TABLE IF NOT EXISTS payroll_runs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    payroll_period_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    processamento_em DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'processado' CHECK (status IN ('processado','aprovado','cancelado')),
    total_bruto NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_descontos NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_liquido NUMERIC(18,2) NOT NULL DEFAULT 0,
    criado_por BIGINT,
    aprovado_por BIGINT,
    aprovado_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payroll_runs UNIQUE (tenant_id, numero),
    CONSTRAINT fk_payroll_runs_period FOREIGN KEY (payroll_period_id) REFERENCES payroll_periods(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS payroll_run_lines (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payroll_run_id BIGINT NOT NULL,
    employee_id BIGINT NOT NULL,
    salario_base NUMERIC(18,2) NOT NULL DEFAULT 0,
    adicionais NUMERIC(18,2) NOT NULL DEFAULT 0,
    descontos NUMERIC(18,2) NOT NULL DEFAULT 0,
    bruto NUMERIC(18,2) NOT NULL DEFAULT 0,
    liquido NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payroll_run_employee UNIQUE (payroll_run_id, employee_id),
    CONSTRAINT fk_payroll_run_lines_run FOREIGN KEY (payroll_run_id) REFERENCES payroll_runs(id) ON DELETE CASCADE,
    CONSTRAINT fk_payroll_run_lines_employee FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_hr_departments_tenant ON hr_departments (tenant_id);
CREATE INDEX IF NOT EXISTS idx_employees_tenant ON employees (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_employees_department ON employees (department_id);
CREATE INDEX IF NOT EXISTS idx_payroll_periods_tenant ON payroll_periods (tenant_id, ano, mes);
CREATE INDEX IF NOT EXISTS idx_payroll_runs_tenant ON payroll_runs (tenant_id, processamento_em);
CREATE INDEX IF NOT EXISTS idx_payroll_run_lines_run ON payroll_run_lines (payroll_run_id);

-- ================================================================
-- SCHEMA: multi_moeda  (multi-moeda-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS multi_moeda;
SET search_path TO multi_moeda, public;

CREATE TABLE IF NOT EXISTS currencies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10),
    decimals INTEGER NOT NULL DEFAULT 2 CHECK (decimals BETWEEN 0 AND 6),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_currencies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    currency_id BIGINT NOT NULL,
    is_base BOOLEAN NOT NULL DEFAULT FALSE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenant_currencies UNIQUE (tenant_id, currency_id),
    CONSTRAINT fk_tenant_currencies_currency FOREIGN KEY (currency_id) REFERENCES currencies(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS exchange_rates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    base_currency_id BIGINT NOT NULL,
    quote_currency_id BIGINT NOT NULL,
    rate NUMERIC(18,6) NOT NULL CHECK (rate > 0),
    source VARCHAR(50) NOT NULL DEFAULT 'manual',
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    is_official BOOLEAN NOT NULL DEFAULT FALSE,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_exchange_rates UNIQUE (tenant_id, base_currency_id, quote_currency_id, effective_date, source),
    CONSTRAINT fk_exchange_rates_base FOREIGN KEY (base_currency_id) REFERENCES currencies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_exchange_rates_quote FOREIGN KEY (quote_currency_id) REFERENCES currencies(id) ON DELETE RESTRICT,
    CONSTRAINT chk_exchange_rate_pair CHECK (base_currency_id <> quote_currency_id)
);

INSERT INTO currencies (code, name, symbol, decimals)
VALUES
    ('MZN', 'Metical Mocambicano', 'MT', 2),
    ('USD', 'US Dollar', '$', 2),
    ('ZAR', 'South African Rand', 'R', 2),
    ('EUR', 'Euro', 'EUR', 2)
ON CONFLICT (code) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_tenant_currencies_tenant ON tenant_currencies (tenant_id, is_base);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_tenant_date ON exchange_rates (tenant_id, effective_date DESC);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_pair ON exchange_rates (tenant_id, base_currency_id, quote_currency_id, effective_date DESC);

-- ================================================================
-- SCHEMA: sistema_configuracao  (sistema-configuracao-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS sistema_configuracao;
SET search_path TO sistema_configuracao, public;

CREATE TABLE IF NOT EXISTS tenant_branding (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL UNIQUE,
    logo_url TEXT,
    cor_primaria VARCHAR(20),
    cor_secundaria VARCHAR(20),
    slogan VARCHAR(150),
    website_url TEXT,
    suporte_email VARCHAR(150),
    suporte_telefone VARCHAR(30),
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_defaults (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    chave VARCHAR(100) NOT NULL,
    valor TEXT,
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenant_defaults UNIQUE (tenant_id, chave)
);

CREATE TABLE IF NOT EXISTS tenant_document_settings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    modulo VARCHAR(50) NOT NULL,
    tipo_documento VARCHAR(50) NOT NULL,
    prefixo VARCHAR(20),
    reinicia_anualmente BOOLEAN NOT NULL DEFAULT TRUE,
    serie_activa VARCHAR(20),
    layout_template VARCHAR(100),
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenant_document_settings UNIQUE (tenant_id, modulo, tipo_documento)
);

CREATE TABLE IF NOT EXISTS tenant_feature_flags (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(100) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT FALSE,
    configuracao JSONB,
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenant_feature_flags UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS tenant_integrations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(100) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT FALSE,
    endpoint_url TEXT,
    credenciais JSONB,
    configuracao JSONB,
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_tenant_integrations UNIQUE (tenant_id, codigo)
);

CREATE INDEX IF NOT EXISTS idx_tenant_defaults_tenant ON tenant_defaults (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_document_settings_tenant ON tenant_document_settings (tenant_id, modulo);
CREATE INDEX IF NOT EXISTS idx_tenant_feature_flags_tenant ON tenant_feature_flags (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_integrations_tenant ON tenant_integrations (tenant_id);

-- ================================================================
-- SCHEMA: auditoria  (auditoria-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS auditoria;
SET search_path TO auditoria, public;

CREATE TABLE IF NOT EXISTS audit_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    actor_user_id BIGINT,
    actor_email VARCHAR(150),
    actor_nome VARCHAR(150),
    service_name VARCHAR(100) NOT NULL,
    module_name VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id VARCHAR(100),
    status VARCHAR(20) NOT NULL DEFAULT 'sucesso' CHECK (status IN ('sucesso','falha','alerta')),
    ip_address VARCHAR(64),
    user_agent TEXT,
    metadata JSONB,
    payload_before JSONB,
    payload_after JSONB,
    previous_hash VARCHAR(64),
    event_hash VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_created ON audit_events (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_service ON audit_events (tenant_id, service_name, module_name);
CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_entity ON audit_events (tenant_id, entity_type, entity_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_audit_events_hash ON audit_events (event_hash);

-- ================================================================
-- SCHEMA: centros_custo  (centros-custo-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS centros_custo;
SET search_path TO centros_custo, public;

CREATE TABLE IF NOT EXISTS cost_centers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    parent_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    tipo VARCHAR(20) NOT NULL DEFAULT 'centro' CHECK (tipo IN ('centro','departamento','projecto')),
    gestor_user_id BIGINT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cost_centers UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_cost_centers_parent FOREIGN KEY (parent_id) REFERENCES cost_centers(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS cost_center_allocations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    cost_center_id BIGINT NOT NULL,
    source_service VARCHAR(100) NOT NULL,
    source_type VARCHAR(100) NOT NULL,
    source_id BIGINT NOT NULL,
    source_line_id BIGINT,
    descricao VARCHAR(255),
    valor NUMERIC(18,2) NOT NULL CHECK (valor >= 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    allocation_percent NUMERIC(8,4) NOT NULL DEFAULT 100 CHECK (allocation_percent > 0 AND allocation_percent <= 100),
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cost_center_allocations_center FOREIGN KEY (cost_center_id) REFERENCES cost_centers(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS cost_center_budgets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    cost_center_id BIGINT NOT NULL,
    ano INTEGER NOT NULL,
    mes INTEGER CHECK (mes BETWEEN 1 AND 12),
    valor_orcamentado NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cost_center_budgets UNIQUE (tenant_id, cost_center_id, ano, mes),
    CONSTRAINT fk_cost_center_budgets_center FOREIGN KEY (cost_center_id) REFERENCES cost_centers(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_cost_centers_tenant ON cost_centers (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_cost_center_allocations_tenant ON cost_center_allocations (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cost_center_allocations_source ON cost_center_allocations (tenant_id, source_service, source_type, source_id);
CREATE INDEX IF NOT EXISTS idx_cost_center_budgets_tenant ON cost_center_budgets (tenant_id, ano, mes);

-- ================================================================
-- SCHEMA: crm  (crm-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS crm;
SET search_path TO crm, public;

CREATE TABLE IF NOT EXISTS crm_lead_sources (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_crm_lead_sources UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS crm_pipelines (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_crm_pipelines UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS crm_pipeline_stages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pipeline_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    ordem INTEGER NOT NULL,
    probabilidade NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (probabilidade BETWEEN 0 AND 100),
    ganho BOOLEAN NOT NULL DEFAULT FALSE,
    perdido BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_crm_pipeline_stages UNIQUE (pipeline_id, codigo),
    CONSTRAINT fk_crm_pipeline_stages_pipeline FOREIGN KEY (pipeline_id) REFERENCES crm_pipelines(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS crm_leads (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    lead_source_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    empresa VARCHAR(150),
    email VARCHAR(150),
    telefone VARCHAR(30),
    estado VARCHAR(20) NOT NULL DEFAULT 'novo' CHECK (estado IN ('novo','qualificado','convertido','perdido')),
    interesse VARCHAR(255),
    observacoes TEXT,
    owner_user_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_crm_leads UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_crm_leads_source FOREIGN KEY (lead_source_id) REFERENCES crm_lead_sources(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS crm_opportunities (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    pipeline_id BIGINT NOT NULL,
    stage_id BIGINT NOT NULL,
    lead_id BIGINT,
    customer_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    valor_estimado NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    probabilidade NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (probabilidade BETWEEN 0 AND 100),
    expected_close_date DATE,
    estado VARCHAR(20) NOT NULL DEFAULT 'aberta' CHECK (estado IN ('aberta','ganha','perdida','cancelada')),
    owner_user_id BIGINT,
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_crm_opportunities UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_crm_opportunities_pipeline FOREIGN KEY (pipeline_id) REFERENCES crm_pipelines(id) ON DELETE RESTRICT,
    CONSTRAINT fk_crm_opportunities_stage FOREIGN KEY (stage_id) REFERENCES crm_pipeline_stages(id) ON DELETE RESTRICT,
    CONSTRAINT fk_crm_opportunities_lead FOREIGN KEY (lead_id) REFERENCES crm_leads(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS crm_activities (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    lead_id BIGINT,
    opportunity_id BIGINT,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('chamada','email','reuniao','nota','tarefa','whatsapp')),
    assunto VARCHAR(150) NOT NULL,
    descricao TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','concluida','cancelada')),
    agendado_para TIMESTAMPTZ,
    concluido_em TIMESTAMPTZ,
    owner_user_id BIGINT,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_crm_activities_lead FOREIGN KEY (lead_id) REFERENCES crm_leads(id) ON DELETE CASCADE,
    CONSTRAINT fk_crm_activities_opportunity FOREIGN KEY (opportunity_id) REFERENCES crm_opportunities(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_crm_lead_sources_tenant ON crm_lead_sources (tenant_id);
CREATE INDEX IF NOT EXISTS idx_crm_pipelines_tenant ON crm_pipelines (tenant_id);
CREATE INDEX IF NOT EXISTS idx_crm_pipeline_stages_pipeline ON crm_pipeline_stages (pipeline_id, ordem);
CREATE INDEX IF NOT EXISTS idx_crm_leads_tenant_estado ON crm_leads (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_tenant_estado ON crm_opportunities (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_stage ON crm_opportunities (stage_id);
CREATE INDEX IF NOT EXISTS idx_crm_activities_tenant ON crm_activities (tenant_id, status);

-- ================================================================
-- SCHEMA: pos  (pos-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS pos;
SET search_path TO pos, public;

CREATE TABLE IF NOT EXISTS pos_terminals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    warehouse_id BIGINT,
    caixa_id BIGINT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_pos_terminals UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS pos_sessions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    terminal_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMPTZ,
    opening_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    closing_amount NUMERIC(18,2),
    status VARCHAR(20) NOT NULL DEFAULT 'aberta' CHECK (status IN ('aberta','fechada')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pos_sessions_terminal FOREIGN KEY (terminal_id) REFERENCES pos_terminals(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS pos_catalog_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    codigo_barra VARCHAR(80),
    preco_venda NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_pos_catalog_items UNIQUE NULLS NOT DISTINCT (tenant_id, product_id, product_variant_id)
);

CREATE TABLE IF NOT EXISTS pos_sales (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    pos_session_id BIGINT NOT NULL,
    terminal_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    customer_id BIGINT,
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    desconto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_recebido NUMERIC(18,2) NOT NULL DEFAULT 0,
    troco NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho','concluida','cancelada')),
    sold_at TIMESTAMPTZ,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_pos_sales UNIQUE (tenant_id, numero),
    CONSTRAINT fk_pos_sales_session FOREIGN KEY (pos_session_id) REFERENCES pos_sessions(id) ON DELETE RESTRICT,
    CONSTRAINT fk_pos_sales_terminal FOREIGN KEY (terminal_id) REFERENCES pos_terminals(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS pos_sale_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pos_sale_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    product_variant_id BIGINT,
    descricao VARCHAR(255),
    quantidade NUMERIC(18,2) NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(18,2) NOT NULL CHECK (preco_unitario >= 0),
    desconto_valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    imposto_valor NUMERIC(18,2) NOT NULL DEFAULT 0,
    subtotal NUMERIC(18,2) NOT NULL DEFAULT 0,
    total NUMERIC(18,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pos_sale_items_sale FOREIGN KEY (pos_sale_id) REFERENCES pos_sales(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS pos_sale_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pos_sale_id BIGINT NOT NULL,
    payment_method_id BIGINT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('numerario','transferencia','tpa','mpesa','emola','outro')),
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    referencia VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pos_sale_payments_sale FOREIGN KEY (pos_sale_id) REFERENCES pos_sales(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_pos_terminals_tenant ON pos_terminals (tenant_id);
CREATE INDEX IF NOT EXISTS idx_pos_sessions_tenant ON pos_sessions (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_pos_catalog_items_tenant ON pos_catalog_items (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_pos_sales_tenant ON pos_sales (tenant_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pos_sale_items_sale ON pos_sale_items (pos_sale_id);
CREATE INDEX IF NOT EXISTS idx_pos_sale_payments_sale ON pos_sale_payments (pos_sale_id);

-- ================================================================
-- SCHEMA: seguranca  (seguranca-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS seguranca;
SET search_path TO seguranca, public;

CREATE TABLE IF NOT EXISTS security_policies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    configuracao JSONB NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_security_policies UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS security_ip_allowlist (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    descricao VARCHAR(150),
    ip_or_cidr VARCHAR(80) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_security_ip_allowlist UNIQUE (tenant_id, ip_or_cidr)
);

CREATE TABLE IF NOT EXISTS security_mfa_enrollments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    metodo VARCHAR(20) NOT NULL DEFAULT 'totp' CHECK (metodo IN ('totp','sms','email')),
    secret VARCHAR(255) NOT NULL,
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    last_verified_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_security_mfa_user_method UNIQUE (tenant_id, user_id, metodo)
);

CREATE INDEX IF NOT EXISTS idx_security_policies_tenant ON security_policies (tenant_id);
CREATE INDEX IF NOT EXISTS idx_security_ip_allowlist_tenant ON security_ip_allowlist (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_security_mfa_enrollments_tenant ON security_mfa_enrollments (tenant_id, user_id);

-- ================================================================
-- SCHEMA: assinaturas  (assinaturas-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS assinaturas;
SET search_path TO assinaturas, public;

CREATE TABLE IF NOT EXISTS subscription_plans (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    billing_period VARCHAR(20) NOT NULL DEFAULT 'mensal' CHECK (billing_period IN ('mensal','trimestral','anual')),
    preco NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    limites JSONB,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_subscription_plans UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS subscriptions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    company_id BIGINT,
    plan_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    starts_at DATE NOT NULL,
    ends_at DATE,
    next_billing_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','activa','suspensa','cancelada','expirada')),
    unit_price NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_subscriptions UNIQUE (tenant_id, numero),
    CONSTRAINT fk_subscriptions_plan FOREIGN KEY (plan_id) REFERENCES subscription_plans(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS subscription_invoices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    subscription_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    due_date DATE NOT NULL,
    valor_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_pago NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    status VARCHAR(20) NOT NULL DEFAULT 'emitida' CHECK (status IN ('emitida','paga','cancelada','vencida')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_subscription_invoices UNIQUE (tenant_id, numero),
    CONSTRAINT fk_subscription_invoices_subscription FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS subscription_usage (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    subscription_id BIGINT NOT NULL,
    recurso VARCHAR(100) NOT NULL,
    quantidade NUMERIC(18,2) NOT NULL DEFAULT 0,
    periodo DATE NOT NULL DEFAULT CURRENT_DATE,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_subscription_usage_subscription FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_subscription_plans_tenant ON subscription_plans (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant_status ON subscriptions (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_subscription_invoices_tenant_status ON subscription_invoices (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_subscription_usage_tenant_periodo ON subscription_usage (tenant_id, periodo);

-- ================================================================
-- SCHEMA: logistica  (logistica-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS logistica;
SET search_path TO logistica, public;

CREATE TABLE IF NOT EXISTS logistics_vehicles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    matricula VARCHAR(30) NOT NULL,
    descricao VARCHAR(150),
    capacidade_kg NUMERIC(18,2),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_logistics_vehicles_codigo UNIQUE (tenant_id, codigo),
    CONSTRAINT uq_logistics_vehicles_matricula UNIQUE (tenant_id, matricula)
);

CREATE TABLE IF NOT EXISTS logistics_drivers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    telefone VARCHAR(30),
    carta_numero VARCHAR(50),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_logistics_drivers UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS logistics_routes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    origem VARCHAR(150) NOT NULL,
    destino VARCHAR(150) NOT NULL,
    distancia_km NUMERIC(18,2),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_logistics_routes UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS logistics_shipments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    source_service VARCHAR(100) NOT NULL,
    source_type VARCHAR(100) NOT NULL,
    source_id BIGINT NOT NULL,
    logistics_route_id BIGINT,
    vehicle_id BIGINT,
    driver_id BIGINT,
    customer_id BIGINT,
    delivery_address TEXT,
    scheduled_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'planeada' CHECK (status IN ('planeada','despachada','em_transito','entregue','cancelada')),
    observacoes TEXT,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_logistics_shipments UNIQUE (tenant_id, numero),
    CONSTRAINT fk_logistics_shipments_route FOREIGN KEY (logistics_route_id) REFERENCES logistics_routes(id) ON DELETE SET NULL,
    CONSTRAINT fk_logistics_shipments_vehicle FOREIGN KEY (vehicle_id) REFERENCES logistics_vehicles(id) ON DELETE SET NULL,
    CONSTRAINT fk_logistics_shipments_driver FOREIGN KEY (driver_id) REFERENCES logistics_drivers(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS logistics_tracking_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    shipment_id BIGINT NOT NULL,
    evento VARCHAR(30) NOT NULL CHECK (evento IN ('planeado','despachado','em_transito','entregue','falha_entrega','cancelado')),
    localizacao VARCHAR(255),
    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),
    observacoes TEXT,
    event_time TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_logistics_tracking_events_shipment FOREIGN KEY (shipment_id) REFERENCES logistics_shipments(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_logistics_vehicles_tenant ON logistics_vehicles (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_logistics_drivers_tenant ON logistics_drivers (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_logistics_routes_tenant ON logistics_routes (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_logistics_shipments_tenant_status ON logistics_shipments (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_logistics_tracking_events_tenant ON logistics_tracking_events (tenant_id, event_time DESC);

-- ================================================================
-- SCHEMA: gestao_escolar  (gestao-escolar-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS gestao_escolar;
SET search_path TO gestao_escolar, public;

CREATE TABLE IF NOT EXISTS school_classes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    nivel VARCHAR(50),
    ano_lectivo VARCHAR(20) NOT NULL,
    turma VARCHAR(20),
    capacidade INTEGER,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_school_classes UNIQUE (tenant_id, codigo, ano_lectivo)
);

CREATE TABLE IF NOT EXISTS school_students (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    data_nascimento DATE,
    genero VARCHAR(20),
    encarregado_nome VARCHAR(150),
    encarregado_telefone VARCHAR(30),
    encarregado_email VARCHAR(150),
    estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','inactivo','transferido','graduado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_school_students UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS school_enrollments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    class_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    data_matricula DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'activa' CHECK (status IN ('activa','cancelada','concluida')),
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_school_enrollments UNIQUE (tenant_id, numero),
    CONSTRAINT uq_school_student_class UNIQUE (student_id, class_id),
    CONSTRAINT fk_school_enrollments_student FOREIGN KEY (student_id) REFERENCES school_students(id) ON DELETE CASCADE,
    CONSTRAINT fk_school_enrollments_class FOREIGN KEY (class_id) REFERENCES school_classes(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS school_fees (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    enrollment_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    descricao VARCHAR(150) NOT NULL,
    mes_referencia VARCHAR(20),
    data_vencimento DATE NOT NULL,
    valor_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_pago NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','parcial','paga','cancelada')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_school_fees UNIQUE (tenant_id, numero),
    CONSTRAINT fk_school_fees_enrollment FOREIGN KEY (enrollment_id) REFERENCES school_enrollments(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS school_attendance (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    class_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    attendance_date DATE NOT NULL,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('presente','ausente','justificado','atrasado')),
    observacoes TEXT,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_school_attendance UNIQUE (class_id, student_id, attendance_date),
    CONSTRAINT fk_school_attendance_class FOREIGN KEY (class_id) REFERENCES school_classes(id) ON DELETE CASCADE,
    CONSTRAINT fk_school_attendance_student FOREIGN KEY (student_id) REFERENCES school_students(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_school_classes_tenant ON school_classes (tenant_id, ano_lectivo);
CREATE INDEX IF NOT EXISTS idx_school_students_tenant ON school_students (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_school_enrollments_tenant ON school_enrollments (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_school_fees_tenant ON school_fees (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_school_attendance_tenant ON school_attendance (tenant_id, attendance_date);

-- ================================================================
-- SCHEMA: notifications  (notifications-service)
-- ================================================================
CREATE SCHEMA IF NOT EXISTS notifications;
SET search_path TO notifications, public;

CREATE TABLE IF NOT EXISTS notification_channels (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('email','sms','whatsapp','push')),
    configuracao JSONB,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_notification_channels UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS notification_templates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    canal_tipo VARCHAR(20) NOT NULL CHECK (canal_tipo IN ('email','sms','whatsapp','push')),
    assunto VARCHAR(150),
    corpo TEXT NOT NULL,
    variaveis JSONB,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    updated_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_notification_templates UNIQUE (tenant_id, codigo, canal_tipo)
);

CREATE TABLE IF NOT EXISTS notification_messages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    channel_id BIGINT,
    template_id BIGINT,
    canal_tipo VARCHAR(20) NOT NULL CHECK (canal_tipo IN ('email','sms','whatsapp','push')),
    destinatario VARCHAR(180) NOT NULL,
    assunto VARCHAR(150),
    corpo TEXT NOT NULL,
    payload JSONB,
    referencia_tipo VARCHAR(50),
    referencia_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','enviado','falha','cancelado')),
    tentativas INTEGER NOT NULL DEFAULT 0,
    erro TEXT,
    enviado_em TIMESTAMPTZ,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notification_messages_channel FOREIGN KEY (channel_id) REFERENCES notification_channels(id) ON DELETE SET NULL,
    CONSTRAINT fk_notification_messages_template FOREIGN KEY (template_id) REFERENCES notification_templates(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_notification_channels_tenant ON notification_channels (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_notification_templates_tenant ON notification_templates (tenant_id, activo);
CREATE INDEX IF NOT EXISTS idx_notification_messages_tenant_status ON notification_messages (tenant_id, status, created_at DESC);
