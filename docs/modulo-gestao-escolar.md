# Módulo de Gestão Escolar — Nexora ERP

## 1. Visão Geral

O **Módulo de Gestão Escolar** é um módulo nativo do **Nexora ERP** que estende a plataforma com todas as funcionalidades de administração académica e pedagógica para instituições de ensino em Moçambique. Foi concebido para atender escolas primárias, secundárias, institutos técnicos, centros pré-universitários e instituições de ensino superior.

Como módulo de primeira classe do Nexora ERP, partilha a mesma base técnica, segurança e modelo de dados multi-tenant dos restantes módulos (Financeiro, RH, Clientes, etc.):

- **Backend:** Go 1.23 + Chi + PostgreSQL (pgx/v5)
- **Autenticação:** JWT + sessões + RBAC (partilhado com todo o ERP)
- **Tenant isolation:** `X-Tenant-ID` em todas as requisições
- **Prefixo de API:** `/api/escolar`

---

## 2. Problemas que resolve

- Substitui processos manuais de matrícula, frequência e notas por um sistema digital centralizado.
- Conecta escola, professores, alunos e encarregados numa única plataforma.
- Automatiza a emissão de boletins, declarações, históricos e certificados.
- Permite a gestão de múltiplas escolas/filiais a partir do painel central do ERP.
- Integra dados académicos com o módulo financeiro para controlo de propinas e mensalidades.

---

## 3. Público-alvo

| Instituição | Uso principal |
| --- | --- |
| Redes/grupos escolares | Gestão centralizada de várias escolas |
| Escolas primárias e secundárias | Matrículas, notas, frequência, comunicação |
| Institutos técnicos | Cursos, módulos, estágios, certificados |
| Centros pré-universitários | Aulas intensivas, simulados, exames de admissão |
| Universidades/faculdades | Cursos, semestres, créditos, histórico académico |

---

## 4. Tipos de ensino suportados

| Tipo | Duração típica | Características |
| --- | --- | --- |
| Ensino Primário (EP) | 7 anos (1ª a 7ª) | Professor único por turma, disciplinas básicas, avaliação contínua |
| Ensino Secundário (ES) | 5 anos (8ª a 12ª) | Professores especialistas, exames nacionais na 10ª e 12ª classe |
| Pré-universitário | 1 ano | Disciplinas intensivas, simulados, preparação para exames de admissão |
| Técnico-profissional | 1 a 3 anos | Módulos por curso, componente prático, estágio |
| Superior | 3 a 5 anos | Semestres, créditos, disciplinas obrigatórias e optativas |

Cada instituição configura independentemente níveis, séries, cursos, turmas, disciplinas, períodos letivos, modelo de avaliação, regras de aprovação e documentos.

---

## 5. Funcionalidades por perfil

### 5.1 Admin Global / Superadmin

- Criar e configurar tenants escolares.
- Definir planos, módulos e features disponíveis por tenant.
- Gerenciar utilizadores globais e administradores de escola.
- Relatórios consolidados entre unidades.

### 5.2 Admin de Unidade/Escola

- Cadastrar professores, alunos, turmas e disciplinas.
- Configurar calendário académico, turnos e períodos letivos.
- Montar horários de aula.
- Publicar comunicados e notificações.
- Visualizar estatísticas de matrículas, frequência e desempenho.

### 5.3 Secretaria

- Processar matrículas e renovações.
- Emitir declarações, atestados, boletins e históricos.
- Gerir transferências e documentação do aluno.
- Enviar comunicados internos.
- Gerar relatórios administrativos.

### 5.4 Professor

- Consultar turmas e agenda de aulas.
- Registar frequência.
- Lançar notas de avaliações, trabalhos e exames.
- Criar atividades e anexar materiais de estudo.
- Enviar comunicados aos alunos.
- Acessar funções diretivas conforme cargo atribuído.

### 5.5 Aluno

