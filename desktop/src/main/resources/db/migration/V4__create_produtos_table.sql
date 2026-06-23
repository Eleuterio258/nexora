CREATE TABLE produtos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
    categoria_id INTEGER REFERENCES categorias(id) ON DELETE SET NULL,
    codigo_barras TEXT UNIQUE,
    sku TEXT,
    nome TEXT NOT NULL,
    descricao TEXT,
    preco_compra REAL DEFAULT 0,
    preco_venda REAL NOT NULL,
    preco_promocao REAL,
    stock_atual INTEGER DEFAULT 0,
    stock_minimo INTEGER DEFAULT 5,
    unidade_medida TEXT DEFAULT 'un',
    validade DATE,
    imagem_url TEXT,
    composto INTEGER DEFAULT 0,
    ativo INTEGER DEFAULT 1,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_produtos_codigo ON produtos(codigo_barras);
CREATE INDEX idx_produtos_nome ON produtos(nome);
