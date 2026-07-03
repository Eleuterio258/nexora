# Análise do Módulo de Gestão Escolar — Nexora

**Data:** 2026-06-28  
**Escopo:** Frontend (PHP 8.3) + Backend (Go 1.23)  
**Autor:** Kimi Code CLI

---

## 1. Resumo Executivo

O módulo de **Gestão Escolar** do Nexora cobre todo o ciclo académico: anos letivos, estrutura curricular, turmas, alunos, matrículas, professores, frequências, avaliações, notas, horários, calendário, ocorrências, propinas, biblioteca, comunicação e portal do aluno.

- **Backend:** Go 1.23 com arquitetura **Ports & Adapters (Hexagonal)**, separando repositories, services e handlers.
- **Frontend:** PHP 8.3 puro com **MVC customizado**, atuando como *thin client/proxy* do backend.
- **Integração:** REST JSON entre frontend PHP e backend Go.

O módulo está funcional e arquitetonicamente sólido, mas apresenta **problemas críticos de permissões e bugs de runtime** que devem ser corrigidos antes da produção para utilizadores não-superadmin.

---

## 2. Stack Tecnológica

| Camada | Tecnologia | Padrão |
|---|---|---|
| **Backend** | Go 1.23, Chi Router, PostgreSQL (pgx), JWT, bcrypt | Hexagonal / Repository-Service-Handler |
| **Frontend** | PHP 8.3 puro, Apache, cURL | MVC customizado + SSR |
| **UI** | CSS vanilla, JS vanilla, Font Awesome, Google Fonts | Design system próprio (`nexora.css`) |
| **Comunicação** | REST JSON | Frontend PHP → Backend Go |

---

## 3. Estrutura do Backend

```
internal/modules/gestao-escolar/
├── handlers/          # 16 ficheiros HTTP handlers
├── models/            # 9 ficheiros de structs de domínio
├── repositories/      # 10 ficheiros de acesso a dados
└── services/          # 10 ficheiros de lógica de negócio + 5 testes
```

As rotas estão centralizadas em `internal/router/router.go`, sob os prefixos:

- `/api/escolar` — administração escolar (requer `gestao-escolar` + ação específica)
- `/api/portal/aluno` — portal do aluno (auth própria)

### 3.1 Modelos de Dados Principais

| Entidade | Tabela(s) | Observações |
|---|---|---|
| Ano letivo | `school_years`, `school_terms` | Status: rascunho/ativo/encerrado |
| Estrutura académica | `school_levels`, `school_cycles`, `school_series`, `school_courses`, `school_course_subjects` | Níveis, ciclos, séries, cursos, disciplinas |
| Turmas | `school_classes` | Capacidade, professor director, horário JSONB |
| Alunos | `school_students` | Dados pessoais, documentos, contactos |
| Encarregados | `school_guardians` | Vários por aluno; flag `principal` |
| Matrículas | `school_enrollments` | Ativa, suspensa, cancelada, concluída, transferida |
| Professores | `school_teachers` | Código único, carga horária máxima |
| Atribuições | `school_teacher_assignments` | Professor ↔ disciplina ↔ turma |
| Frequências | `school_attendance` | Por turma/aluno/data/disciplina |
| Avaliações/Notas | `school_grade_items`, `school_grades` | Itens publicáveis; notas com peso e nota máxima |
| Propinas | `school_fee_plans`, `school_fees`, `school_payments` | Planos, cobranças, pagamentos, descontos |
| Horários | `school_time_slots`, `school_timetable_entries` | Slots e horários |
| Calendário | `school_calendar_event_types`, `school_calendar_events` | Tipos de evento com impacto na frequência |
| Ocorrências | `school_incident_types`, `school_student_incidents`, `school_student_sanctions`, `school_student_merits` | Ocorrências, sanções e méritos |
| Biblioteca | `school_books`, `school_library_loans` | Livros e empréstimos |
| Comunicação | `school_messages` | Comunicados com audiência |
| Portal do aluno | `portal_sessions` + colunas em `school_students` | Auth própria |
| Config financeira | `school_financial_config` | Flags de integração com finanças |

### 3.2 Integrações com Outros Módulos

O módulo escolar desacopla-se via `internal/shared/contracts/erp_ports.go`:

| Port | Uso |
|---|---|
| `TreasuryPort` | Regista recebimentos em tesouraria |
| `FinancialPort` | Cria conta a receber + pagamento |
| `AccountingPort` | Lançamentos contabilísticos |
| `InvoicingPort` | Emite recibos (tipo RB) |
| `NotificationPort` | Grava notificações |
| `HRPort` | Liga/cria funcionário em RH |
| `ClientPort` | Resolve/cria cliente |
| `ApprovalPort` | Fluxo de aprovação |
| `SystemConfigPort` | Settings do sistema |

### 3.3 Autorização

- JWT + sessão na BD (`auth.sessions`).
- RBAC via `auth.models.LoadUserAccess`, mergeando permissões de cargo, permissões diretas e permissões por tipo.
- Middleware `RequirePermission` / `RequirePermissionAny`.
- Portal do aluno usa JWT separado com claim `tipo=aluno`.