- Consultar disciplinas, horários e atividades.
- Visualizar notas, frequência e boletim.
- Aceder a material de estudo.
- Exercer funções de classe (chefe, subchefe, higiene, informação, segurança).

### 5.6 Encarregado de educação

- Acompanhar notas, faltas e boletim dos filhos.
- Receber comunicados e alertas da escola.
- Solicitar documentos e justificar faltas.
- Visualizar eventos e calendário escolar.

---

## 6. Cargos e funções complementares

### Cargos de professor

| Cargo | Responsabilidade |
| --- | --- |
| Diretor de Escola | Visão geral pedagógica e administrativa |
| Diretor Adjunto | Apoio à direção |
| Diretor de Turma | Acompanhamento específico de uma turma |
| Coordenador de Disciplina | Supervisão pedagógica de uma disciplina |
| Coordenador de Ciclo | Acompanhamento de ciclo/etapa de ensino |

### Funções de aluno

| Função | Responsabilidade |
| --- | --- |
| Chefe de Turma | Organização e comunicação da turma |
| Subchefe | Apoio ao chefe de turma |
| Higiene | Organização da sala e materiais de limpeza |
| Informação | Divulgação de informações |
| Segurança | Monitoramento e prevenção de incidentes |

---

## 7. Posicionamento no Nexora ERP

Este módulo não é um sistema externo que se liga ao ERP — é parte integrante dele. Reside no mesmo processo Go, usa a mesma base de dados PostgreSQL, o mesmo sistema de autenticação JWT e o mesmo RBAC que todos os outros módulos do Nexora ERP. A única diferença em relação aos módulos base (Financeiro, RH, Clientes…) é o contexto de negócio: gestão de escolas.

### 7.1 Infra-estrutura partilhada com o ERP

| Componente | Como este módulo o usa |
| --- | --- |
| Middleware de autenticação | `mw.GetUser(r)` — lê utilizador e `tenant_id` do JWT já validado |
| RBAC | `mw.RequirePermission(db, "gestao-escolar", "permissao")` — mesmo motor do ERP |
| Auditoria | `mw.AuditModule(db, "/api/escolar", "gestao-escolar")` — regista todas as acções |
| Pool de ligações | `*pgxpool.Pool` injectado em `handlers.New(db, cfg)` |
| Schema isolado | Todas as tabelas estão no schema `gestao_escolar` dentro do mesmo PostgreSQL |
| Tenant isolation | Todas as queries filtram por `tenant_id` — mesmo padrão do ERP |

### 7.2 Permissões RBAC do módulo

Cada permissão corresponde a um grupo de rotas protegidas no router (`/api/escolar`).

| Permissão | Rotas protegidas | Perfis pré-definidos |
| --- | --- | --- |
| `ver_escolar` | GET de tudo: anos, turmas, alunos, professores, notas, pagamentos, etc. | tenant_admin, professor, funcionario |
| `gerir_academico` | POST/PUT/DELETE de anos, turmas, disciplinas, atribuições, níveis, séries, cursos | tenant_admin |
| `gerir_professores` | POST/PUT/DELETE de `/teachers` | tenant_admin |
| `gerir_alunos` | Criar/editar alunos, encarregados, matrículas, transferências | tenant_admin, funcionario |
| `gerir_frequencia` | Lançar e corrigir frequências | tenant_admin, professor, funcionario |
| `gerir_avaliacoes` | Criar avaliações, lançar e corrigir notas, gerar boletins | tenant_admin, professor |
| `gerir_financeiro` | Planos de propinas, cobranças, pagamentos, descontos | tenant_admin, funcionario |
| `gerir_biblioteca` | Livros, empréstimos e devoluções | tenant_admin |
| `gerir_comunicacao` | Criar e publicar comunicados escolares | tenant_admin |
| `gerir_horarios` | Time slots, horários de turma, calendário escolar | tenant_admin |
| `gerir_ocorrencias` | Tipos de ocorrência, ocorrências, sanções, méritos | tenant_admin |

