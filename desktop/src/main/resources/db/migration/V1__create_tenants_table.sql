CREATE TABLE tenants (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo TEXT UNIQUE NOT NULL,
    nome TEXT NOT NULL,
    nif TEXT,
    email TEXT,
    telefone TEXT,
    endereco TEXT,
    configuracao TEXT DEFAULT '{}',
    ativo INTEGER DEFAULT 1,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);
