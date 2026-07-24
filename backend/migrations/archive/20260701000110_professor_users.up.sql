-- ============================================================
-- Migration 110: Portal do Professor — utilizadores auth
-- tipo permanece 'funcionario'; escopo='portal_professor' identifica professores
-- ============================================================

SET search_path TO auth, gestao_escolar, saas, public;

-- ── 1. Professores já existentes ligados a school_teachers ────
--    Se estiverem com escopo='escola', mudar para 'portal_professor'
UPDATE auth.memberships m
   SET escopo     = 'portal_professor',
       updated_at = NOW()
  FROM gestao_escolar.school_teachers t
  JOIN auth.users u ON u.id = t.user_id
 WHERE m.user_id = u.id
   AND u.tipo    = 'funcionario'
   AND m.escopo  = 'escola';

-- ── 2. Criar auth.users para teachers sem user_id ────────────
DO $$
DECLARE
    rec    RECORD;
    v_uid  BIGINT;
    v_hash TEXT := '$2a$12$fKX9WLMbacb6XcrLuagGR.4Krl22c4CG8XE0Pc5eF9drEehj9DZn6';
BEGIN
    FOR rec IN
        SELECT t.tenant_id,
               t.id  AS teacher_id,
               t.nome_completo,
               LOWER(TRIM(t.email)) AS email
          FROM gestao_escolar.school_teachers t
         WHERE t.user_id IS NULL
           AND t.email   IS NOT NULL
           AND TRIM(t.email) <> ''
    LOOP
        SELECT id INTO v_uid FROM auth.users WHERE email = rec.email LIMIT 1;

        IF v_uid IS NULL THEN
            INSERT INTO auth.users (nome, email, password_hash, estado, email_verificado, tipo)
            VALUES (rec.nome_completo, rec.email, v_hash, 'ativo', TRUE, 'funcionario')
            RETURNING id INTO v_uid;
        END IF;

        UPDATE gestao_escolar.school_teachers
           SET user_id = v_uid, updated_at = NOW()
         WHERE id = rec.teacher_id;

        IF NOT EXISTS (SELECT 1 FROM auth.memberships WHERE user_id = v_uid AND tenant_id = rec.tenant_id) THEN
            INSERT INTO auth.memberships (user_id, tenant_id, escopo, ativo)
            VALUES (v_uid, rec.tenant_id, 'portal_professor', TRUE);
        ELSE
            UPDATE auth.memberships
               SET escopo = 'portal_professor', updated_at = NOW()
             WHERE user_id = v_uid AND tenant_id = rec.tenant_id AND escopo = 'escola';
        END IF;
    END LOOP;
END $$;
