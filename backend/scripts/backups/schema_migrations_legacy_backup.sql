--
-- PostgreSQL database dump
--

\restrict lp7KoUCje8KV38OhMD1sEZkw8pV1qenffywFzbZ1Ndk4sb2lLFxsKf8PaX87LhK

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

ALTER TABLE IF EXISTS ONLY public.schema_migrations_legacy DROP CONSTRAINT IF EXISTS schema_migrations_pkey;
DROP TABLE IF EXISTS public.schema_migrations_legacy;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: schema_migrations_legacy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations_legacy (
    version text NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.schema_migrations_legacy OWNER TO postgres;

--
-- Data for Name: schema_migrations_legacy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations_legacy (version, applied_at) FROM stdin;
002_empresas.sql	2026-06-29 11:44:13.636628+00
003_autorizacao.sql	2026-06-29 11:44:13.636628+00
004_auditoria.sql	2026-06-29 11:44:13.636628+00
005_sistema_configuracao.sql	2026-06-29 11:44:13.636628+00
006_clientes.sql	2026-06-29 11:44:13.636628+00
007_produtos.sql	2026-06-29 11:44:13.636628+00
008_stock.sql	2026-06-29 11:44:13.636628+00
009_faturacao.sql	2026-06-29 11:44:13.636628+00
010_recrutamento.sql	2026-06-29 11:44:13.636628+00
011_users_email_unique_global.sql	2026-06-29 11:44:13.636628+00
012_crm.sql	2026-06-29 11:44:13.636628+00
013_invoices_tipo.sql	2026-06-29 11:44:13.636628+00
014_pos.sql	2026-06-29 11:44:13.636628+00
015_recursos_humanos.sql	2026-06-29 11:44:13.636628+00
016_unidades_organizacionais.sql	2026-06-29 11:44:13.636628+00
017_rh_ext.sql	2026-06-29 11:44:13.636628+00
018_rh_cargos.sql	2026-06-29 11:44:13.636628+00
019_rh_horarios.sql	2026-06-29 11:44:13.636628+00
020_rh_dados_complementares.sql	2026-06-29 11:44:13.636628+00
021_rh_historico_salarial.sql	2026-06-29 11:44:13.636628+00
022_rh_componentes_salariais.sql	2026-06-29 11:44:13.636628+00
023_rh_beneficios.sql	2026-06-29 11:44:13.636628+00
024_rh_presencas.sql	2026-06-29 11:44:13.636628+00
025_rh_ferias_licencas.sql	2026-06-29 11:44:13.636628+00
026_rh_avaliacoes_criterios.sql	2026-06-29 11:44:13.636628+00
027_rh_formacoes.sql	2026-06-29 11:44:13.636628+00
028_rh_processos_disciplinares.sql	2026-06-29 11:44:13.636628+00
029_rh_processamento_salarial.sql	2026-06-29 11:44:13.636628+00
030_produtos_api_ext.sql	2026-06-29 11:44:13.636628+00
031_stock_api_ext.sql	2026-06-29 11:44:13.636628+00
032_impostos_avancados.sql	2026-06-29 11:44:13.636628+00
033_contabilidade_plano_contas.sql	2026-06-29 11:44:13.636628+00
034_contabilidade_periodos_fiscais.sql	2026-06-29 11:44:13.636628+00
035b_contabilidade_lancamentos.sql	2026-06-29 11:44:13.636628+00
035_clientes_api_ext.sql	2026-06-29 11:44:13.636628+00
036_gestao_escolar.sql	2026-06-29 11:44:13.636628+00
037_compras_api.sql	2026-06-29 11:44:13.636628+00
038_impostos_taxas.sql	2026-06-29 11:44:13.636628+00
039_impostos_transacoes.sql	2026-06-29 11:44:13.636628+00
040_contabilidade_ativos_fixos.sql	2026-06-29 11:44:13.636628+00
041_contabilidade_orcamentos.sql	2026-06-29 11:44:13.636628+00
042_contabilidade_encerramento.sql	2026-06-29 11:44:13.636628+00
043_contabilidade_relatorios.sql	2026-06-29 11:44:13.636628+00
044_logistica_tesouraria.sql	2026-06-29 11:44:13.636628+00
045_permissoes_tipo.sql	2026-06-29 11:44:13.636628+00
046_permissoes_funcionalidades.sql	2026-06-29 11:44:13.636628+00
047_employee_self_service.sql	2026-06-29 11:44:13.636628+00
048_saas_schema.sql	2026-06-29 11:44:13.636628+00
049_link_tenants.sql	2026-06-29 11:44:13.636628+00
050_tenant_admin.sql	2026-06-29 11:44:13.636628+00
051_auth_fks.sql	2026-06-29 11:44:13.636628+00
052_permissoes_tipo_alinhamento.sql	2026-06-29 11:44:13.636628+00
053_remove_modulo_vendas.sql	2026-06-29 11:44:13.636628+00
054_autorizacao_user_roles_fk.sql	2026-06-29 11:44:13.636628+00
055_rh_permissoes_sensiveis.sql	2026-06-29 11:44:13.636628+00
056_superadmin_security_base.sql	2026-06-29 11:44:13.636628+00
057_auth_memberships.sql	2026-06-29 11:44:13.636628+00
058_module_catalog.sql	2026-06-29 11:44:13.636628+00
059_feature_catalog.sql	2026-06-29 11:44:13.636628+00
060_plan_modules.sql	2026-06-29 11:44:13.636628+00
061_approval_flows.sql	2026-06-29 11:44:13.636628+00
062_gestao_escolar_foundation.sql	2026-06-29 11:44:13.636628+00
063_gestao_escolar_horarios_calendario.sql	2026-06-29 11:44:13.636628+00
064_gestao_escolar_ocorrencias.sql	2026-06-29 11:44:13.636628+00
065_gestao_escolar_configuracao_avancada.sql	2026-06-29 11:44:13.636628+00
066_permissoes_gestao_escolar.sql	2026-06-29 11:44:13.636628+00
067_gestao_escolar_financeiro.sql	2026-06-29 11:44:13.636628+00
068_irps_adiantamentos.sql	2026-06-29 11:44:13.636628+00
069_rh_folha_integracao_fase1.sql	2026-06-29 11:44:13.636628+00
070_rh_config_contabilidade_folha.sql	2026-06-29 11:44:13.636628+00
071_rh_folha_tesouraria.sql	2026-06-29 11:44:13.636628+00
072_recrutamento_melhorias.sql	2026-06-29 11:44:13.636628+00
073_recrutamento_permissoes_configuracao.sql	2026-06-29 11:44:13.636628+00
074_recrutamento_form_builder.sql	2026-06-29 11:44:13.636628+00
075_gestao_escolar_integracao_dependencias.sql	2026-06-29 11:44:13.636628+00
076_gestao_escolar_ligacoes_rh_clientes.sql	2026-06-29 11:44:13.636628+00
077_gestao_escolar_config_integracao_completa.sql	2026-06-29 11:44:13.636628+00
078_tarefas.sql	2026-06-29 11:44:13.636628+00
079_portal_aluno.sql	2026-06-29 11:44:13.636628+00
080_remove_tenant_admin.sql	2026-06-29 11:44:13.636628+00
081_cargos_padrao_function.sql	2026-06-29 11:44:13.636628+00
082_portal_fase3.sql	2026-06-29 11:44:13.636628+00
083_escola_notif_fase4.sql	2026-06-29 11:44:13.636628+00
084_portal_encarregado.sql	2026-06-29 11:44:13.636628+00
085_escola_fase6.sql	2026-06-29 11:44:13.636628+00
086_permissoes_escolares_alinhamento.sql	2026-06-29 11:44:13.636628+00
087_funcionarios_sem_cargo_administrador.sql	2026-06-29 11:44:13.636628+00
088_users_escopo.sql	2026-06-29 11:44:13.636628+00
089_seed_utilizadores_teste_escopo.sql	2026-06-29 11:44:13.636628+00
091_classificar_utilizadores_por_escopo.sql	2026-06-29 11:44:13.636628+00
094_schema_migrations.sql	2026-06-29 11:44:13.636628+00
092_portal_aluno_lockout.sql	2026-06-29 11:48:56.957541+00
093_gestao_escolar_fase2.sql	2026-06-29 11:48:56.957541+00
\.


--
-- Name: schema_migrations_legacy schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations_legacy
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- PostgreSQL database dump complete
--

\unrestrict lp7KoUCje8KV38OhMD1sEZkw8pV1qenffywFzbZ1Ndk4sb2lLFxsKf8PaX87LhK

