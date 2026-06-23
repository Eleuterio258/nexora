CREATE TABLE stock_movimentos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    produto_id INTEGER REFERENCES produtos(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL,
    quantidade REAL NOT NULL,
    motivo TEXT,
    referencia TEXT,
    user_id INTEGER REFERENCES users(id),
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_stock_produto ON stock_movimentos(produto_id);
