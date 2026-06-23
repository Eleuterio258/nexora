CREATE TABLE auditoria_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    acao TEXT NOT NULL,
    recurso TEXT NOT NULL,
    recurso_id INTEGER,
    descricao TEXT,
    ip_address TEXT,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_auditoria_user ON auditoria_logs(user_id);
CREATE INDEX idx_auditoria_data ON auditoria_logs(criado_em);
