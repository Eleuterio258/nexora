-- Migration: Secção 9 (filiação) do modelo Pessoa central.
-- Ver docs/analise-modelo-pessoa-multi-tenant.md (secção 9.3a) e o plano em
-- C:\Users\Eleuterio\.claude\plans\fizzy-napping-sifakis.md.
--
-- Objectivo: pessoa_relacoes generaliza a filiação (hoje só existe como
-- colunas soltas em gestao_escolar.school_guardians, e nem sequer isso em
-- rh.contactos_emergencia) numa tabela pessoa<->pessoa reutilizável.
--
-- Puramente aditivo: nenhuma coluna/tabela existente é alterada ou removida.

CREATE TABLE IF NOT EXISTS pessoas.pessoa_relacoes (
    id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id             BIGINT REFERENCES saas.tenants(id) ON DELETE CASCADE,
    pessoa_id             BIGINT NOT NULL REFERENCES pessoas.pessoas(id) ON DELETE CASCADE,
    pessoa_relacionada_id BIGINT NOT NULL REFERENCES pessoas.pessoas(id) ON DELETE CASCADE,
    tipo_relacao          VARCHAR(50) NOT NULL CHECK (tipo_relacao IN (
        'pai','mae','tutor','encarregado','filho','filha','conjuge',
        'irmao','irma','avo','avo_materno','avo_paterno','tio','tia','outro'
    )),
    responsavel_legal     BOOLEAN NOT NULL DEFAULT FALSE,
    principal             BOOLEAN NOT NULL DEFAULT FALSE,
    data_inicio           DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim              DATE,
    observacoes           TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_pessoa_relacao UNIQUE (tenant_id, pessoa_id, pessoa_relacionada_id, tipo_relacao, data_inicio)
);
CREATE INDEX IF NOT EXISTS idx_pessoa_relacoes_pessoa ON pessoas.pessoa_relacoes(tenant_id, pessoa_id);
CREATE INDEX IF NOT EXISTS idx_pessoa_relacoes_relacionada ON pessoas.pessoa_relacoes(tenant_id, pessoa_relacionada_id);

ALTER TABLE rh.contactos_emergencia
    ADD COLUMN IF NOT EXISTS pessoa_id BIGINT REFERENCES pessoas.pessoas(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_contactos_emergencia_pessoa_id ON rh.contactos_emergencia(pessoa_id);

-- ============================================================
-- Backfill
-- ============================================================
DO $$
DECLARE
    r RECORD;
    v_tipo VARCHAR(50);
BEGIN
    -- 1) school_guardians -> pessoa_relacoes (guardian já tem pessoa_id
    --    preenchido a 100% desde o backfill da Fase 1; o aluno também).
    FOR r IN
        SELECT g.tenant_id, g.pessoa_id AS guardian_pessoa_id,
               s.pessoa_id AS aluno_pessoa_id, g.parentesco, g.principal
          FROM gestao_escolar.school_guardians g
          JOIN gestao_escolar.school_students s ON s.id = g.student_id
         WHERE g.pessoa_id IS NOT NULL AND s.pessoa_id IS NOT NULL
    LOOP
        v_tipo := CASE lower(trim(coalesce(r.parentesco, '')))
            WHEN 'pai' THEN 'pai'
            WHEN 'mae' THEN 'mae'
            WHEN 'mãe' THEN 'mae'
            WHEN 'tutor' THEN 'tutor'
            WHEN 'encarregado' THEN 'encarregado'
            WHEN 'encarregada' THEN 'encarregado'
            WHEN 'irmao' THEN 'irmao'
            WHEN 'irmão' THEN 'irmao'
            WHEN 'irma' THEN 'irma'
            WHEN 'irmã' THEN 'irma'
            WHEN 'avo' THEN 'avo'
            WHEN 'avô' THEN 'avo'
            WHEN 'avó' THEN 'avo'
            WHEN 'tio' THEN 'tio'
            WHEN 'tia' THEN 'tia'
            ELSE 'outro'
        END;

        INSERT INTO pessoas.pessoa_relacoes
            (tenant_id, pessoa_id, pessoa_relacionada_id, tipo_relacao, principal)
        VALUES (r.tenant_id, r.guardian_pessoa_id, r.aluno_pessoa_id, v_tipo, r.principal)
        ON CONFLICT (tenant_id, pessoa_id, pessoa_relacionada_id, tipo_relacao, data_inicio) DO NOTHING;
    END LOOP;

    -- 2) rh.contactos_emergencia -> pessoa própria (nunca teve pessoa_id) +
    --    pessoa_relacoes ligando ao funcionário (que já tem pessoa_id da Fase 1).
    FOR r IN
        SELECT ce.id, ce.tenant_id, ce.nome, ce.parentesco, f.pessoa_id AS funcionario_pessoa_id
          FROM rh.contactos_emergencia ce
          JOIN rh.funcionarios f ON f.id = ce.funcionario_id
         WHERE ce.pessoa_id IS NULL AND f.pessoa_id IS NOT NULL
    LOOP
        DECLARE
            v_pessoa_id BIGINT;
        BEGIN
            INSERT INTO pessoas.pessoas (nome_completo) VALUES (r.nome) RETURNING id INTO v_pessoa_id;
            UPDATE rh.contactos_emergencia SET pessoa_id = v_pessoa_id WHERE id = r.id;

            v_tipo := CASE lower(trim(coalesce(r.parentesco, '')))
                WHEN 'conjuge' THEN 'conjuge'
                WHEN 'cônjuge' THEN 'conjuge'
                WHEN 'esposo' THEN 'conjuge'
                WHEN 'esposa' THEN 'conjuge'
                WHEN 'pai' THEN 'pai'
                WHEN 'mae' THEN 'mae'
                WHEN 'mãe' THEN 'mae'
                WHEN 'filho' THEN 'filho'
                WHEN 'filha' THEN 'filha'
                WHEN 'irmao' THEN 'irmao'
                WHEN 'irmão' THEN 'irmao'
                WHEN 'irma' THEN 'irma'
                WHEN 'irmã' THEN 'irma'
                ELSE 'outro'
            END;

            INSERT INTO pessoas.pessoa_relacoes
                (tenant_id, pessoa_id, pessoa_relacionada_id, tipo_relacao)
            VALUES (r.tenant_id, v_pessoa_id, r.funcionario_pessoa_id, v_tipo)
            ON CONFLICT (tenant_id, pessoa_id, pessoa_relacionada_id, tipo_relacao, data_inicio) DO NOTHING;
        END;
    END LOOP;
END $$;
