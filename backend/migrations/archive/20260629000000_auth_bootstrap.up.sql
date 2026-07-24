-- Base de identidade: schema auth e tabela users.
-- Esta migracao e o ponto de partida para todas as restantes, que assumem
-- a existencia de auth.users. As constraints especificas (email unico,
-- pessoa_id, triggers) sao adicionadas por migracoes posteriores.

CREATE SCHEMA IF NOT EXISTS auth;
SET search_path TO auth, public;

CREATE TABLE IF NOT EXISTS auth.users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL,
    password_hash TEXT NOT NULL,
    telefone VARCHAR(30),
    estado VARCHAR(20) DEFAULT 'ativo'::character varying NOT NULL,
    email_verificado BOOLEAN DEFAULT false NOT NULL,
    ultimo_login_em TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tipo VARCHAR(20) DEFAULT 'funcionario'::character varying NOT NULL,
    permissoes_atualizadas_em TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT users_estado_check CHECK (
        (estado)::text = ANY (
            ARRAY[
                ('ativo'::character varying)::text,
                ('bloqueado'::character varying)::text,
                ('pendente'::character varying)::text,
                ('inativo'::character varying)::text
            ]
        )
    ),
    CONSTRAINT users_tipo_check CHECK (
        (tipo)::text = ANY (
            ARRAY[
                ('superadmin'::character varying)::text,
                ('funcionario'::character varying)::text,
                ('aluno'::character varying)::text,
                ('encarregado'::character varying)::text,
                ('candidato'::character varying)::text
            ]
        )
    )
);

-- Schema e tabelas base de impostos (necessarias antes da migracao 31)
CREATE SCHEMA IF NOT EXISTS impostos;
SET search_path TO impostos, public;
CREATE TABLE impostos.tax_exemptions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    tax_id bigint NOT NULL,
    entity_type character varying(30) NOT NULL,
    entity_id bigint NOT NULL,
    motivo character varying(255),
    numero_isencao character varying(60),
    validade date,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tax_exemptions_entity_type_check CHECK (((entity_type)::text = ANY (ARRAY[('customer'::character varying)::text, ('supplier'::character varying)::text, ('product'::character varying)::text, ('product_category'::character varying)::text])))
);
ALTER TABLE impostos.tax_exemptions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_exemptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE impostos.tax_groups (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(20) NOT NULL,
    nome character varying(100) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE impostos.tax_groups ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE impostos.tax_regimes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    tipo character varying(20) DEFAULT 'normal'::character varying NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    data_inicio date,
    data_fim date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tax_regimes_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('simplificado'::character varying)::text, ('normal'::character varying)::text, ('isento'::character varying)::text])))
);
ALTER TABLE impostos.tax_regimes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_regimes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE impostos.tax_returns (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    periodo character varying(20) NOT NULL,
    tipo character varying(30) NOT NULL,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    total_base numeric(18,2) DEFAULT 0 NOT NULL,
    total_imposto numeric(18,2) DEFAULT 0 NOT NULL,
    total_credito numeric(18,2) DEFAULT 0 NOT NULL,
    total_a_pagar numeric(18,2) DEFAULT 0 NOT NULL,
    data_submissao timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    periodo_inicio date,
    periodo_fim date,
    substitui_id bigint,
    submetida_por bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    total_a_recuperar numeric(18,2) DEFAULT 0 NOT NULL,
    CONSTRAINT tax_returns_status_check CHECK (((status)::text = ANY (ARRAY[('rascunho'::character varying)::text, ('submetida'::character varying)::text, ('paga'::character varying)::text, ('cancelada'::character varying)::text]))),
    CONSTRAINT tax_returns_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('iva'::character varying)::text, ('irps'::character varying)::text, ('irpc'::character varying)::text, ('retencoes'::character varying)::text])))
);
ALTER TABLE impostos.tax_returns ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_returns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE impostos.taxes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    taxa numeric(8,4) DEFAULT 0 NOT NULL,
    tipo character varying(20) DEFAULT 'iva'::character varying NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tax_group_id bigint,
    CONSTRAINT taxes_taxa_check CHECK ((taxa >= (0)::numeric)),
    CONSTRAINT taxes_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('iva'::character varying)::text, ('isento'::character varying)::text, ('zero'::character varying)::text, ('outro'::character varying)::text])))
);
ALTER TABLE impostos.taxes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.taxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE impostos.withholding_tax_transactions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    withholding_tax_id bigint NOT NULL,
    referencia_tipo character varying(50),
    referencia_id bigint,
    base_imponivel numeric(18,2) NOT NULL,
    taxa_aplicada numeric(8,4) NOT NULL,
    valor_retido numeric(18,2) NOT NULL,
    transaction_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entity_type character varying(30),
    entity_id bigint,
    documento_numero character varying(80),
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);
ALTER TABLE impostos.withholding_tax_transactions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.withholding_tax_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
CREATE TABLE impostos.withholding_taxes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    taxa numeric(8,4) NOT NULL,
    aplica_em character varying(30) NOT NULL,
    tipo_entidade character varying(30),
    ativo boolean DEFAULT true NOT NULL,
    tipo character varying(10) DEFAULT 'IRPS'::character varying NOT NULL,
    descricao text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT withholding_taxes_aplica_em_check CHECK (((aplica_em)::text = ANY (ARRAY[('pagamento'::character varying)::text, ('fatura'::character varying)::text]))),
    CONSTRAINT withholding_taxes_taxa_check CHECK ((taxa >= (0)::numeric)),
    CONSTRAINT withholding_taxes_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('IRPS'::character varying)::text, ('IRPC'::character varying)::text]))),
    CONSTRAINT withholding_taxes_tipo_entidade_check CHECK (((tipo_entidade)::text = ANY (ARRAY[('pessoa_singular'::character varying)::text, ('pessoa_colectiva'::character varying)::text, ('todos'::character varying)::text])))
);
ALTER TABLE impostos.withholding_taxes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.withholding_taxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
ALTER TABLE ONLY impostos.tax_exemptions
    ADD CONSTRAINT tax_exemptions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.tax_groups
    ADD CONSTRAINT tax_groups_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.tax_regimes
    ADD CONSTRAINT tax_regimes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.tax_returns
    ADD CONSTRAINT tax_returns_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.taxes
    ADD CONSTRAINT taxes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.tax_groups
    ADD CONSTRAINT uq_tax_groups UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY impostos.tax_regimes
    ADD CONSTRAINT uq_tax_regimes UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY impostos.taxes
    ADD CONSTRAINT uq_taxes UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY impostos.withholding_taxes
    ADD CONSTRAINT uq_withholding_taxes UNIQUE (tenant_id, codigo);
