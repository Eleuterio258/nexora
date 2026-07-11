DROP TABLE IF EXISTS hardware.drivers;
DROP TABLE IF EXISTS hardware.device_configs;
ALTER TABLE hardware.devices DROP COLUMN IF EXISTS driver;
