CREATE SCHEMA IF NOT EXISTS rh;
SET search_path TO rh, public;

-- Modulo de Recursos Humanos para PostgreSQL
-- Responsavel por: departamentos, funcionarios, contratos, ausencias/ferias e avaliacoes de desempenho

CREATE TABLE IF NOT EXISTS departamentos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    responsavel_id BIGINT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_departamentos_tenant_codigo UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS funcionarios (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    department_id BIGINT,
    numero_funcionario VARCHAR(30),
    nome_completo VARCHAR(150) NOT NULL,
    data_nascimento DATE,
    genero VARCHAR(10) CHECK (genero IN ('M', 'F', 'outro')),
    nuit VARCHAR(30),
    telefone VARCHAR(30),
    email VARCHAR(150),
    endereco TEXT,
    cargo VARCHAR(120),
    data_admissao DATE NOT NULL DEFAULT CURRENT_DATE,
    data_saida DATE,
    tipo_contrato VARCHAR(30) NOT NULL DEFAULT 'efetivo'
        CHECK (tipo_contrato IN ('efetivo', 'termo_certo', 'termo_incerto', 'estagio', 'prestacao_servico')),
    salario_base NUMERIC(14,2),
    estado VARCHAR(20) NOT NULL DEFAULT 'ativo'
        CHECK (estado IN ('ativo', 'suspenso', 'licenca', 'desligado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_funcionarios_departamento FOREIGN KEY (department_id) REFERENCES departamentos(id) ON DELETE SET NULL
);

ALTER TABLE departamentos
    ADD CONSTRAINT fk_departamentos_responsavel FOREIGN KEY (responsavel_id) REFERENCES funcionarios(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS contratos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL
        CHECK (tipo IN ('efetivo', 'termo_certo', 'termo_incerto', 'estagio', 'prestacao_servico')),
    funcao VARCHAR(120),
    data_inicio DATE NOT NULL,
    data_fim DATE,
    salario NUMERIC(14,2),
    ficheiro_url TEXT,
    estado VARCHAR(20) NOT NULL DEFAULT 'ativo'
        CHECK (estado IN ('ativo', 'encerrado', 'rescindido')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_contratos_funcionario FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ausencias (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL
        CHECK (tipo IN ('ferias', 'doenca', 'licenca_maternidade', 'licenca_paternidade', 'luto', 'injustificada', 'outro')),
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    dias INTEGER,
    motivo TEXT,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendente'
        CHECK (estado IN ('pendente', 'aprovado', 'rejeitado')),
    aprovado_por BIGINT,
    aprovado_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- aprovado_por referencia auth.users (sem FK)
    CONSTRAINT fk_ausencias_funcionario FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS avaliacoes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    funcionario_id BIGINT NOT NULL,
    periodo VARCHAR(30) NOT NULL,
    avaliador_id BIGINT,
    pontuacao NUMERIC(4,2),
    comentarios TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- avaliador_id referencia auth.users (sem FK)
    CONSTRAINT fk_avaliacoes_funcionario FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_departamentos_tenant_id ON departamentos (tenant_id);
CREATE INDEX IF NOT EXISTS idx_funcionarios_tenant_id ON funcionarios (tenant_id);
CREATE INDEX IF NOT EXISTS idx_funcionarios_department_id ON funcionarios (department_id);
CREATE INDEX IF NOT EXISTS idx_contratos_tenant_id ON contratos (tenant_id);
CREATE INDEX IF NOT EXISTS idx_contratos_funcionario_id ON contratos (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_ausencias_tenant_id ON ausencias (tenant_id);
CREATE INDEX IF NOT EXISTS idx_ausencias_funcionario_id ON ausencias (funcionario_id);
CREATE INDEX IF NOT EXISTS idx_ausencias_estado ON ausencias (estado);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_tenant_id ON avaliacoes (tenant_id);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_funcionario_id ON avaliacoes (funcionario_id);