### 7.3 Complementaridade com outros módulos do ERP

Os módulos abaixo já existem no Nexora ERP. O módulo de Gestão Escolar **complementa-os** — não os substitui nem se integra externamente com eles.

| Módulo existente | Como o módulo escolar o complementa | Implementação |
| --- | --- | --- |
| Tesouraria | Pagamentos escolares criam movimentos em `tesouraria.movimentos_financeiros` | **Implementado** — opcional, controlado por `school_financial_config.criar_movimento_tesouraria` |
| Financeiro | Cobranças de propinas podem originar facturas no módulo Financeiro | **Previsto** — campo `criar_movimento_financeiro` existe em `school_financial_config` mas ainda não implementado |
| Contabilidade | Receitas de propinas podem ser lançadas via Contabilidade | **Previsto** — `conta_receita_id` em `school_financial_config` |
| Clientes | Alunos e encarregados podem ser registados como entidades do ERP | **Manual** — nenhuma sincronização automática |
| Recursos Humanos | Professores estão em `gestao_escolar.school_teachers` (schema próprio) | **Independente** — professores são geridos directamente pelo módulo |
| Notificações | Alertas de faltas, notas e comunicados | **Previsto** — não integrado automaticamente |
| Auditoria | Todas as alterações sensíveis ficam no log de auditoria | **Implementado** — `mw.AuditModule` aplicado a todas as rotas `/api/escolar` |

### 7.4 Frontend

O módulo tem um frontend PHP completo com **35 páginas** e um serviço central (`SchoolService.php`) com 163 operações de API. As páginas cobrem todas as funcionalidades: alunos, matrículas, notas, frequência, propinas, pagamentos, biblioteca, comunicados, horários, ocorrências, dashboard e relatórios.

---

## 8. Rotas da API

Todas as rotas partem do prefixo `/api/escolar`.

### 8.1 Leitura geral — `ver_escolar`

| Método | Rota | Descrição |
| --- | --- | --- |
| GET | `/years` | Listar anos lectivos |
| GET | `/years/{id}` | Obter ano lectivo com períodos |
| GET | `/classes` | Listar turmas (filtros: year_id, activo) |
| GET | `/classes/{id}` | Obter turma com alunos e professores |
| GET | `/subjects` | Listar disciplinas |
| GET | `/students` | Listar alunos (filtros: status, search) |
| GET | `/students/{id}` | Obter aluno com encarregados e matrículas |
| GET | `/enrollments/{id}` | Obter matrícula |
| GET | `/student-roles` | Listar funções de alunos |
| GET | `/teacher-roles` | Listar cargos de professores |
| GET | `/teachers` | Listar professores (paginado, filtros: status, search) |
| GET | `/teachers/{id}` | Obter professor |
| GET | `/levels` | Listar níveis de ensino |
| GET | `/levels/{id}` | Obter nível de ensino |
| GET | `/series` | Listar séries (filtro: level_id) |
| GET | `/series/{id}` | Obter série |
| GET | `/courses` | Listar cursos (filtro: level_id) |
| GET | `/courses/{id}` | Obter curso |
| GET | `/attendance` | Listar frequências (filtros: class_id, subject_id, data) |
| GET | `/grade-items` | Listar avaliações (filtros: class_id, subject_id, term_id) |
| GET | `/fee-plans` | Listar planos de propinas |
| GET | `/student-invoices` | Listar cobranças (filtros: student_id, status, vencimento_ate) |
| GET | `/student-invoices/{id}` | Obter cobrança com pagamentos |
| GET | `/payments/{id}` | Obter pagamento |
| GET | `/payments/{id}/receipt` | Obter recibo de pagamento |
| GET | `/library/books` | Listar livros |
| GET | `/library/loans` | Listar empréstimos (filtros: status, student_id) |
| GET | `/messages` | Listar comunicados (filtros: status, audience_type) |
| GET | `/dashboard/direction` | Dashboard da direção |
| GET | `/reports/academic-summary` | Relatório académico por turma/disciplina |
| GET | `/reports/financial-summary` | Relatório financeiro resumido |
| GET | `/reports/delinquency` | Relatório de inadimplência |

