-- Reverte a Fase 1 do modelo Pessoa central.
-- Puramente aditivo na subida, por isso a descida so remove o que foi criado.

ALTER TABLE recrutamento.candidatos DROP COLUMN IF EXISTS pessoa_id;
ALTER TABLE gestao_escolar.school_teachers DROP COLUMN IF EXISTS pessoa_id;
ALTER TABLE gestao_escolar.school_guardians DROP COLUMN IF EXISTS pessoa_id;
ALTER TABLE gestao_escolar.school_students DROP COLUMN IF EXISTS pessoa_id;
ALTER TABLE rh.funcionarios DROP COLUMN IF EXISTS pessoa_id;
ALTER TABLE auth.users DROP COLUMN IF EXISTS pessoa_id;

DROP TABLE IF EXISTS pessoas.pessoa_enderecos;
DROP TABLE IF EXISTS pessoas.pessoa_contatos;
DROP TABLE IF EXISTS pessoas.pessoas;
DROP SCHEMA IF EXISTS pessoas;
