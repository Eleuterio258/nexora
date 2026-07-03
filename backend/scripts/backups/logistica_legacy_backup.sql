--
-- PostgreSQL database dump
--

\restrict NoDVnLcoywgqAqEsxYq9wE17wH9DsUtkaOhML3VWXW33H1JBy8FTXIAE5srah3Z

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

ALTER TABLE IF EXISTS ONLY logistica.shipments DROP CONSTRAINT IF EXISTS shipments_vehicle_id_fkey;
ALTER TABLE IF EXISTS ONLY logistica.shipments DROP CONSTRAINT IF EXISTS shipments_status_id_fkey;
ALTER TABLE IF EXISTS ONLY logistica.shipments DROP CONSTRAINT IF EXISTS shipments_route_id_fkey;
ALTER TABLE IF EXISTS ONLY logistica.shipments DROP CONSTRAINT IF EXISTS shipments_driver_id_fkey;
ALTER TABLE IF EXISTS ONLY logistica.shipment_items DROP CONSTRAINT IF EXISTS shipment_items_shipment_id_fkey;
ALTER TABLE IF EXISTS ONLY logistica.logistics_tracking_events DROP CONSTRAINT IF EXISTS fk_logistics_tracking_events_shipment;
ALTER TABLE IF EXISTS ONLY logistica.logistics_shipments DROP CONSTRAINT IF EXISTS fk_logistics_shipments_vehicle;
ALTER TABLE IF EXISTS ONLY logistica.logistics_shipments DROP CONSTRAINT IF EXISTS fk_logistics_shipments_route;
ALTER TABLE IF EXISTS ONLY logistica.logistics_shipments DROP CONSTRAINT IF EXISTS fk_logistics_shipments_driver;
ALTER TABLE IF EXISTS ONLY logistica.delivery_tracking DROP CONSTRAINT IF EXISTS delivery_tracking_status_id_fkey;
ALTER TABLE IF EXISTS ONLY logistica.delivery_tracking DROP CONSTRAINT IF EXISTS delivery_tracking_shipment_id_fkey;
DROP INDEX IF EXISTS logistica.idx_logistics_vehicles_tenant;
DROP INDEX IF EXISTS logistica.idx_logistics_tracking_shipment;
DROP INDEX IF EXISTS logistica.idx_logistics_tracking_events_tenant;
DROP INDEX IF EXISTS logistica.idx_logistics_shipments_tenant_status;
DROP INDEX IF EXISTS logistica.idx_logistics_routes_tenant;
DROP INDEX IF EXISTS logistica.idx_logistics_drivers_tenant;
ALTER TABLE IF EXISTS ONLY logistica.logistics_vehicles DROP CONSTRAINT IF EXISTS uq_logistics_vehicles_matricula;
ALTER TABLE IF EXISTS ONLY logistica.logistics_vehicles DROP CONSTRAINT IF EXISTS uq_logistics_vehicles_codigo;
ALTER TABLE IF EXISTS ONLY logistica.logistics_shipments DROP CONSTRAINT IF EXISTS uq_logistics_shipments;
ALTER TABLE IF EXISTS ONLY logistica.logistics_routes DROP CONSTRAINT IF EXISTS uq_logistics_routes;
ALTER TABLE IF EXISTS ONLY logistica.logistics_drivers DROP CONSTRAINT IF EXISTS uq_logistics_drivers;
ALTER TABLE IF EXISTS ONLY logistica.shipments DROP CONSTRAINT IF EXISTS shipments_tenant_id_numero_key;
ALTER TABLE IF EXISTS ONLY logistica.shipments DROP CONSTRAINT IF EXISTS shipments_pkey;
ALTER TABLE IF EXISTS ONLY logistica.shipment_items DROP CONSTRAINT IF EXISTS shipment_items_pkey;
ALTER TABLE IF EXISTS ONLY logistica.logistics_vehicles DROP CONSTRAINT IF EXISTS logistics_vehicles_pkey;
ALTER TABLE IF EXISTS ONLY logistica.logistics_tracking_events DROP CONSTRAINT IF EXISTS logistics_tracking_events_pkey;
ALTER TABLE IF EXISTS ONLY logistica.logistics_shipments DROP CONSTRAINT IF EXISTS logistics_shipments_pkey;
ALTER TABLE IF EXISTS ONLY logistica.logistics_routes DROP CONSTRAINT IF EXISTS logistics_routes_pkey;
ALTER TABLE IF EXISTS ONLY logistica.logistics_drivers DROP CONSTRAINT IF EXISTS logistics_drivers_pkey;
ALTER TABLE IF EXISTS ONLY logistica.delivery_vehicles DROP CONSTRAINT IF EXISTS delivery_vehicles_tenant_id_matricula_key;
ALTER TABLE IF EXISTS ONLY logistica.delivery_vehicles DROP CONSTRAINT IF EXISTS delivery_vehicles_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY logistica.delivery_vehicles DROP CONSTRAINT IF EXISTS delivery_vehicles_pkey;
ALTER TABLE IF EXISTS ONLY logistica.delivery_tracking DROP CONSTRAINT IF EXISTS delivery_tracking_pkey;
ALTER TABLE IF EXISTS ONLY logistica.delivery_statuses DROP CONSTRAINT IF EXISTS delivery_statuses_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY logistica.delivery_statuses DROP CONSTRAINT IF EXISTS delivery_statuses_pkey;
ALTER TABLE IF EXISTS ONLY logistica.delivery_routes DROP CONSTRAINT IF EXISTS delivery_routes_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY logistica.delivery_routes DROP CONSTRAINT IF EXISTS delivery_routes_pkey;
ALTER TABLE IF EXISTS ONLY logistica.delivery_drivers DROP CONSTRAINT IF EXISTS delivery_drivers_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY logistica.delivery_drivers DROP CONSTRAINT IF EXISTS delivery_drivers_pkey;
DROP TABLE IF EXISTS logistica.shipments;
DROP TABLE IF EXISTS logistica.shipment_items;
DROP TABLE IF EXISTS logistica.logistics_vehicles;
DROP TABLE IF EXISTS logistica.logistics_tracking_events;
DROP TABLE IF EXISTS logistica.logistics_shipments;
DROP TABLE IF EXISTS logistica.logistics_routes;
DROP TABLE IF EXISTS logistica.logistics_drivers;
DROP TABLE IF EXISTS logistica.delivery_vehicles;
DROP TABLE IF EXISTS logistica.delivery_tracking;
DROP TABLE IF EXISTS logistica.delivery_statuses;
DROP TABLE IF EXISTS logistica.delivery_routes;
DROP TABLE IF EXISTS logistica.delivery_drivers;
DROP SCHEMA IF EXISTS logistica;
--
-- Name: logistica; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA logistica;


