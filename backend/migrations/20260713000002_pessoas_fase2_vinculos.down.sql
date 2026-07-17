-- Reverte a Fase 2 do modelo Pessoa central.

DROP VIEW IF EXISTS pessoas.v_pessoa_papeis;

DROP INDEX IF EXISTS auth.idx_permissoes_diretas_tenant_id;
ALTER TABLE auth.permissoes_diretas
    DROP CONSTRAINT IF EXISTS uq_permissoes_diretas_user_tenant_modulo_acao;
ALTER TABLE auth.permissoes_diretas
    ADD CONSTRAINT permissoes_diretas_user_id_modulo_acao_key UNIQUE (user_id, modulo, acao);
ALTER TABLE auth.permissoes_diretas
    DROP COLUMN IF EXISTS tenant_id;

ALTER TABLE auth.memberships
    DROP CONSTRAINT IF EXISTS uq_memberships_user_tenant_escopo_papel;
ALTER TABLE auth.memberships
    DROP COLUMN IF EXISTS data_fim,
    DROP COLUMN IF EXISTS data_inicio;
ALTER TABLE auth.memberships
    DROP CONSTRAINT IF EXISTS memberships_papel_check;
ALTER TABLE auth.memberships
    DROP COLUMN IF EXISTS papel;

-- Restaurar UNIQUE(user_id) so e seguro se, nesse momento, cada user tiver
-- no maximo 1 membership outra vez (caso contrario a constraint falha e
-- e preciso limpar os vinculos extra primeiro).
ALTER TABLE auth.memberships
    ADD CONSTRAINT memberships_user_id_key UNIQUE (user_id);
