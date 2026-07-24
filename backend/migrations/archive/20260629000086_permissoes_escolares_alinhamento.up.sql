-- ============================================================
-- Migration 086: Alinhamento idempotente das permissões escolares
-- ============================================================
-- Corrige o desalinhamento entre as acções esperadas pelo router
-- (backend/internal/router/router.go) e as permissões seedadas.
--
-- Acções válidas em /api/escolar:
--   ver, relatorios, gerir_turmas, gerir_alunos, gerir_matriculas,
--   gerir_presencas, lancar_notas, gerir_propinas, gerir_biblioteca,
--   gerir_comunicacao, gerir_horarios, gerir_calendario,
--   gerir_ocorrencias, portal_aluno
-- ============================================================

SET search_path TO auth, public;

DO $$
DECLARE
    v_cargo_id BIGINT;
    v_tenant_id BIGINT;
BEGIN
    -- ============================================================
    -- 1. Limpar permissões escolares obsoletas/inconsistentes
    -- ============================================================
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'permissoes_tipo') THEN
        DELETE FROM auth.permissoes_tipo
        WHERE modulo = 'gestao-escolar'
          AND (
              acao IN ('ver_escolar', 'gerir_academico', 'gerir_professores', 'gerir_frequencia',
                       'gerir_avaliacoes', 'gerir_financeiro', 'gerir', 'gerir_configuracao_escolar',
                       'criar', 'editar', 'eliminar', 'apagar')
              OR tipo IN ('tenant_admin', 'professor')
          );
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'permissoes_cargo') THEN
        DELETE FROM auth.permissoes_cargo
        WHERE modulo = 'gestao-escolar'
          AND acao IN ('ver_escolar', 'gerir_academico', 'gerir_professores', 'gerir_frequencia',
                       'gerir_avaliacoes', 'gerir_financeiro', 'gerir', 'gerir_configuracao_escolar',
                       'eliminar');
    END IF;

    -- ============================================================
    -- 2. Garantir permissões correctas nos cargos escolares padrão
    -- ============================================================
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'cargos') THEN
        RETURN;
    END IF;

    -- Assegura que o Administrador continua a ter todas as acções escolares
    FOR v_cargo_id IN
        SELECT c.id FROM auth.cargos c WHERE c.nome = 'Administrador'
    LOOP
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'gestao-escolar', 'ver'),
            (v_cargo_id, 'gestao-escolar', 'relatorios'),
            (v_cargo_id, 'gestao-escolar', 'gerir_alunos'),
            (v_cargo_id, 'gestao-escolar', 'gerir_turmas'),
            (v_cargo_id, 'gestao-escolar', 'gerir_matriculas'),
            (v_cargo_id, 'gestao-escolar', 'gerir_presencas'),
            (v_cargo_id, 'gestao-escolar', 'lancar_notas'),
            (v_cargo_id, 'gestao-escolar', 'gerir_propinas'),
            (v_cargo_id, 'gestao-escolar', 'gerir_biblioteca'),
            (v_cargo_id, 'gestao-escolar', 'gerir_comunicacao'),
            (v_cargo_id, 'gestao-escolar', 'gerir_horarios'),
            (v_cargo_id, 'gestao-escolar', 'gerir_calendario'),
            (v_cargo_id, 'gestao-escolar', 'gerir_ocorrencias'),
            (v_cargo_id, 'gestao-escolar', 'portal_aluno')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Director Escolar: acesso total ao módulo escolar
    FOR v_cargo_id IN
        SELECT c.id FROM auth.cargos c WHERE c.nome = 'Director Escolar'
    LOOP
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao)
        SELECT v_cargo_id, 'gestao-escolar', a.acao
        FROM (VALUES
            ('ver'),('relatorios'),('gerir_alunos'),('gerir_turmas'),('gerir_matriculas'),
            ('gerir_presencas'),('lancar_notas'),('gerir_propinas'),('gerir_biblioteca'),
            ('gerir_comunicacao'),('gerir_horarios'),('gerir_calendario'),('gerir_ocorrencias'),('portal_aluno')
        ) AS a(acao)
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Director Adjunto Pedagógico
    FOR v_cargo_id IN
        SELECT c.id FROM auth.cargos c WHERE c.nome = 'Director Adjunto Pedagógico'
    LOOP
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'gestao-escolar', 'ver'),
            (v_cargo_id, 'gestao-escolar', 'relatorios'),
            (v_cargo_id, 'gestao-escolar', 'gerir_turmas'),
            (v_cargo_id, 'gestao-escolar', 'gerir_horarios'),
            (v_cargo_id, 'gestao-escolar', 'gerir_calendario'),
            (v_cargo_id, 'gestao-escolar', 'gerir_presencas'),
            (v_cargo_id, 'gestao-escolar', 'gerir_ocorrencias'),
            (v_cargo_id, 'gestao-escolar', 'gerir_comunicacao')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Secretário Escolar
    FOR v_cargo_id IN
        SELECT c.id FROM auth.cargos c WHERE c.nome = 'Secretário Escolar'
    LOOP
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'gestao-escolar', 'ver'),
            (v_cargo_id, 'gestao-escolar', 'relatorios'),
            (v_cargo_id, 'gestao-escolar', 'gerir_alunos'),
            (v_cargo_id, 'gestao-escolar', 'gerir_matriculas'),
            (v_cargo_id, 'gestao-escolar', 'gerir_propinas')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Bibliotecário
    FOR v_cargo_id IN
        SELECT c.id FROM auth.cargos c WHERE c.nome = 'Bibliotecário'
    LOOP
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'gestao-escolar', 'ver'),
            (v_cargo_id, 'gestao-escolar', 'gerir_biblioteca')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Professor
    FOR v_cargo_id IN
        SELECT c.id FROM auth.cargos c WHERE c.nome = 'Professor'
    LOOP
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'gestao-escolar', 'ver'),
            (v_cargo_id, 'gestao-escolar', 'gerir_presencas'),
            (v_cargo_id, 'gestao-escolar', 'lancar_notas')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Director de Turma
    FOR v_cargo_id IN
        SELECT c.id FROM auth.cargos c WHERE c.nome = 'Director de Turma'
    LOOP
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'gestao-escolar', 'ver'),
            (v_cargo_id, 'gestao-escolar', 'gerir_presencas'),
            (v_cargo_id, 'gestao-escolar', 'lancar_notas'),
            (v_cargo_id, 'gestao-escolar', 'gerir_ocorrencias')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Coordenador de Disciplina
    FOR v_cargo_id IN
        SELECT c.id FROM auth.cargos c WHERE c.nome = 'Coordenador de Disciplina'
    LOOP
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'gestao-escolar', 'ver'),
            (v_cargo_id, 'gestao-escolar', 'relatorios'),
            (v_cargo_id, 'gestao-escolar', 'gerir_presencas'),
            (v_cargo_id, 'gestao-escolar', 'lancar_notas')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Coordenador de Ciclo
    FOR v_cargo_id IN
        SELECT c.id FROM auth.cargos c WHERE c.nome = 'Coordenador de Ciclo'
    LOOP
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'gestao-escolar', 'ver'),
            (v_cargo_id, 'gestao-escolar', 'relatorios'),
            (v_cargo_id, 'gestao-escolar', 'gerir_ocorrencias')
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- Chefe de Oficina
    FOR v_cargo_id IN
        SELECT c.id FROM auth.cargos c WHERE c.nome = 'Chefe de Oficina'
    LOOP
        INSERT INTO auth.permissoes_cargo (cargo_id, modulo, acao) VALUES
            (v_cargo_id, 'gestao-escolar', 'ver'),
            (v_cargo_id, 'gestao-escolar', 'gerir_presencas'),
            (v_cargo_id, 'gestao-escolar', 'lancar_notas')
        ON CONFLICT DO NOTHING;
    END LOOP;

END $$;
