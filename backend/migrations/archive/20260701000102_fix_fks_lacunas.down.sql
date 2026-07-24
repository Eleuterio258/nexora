-- 102_fix_fks_lacunas.down.sql

BEGIN;

-- utilizadores
ALTER TABLE utilizadores.user_tokens         DROP CONSTRAINT IF EXISTS fk_user_tokens_user;
ALTER TABLE utilizadores.user_settings       DROP CONSTRAINT IF EXISTS fk_user_settings_user;
ALTER TABLE utilizadores.user_security_logs  DROP CONSTRAINT IF EXISTS fk_user_security_logs_user;
ALTER TABLE utilizadores.user_preferences    DROP CONSTRAINT IF EXISTS fk_user_preferences_user;
ALTER TABLE utilizadores.user_notifications  DROP CONSTRAINT IF EXISTS fk_user_notifications_user;
ALTER TABLE utilizadores.user_devices        DROP CONSTRAINT IF EXISTS fk_user_devices_user;
ALTER TABLE utilizadores.user_avatar         DROP CONSTRAINT IF EXISTS fk_user_avatar_user;
ALTER TABLE utilizadores.user_activity       DROP CONSTRAINT IF EXISTS fk_user_activity_user;
ALTER TABLE utilizadores.profiles            DROP CONSTRAINT IF EXISTS fk_profiles_user;

-- recrutamento
ALTER TABLE recrutamento.config_notificacoes DROP CONSTRAINT IF EXISTS fk_config_notificacoes_tenant;

-- gestao_escolar
ALTER TABLE gestao_escolar.school_messages   DROP CONSTRAINT IF EXISTS fk_school_messages_created_by;

-- pos
ALTER TABLE pos.pos_terminals                DROP CONSTRAINT IF EXISTS fk_pos_terminals_caixa;
ALTER TABLE pos.pos_terminals                DROP CONSTRAINT IF EXISTS fk_pos_terminals_warehouse;
ALTER TABLE pos.pos_catalog_items            DROP CONSTRAINT IF EXISTS fk_pos_catalog_items_variant;
ALTER TABLE pos.pos_catalog_items            DROP CONSTRAINT IF EXISTS fk_pos_catalog_items_product;

-- stock
ALTER TABLE stock.stock_counts               DROP CONSTRAINT IF EXISTS fk_stock_counts_warehouse;
ALTER TABLE stock.stock_items                DROP CONSTRAINT IF EXISTS fk_stock_items_warehouse;
ALTER TABLE stock.stock_items                DROP CONSTRAINT IF EXISTS fk_stock_items_product;

-- sistema_configuracao
ALTER TABLE sistema_configuracao.exchange_rates DROP CONSTRAINT IF EXISTS fk_exchange_rates_to_currency;
ALTER TABLE sistema_configuracao.exchange_rates DROP CONSTRAINT IF EXISTS fk_exchange_rates_from_currency;
ALTER TABLE sistema_configuracao.cities        DROP CONSTRAINT IF EXISTS fk_cities_country;

-- rh.ausencias.tipo — restaurar coluna legada (sem dados, só estrutura)
ALTER TABLE rh.ausencias ADD COLUMN IF NOT EXISTS tipo VARCHAR(100);

COMMIT;
