--
-- PostgreSQL database dump
--

\restrict hjMhFvQiHZdzESHm8u473PagtNNuamKdBjPjeHlG7zgVtCBlXQ9pYSihbL4MEZo

-- Dumped from database version 15.15 (Debian 15.15-1.pgdg13+1)
-- Dumped by pg_dump version 18.1 (Debian 18.1-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY empresa.company_users DROP CONSTRAINT IF EXISTS fk_company_users_company;
ALTER TABLE IF EXISTS ONLY empresa.company_users DROP CONSTRAINT IF EXISTS fk_company_users_branch;
ALTER TABLE IF EXISTS ONLY empresa.company_tax_info DROP CONSTRAINT IF EXISTS fk_company_tax_info_company;
ALTER TABLE IF EXISTS ONLY empresa.company_settings DROP CONSTRAINT IF EXISTS fk_company_settings_company;
ALTER TABLE IF EXISTS ONLY empresa.company_licenses DROP CONSTRAINT IF EXISTS fk_company_licenses_company;
ALTER TABLE IF EXISTS ONLY empresa.company_documents DROP CONSTRAINT IF EXISTS fk_company_documents_company;
ALTER TABLE IF EXISTS ONLY empresa.company_contacts DROP CONSTRAINT IF EXISTS fk_company_contacts_company;
ALTER TABLE IF EXISTS ONLY empresa.company_contacts DROP CONSTRAINT IF EXISTS fk_company_contacts_branch;
ALTER TABLE IF EXISTS ONLY empresa.company_branches DROP CONSTRAINT IF EXISTS fk_company_branches_company;
ALTER TABLE IF EXISTS ONLY empresa.company_banks DROP CONSTRAINT IF EXISTS fk_company_banks_company;
ALTER TABLE IF EXISTS ONLY empresa.company_addresses DROP CONSTRAINT IF EXISTS fk_company_addresses_company;
ALTER TABLE IF EXISTS ONLY empresa.company_addresses DROP CONSTRAINT IF EXISTS fk_company_addresses_branch;
DROP INDEX IF EXISTS empresa.idx_company_users_user_id;
DROP INDEX IF EXISTS empresa.idx_company_users_company_id;
DROP INDEX IF EXISTS empresa.idx_company_settings_company_id;
DROP INDEX IF EXISTS empresa.idx_company_licenses_company_id;
DROP INDEX IF EXISTS empresa.idx_company_documents_company_id;
DROP INDEX IF EXISTS empresa.idx_company_contacts_company_id;
DROP INDEX IF EXISTS empresa.idx_company_branches_company_id;
DROP INDEX IF EXISTS empresa.idx_company_banks_company_id;
DROP INDEX IF EXISTS empresa.idx_company_addresses_company_id;
ALTER TABLE IF EXISTS ONLY empresa.company_users DROP CONSTRAINT IF EXISTS uq_company_users;
ALTER TABLE IF EXISTS ONLY empresa.company_tax_info DROP CONSTRAINT IF EXISTS uq_company_tax_info_nuit;
ALTER TABLE IF EXISTS ONLY empresa.company_tax_info DROP CONSTRAINT IF EXISTS uq_company_tax_info_company;
ALTER TABLE IF EXISTS ONLY empresa.company_settings DROP CONSTRAINT IF EXISTS uq_company_settings;
ALTER TABLE IF EXISTS ONLY empresa.company_branches DROP CONSTRAINT IF EXISTS uq_company_branches;
ALTER TABLE IF EXISTS ONLY empresa.companies DROP CONSTRAINT IF EXISTS uq_companies_codigo;
ALTER TABLE IF EXISTS ONLY empresa.company_users DROP CONSTRAINT IF EXISTS company_users_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_tax_info DROP CONSTRAINT IF EXISTS company_tax_info_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_settings DROP CONSTRAINT IF EXISTS company_settings_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_licenses DROP CONSTRAINT IF EXISTS company_licenses_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_documents DROP CONSTRAINT IF EXISTS company_documents_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_contacts DROP CONSTRAINT IF EXISTS company_contacts_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_branches DROP CONSTRAINT IF EXISTS company_branches_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_banks DROP CONSTRAINT IF EXISTS company_banks_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_addresses DROP CONSTRAINT IF EXISTS company_addresses_pkey;
ALTER TABLE IF EXISTS ONLY empresa.companies DROP CONSTRAINT IF EXISTS companies_pkey;
DROP TABLE IF EXISTS empresa.company_users;
DROP TABLE IF EXISTS empresa.company_tax_info;
DROP TABLE IF EXISTS empresa.company_settings;
DROP TABLE IF EXISTS empresa.company_licenses;
DROP TABLE IF EXISTS empresa.company_documents;
DROP TABLE IF EXISTS empresa.company_contacts;
DROP TABLE IF EXISTS empresa.company_branches;
DROP TABLE IF EXISTS empresa.company_banks;
DROP TABLE IF EXISTS empresa.company_addresses;
DROP TABLE IF EXISTS empresa.companies;
DROP SCHEMA IF EXISTS empresa;
--
-- Name: empresa; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA empresa;


ALTER SCHEMA empresa OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: companies; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.companies (
    id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    nome_comercial character varying(150),
    tipo character varying(30) DEFAULT 'empresa'::character varying NOT NULL,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    moeda_base character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    timezone character varying(60) DEFAULT 'Africa/Maputo'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT companies_status_check CHECK (((status)::text = ANY ((ARRAY['ativa'::character varying, 'suspensa'::character varying, 'inativa'::character varying])::text[]))),
    CONSTRAINT companies_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['empresa'::character varying, 'organizacao'::character varying, 'holding'::character varying, 'filial_independente'::character varying])::text[])))
);


