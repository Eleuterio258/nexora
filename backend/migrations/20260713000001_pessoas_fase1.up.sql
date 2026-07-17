-- Migration: Fase 1 do modelo Pessoa central
-- Ver docs/analise-modelo-pessoa-multi-tenant.md (secoes 5 e 6, Fase 1 - Preparacao)
--
-- Objectivo: introduzir a entidade Pessoa como agregador de dados civis,
-- sem remover nem quebrar nada do modelo actual. E puramente aditivo:
-- schema/tabelas novas + colunas pessoa_id opcionais + backfill.
-- A normalizacao de auth.memberships/auth.users.tipo (multi-tenant e
-- multi-papel reais) fica para a Fase 2.

CREATE SCHEMA IF NOT EXISTS pessoas;

CREATE TABLE IF NOT EXISTS pessoas.pessoas (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo            VARCHAR(50) UNIQUE,
    nome_completo     VARCHAR(200) NOT NULL,
    primeiro_nome     VARCHAR(100),
    ultimo_nome       VARCHAR(100),
    data_nascimento   DATE,
    genero            VARCHAR(20) CHECK (genero IN ('M','F','outro','nao_informado')),
    nuit              VARCHAR(30),
    tipo_documento    VARCHAR(30),
    numero_documento  VARCHAR(60),
    nacionalidade     VARCHAR(60),
    estado_civil      VARCHAR(30),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_pessoas_documento UNIQUE (tipo_documento, numero_documento)
);

CREATE TABLE IF NOT EXISTS pessoas.pessoa_contatos (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pessoa_id   BIGINT NOT NULL REFERENCES pessoas.pessoas(id) ON DELETE CASCADE,
    tipo        VARCHAR(30) NOT NULL CHECK (tipo IN ('email','telefone','whatsapp')),
    valor       VARCHAR(255) NOT NULL,
    principal   BOOLEAN NOT NULL DEFAULT FALSE,
    verificado  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_pessoa_contatos_pessoa ON pessoas.pessoa_contatos(pessoa_id);

CREATE TABLE IF NOT EXISTS pessoas.pessoa_enderecos (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pessoa_id     BIGINT NOT NULL REFERENCES pessoas.pessoas(id) ON DELETE CASCADE,
    tipo          VARCHAR(30) NOT NULL DEFAULT 'residencia',
    provincia     VARCHAR(60),
    cidade        VARCHAR(60),
    bairro        VARCHAR(100),
    logradouro    TEXT,
    codigo_postal VARCHAR(20),
    principal     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_pessoa_enderecos_pessoa ON pessoas.pessoa_enderecos(pessoa_id);

-- ============================================================
-- pessoa_id opcional nas tabelas de identidade e de papeis de negocio.
-- Nao se toca em nenhuma constraint/coluna existente.
-- ============================================================
ALTER TABLE auth.users
    ADD COLUMN IF NOT EXISTS pessoa_id BIGINT REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_users_pessoa_id ON auth.users(pessoa_id);

ALTER TABLE rh.funcionarios
    ADD COLUMN IF NOT EXISTS pessoa_id BIGINT REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_funcionarios_pessoa_id ON rh.funcionarios(pessoa_id);

ALTER TABLE gestao_escolar.school_students
    ADD COLUMN IF NOT EXISTS pessoa_id BIGINT REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_school_students_pessoa_id ON gestao_escolar.school_students(pessoa_id);

ALTER TABLE gestao_escolar.school_guardians
    ADD COLUMN IF NOT EXISTS pessoa_id BIGINT REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_school_guardians_pessoa_id ON gestao_escolar.school_guardians(pessoa_id);

ALTER TABLE gestao_escolar.school_teachers
    ADD COLUMN IF NOT EXISTS pessoa_id BIGINT REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_school_teachers_pessoa_id ON gestao_escolar.school_teachers(pessoa_id);

ALTER TABLE recrutamento.candidatos
    ADD COLUMN IF NOT EXISTS pessoa_id BIGINT REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_candidatos_pessoa_id ON recrutamento.candidatos(pessoa_id);

-- ============================================================
-- Backfill
--
-- Estrategia (deliberadamente conservadora, sem deduplicacao entre
-- tabelas - isso e trabalho da Fase 2/curadoria manual):
--
-- 1) Uma pessoa por auth.users. E o ponto de dedup natural disponivel
--    hoje: email e unico globalmente e quase todos os registos de
--    negocio ja tem user_id preenchido (ver contagens no documento
--    de analise: funcionarios 33/34, students 31/31, guardians 31/31,
--    teachers 32/32, candidatos 5/5).
-- 2) Tabelas de negocio com user_id preenchido herdam o pessoa_id
--    do respectivo auth.users e enriquecem essa pessoa com dados
--    biograficos (data_nascimento, nuit, genero normalizado) quando
--    a pessoa ainda nao os tem.
-- 3) Registos de negocio SEM user_id (ex.: o funcionario 34/34 sem
--    conta) recebem uma pessoa propria, criada a partir dos seus
--    proprios dados.
--
-- Documento (tipo_documento/numero_documento) fica de fora do
-- backfill automatico: e o unico campo com UNIQUE em pessoas, e
-- dados legados nao teem garantia de qualidade suficiente para
-- preencher isso as cegas sem risco de colisao entre duas pessoas
-- diferentes. Fica para curadoria manual na Fase 2.
-- ============================================================
DO $$
DECLARE
    r RECORD;
    v_pessoa_id BIGINT;