ALTER TABLE ONLY impostos.withholding_tax_transactions
    ADD CONSTRAINT withholding_tax_transactions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY impostos.withholding_taxes
    ADD CONSTRAINT withholding_taxes_pkey PRIMARY KEY (id);
CREATE INDEX idx_tax_exemptions_active ON impostos.tax_exemptions USING btree (tenant_id, entity_type, entity_id, data_inicio, validade) WHERE ativo;
CREATE INDEX idx_tax_exemptions_entity ON impostos.tax_exemptions USING btree (entity_type, entity_id);
CREATE INDEX idx_tax_exemptions_tenant ON impostos.tax_exemptions USING btree (tenant_id);
CREATE INDEX idx_tax_regimes_tenant ON impostos.tax_regimes USING btree (tenant_id);
CREATE INDEX idx_tax_returns_tenant ON impostos.tax_returns USING btree (tenant_id);
CREATE INDEX idx_taxes_tax_group ON impostos.taxes USING btree (tenant_id, tax_group_id);
CREATE INDEX idx_taxes_tenant ON impostos.taxes USING btree (tenant_id);
CREATE INDEX idx_wtt_tenant ON impostos.withholding_tax_transactions USING btree (tenant_id);
CREATE UNIQUE INDEX uq_tax_regime_principal ON impostos.tax_regimes USING btree (tenant_id) WHERE (principal AND ativo);
CREATE UNIQUE INDEX uq_tax_returns_original ON impostos.tax_returns USING btree (tenant_id, periodo, tipo) WHERE (substitui_id IS NULL);
CREATE UNIQUE INDEX uq_tax_returns_substituicao ON impostos.tax_returns USING btree (substitui_id) WHERE (substitui_id IS NOT NULL);
ALTER TABLE ONLY impostos.tax_exemptions
    ADD CONSTRAINT fk_tax_exemptions_tax FOREIGN KEY (tax_id) REFERENCES impostos.taxes(id) ON DELETE CASCADE;
ALTER TABLE ONLY impostos.tax_returns
    ADD CONSTRAINT fk_tax_returns_substitui FOREIGN KEY (substitui_id) REFERENCES impostos.tax_returns(id) ON DELETE RESTRICT;
ALTER TABLE ONLY impostos.withholding_tax_transactions
    ADD CONSTRAINT fk_wtt_wt FOREIGN KEY (withholding_tax_id) REFERENCES impostos.withholding_taxes(id);
ALTER TABLE ONLY impostos.taxes
    ADD CONSTRAINT taxes_tax_group_id_fkey FOREIGN KEY (tax_group_id) REFERENCES impostos.tax_groups(id);

-- Schema e tabelas base de contabilidade
CREATE SCHEMA IF NOT EXISTS contabilidade;
SET search_path TO contabilidade, public;

CREATE TABLE IF NOT EXISTS account_types (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(20) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    classe VARCHAR(20) NOT NULL
        CHECK (classe IN ('ativo','passivo','capital','rendimento','gasto')),
    natureza VARCHAR(20) NOT NULL
        CHECK (natureza IN ('devedora','credora')),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_account_types UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS chart_of_accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(200) NOT NULL,
    descricao TEXT,
    parent_id BIGINT,
    account_type_id BIGINT,
    aceita_lancamento BOOLEAN DEFAULT TRUE NOT NULL,
    ativo BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_chart_of_accounts UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_chart_parent FOREIGN KEY (parent_id) REFERENCES chart_of_accounts(id) ON DELETE SET NULL,
    CONSTRAINT chart_of_accounts_account_type_id_fkey FOREIGN KEY (account_type_id) REFERENCES account_types(id)
);

CREATE INDEX IF NOT EXISTS idx_chart_of_accounts_tenant ON chart_of_accounts (tenant_id, codigo);
CREATE INDEX IF NOT EXISTS idx_chart_of_accounts_account_type ON chart_of_accounts (tenant_id, account_type_id);