---

## 4. Estrutura do Frontend

```
frontend/
├── index.php                 # Front controller
├── src/
│   ├── Controller/
│   │   ├── Admin/Api/GestaoEscolarController.php
│   │   ├── Admin/AdminApiRuntime.php
│   │   └── Portal/PortalAlunoController.php
│   ├── Core/Application.php
│   ├── Http/
│   ├── Infrastructure/
│   │   ├── Auth/
│   │   ├── Http/CurlHttpClient.php
│   │   ├── Nexora/NexoraClient.php
│   │   └── Security/WebSecurity.php
│   ├── Model/Service/School/SchoolService.php
│   ├── Routing/
│   │   ├── AdminRoutes.php
│   │   └── AdminApiRoutes.php
│   └── View/templates/
│       ├── partials/
│       │   ├── escolar_resources.php
│       │   └── operational_workspace.php
│       ├── pages/escolar_*.php (32 páginas)
│       └── portal/
└── assets/
    ├── css/nexora.css
    └── js/script.js
```

### 4.1 Páginas Escolares (32 rotas sob `/nexora/gestao-escolar/*`)

| Categoria | Páginas |
|---|---|
| Académico | dashboard, anos-lectivos, níveis, séries, cursos, turmas, disciplinas, atribuições, horários, calendário |
| Pessoas | alunos, matrículas, professores, cargos de alunos/professores, ocorrências |
| Avaliação | frequência, avaliações, notas, boletins |
| Financeiro | planos de cobrança, cobranças, pagamentos, inadimplência, config. financeira |
| Biblioteca | biblioteca, empréstimos |
| Comunicação/Relatórios | comunicação, resumo académico, resumo financeiro |

### 4.2 Padrão de UI: CRUD Declarativo

A maioria das páginas escolares:

1. Inclui `partials/escolar_resources.php`.
2. Define um `$workspace` com título, endpoint e recursos.
3. Inclui `partials/operational_workspace.php`, que renderiza tabela, filtros, paginação, modais e dispara `fetch` para `/nexora/api/escolar_operacao`.

### 4.3 Autenticação e Permissões

- Sessões PHP armazenam JWT do backend.
- Refresh automático de token próximo da expiração.
- Sincronização de permissões a cada 5 minutos.
- CSRF obrigatório em operações de escrita.
- Portal do aluno com sessão separada.

---

## 5. Endpoints Principais Consumidos

### Admin escolar (`/api/escolar/*`)

| Operação | Método | Endpoint |
|---|---|---|
| Listar anos lectivos | GET | `/api/escolar/years` |
| Criar turma | POST | `/api/escolar/classes` |
| Atualizar turma | PUT | `/api/escolar/classes/{id}` |
| Criar aluno | POST | `/api/escolar/students` |
| Criar matrícula | POST | `/api/escolar/enrollments` |
| Transferir matrícula | POST | `/api/escolar/enrollments/{id}/transfer` |
| Lançar frequência | POST | `/api/escolar/attendance` |
| Criar avaliação | POST | `/api/escolar/grade-items` |
| Lançar nota | POST | `/api/escolar/grades` |
| Ver boletim | GET | `/api/escolar/report-cards/{student_id}` |
| Criar horário | POST | `/api/escolar/timetables` |
| Criar ocorrência | POST | `/api/escolar/incidents` |
| Registar pagamento | POST | `/api/escolar/payments` |
| Comunicados | POST | `/api/escolar/messages` |

### Portal do aluno (`/api/portal/aluno/*`)

| Rota | Descrição |
|---|---|
| `POST /login` | Autenticação |
| `GET /me` | Dados do aluno |
| `GET /me/boletim` | Notas por período |
| `GET /me/cobrancas` | Propinas |
| `GET /me/horario` | Horário da turma |
| `GET /me/presencas` | Assiduidade |
| `GET /me/ocorrencias` | Incidentes/sanções/méritos |
| `GET /me/mensagens` | Avisos |
| `GET /me/eventos` | Eventos |
| `GET /me/biblioteca` | Empréstimos |

---

## 6. Pontos Fortes

### Backend

1. Desacoplamento bem estruturado via Ports & Adapters.
2. Multi-tenant consistente.
3. Lógica de negócio centralizada nos services.
4. Integrações financeiras configuráveis.
5. Portal do aluno com auth independente.
6. Migrações idempotentes.
7. Testes unitários iniciados com pgxmock.

### Frontend

1. Simplicidade e rapidez de desenvolvimento com PHP vanilla.
2. Separação MVC clara.
3. Segurança básica robusta (CSRF, rate-limit, refresh de tokens).
4. Reutilização via `operational_workspace.php`.
5. Integração transversal completa com ERP.
6. Testes de arquitetura garantem pureza da camada Model.

---

## 7. Problemas Críticos

### 7.1 Backend

