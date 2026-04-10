CREATE TABLE IF NOT EXISTS hr_departments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_hr_departments UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS employees (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    department_id BIGINT,
    user_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150),
    telefone VARCHAR(30),
    nuit VARCHAR(30),
    data_nascimento DATE,
    data_admissao DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (estado IN ('ativo','suspenso','desligado')),
    cargo VARCHAR(120) NOT NULL,
    tipo_contrato VARCHAR(20) NOT NULL DEFAULT 'efectivo' CHECK (tipo_contrato IN ('efectivo','prazo_certo','prestador','estagiario')),
    salario_base NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (salario_base >= 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_employees_tenant_codigo UNIQUE (tenant_id, codigo),
    CONSTRAINT uq_employees_tenant_nuit UNIQUE NULLS NOT DISTINCT (tenant_id, nuit),
    CONSTRAINT fk_employees_department FOREIGN KEY (department_id) REFERENCES hr_departments(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS employee_bank_accounts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    banco VARCHAR(120) NOT NULL,
    numero_conta VARCHAR(60) NOT NULL,
    nib VARCHAR(60),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    principal BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_bank_accounts_employee FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS payroll_periods (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ano INTEGER NOT NULL,
    mes INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto','fechado')),
    fechado_em TIMESTAMPTZ,
    fechado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payroll_periods UNIQUE (tenant_id, ano, mes)
);

CREATE TABLE IF NOT EXISTS payroll_runs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    payroll_period_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    processamento_em DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'processado' CHECK (status IN ('processado','aprovado','cancelado')),
    total_bruto NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_descontos NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_liquido NUMERIC(18,2) NOT NULL DEFAULT 0,
    criado_por BIGINT,
    aprovado_por BIGINT,
    aprovado_em TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payroll_runs UNIQUE (tenant_id, numero),
    CONSTRAINT fk_payroll_runs_period FOREIGN KEY (payroll_period_id) REFERENCES payroll_periods(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS payroll_run_lines (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payroll_run_id BIGINT NOT NULL,
    employee_id BIGINT NOT NULL,
    salario_base NUMERIC(18,2) NOT NULL DEFAULT 0,
    adicionais NUMERIC(18,2) NOT NULL DEFAULT 0,
    descontos NUMERIC(18,2) NOT NULL DEFAULT 0,
    bruto NUMERIC(18,2) NOT NULL DEFAULT 0,
    liquido NUMERIC(18,2) NOT NULL DEFAULT 0,
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payroll_run_employee UNIQUE (payroll_run_id, employee_id),
    CONSTRAINT fk_payroll_run_lines_run FOREIGN KEY (payroll_run_id) REFERENCES payroll_runs(id) ON DELETE CASCADE,
    CONSTRAINT fk_payroll_run_lines_employee FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_hr_departments_tenant ON hr_departments (tenant_id);
CREATE INDEX IF NOT EXISTS idx_employees_tenant ON employees (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_employees_department ON employees (department_id);
CREATE INDEX IF NOT EXISTS idx_payroll_periods_tenant ON payroll_periods (tenant_id, ano, mes);
CREATE INDEX IF NOT EXISTS idx_payroll_runs_tenant ON payroll_runs (tenant_id, processamento_em);
CREATE INDEX IF NOT EXISTS idx_payroll_run_lines_run ON payroll_run_lines (payroll_run_id);
