-- ============================================================
-- Migration 093 (down): Reverte alterações dos cargos de turma
-- ============================================================

SET search_path TO auth, public;

-- Remove permissões adicionais do Director de Turma
DELETE FROM auth.permissoes_cargo
WHERE modulo = 'gestao-escolar'
  AND acao IN ('relatorios', 'gerir_comunicacao')
  AND cargo_id IN (SELECT id FROM auth.cargos WHERE nome = 'Director de Turma');

-- Remove permissões e cargo Chefe de Turma (apenas se não tiver membros atribuídos)
DO $$
DECLARE
    v_cargo_id BIGINT;
BEGIN
    SELECT id INTO v_cargo_id FROM auth.cargos WHERE nome = 'Chefe de Turma';

    IF v_cargo_id IS NOT NULL THEN
        DELETE FROM auth.permissoes_cargo WHERE cargo_id = v_cargo_id;

        IF NOT EXISTS (SELECT 1 FROM auth.memberships WHERE cargo_id = v_cargo_id) THEN
            DELETE FROM auth.cargos WHERE id = v_cargo_id;
        END IF;
    END IF;
END $$;

-- Restaura a função de cargos padrão sem o Chefe de Turma e com permissões
-- originais do Director de Turma.
CREATE OR REPLACE FUNCTION auth.criar_cargos_padrao(p_tenant_id BIGINT)
RETURNS void
LANGUAGE plpgsql AS
$$
DECLARE
    v_id BIGINT;
BEGIN

    -- Director de Turma (permissões originais)
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Director de Turma',
            'Notas e presenças + brigada de turma e comunicação com EE.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET descricao = EXCLUDED.descricao
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'lancar_notas'),
        (v_id, 'gestao-escolar', 'gerir_presencas'),
        (v_id, 'gestao-escolar', 'gerir_ocorrencias')
    ON CONFLICT DO NOTHING;

END;
$$;