BEGIN
    -- 1) auth.users -> pessoas
    FOR r IN SELECT id, nome FROM auth.users WHERE pessoa_id IS NULL ORDER BY id LOOP
        INSERT INTO pessoas.pessoas (nome_completo)
        VALUES (r.nome)
        RETURNING id INTO v_pessoa_id;

        UPDATE auth.users SET pessoa_id = v_pessoa_id WHERE id = r.id;
    END LOOP;

    -- 2a) funcionarios com user_id -> herdam pessoa_id e enriquecem
    UPDATE rh.funcionarios f
       SET pessoa_id = u.pessoa_id
      FROM auth.users u
     WHERE f.user_id = u.id AND f.pessoa_id IS NULL;

    UPDATE pessoas.pessoas p
       SET data_nascimento = COALESCE(p.data_nascimento, f.data_nascimento),
           nuit             = COALESCE(p.nuit, f.nuit),
           genero           = COALESCE(p.genero, CASE
                                   WHEN UPPER(f.genero) IN ('M','MASCULINO') THEN 'M'
                                   WHEN UPPER(f.genero) IN ('F','FEMININO') THEN 'F'
                                   WHEN f.genero IS NOT NULL THEN 'outro'
                                   ELSE NULL END),
           updated_at       = NOW()
      FROM rh.funcionarios f
     WHERE f.pessoa_id = p.id;

    -- 2b) school_students com user_id -> herdam pessoa_id e enriquecem
    UPDATE gestao_escolar.school_students s
       SET pessoa_id = u.pessoa_id
      FROM auth.users u
     WHERE s.user_id = u.id AND s.pessoa_id IS NULL;

    UPDATE pessoas.pessoas p
       SET data_nascimento = COALESCE(p.data_nascimento, s.data_nascimento),
           nuit             = COALESCE(p.nuit, s.nuit),
           genero           = COALESCE(p.genero, CASE
                                   WHEN UPPER(s.genero) IN ('M','MASCULINO') THEN 'M'
                                   WHEN UPPER(s.genero) IN ('F','FEMININO') THEN 'F'
                                   WHEN s.genero IS NOT NULL THEN 'outro'
                                   ELSE NULL END),
           updated_at       = NOW()
      FROM gestao_escolar.school_students s
     WHERE s.pessoa_id = p.id;

    -- 2c) school_guardians com user_id -> herdam pessoa_id e enriquecem
    UPDATE gestao_escolar.school_guardians g
       SET pessoa_id = u.pessoa_id
      FROM auth.users u
     WHERE g.user_id = u.id AND g.pessoa_id IS NULL;

    UPDATE pessoas.pessoas p
       SET nuit       = COALESCE(p.nuit, g.nuit),
           updated_at = NOW()
      FROM gestao_escolar.school_guardians g
     WHERE g.pessoa_id = p.id;

    -- 2d) school_teachers com user_id -> herdam pessoa_id e enriquecem
    UPDATE gestao_escolar.school_teachers t
       SET pessoa_id = u.pessoa_id
      FROM auth.users u
     WHERE t.user_id = u.id AND t.pessoa_id IS NULL;

    UPDATE pessoas.pessoas p
       SET genero     = COALESCE(p.genero, CASE
                             WHEN UPPER(t.genero) IN ('M','MASCULINO') THEN 'M'
                             WHEN UPPER(t.genero) IN ('F','FEMININO') THEN 'F'
                             WHEN t.genero IS NOT NULL THEN 'outro'
                             ELSE NULL END),
           updated_at = NOW()
      FROM gestao_escolar.school_teachers t
     WHERE t.pessoa_id = p.id;

    -- 2e) candidatos com user_id -> herdam pessoa_id (sem dados bio adicionais)
    UPDATE recrutamento.candidatos c
       SET pessoa_id = u.pessoa_id
      FROM auth.users u
     WHERE c.user_id = u.id AND c.pessoa_id IS NULL;

    -- 3) Registos de negocio SEM user_id -> pessoa propria a partir dos seus dados
    FOR r IN SELECT id, nome_completo AS nome, data_nascimento, nuit, genero
               FROM rh.funcionarios WHERE pessoa_id IS NULL LOOP
        INSERT INTO pessoas.pessoas (nome_completo, data_nascimento, nuit, genero)
        VALUES (r.nome, r.data_nascimento, r.nuit,
                CASE WHEN UPPER(r.genero) IN ('M','MASCULINO') THEN 'M'
                     WHEN UPPER(r.genero) IN ('F','FEMININO') THEN 'F'
                     WHEN r.genero IS NOT NULL THEN 'outro' ELSE NULL END)
        RETURNING id INTO v_pessoa_id;
        UPDATE rh.funcionarios SET pessoa_id = v_pessoa_id WHERE id = r.id;
    END LOOP;

    FOR r IN SELECT id, nome, data_nascimento, nuit, genero
               FROM gestao_escolar.school_students WHERE pessoa_id IS NULL LOOP
        INSERT INTO pessoas.pessoas (nome_completo, data_nascimento, nuit, genero)
        VALUES (r.nome, r.data_nascimento, r.nuit,
                CASE WHEN UPPER(r.genero) IN ('M','MASCULINO') THEN 'M'
                     WHEN UPPER(r.genero) IN ('F','FEMININO') THEN 'F'
                     WHEN r.genero IS NOT NULL THEN 'outro' ELSE NULL END)
        RETURNING id INTO v_pessoa_id;
        UPDATE gestao_escolar.school_students SET pessoa_id = v_pessoa_id WHERE id = r.id;
    END LOOP;

    FOR r IN SELECT id, nome, nuit
               FROM gestao_escolar.school_guardians WHERE pessoa_id IS NULL LOOP
        INSERT INTO pessoas.pessoas (nome_completo, nuit)
        VALUES (r.nome, r.nuit)
        RETURNING id INTO v_pessoa_id;
        UPDATE gestao_escolar.school_guardians SET pessoa_id = v_pessoa_id WHERE id = r.id;
    END LOOP;

    FOR r IN SELECT id, nome_completo AS nome, genero
               FROM gestao_escolar.school_teachers WHERE pessoa_id IS NULL LOOP
        INSERT INTO pessoas.pessoas (nome_completo, genero)
        VALUES (r.nome,
                CASE WHEN UPPER(r.genero) IN ('M','MASCULINO') THEN 'M'
                     WHEN UPPER(r.genero) IN ('F','FEMININO') THEN 'F'
                     WHEN r.genero IS NOT NULL THEN 'outro' ELSE NULL END)
        RETURNING id INTO v_pessoa_id;
        UPDATE gestao_escolar.school_teachers SET pessoa_id = v_pessoa_id WHERE id = r.id;
    END LOOP;

    FOR r IN SELECT id, nome FROM recrutamento.candidatos WHERE pessoa_id IS NULL LOOP
        INSERT INTO pessoas.pessoas (nome_completo) VALUES (r.nome) RETURNING id INTO v_pessoa_id;
        UPDATE recrutamento.candidatos SET pessoa_id = v_pessoa_id WHERE id = r.id;
    END LOOP;
END $$;