### 8.2 Gestão académica — `gerir_academico`

| Método | Rota | Descrição |
| --- | --- | --- |
| POST | `/years` | Criar ano lectivo |
| PUT | `/years/{id}` | Actualizar ano lectivo |
| POST | `/years/{id}/activar` | Activar ano lectivo |
| POST | `/years/{id}/close` | Encerrar ano lectivo |
| POST | `/years/{id}/terms` | Criar período lectivo |
| POST | `/classes` | Criar turma (com validação de nível/série/curso) |
| PUT | `/classes/{id}` | Actualizar turma |
| POST | `/classes/{id}/assign-teacher` | Associar director de turma |
| POST | `/subjects` | Criar disciplina |
| POST | `/teacher-assignments` | Atribuir professor a disciplina/turma |
| POST | `/student-roles` | Atribuir função a aluno |
| PUT | `/student-roles/{id}` | Actualizar função de aluno |
| POST | `/student-roles/{id}/revoke` | Revogar função de aluno |
| POST | `/teacher-roles` | Atribuir cargo a professor |
| PUT | `/teacher-roles/{id}` | Actualizar cargo de professor |
| POST | `/teacher-roles/{id}/revoke` | Revogar cargo de professor |
| POST | `/levels` | Criar nível de ensino |
| PUT | `/levels/{id}` | Actualizar nível de ensino |
| DELETE | `/levels/{id}` | Remover nível de ensino |
| POST | `/series` | Criar série |
| PUT | `/series/{id}` | Actualizar série |
| DELETE | `/series/{id}` | Remover série |
| POST | `/courses` | Criar curso |
| PUT | `/courses/{id}` | Actualizar curso |
| DELETE | `/courses/{id}` | Remover curso |

### 8.3 Gestão de professores — `gerir_professores`

| Método | Rota | Descrição |
| --- | --- | --- |
| POST | `/teachers` | Criar professor |
| PUT | `/teachers/{id}` | Actualizar professor |
| DELETE | `/teachers/{id}` | Remover professor |

### 8.4 Gestão de alunos — `gerir_alunos`

| Método | Rota | Descrição |
| --- | --- | --- |
| POST | `/students` | Criar aluno |
| PUT | `/students/{id}` | Actualizar aluno |
| POST | `/students/{id}/guardians` | Adicionar encarregado |
| POST | `/enrollments` | Matricular aluno (com validação de capacidade) |
| POST | `/enrollments/{id}/transfer` | Transferir aluno para outra turma |
| POST | `/enrollments/{id}/cancel` | Cancelar matrícula |

### 8.5 Frequência — `gerir_frequencia`

| Método | Rota | Descrição |
| --- | --- | --- |
| POST | `/attendance` | Lançar frequência em lote (array de alunos) |
| PUT | `/attendance/{id}` | Corrigir frequência individual |

### 8.6 Avaliações e notas — `gerir_avaliacoes`

| Método | Rota | Descrição |
| --- | --- | --- |
| POST | `/grade-items` | Criar avaliação |
| POST | `/grade-items/{id}/publish` | Publicar/despublicar avaliação |
| POST | `/grades` | Lançar notas em lote |
| PUT | `/grades/{id}` | Corrigir nota individual |
| GET | `/report-cards/{student_id}` | Obter boletim do aluno (filtro: term_id) |

### 8.7 Financeiro escolar — `gerir_financeiro`

