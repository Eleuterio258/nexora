-- Modulo Gestao Escolar para PostgreSQL
--
-- Responsabilidades: matriculas, turmas, cargos escolares,
-- desempenho academico, cobranca escolar, biblioteca e comunicacao.
--
-- Dependencias:
--   autenticacao / autorizacao / utilizadores / auditoria
--   financeiro / tesouraria para cobranca e recebimentos

CREATE TABLE IF NOT EXISTS school_years (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(20) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'planeado' CHECK (status IN ('planeado', 'activo', 'encerrado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_school_years UNIQUE (tenant_id, codigo),
    CONSTRAINT ck_school_year_dates CHECK (data_fim >= data_inicio)
);

CREATE TABLE IF NOT EXISTS school_terms (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    school_year_id BIGINT NOT NULL,
    codigo VARCHAR(20) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    ordem INTEGER NOT NULL CHECK (ordem > 0),
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto', 'fechado')),
    CONSTRAINT uq_school_terms UNIQUE (school_year_id, codigo),
    CONSTRAINT fk_school_terms_year FOREIGN KEY (school_year_id) REFERENCES school_years(id) ON DELETE CASCADE,
    CONSTRAINT ck_school_term_dates CHECK (data_fim >= data_inicio)
);

CREATE TABLE IF NOT EXISTS classes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    ciclo VARCHAR(60),
    serie VARCHAR(30) NOT NULL,
    turno VARCHAR(30) NOT NULL CHECK (turno IN ('manha', 'tarde', 'noite', 'integral')),
    sala VARCHAR(30),
    capacidade INTEGER NOT NULL DEFAULT 0 CHECK (capacidade >= 0),
    diretor_turma_teacher_id BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_classes UNIQUE (tenant_id, school_year_id, codigo),
    CONSTRAINT fk_classes_year FOREIGN KEY (school_year_id) REFERENCES school_years(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS subjects (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    area VARCHAR(60),
    carga_horaria INTEGER NOT NULL DEFAULT 0 CHECK (carga_horaria >= 0),
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_subjects UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS teachers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT,
    codigo VARCHAR(30) NOT NULL,
    nome_completo VARCHAR(160) NOT NULL,
    genero VARCHAR(20),
    telefone VARCHAR(40),
    email VARCHAR(150),
    documento_identificacao VARCHAR(60),
    especialidade VARCHAR(120),
    status VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (status IN ('activo', 'inactivo', 'suspenso')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_teachers UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS teacher_assignments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT NOT NULL,
    class_id BIGINT NOT NULL,
    subject_id BIGINT NOT NULL,
    teacher_id BIGINT NOT NULL,
    carga_horaria_semanal INTEGER NOT NULL DEFAULT 0 CHECK (carga_horaria_semanal >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (status IN ('activo', 'encerrado')),
    CONSTRAINT uq_teacher_assignments UNIQUE (school_year_id, class_id, subject_id, teacher_id),
    CONSTRAINT fk_teacher_assignments_year FOREIGN KEY (school_year_id) REFERENCES school_years(id) ON DELETE RESTRICT,
    CONSTRAINT fk_teacher_assignments_class FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    CONSTRAINT fk_teacher_assignments_subject FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE RESTRICT,
    CONSTRAINT fk_teacher_assignments_teacher FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS teacher_roles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    teacher_id BIGINT NOT NULL,
    school_year_id BIGINT NOT NULL,
    class_id BIGINT,
    tipo_cargo VARCHAR(40) NOT NULL CHECK (tipo_cargo IN ('director_turma', 'director_ciclo', 'director_disciplina', 'director_escola')),
    data_inicio DATE NOT NULL,
    data_fim DATE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_teacher_roles_teacher FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    CONSTRAINT fk_teacher_roles_year FOREIGN KEY (school_year_id) REFERENCES school_years(id) ON DELETE RESTRICT,
    CONSTRAINT fk_teacher_roles_class FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL,
    CONSTRAINT ck_teacher_roles_dates CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);

CREATE TABLE IF NOT EXISTS students (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT,
    codigo_aluno VARCHAR(30) NOT NULL,
    referencia_matricula VARCHAR(40) NOT NULL,
    nome_completo VARCHAR(160) NOT NULL,
    data_nascimento DATE NOT NULL,
    genero VARCHAR(20),
    documento_identificacao VARCHAR(60),
    morada TEXT,
    telefone VARCHAR(40),
    email VARCHAR(150),
    status VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (status IN ('activo', 'inactivo', 'transferido', 'graduado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_students_codigo UNIQUE (tenant_id, codigo_aluno),
    CONSTRAINT uq_students_referencia UNIQUE (tenant_id, referencia_matricula)
);

CREATE TABLE IF NOT EXISTS student_guardians (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    nome_completo VARCHAR(160) NOT NULL,
    parentesco VARCHAR(40) NOT NULL,
    telefone VARCHAR(40) NOT NULL,
    email VARCHAR(150),
    endereco TEXT,
    responsavel_financeiro BOOLEAN NOT NULL DEFAULT FALSE,
    recebe_notificacoes BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_student_guardians_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS enrollments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    class_id BIGINT NOT NULL,
    numero_matricula VARCHAR(40) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('nova', 'rematricula', 'transferencia')),
    data_matricula DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'activa' CHECK (estado IN ('activa', 'suspensa', 'cancelada', 'concluida', 'transferida')),
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_enrollments_numero UNIQUE (tenant_id, numero_matricula),
    CONSTRAINT uq_enrollment_student_year UNIQUE (school_year_id, student_id),
    CONSTRAINT fk_enrollments_year FOREIGN KEY (school_year_id) REFERENCES school_years(id) ON DELETE RESTRICT,
    CONSTRAINT fk_enrollments_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    CONSTRAINT fk_enrollments_class FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS student_roles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    enrollment_id BIGINT NOT NULL,
    tipo_cargo VARCHAR(30) NOT NULL CHECK (tipo_cargo IN ('chefe_turma', 'adjunto', 'higiene', 'seguranca', 'chefe_grupo', 'informacao')),
    data_inicio DATE NOT NULL,
    data_fim DATE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_student_roles UNIQUE (enrollment_id, tipo_cargo, data_inicio),
    CONSTRAINT fk_student_roles_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE,
    CONSTRAINT ck_student_roles_dates CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);

CREATE TABLE IF NOT EXISTS attendance_records (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_term_id BIGINT NOT NULL,
    teacher_assignment_id BIGINT NOT NULL,
    enrollment_id BIGINT NOT NULL,
    data_aula DATE NOT NULL,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('presente', 'falta_justificada', 'falta_injustificada', 'atraso')),
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_attendance UNIQUE (teacher_assignment_id, enrollment_id, data_aula),
    CONSTRAINT fk_attendance_term FOREIGN KEY (school_term_id) REFERENCES school_terms(id) ON DELETE RESTRICT,
    CONSTRAINT fk_attendance_assignment FOREIGN KEY (teacher_assignment_id) REFERENCES teacher_assignments(id) ON DELETE CASCADE,
    CONSTRAINT fk_attendance_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS grade_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_term_id BIGINT NOT NULL,
    teacher_assignment_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    titulo VARCHAR(120) NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('teste', 'trabalho', 'oral', 'exame', 'projecto', 'outra')),
    peso NUMERIC(5,2) NOT NULL CHECK (peso > 0),
    nota_maxima NUMERIC(6,2) NOT NULL DEFAULT 20 CHECK (nota_maxima > 0),
    data_avaliacao DATE NOT NULL,
    CONSTRAINT uq_grade_items UNIQUE (teacher_assignment_id, codigo),
    CONSTRAINT fk_grade_items_term FOREIGN KEY (school_term_id) REFERENCES school_terms(id) ON DELETE RESTRICT,
    CONSTRAINT fk_grade_items_assignment FOREIGN KEY (teacher_assignment_id) REFERENCES teacher_assignments(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS grades (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    grade_item_id BIGINT NOT NULL,
    enrollment_id BIGINT NOT NULL,
    nota_obtida NUMERIC(6,2) NOT NULL CHECK (nota_obtida >= 0),
    comentario TEXT,
    lancado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ,
    CONSTRAINT uq_grades UNIQUE (grade_item_id, enrollment_id),
    CONSTRAINT fk_grades_item FOREIGN KEY (grade_item_id) REFERENCES grade_items(id) ON DELETE CASCADE,
    CONSTRAINT fk_grades_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS fee_plans (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    tipo_taxa VARCHAR(30) NOT NULL CHECK (tipo_taxa IN ('matricula', 'propina', 'exame', 'uniforme', 'transporte', 'multa', 'outra')),
    classe_serie VARCHAR(30),
    valor NUMERIC(18,2) NOT NULL CHECK (valor >= 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    periodicidade VARCHAR(20) NOT NULL CHECK (periodicidade IN ('unica', 'mensal', 'trimestral', 'anual')),
    permite_desconto BOOLEAN NOT NULL DEFAULT TRUE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_fee_plans UNIQUE (tenant_id, school_year_id, codigo),
    CONSTRAINT fk_fee_plans_year FOREIGN KEY (school_year_id) REFERENCES school_years(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS student_invoices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    enrollment_id BIGINT NOT NULL,
    fee_plan_id BIGINT NOT NULL,
    school_term_id BIGINT,
    codigo_documento VARCHAR(40) NOT NULL,
    entidade VARCHAR(20) NOT NULL,
    referencia_pagamento VARCHAR(50) NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    mes_referencia INTEGER CHECK (mes_referencia BETWEEN 1 AND 12),
    ano_referencia INTEGER NOT NULL,
    data_emissao DATE NOT NULL,
    data_vencimento DATE NOT NULL,
    valor_original NUMERIC(18,2) NOT NULL CHECK (valor_original >= 0),
    valor_desconto NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (valor_desconto >= 0),
    valor_pago NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (valor_pago >= 0),
    valor_pendente NUMERIC(18,2) GENERATED ALWAYS AS ((valor_original - valor_desconto) - valor_pago) STORED,
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'parcial', 'paga', 'vencida', 'cancelada')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_student_invoices_codigo UNIQUE (tenant_id, codigo_documento),
    CONSTRAINT uq_student_invoices_ref UNIQUE (tenant_id, referencia_pagamento),
    CONSTRAINT fk_student_invoices_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE,
    CONSTRAINT fk_student_invoices_fee_plan FOREIGN KEY (fee_plan_id) REFERENCES fee_plans(id) ON DELETE RESTRICT,
    CONSTRAINT fk_student_invoices_term FOREIGN KEY (school_term_id) REFERENCES school_terms(id) ON DELETE SET NULL,
    CONSTRAINT ck_student_invoices_dates CHECK (data_vencimento >= data_emissao)
);

CREATE TABLE IF NOT EXISTS student_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    student_invoice_id BIGINT NOT NULL,
    numero_recibo VARCHAR(40) NOT NULL,
    canal VARCHAR(30) NOT NULL CHECK (canal IN ('caixa', 'transferencia', 'mpesa', 'emola', 'gateway_bancario', 'pos')),
    referencia_externa VARCHAR(80),
    telefone_pagador VARCHAR(40),
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    estado VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (estado IN ('pendente', 'confirmado', 'falhado', 'cancelado')),
    pago_em TIMESTAMPTZ,
    callback_payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_student_payments_recibo UNIQUE (tenant_id, numero_recibo),
    CONSTRAINT uq_student_payments_external UNIQUE (tenant_id, referencia_externa),
    CONSTRAINT fk_student_payments_invoice FOREIGN KEY (student_invoice_id) REFERENCES student_invoices(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS library_books (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    titulo VARCHAR(180) NOT NULL,
    autor VARCHAR(160),
    editora VARCHAR(120),
    categoria VARCHAR(80),
    isbn VARCHAR(40),
    quantidade_total INTEGER NOT NULL DEFAULT 1 CHECK (quantidade_total >= 0),
    quantidade_disponivel INTEGER NOT NULL DEFAULT 1 CHECK (quantidade_disponivel >= 0),
    estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'danificado')),
    CONSTRAINT uq_library_books UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS library_loans (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    library_book_id BIGINT NOT NULL,
    student_id BIGINT,
    teacher_id BIGINT,
    data_emprestimo DATE NOT NULL,
    data_prevista_devolucao DATE NOT NULL,
    data_devolucao DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'emprestado' CHECK (status IN ('emprestado', 'devolvido', 'atrasado', 'perdido')),
    observacoes TEXT,
    CONSTRAINT fk_library_loans_book FOREIGN KEY (library_book_id) REFERENCES library_books(id) ON DELETE CASCADE,
    CONSTRAINT fk_library_loans_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL,
    CONSTRAINT fk_library_loans_teacher FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE SET NULL,
    CONSTRAINT ck_library_loan_target CHECK (
        (student_id IS NOT NULL AND teacher_id IS NULL) OR
        (student_id IS NULL AND teacher_id IS NOT NULL)
    ),
    CONSTRAINT ck_library_loan_dates CHECK (
        data_prevista_devolucao >= data_emprestimo AND
        (data_devolucao IS NULL OR data_devolucao >= data_emprestimo)
    )
);

CREATE TABLE IF NOT EXISTS school_messages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    titulo VARCHAR(160) NOT NULL,
    corpo TEXT NOT NULL,
    publico_alvo VARCHAR(30) NOT NULL CHECK (publico_alvo IN ('aluno', 'encarregado', 'professor', 'turma', 'escola')),
    class_id BIGINT,
    student_id BIGINT,
    guardian_email VARCHAR(150),
    publicado_por BIGINT,
    publicado_em TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho' CHECK (status IN ('rascunho', 'publicado', 'arquivado')),
    CONSTRAINT fk_school_messages_class FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL,
    CONSTRAINT fk_school_messages_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL
);

-- ============================================================
-- HORARIO ESCOLAR
-- ============================================================

CREATE TABLE IF NOT EXISTS time_slots (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    nome VARCHAR(60) NOT NULL,
    ordem INTEGER NOT NULL CHECK (ordem > 0),
    hora_inicio TIME NOT NULL,
    hora_fim TIME NOT NULL,
    tipo VARCHAR(20) NOT NULL DEFAULT 'aula' CHECK (tipo IN ('aula', 'intervalo', 'almoco')),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_time_slots UNIQUE (tenant_id, nome),
    CONSTRAINT ck_time_slots_hours CHECK (hora_fim > hora_inicio)
);

CREATE TABLE IF NOT EXISTS timetable_entries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT NOT NULL,
    class_id BIGINT NOT NULL,
    teacher_assignment_id BIGINT NOT NULL,
    time_slot_id BIGINT NOT NULL,
    dia_semana INTEGER NOT NULL CHECK (dia_semana BETWEEN 1 AND 6),
    sala VARCHAR(30),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_timetable_entries UNIQUE (school_year_id, class_id, time_slot_id, dia_semana),
    CONSTRAINT fk_timetable_year FOREIGN KEY (school_year_id) REFERENCES school_years(id) ON DELETE RESTRICT,
    CONSTRAINT fk_timetable_class FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
    CONSTRAINT fk_timetable_assignment FOREIGN KEY (teacher_assignment_id) REFERENCES teacher_assignments(id) ON DELETE CASCADE,
    CONSTRAINT fk_timetable_slot FOREIGN KEY (time_slot_id) REFERENCES time_slots(id) ON DELETE RESTRICT
);

-- ============================================================
-- CALENDARIO ESCOLAR
-- ============================================================

CREATE TABLE IF NOT EXISTS school_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT NOT NULL,
    titulo VARCHAR(160) NOT NULL,
    descricao TEXT,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('feriado', 'reuniao_pais', 'visita_estudo', 'exame', 'actividade_extra', 'suspensao_aulas', 'outro')),
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    dia_letivo BOOLEAN NOT NULL DEFAULT FALSE,
    class_id BIGINT,
    publico BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_school_events_year FOREIGN KEY (school_year_id) REFERENCES school_years(id) ON DELETE CASCADE,
    CONSTRAINT fk_school_events_class FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL,
    CONSTRAINT ck_school_events_dates CHECK (data_fim >= data_inicio)
);

-- ============================================================
-- DISCIPLINA DE ALUNOS
-- ============================================================

CREATE TABLE IF NOT EXISTS student_incidents (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    enrollment_id BIGINT NOT NULL,
    tipo VARCHAR(40) NOT NULL CHECK (tipo IN ('falta_disciplinar', 'agressao', 'vandalismo', 'furto', 'falta_respeito', 'ausencia_injustificada', 'uso_telemovel', 'outro')),
    gravidade VARCHAR(20) NOT NULL CHECK (gravidade IN ('leve', 'moderada', 'grave')),
    descricao TEXT NOT NULL,
    data_ocorrencia DATE NOT NULL,
    registado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_student_incidents_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS student_sanctions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    incident_id BIGINT NOT NULL,
    tipo_sancao VARCHAR(30) NOT NULL CHECK (tipo_sancao IN ('advertencia_verbal', 'advertencia_escrita', 'suspensao', 'participacao_encarregado', 'trabalho_comunitario', 'expulsao')),
    data_inicio DATE NOT NULL,
    data_fim DATE,
    descricao TEXT,
    aplicado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_student_sanctions_incident FOREIGN KEY (incident_id) REFERENCES student_incidents(id) ON DELETE CASCADE,
    CONSTRAINT ck_student_sanctions_dates CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);

CREATE INDEX IF NOT EXISTS idx_school_years_tenant ON school_years (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_school_terms_year ON school_terms (school_year_id, ordem);
CREATE INDEX IF NOT EXISTS idx_classes_tenant_year ON classes (tenant_id, school_year_id);
CREATE INDEX IF NOT EXISTS idx_subjects_tenant ON subjects (tenant_id, activa);
CREATE INDEX IF NOT EXISTS idx_teachers_tenant_status ON teachers (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_teacher_assignments_class ON teacher_assignments (class_id, subject_id);
CREATE INDEX IF NOT EXISTS idx_teacher_roles_teacher ON teacher_roles (teacher_id, activo);
CREATE INDEX IF NOT EXISTS idx_students_tenant_status ON students (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_enrollments_student_year ON enrollments (student_id, school_year_id);
CREATE INDEX IF NOT EXISTS idx_student_roles_enrollment ON student_roles (enrollment_id, activo);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_records (data_aula, teacher_assignment_id);
CREATE INDEX IF NOT EXISTS idx_grade_items_assignment ON grade_items (teacher_assignment_id, school_term_id);
CREATE INDEX IF NOT EXISTS idx_grades_enrollment ON grades (enrollment_id);
CREATE INDEX IF NOT EXISTS idx_fee_plans_year ON fee_plans (school_year_id, tipo_taxa);
CREATE INDEX IF NOT EXISTS idx_student_invoices_status ON student_invoices (tenant_id, status, data_vencimento);
CREATE INDEX IF NOT EXISTS idx_student_invoices_enrollment ON student_invoices (enrollment_id, ano_referencia, mes_referencia);
CREATE INDEX IF NOT EXISTS idx_student_payments_invoice ON student_payments (student_invoice_id, estado);
CREATE INDEX IF NOT EXISTS idx_student_payments_external ON student_payments (referencia_externa);
CREATE INDEX IF NOT EXISTS idx_library_books_tenant ON library_books (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_library_loans_status ON library_loans (tenant_id, status, data_prevista_devolucao);
CREATE INDEX IF NOT EXISTS idx_school_messages_target ON school_messages (tenant_id, publico_alvo, status);
