# Análise do Backend do Módulo de Gestão Escolar

## 1. Visão Geral

| Aspecto | Tecnologia / Padrão |
|---|---|
| **Linguagem** | Go 1.25 |
| **Router HTTP** | `go-chi/chi/v5` |
| **Base de Dados** | PostgreSQL (`jackc/pgx/v5`, pool `pgxpool`) |
| **ORM** | Nenhum — SQL nativo parametrizado |
| **Auth** | JWT + sessões na BD + RBAC por permissões |
| **Arquitetura** | Modular por domínio em `internal/modules/*` |
| **Padrão de Integração** | Ports & Adapters (Hexagonal) |
| **Storage** | Abstração própria (Local / MinIO / S3) |
| **Background Jobs** | Goroutines para notificações |
| **Testes** | `pgxmock/v4` + `testify` |

**Entrypoint:** `backend/main.go` carrega configuração, conecta à BD, inicia jobs e monta o router.

**Schemas PostgreSQL:** cada módulo possui seu próprio schema (`gestao_escolar`, `auth`, `rh`, `financeiro`, `tesouraria`, `contabilidade`, `faturacao`, `notifications`, etc.).

---

## 2. Estrutura do Módulo

O módulo de Gestão Escolar está localizado em:

```
backend/internal/modules/gestao-escolar/
├── handlers/              # 23 ficheiros — controllers HTTP
├── models/                # 9 ficheiros — structs de domínio
├── repositories/          # 10 ficheiros — acesso a dados (SQL)
└── services/              # 16 ficheiros — lógica de negócio + testes
```

**Registo de rotas:** `backend/internal/router/router.go`, prefixo `/api/escolar`.

**Portais separados:**
- `/api/portal/aluno` — auto-atendimento do aluno
- `/api/portal/professor` — portal do professor
- `/api/portal/encarregado` — portal do encarregado

---

## 3. Principais Entidades e Tabelas

Todas as tabelas do módulo escolar residem no schema `gestao_escolar`.

| Domínio | Tabelas Principais |
|---|---|
| **Ano letivo / Períodos** | `school_years`, `school_terms` |
| **Estrutura académica** | `school_levels`, `school_cycles`, `school_series`, `school_courses`, `school_course_subjects`, `school_course_subject_terms`, `school_academic_config`, `school_evaluation_types` |
| **Turmas** | `school_classes` |
| **Alunos** | `school_students` |
| **Encarregados** | `school_guardians` |
| **Matrículas** | `school_enrollments` |
| **Professores** | `school_teachers` |
| **Atribuições** | `school_teacher_assignments` |
| **Cargos** | `school_student_roles`, `school_teacher_roles` |
| **Frequências** | `school_attendance` |
| **Avaliações / Notas** | `school_grade_items`, `school_grades`, `school_grade_formulas` |
| **Financeiro escolar** | `school_fee_plans`, `school_fees`, `school_payments`, `school_fee_generations`, `school_fee_installments`, `school_student_fee_discounts`, `school_financial_config` |
| **Horários** | `school_time_slots`, `school_timetable_entries` |
| **Calendário** | `school_calendar_event_types`, `school_calendar_events` |
| **Ocorrências** | `school_incident_types`, `school_sanction_types`, `school_student_incidents`, `school_student_sanctions`, `school_student_merits` |
| **Biblioteca** | `school_books`, `school_library_loans` |
| **Comunicação** | `school_messages` |
| **Histórico académico** | `school_academic_transcripts`, `school_transcript_subjects` |
| **Portais** | colunas `portal_*` em `school_students`/`school_guardians`, tabelas `portal_sessions`, `guardian_portal_sessions` |

---

## 4. API e Rotas Principais

### 4.1 Administração Escolar (`/api/escolar`)

**Grupos de permissão utilizados:**

- `ver` — leitura geral
- `relatorios` — relatórios
- `gerir_turmas` — estrutura académica, turmas, disciplinas, professores
- `gerir_alunos` — alunos e encarregados
- `gerir_matriculas` — matrículas
- `gerir_presencas` — frequências
- `lancar_notas` — avaliações e notas
- `gerir_propinas` — planos, cobranças, pagamentos, bolsas, parcelas
- `gerir_biblioteca`, `gerir_comunicacao`, `gerir_horarios`, `gerir_calendario`, `gerir_ocorrencias`
- `portal_aluno` — gestão de acesso aos portais

