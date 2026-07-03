--
-- PostgreSQL database dump
--

\restrict M2nfv9kvvlU4lPWpbEqUDN5LQcgXNBcDsN0vebdZU7a2NCPdga4QubTjW4xuhmj

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

--
-- Name: autorizacao; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA autorizacao;


ALTER SCHEMA autorizacao OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: permissions; Type: TABLE; Schema: autorizacao; Owner: postgres
--

CREATE TABLE autorizacao.permissions (
    id bigint NOT NULL,
    codigo character varying(100) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    recurso character varying(100),
    acao character varying(50),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE autorizacao.permissions OWNER TO postgres;

--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: autorizacao; Owner: postgres
--

ALTER TABLE autorizacao.permissions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME autorizacao.permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: role_permissions; Type: TABLE; Schema: autorizacao; Owner: postgres
--

CREATE TABLE autorizacao.role_permissions (
    id bigint NOT NULL,
    role_id bigint NOT NULL,
    permission_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE autorizacao.role_permissions OWNER TO postgres;

--
-- Name: role_permissions_id_seq; Type: SEQUENCE; Schema: autorizacao; Owner: postgres
--

ALTER TABLE autorizacao.role_permissions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME autorizacao.role_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: roles; Type: TABLE; Schema: autorizacao; Owner: postgres
--

CREATE TABLE autorizacao.roles (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE autorizacao.roles OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: autorizacao; Owner: postgres
--

ALTER TABLE autorizacao.roles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME autorizacao.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_roles; Type: TABLE; Schema: autorizacao; Owner: postgres
--

CREATE TABLE autorizacao.user_roles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    role_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE autorizacao.user_roles OWNER TO postgres;

--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: autorizacao; Owner: postgres
--

ALTER TABLE autorizacao.user_roles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME autorizacao.user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: autorizacao; Owner: postgres
--

COPY autorizacao.permissions (id, codigo, nome, descricao, recurso, acao, created_at) FROM stdin;
1	auth.users.manage	Gerir utilizadores	Criar e atualizar utilizadores	auth.users	manage	2026-03-17 16:33:58.781445+00
2	companies.manage	Gerir empresas	Gerir empresas e filiais	companies	manage	2026-03-17 16:33:58.781445+00
3	faturacao.manage	Gerir faturacao	Emitir e anular documentos	faturacao	manage	2026-03-17 16:33:58.781445+00
4	stock.manage	Gerir stock	Movimentar e consultar stock	stock	manage	2026-03-17 16:33:58.781445+00
5	reports.view	Ver relatorios	Consultar relatorios e dashboards	reports	view	2026-03-17 16:33:58.781445+00
6	settings.manage	Gerir configuracoes	Alterar configuracoes do tenant	settings	manage	2026-03-17 16:33:58.781445+00
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: autorizacao; Owner: postgres
--

COPY autorizacao.role_permissions (id, role_id, permission_id, created_at) FROM stdin;
1	1	1	2026-03-17 16:33:58.788285+00
2	1	2	2026-03-17 16:33:58.788285+00
3	1	3	2026-03-17 16:33:58.788285+00
4	1	4	2026-03-17 16:33:58.788285+00
5	1	5	2026-03-17 16:33:58.788285+00
6	1	6	2026-03-17 16:33:58.788285+00
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: autorizacao; Owner: postgres
--

COPY autorizacao.roles (id, tenant_id, codigo, nome, descricao, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: autorizacao; Owner: postgres
--

COPY autorizacao.user_roles (id, user_id, role_id, created_at) FROM stdin;
1	1	1	2026-03-17 16:33:58.793436+00
\.


--
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: autorizacao; Owner: postgres
--

SELECT pg_catalog.setval('autorizacao.permissions_id_seq', 18, true);


--
-- Name: role_permissions_id_seq; Type: SEQUENCE SET; Schema: autorizacao; Owner: postgres
--

SELECT pg_catalog.setval('autorizacao.role_permissions_id_seq', 18, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: autorizacao; Owner: postgres
--

SELECT pg_catalog.setval('autorizacao.roles_id_seq', 4, true);


--
-- Name: user_roles_id_seq; Type: SEQUENCE SET; Schema: autorizacao; Owner: postgres
--

SELECT pg_catalog.setval('autorizacao.user_roles_id_seq', 3, true);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: autorizacao; Owner: postgres
--

ALTER TABLE ONLY autorizacao.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: autorizacao; Owner: postgres
--

ALTER TABLE ONLY autorizacao.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: autorizacao; Owner: postgres
--

ALTER TABLE ONLY autorizacao.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: permissions uq_permissions_codigo; Type: CONSTRAINT; Schema: autorizacao; Owner: postgres
--

ALTER TABLE ONLY autorizacao.permissions
    ADD CONSTRAINT uq_permissions_codigo UNIQUE (codigo);


--
-- Name: role_permissions uq_role_permissions; Type: CONSTRAINT; Schema: autorizacao; Owner: postgres
--

ALTER TABLE ONLY autorizacao.role_permissions
    ADD CONSTRAINT uq_role_permissions UNIQUE (role_id, permission_id);


--
-- Name: roles uq_roles_tenant_codigo; Type: CONSTRAINT; Schema: autorizacao; Owner: postgres
--

ALTER TABLE ONLY autorizacao.roles
    ADD CONSTRAINT uq_roles_tenant_codigo UNIQUE (tenant_id, codigo);


--
-- Name: user_roles uq_user_roles; Type: CONSTRAINT; Schema: autorizacao; Owner: postgres
--

ALTER TABLE ONLY autorizacao.user_roles
    ADD CONSTRAINT uq_user_roles UNIQUE (user_id, role_id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: autorizacao; Owner: postgres
--

ALTER TABLE ONLY autorizacao.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: idx_role_permissions_role_id; Type: INDEX; Schema: autorizacao; Owner: postgres
--

CREATE INDEX idx_role_permissions_role_id ON autorizacao.role_permissions USING btree (role_id);


--
-- Name: idx_roles_tenant_id; Type: INDEX; Schema: autorizacao; Owner: postgres
--

CREATE INDEX idx_roles_tenant_id ON autorizacao.roles USING btree (tenant_id);


--
-- Name: idx_user_roles_role_id; Type: INDEX; Schema: autorizacao; Owner: postgres
--

CREATE INDEX idx_user_roles_role_id ON autorizacao.user_roles USING btree (role_id);


--
-- Name: idx_user_roles_user_id; Type: INDEX; Schema: autorizacao; Owner: postgres
--

CREATE INDEX idx_user_roles_user_id ON autorizacao.user_roles USING btree (user_id);


--
-- Name: role_permissions fk_role_permissions_permission; Type: FK CONSTRAINT; Schema: autorizacao; Owner: postgres
--

ALTER TABLE ONLY autorizacao.role_permissions
    ADD CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES autorizacao.permissions(id) ON DELETE CASCADE;


--
-- Name: role_permissions fk_role_permissions_role; Type: FK CONSTRAINT; Schema: autorizacao; Owner: postgres
--

ALTER TABLE ONLY autorizacao.role_permissions
    ADD CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES autorizacao.roles(id) ON DELETE CASCADE;


--
-- Name: user_roles fk_user_roles_role; Type: FK CONSTRAINT; Schema: autorizacao; Owner: postgres
--

ALTER TABLE ONLY autorizacao.user_roles
    ADD CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES autorizacao.roles(id) ON DELETE CASCADE;


--
-- Name: user_roles fk_user_roles_user; Type: FK CONSTRAINT; Schema: autorizacao; Owner: postgres
--

ALTER TABLE ONLY autorizacao.user_roles
    ADD CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict M2nfv9kvvlU4lPWpbEqUDN5LQcgXNBcDsN0vebdZU7a2NCPdga4QubTjW4xuhmj

