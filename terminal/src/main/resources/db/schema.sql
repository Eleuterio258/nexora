CREATE TABLE IF NOT EXISTS employee (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    numero TEXT NOT NULL UNIQUE,
    nome TEXT NOT NULL,
    departamento TEXT,
    pin_hash TEXT,
    qr_code_token TEXT UNIQUE,
    qr_totp_secret TEXT,
    fingerprint_template TEXT,
    nfc_uid TEXT,
    ativo INTEGER DEFAULT 1,
    criado_em TEXT DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TEXT DEFAULT CURRENT_TIMESTAMP
);

-- nfc_uid acima só se aplica a bases de dados novas. DatabaseManager.migrateSchema()
-- adiciona a coluna (e o índice) a bases de dados já existentes que não a têm,
-- porque "ALTER TABLE ... ADD COLUMN IF NOT EXISTS" não é sintaxe válida em SQLite.

CREATE TABLE IF NOT EXISTS registo_ponto (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    employee_numero TEXT NOT NULL,
    employee_nome TEXT,
    tipo TEXT NOT NULL,
    metodo TEXT NOT NULL,
    data_hora TEXT DEFAULT CURRENT_TIMESTAMP,
    sincronizado INTEGER DEFAULT 0,
    observacao TEXT,
    FOREIGN KEY (employee_id) REFERENCES employee(id)
);

CREATE INDEX IF NOT EXISTS idx_registo_data ON registo_ponto(data_hora);
CREATE INDEX IF NOT EXISTS idx_registo_employee ON registo_ponto(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_numero ON employee(numero);

-- Definições editáveis a partir do ecrã "Configurações" do admin (ex.: api.base.url,
-- api.device.key) — sobrepõem-se aos valores de application.properties quando presentes.
CREATE TABLE IF NOT EXISTS configuracao (
    chave TEXT PRIMARY KEY,
    valor TEXT
);
