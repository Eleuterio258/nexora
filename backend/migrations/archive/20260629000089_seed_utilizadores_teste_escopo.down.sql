-- ============================================================
-- Down migration 089: remove os utilizadores de teste criados
-- ============================================================

SET search_path TO auth, public;

DELETE FROM auth.sessions
 WHERE user_id IN (
     SELECT id FROM auth.users
      WHERE email IN ('erp_teste@nexora.test', 'escola_teste@nexora.test', 'ambos_teste@nexora.test')
 );

DELETE FROM auth.memberships
 WHERE user_id IN (
     SELECT id FROM auth.users
      WHERE email IN ('erp_teste@nexora.test', 'escola_teste@nexora.test', 'ambos_teste@nexora.test')
 );

DELETE FROM auth.users
 WHERE email IN ('erp_teste@nexora.test', 'escola_teste@nexora.test', 'ambos_teste@nexora.test');
