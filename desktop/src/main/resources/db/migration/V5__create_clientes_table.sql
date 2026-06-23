CREATE TABLE clientes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
    codigo TEXT UNIQUE,
    nome TEXT NOT NULL,
    email TEXT,
    telefone TEXT,
    nif TEXT,
    endereco TEXT,
    limite_credito REAL DEFAULT 0,
    credito_usado REAL DEFAULT 0,
    pontos_fidelidade INTEGER DEFAULT 0,
    tipo_preco TEXT DEFAULT 'normal',
    ativo INTEGER DEFAULT 1,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);
