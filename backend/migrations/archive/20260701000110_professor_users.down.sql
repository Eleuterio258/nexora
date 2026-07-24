-- Reverter migration 110

SET search_path TO auth, gestao_escolar, public;

-- Reverter escopo de portal_professor para escola
UPDATE auth.memberships m
   SET escopo = 'escola', updated_at = NOW()
  FROM gestao_escolar.school_teachers t
  JOIN auth.users u ON u.id = t.user_id
 WHERE m.user_id = u.id
   AND m.escopo  = 'portal_professor';

-- Desligar school_teachers criados por esta migration (user_id que só existem pela migration)
-- (conservador: não apaga utilizadores que possam ter outros papéis)