| Método | Rota | Descrição |
| --- | --- | --- |
| POST | `/fee-plans` | Criar plano de propinas |
| POST | `/fee-plans/{id}/generate` | Gerar cobranças a partir de um plano |
| POST | `/student-invoices` | Gerar cobrança individual |
| POST | `/student-invoices/{id}/emit` | Emitir cobrança pendente |
| POST | `/student-invoices/{id}/discount` | Aplicar desconto |
| POST | `/payments` | Registar pagamento |
| POST | `/payments/callback` | Callback de gateway de pagamento |

### 8.8 Biblioteca — `gerir_biblioteca`

| Método | Rota | Descrição |
| --- | --- | --- |
| POST | `/library/books` | Registar livro |
| POST | `/library/loans` | Registar empréstimo |
| POST | `/library/loans/{id}/return` | Confirmar devolução |

### 8.9 Comunicação — `gerir_comunicacao`

| Método | Rota | Descrição |
| --- | --- | --- |
| POST | `/messages` | Criar comunicado (rascunho) |
| POST | `/messages/{id}/publish` | Publicar comunicado |

### 8.10 Horários e calendário — `gerir_horarios`

| Método | Rota | Descrição |
| --- | --- | --- |
| GET | `/time-slots` | Listar slots de tempo |
| POST | `/time-slots` | Criar slot de tempo |
| GET | `/timetables/class/{class_id}` | Horário de uma turma |
| GET | `/timetables/teacher/{teacher_id}` | Horário de um professor |
| POST | `/timetables` | Criar entrada de horário (com detecção de conflito) |
| PUT | `/timetables/{id}` | Actualizar entrada de horário |
| DELETE | `/timetables/{id}` | Remover entrada de horário |
| GET | `/calendar-event-types` | Listar tipos de evento |
| POST | `/calendar-event-types` | Criar tipo de evento |
| GET | `/calendar-events` | Listar eventos do calendário |
| GET | `/calendar-events/{id}` | Obter evento |
| POST | `/calendar-events` | Criar evento |
| PUT | `/calendar-events/{id}` | Actualizar evento |
| DELETE | `/calendar-events/{id}` | Remover evento |

### 8.11 Ocorrências — `gerir_ocorrencias`

| Método | Rota | Descrição |
| --- | --- | --- |
| GET | `/incident-types` | Listar tipos de ocorrência |
| POST | `/incident-types` | Criar tipo de ocorrência |
| GET | `/incidents` | Listar ocorrências |
| GET | `/incidents/{id}` | Obter ocorrência |
| POST | `/incidents` | Registar ocorrência |
| PUT | `/incidents/{id}` | Actualizar ocorrência |
| POST | `/sanctions` | Registar sanção |
| POST | `/merits` | Registar mérito |

---

## 9. Estrutura de diretórios no backend Go

```
backend/
└── internal/
    └── modules/
        └── gestao-escolar/
            ├── handlers/
            │   ├── handler.go              (Handler struct + helpers HTTP)
            │   ├── escolar.go              (anos lectivos, turmas, alunos, matrículas)
            │   ├── academico.go            (frequências, avaliações, cargos)
            │   ├── operacoes.go            (propinas, pagamentos, biblioteca)
            │   ├── estrutura_academica.go  (níveis, séries, cursos)
            │   ├── turmas_matriculas.go    (turmas V2, matrículas V2)
            │   ├── professores.go          (CRUD professores)
            │   ├── grades.go               (avaliações V2, notas, boletim)
            │   ├── fees.go                 (planos propinas V2, pagamentos V2)
            │   ├── timetable.go            (time slots, horários)
            │   ├── calendar.go             (tipos de evento, calendário)
            │   ├── incidents.go            (ocorrências, sanções, méritos)
            │   └── comunicacao.go          (mensagens, dashboard, relatórios)
            ├── models/
            │   ├── models.go               (tipos partilhados: Pagination, ListResponse)
            │   ├── class.go                (Class, ClassCreate, ClassUpdate)
            │   ├── enrollment.go           (Enrollment, EnrollmentCreate, EnrollmentTransfer)
            │   ├── teacher.go              (Teacher, TeacherCreate, TeacherUpdate)
            │   ├── grade.go                (GradeItem, Grade)
            │   ├── fee.go                  (FeePlan, SchoolFee, SchoolPayment)
            │   ├── timetable.go            (TimeSlot, TimetableEntry)
            │   ├── academic_structure.go   (Level, Series, Course)
            │   └── discipline.go           (Subject)
            ├── repositories/
            │   ├── db.go
            │   ├── academic_structure.go
            │   ├── class.go
            │   ├── enrollment.go
            │   ├── teacher.go
            │   ├── grade.go
            │   ├── fee.go                  (inclui integração com tesouraria)
            │   ├── timetable.go
            │   ├── calendar.go
            │   └── incident.go
            └── services/
                ├── academic_structure.go
                ├── class.go
                ├── enrollment.go
                ├── teacher.go
                ├── grade.go
                ├── fee.go                  (gera cobranças em lote, regista pagamentos)
                ├── timetable.go
                ├── calendar.go
                └── incident.go
```

