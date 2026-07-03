--
-- PostgreSQL database dump
--

\restrict yhVKsXINaghSyfFjlcUagrginpZx9yepoTXJ21pBVWeFox0qzzIEezbJTDBkhXU

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

ALTER TABLE IF EXISTS ONLY tesouraria.reconciliations DROP CONSTRAINT IF EXISTS reconciliations_bank_account_id_fkey;
ALTER TABLE IF EXISTS ONLY tesouraria.movements DROP CONSTRAINT IF EXISTS movements_cash_register_id_fkey;
ALTER TABLE IF EXISTS ONLY tesouraria.movements DROP CONSTRAINT IF EXISTS movements_bank_account_id_fkey;
ALTER TABLE IF EXISTS ONLY tesouraria.reconciliacoes_bancarias DROP CONSTRAINT IF EXISTS fk_reconciliacoes_conta;
ALTER TABLE IF EXISTS ONLY tesouraria.movimentos_financeiros DROP CONSTRAINT IF EXISTS fk_mov_conta;
ALTER TABLE IF EXISTS ONLY tesouraria.movimentos_financeiros DROP CONSTRAINT IF EXISTS fk_mov_caixa;
DROP INDEX IF EXISTS tesouraria.idx_treasury_reconciliations_tenant_status;
DROP INDEX IF EXISTS tesouraria.idx_treasury_movements_tenant_date;
DROP INDEX IF EXISTS tesouraria.idx_reconciliacoes_conta_id;
DROP INDEX IF EXISTS tesouraria.idx_movimentos_tenant_id;
DROP INDEX IF EXISTS tesouraria.idx_contas_bancarias_tenant_id;
DROP INDEX IF EXISTS tesouraria.idx_caixas_tenant_id;
ALTER TABLE IF EXISTS ONLY tesouraria.reconciliations DROP CONSTRAINT IF EXISTS reconciliations_tenant_id_bank_account_id_periodo_inicio_pe_key;
ALTER TABLE IF EXISTS ONLY tesouraria.reconciliations DROP CONSTRAINT IF EXISTS reconciliations_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.reconciliacoes_bancarias DROP CONSTRAINT IF EXISTS reconciliacoes_bancarias_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.movimentos_financeiros DROP CONSTRAINT IF EXISTS movimentos_financeiros_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.movements DROP CONSTRAINT IF EXISTS movements_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.contas_bancarias DROP CONSTRAINT IF EXISTS contas_bancarias_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.cash_registers DROP CONSTRAINT IF EXISTS cash_registers_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY tesouraria.cash_registers DROP CONSTRAINT IF EXISTS cash_registers_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.caixas DROP CONSTRAINT IF EXISTS caixas_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY tesouraria.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_tenant_id_banco_numero_conta_key;
ALTER TABLE IF EXISTS ONLY tesouraria.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_pkey;
DROP TABLE IF EXISTS tesouraria.reconciliations;
DROP TABLE IF EXISTS tesouraria.reconciliacoes_bancarias;
DROP TABLE IF EXISTS tesouraria.movimentos_financeiros;
DROP TABLE IF EXISTS tesouraria.movements;
DROP TABLE IF EXISTS tesouraria.contas_bancarias;
DROP TABLE IF EXISTS tesouraria.cash_registers;
DROP TABLE IF EXISTS tesouraria.caixas;
DROP TABLE IF EXISTS tesouraria.bank_accounts;
DROP SCHEMA IF EXISTS tesouraria;
--
-- Name: tesouraria; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA tesouraria;


ALTER SCHEMA tesouraria OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bank_accounts; Type: TABLE; Schema: tesouraria; Owner: postgres
--

CREATE TABLE tesouraria.bank_accounts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    banco character varying(120) NOT NULL,
    numero_conta character varying(80) NOT NULL,
    iban character varying(80),
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    saldo_inicial numeric(18,2) DEFAULT 0 NOT NULL,
    saldo_actual numeric(18,2) DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE tesouraria.bank_accounts OWNER TO postgres;

--
-- Name: bank_accounts_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: postgres
--

ALTER TABLE tesouraria.bank_accounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.bank_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: caixas; Type: TABLE; Schema: tesouraria; Owner: postgres
--

