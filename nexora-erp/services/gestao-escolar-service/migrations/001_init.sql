CREATE TABLE IF NOT EXISTS school_classes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    nivel VARCHAR(50),
    ano_lectivo VARCHAR(20) NOT NULL,
    turma VARCHAR(20),
    capacidade INTEGER,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_school_classes UNIQUE (tenant_id, codigo, ano_lectivo)
);

CREATE TABLE IF NOT EXISTS school_students (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    data_nascimento DATE,
    genero VARCHAR(20),
    encarregado_nome VARCHAR(150),
    encarregado_telefone VARCHAR(30),
    encarregado_email VARCHAR(150),
    estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','inactivo','transferido','graduado')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_school_students UNIQUE (tenant_id, codigo)
);

CREATE TABLE IF NOT EXISTS school_enrollments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    class_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    data_matricula DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'activa' CHECK (status IN ('activa','cancelada','concluida')),
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_school_enrollments UNIQUE (tenant_id, numero),
    CONSTRAINT uq_school_student_class UNIQUE (student_id, class_id),
    CONSTRAINT fk_school_enrollments_student FOREIGN KEY (student_id) REFERENCES school_students(id) ON DELETE CASCADE,
    CONSTRAINT fk_school_enrollments_class FOREIGN KEY (class_id) REFERENCES school_classes(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS school_fees (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    enrollment_id BIGINT NOT NULL,
    numero VARCHAR(50) NOT NULL,
    descricao VARCHAR(150) NOT NULL,
    mes_referencia VARCHAR(20),
    data_vencimento DATE NOT NULL,
    valor_total NUMERIC(18,2) NOT NULL DEFAULT 0,
    valor_pago NUMERIC(18,2) NOT NULL DEFAULT 0,
    moeda VARCHAR(10) NOT NULL DEFAULT 'MZN',
    status VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','parcial','paga','cancelada')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_school_fees UNIQUE (tenant_id, numero),
    CONSTRAINT fk_school_fees_enrollment FOREIGN KEY (enrollment_id) REFERENCES school_enrollments(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS school_attendance (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    class_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    attendance_date DATE NOT NULL,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('presente','ausente','justificado','atrasado')),
    observacoes TEXT,
    created_by BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_school_attendance UNIQUE (class_id, student_id, attendance_date),
    CONSTRAINT fk_school_attendance_class FOREIGN KEY (class_id) REFERENCES school_classes(id) ON DELETE CASCADE,
    CONSTRAINT fk_school_attendance_student FOREIGN KEY (student_id) REFERENCES school_students(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_school_classes_tenant ON school_classes (tenant_id, ano_lectivo);
CREATE INDEX IF NOT EXISTS idx_school_students_tenant ON school_students (tenant_id, estado);
CREATE INDEX IF NOT EXISTS idx_school_enrollments_tenant ON school_enrollments (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_school_fees_tenant ON school_fees (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_school_attendance_tenant ON school_attendance (tenant_id, attendance_date);
