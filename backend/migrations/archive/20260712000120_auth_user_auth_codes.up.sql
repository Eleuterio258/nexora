CREATE TABLE IF NOT EXISTS auth.user_auth_codes (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tipo varchar(20) NOT NULL CHECK (tipo IN ('pin','totp')),
    secret_hash text NOT NULL,
    ativo boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by bigint REFERENCES auth.users(id),
    revoked_at timestamptz,
    UNIQUE (user_id, tipo)
);

CREATE INDEX IF NOT EXISTS idx_user_auth_codes_user_id ON auth.user_auth_codes(user_id);
