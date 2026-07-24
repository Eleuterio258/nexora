-- ============================================================
-- Migration 066: Permissões padrão do módulo Gestão Escolar
-- ============================================================
-- Alinha as permissões em auth.permissoes_tipo com as acções reais
-- exigidas por backend/internal/router/router.go em /api/escolar.
--
-- Nota: o acesso de professores é gerido pelo cargo "Professor"
-- (auth.cargos / auth.permissoes_cargo), não pelo tipo de utilizador,
-- uma vez que auth.users.tipo só admite 'superadmin' e 'funcionario'.
-- ============================================================

SET search_path TO auth, public;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'permissoes_tipo') THEN
        RETURN;
    END IF;

    -- ============================================================
    -- 1. Remover permissões escolares desactualizadas/inválidas
    -- ============================================================
    DELETE FROM auth.permissoes_tipo
    WHERE modulo = 'gestao-escolar'
      AND (
          -- Acções antigas ou renomeadas
          acao IN ('ver_escolar', 'gerir_academico', 'gerir_professores', 'gerir_alunos',
                   'gerir_frequencia', 'gerir_avaliacoes', 'gerir_financeiro', 'gerir_horarios',
                   'gerir_biblioteca', 'gerir_comunicacao', 'gerir_ocorrencias',
                   'ver', 'criar', 'editar', 'eliminar', 'apagar', 'gerir', 'gerir_configuracao_escolar')
          -- Tipos de utilizador que já não existem
          OR tipo IN ('tenant_admin', 'professor')
      );

    -- ============================================================
    -- 2. Permissões por tipo válido para fresh installs
    -- ============================================================
    -- superadmin: bypass total; não precisa de entradas.
    -- funcionário: herda permissões de Gestão Escolar via cargo.
    -- Não atribuímos permissões escolares globais a todo o tipo 'funcionario'
    -- para evitar acesso automático indiscriminado.

END $$;
