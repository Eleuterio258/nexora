-- Reverte auth.criar_cargos_padrao() para o estado (regressivo) em que
-- 20260727000002_cargos_padrao_restore.up.sql a encontrou — só os 2 cargos
-- escolares de archive/20260629000093_cargos_turma. Não desfaz a reparação de
-- dados (cargos/permissões já criados ficam), à semelhança de outras
-- migrações de restauro nesta pasta — reverter dados de RBAC já concedidos
-- seria mais destrutivo do que útil.

SET search_path TO auth, public;

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