ALTER TABLE empresa.companies OWNER TO postgres;

--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

ALTER TABLE empresa.companies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_addresses; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.company_addresses (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    branch_id bigint,
    tipo character varying(30) DEFAULT 'principal'::character varying NOT NULL,
    endereco character varying(255) NOT NULL,
    cidade character varying(100),
    provincia character varying(100),
    pais character varying(100) DEFAULT 'Mocambique'::character varying NOT NULL,
    codigo_postal character varying(30),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_addresses_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['principal'::character varying, 'fiscal'::character varying, 'entrega'::character varying, 'filial'::character varying, 'cobranca'::character varying])::text[])))
);


ALTER TABLE empresa.company_addresses OWNER TO postgres;

--
-- Name: company_addresses_id_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

ALTER TABLE empresa.company_addresses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_banks; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.company_banks (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    banco character varying(120) NOT NULL,
    numero_conta character varying(60) NOT NULL,
    nib character varying(60),
    iban character varying(60),
    swift character varying(30),
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE empresa.company_banks OWNER TO postgres;

--
-- Name: company_banks_id_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

ALTER TABLE empresa.company_banks ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_banks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_branches; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.company_branches (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_branches_status_check CHECK (((status)::text = ANY ((ARRAY['ativa'::character varying, 'inativa'::character varying])::text[])))
);


ALTER TABLE empresa.company_branches OWNER TO postgres;

--
-- Name: company_branches_id_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

ALTER TABLE empresa.company_branches ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_branches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_contacts; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.company_contacts (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    branch_id bigint,
    tipo character varying(30) DEFAULT 'geral'::character varying NOT NULL,
    nome character varying(150),
    telefone character varying(30),
    email character varying(150),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_contacts_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['geral'::character varying, 'financeiro'::character varying, 'comercial'::character varying, 'suporte'::character varying, 'rh'::character varying])::text[])))
);


ALTER TABLE empresa.company_contacts OWNER TO postgres;

--
-- Name: company_contacts_id_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

