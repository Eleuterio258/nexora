-- qr_code_token: QR fixo do funcionário (Modo 1 — crachá impresso ou app Nexo), gerado
-- localmente na criação (EmployeeService.criar) e lido/identificado localmente
-- (QrAuthPanel/AuthService.authenticateByQrToken), sem chamar o ERP. O Modo 2 (QR
-- dinâmico do terminal, QrMostrarPanel) não guarda nada aqui — pede sempre um código
-- novo ao ERP (POST /assiduidade/qr/gerar-terminal).
CREATE TABLE IF NOT EXISTS employee (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    numero TEXT NOT NULL UNIQUE,
    nome TEXT NOT NULL,
    departamento TEXT,
    pin_hash TEXT,
    qr_code_token TEXT UNIQUE,
    fingerprint_template TEXT,
    nfc_uid TEXT,
    ativo INTEGER DEFAULT 1,
    criado_em TEXT DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TEXT DEFAULT CURRENT_TIMESTAMP
);

-- nfc_uid acima só se aplica a bases de dados novas. DatabaseManager.migrateSchema()
-- adiciona a coluna (e o índice) a bases de dados já existentes que não a têm,
-- porque "ALTER TABLE ... ADD COLUMN IF NOT EXISTS" não é sintaxe válida em SQLite.

-- Sem coluna "tipo": o terminal não classifica a marcação como entrada/saída/
-- pausa, só regista o instante — é o ERP que interpreta o papel de cada
-- marcação a partir da sequência do dia (ver PontoService).
CREATE TABLE IF NOT EXISTS registo_ponto (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    employee_numero TEXT NOT NULL,
    employee_nome TEXT,
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
