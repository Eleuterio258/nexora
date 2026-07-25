-- Remove o schema `hardware` reposto por 20260725140001_hardware_restore.up.sql.
-- CASCADE porque device_users/device_events/device_configs têm FK para devices.
DROP SCHEMA IF EXISTS hardware CASCADE;
