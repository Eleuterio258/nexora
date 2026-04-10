-- Bootstrap multi-schema database for Nexora ERP

CREATE SCHEMA IF NOT EXISTS auth;
SET search_path TO auth;
\i /opt/nexora-services/auth-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS empresa;
SET search_path TO empresa;
\i /opt/nexora-services/empresa-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS faturacao;
SET search_path TO faturacao;
\i /opt/nexora-services/faturacao-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS autorizacao;
SET search_path TO autorizacao;
\i /opt/nexora-services/autorizacao-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS clientes;
SET search_path TO clientes;
\i /opt/nexora-services/clientes-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS produtos;
SET search_path TO produtos;
\i /opt/nexora-services/produtos-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS impostos;
SET search_path TO impostos;
\i /opt/nexora-services/impostos-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS stock;
SET search_path TO stock;
\i /opt/nexora-services/stock-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS financeiro;
SET search_path TO financeiro;
\i /opt/nexora-services/financeiro-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS tesouraria;
SET search_path TO tesouraria;
\i /opt/nexora-services/tesouraria-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS compras;
SET search_path TO compras;
\i /opt/nexora-services/compras-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS contabilidade;
SET search_path TO contabilidade;
\i /opt/nexora-services/contabilidade-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS recursos_humanos;
SET search_path TO recursos_humanos;
\i /opt/nexora-services/recursos-humanos-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS multi_moeda;
SET search_path TO multi_moeda;
\i /opt/nexora-services/multi-moeda-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS sistema_configuracao;
SET search_path TO sistema_configuracao;
\i /opt/nexora-services/sistema-configuracao-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS auditoria;
SET search_path TO auditoria;
\i /opt/nexora-services/auditoria-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS crm;
SET search_path TO crm;
\i /opt/nexora-services/crm-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS pos;
SET search_path TO pos;
\i /opt/nexora-services/pos-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS centros_custo;
SET search_path TO centros_custo;
\i /opt/nexora-services/centros-custo-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS seguranca;
SET search_path TO seguranca;
\i /opt/nexora-services/seguranca-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS assinaturas;
SET search_path TO assinaturas;
\i /opt/nexora-services/assinaturas-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS notifications;
SET search_path TO notifications;
\i /opt/nexora-services/notifications-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS logistica;
SET search_path TO logistica;
\i /opt/nexora-services/logistica-service/migrations/001_init.sql

CREATE SCHEMA IF NOT EXISTS gestao_escolar;
SET search_path TO gestao_escolar;
\i /opt/nexora-services/gestao-escolar-service/migrations/001_init.sql
