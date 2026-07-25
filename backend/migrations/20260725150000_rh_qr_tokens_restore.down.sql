-- Remove rh.qr_tokens reposta por 20260725150000_rh_qr_tokens_restore.up.sql.
SET search_path TO rh, public;

DROP TABLE IF EXISTS qr_tokens;
