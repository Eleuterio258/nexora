CREATE TABLE roles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    descricao TEXT,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE permissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT UNIQUE NOT NULL,
    recurso TEXT NOT NULL,
    acao TEXT NOT NULL,
    descricao TEXT,
    UNIQUE(recurso, acao)
);

CREATE TABLE role_permissions (
    role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
    permission_id INTEGER REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
    role_id INTEGER REFERENCES roles(id),
    nome TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    senha_hash TEXT NOT NULL,
    telefone TEXT,
    ativo INTEGER DEFAULT 1,
    ultimo_login DATETIME,
    tentativas_falhas INTEGER DEFAULT 0,
    bloqueado_ate DATETIME,
    criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
