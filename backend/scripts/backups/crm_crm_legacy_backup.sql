--
-- PostgreSQL database dump
--

\restrict pRlol1HQzkIvVd8hp6TnYTGnx07lVZOkXqrmDFtT2UZy5sP9B14lgJa14BSeRIE

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

ALTER TABLE IF EXISTS ONLY crm.crm_pipeline_stages DROP CONSTRAINT IF EXISTS fk_crm_pipeline_stages_pipeline;
ALTER TABLE IF EXISTS ONLY crm.crm_opportunities DROP CONSTRAINT IF EXISTS fk_crm_opportunities_stage;
ALTER TABLE IF EXISTS ONLY crm.crm_opportunities DROP CONSTRAINT IF EXISTS fk_crm_opportunities_pipeline;
ALTER TABLE IF EXISTS ONLY crm.crm_opportunities DROP CONSTRAINT IF EXISTS fk_crm_opportunities_lead;
ALTER TABLE IF EXISTS ONLY crm.crm_leads DROP CONSTRAINT IF EXISTS fk_crm_leads_source;
ALTER TABLE IF EXISTS ONLY crm.crm_activities DROP CONSTRAINT IF EXISTS fk_crm_activities_opportunity;
ALTER TABLE IF EXISTS ONLY crm.crm_activities DROP CONSTRAINT IF EXISTS fk_crm_activities_lead;
DROP INDEX IF EXISTS crm.idx_crm_pipelines_tenant;
DROP INDEX IF EXISTS crm.idx_crm_pipeline_stages_pipeline;
DROP INDEX IF EXISTS crm.idx_crm_opportunities_tenant_estado;
DROP INDEX IF EXISTS crm.idx_crm_opportunities_stage;
DROP INDEX IF EXISTS crm.idx_crm_leads_tenant_estado;
DROP INDEX IF EXISTS crm.idx_crm_lead_sources_tenant;
DROP INDEX IF EXISTS crm.idx_crm_activities_tenant;
ALTER TABLE IF EXISTS ONLY crm.crm_pipelines DROP CONSTRAINT IF EXISTS uq_crm_pipelines;
ALTER TABLE IF EXISTS ONLY crm.crm_pipeline_stages DROP CONSTRAINT IF EXISTS uq_crm_pipeline_stages;
ALTER TABLE IF EXISTS ONLY crm.crm_opportunities DROP CONSTRAINT IF EXISTS uq_crm_opportunities;
ALTER TABLE IF EXISTS ONLY crm.crm_leads DROP CONSTRAINT IF EXISTS uq_crm_leads;
ALTER TABLE IF EXISTS ONLY crm.crm_lead_sources DROP CONSTRAINT IF EXISTS uq_crm_lead_sources;
ALTER TABLE IF EXISTS ONLY crm.crm_pipelines DROP CONSTRAINT IF EXISTS crm_pipelines_pkey;
ALTER TABLE IF EXISTS ONLY crm.crm_pipeline_stages DROP CONSTRAINT IF EXISTS crm_pipeline_stages_pkey;
ALTER TABLE IF EXISTS ONLY crm.crm_opportunities DROP CONSTRAINT IF EXISTS crm_opportunities_pkey;
ALTER TABLE IF EXISTS ONLY crm.crm_leads DROP CONSTRAINT IF EXISTS crm_leads_pkey;
ALTER TABLE IF EXISTS ONLY crm.crm_lead_sources DROP CONSTRAINT IF EXISTS crm_lead_sources_pkey;
ALTER TABLE IF EXISTS ONLY crm.crm_activities DROP CONSTRAINT IF EXISTS crm_activities_pkey;
DROP TABLE IF EXISTS crm.crm_pipelines;
DROP TABLE IF EXISTS crm.crm_pipeline_stages;
DROP TABLE IF EXISTS crm.crm_opportunities;
DROP TABLE IF EXISTS crm.crm_leads;
DROP TABLE IF EXISTS crm.crm_lead_sources;
DROP TABLE IF EXISTS crm.crm_activities;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: crm_activities; Type: TABLE; Schema: crm; Owner: postgres
--