ALTER TABLE empresa.company_contacts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_documents; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.company_documents (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    numero character varying(100),
    ficheiro_url text,
    emitido_em date,
    expira_em date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_documents_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['alvara'::character varying, 'certidao'::character varying, 'contrato_social'::character varying, 'licenca'::character varying, 'outro'::character varying])::text[])))
);


ALTER TABLE empresa.company_documents OWNER TO postgres;

--
-- Name: company_documents_id_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

ALTER TABLE empresa.company_documents ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_licenses; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.company_licenses (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    plano character varying(50) NOT NULL,
    licenca_chave character varying(120),
    limite_usuarios integer,
    limite_filiais integer,
    inicia_em date NOT NULL,
    expira_em date,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_licenses_status_check CHECK (((status)::text = ANY ((ARRAY['ativa'::character varying, 'expirada'::character varying, 'suspensa'::character varying])::text[])))
);


ALTER TABLE empresa.company_licenses OWNER TO postgres;

--
-- Name: company_licenses_id_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

ALTER TABLE empresa.company_licenses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_licenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_settings; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.company_settings (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    chave character varying(100) NOT NULL,
    valor text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE empresa.company_settings OWNER TO postgres;

--
-- Name: company_settings_id_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

ALTER TABLE empresa.company_settings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_tax_info; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.company_tax_info (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    nuit character varying(30) NOT NULL,
    regime_iva character varying(50),
    taxa_iva_padrao numeric(5,2) DEFAULT 17.00 NOT NULL,
    inicio_atividade date,
    reparticao_fiscal character varying(150),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_tax_info_taxa_iva_padrao_check CHECK ((taxa_iva_padrao >= (0)::numeric))
);


ALTER TABLE empresa.company_tax_info OWNER TO postgres;

--
-- Name: company_tax_info_id_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

ALTER TABLE empresa.company_tax_info ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_tax_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_users; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.company_users (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    user_id bigint NOT NULL,
    branch_id bigint,
    perfil_empresa character varying(50),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE empresa.company_users OWNER TO postgres;

--
-- Name: company_users_id_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

ALTER TABLE empresa.company_users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: companies; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.companies (id, codigo, nome, nome_comercial, tipo, status, moeda_base, timezone, created_at, updated_at) FROM stdin;
1	DEMO	Nexora Demo, Lda	Nexora Demo	empresa	ativa	MZN	Africa/Maputo	2026-03-17 16:33:58.713908+00	2026-03-17 16:40:19.441056+00
\.


--
-- Data for Name: company_addresses; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.company_addresses (id, company_id, branch_id, tipo, endereco, cidade, provincia, pais, codigo_postal, created_at) FROM stdin;
\.


--
-- Data for Name: company_banks; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.company_banks (id, company_id, banco, numero_conta, nib, iban, swift, moeda, principal, created_at) FROM stdin;
\.


--
-- Data for Name: company_branches; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.company_branches (id, company_id, codigo, nome, status, principal, created_at, updated_at) FROM stdin;
1	1	MATRIZ	Sede Maputo	ativa	t	2026-03-17 16:33:58.7282+00	2026-03-17 16:40:19.448791+00
\.


--
-- Data for Name: company_contacts; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.company_contacts (id, company_id, branch_id, tipo, nome, telefone, email, principal, created_at) FROM stdin;
\.


--
-- Data for Name: company_documents; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.company_documents (id, company_id, tipo, numero, ficheiro_url, emitido_em, expira_em, created_at) FROM stdin;
\.


--
-- Data for Name: company_licenses; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.company_licenses (id, company_id, plano, licenca_chave, limite_usuarios, limite_filiais, inicia_em, expira_em, status, created_at) FROM stdin;
\.


--
-- Data for Name: company_settings; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.company_settings (id, company_id, chave, valor, created_at, updated_at) FROM stdin;
1	1	default_currency	MZN	2026-03-17 16:33:58.760037+00	2026-03-17 16:40:19.453223+00
2	1	country	Mocambique	2026-03-17 16:33:58.760037+00	2026-03-17 16:40:19.453223+00
3	1	timezone	Africa/Maputo	2026-03-17 16:33:58.760037+00	2026-03-17 16:40:19.453223+00
4	1	language	pt-MZ	2026-03-17 16:33:58.760037+00	2026-03-17 16:40:19.453223+00
\.


--
-- Data for Name: company_tax_info; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.company_tax_info (id, company_id, nuit, regime_iva, taxa_iva_padrao, inicio_atividade, reparticao_fiscal, created_at, updated_at) FROM stdin;
1	1	400000001	regime_geral	16.00	2026-03-17	Maputo Cidade	2026-03-17 16:33:58.718891+00	2026-03-17 16:40:19.444924+00
\.


--
-- Data for Name: company_users; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.company_users (id, company_id, user_id, branch_id, perfil_empresa, ativo, created_at) FROM stdin;
1	1	1	1	admin	t	2026-03-17 16:33:58.773755+00
\.


--
-- Name: companies_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.companies_id_seq', 3, true);


--
-- Name: company_addresses_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.company_addresses_id_seq', 1, false);


--
-- Name: company_banks_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.company_banks_id_seq', 1, false);


--
-- Name: company_branches_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.company_branches_id_seq', 3, true);


--
-- Name: company_contacts_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.company_contacts_id_seq', 1, false);


--
-- Name: company_documents_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.company_documents_id_seq', 1, false);


--
-- Name: company_licenses_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.company_licenses_id_seq', 1, false);


--
-- Name: company_settings_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.company_settings_id_seq', 12, true);


--
-- Name: company_tax_info_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.company_tax_info_id_seq', 3, true);


--
-- Name: company_users_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.company_users_id_seq', 3, true);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: company_addresses company_addresses_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_addresses
    ADD CONSTRAINT company_addresses_pkey PRIMARY KEY (id);


--
-- Name: company_banks company_banks_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_banks
    ADD CONSTRAINT company_banks_pkey PRIMARY KEY (id);


--
-- Name: company_branches company_branches_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_branches
    ADD CONSTRAINT company_branches_pkey PRIMARY KEY (id);


--
-- Name: company_contacts company_contacts_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_contacts
    ADD CONSTRAINT company_contacts_pkey PRIMARY KEY (id);


--
-- Name: company_documents company_documents_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_documents
    ADD CONSTRAINT company_documents_pkey PRIMARY KEY (id);


--
-- Name: company_licenses company_licenses_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_licenses
    ADD CONSTRAINT company_licenses_pkey PRIMARY KEY (id);


--
-- Name: company_settings company_settings_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_settings
    ADD CONSTRAINT company_settings_pkey PRIMARY KEY (id);


--
-- Name: company_tax_info company_tax_info_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_tax_info
    ADD CONSTRAINT company_tax_info_pkey PRIMARY KEY (id);


--
-- Name: company_users company_users_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_users
    ADD CONSTRAINT company_users_pkey PRIMARY KEY (id);


--
-- Name: companies uq_companies_codigo; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.companies
    ADD CONSTRAINT uq_companies_codigo UNIQUE (codigo);


--
-- Name: company_branches uq_company_branches; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_branches
    ADD CONSTRAINT uq_company_branches UNIQUE (company_id, codigo);


--
-- Name: company_settings uq_company_settings; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_settings
    ADD CONSTRAINT uq_company_settings UNIQUE (company_id, chave);


--
-- Name: company_tax_info uq_company_tax_info_company; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_tax_info
    ADD CONSTRAINT uq_company_tax_info_company UNIQUE (company_id);


--
-- Name: company_tax_info uq_company_tax_info_nuit; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_tax_info
    ADD CONSTRAINT uq_company_tax_info_nuit UNIQUE (nuit);


--
-- Name: company_users uq_company_users; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_users
    ADD CONSTRAINT uq_company_users UNIQUE (company_id, user_id);


--
-- Name: idx_company_addresses_company_id; Type: INDEX; Schema: empresa; Owner: postgres
--

CREATE INDEX idx_company_addresses_company_id ON empresa.company_addresses USING btree (company_id);


--
-- Name: idx_company_banks_company_id; Type: INDEX; Schema: empresa; Owner: postgres
--

CREATE INDEX idx_company_banks_company_id ON empresa.company_banks USING btree (company_id);


--
-- Name: idx_company_branches_company_id; Type: INDEX; Schema: empresa; Owner: postgres
--

CREATE INDEX idx_company_branches_company_id ON empresa.company_branches USING btree (company_id);


--
-- Name: idx_company_contacts_company_id; Type: INDEX; Schema: empresa; Owner: postgres
--

CREATE INDEX idx_company_contacts_company_id ON empresa.company_contacts USING btree (company_id);


--
-- Name: idx_company_documents_company_id; Type: INDEX; Schema: empresa; Owner: postgres
--

CREATE INDEX idx_company_documents_company_id ON empresa.company_documents USING btree (company_id);


--
-- Name: idx_company_licenses_company_id; Type: INDEX; Schema: empresa; Owner: postgres
--

CREATE INDEX idx_company_licenses_company_id ON empresa.company_licenses USING btree (company_id);


--
-- Name: idx_company_settings_company_id; Type: INDEX; Schema: empresa; Owner: postgres
--

CREATE INDEX idx_company_settings_company_id ON empresa.company_settings USING btree (company_id);


--
-- Name: idx_company_users_company_id; Type: INDEX; Schema: empresa; Owner: postgres
--

CREATE INDEX idx_company_users_company_id ON empresa.company_users USING btree (company_id);


--
-- Name: idx_company_users_user_id; Type: INDEX; Schema: empresa; Owner: postgres
--

CREATE INDEX idx_company_users_user_id ON empresa.company_users USING btree (user_id);


--
-- Name: company_addresses fk_company_addresses_branch; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_addresses
    ADD CONSTRAINT fk_company_addresses_branch FOREIGN KEY (branch_id) REFERENCES empresa.company_branches(id) ON DELETE SET NULL;


--
-- Name: company_addresses fk_company_addresses_company; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_addresses
    ADD CONSTRAINT fk_company_addresses_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_banks fk_company_banks_company; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_banks
    ADD CONSTRAINT fk_company_banks_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_branches fk_company_branches_company; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_branches
    ADD CONSTRAINT fk_company_branches_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_contacts fk_company_contacts_branch; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_contacts
    ADD CONSTRAINT fk_company_contacts_branch FOREIGN KEY (branch_id) REFERENCES empresa.company_branches(id) ON DELETE SET NULL;


--
-- Name: company_contacts fk_company_contacts_company; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_contacts
    ADD CONSTRAINT fk_company_contacts_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_documents fk_company_documents_company; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_documents
    ADD CONSTRAINT fk_company_documents_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_licenses fk_company_licenses_company; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_licenses
    ADD CONSTRAINT fk_company_licenses_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_settings fk_company_settings_company; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_settings
    ADD CONSTRAINT fk_company_settings_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_tax_info fk_company_tax_info_company; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_tax_info
    ADD CONSTRAINT fk_company_tax_info_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_users fk_company_users_branch; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_users
    ADD CONSTRAINT fk_company_users_branch FOREIGN KEY (branch_id) REFERENCES empresa.company_branches(id) ON DELETE SET NULL;


--
-- Name: company_users fk_company_users_company; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.company_users
    ADD CONSTRAINT fk_company_users_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict hjMhFvQiHZdzESHm8u473PagtNNuamKdBjPjeHlG7zgVtCBlXQ9pYSihbL4MEZo

