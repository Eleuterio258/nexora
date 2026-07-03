-- ============================================================
-- Migration 087: Atribuir cargo Administrador a funcionários sem cargo
-- ============================================================
-- Após a remoção do tipo 'tenant_admin' (migration 080), utilizadores
-- desse tipo ficaram como 'funcionario' sem cargo atribuído. Sem cargo,
-- o RBAC não lhes concede permissões, resultando em 403 em quase tudo.
--
-- Esta migration atribui o cargo "Administrador" aos funcionários
-- activos que não tenham cargo, para cada tenant existente.
-- ============================================================

SET search_path TO auth, public;

DO $$
DECLARE
    rec RECORD;
    v_admin_id BIGINT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'memberships')
       OR NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'cargos')
    THEN
        RETURN;
    END IF;

    FOR rec IN
        SELECT DISTINCT m.tenant_id
          FROM auth.memberships m
          JOIN auth.users u ON u.id = m.user_id
         WHERE m.cargo_id IS NULL
           AND m.ativo = TRUE
           AND u.tipo = 'funcionario'
    LOOP
        SELECT c.id INTO v_admin_id
          FROM auth.cargos c
         WHERE c.tenant_id = rec.tenant_id
           AND c.nome = 'Administrador'
         LIMIT 1;

        IF v_admin_id IS NOT NULL THEN
            UPDATE auth.memberships m
               SET cargo_id = v_admin_id,
                   updated_at = NOW()
              FROM auth.users u
             WHERE m.user_id = u.id
               AND m.tenant_id = rec.tenant_id
               AND m.cargo_id IS NULL
               AND m.ativo = TRUE
               AND u.tipo = 'funcionario';
        END IF;
    END LOOP;
END $$;
