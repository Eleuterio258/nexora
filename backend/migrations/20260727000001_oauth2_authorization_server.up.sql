-- Authorization Server OAuth 2.0 dentro do ERP — substitui o mecanismo actual
-- (JWT HS256 partilhado + auth.sessions + GatewayValidate) por um modelo
-- standard com client registry, tokens RS256 e scopes = permissões RBAC.
-- Ver plano em C:\Users\Eleuterio\.claude\plans\whimsical-napping-stearns.md.
--
-- hardware.devices e auth.api_keys NÃO migram para este registry (decisão
-- explícita — ver secção "Decisões de âmbito" do plano). auth.api_keys é
-- removida à parte, na fase de limpeza.

-- Registo de clientes OAuth2 — pequeno e global (dezena de linhas, não por
-- tenant): as aplicações que consomem o Authorization Server, não os
-- utilizadores finais nem os dispositivos físicos.
CREATE TABLE IF NOT EXISTS auth.oauth_clients (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id VARCHAR(60) NOT NULL UNIQUE,
    client_secret_hash TEXT,
    client_type VARCHAR(20) NOT NULL
        CHECK (client_type IN ('confidential','public')),
    nome VARCHAR(120) NOT NULL,
    grant_types TEXT[] NOT NULL DEFAULT '{}',
    redirect_uris TEXT[] NOT NULL DEFAULT '{}',
    allowed_scopes TEXT[] NOT NULL DEFAULT '{}',
    is_first_party BOOLEAN NOT NULL DEFAULT TRUE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Nota: um client_type='confidential' com client_secret_hash NULL é um
-- estado válido em BD (seed inicial antes do segredo ser gerado/rodado),
-- mas a aplicação deve recusar qualquer grant que exija autenticação de
-- cliente (client_credentials, ou password/authorization_code para um
-- cliente confidencial) enquanto o hash estiver NULL — nunca tratar como
-- "sem segredo = sem autenticação exigida".

-- Códigos de autorização de uso único (fluxo authorization_code + PKCE).
-- Vida muito curta (60-120s) — limpar periodicamente linhas expiradas.
CREATE TABLE IF NOT EXISTS auth.oauth_authorization_codes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code_hash VARCHAR(64) NOT NULL UNIQUE,
    client_id BIGINT NOT NULL REFERENCES auth.oauth_clients(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL,
    membership_id BIGINT NOT NULL DEFAULT 0,
    redirect_uri TEXT NOT NULL,
    scope TEXT NOT NULL DEFAULT '',
    code_challenge VARCHAR(128) NOT NULL,
    code_challenge_method VARCHAR(10) NOT NULL DEFAULT 'S256'
        CHECK (code_challenge_method = 'S256'),
    expira_em TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_oauth_authorization_codes_expira
    ON auth.oauth_authorization_codes (expira_em);

-- Refresh tokens — consolida sessions/portal_sessions/guardian_portal_sessions/
-- candidato_sessions num único modelo com rotation (family_id constante ao
-- longo da cadeia; reuse de um token já revogado revoga a família inteira).
CREATE TABLE IF NOT EXISTS auth.oauth_refresh_tokens (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    client_id BIGINT NOT NULL REFERENCES auth.oauth_clients(id) ON DELETE CASCADE,
    subject_type VARCHAR(20) NOT NULL
        CHECK (subject_type IN ('funcionario','superadmin','aluno','encarregado','candidato','client')),
    subject_id BIGINT NOT NULL,
    membership_id BIGINT NOT NULL DEFAULT 0,
    scope TEXT NOT NULL DEFAULT '',
    family_id UUID NOT NULL,
    parent_id BIGINT REFERENCES auth.oauth_refresh_tokens(id) ON DELETE SET NULL,
    revoked_at TIMESTAMPTZ,
    expira_em TIMESTAMPTZ NOT NULL,
    ip_address VARCHAR(64),
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_oauth_refresh_tokens_family
    ON auth.oauth_refresh_tokens (family_id);
CREATE INDEX IF NOT EXISTS idx_oauth_refresh_tokens_subject
    ON auth.oauth_refresh_tokens (subject_type, subject_id);

-- Denylist curta de access tokens revogados antes do exp natural (logout,
-- mudança de password, bloqueio de conta). Só consultada pelo próprio
-- RequireAuth do ERP (tem BD local) — nunca pelo FaceClock/Android via rede,
-- que verificam o JWT localmente via JWKS sem round-trip.
CREATE TABLE IF NOT EXISTS auth.oauth_access_token_revocations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    jti VARCHAR(64) NOT NULL UNIQUE,
    subject_id BIGINT NOT NULL,
    revogado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expira_em TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_oauth_access_token_revocations_expira
    ON auth.oauth_access_token_revocations (expira_em);

-- Seed dos clientes reais. client_secret_hash preenchido à parte (fora desta
-- migration, nunca em texto plano no controlo de versões) via UPDATE manual
-- ou variável de ambiente lida no arranque — ver internal/modules/auth/oauthkeys.
INSERT INTO auth.oauth_clients
    (client_id, client_secret_hash, client_type, nome, grant_types, redirect_uris, allowed_scopes, is_first_party)
VALUES
    ('web-erp', NULL, 'confidential', 'Portal Web do ERP (PHP, backend-for-frontend)',
        ARRAY['password','refresh_token','authorization_code'], ARRAY[]::text[], ARRAY[]::text[], TRUE),
    ('android-app', NULL, 'public', 'App Android nexora_assiduidade',
        ARRAY['password','refresh_token','authorization_code'], ARRAY[]::text[], ARRAY[]::text[], TRUE),
    ('smoke-test', NULL, 'confidential', 'Cliente de validação do fluxo /oauth/authorize (dev/staging apenas)',
        ARRAY['authorization_code','refresh_token'], ARRAY['http://localhost:4000/callback'], ARRAY[]::text[], TRUE)
ON CONFLICT (client_id) DO NOTHING;
