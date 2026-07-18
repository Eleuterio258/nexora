-- Migration: Fase 4 do modelo Pessoa central - limpeza de legado morto no
-- portal do aluno e do encarregado.
--
-- Ver docs/analise-modelo-pessoa-multi-tenant.md (seccao 6, Fase 4) e o
-- plano em C:\Users\Eleuterio\.claude\plans\fizzy-napping-sifakis.md.
--
-- Contexto: a migration 20260629000096 "unificou" o login dos portais em
-- auth.users, mas os handlers antigos de login directo (que faziam lockout
-- sobre estas colunas) nunca foram removidos do codigo Go - so desligados
-- do router. Confirmado por investigacao exaustiva (3 agentes Explore em
-- paralelo) que estas colunas ja nao tem nenhum escritor vivo no codigo:
--
--   school_students.portal_password_hash    - morta (credenciais em auth.users)
--   school_students.portal_login_tentativas - so escrita pelo handler morto
--   school_students.portal_bloqueado_ate    - so escrita pelo handler morto
--   school_students.portal_ultimo_login     - so escrita pelo handler morto
--     (ou seja: hoje o login real NUNCA regista o ultimo acesso do aluno -
--      confirmado como bug aceite, nao corrigido por decisao do utilizador)
--
--   school_guardians.portal_password_hash    - idem
--   school_guardians.portal_login_tentativas - idem
--   school_guardians.portal_bloqueado_ate    - idem
--   school_guardians.portal_ultimo_login     - idem
--   school_guardians.portal_email_verificado - escrita mas nunca lida
--
-- NAO tocar em portal_email/portal_ativo/portal_invite_token/
-- portal_invite_expires_at (vivas, usadas em cada pedido autenticado pelos
-- middlewares RequireAlunoAuth/RequireEncarregadoAuth e pelo fluxo de
-- convite), nem em gestao_escolar.portal_sessions/guardian_portal_sessions
-- (tabelas de sessao activas e criticas).

ALTER TABLE gestao_escolar.school_students
  DROP COLUMN IF EXISTS portal_password_hash,
  DROP COLUMN IF EXISTS portal_login_tentativas,
  DROP COLUMN IF EXISTS portal_bloqueado_ate,
  DROP COLUMN IF EXISTS portal_ultimo_login;

ALTER TABLE gestao_escolar.school_guardians
  DROP COLUMN IF EXISTS portal_password_hash,
  DROP COLUMN IF EXISTS portal_login_tentativas,
  DROP COLUMN IF EXISTS portal_bloqueado_ate,
  DROP COLUMN IF EXISTS portal_ultimo_login,
  DROP COLUMN IF EXISTS portal_email_verificado;