### Migrações SQL

| Ficheiro | Conteúdo |
| --- | --- |
| `036_gestao_escolar.sql` | Tabelas originais (legacy) |
| `062_gestao_escolar_foundation.sql` | Estrutura base completa (anos, turmas, alunos, propinas, etc.) |
| `063_gestao_escolar_horarios_calendario.sql` | Time slots, horários, tipos de evento, calendário |
| `064_gestao_escolar_ocorrencias.sql` | Tipos de ocorrência, ocorrências, sanções, méritos |
| `065_gestao_escolar_configuracao_avancada.sql` | Configurações académicas avançadas |
| `066_permissoes_gestao_escolar.sql` | Permissões RBAC por perfil |
| `067_gestao_escolar_financeiro.sql` | Configuração financeira e integração com Tesouraria |

---

## 10. Modelo de dados — schema `gestao_escolar`

### Tabelas principais

| Tabela | Descrição |
| --- | --- |
| `school_years` | Anos lectivos |
| `school_terms` | Períodos lectivos (trimestres/semestres) |
| `school_levels` | Níveis de ensino (primário, secundário, etc.) |
| `school_series` | Séries/classes dentro de um nível |
| `school_courses` | Cursos (para ensino técnico/superior) |
| `school_classes` | Turmas |
| `school_subjects` | Disciplinas |
| `school_teachers` | Professores |
| `school_teacher_assignments` | Vínculo professor-disciplina-turma |
| `school_teacher_roles` | Cargos de professores (director de turma, etc.) |
| `school_students` | Alunos |
| `school_guardians` | Encarregados de educação |
| `school_enrollments` | Matrículas |
| `school_student_roles` | Funções de alunos (chefe de turma, etc.) |
| `school_attendance` | Frequências/presenças |
| `school_grade_items` | Avaliações (fichas, testes, exames) |
| `school_grades` | Notas por aluno e avaliação |
| `school_fee_plans` | Planos de propinas |
| `school_fees` | Cobranças emitidas a alunos |
| `school_fee_generations` | Registo de gerações de cobranças em lote (evita duplicados) |
| `school_payments` | Pagamentos efectuados |
| `school_financial_config` | Configuração de integração financeira por tenant |
| `school_books` | Livros da biblioteca |
| `school_library_loans` | Empréstimos de livros |
| `school_messages` | Comunicados escolares |
| `school_timetable_slots` | Slots de tempo (horários) |
| `school_timetable_entries` | Entradas de horário |
| `school_calendar_event_types` | Tipos de evento do calendário |
| `school_calendar_events` | Eventos do calendário escolar |
| `school_incident_types` | Tipos de ocorrência |
| `school_incidents` | Ocorrências disciplinares/académicas |
| `school_sanctions` | Sanções |
| `school_merits` | Méritos |

Todas as tabelas contêm `tenant_id` e campos de auditoria (`created_at`, `updated_at`, `created_by`).