| Endpoint | Método | Handler / Função |
|---|---|---|
| `/api/escolar/years` | GET / POST | Listar / Criar Ano Letivo |
| `/api/escolar/years/{id}/terms` | POST | Criar Período Letivo |
| `/api/escolar/classes` | GET / POST | Listar / Criar Turma |
| `/api/escolar/classes/{id}` | PUT | Atualizar Turma |
| `/api/escolar/students` | GET / POST | Listar / Criar Aluno |
| `/api/escolar/students/{id}/guardians` | POST | Adicionar Encarregado |
| `/api/escolar/enrollments` | POST | Criar Matrícula |
| `/api/escolar/enrollments/{id}/transfer` | POST | Transferir Matrícula |
| `/api/escolar/attendance` | POST / PUT | Lançar / Corrigir Frequência |
| `/api/escolar/grade-items` | GET / POST | Listar / Criar Avaliação |
| `/api/escolar/grade-items/{id}/publish` | POST | Publicar Avaliação |
| `/api/escolar/grades` | POST | Lançar Notas |
| `/api/escolar/report-cards/{student_id}` | GET | Obter Boletim |
| `/api/escolar/fee-plans/{id}/generate` | POST | Gerar Cobranças do Plano |
| `/api/escolar/payments` | POST | Registar Pagamento Escolar |
| `/api/escolar/config/financial` | GET / POST | Configuração Financeira |

### 4.2 Portais

**Portal do Aluno (`/api/portal/aluno`)**
- `POST /definir-senha`
- `GET /me`, `GET /me/boletim`, `GET /me/notas`, `GET /me/cobrancas`, `GET /me/horario`, `GET /me/presencas`, `GET /me/ocorrencias`, `GET /me/biblioteca`
- `POST /me/cobrancas/{id}/pagar`

**Portal do Professor (`/api/portal/professor`)**
- `GET /me/turmas`, `GET /me/horario`
- `POST /me/presencas`, `POST /me/notas`

**Portal do Encarregado (`/api/portal/encarregado`)**
- `GET /me/educandos/{id}/boletim`
- `GET /me/educandos/{id}/cobrancas`
- `GET /me/educandos/{id}/presencas`
- `GET /me/educandos/{id}/ocorrencias`

---

## 5. Services, Use Cases e Repositórios

### Repositórios (`repositories/`)

Cada repositório recebe a interface `DB` (pool ou mock) e executa SQL parametrizado.

| Repositório | Responsabilidade |
|---|---|
| `FeeRepository` | Planos, cobranças, pagamentos, configuração financeira |
| `EnrollmentRepository` | Matrículas, transferências, cancelamentos |
| `ClassRepository` | Turmas e capacidade |
| `GradeRepository` | Avaliações e notas |
| `TeacherRepository` | Professores |
| `AcademicStructureRepository` | Níveis, séries, cursos |
| `TimetableRepository` | Horários |
| `CalendarRepository` | Calendário escolar |
| `IncidentRepository` | Ocorrências e sanções |

### Services (`services/`)

Contêm a lógica de negócio e validações.

| Service | Responsabilidade |
|---|---|
| `FeeService` | Geração de cobranças, descontos, registo de pagamento e integrações financeiras |
| `EnrollmentService` | Criação de matrícula com validação de capacidade e duplicados |
| `ClassService` | Criação / atualização de turmas e verificação de vagas |
| `GradeService` | Criação de avaliações, lançamento de notas, boletim |
| `TeacherService` | Gestão de professores |
| `AcademicStructureService` | Estrutura académica |
| `TimetableService` | Horários |
| `CalendarService` | Calendário |
| `IncidentService` | Ocorrências |

### Injeção de Dependências

No `Handler` (`handlers/handler.go`), os repositórios são criados no construtor `New(...))`.
Os services são instanciados sob demanda nos métodos auxiliares:

```go
func (h *Handler) feeService() *services.FeeService {
    return services.NewFeeService(h.feeRepo, h.treasury, h.financial, h.accounting, h.invoicing)
}
```

---

## 6. Integrações com Outros Módulos

O módulo escolar desacopla-se via `internal/shared/contracts/erp_ports.go` e adapters em `internal/shared/adapters/`.

| Port | Módulo Destino | Uso no Escolar |
|---|---|---|
| `TreasuryPort` | Tesouraria | Registar recebimentos em `tesouraria.movements` |
| `FinancialPort` | Financeiro | Criar conta a receber + pagamento |
| `AccountingPort` | Contabilidade | Criar lançamentos contabilísticos |
| `InvoicingPort` | Faturação | Emitir recibos tipo RB |
| `NotificationPort` | Notificações | Enviar e-mails/SMS de cobranças, notas, matrículas |
| `HRPort` | Recursos Humanos | Criar/ligar funcionário para professor |
| `ClientPort` | Gestão de Clientes | Criar/ligar cliente para aluno/encarregado |
| `ApprovalPort` | Aprovações | Fluxo de aprovação para descontos |
| `SystemConfigPort` | Sistema / Configuração | Ler/gravar settings por tenant |

### Ligações de Dados (FKs opcionais)

- `school_teachers.rh_employee_id → rh.funcionarios`
- `school_students.client_id → clientes.customers`
- `school_guardians.client_id → clientes.customers`

---

## 7. Documentação Relevante

