CREATE TABLE pagamentos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    venda_id INTEGER REFERENCES vendas(id) ON DELETE CASCADE,
    metodo TEXT NOT NULL,
    valor REAL NOT NULL,
    referencia TEXT,
    transacao_id TEXT,
    status TEXT DEFAULT 'pendente',
    processado_em DATETIME,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pagamentos_venda ON pagamentos(venda_id);