### Configuração de integração financeira (`school_financial_config`)

| Campo | Descrição | Estado |
| --- | --- | --- |
| `conta_bancaria_id` | Conta bancária para recebimentos escolares | Implementado |
| `criar_movimento_tesouraria` | Cria movimento em `tesouraria.movimentos_financeiros` ao registar pagamento | Implementado |
| `conta_receita_id` | Conta contabilística de receita | Previsto |
| `criar_movimento_financeiro` | Cria factura no módulo Financeiro ao registar pagamento | Previsto |
| `centro_custo_id` | Centro de custo para lançamentos contabilísticos | Previsto |

---

## 11. Fluxos principais

### 11.1 Matrícula de aluno

1. Admin cria nível (`/levels`), série (`/series`) e turma (`/classes`).
2. Secretaria cria aluno em `/students` e adiciona encarregados em `/students/{id}/guardians`.
3. Secretaria cria matrícula em `/enrollments` — sistema valida capacidade da turma.
4. Financeiro gera cobrança: criar plano (`/fee-plans`) e emitir cobrança (`/student-invoices`).

### 11.2 Lançamento de notas

1. Professor cria avaliação em `/grade-items` (tipo, peso, data).
2. Lança notas em lote em `/grades` (array de alunos + nota).
3. Publica avaliação em `/grade-items/{id}/publish`.
4. Boletim fica disponível em `/report-cards/{student_id}`.

### 11.3 Registo de frequência

1. Professor abre chamada: POST `/attendance` com array `students` (student_id + estado).
2. Sistema regista por turma/disciplina/data com upsert (evita duplicados por conflict constraint).
3. Secretaria pode corrigir via PUT `/attendance/{id}`.

### 11.4 Gestão financeira

1. Admin cria plano de propinas (`/fee-plans`) com periodicidade e valor.
2. Sistema gera cobranças em lote via `/fee-plans/{id}/generate` com período de referência.
3. Cobrança emitida via `/student-invoices/{id}/emit`.
4. Pagamento registado via `/payments` — sistema actualiza saldo automaticamente.
5. Se `criar_movimento_tesouraria=true`, cria automaticamente movimento em Tesouraria.
6. Recibo disponível em `/payments/{id}/receipt`.

### 11.5 Horário de aulas

1. Admin cria slots de tempo (hora início/fim, dia da semana) via `/time-slots`.
2. Cria entradas de horário via `/timetables` (turma + disciplina + professor + slot).
3. Sistema detecta conflitos de sala/professor automaticamente.
4. Professor consulta `/timetables/teacher/{teacher_id}`, turma consulta `/timetables/class/{class_id}`.

---

## 12. Adaptação por tipo de ensino

| Tipo de ensino | Configurações específicas |
| --- | --- |
| Primário | Classes 1ª a 7ª, professor único por turma, avaliação por trimestre |
| Secundário | Classes 8ª a 12ª, professores por disciplina, exames na 10ª e 12ª |
| Técnico | Cursos e módulos, carga horária teórica/prática, estágio |
| Pré-universitário | Turmas intensivas, simulados, foco em exames de admissão |
| Superior | Cursos, semestres, créditos, disciplinas optativas |

---

## 13. Considerações de implementação

- Reutilizar o middleware de autenticação e RBAC existente do ERP (`nexora/internal/middleware`).
- Garantir que todas as queries filtrem por `tenant_id`.
- Upsert na frequência evita duplicados: `ON CONFLICT(tenant_id,class_id,student_id,attendance_date,COALESCE(subject_id,0))`.
- Detecção de conflito de horário é tratada pelo `TimetableService`.
- A integração com Tesouraria é **opcional** e controlada por `school_financial_config.criar_movimento_tesouraria`.
- A integração com o módulo Financeiro (`criar_movimento_financeiro`) está prevista mas não implementada.
- Considerar cache Redis para horários e dashboards de alta frequência.
