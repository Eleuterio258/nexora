-- 102_fix_fks_lacunas.up.sql
-- Corrige lacunas de integridade referencial identificadas na análise de 2026-07-01:
--   1. FKs em falta em sistema_configuracao, stock, pos, gestao_escolar, recrutamento
--   2. FKs em falta em todas as tabelas do schema utilizadores
--   3. Remove coluna legada rh.ausencias.tipo (substituída por tipo_id)
--   4. Adiciona PK explícita em recrutamento.config_notificacoes

BEGIN;

-- ── 1. sistema_configuracao ──────────────────────────────────────────────────

ALTER TABLE sistema_configuracao.cities
    ADD CONSTRAINT fk_cities_country
        FOREIGN KEY (country_id) REFERENCES sistema_configuracao.countries(id)
        ON DELETE SET NULL;

ALTER TABLE sistema_configuracao.exchange_rates
    ADD CONSTRAINT fk_exchange_rates_from_currency
        FOREIGN KEY (from_currency_id) REFERENCES sistema_configuracao.currencies(id)
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_exchange_rates_to_currency
        FOREIGN KEY (to_currency_id) REFERENCES sistema_configuracao.currencies(id)
        ON DELETE RESTRICT;

-- ── 2. stock ────────────────────────────────────────────────────────────────

ALTER TABLE stock.stock_items
    ADD CONSTRAINT fk_stock_items_product
        FOREIGN KEY (product_id) REFERENCES produtos.products(id)
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_stock_items_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES produtos.warehouses(id)
        ON DELETE RESTRICT;

ALTER TABLE stock.stock_counts
    ADD CONSTRAINT fk_stock_counts_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES produtos.warehouses(id)
        ON DELETE RESTRICT;

-- ── 3. pos ───────────────────────────────────────────────────────────────────

ALTER TABLE pos.pos_catalog_items
    ADD CONSTRAINT fk_pos_catalog_items_product
        FOREIGN KEY (product_id) REFERENCES produtos.products(id)
        ON DELETE CASCADE;

ALTER TABLE pos.pos_catalog_items
    ADD CONSTRAINT fk_pos_catalog_items_variant
        FOREIGN KEY (product_variant_id) REFERENCES produtos.product_variants(id)
        ON DELETE SET NULL;

ALTER TABLE pos.pos_terminals
    ADD CONSTRAINT fk_pos_terminals_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES produtos.warehouses(id)
        ON DELETE SET NULL,
    ADD CONSTRAINT fk_pos_terminals_caixa
        FOREIGN KEY (caixa_id) REFERENCES tesouraria.cash_registers(id)
        ON DELETE SET NULL;

-- ── 4. gestao_escolar ────────────────────────────────────────────────────────

ALTER TABLE gestao_escolar.school_messages
    ADD CONSTRAINT fk_school_messages_created_by
        FOREIGN KEY (created_by) REFERENCES auth.users(id)
        ON DELETE SET NULL;

-- ── 5. recrutamento.config_notificacoes — PK explícita + FK ─────────────────

ALTER TABLE recrutamento.config_notificacoes
    ADD CONSTRAINT fk_config_notificacoes_tenant
        FOREIGN KEY (tenant_id) REFERENCES saas.tenants(id)
        ON DELETE CASCADE;

-- ── 6. utilizadores — limpar órfãos e adicionar FKs com CASCADE ──────────────
-- user_id=4 não existe em auth.users — registos foram criados por conta de teste
-- entretanto eliminada. Apagar antes de adicionar a FK.

DELETE FROM utilizadores.user_preferences   WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = user_id);
DELETE FROM utilizadores.user_notifications  WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = user_id);
DELETE FROM utilizadores.user_devices        WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = user_id);
DELETE FROM utilizadores.profiles            WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = user_id);

ALTER TABLE utilizadores.profiles
    ADD CONSTRAINT fk_profiles_user
        FOREIGN KEY (user_id) REFERENCES auth.users(id)
        ON DELETE CASCADE;

ALTER TABLE utilizadores.user_activity
    ADD CONSTRAINT fk_user_activity_user
        FOREIGN KEY (user_id) REFERENCES auth.users(id)
        ON DELETE CASCADE;

ALTER TABLE utilizadores.user_avatar
    ADD CONSTRAINT fk_user_avatar_user
        FOREIGN KEY (user_id) REFERENCES auth.users(id)
        ON DELETE CASCADE;

ALTER TABLE utilizadores.user_devices
    ADD CONSTRAINT fk_user_devices_user
        FOREIGN KEY (user_id) REFERENCES auth.users(id)
        ON DELETE CASCADE;

ALTER TABLE utilizadores.user_notifications
    ADD CONSTRAINT fk_user_notifications_user
        FOREIGN KEY (user_id) REFERENCES auth.users(id)
        ON DELETE CASCADE;

ALTER TABLE utilizadores.user_preferences
    ADD CONSTRAINT fk_user_preferences_user
        FOREIGN KEY (user_id) REFERENCES auth.users(id)
        ON DELETE CASCADE;

ALTER TABLE utilizadores.user_security_logs
    ADD CONSTRAINT fk_user_security_logs_user
        FOREIGN KEY (user_id) REFERENCES auth.users(id)
        ON DELETE CASCADE;

ALTER TABLE utilizadores.user_settings
    ADD CONSTRAINT fk_user_settings_user
        FOREIGN KEY (user_id) REFERENCES auth.users(id)
        ON DELETE CASCADE;

ALTER TABLE utilizadores.user_tokens
    ADD CONSTRAINT fk_user_tokens_user
        FOREIGN KEY (user_id) REFERENCES auth.users(id)
        ON DELETE CASCADE;

-- ── 7. rh.ausencias — remover coluna legada tipo (substituída por tipo_id) ───
-- Verificado: backend usa exclusivamente tipo_id; ambas as colunas têm 32 linhas
-- em sincronia. A coluna tipo (varchar) não é lida nem escrita pelo código Go.

ALTER TABLE rh.ausencias DROP COLUMN IF EXISTS tipo;

COMMIT;