CREATE TABLE crm.crm_activities (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    lead_id bigint,
    opportunity_id bigint,
    tipo character varying(30) NOT NULL,
    assunto character varying(150) NOT NULL,
    descricao text,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    agendado_para timestamp with time zone,
    concluido_em timestamp with time zone,
    owner_user_id bigint,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT crm_activities_status_check CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'concluida'::character varying, 'cancelada'::character varying])::text[]))),
    CONSTRAINT crm_activities_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['chamada'::character varying, 'email'::character varying, 'reuniao'::character varying, 'nota'::character varying, 'tarefa'::character varying, 'whatsapp'::character varying])::text[])))
);


ALTER TABLE crm.crm_activities OWNER TO postgres;

--
-- Name: crm_activities_id_seq; Type: SEQUENCE; Schema: crm; Owner: postgres
--

ALTER TABLE crm.crm_activities ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.crm_activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: crm_lead_sources; Type: TABLE; Schema: crm; Owner: postgres
--

CREATE TABLE crm.crm_lead_sources (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE crm.crm_lead_sources OWNER TO postgres;

--
-- Name: crm_lead_sources_id_seq; Type: SEQUENCE; Schema: crm; Owner: postgres
--

ALTER TABLE crm.crm_lead_sources ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.crm_lead_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: crm_leads; Type: TABLE; Schema: crm; Owner: postgres
--

CREATE TABLE crm.crm_leads (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    lead_source_id bigint,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    empresa character varying(150),
    email character varying(150),
    telefone character varying(30),
    estado character varying(20) DEFAULT 'novo'::character varying NOT NULL,
    interesse character varying(255),
    observacoes text,
    owner_user_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT crm_leads_estado_check CHECK (((estado)::text = ANY ((ARRAY['novo'::character varying, 'qualificado'::character varying, 'convertido'::character varying, 'perdido'::character varying])::text[])))
);


ALTER TABLE crm.crm_leads OWNER TO postgres;

--
-- Name: crm_leads_id_seq; Type: SEQUENCE; Schema: crm; Owner: postgres
--

ALTER TABLE crm.crm_leads ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.crm_leads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: crm_opportunities; Type: TABLE; Schema: crm; Owner: postgres
--

CREATE TABLE crm.crm_opportunities (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    pipeline_id bigint NOT NULL,
    stage_id bigint NOT NULL,
    lead_id bigint,
    customer_id bigint,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    valor_estimado numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    probabilidade numeric(5,2) DEFAULT 0 NOT NULL,
    expected_close_date date,
    estado character varying(20) DEFAULT 'aberta'::character varying NOT NULL,
    owner_user_id bigint,
    observacoes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT crm_opportunities_estado_check CHECK (((estado)::text = ANY ((ARRAY['aberta'::character varying, 'ganha'::character varying, 'perdida'::character varying, 'cancelada'::character varying])::text[]))),
    CONSTRAINT crm_opportunities_probabilidade_check CHECK (((probabilidade >= (0)::numeric) AND (probabilidade <= (100)::numeric)))
);


ALTER TABLE crm.crm_opportunities OWNER TO postgres;

--
-- Name: crm_opportunities_id_seq; Type: SEQUENCE; Schema: crm; Owner: postgres
--

ALTER TABLE crm.crm_opportunities ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.crm_opportunities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: crm_pipeline_stages; Type: TABLE; Schema: crm; Owner: postgres
--

CREATE TABLE crm.crm_pipeline_stages (
    id bigint NOT NULL,
    pipeline_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    ordem integer NOT NULL,
    probabilidade numeric(5,2) DEFAULT 0 NOT NULL,
    ganho boolean DEFAULT false NOT NULL,
    perdido boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT crm_pipeline_stages_probabilidade_check CHECK (((probabilidade >= (0)::numeric) AND (probabilidade <= (100)::numeric)))
);


ALTER TABLE crm.crm_pipeline_stages OWNER TO postgres;

--
-- Name: crm_pipeline_stages_id_seq; Type: SEQUENCE; Schema: crm; Owner: postgres
--

ALTER TABLE crm.crm_pipeline_stages ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.crm_pipeline_stages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: crm_pipelines; Type: TABLE; Schema: crm; Owner: postgres
--

CREATE TABLE crm.crm_pipelines (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE crm.crm_pipelines OWNER TO postgres;

--
-- Name: crm_pipelines_id_seq; Type: SEQUENCE; Schema: crm; Owner: postgres
--

ALTER TABLE crm.crm_pipelines ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.crm_pipelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: crm_activities; Type: TABLE DATA; Schema: crm; Owner: postgres
--

COPY crm.crm_activities (id, tenant_id, lead_id, opportunity_id, tipo, assunto, descricao, status, agendado_para, concluido_em, owner_user_id, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: crm_lead_sources; Type: TABLE DATA; Schema: crm; Owner: postgres
--

COPY crm.crm_lead_sources (id, tenant_id, codigo, nome, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: crm_leads; Type: TABLE DATA; Schema: crm; Owner: postgres
--

COPY crm.crm_leads (id, tenant_id, lead_source_id, codigo, nome, empresa, email, telefone, estado, interesse, observacoes, owner_user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: crm_opportunities; Type: TABLE DATA; Schema: crm; Owner: postgres
--

COPY crm.crm_opportunities (id, tenant_id, pipeline_id, stage_id, lead_id, customer_id, codigo, nome, valor_estimado, moeda, probabilidade, expected_close_date, estado, owner_user_id, observacoes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: crm_pipeline_stages; Type: TABLE DATA; Schema: crm; Owner: postgres
--

COPY crm.crm_pipeline_stages (id, pipeline_id, codigo, nome, ordem, probabilidade, ganho, perdido, created_at) FROM stdin;
\.


--
-- Data for Name: crm_pipelines; Type: TABLE DATA; Schema: crm; Owner: postgres
--

COPY crm.crm_pipelines (id, tenant_id, codigo, nome, ativo, created_at) FROM stdin;
\.


--
-- Name: crm_activities_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: postgres
--

SELECT pg_catalog.setval('crm.crm_activities_id_seq', 1, false);


--
-- Name: crm_lead_sources_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: postgres
--

SELECT pg_catalog.setval('crm.crm_lead_sources_id_seq', 1, false);


--
-- Name: crm_leads_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: postgres
--

SELECT pg_catalog.setval('crm.crm_leads_id_seq', 1, false);


--
-- Name: crm_opportunities_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: postgres
--

SELECT pg_catalog.setval('crm.crm_opportunities_id_seq', 1, false);


--
-- Name: crm_pipeline_stages_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: postgres
--

SELECT pg_catalog.setval('crm.crm_pipeline_stages_id_seq', 1, false);


--
-- Name: crm_pipelines_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: postgres
--

SELECT pg_catalog.setval('crm.crm_pipelines_id_seq', 1, false);


--
-- Name: crm_activities crm_activities_pkey; Type: CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_activities
    ADD CONSTRAINT crm_activities_pkey PRIMARY KEY (id);


--
-- Name: crm_lead_sources crm_lead_sources_pkey; Type: CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_lead_sources
    ADD CONSTRAINT crm_lead_sources_pkey PRIMARY KEY (id);


--
-- Name: crm_leads crm_leads_pkey; Type: CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_leads
    ADD CONSTRAINT crm_leads_pkey PRIMARY KEY (id);


--
-- Name: crm_opportunities crm_opportunities_pkey; Type: CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_opportunities
    ADD CONSTRAINT crm_opportunities_pkey PRIMARY KEY (id);


--
-- Name: crm_pipeline_stages crm_pipeline_stages_pkey; Type: CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_pipeline_stages
    ADD CONSTRAINT crm_pipeline_stages_pkey PRIMARY KEY (id);


--
-- Name: crm_pipelines crm_pipelines_pkey; Type: CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_pipelines
    ADD CONSTRAINT crm_pipelines_pkey PRIMARY KEY (id);


--
-- Name: crm_lead_sources uq_crm_lead_sources; Type: CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_lead_sources
    ADD CONSTRAINT uq_crm_lead_sources UNIQUE (tenant_id, codigo);


--
-- Name: crm_leads uq_crm_leads; Type: CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_leads
    ADD CONSTRAINT uq_crm_leads UNIQUE (tenant_id, codigo);


--
-- Name: crm_opportunities uq_crm_opportunities; Type: CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_opportunities
    ADD CONSTRAINT uq_crm_opportunities UNIQUE (tenant_id, codigo);


--
-- Name: crm_pipeline_stages uq_crm_pipeline_stages; Type: CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_pipeline_stages
    ADD CONSTRAINT uq_crm_pipeline_stages UNIQUE (pipeline_id, codigo);


--
-- Name: crm_pipelines uq_crm_pipelines; Type: CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_pipelines
    ADD CONSTRAINT uq_crm_pipelines UNIQUE (tenant_id, codigo);


--
-- Name: idx_crm_activities_tenant; Type: INDEX; Schema: crm; Owner: postgres
--

CREATE INDEX idx_crm_activities_tenant ON crm.crm_activities USING btree (tenant_id, status);


--
-- Name: idx_crm_lead_sources_tenant; Type: INDEX; Schema: crm; Owner: postgres
--

CREATE INDEX idx_crm_lead_sources_tenant ON crm.crm_lead_sources USING btree (tenant_id);


--
-- Name: idx_crm_leads_tenant_estado; Type: INDEX; Schema: crm; Owner: postgres
--

CREATE INDEX idx_crm_leads_tenant_estado ON crm.crm_leads USING btree (tenant_id, estado);


--
-- Name: idx_crm_opportunities_stage; Type: INDEX; Schema: crm; Owner: postgres
--

CREATE INDEX idx_crm_opportunities_stage ON crm.crm_opportunities USING btree (stage_id);


--
-- Name: idx_crm_opportunities_tenant_estado; Type: INDEX; Schema: crm; Owner: postgres
--

CREATE INDEX idx_crm_opportunities_tenant_estado ON crm.crm_opportunities USING btree (tenant_id, estado);


--
-- Name: idx_crm_pipeline_stages_pipeline; Type: INDEX; Schema: crm; Owner: postgres
--

CREATE INDEX idx_crm_pipeline_stages_pipeline ON crm.crm_pipeline_stages USING btree (pipeline_id, ordem);


--
-- Name: idx_crm_pipelines_tenant; Type: INDEX; Schema: crm; Owner: postgres
--

CREATE INDEX idx_crm_pipelines_tenant ON crm.crm_pipelines USING btree (tenant_id);


--
-- Name: crm_activities fk_crm_activities_lead; Type: FK CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_activities
    ADD CONSTRAINT fk_crm_activities_lead FOREIGN KEY (lead_id) REFERENCES crm.crm_leads(id) ON DELETE CASCADE;


--
-- Name: crm_activities fk_crm_activities_opportunity; Type: FK CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_activities
    ADD CONSTRAINT fk_crm_activities_opportunity FOREIGN KEY (opportunity_id) REFERENCES crm.crm_opportunities(id) ON DELETE CASCADE;


--
-- Name: crm_leads fk_crm_leads_source; Type: FK CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_leads
    ADD CONSTRAINT fk_crm_leads_source FOREIGN KEY (lead_source_id) REFERENCES crm.crm_lead_sources(id) ON DELETE SET NULL;


--
-- Name: crm_opportunities fk_crm_opportunities_lead; Type: FK CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_opportunities
    ADD CONSTRAINT fk_crm_opportunities_lead FOREIGN KEY (lead_id) REFERENCES crm.crm_leads(id) ON DELETE SET NULL;


--
-- Name: crm_opportunities fk_crm_opportunities_pipeline; Type: FK CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_opportunities
    ADD CONSTRAINT fk_crm_opportunities_pipeline FOREIGN KEY (pipeline_id) REFERENCES crm.crm_pipelines(id) ON DELETE RESTRICT;


--
-- Name: crm_opportunities fk_crm_opportunities_stage; Type: FK CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_opportunities
    ADD CONSTRAINT fk_crm_opportunities_stage FOREIGN KEY (stage_id) REFERENCES crm.crm_pipeline_stages(id) ON DELETE RESTRICT;


--
-- Name: crm_pipeline_stages fk_crm_pipeline_stages_pipeline; Type: FK CONSTRAINT; Schema: crm; Owner: postgres
--

ALTER TABLE ONLY crm.crm_pipeline_stages
    ADD CONSTRAINT fk_crm_pipeline_stages_pipeline FOREIGN KEY (pipeline_id) REFERENCES crm.crm_pipelines(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict pRlol1HQzkIvVd8hp6TnYTGnx07lVZOkXqrmDFtT2UZy5sP9B14lgJa14BSeRIE

