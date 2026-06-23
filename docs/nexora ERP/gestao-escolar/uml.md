# UML — Modulo Gestao Escolar

## Diagrama de Entidades (ERD)

```mermaid
erDiagram
    school_years {
        bigint id PK
        bigint tenant_id
        varchar codigo UK
        varchar nome
        date data_inicio
        date data_fim
        varchar status
    }

    school_terms {
        bigint id PK
        bigint school_year_id FK
        varchar codigo
        integer ordem
        date data_inicio
        date data_fim
    }

    classes {
        bigint id PK
        bigint school_year_id FK
        varchar codigo
        varchar nome
        varchar serie
        varchar turno
    }

    subjects {
        bigint id PK
        bigint tenant_id
        varchar codigo UK
        varchar nome
    }

    teachers {
        bigint id PK
        bigint tenant_id
        varchar codigo UK
        varchar nome_completo
    }

    teacher_assignments {
        bigint id PK
        bigint school_year_id FK
        bigint class_id FK
        bigint subject_id FK
        bigint teacher_id FK
    }

    teacher_roles {
        bigint id PK
        bigint teacher_id FK
        bigint school_year_id FK
        bigint class_id FK
        varchar tipo_cargo
    }

    students {
        bigint id PK
        bigint tenant_id
        varchar codigo_aluno UK
        varchar referencia_matricula UK
        varchar nome_completo
    }

    student_guardians {
        bigint id PK
        bigint student_id FK
        varchar nome_completo
        varchar parentesco
        boolean responsavel_financeiro
    }

    enrollments {
        bigint id PK
        bigint school_year_id FK
        bigint student_id FK
        bigint class_id FK
        varchar numero_matricula UK
        varchar estado
    }

    student_roles {
        bigint id PK
        bigint enrollment_id FK
        varchar tipo_cargo
    }

    attendance_records {
        bigint id PK
        bigint school_term_id FK
        bigint teacher_assignment_id FK
        bigint enrollment_id FK
        date data_aula
        varchar estado
    }

    grade_items {
        bigint id PK
        bigint school_term_id FK
        bigint teacher_assignment_id FK
        varchar titulo
        numeric peso
    }

    grades {
        bigint id PK
        bigint grade_item_id FK
        bigint enrollment_id FK
        numeric nota_obtida
    }

    fee_plans {
        bigint id PK
        bigint school_year_id FK
        varchar codigo UK
        varchar tipo_taxa
        numeric valor
    }

    student_invoices {
        bigint id PK
        bigint enrollment_id FK
        bigint fee_plan_id FK
        varchar entidade
        varchar referencia_pagamento UK
        numeric valor_pendente
        varchar status
    }

    student_payments {
        bigint id PK
        bigint student_invoice_id FK
        varchar numero_recibo UK
        varchar canal
        numeric valor
        varchar estado
    }

    library_books {
        bigint id PK
        varchar codigo UK
        varchar titulo
    }

    library_loans {
        bigint id PK
        bigint library_book_id FK
        bigint student_id FK
        bigint teacher_id FK
        varchar status
    }

    school_messages {
        bigint id PK
        bigint class_id FK
        bigint student_id FK
        varchar publico_alvo
        varchar status
    }

    school_years ||--o{ school_terms : "define"
    school_years ||--o{ classes : "organiza"
    school_years ||--o{ enrollments : "contexto"
    school_years ||--o{ teacher_assignments : "vigencia"
    school_years ||--o{ teacher_roles : "vigencia"
    school_years ||--o{ fee_plans : "aplica"
    classes ||--o{ enrollments : "recebe"
    classes ||--o{ teacher_assignments : "usa"
    subjects ||--o{ teacher_assignments : "leccionada em"
    teachers ||--o{ teacher_assignments : "ensina"
    teachers ||--o{ teacher_roles : "ocupa"
    students ||--o{ student_guardians : "tem"
    students ||--o{ enrollments : "matricula"
    enrollments ||--o{ student_roles : "representa"
    school_terms ||--o{ attendance_records : "periodo"
    school_terms ||--o{ grade_items : "periodo"
    teacher_assignments ||--o{ attendance_records : "regista"
    teacher_assignments ||--o{ grade_items : "planeia"
    enrollments ||--o{ attendance_records : "frequencia"
    enrollments ||--o{ grades : "avaliado"
    grade_items ||--o{ grades : "gera"
    enrollments ||--o{ student_invoices : "cobrado"
    fee_plans ||--o{ student_invoices : "origina"
    student_invoices ||--o{ student_payments : "liquidada por"
    library_books ||--o{ library_loans : "emprestado em"
    students ||--o{ library_loans : "requisita"
    teachers ||--o{ library_loans : "requisita"
    classes ||--o{ school_messages : "alvo"
    students ||--o{ school_messages : "alvo"
```

## Fluxo de Matricula e Cargo

```mermaid
sequenceDiagram
    actor Secretaria
    participant Escolar
    participant BD

    Secretaria->>Escolar: POST /api/escolar/students
    Escolar->>BD: INSERT students
    Secretaria->>Escolar: POST /api/escolar/enrollments
    Escolar->>BD: INSERT enrollments
    opt aluno com cargo
        Secretaria->>Escolar: POST /api/escolar/student-roles
        Escolar->>BD: INSERT student_roles
    end
    Escolar-->>Secretaria: matricula concluida
```

## Fluxo de Notas e Frequencia

```mermaid
sequenceDiagram
    actor Professor
    participant Portal
    participant Escolar
    participant BD
    participant Auditoria

    Professor->>Portal: abre diario de turma
    Portal->>Escolar: GET /api/escolar/classes/{id}
    Professor->>Portal: submete frequencia e notas
    Portal->>Escolar: POST /api/escolar/attendance
    Escolar->>BD: INSERT attendance_records
    Portal->>Escolar: POST /api/escolar/grades
    Escolar->>BD: INSERT grades
    Escolar->>Auditoria: regista alteracoes
    Escolar-->>Professor: lancamento concluido
```

## Fluxo de Pagamento com Entidade e Referencia

```mermaid
sequenceDiagram
    actor Financeiro
    actor Encarregado
    participant Escolar
    participant Gateway
    participant BD

    Financeiro->>Escolar: POST /api/escolar/student-invoices
    Escolar->>BD: INSERT student_invoices
    Escolar-->>Encarregado: exibe entidade e referencia
    Encarregado->>Gateway: paga via M-Pesa / banco / e-Mola
    Gateway->>Escolar: POST /api/escolar/payments/callback
    Escolar->>BD: INSERT student_payments
    Escolar->>BD: UPDATE student_invoices SET valor_pago, status
    Escolar-->>Encarregado: recibo digital disponivel
```

## Estados da Cobranca

```mermaid
stateDiagram-v2
    [*] --> pendente : emissao
    pendente --> parcial : pagamento parcial
    parcial --> paga : liquidacao total
    pendente --> paga : pagamento integral
    pendente --> vencida : prazo expirado
    parcial --> vencida : prazo expirado
    pendente --> cancelada : anulacao
    parcial --> cancelada : anulacao
    vencida --> paga : pagamento confirmado
    paga --> [*]
    cancelada --> [*]
```
