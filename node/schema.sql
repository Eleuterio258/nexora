CREATE TABLE IF NOT EXISTS clientes (
    id           SERIAL PRIMARY KEY,
    nome         TEXT NOT NULL,
    api_key      TEXT NOT NULL UNIQUE,
    activo       BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS envios (
    id           BIGSERIAL PRIMARY KEY,
    cliente_id   INTEGER REFERENCES clientes(id),
    destinatario TEXT NOT NULL,
    assunto      TEXT NOT NULL,
    estado       TEXT NOT NULL CHECK (estado IN ('enviado', 'falhou')),
    erro         TEXT,
    message_id   TEXT,
    criado_em    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_envios_cliente_id ON envios(cliente_id);
CREATE INDEX IF NOT EXISTS idx_envios_criado_em ON envios(criado_em);
