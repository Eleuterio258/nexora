-- Permissões padrão por tipo de utilizador.
-- Qualquer utilizador desse tipo herda estas permissões no login,
-- para além das do cargo e das directas.

CREATE TABLE IF NOT EXISTS auth.permissoes_tipo (
    id      BIGSERIAL PRIMARY KEY,
    tipo    TEXT NOT NULL,
    modulo  TEXT NOT NULL,
    acao    TEXT NOT NULL,
    CONSTRAINT uq_permissoes_tipo UNIQUE (tipo, modulo, acao)
);

CREATE INDEX IF NOT EXISTS idx_permissoes_tipo_tipo ON auth.permissoes_tipo (tipo);

-- Permissões padrão para funcionários: self-service de pedido de férias
INSERT INTO auth.permissoes_tipo (tipo, modulo, acao) VALUES
    ('funcionario', 'pedido-ferias', 'ver'),
    ('funcionario', 'pedido-ferias', 'criar')
ON CONFLICT DO NOTHING;
