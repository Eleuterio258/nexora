CREATE TABLE fornecedores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    contato TEXT,
    telefone TEXT,
    email TEXT,
    endereco TEXT,
    nif TEXT,
    ativo INTEGER DEFAULT 1,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE compras (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
    fornecedor_id INTEGER REFERENCES fornecedores(id),
    user_id INTEGER REFERENCES users(id),
    total REAL NOT NULL,
    status TEXT DEFAULT 'pendente',
    data_compra DATE,
    observacoes TEXT,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE compra_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    compra_id INTEGER REFERENCES compras(id) ON DELETE CASCADE,
    produto_id INTEGER REFERENCES produtos(id),
    quantidade REAL NOT NULL,
    preco_unitario REAL NOT NULL,
    total REAL NOT NULL,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);
