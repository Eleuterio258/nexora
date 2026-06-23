CREATE TABLE contas_receber (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id INTEGER REFERENCES clientes(id) ON DELETE CASCADE,
    venda_id INTEGER REFERENCES vendas(id),
    valor_total REAL NOT NULL,
    valor_pago REAL DEFAULT 0,
    valor_pendente REAL NOT NULL,
    status TEXT DEFAULT 'pendente',
    data_vencimento DATE,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);
