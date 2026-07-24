-- ============================================================
-- Migration 091: Classificar utilizadores existentes por escopo
-- ============================================================
-- Após a introdução da coluna auth.users.escopo (default 'erp'),
-- esta migration classifica os utilizadores existentes com base
-- nas permissões reais que têm (cargo + permissões directas).
--
-- Regras:
--   - Apenas gestao-escolar                -> 'escola'
--   - gestao-escolar + módulos ERP         -> 'ambos'
--   - Sem gestao-escolar                   -> 'erp'
--   - Superadmins e contas já classificadas -> ignorados
-- ============================================================

SET search_path TO auth, public;

DO $$
DECLARE
    v_user_id BIGINT;
    v_modulos TEXT[];
    v_escopo TEXT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'escopo'
    ) THEN
        RETURN;
    END IF;

    FOR v_user_id IN
        SELECT u.id
          FROM auth.users u
          JOIN auth.memberships m ON m.user_id = u.id AND m.ativo = TRUE
         WHERE u.tipo = 'funcionario'
           AND (u.escopo IS NULL OR u.escopo = '' OR u.escopo = 'erp')
    LOOP
        SELECT ARRAY_AGG(DISTINCT modulo) INTO v_modulos
          FROM (
              SELECT pc.modulo
                FROM auth.permissoes_cargo pc
                JOIN auth.memberships m ON m.cargo_id = pc.cargo_id
               WHERE m.user_id = v_user_id
              UNION
              SELECT pd.modulo
                FROM auth.permissoes_diretas pd
               WHERE pd.user_id = v_user_id
          ) AS mods;

        IF v_modulos IS NULL THEN
            v_escopo := 'erp';
        ELSIF v_modulos = ARRAY['gestao-escolar'] THEN
            v_escopo := 'escola';
        ELSIF 'gestao-escolar' = ANY(v_modulos) THEN
            v_escopo := 'ambos';
        ELSE
            v_escopo := 'erp';
        END IF;

        UPDATE auth.users
           SET escopo = v_escopo,
               updated_at = NOW()
         WHERE id = v_user_id;
    END LOOP;
END $$;
