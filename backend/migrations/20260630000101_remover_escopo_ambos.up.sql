-- Remove o escopo legado 'ambos'. A partir desta migracao, funcionario
-- pertence ao painel ERP ou ao painel escolar, nunca aos dois ao mesmo tempo.

UPDATE auth.memberships m
   SET escopo = 'escola',
       updated_at = NOW()
 WHERE EXISTS (
       SELECT 1
         FROM auth.users u
         LEFT JOIN auth.cargos c ON c.id = m.cargo_id
         LEFT JOIN saas.tenants t ON t.id = m.tenant_id
        WHERE u.id = m.user_id
          AND (
               u.email = 'admin@enigmaschool.mz'
               OR u.email = 'escola_teste@nexora.test'
               OR c.nome ILIKE '%Escolar%'
               OR t.nome ILIKE '%Instituto%'
          )
   )
   AND m.escopo = 'ambos'
;

UPDATE auth.memberships
   SET escopo = 'erp',
       updated_at = NOW()
 WHERE escopo = 'ambos';

UPDATE auth.users
   SET nome = 'Teste ERP 2',
       email = 'erp2_teste@nexora.test',
       updated_at = NOW()
 WHERE email = 'ambos_teste@nexora.test';

ALTER TABLE auth.memberships
  DROP CONSTRAINT IF EXISTS memberships_escopo_check;

ALTER TABLE auth.memberships
  ADD CONSTRAINT memberships_escopo_check
  CHECK (escopo IN ('erp', 'escola'));