| Ficheiro | Conteúdo |
|---|---|
| `backend/analise_modulo_gestao_escolar.md` | Análise inicial do módulo escolar |
| `backend/relatorio_completo_gestao_escolar.md` | Relatório atualizado com portais, cargos, escopo e integrações |
| `backend/correcoes_aplicadas.md` | Correções aplicadas (permissões, dashboard, MinIO, etc.) |
| `backend/analise_banco_nexora_erp.md` | Análise geral do banco de dados |
| `backend/analise_migracao_minio.md` | Migração de storage para MinIO |
| `documentacao_banco_dados_nexora_organizada.md` | Documentação do banco na raiz do projeto |
| `docs/analise-implementacao-escolar.md` | Análise de implementação escolar |

---

## 8. Pontos Fortes

1. **Arquitetura modular e desacoplada** — separação clara entre handlers, services, repositories e ports/adapters.
2. **Multi-tenant consistente** — todas as tabelas escolares têm `tenant_id`.
3. **Integrações financeiras configuráveis** — propinas podem gerar movimentos em tesouraria, financeiro, contabilidade e faturação.
4. **Portais separados** — aluno, professor e encarregado têm APIs e autenticação próprias.
5. **Migrations idempotentes** — uso extensivo de `IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`, seeds condicionais.
6. **Testes unitários iniciados** — services testados com `pgxmock`.
7. **Notificações assíncronas** — envio de e-mails não bloqueia o request principal.
8. **Suporte a múltiplos níveis de ensino** — primário, secundário, técnico, superior.

---

## 9. Problemas Arquiteturais e Riscos

1. **Mix de padrões nos handlers**
   - Alguns handlers usam services tipados (`turmas_matriculas.go`, `grades.go`, `fees.go`).
   - Outros usam SQL inline massivo com `jsonb_to_record` e concatenação de strings (`escolar.go`, `operacoes.go`, `academico.go`).
   - Isto fragmenta a arquitetura e dificulta testes.

2. **Risco de injeção SQL / manutenção perigosa**
   - Embora os valores sejam parametrizados, há concatenação de cláusulas `WHERE` e nomes de colunas. O impacto real é limitado, mas a manutenção é arriscada.

3. **Configuração financeira incompleta na API**
   - `config.go` só expõe 4 campos, mas a migration `077` adicionou mais 5 (`criar_lancamento_contabilidade`, `conta_debito_id`, `conta_credito_id`, `criar_recibo_faturacao`, `customer_group_id`).

4. **Goroutines sem controlo**
   - Notificações em background são lançadas sem fila, circuit breaker ou rate limit. Falhas repetidas podem acumular goroutines.

5. **Adapters inserem em schemas externos sem verificação**
   - `TreasuryAdapter`, `FinancialAdapter`, etc. assumem que tabelas como `tesouraria.movements`, `financeiro.accounts_receivable` existem. Em fresh installs podem falhar.

6. **Dependência de `search_path`**
   - Muitas queries usam nomes qualificados (`gestao_escolar.school_*`), mas o `search_path` padrão na config inclui dezenas de schemas, o que pode causar confusão.

7. **Código duplicado / legado**
   - `FeeRepository.CreateFinancialReceivable` e `FeeRepository.CreateTreasuryMovement` parecem legados; o caminho principal agora é via ports.

8. **Comentários com mojibake**
   - `router.go` e outros ficheiros têm comentários com caracteres corrompidos, dificultando manutenção.

---

## 10. Oportunidades de Melhoria

1. **Padronizar todos os handlers para usar services/models**
   - Migrar SQL inline de `escolar.go`, `operacoes.go` e `academico.go` para services/repositories tipados.

2. **Usar query builder**
   - Adotar `squirrel` ou `goqu` para queries dinâmicas seguras.

3. **Completar API de configuração financeira**
   - Expor todos os campos da `school_financial_config`.

4. **Adicionar fila de notificações**
   - Substituir goroutines soltas por uma fila controlada (tabela de jobs ou message broker).

5. **Melhorar adapters**
   - Verificar existência de schemas/tabelas antes de inserir; retornar erros graciosos.

6. **Aumentar cobertura de testes**
   - Testes ponta-a-ponta para matrículas, pagamentos e portais.

7. **Documentar fluxos financeiros**
   - Criar diagrama do fluxo propina → cobrança → pagamento → integrações.

8. **Revisar permissões por perfil**
   - Validar que `Director de Turma`, `Chefe de Turma`, professor, secretaria e direção têm exatamente os acessos necessários.

---

## 11. Conclusão

O backend do módulo de Gestão Escolar do Nexora está em fase avançada, com cobertura funcional abrangente (académico, administrativo, financeiro, biblioteca, comunicação, portais) e uma arquitetura sólida baseada em Ports & Adapters.

Os principais riscos atuais são:
- Inconsistência entre SQL inline e services tipados
- API de configuração financeira incompleta
- Falta de controlo sobre processamento assíncrono de notificações

Com as correções indicadas, o módulo estará bem posicionado para produção.

---

*Análise gerada automaticamente a partir da estrutura do projeto.*
