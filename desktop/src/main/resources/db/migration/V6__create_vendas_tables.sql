CREATE TABLE vendas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id),
    cliente_id INTEGER REFERENCES clientes(id) ON DELETE SET NULL,
    terminal TEXT,
    subtotal REAL NOT NULL,
    desconto REAL DEFAULT 0,
    imposto REAL DEFAULT 0,
    total REAL NOT NULL,
    metodo_pagamento TEXT,
    status TEXT DEFAULT 'aberta',
    tipo_documento TEXT DEFAULT 'fatura',
    serie_documento TEXT,
    numero_documento INTEGER,
    referencia TEXT,
    observacoes TEXT,
    cancelada_por INTEGER REFERENCES users(id),
    cancelada_motivo TEXT,
    cancelada_em DATETIME,
    criada_em DATETIME DEFAULT CURRENT_TIMESTAMP,
    atualizada_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE venda_itens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    venda_id INTEGER REFERENCES vendas(id) ON DELETE CASCADE,
    produto_id INTEGER REFERENCES produtos(id),
    quantidade REAL NOT NULL,
    preco_unitario REAL NOT NULL,
    desconto REAL DEFAULT 0,
    total REAL NOT NULL,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_vendas_data ON vendas(criada_em DESC);
CREATE INDEX idx_vendas_status ON vendas(status);
CREATE INDEX idx_venda_itens_venda ON venda_itens(venda_id);
