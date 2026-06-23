SET search_path TO gestao_escolar, public;

CREATE TABLE IF NOT EXISTS school_years (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho'
        CHECK (status IN ('rascunho','activo','encerrado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo),
    CHECK (data_fim >= data_inicio)
);

CREATE TABLE IF NOT EXISTS school_terms (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT NOT NULL REFERENCES school_years(id) ON DELETE CASCADE,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    peso NUMERIC(6,2) NOT NULL DEFAULT 1,
    status VARCHAR(20) NOT NULL DEFAULT 'aberto'
        CHECK (status IN ('aberto','encerrado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, school_year_id, codigo),
    CHECK (data_fim >= data_inicio)
);

ALTER TABLE school_classes
    ADD COLUMN IF NOT EXISTS school_year_id BIGINT REFERENCES school_years(id),
    ADD COLUMN IF NOT EXISTS director_teacher_id BIGINT,
    ADD COLUMN IF NOT EXISTS sala VARCHAR(50),
    ADD COLUMN IF NOT EXISTS horario JSONB NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE school_students
    ADD COLUMN IF NOT EXISTS documento_tipo VARCHAR(30),
    ADD COLUMN IF NOT EXISTS documento_numero VARCHAR(60),
    ADD COLUMN IF NOT EXISTS nuit VARCHAR(30),
    ADD COLUMN IF NOT EXISTS telefone VARCHAR(30),
    ADD COLUMN IF NOT EXISTS email VARCHAR(120),
    ADD COLUMN IF NOT EXISTS endereco TEXT,
    ADD COLUMN IF NOT EXISTS fotografia_url TEXT;

ALTER TABLE school_enrollments
    ADD COLUMN IF NOT EXISTS school_year_id BIGINT REFERENCES school_years(id),
    ADD COLUMN IF NOT EXISTS observacoes TEXT,
    ADD COLUMN IF NOT EXISTS transferred_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE school_enrollments DROP CONSTRAINT IF EXISTS uq_school_student_class;
CREATE UNIQUE INDEX IF NOT EXISTS uq_school_student_class_year
    ON school_enrollments(student_id,class_id,COALESCE(school_year_id,0));

CREATE TABLE IF NOT EXISTS school_guardians (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL REFERENCES school_students(id) ON DELETE CASCADE,
    nome VARCHAR(150) NOT NULL,
    parentesco VARCHAR(50),
    telefone VARCHAR(30) NOT NULL,
    email VARCHAR(120),
    nuit VARCHAR(30),
    endereco TEXT,
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    autorizado_recolher BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS school_subjects (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    descricao TEXT,
    carga_horaria INTEGER,
    nota_minima NUMERIC(6,2) NOT NULL DEFAULT 10,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS school_teacher_assignments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT REFERENCES school_years(id),
    class_id BIGINT NOT NULL REFERENCES school_classes(id) ON DELETE CASCADE,
    subject_id BIGINT NOT NULL REFERENCES school_subjects(id),
    teacher_id BIGINT NOT NULL,
    data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim DATE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, class_id, subject_id, teacher_id, data_inicio)
);

CREATE TABLE IF NOT EXISTS school_student_roles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL REFERENCES school_students(id) ON DELETE CASCADE,
    class_id BIGINT REFERENCES school_classes(id) ON DELETE CASCADE,
    cargo VARCHAR(100) NOT NULL,
    data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim DATE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS school_teacher_roles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    teacher_id BIGINT NOT NULL,
    cargo VARCHAR(100) NOT NULL,
    school_year_id BIGINT REFERENCES school_years(id),
    data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim DATE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE school_attendance
    ADD COLUMN IF NOT EXISTS subject_id BIGINT REFERENCES school_subjects(id),
    ADD COLUMN IF NOT EXISTS enrollment_id BIGINT REFERENCES school_enrollments(id),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE school_attendance DROP CONSTRAINT IF EXISTS uq_school_attendance;
CREATE UNIQUE INDEX IF NOT EXISTS uq_school_attendance_entry
    ON school_attendance(tenant_id,class_id,student_id,attendance_date,COALESCE(subject_id,0));

CREATE TABLE IF NOT EXISTS school_grade_items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    class_id BIGINT NOT NULL REFERENCES school_classes(id) ON DELETE CASCADE,
    subject_id BIGINT NOT NULL REFERENCES school_subjects(id),
    term_id BIGINT NOT NULL REFERENCES school_terms(id),
    nome VARCHAR(120) NOT NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'teste',
    data_avaliacao DATE,
    nota_maxima NUMERIC(6,2) NOT NULL DEFAULT 20,
    peso NUMERIC(6,2) NOT NULL DEFAULT 1,
    publicado BOOLEAN NOT NULL DEFAULT FALSE,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS school_grades (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    grade_item_id BIGINT NOT NULL REFERENCES school_grade_items(id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES school_students(id) ON DELETE CASCADE,
    enrollment_id BIGINT REFERENCES school_enrollments(id),
    nota NUMERIC(6,2),
    observacoes TEXT,
    lancado_por BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, grade_item_id, student_id)
);

CREATE TABLE IF NOT EXISTS school_fee_plans (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_year_id BIGINT REFERENCES school_years(id),
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'propina',
    valor NUMERIC(18,2) NOT NULL CHECK (valor >= 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    periodicidade VARCHAR(20) NOT NULL DEFAULT 'mensal',
    dia_vencimento INTEGER,
    classe_nivel VARCHAR(80),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

ALTER TABLE school_fees
    ADD COLUMN IF NOT EXISTS fee_plan_id BIGINT REFERENCES school_fee_plans(id),
    ADD COLUMN IF NOT EXISTS student_id BIGINT REFERENCES school_students(id),
    ADD COLUMN IF NOT EXISTS desconto NUMERIC(18,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS desconto_motivo TEXT,
    ADD COLUMN IF NOT EXISTS entidade VARCHAR(20),
    ADD COLUMN IF NOT EXISTS referencia VARCHAR(40),
    ADD COLUMN IF NOT EXISTS emitida_em TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE school_fees DROP CONSTRAINT IF EXISTS school_fees_status_check;
ALTER TABLE school_fees ADD CONSTRAINT school_fees_status_check
    CHECK (status IN ('pendente','emitida','parcial','paga','cancelada'));

CREATE TABLE IF NOT EXISTS school_payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    school_fee_id BIGINT NOT NULL REFERENCES school_fees(id),
    student_id BIGINT NOT NULL REFERENCES school_students(id),
    external_id VARCHAR(100),
    metodo VARCHAR(30) NOT NULL,
    referencia VARCHAR(100),
    valor NUMERIC(18,2) NOT NULL CHECK (valor > 0),
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    status VARCHAR(20) NOT NULL DEFAULT 'confirmado'
        CHECK (status IN ('pendente','confirmado','falhado','estornado')),
    conciliado BOOLEAN NOT NULL DEFAULT FALSE,
    pago_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by BIGINT,
    payload_gateway JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE NULLS NOT DISTINCT (tenant_id, external_id)
);

CREATE TABLE IF NOT EXISTS school_books (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    isbn VARCHAR(30),
    codigo VARCHAR(40) NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    autor VARCHAR(150),
    editora VARCHAR(120),
    ano_publicacao INTEGER,
    categoria VARCHAR(80),
    exemplares_total INTEGER NOT NULL DEFAULT 1 CHECK (exemplares_total >= 0),
    exemplares_disponiveis INTEGER NOT NULL DEFAULT 1 CHECK (exemplares_disponiveis >= 0),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS school_library_loans (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    book_id BIGINT NOT NULL REFERENCES school_books(id),
    student_id BIGINT REFERENCES school_students(id),
    borrower_type VARCHAR(20) NOT NULL DEFAULT 'aluno',
    borrower_id BIGINT,
    emprestado_em DATE NOT NULL DEFAULT CURRENT_DATE,
    devolucao_prevista DATE NOT NULL,
    devolvido_em DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'emprestado'
        CHECK (status IN ('emprestado','devolvido','atrasado','perdido')),
    observacoes TEXT,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS school_messages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    titulo VARCHAR(180) NOT NULL,
    conteudo TEXT NOT NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'comunicado',
    audience_type VARCHAR(30) NOT NULL DEFAULT 'todos',
    audience_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'rascunho'
        CHECK (status IN ('rascunho','publicado','arquivado')),
    publicado_em TIMESTAMPTZ,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_school_years_tenant ON school_years(tenant_id,status);
CREATE INDEX IF NOT EXISTS idx_school_terms_year ON school_terms(school_year_id);
CREATE INDEX IF NOT EXISTS idx_school_classes_tenant_year ON school_classes(tenant_id,school_year_id);
CREATE INDEX IF NOT EXISTS idx_school_students_tenant_estado ON school_students(tenant_id,estado);
CREATE INDEX IF NOT EXISTS idx_school_enrollments_tenant_year ON school_enrollments(tenant_id,school_year_id,status);
CREATE INDEX IF NOT EXISTS idx_school_guardians_student ON school_guardians(student_id);
CREATE INDEX IF NOT EXISTS idx_school_assignments_class ON school_teacher_assignments(class_id,subject_id);
CREATE INDEX IF NOT EXISTS idx_school_attendance_filters ON school_attendance(tenant_id,class_id,attendance_date);
CREATE INDEX IF NOT EXISTS idx_school_grades_student ON school_grades(student_id);
CREATE INDEX IF NOT EXISTS idx_school_fees_filters ON school_fees(tenant_id,student_id,status,data_vencimento);
CREATE INDEX IF NOT EXISTS idx_school_payments_fee ON school_payments(school_fee_id,status);
CREATE INDEX IF NOT EXISTS idx_school_loans_status ON school_library_loans(tenant_id,status,devolucao_prevista);
CREATE INDEX IF NOT EXISTS idx_school_messages_tenant_status ON school_messages(tenant_id,status);
