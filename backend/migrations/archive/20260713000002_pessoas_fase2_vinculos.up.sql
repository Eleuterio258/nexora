-- Migration: Fase 2 do modelo Pessoa central - normalizacao dos vinculos
-- Ver docs/analise-modelo-pessoa-multi-tenant.md (seccao 6, Fase 2).
--
-- Objectivo: permitir que um utilizador (e, por extensao, uma pessoa) tenha
-- MAIS DE UM vinculo user-tenant-papel. Ate aqui, auth.memberships tinha
-- UNIQUE(user_id), o que limitava qualquer pessoa a um unico tenant.
--
-- Seguranca da migracao: hoje, TODOS os utilizadores tem exactamente 1
-- membership (era garantido pela propria UNIQUE(user_id) que estamos a
-- remover). Esta migration nao insere nenhum vinculo novo - so alarga o
-- que a base de dados PERMITE. O backend Go continua, por agora, a
-- assumir 1 membership por user (LEFT JOIN sem agregacao em rbac.go,
-- middleware/auth.go, auth.go) - com os dados actuais isso continua a
-- devolver no maximo 1 linha por user, por isso nada quebra. Passar a
-- criar vinculos multiplos de facto so deve acontecer depois do refactor
-- do backend (Fase 3), que ainda nao foi feito.

-- ============================================================
-- 1. auth.memberships: permitir multiplos vinculos por user
-- ============================================================
ALTER TABLE auth.memberships
    DROP CONSTRAINT IF EXISTS memberships_user_id_key;

-- papel de negocio deste vinculo (funcionario/aluno/encarregado/candidato/
-- superadmin) - hoje vive em auth.users.tipo (global, unico). Passa a
-- existir tambem por vinculo, para no futuro (Fase 3) um mesmo user poder
-- ter papeis diferentes em tenants diferentes (ou no mesmo tenant, com
-- escopos diferentes). auth.users.tipo mantem-se por agora como coluna
-- legado - a Fase 3 e que decide se e substituida ou so passa a derivada.
ALTER TABLE auth.memberships
    ADD COLUMN IF NOT EXISTS papel VARCHAR(20);

UPDATE auth.memberships m
   SET papel = u.tipo
  FROM auth.users u
 WHERE u.id = m.user_id AND m.papel IS NULL;

ALTER TABLE auth.memberships
    ADD CONSTRAINT memberships_papel_check
    CHECK (papel IS NULL OR papel IN ('superadmin','funcionario','aluno','encarregado','candidato'));

ALTER TABLE auth.memberships
    ADD COLUMN IF NOT EXISTS data_inicio DATE,
    ADD COLUMN IF NOT EXISTS data_fim    DATE;

UPDATE auth.memberships SET data_inicio = created_at::date WHERE data_inicio IS NULL;

ALTER TABLE auth.memberships
    ALTER COLUMN data_inicio SET NOT NULL,
    ALTER COLUMN data_inicio SET DEFAULT CURRENT_DATE;

-- Chave de unicidade nova: um user pode ter varios vinculos, mas nao dois
-- identicos (mesmo tenant + mesmo escopo + mesmo papel). Inclui "papel" e
-- nao so "escopo" porque, nos dados reais, aluno e encarregado partilham
-- escopo='escola' - sem "papel" na chave, o proprio cenario "pessoa e
-- aluno e encarregado no mesmo tenant" ficaria bloqueado outra vez.
ALTER TABLE auth.memberships
    ADD CONSTRAINT uq_memberships_user_tenant_escopo_papel UNIQUE (user_id, tenant_id, escopo, papel);

-- ============================================================
-- 2. auth.permissoes_diretas: permissoes directas passam a ser por tenant
-- ============================================================
ALTER TABLE auth.permissoes_diretas
    ADD COLUMN IF NOT EXISTS tenant_id BIGINT REFERENCES saas.tenants(id) ON DELETE CASCADE;

-- Backfill: cada permissao directa existente aplica-se ao tenant do
-- (unico, ate agora) vinculo desse user.
UPDATE auth.permissoes_diretas pd
   SET tenant_id = m.tenant_id
  FROM auth.memberships m
 WHERE m.user_id = pd.user_id AND pd.tenant_id IS NULL;

ALTER TABLE auth.permissoes_diretas
    DROP CONSTRAINT IF EXISTS permissoes_diretas_user_id_modulo_acao_key;

ALTER TABLE auth.permissoes_diretas
    ADD CONSTRAINT uq_permissoes_diretas_user_tenant_modulo_acao UNIQUE (user_id, tenant_id, modulo, acao);

CREATE INDEX IF NOT EXISTS idx_permissoes_diretas_tenant_id ON auth.permissoes_diretas(tenant_id);

-- ============================================================
-- 3. View: todos os papeis/vinculos de uma pessoa (multi-tenant)
-- ============================================================
CREATE OR REPLACE VIEW pessoas.v_pessoa_papeis AS
SELECT
    p.id            AS pessoa_id,
    p.nome_completo,
    u.id            AS user_id,
    u.email,
    m.id            AS membership_id,
    m.tenant_id,
    t.nome          AS tenant_nome,
    m.papel,
    m.escopo,
    m.cargo_id,
    c.nome          AS cargo_nome,
    m.ativo,
    m.data_inicio,
    m.data_fim
FROM auth.memberships m
JOIN auth.users u   ON u.id = m.user_id
JOIN pessoas.pessoas p ON p.id = u.pessoa_id
JOIN saas.tenants t ON t.id = m.tenant_id
LEFT JOIN auth.cargos c ON c.id = m.cargo_id;