CREATE TABLE tesouraria.caixas (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(120) NOT NULL,
    saldo_atual numeric(18,2) DEFAULT 0 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE tesouraria.caixas OWNER TO postgres;

--
-- Name: caixas_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: postgres
--

ALTER TABLE tesouraria.caixas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.caixas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cash_registers; Type: TABLE; Schema: tesouraria; Owner: postgres
--

CREATE TABLE tesouraria.cash_registers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    nome character varying(120) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    saldo_inicial numeric(18,2) DEFAULT 0 NOT NULL,
    saldo_actual numeric(18,2) DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE tesouraria.cash_registers OWNER TO postgres;

--
-- Name: cash_registers_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: postgres
--

ALTER TABLE tesouraria.cash_registers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.cash_registers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: contas_bancarias; Type: TABLE; Schema: tesouraria; Owner: postgres
--

CREATE TABLE tesouraria.contas_bancarias (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    banco character varying(120) NOT NULL,
    numero_conta character varying(60) NOT NULL,
    nib character varying(60),
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    saldo_atual numeric(18,2) DEFAULT 0 NOT NULL,
    ativa boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE tesouraria.contas_bancarias OWNER TO postgres;

--
-- Name: contas_bancarias_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: postgres
--

ALTER TABLE tesouraria.contas_bancarias ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.contas_bancarias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: movements; Type: TABLE; Schema: tesouraria; Owner: postgres
--

CREATE TABLE tesouraria.movements (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    bank_account_id bigint,
    cash_register_id bigint,
    tipo character varying(20) NOT NULL,
    valor numeric(18,2) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    data_movimento date DEFAULT CURRENT_DATE NOT NULL,
    metodo character varying(40),
    referencia character varying(100),
    descricao text,
    reference_type character varying(60),
    reference_id bigint,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT movements_check CHECK (((((bank_account_id IS NOT NULL))::integer + ((cash_register_id IS NOT NULL))::integer) = 1)),
    CONSTRAINT movements_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['recebimento'::character varying, 'pagamento'::character varying])::text[]))),
    CONSTRAINT movements_valor_check CHECK ((valor > (0)::numeric))
);


ALTER TABLE tesouraria.movements OWNER TO postgres;

--
-- Name: movements_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: postgres
--

ALTER TABLE tesouraria.movements ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.movements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: movimentos_financeiros; Type: TABLE; Schema: tesouraria; Owner: postgres
--

CREATE TABLE tesouraria.movimentos_financeiros (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    origem_tipo character varying(30) NOT NULL,
    origem_id bigint,
    conta_bancaria_id bigint,
    caixa_id bigint,
    tipo character varying(20) NOT NULL,
    valor numeric(18,2) NOT NULL,
    referencia character varying(100),
    descricao text,
    data_movimento timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT movimentos_financeiros_origem_tipo_check CHECK (((origem_tipo)::text = ANY ((ARRAY['faturacao'::character varying, 'compras'::character varying, 'rh'::character varying, 'ajuste'::character varying, 'escolar'::character varying])::text[]))),
    CONSTRAINT movimentos_financeiros_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['recebimento'::character varying, 'pagamento'::character varying, 'transferencia'::character varying, 'ajuste'::character varying])::text[]))),
    CONSTRAINT movimentos_financeiros_valor_check CHECK ((valor > (0)::numeric))
);


ALTER TABLE tesouraria.movimentos_financeiros OWNER TO postgres;

--
-- Name: movimentos_financeiros_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: postgres
--

ALTER TABLE tesouraria.movimentos_financeiros ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.movimentos_financeiros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reconciliacoes_bancarias; Type: TABLE; Schema: tesouraria; Owner: postgres
--

CREATE TABLE tesouraria.reconciliacoes_bancarias (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    conta_bancaria_id bigint NOT NULL,
    periodo_inicio date NOT NULL,
    periodo_fim date NOT NULL,
    saldo_extrato numeric(18,2) NOT NULL,
    saldo_sistema numeric(18,2) NOT NULL,
    diferenca numeric(18,2) NOT NULL,
    status character varying(20) DEFAULT 'aberta'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT reconciliacoes_bancarias_status_check CHECK (((status)::text = ANY ((ARRAY['aberta'::character varying, 'fechada'::character varying])::text[])))
);


ALTER TABLE tesouraria.reconciliacoes_bancarias OWNER TO postgres;

--
-- Name: reconciliacoes_bancarias_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: postgres
--

ALTER TABLE tesouraria.reconciliacoes_bancarias ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.reconciliacoes_bancarias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reconciliations; Type: TABLE; Schema: tesouraria; Owner: postgres
--