ALTER SCHEMA logistica OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: delivery_drivers; Type: TABLE; Schema: logistica; Owner: postgres
--

CREATE TABLE logistica.delivery_drivers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    nome character varying(150) NOT NULL,
    telefone character varying(30),
    documento character varying(80),
    carta_conducao character varying(80),
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT delivery_drivers_estado_check CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'inactivo'::character varying, 'suspenso'::character varying])::text[])))
);


ALTER TABLE logistica.delivery_drivers OWNER TO postgres;

--
-- Name: delivery_drivers_id_seq; Type: SEQUENCE; Schema: logistica; Owner: postgres
--

ALTER TABLE logistica.delivery_drivers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.delivery_drivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: delivery_routes; Type: TABLE; Schema: logistica; Owner: postgres
--

CREATE TABLE logistica.delivery_routes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    nome character varying(150) NOT NULL,
    origem character varying(200) NOT NULL,
    destino character varying(200) NOT NULL,
    distancia_km numeric(12,2),
    duracao_estimada_min integer,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE logistica.delivery_routes OWNER TO postgres;

--
-- Name: delivery_routes_id_seq; Type: SEQUENCE; Schema: logistica; Owner: postgres
--

ALTER TABLE logistica.delivery_routes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.delivery_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: delivery_statuses; Type: TABLE; Schema: logistica; Owner: postgres
--

