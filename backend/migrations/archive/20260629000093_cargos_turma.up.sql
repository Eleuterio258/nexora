-- ============================================================
-- Migration 093: Cargos Director de Turma e Chefe de Turma
-- ============================================================
-- Ajusta as permissões do cargo "Director de Turma" e cria o cargo
-- "Chefe de Turma" com permissões de apoio à comunicação.

SET search_path TO auth, public;

-- ============================================================
-- 1. Actualizar função de provisionamento de cargos-padrão
-- ============================================================
CREATE OR REPLACE FUNCTION auth.criar_cargos_padrao(p_tenant_id BIGINT)
RETURNS void
LANGUAGE plpgsql AS
$$
DECLARE
    v_id BIGINT;
BEGIN

    -- Director de Turma
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Director de Turma',
            'Acompanha pedagogicamente a turma, consulta relatórios e comunica com encarregados.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET descricao = EXCLUDED.descricao
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'relatorios'),
        (v_id, 'gestao-escolar', 'lancar_notas'),
        (v_id, 'gestao-escolar', 'gerir_presencas'),
        (v_id, 'gestao-escolar', 'gerir_ocorrencias'),
        (v_id, 'gestao-escolar', 'gerir_comunicacao')
    ON CONFLICT DO NOTHING;

    -- Chefe de Turma
    INSERT INTO auth.cargos (tenant_id, nome, descricao)
    VALUES (p_tenant_id, 'Chefe de Turma',
            'Apoia a comunicação e organização da turma.')
    ON CONFLICT (tenant_id, nome) DO UPDATE SET descricao = EXCLUDED.descricao
    RETURNING id INTO v_id;

    INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
        (v_id, 'gestao-escolar', 'ver'),
        (v_id, 'gestao-escolar', 'gerir_comunicacao')
    ON CONFLICT DO NOTHING;

END;
$$;

-- ============================================================
-- 2. Aplicar aos tenants existentes
-- ============================================================
DO $$
DECLARE
    v_tenant_id BIGINT;
BEGIN
    FOR v_tenant_id IN SELECT id FROM saas.tenants LOOP
        PERFORM auth.criar_cargos_padrao(v_tenant_id);
    END LOOP;
END $$;
