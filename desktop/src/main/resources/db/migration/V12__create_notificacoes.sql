CREATE TABLE notificacoes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL,
    titulo TEXT NOT NULL,
    mensagem TEXT NOT NULL,
    lida INTEGER DEFAULT 0,
    lida_em DATETIME,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notificacoes_user ON notificacoes(user_id);
CREATE INDEX idx_notificacoes_lida ON notificacoes(lida);
