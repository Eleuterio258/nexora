-- Modulo de Recursos Humanos Completo para PostgreSQL

-- ============================================================
-- ESTRUTURA ORGANIZACIONAL
-- ============================================================

CREATE TABLE IF NOT EXISTS org_units (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    parent_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    responsavel_id BIGINT,
    nivel INTEGER NOT NULL DEFAULT 1,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_org_units UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_org_units_parent FOREIGN KEY (parent_id) REFERENCES org_units(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS employee_positions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    org_unit_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    grau_salarial VARCHAR(20),
    salario_minimo NUMERIC(18,2),
    salario_maximo NUMERIC(18,2),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_employee_positions UNIQUE (tenant_id, codigo),
    CONSTRAINT fk_positions_org_unit FOREIGN KEY (org_unit_id) REFERENCES org_units(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS work_schedules (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    horas_semanais NUMERIC(5,2) NOT NULL DEFAULT 40,
    horas_diarias NUMERIC(5,2) NOT NULL DEFAULT 8,
    dias_uteis INTEGER NOT NULL DEFAULT 5,
    hora_entrada TIME,
    hora_saida TIME,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_work_schedules UNIQUE (tenant_id, codigo)
);

-- ============================================================
-- COLABORADOR (DADOS PESSOAIS E PROFISSIONAIS)
-- ============================================================

CREATE TABLE IF NOT EXISTS employees (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    org_unit_id BIGINT,
    employee_position_id BIGINT,
    work_schedule_id BIGINT,
    numero VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    nome_curto VARCHAR(60),
    data_nascimento DATE,
    genero VARCHAR(10) CHECK (genero IN ('masculino', 'feminino', 'outro')),
    estado_civil VARCHAR(20) CHECK (estado_civil IN ('solteiro', 'casado', 'divorciado', 'viuvo', 'uniao_de_facto')),
    nacionalidade VARCHAR(80),
    nuit VARCHAR(30),
    inss VARCHAR(30),
    numero_bi VARCHAR(30),
    telefone VARCHAR(30),
    email_pessoal VARCHAR(120),
    email_profissional VARCHAR(120),
    data_admissao DATE NOT NULL,
    data_demissao DATE,
    motivo_demissao TEXT,
    estado VARCHAR(20) NOT NULL DEFAULT 'ativo' CHECK (estado IN ('ativo', 'inativo', 'suspenso', 'demitido')),
    foto_url TEXT,
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_employees UNIQUE (tenant_id, numero),
    CONSTRAINT uq_employees_nuit UNIQUE NULLS NOT DISTINCT (tenant_id, nuit),
    CONSTRAINT fk_employees_org_unit FOREIGN KEY (org_unit_id) REFERENCES org_units(id) ON DELETE SET NULL,
    CONSTRAINT fk_employees_position FOREIGN KEY (employee_position_id) REFERENCES employee_positions(id) ON DELETE SET NULL,
    CONSTRAINT fk_employees_schedule FOREIGN KEY (work_schedule_id) REFERENCES work_schedules(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS employee_addresses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    tipo VARCHAR(20) NOT NULL DEFAULT 'residencia' CHECK (tipo IN ('residencia', 'fiscal', 'correspondencia')),
    endereco VARCHAR(255) NOT NULL,
    bairro VARCHAR(100),
    cidade VARCHAR(100),
    provincia VARCHAR(100),
    pais VARCHAR(100) NOT NULL DEFAULT 'Mocambique',
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_addresses_emp FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS employee_emergency_contacts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    parentesco VARCHAR(60),
    telefone VARCHAR(30) NOT NULL,
    email VARCHAR(120),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_emergency_emp FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS employee_documents (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('bi', 'passaporte', 'nuit', 'inss', 'carta_conducao', 'certidao', 'diploma', 'contrato', 'outro')),
    numero VARCHAR(100),
    ficheiro_url TEXT,
    emitido_em DATE,
    expira_em DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_documents_emp FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

-- ============================================================
-- CONTRATOS E REMUNERACAO
-- ============================================================

CREATE TABLE IF NOT EXISTS employee_contracts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    numero VARCHAR(50),
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('efectivo', 'termo_certo', 'termo_incerto', 'prestacao_servicos', 'estagio')),
    data_inicio DATE NOT NULL,
    data_fim DATE,
    renovacoes INTEGER NOT NULL DEFAULT 0,
    salario_base NUMERIC(18,2) NOT NULL CHECK (salario_base >= 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    regime_trabalho VARCHAR(20) NOT NULL DEFAULT 'integral' CHECK (regime_trabalho IN ('integral', 'parcial', 'remoto', 'hibrido')),
    local_trabalho VARCHAR(150),
    status VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (status IN ('activo', 'expirado', 'rescindido', 'suspenso')),
    observacoes TEXT,
    ficheiro_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_contracts_emp FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS payroll_components (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('provento', 'desconto')),
    categoria VARCHAR(30) NOT NULL CHECK (categoria IN ('base', 'subsidio', 'bonus', 'inss', 'irps', 'outros_descontos', 'outros_proventos')),
    calculo VARCHAR(20) NOT NULL DEFAULT 'valor_fixo' CHECK (calculo IN ('valor_fixo', 'percentagem_base', 'percentagem_bruto', 'formula')),
    valor_padrao NUMERIC(18,4),
    formula TEXT,
    tributavel BOOLEAN NOT NULL DEFAULT TRUE,
    sujeito_inss BOOLEAN NOT NULL DEFAULT TRUE,
    obrigatorio BOOLEAN NOT NULL DEFAULT FALSE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payroll_components UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS employee_salaries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    salario_base NUMERIC(18,2) NOT NULL CHECK (salario_base >= 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    inicia_em DATE NOT NULL,
    fim_em DATE,
    motivo_alteracao VARCHAR(150),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_salaries_emp FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS employee_benefits (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    payroll_component_id BIGINT NOT NULL,
    valor NUMERIC(18,2),
    inicia_em DATE,
    fim_em DATE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    observacao TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_employee_benefits UNIQUE (employee_id, payroll_component_id),
    CONSTRAINT fk_employee_benefits_emp FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    CONSTRAINT fk_employee_benefits_comp FOREIGN KEY (payroll_component_id) REFERENCES payroll_components(id)
);

-- ============================================================
-- ASSIDUIDADE E FERIAS
-- ============================================================

CREATE TABLE IF NOT EXISTS employee_attendance (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    data_registo DATE NOT NULL,
    hora_entrada TIME,
    hora_saida TIME,
    horas_trabalhadas NUMERIC(5,2),
    horas_extra NUMERIC(5,2) NOT NULL DEFAULT 0,
    estado VARCHAR(20) NOT NULL DEFAULT 'presente' CHECK (estado IN ('presente', 'ausente', 'falta_justificada', 'falta_injustificada', 'ferias', 'feriado', 'meio_dia')),
    observacao VARCHAR(200),
    registado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_employee_attendance UNIQUE (employee_id, data_registo),
    CONSTRAINT fk_employee_attendance_emp FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS employee_overtime (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    data DATE NOT NULL,
    horas NUMERIC(5,2) NOT NULL CHECK (horas > 0),
    tipo VARCHAR(20) NOT NULL DEFAULT 'normal' CHECK (tipo IN ('normal', 'nocturno', 'feriado', 'fim_semana')),
    valor_hora NUMERIC(18,2),
    aprovado_por BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'aprovado', 'rejeitado', 'pago')),
    observacao TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_overtime_emp FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS employee_leave_types (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    dias_anuais INTEGER,
    pago BOOLEAN NOT NULL DEFAULT TRUE,
    requer_aprovacao BOOLEAN NOT NULL DEFAULT TRUE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_employee_leave_types UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS employee_leave_balances (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    employee_leave_type_id BIGINT NOT NULL,
    ano INTEGER NOT NULL,
    dias_direito NUMERIC(5,1) NOT NULL DEFAULT 0,
    dias_gozados NUMERIC(5,1) NOT NULL DEFAULT 0,
    dias_pendentes NUMERIC(5,1) NOT NULL DEFAULT 0,
    dias_disponiveis NUMERIC(5,1) NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_employee_leave_balances UNIQUE (employee_id, employee_leave_type_id, ano),
    CONSTRAINT fk_leave_balances_emp FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    CONSTRAINT fk_leave_balances_type FOREIGN KEY (employee_leave_type_id) REFERENCES employee_leave_types(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS employee_leaves (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    employee_leave_type_id BIGINT NOT NULL,
    numero VARCHAR(30),
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    dias_solicitados NUMERIC(5,1) NOT NULL,
    dias_aprovados NUMERIC(5,1),
    motivo TEXT,
    aprovado_por BIGINT,
    aprovado_em TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'aprovada', 'rejeitada', 'gozada', 'cancelada')),
    observacao_aprovador TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_leaves_emp FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    CONSTRAINT fk_employee_leaves_type FOREIGN KEY (employee_leave_type_id) REFERENCES employee_leave_types(id)
);

-- ============================================================
-- PROCESSAMENTO SALARIAL
-- ============================================================

CREATE TABLE IF NOT EXISTS payroll_runs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    mes INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
    ano INTEGER NOT NULL,
    descricao VARCHAR(150),
    data_processamento TIMESTAMPTZ,
    data_pagamento DATE,
    total_colaboradores INTEGER NOT NULL DEFAULT 0,
    total_bruto NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_descontos NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_liquido NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_inss_colaborador NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_inss_entidade NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_irps NUMERIC(18,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho', 'processado', 'aprovado', 'pago', 'cancelado')),
    processado_por BIGINT,
    aprovado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payroll_runs UNIQUE (tenant_id, mes, ano)
);

CREATE TABLE IF NOT EXISTS employee_payroll (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payroll_run_id BIGINT NOT NULL,
    employee_id BIGINT NOT NULL,
    salario_base NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_proventos NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_descontos NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_bruto NUMERIC(18,2) NOT NULL DEFAULT 0,
    inss_colaborador NUMERIC(18,2) NOT NULL DEFAULT 0,
    inss_entidade NUMERIC(18,2) NOT NULL DEFAULT 0,
    irps NUMERIC(18,2) NOT NULL DEFAULT 0,
    outros_descontos NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_liquido NUMERIC(18,2) NOT NULL DEFAULT 0,
    dias_trabalhados INTEGER,
    horas_extra NUMERIC(5,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'processado' CHECK (status IN ('processado', 'pago', 'cancelado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_employee_payroll UNIQUE (payroll_run_id, employee_id),
    CONSTRAINT fk_employee_payroll_run FOREIGN KEY (payroll_run_id) REFERENCES payroll_runs(id) ON DELETE CASCADE,
    CONSTRAINT fk_employee_payroll_emp FOREIGN KEY (employee_id) REFERENCES employees(id)
);

CREATE TABLE IF NOT EXISTS employee_payroll_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_payroll_id BIGINT NOT NULL,
    payroll_component_id BIGINT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('provento', 'desconto')),
    descricao VARCHAR(150) NOT NULL,
    valor NUMERIC(18,2) NOT NULL,
    tributavel BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_payroll_items_payroll FOREIGN KEY (employee_payroll_id) REFERENCES employee_payroll(id) ON DELETE CASCADE,
    CONSTRAINT fk_payroll_items_component FOREIGN KEY (payroll_component_id) REFERENCES payroll_components(id) ON DELETE SET NULL
);

-- ============================================================
-- DESENVOLVIMENTO E DESEMPENHO
-- ============================================================

CREATE TABLE IF NOT EXISTS employee_evaluations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    avaliador_id BIGINT NOT NULL,
    periodo_inicio DATE NOT NULL,
    periodo_fim DATE NOT NULL,
    pontuacao_global NUMERIC(4,2) CHECK (pontuacao_global BETWEEN 0 AND 10),
    classificacao VARCHAR(30) CHECK (classificacao IN ('insatisfatorio', 'necessita_melhoria', 'satisfatorio', 'bom', 'excelente')),
    pontos_fortes TEXT,
    areas_melhoria TEXT,
    plano_desenvolvimento TEXT,
    comentario_colaborador TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'em_curso', 'concluida')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_evaluations_emp FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS evaluation_criteria (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    evaluation_id BIGINT NOT NULL,
    criterio VARCHAR(150) NOT NULL,
    pontuacao NUMERIC(4,2) CHECK (pontuacao BETWEEN 0 AND 10),
    comentario TEXT,
    CONSTRAINT fk_eval_criteria_evaluation FOREIGN KEY (evaluation_id) REFERENCES employee_evaluations(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS employee_training (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    entidade_formadora VARCHAR(150),
    tipo VARCHAR(30) CHECK (tipo IN ('interno', 'externo', 'online', 'conferencia')),
    data_inicio DATE,
    data_fim DATE,
    horas INTEGER,
    custo NUMERIC(18,2),
    certificado BOOLEAN NOT NULL DEFAULT FALSE,
    certificado_url TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'agendada' CHECK (status IN ('agendada', 'em_curso', 'concluida', 'cancelada')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_training_emp FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS employee_disciplinary (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('advertencia_verbal', 'advertencia_escrita', 'suspensao', 'processo_disciplinar')),
    descricao TEXT NOT NULL,
    data_ocorrencia DATE NOT NULL,
    data_audiencia DATE,
    sancao_aplicada VARCHAR(200),
    dias_suspensao INTEGER,
    observacoes TEXT,
    registado_por BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto', 'em_instrucao', 'encerrado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_employee_disciplinary_emp FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

-- ============================================================
-- INDICES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_org_units_tenant_id ON org_units (tenant_id);
CREATE INDEX IF NOT EXISTS idx_org_units_parent_id ON org_units (parent_id);
CREATE INDEX IF NOT EXISTS idx_employee_positions_tenant_id ON employee_positions (tenant_id);
CREATE INDEX IF NOT EXISTS idx_work_schedules_tenant_id ON work_schedules (tenant_id);
CREATE INDEX IF NOT EXISTS idx_employees_tenant_id ON employees (tenant_id);
CREATE INDEX IF NOT EXISTS idx_employees_org_unit_id ON employees (org_unit_id);
CREATE INDEX IF NOT EXISTS idx_employees_position_id ON employees (employee_position_id);
CREATE INDEX IF NOT EXISTS idx_employees_estado ON employees (estado);
CREATE INDEX IF NOT EXISTS idx_employee_contracts_employee_id ON employee_contracts (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_contracts_status ON employee_contracts (status);
CREATE INDEX IF NOT EXISTS idx_payroll_components_tenant_id ON payroll_components (tenant_id);
CREATE INDEX IF NOT EXISTS idx_employee_salaries_employee_id ON employee_salaries (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_attendance_employee_id ON employee_attendance (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_attendance_data ON employee_attendance (data_registo);
CREATE INDEX IF NOT EXISTS idx_employee_overtime_employee_id ON employee_overtime (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_leave_types_tenant_id ON employee_leave_types (tenant_id);
CREATE INDEX IF NOT EXISTS idx_employee_leave_balances_employee_id ON employee_leave_balances (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_leaves_employee_id ON employee_leaves (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_leaves_status ON employee_leaves (status);
CREATE INDEX IF NOT EXISTS idx_payroll_runs_tenant_id ON payroll_runs (tenant_id);
CREATE INDEX IF NOT EXISTS idx_payroll_runs_mes_ano ON payroll_runs (tenant_id, ano, mes);
CREATE INDEX IF NOT EXISTS idx_employee_payroll_run_id ON employee_payroll (payroll_run_id);
CREATE INDEX IF NOT EXISTS idx_employee_payroll_employee_id ON employee_payroll (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_evaluations_employee_id ON employee_evaluations (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_training_employee_id ON employee_training (employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_disciplinary_employee_id ON employee_disciplinary (employee_id);