| # | Problema | Ficheiros Afetados | Impacto |
|---|---|---|---|
| 1 | **Inconsistência de permissões**: seeds usam `ver_escolar`, `gerir_academico`, etc.; router exige `ver`, `gerir_turmas`, `gerir_alunos`, `gerir_matriculas`, `lancar_notas`, etc. | `migrations/066_permissoes_gestao_escolar.sql`, `internal/router/router.go` | **403 em quase todas as rotas** para utilizadores padrão |
| 2 | **Bug no dashboard**: query usa `estado='aberto'` em vez de `status='aberto'` | `internal/modules/gestao-escolar/handlers/comunicacao.go` | **Erro em runtime** no dashboard escolar |
| 3 | **Configuração financeira incompleta**: handler expõe apenas 4 campos; migration 077 adicionou 5 campos adicionais não geridos | `internal/modules/gestao-escolar/handlers/config.go`, `migrations/077_gestao_escolar_config_integracao_completa.sql` | Configuração financeira avançada **inacessível via API** |
| 4 | **SQL inline com concatenação de strings** | `escolar.go`, `academico.go`, `comunicacao.go` | Risco de injeção e manutenção difícil |
| 5 | **Mix arquitetural**: SQL inline com `jsonb_to_record` lado a lado com services tipados | Vários handlers | Fragmentação e dificuldade de testes |
| 6 | **Notificações em goroutines sem controle** | Matrículas, notas, comunicados | Goroutines acumuladas em caso de falhas repetidas |
| 7 | **Ligação professor-RH mal aproveitada** | `internal/modules/gestao-escolar/handlers/ligacoes.go` | Semântica confusa do `HRPort` |
| 8 | **Adapters inserem em schemas externos sem verificar existência** | `internal/shared/adapters/*` | Falhas em fresh installs |

### 7.2 Frontend

| # | Problema | Impacto |
|---|---|---|
| 1 | Sem Composer/PHPUnit/bundler — dependências via CDN | Difícil escalar testes e gestão de dependências |
| 2 | `operational_workspace.php` monolítico (~400 linhas) misturando PHP/HTML/CSS/JS | Baixa testabilidade e manutenibilidade |
| 3 | Formulários exigem IDs numéricos manuais | Erros de dados e má UX |
| 4 | Ausência de select boxes com busca/popup | Fluxos lentos e propensos a erro |
| 5 | Estilos inline frequentes | Design system inconsistente |
| 6 | Dependência total do backend; falhas silenciosas | Pouca resiliência |
| 7 | Validação limitada; sem máscaras | Dados incorretos frequentes |
| 8 | Sem testes de integração de views/serviços | Regressões difíceis de detectar |

---

## 8. Recomendações

### Curto Prazo (Bloqueantes)

1. **Corrigir e alinhar permissões** entre `migration 066` e `router.go`.
2. **Corrigir o bug do dashboard** (`estado` → `status`).
3. **Completar a API de configuração financeira** com os campos da migration `077`.
4. **Adicionar verificação de existência de schemas** nos adapters antes de inserir.

### Médio Prazo

5. Padronizar handlers para usar services/models, reduzindo SQL inline.
6. Parametrizar queries dinâmicas ou adotar `squirrel`/`goqu`.
7. Revisar ligação professor-RH para usar corretamente o `HRPort`.
8. Adicionar select boxes com busca no frontend para entidades relacionadas.
9. Implementar filas/controlador de concorrência para notificações em background.

### Longo Prazo

10. Aumentar cobertura de testes no backend (fluxos felizes, pagamentos, portal).
11. Refactorar `operational_workspace.php` em componentes menores.
12. Adicionar testes de integração no frontend.
13. Avaliar adoção de HTMX ou componentes leves para melhorar UX sem perder a simplicidade do SSR.

---

## 9. Cobertura Funcional

| Domínio | Backend | Frontend |
|---|---|---|
| Ano letivo / períodos | ✅ | ✅ |
| Estrutura académica | ✅ | ✅ |
| Turmas | ✅ | ✅ |
| Alunos e encarregados | ✅ | ✅ |
| Matrículas, transferências, cancelamentos | ✅ | ✅ |
| Professores e atribuições | ✅ | ✅ |
| Disciplinas | ✅ | ✅ |
| Frequências | ✅ | ✅ |
| Avaliações e notas | ✅ | ✅ |
| Boletins / relatórios académicos | ✅ | ✅ |
| Horários | ✅ | ✅ |
| Calendário escolar | ✅ | ✅ |
| Ocorrências, sanções, méritos | ✅ | ✅ |
| Propinas / planos / cobranças / pagamentos | ✅ | ✅ |
| Integração financeira completa | ✅ | ⚠️ config incompleta |
| Biblioteca | ✅ | ✅ |
| Comunicação / mensagens | ✅ | ✅ |
| Portal do aluno | ✅ | ✅ |

---

## 10. Conclusão

O módulo de Gestão Escolar é **funcional e abrangente**, com boa arquitetura no backend e desenvolvimento ágil no frontend. No entanto, os **problemas de permissões e o bug do dashboard são bloqueantes** para utilização por utilizadores não-superadmin. A configuração financeira avançada também precisa ser exposta pela API. Após essas correções, o módulo estará em condições de produção, devendo-se seguir com melhorias de UX no frontend e padronização arquitetural no backend.
