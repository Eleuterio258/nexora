-- ============================================================
-- Migration 089: Utilizadores de teste para separação ERP/Escola
-- ============================================================
-- Cria contas de teste com escopos distintos, todas com cargo
-- Administrador, para validar a separação independentemente das
-- permissões de cargo.
--
-- Credenciais:  email@nexora.test  /  1234567890
-- ============================================================

SET search_path TO auth, public;

DO $$
DECLARE
    v_tenant_id BIGINT := 1;
    v_admin_cargo_id BIGINT;
    v_user_id BIGINT;
    v_hash TEXT := '$2a$10$.PIscVrYMQhcQ03VxXIK4OqItZRiy6KtoymlPHoUsOcdbWblhV9CG'; -- 1234567890
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'memberships') THEN
        RETURN;
    END IF;

    -- Cargo Administrador do tenant 1
    SELECT c.id INTO v_admin_cargo_id
      FROM auth.cargos c
     WHERE c.tenant_id = v_tenant_id AND c.nome = 'Administrador'
     LIMIT 1;

    IF v_admin_cargo_id IS NULL THEN
        RETURN;
    END IF;

    -- 1. Utilizador ERP puro
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'erp_teste@nexora.test') THEN
        INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo, escopo)
        VALUES ('Teste ERP', 'erp_teste@nexora.test', v_hash, '+258000000001', 'ativo', TRUE, 'funcionario', 'erp')
        RETURNING id INTO v_user_id;

        INSERT INTO auth.memberships (user_id, tenant_id, cargo_id, ativo)
        VALUES (v_user_id, v_tenant_id, v_admin_cargo_id, TRUE);
    END IF;

    -- 2. Utilizador Escola pura
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'escola_teste@nexora.test') THEN
        INSERT INTO auth.users (nome, email, password_hash, telefone, estado, email_verificado, tipo, escopo)
        VALUES ('Teste Escola', 'escola_teste@nexora.test', v_hash, '+258000000002', 'ativo', TRUE, 'funcionario', 'escola')
        RETURNING id INTO v_user_id;

        INSERT INTO auth.memberships (user_id, tenant_id, cargo_id, ativo)
        VALUES (v_user_id, v_tenant_id, v_admin_cargo_id, TRUE);
    END IF;

END $$;
