-- Reverte a Fase de filiação (secção 9, parte 1).

ALTER TABLE rh.contactos_emergencia DROP COLUMN IF EXISTS pessoa_id;
DROP TABLE IF EXISTS pessoas.pessoa_relacoes;
