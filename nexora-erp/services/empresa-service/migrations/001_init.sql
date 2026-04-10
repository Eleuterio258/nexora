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