CREATE TABLE logistica.delivery_statuses (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    nome character varying(100) NOT NULL,
    ordem integer DEFAULT 0 NOT NULL,
    final boolean DEFAULT false NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE logistica.delivery_statuses OWNER TO postgres;

--
-- Name: delivery_statuses_id_seq; Type: SEQUENCE; Schema: logistica; Owner: postgres
--

ALTER TABLE logistica.delivery_statuses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.delivery_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: delivery_tracking; Type: TABLE; Schema: logistica; Owner: postgres
--

CREATE TABLE logistica.delivery_tracking (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    shipment_id bigint NOT NULL,
    status_id bigint NOT NULL,
    latitude numeric(10,7),
    longitude numeric(10,7),
    localizacao character varying(200),
    observacoes text,
    registado_por bigint,
    registado_em timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE logistica.delivery_tracking OWNER TO postgres;

--
-- Name: delivery_tracking_id_seq; Type: SEQUENCE; Schema: logistica; Owner: postgres
--

ALTER TABLE logistica.delivery_tracking ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.delivery_tracking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: delivery_vehicles; Type: TABLE; Schema: logistica; Owner: postgres
--

CREATE TABLE logistica.delivery_vehicles (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    matricula character varying(30) NOT NULL,
    marca character varying(80),
    modelo character varying(80),
    capacidade_kg numeric(18,2),
    estado character varying(20) DEFAULT 'disponivel'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT delivery_vehicles_estado_check CHECK (((estado)::text = ANY ((ARRAY['disponivel'::character varying, 'em_rota'::character varying, 'manutencao'::character varying, 'inactivo'::character varying])::text[])))
);


ALTER TABLE logistica.delivery_vehicles OWNER TO postgres;

--
-- Name: delivery_vehicles_id_seq; Type: SEQUENCE; Schema: logistica; Owner: postgres
--

ALTER TABLE logistica.delivery_vehicles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.delivery_vehicles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: logistics_drivers; Type: TABLE; Schema: logistica; Owner: postgres
--

CREATE TABLE logistica.logistics_drivers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    telefone character varying(30),
    carta_numero character varying(50),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE logistica.logistics_drivers OWNER TO postgres;

--
-- Name: logistics_drivers_id_seq; Type: SEQUENCE; Schema: logistica; Owner: postgres
--

ALTER TABLE logistica.logistics_drivers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_drivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: logistics_routes; Type: TABLE; Schema: logistica; Owner: postgres
--

CREATE TABLE logistica.logistics_routes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    origem character varying(150) NOT NULL,
    destino character varying(150) NOT NULL,
    distancia_km numeric(18,2),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE logistica.logistics_routes OWNER TO postgres;

--
-- Name: logistics_routes_id_seq; Type: SEQUENCE; Schema: logistica; Owner: postgres
--

ALTER TABLE logistica.logistics_routes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: logistics_shipments; Type: TABLE; Schema: logistica; Owner: postgres
--

CREATE TABLE logistica.logistics_shipments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    source_service character varying(100) NOT NULL,
    source_type character varying(100) NOT NULL,
    source_id bigint NOT NULL,
    logistics_route_id bigint,
    vehicle_id bigint,
    driver_id bigint,
    customer_id bigint,
    delivery_address text,
    scheduled_date date,
    status character varying(20) DEFAULT 'planeada'::character varying NOT NULL,
    observacoes text,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT logistics_shipments_status_check CHECK (((status)::text = ANY ((ARRAY['planeada'::character varying, 'despachada'::character varying, 'em_transito'::character varying, 'entregue'::character varying, 'cancelada'::character varying])::text[])))
);


ALTER TABLE logistica.logistics_shipments OWNER TO postgres;

--
-- Name: logistics_shipments_id_seq; Type: SEQUENCE; Schema: logistica; Owner: postgres
--

ALTER TABLE logistica.logistics_shipments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_shipments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: logistics_tracking_events; Type: TABLE; Schema: logistica; Owner: postgres
--

CREATE TABLE logistica.logistics_tracking_events (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    shipment_id bigint NOT NULL,
    evento character varying(30) NOT NULL,
    localizacao character varying(255),
    latitude numeric(10,7),
    longitude numeric(10,7),
    observacoes text,
    event_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT logistics_tracking_events_evento_check CHECK (((evento)::text = ANY ((ARRAY['planeado'::character varying, 'despachado'::character varying, 'em_transito'::character varying, 'entregue'::character varying, 'falha_entrega'::character varying, 'cancelado'::character varying])::text[])))
);


ALTER TABLE logistica.logistics_tracking_events OWNER TO postgres;

--
-- Name: logistics_tracking_events_id_seq; Type: SEQUENCE; Schema: logistica; Owner: postgres
--

ALTER TABLE logistica.logistics_tracking_events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_tracking_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: logistics_vehicles; Type: TABLE; Schema: logistica; Owner: postgres
--

CREATE TABLE logistica.logistics_vehicles (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    matricula character varying(30) NOT NULL,
    descricao character varying(150),
    capacidade_kg numeric(18,2),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE logistica.logistics_vehicles OWNER TO postgres;

--
-- Name: logistics_vehicles_id_seq; Type: SEQUENCE; Schema: logistica; Owner: postgres
--

ALTER TABLE logistica.logistics_vehicles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_vehicles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: shipment_items; Type: TABLE; Schema: logistica; Owner: postgres
--

CREATE TABLE logistica.shipment_items (
    id bigint NOT NULL,
    shipment_id bigint NOT NULL,
    product_id bigint,
    descricao character varying(255) NOT NULL,
    quantidade numeric(18,4) NOT NULL,
    peso_kg numeric(18,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT shipment_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);


ALTER TABLE logistica.shipment_items OWNER TO postgres;

--
-- Name: shipment_items_id_seq; Type: SEQUENCE; Schema: logistica; Owner: postgres
--

ALTER TABLE logistica.shipment_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.shipment_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: shipments; Type: TABLE; Schema: logistica; Owner: postgres
--

CREATE TABLE logistica.shipments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(60) NOT NULL,
    reference_type character varying(60),
    reference_id bigint,
    customer_id bigint,
    route_id bigint,
    driver_id bigint,
    vehicle_id bigint,
    status_id bigint,
    endereco_entrega text NOT NULL,
    contacto_entrega character varying(120),
    data_prevista timestamp with time zone,
    data_entrega timestamp with time zone,
    observacoes text,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE logistica.shipments OWNER TO postgres;

--
-- Name: shipments_id_seq; Type: SEQUENCE; Schema: logistica; Owner: postgres
--

ALTER TABLE logistica.shipments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.shipments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: delivery_drivers; Type: TABLE DATA; Schema: logistica; Owner: postgres
--

COPY logistica.delivery_drivers (id, tenant_id, codigo, nome, telefone, documento, carta_conducao, estado, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: delivery_routes; Type: TABLE DATA; Schema: logistica; Owner: postgres
--

COPY logistica.delivery_routes (id, tenant_id, codigo, nome, origem, destino, distancia_km, duracao_estimada_min, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: delivery_statuses; Type: TABLE DATA; Schema: logistica; Owner: postgres
--

COPY logistica.delivery_statuses (id, tenant_id, codigo, nome, ordem, final, activo, created_at) FROM stdin;
\.


--
-- Data for Name: delivery_tracking; Type: TABLE DATA; Schema: logistica; Owner: postgres
--

COPY logistica.delivery_tracking (id, tenant_id, shipment_id, status_id, latitude, longitude, localizacao, observacoes, registado_por, registado_em) FROM stdin;
\.


--
-- Data for Name: delivery_vehicles; Type: TABLE DATA; Schema: logistica; Owner: postgres
--

COPY logistica.delivery_vehicles (id, tenant_id, codigo, matricula, marca, modelo, capacidade_kg, estado, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: logistics_drivers; Type: TABLE DATA; Schema: logistica; Owner: postgres
--

COPY logistica.logistics_drivers (id, tenant_id, codigo, nome, telefone, carta_numero, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: logistics_routes; Type: TABLE DATA; Schema: logistica; Owner: postgres
--

COPY logistica.logistics_routes (id, tenant_id, codigo, nome, origem, destino, distancia_km, activo, created_at) FROM stdin;
\.


--
-- Data for Name: logistics_shipments; Type: TABLE DATA; Schema: logistica; Owner: postgres
--

COPY logistica.logistics_shipments (id, tenant_id, numero, source_service, source_type, source_id, logistics_route_id, vehicle_id, driver_id, customer_id, delivery_address, scheduled_date, status, observacoes, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: logistics_tracking_events; Type: TABLE DATA; Schema: logistica; Owner: postgres
--

COPY logistica.logistics_tracking_events (id, tenant_id, shipment_id, evento, localizacao, latitude, longitude, observacoes, event_time, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: logistics_vehicles; Type: TABLE DATA; Schema: logistica; Owner: postgres
--

COPY logistica.logistics_vehicles (id, tenant_id, codigo, matricula, descricao, capacidade_kg, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: shipment_items; Type: TABLE DATA; Schema: logistica; Owner: postgres
--

COPY logistica.shipment_items (id, shipment_id, product_id, descricao, quantidade, peso_kg, created_at) FROM stdin;
\.


--
-- Data for Name: shipments; Type: TABLE DATA; Schema: logistica; Owner: postgres
--

COPY logistica.shipments (id, tenant_id, numero, reference_type, reference_id, customer_id, route_id, driver_id, vehicle_id, status_id, endereco_entrega, contacto_entrega, data_prevista, data_entrega, observacoes, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Name: delivery_drivers_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: postgres
--

SELECT pg_catalog.setval('logistica.delivery_drivers_id_seq', 1, false);


--
-- Name: delivery_routes_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: postgres
--

SELECT pg_catalog.setval('logistica.delivery_routes_id_seq', 1, false);


--
-- Name: delivery_statuses_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: postgres
--

SELECT pg_catalog.setval('logistica.delivery_statuses_id_seq', 1, true);


--
-- Name: delivery_tracking_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: postgres
--

SELECT pg_catalog.setval('logistica.delivery_tracking_id_seq', 1, true);


--
-- Name: delivery_vehicles_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: postgres
--

SELECT pg_catalog.setval('logistica.delivery_vehicles_id_seq', 1, false);


--
-- Name: logistics_drivers_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: postgres
--

SELECT pg_catalog.setval('logistica.logistics_drivers_id_seq', 1, false);


--
-- Name: logistics_routes_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: postgres
--

SELECT pg_catalog.setval('logistica.logistics_routes_id_seq', 1, false);


--
-- Name: logistics_shipments_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: postgres
--

SELECT pg_catalog.setval('logistica.logistics_shipments_id_seq', 1, false);


--
-- Name: logistics_tracking_events_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: postgres
--

SELECT pg_catalog.setval('logistica.logistics_tracking_events_id_seq', 1, false);


--
-- Name: logistics_vehicles_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: postgres
--

SELECT pg_catalog.setval('logistica.logistics_vehicles_id_seq', 1, false);


--
-- Name: shipment_items_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: postgres
--

SELECT pg_catalog.setval('logistica.shipment_items_id_seq', 1, true);


--
-- Name: shipments_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: postgres
--

SELECT pg_catalog.setval('logistica.shipments_id_seq', 1, true);


--
-- Name: delivery_drivers delivery_drivers_pkey; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.delivery_drivers
    ADD CONSTRAINT delivery_drivers_pkey PRIMARY KEY (id);


--
-- Name: delivery_drivers delivery_drivers_tenant_id_codigo_key; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.delivery_drivers
    ADD CONSTRAINT delivery_drivers_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: delivery_routes delivery_routes_pkey; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.delivery_routes
    ADD CONSTRAINT delivery_routes_pkey PRIMARY KEY (id);


--
-- Name: delivery_routes delivery_routes_tenant_id_codigo_key; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.delivery_routes
    ADD CONSTRAINT delivery_routes_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: delivery_statuses delivery_statuses_pkey; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.delivery_statuses
    ADD CONSTRAINT delivery_statuses_pkey PRIMARY KEY (id);


--
-- Name: delivery_statuses delivery_statuses_tenant_id_codigo_key; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.delivery_statuses
    ADD CONSTRAINT delivery_statuses_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: delivery_tracking delivery_tracking_pkey; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.delivery_tracking
    ADD CONSTRAINT delivery_tracking_pkey PRIMARY KEY (id);


--
-- Name: delivery_vehicles delivery_vehicles_pkey; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.delivery_vehicles
    ADD CONSTRAINT delivery_vehicles_pkey PRIMARY KEY (id);


--
-- Name: delivery_vehicles delivery_vehicles_tenant_id_codigo_key; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.delivery_vehicles
    ADD CONSTRAINT delivery_vehicles_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: delivery_vehicles delivery_vehicles_tenant_id_matricula_key; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.delivery_vehicles
    ADD CONSTRAINT delivery_vehicles_tenant_id_matricula_key UNIQUE (tenant_id, matricula);


--
-- Name: logistics_drivers logistics_drivers_pkey; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_drivers
    ADD CONSTRAINT logistics_drivers_pkey PRIMARY KEY (id);


--
-- Name: logistics_routes logistics_routes_pkey; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_routes
    ADD CONSTRAINT logistics_routes_pkey PRIMARY KEY (id);


--
-- Name: logistics_shipments logistics_shipments_pkey; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT logistics_shipments_pkey PRIMARY KEY (id);


--
-- Name: logistics_tracking_events logistics_tracking_events_pkey; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_tracking_events
    ADD CONSTRAINT logistics_tracking_events_pkey PRIMARY KEY (id);


--
-- Name: logistics_vehicles logistics_vehicles_pkey; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_vehicles
    ADD CONSTRAINT logistics_vehicles_pkey PRIMARY KEY (id);


--
-- Name: shipment_items shipment_items_pkey; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.shipment_items
    ADD CONSTRAINT shipment_items_pkey PRIMARY KEY (id);


--
-- Name: shipments shipments_pkey; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.shipments
    ADD CONSTRAINT shipments_pkey PRIMARY KEY (id);


--
-- Name: shipments shipments_tenant_id_numero_key; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.shipments
    ADD CONSTRAINT shipments_tenant_id_numero_key UNIQUE (tenant_id, numero);


--
-- Name: logistics_drivers uq_logistics_drivers; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_drivers
    ADD CONSTRAINT uq_logistics_drivers UNIQUE (tenant_id, codigo);


--
-- Name: logistics_routes uq_logistics_routes; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_routes
    ADD CONSTRAINT uq_logistics_routes UNIQUE (tenant_id, codigo);


--
-- Name: logistics_shipments uq_logistics_shipments; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT uq_logistics_shipments UNIQUE (tenant_id, numero);


--
-- Name: logistics_vehicles uq_logistics_vehicles_codigo; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_vehicles
    ADD CONSTRAINT uq_logistics_vehicles_codigo UNIQUE (tenant_id, codigo);


--
-- Name: logistics_vehicles uq_logistics_vehicles_matricula; Type: CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_vehicles
    ADD CONSTRAINT uq_logistics_vehicles_matricula UNIQUE (tenant_id, matricula);


--
-- Name: idx_logistics_drivers_tenant; Type: INDEX; Schema: logistica; Owner: postgres
--

CREATE INDEX idx_logistics_drivers_tenant ON logistica.logistics_drivers USING btree (tenant_id, activo);


--
-- Name: idx_logistics_routes_tenant; Type: INDEX; Schema: logistica; Owner: postgres
--

CREATE INDEX idx_logistics_routes_tenant ON logistica.logistics_routes USING btree (tenant_id, activo);


--
-- Name: idx_logistics_shipments_tenant_status; Type: INDEX; Schema: logistica; Owner: postgres
--

CREATE INDEX idx_logistics_shipments_tenant_status ON logistica.logistics_shipments USING btree (tenant_id, status);


--
-- Name: idx_logistics_tracking_events_tenant; Type: INDEX; Schema: logistica; Owner: postgres
--

CREATE INDEX idx_logistics_tracking_events_tenant ON logistica.logistics_tracking_events USING btree (tenant_id, event_time DESC);


--
-- Name: idx_logistics_tracking_shipment; Type: INDEX; Schema: logistica; Owner: postgres
--

CREATE INDEX idx_logistics_tracking_shipment ON logistica.delivery_tracking USING btree (shipment_id, registado_em DESC);


--
-- Name: idx_logistics_vehicles_tenant; Type: INDEX; Schema: logistica; Owner: postgres
--

CREATE INDEX idx_logistics_vehicles_tenant ON logistica.logistics_vehicles USING btree (tenant_id, activo);


--
-- Name: delivery_tracking delivery_tracking_shipment_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.delivery_tracking
    ADD CONSTRAINT delivery_tracking_shipment_id_fkey FOREIGN KEY (shipment_id) REFERENCES logistica.shipments(id) ON DELETE CASCADE;


--
-- Name: delivery_tracking delivery_tracking_status_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.delivery_tracking
    ADD CONSTRAINT delivery_tracking_status_id_fkey FOREIGN KEY (status_id) REFERENCES logistica.delivery_statuses(id);


--
-- Name: logistics_shipments fk_logistics_shipments_driver; Type: FK CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT fk_logistics_shipments_driver FOREIGN KEY (driver_id) REFERENCES logistica.logistics_drivers(id) ON DELETE SET NULL;


--
-- Name: logistics_shipments fk_logistics_shipments_route; Type: FK CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT fk_logistics_shipments_route FOREIGN KEY (logistics_route_id) REFERENCES logistica.logistics_routes(id) ON DELETE SET NULL;


--
-- Name: logistics_shipments fk_logistics_shipments_vehicle; Type: FK CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT fk_logistics_shipments_vehicle FOREIGN KEY (vehicle_id) REFERENCES logistica.logistics_vehicles(id) ON DELETE SET NULL;


--
-- Name: logistics_tracking_events fk_logistics_tracking_events_shipment; Type: FK CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.logistics_tracking_events
    ADD CONSTRAINT fk_logistics_tracking_events_shipment FOREIGN KEY (shipment_id) REFERENCES logistica.logistics_shipments(id) ON DELETE CASCADE;


--
-- Name: shipment_items shipment_items_shipment_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.shipment_items
    ADD CONSTRAINT shipment_items_shipment_id_fkey FOREIGN KEY (shipment_id) REFERENCES logistica.shipments(id) ON DELETE CASCADE;


--
-- Name: shipments shipments_driver_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.shipments
    ADD CONSTRAINT shipments_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES logistica.delivery_drivers(id);


--
-- Name: shipments shipments_route_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.shipments
    ADD CONSTRAINT shipments_route_id_fkey FOREIGN KEY (route_id) REFERENCES logistica.delivery_routes(id);


--
-- Name: shipments shipments_status_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.shipments
    ADD CONSTRAINT shipments_status_id_fkey FOREIGN KEY (status_id) REFERENCES logistica.delivery_statuses(id);


--
-- Name: shipments shipments_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: postgres
--

ALTER TABLE ONLY logistica.shipments
    ADD CONSTRAINT shipments_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES logistica.delivery_vehicles(id);


--
-- PostgreSQL database dump complete
--

\unrestrict NoDVnLcoywgqAqEsxYq9wE17wH9DsUtkaOhML3VWXW33H1JBy8FTXIAE5srah3Z