CREATE TABLE tesouraria.reconciliations (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    bank_account_id bigint NOT NULL,
    periodo_inicio date NOT NULL,
    periodo_fim date NOT NULL,
    saldo_extracto numeric(18,2) NOT NULL,
    saldo_sistema numeric(18,2) DEFAULT 0 NOT NULL,
    diferenca numeric(18,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'aberta'::character varying NOT NULL,
    observacoes text,
    criada_por bigint,
    fechada_por bigint,
    fechada_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT reconciliations_check CHECK ((periodo_fim >= periodo_inicio)),
    CONSTRAINT reconciliations_status_check CHECK (((status)::text = ANY ((ARRAY['aberta'::character varying, 'fechada'::character varying])::text[])))
);


ALTER TABLE tesouraria.reconciliations OWNER TO postgres;

--
-- Name: reconciliations_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: postgres
--

ALTER TABLE tesouraria.reconciliations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.reconciliations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: bank_accounts; Type: TABLE DATA; Schema: tesouraria; Owner: postgres
--

COPY tesouraria.bank_accounts (id, tenant_id, codigo, banco, numero_conta, iban, moeda, saldo_inicial, saldo_actual, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: caixas; Type: TABLE DATA; Schema: tesouraria; Owner: postgres
--

COPY tesouraria.caixas (id, tenant_id, nome, saldo_atual, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: cash_registers; Type: TABLE DATA; Schema: tesouraria; Owner: postgres
--

COPY tesouraria.cash_registers (id, tenant_id, codigo, nome, moeda, saldo_inicial, saldo_actual, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: contas_bancarias; Type: TABLE DATA; Schema: tesouraria; Owner: postgres
--

COPY tesouraria.contas_bancarias (id, tenant_id, banco, numero_conta, nib, moeda, saldo_atual, ativa, created_at) FROM stdin;
\.


--
-- Data for Name: movements; Type: TABLE DATA; Schema: tesouraria; Owner: postgres
--

COPY tesouraria.movements (id, tenant_id, bank_account_id, cash_register_id, tipo, valor, moeda, data_movimento, metodo, referencia, descricao, reference_type, reference_id, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: movimentos_financeiros; Type: TABLE DATA; Schema: tesouraria; Owner: postgres
--

COPY tesouraria.movimentos_financeiros (id, tenant_id, origem_tipo, origem_id, conta_bancaria_id, caixa_id, tipo, valor, referencia, descricao, data_movimento) FROM stdin;
\.


--
-- Data for Name: reconciliacoes_bancarias; Type: TABLE DATA; Schema: tesouraria; Owner: postgres
--

COPY tesouraria.reconciliacoes_bancarias (id, tenant_id, conta_bancaria_id, periodo_inicio, periodo_fim, saldo_extrato, saldo_sistema, diferenca, status, created_at) FROM stdin;
\.


--
-- Data for Name: reconciliations; Type: TABLE DATA; Schema: tesouraria; Owner: postgres
--

COPY tesouraria.reconciliations (id, tenant_id, bank_account_id, periodo_inicio, periodo_fim, saldo_extracto, saldo_sistema, diferenca, status, observacoes, criada_por, fechada_por, fechada_em, created_at, updated_at) FROM stdin;
\.


--
-- Name: bank_accounts_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: postgres
--

SELECT pg_catalog.setval('tesouraria.bank_accounts_id_seq', 2, true);


--
-- Name: caixas_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: postgres
--

SELECT pg_catalog.setval('tesouraria.caixas_id_seq', 1, false);


--
-- Name: cash_registers_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: postgres
--

SELECT pg_catalog.setval('tesouraria.cash_registers_id_seq', 1, false);


--
-- Name: contas_bancarias_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: postgres
--

SELECT pg_catalog.setval('tesouraria.contas_bancarias_id_seq', 1, false);


--
-- Name: movements_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: postgres
--

SELECT pg_catalog.setval('tesouraria.movements_id_seq', 2, true);


--
-- Name: movimentos_financeiros_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: postgres
--

SELECT pg_catalog.setval('tesouraria.movimentos_financeiros_id_seq', 1, false);


--
-- Name: reconciliacoes_bancarias_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: postgres
--

SELECT pg_catalog.setval('tesouraria.reconciliacoes_bancarias_id_seq', 1, false);


--
-- Name: reconciliations_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: postgres
--

SELECT pg_catalog.setval('tesouraria.reconciliations_id_seq', 1, true);


--
-- Name: bank_accounts bank_accounts_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.bank_accounts
    ADD CONSTRAINT bank_accounts_pkey PRIMARY KEY (id);


--
-- Name: bank_accounts bank_accounts_tenant_id_banco_numero_conta_key; Type: CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.bank_accounts
    ADD CONSTRAINT bank_accounts_tenant_id_banco_numero_conta_key UNIQUE (tenant_id, banco, numero_conta);


--
-- Name: bank_accounts bank_accounts_tenant_id_codigo_key; Type: CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.bank_accounts
    ADD CONSTRAINT bank_accounts_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: caixas caixas_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.caixas
    ADD CONSTRAINT caixas_pkey PRIMARY KEY (id);


--
-- Name: cash_registers cash_registers_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.cash_registers
    ADD CONSTRAINT cash_registers_pkey PRIMARY KEY (id);


--
-- Name: cash_registers cash_registers_tenant_id_codigo_key; Type: CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.cash_registers
    ADD CONSTRAINT cash_registers_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: contas_bancarias contas_bancarias_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.contas_bancarias
    ADD CONSTRAINT contas_bancarias_pkey PRIMARY KEY (id);


--
-- Name: movements movements_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.movements
    ADD CONSTRAINT movements_pkey PRIMARY KEY (id);


--
-- Name: movimentos_financeiros movimentos_financeiros_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.movimentos_financeiros
    ADD CONSTRAINT movimentos_financeiros_pkey PRIMARY KEY (id);


--
-- Name: reconciliacoes_bancarias reconciliacoes_bancarias_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.reconciliacoes_bancarias
    ADD CONSTRAINT reconciliacoes_bancarias_pkey PRIMARY KEY (id);


--
-- Name: reconciliations reconciliations_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.reconciliations
    ADD CONSTRAINT reconciliations_pkey PRIMARY KEY (id);


--
-- Name: reconciliations reconciliations_tenant_id_bank_account_id_periodo_inicio_pe_key; Type: CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.reconciliations
    ADD CONSTRAINT reconciliations_tenant_id_bank_account_id_periodo_inicio_pe_key UNIQUE (tenant_id, bank_account_id, periodo_inicio, periodo_fim);


--
-- Name: idx_caixas_tenant_id; Type: INDEX; Schema: tesouraria; Owner: postgres
--

CREATE INDEX idx_caixas_tenant_id ON tesouraria.caixas USING btree (tenant_id);


--
-- Name: idx_contas_bancarias_tenant_id; Type: INDEX; Schema: tesouraria; Owner: postgres
--

CREATE INDEX idx_contas_bancarias_tenant_id ON tesouraria.contas_bancarias USING btree (tenant_id);


--
-- Name: idx_movimentos_tenant_id; Type: INDEX; Schema: tesouraria; Owner: postgres
--

CREATE INDEX idx_movimentos_tenant_id ON tesouraria.movimentos_financeiros USING btree (tenant_id);


--
-- Name: idx_reconciliacoes_conta_id; Type: INDEX; Schema: tesouraria; Owner: postgres
--

CREATE INDEX idx_reconciliacoes_conta_id ON tesouraria.reconciliacoes_bancarias USING btree (conta_bancaria_id);


--
-- Name: idx_treasury_movements_tenant_date; Type: INDEX; Schema: tesouraria; Owner: postgres
--

CREATE INDEX idx_treasury_movements_tenant_date ON tesouraria.movements USING btree (tenant_id, data_movimento DESC);


--
-- Name: idx_treasury_reconciliations_tenant_status; Type: INDEX; Schema: tesouraria; Owner: postgres
--

CREATE INDEX idx_treasury_reconciliations_tenant_status ON tesouraria.reconciliations USING btree (tenant_id, status, periodo_fim DESC);


--
-- Name: movimentos_financeiros fk_mov_caixa; Type: FK CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.movimentos_financeiros
    ADD CONSTRAINT fk_mov_caixa FOREIGN KEY (caixa_id) REFERENCES tesouraria.caixas(id) ON DELETE SET NULL;


--
-- Name: movimentos_financeiros fk_mov_conta; Type: FK CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.movimentos_financeiros
    ADD CONSTRAINT fk_mov_conta FOREIGN KEY (conta_bancaria_id) REFERENCES tesouraria.contas_bancarias(id) ON DELETE SET NULL;


--
-- Name: reconciliacoes_bancarias fk_reconciliacoes_conta; Type: FK CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.reconciliacoes_bancarias
    ADD CONSTRAINT fk_reconciliacoes_conta FOREIGN KEY (conta_bancaria_id) REFERENCES tesouraria.contas_bancarias(id) ON DELETE RESTRICT;


--
-- Name: movements movements_bank_account_id_fkey; Type: FK CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.movements
    ADD CONSTRAINT movements_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES tesouraria.bank_accounts(id);


--
-- Name: movements movements_cash_register_id_fkey; Type: FK CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.movements
    ADD CONSTRAINT movements_cash_register_id_fkey FOREIGN KEY (cash_register_id) REFERENCES tesouraria.cash_registers(id);


--
-- Name: reconciliations reconciliations_bank_account_id_fkey; Type: FK CONSTRAINT; Schema: tesouraria; Owner: postgres
--

ALTER TABLE ONLY tesouraria.reconciliations
    ADD CONSTRAINT reconciliations_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES tesouraria.bank_accounts(id);


--
-- PostgreSQL database dump complete
--

\unrestrict yhVKsXINaghSyfFjlcUagrginpZx9yepoTXJ21pBVWeFox0qzzIEezbJTDBkhXU

