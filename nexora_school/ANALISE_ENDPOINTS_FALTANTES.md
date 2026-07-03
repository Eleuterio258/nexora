# Análise: Endpoints que Faltam no Mobile `nexora_school`

> Data da análise: 2026-06-30  
> Escopo: comparar o app Flutter `nexora_school` com os endpoints disponíveis no backend Go (`backend/internal/modules/gestao-escolar`).

---

## 1. Resumo Executivo

O mobile `nexora_school` possui **muitas telas desenhadas**, mas praticamente **nenhuma integração real com o backend**.

- O **login** consome a API real (`POST /api/auth/login`).
- Existe um `StudentPortalRemoteDatasource` com **15 endpoints do portal do aluno** já mapeados, mas **nenhuma tela o consome**.
- A **Agenda** usa arquitetura limpa (datasource → repository → usecase → BLoC), porém com dados **locais/estáticos**.
- Todas as demais telas (aluno e professor) trabalham com **dados mockados inline**.

**Conclusão:** o que falta não são só endpoints no backend — a maior parte já existe. Falta implementar no mobile as camadas de repository/usecase/BLoC e conectar as telas aos endpoints já disponíveis.

---

## 2. Endpoints já consumidos pelo mobile

| Método | Endpoint | Tela/Feature | Status real |
|--------|----------|--------------|-------------|
| `POST` | `/api/auth/login` | LoginScreen | ✅ Consumo real da API |
| `GET`  | `/api/portal/aluno/me` | HomeTab / Dashboard | ✅ Consumo real da API |
| `GET`  | `/api/portal/aluno/me/dashboard` | HomeTab | ✅ Consumo real da API |
| `GET`  | `/api/portal/aluno/me/mensagens` | HomeTab | ✅ Consumo real da API |
| `GET`  | `/api/portal/aluno/me/eventos` | HomeTab | ✅ Consumo real da API |
| `GET`  | `/api/portal/aluno/me/boletim` | BoletimTab | ✅ Consumo real da API |

Outras chamadas ainda não estão ligadas às respetivas telas.

---

## 3. Endpoints do portal do aluno já existentes no backend (e não consumidos)

Todos estes endpoints estão prontos no backend e já mapeados em `StudentPortalRemoteDatasource`, mas **nenhuma tela os usa**:

| # | Método | Endpoint | Dados fornecidos | Telas que precisam |
|---|--------|----------|------------------|-------------------|
| 1 | `GET` | `/api/portal/aluno/me` | Perfil completo do aluno + matrícula ativa + encarregados | PerfilTab, EditarPerfilScreen, HomeTab |
| 2 | `POST` | `/api/portal/aluno/logout` | Terminar sessão | Logout |
| 3 | `POST` | `/api/portal/aluno/alterar-senha` | Alterar senha do aluno | SegurancaScreen |
| 4 | `POST` | `/api/portal/aluno/definir-senha` | Primeiro acesso via convite | Onboarding/PIN setup |
| 5 | `GET` | `/api/portal/aluno/me/boletim` | Médias por disciplina, média geral, períodos | BoletimTab |
| 6 | `GET` | `/api/portal/aluno/me/notas` | Detalhe de cada avaliação/nota | BoletimTab (detalhe) |
| 7 | `GET` | `/api/portal/aluno/me/presencas` | Faltas/presenças paginadas | FrequenciaScreen, FaltasScreen |
| 8 | `GET` | `/api/portal/aluno/me/horario` | Horário da turma do aluno | AgendaTab |
| 9 | `GET` | `/api/portal/aluno/me/cobrancas` | Propinas/cobranças do aluno | FinanceiroTab |
| 10 | `GET` | `/api/portal/aluno/me/cobrancas/{id}/recibo` | Dados do recibo | ComprovativoScreen |
| 11 | `POST` | `/api/portal/aluno/me/cobrancas/{id}/pagar` | Iniciar pagamento M-Pesa/e-Mola | FinanceiroTab (botão Pagar) |
| 12 | `GET` | `/api/portal/aluno/me/cobrancas/{id}/pagamento/{gtid}` | Estado do pagamento | FinanceiroTab |
| 13 | `GET` | `/api/portal/aluno/me/mensagens` | Comunicados/mensagens da escola | ChatTab, NoticiasScreen |
| 14 | `GET` | `/api/portal/aluno/me/eventos` | Eventos do calendário escolar | CalendarioScreen |
| 15 | `GET` | `/api/portal/aluno/me/ocorrencias` | Ocorrências disciplinares | Perfil/segurança |
| 16 | `GET` | `/api/portal/aluno/me/biblioteca` | Empréstimos da biblioteca | (tela não existe ainda) |

> **Observação:** o `StudentPortalRemoteDatasource` está registrado no GetIt, mas nenhum BLoC/repository/usecase o utiliza.

---

## 4. Endpoints que faltam no backend para atender telas do aluno

Embora o backend já tenha a base do portal do aluno, algumas telas específicas do mobile **não têm endpoint correspondente**:

| # | Feature/Tela do mobile | O que falta no backend | Sugestão de endpoint |
|---|------------------------|------------------------|----------------------|
| 1 | **HomeTab — resumo académico** (aulas hoje, média, faltas, ranking, atividades pendentes) | Não existe um endpoint consolidado de dashboard/resumo do aluno | `GET /api/portal/aluno/me/dashboard` ou `GET /api/portal/aluno/me/resumo` |
| 2 | **TurmaScreen — detalhes da turma do aluno** | `/api/escolar/classes/{id}` existe, mas requer permissão `gestao-escolar:ver` de funcionário | `GET /api/portal/aluno/me/turma` (dados da turma, colegas, docentes, cargos) |
| 3 | **NoticiasScreen — feed de comunicados** | `/api/portal/aluno/me/mensagens` retorna mensagens, mas não um feed de notícias com tags/categorias | `GET /api/portal/aluno/me/noticias` ou estender `mensagens` com `type=noticia` |
| 4 | **Chat em tempo real** | Apenas WebSocket `/ws/chat` existe; não há API REST de conversas/histórico | Implementar histórico de chat ou usar o WebSocket já existente |
| 5 | **Notificações push/inbox** | Não há endpoint de notificações pessoais do aluno | `GET /api/portal/aluno/me/notificacoes` |
| 6 | **Justificar faltas** | Não há endpoint para envio de justificação | `POST /api/portal/aluno/me/presencas/{id}/justificar` |
| 7 | **Editar perfil** | Não há endpoint para atualizar dados do aluno no portal | `PUT /api/portal/aluno/me` (restrito a campos editáveis) |
| 8 | **Ranking da turma** | Não há endpoint de ranking | `GET /api/portal/aluno/me/turma/ranking` |

---

## 5. Endpoints necessários para o fluxo de professor

O mobile tem telas de professor, mas **não existe nenhum datasource/repository implementado** para professor. O backend já expõe estes endpoints (todos sob `/api/escolar` e requerem autenticação de funcionário + permissões):

| # | Feature/Tela do professor | Endpoint sugerido no backend | Permissão necessária |
|---|---------------------------|------------------------------|----------------------|
| 1 | Login do professor | `POST /api/auth/login` (tipo = funcionário/professor) | Conta ativa no ERP |
| 2 | Home — aulas de hoje/horário | `GET /api/escolar/timetables/teacher/{teacher_id}` | `gestao-escolar:ver` |
| 3 | Lista de turmas | `GET /api/escolar/classes` | `gestao-escolar:ver` |
| 4 | Detalhe da turma | `GET /api/escolar/classes/{id}` | `gestao-escolar:ver` |
| 5 | Alunos da turma | `GET /api/escolar/students?class_id={id}` | `gestao-escolar:ver` |
| 6 | Lançar presenças | `POST /api/escolar/attendance` | `gestao-escolar:gerir_presencas` |
| 7 | Ver/corrigir presenças | `GET /api/escolar/attendance` / `PUT /api/escolar/attendance/{id}` | `gestao-escolar:ver` / `gerir_presencas` |
| 8 | Criar avaliação | `POST /api/escolar/grade-items` | `gestao-escolar:lancar_notas` |
| 9 | Lançar notas | `POST /api/escolar/grades` | `gestao-escolar:lancar_notas` |
| 10 | Listar notas | `GET /api/escolar/grades` | `gestao-escolar:ver` |
| 11 | Criar tarefa | Não existe endpoint específico de "tarefa" no backend escolar | Criar `POST /api/escolar/tasks` ou reutilizar `grade-items` |
| 12 | Criar comunicado | `POST /api/escolar/messages` + `POST /messages/{id}/publish` | `gestao-escolar:gerir_comunicacao` |
| 13 | Relatório da turma | `GET /api/escolar/reports/academic-summary` | `gestao-escolar:relatorios` |
| 14 | Ficha do aluno | `GET /api/escolar/report-cards/{student_id}` | `gestao-escolar:ver` |

> **Nota:** o login do professor atualmente é fake (`professor@nexora.mz`). Para produção, o professor deve usar `/api/auth/login` com uma conta de funcionário do ERP.

---

## 6. Endpoints já existentes no backend (lista completa relevante)

### Portal do Aluno (`/api/portal/aluno`)

```text
POST /definir-senha
GET  /me
POST /logout
POST /alterar-senha
GET  /me/boletim
GET  /me/notas
GET  /me/cobrancas
GET  /me/cobrancas/{id}/recibo
POST /me/cobrancas/{id}/pagar
GET  /me/cobrancas/{id}/pagamento/{gtid}
GET  /me/horario
GET  /me/mensagens
GET  /me/eventos
GET  /me/presencas
GET  /me/ocorrencias
GET  /me/biblioteca
```

### Portal do Encarregado (`/api/portal/encarregado`)

```text
POST /definir-senha
GET  /me
POST /logout
POST /alterar-senha
GET  /me/educandos/{id}/boletim
GET  /me/educandos/{id}/cobrancas
GET  /me/educandos/{id}/presencas
GET  /me/educandos/{id}/ocorrencias
```

### Gestão Escolar (`/api/escolar`) — uso do professor/admin

```text
GET    /years
GET    /years/{id}
GET    /classes
GET    /classes/{id}
GET    /subjects
GET    /subjects/{id}
GET    /students
GET    /students/{id}
GET    /enrollments
GET    /enrollments/{id}
GET    /attendance
GET    /attendance/{id}
POST   /attendance
PUT    /attendance/{id}
GET    /grades
GET    /grades/{id}
POST   /grades
PUT    /grades/{id}
GET    /grade-items
POST   /grade-items
POST   /grade-items/{id}/publish
GET    /fee-plans
GET    /fee-plans/{id}
GET    /student-invoices
GET    /student-invoices/{id}
GET    /payments/{id}
GET    /payments/{id}/receipt
GET    /library/books
GET    /library/loans
GET    /messages
GET    /notificacoes
GET    /teachers
GET    /teachers/{id}
GET    /timetables/class/{class_id}
GET    /timetables/teacher/{teacher_id}
GET    /calendar-events
GET    /calendar-events/{id}
GET    /incidents
GET    /incidents/{id}
GET    /reports/academic-summary
GET    /reports/financial-summary
GET    /report-cards/{student_id}
GET    /dashboard
GET    /dashboard/direction
```

---

## 7. Ordem de prioridade para implementar no mobile

### Prioridade 1 — Portal do Aluno (dados reais)

1. Conectar `StudentPortalRemoteDatasource` às telas via BLoC/repository/usecase.
2. Substituir dados mockados nas telas principais:
   - `HomeTab` → `GET /api/portal/aluno/me` + novo endpoint de resumo.
   - `AgendaTab` → `GET /api/portal/aluno/me/horario`.
   - `BoletimTab` → `GET /api/portal/aluno/me/boletim` + `/me/notas`.
   - `FinanceiroTab` → `GET /api/portal/aluno/me/cobrancas` + pagamento.
   - `FrequenciaScreen`/`FaltasScreen` → `GET /api/portal/aluno/me/presencas`.
   - `CalendarioScreen` → `GET /api/portal/aluno/me/eventos`.
   - `NoticiasScreen` → `GET /api/portal/aluno/me/mensagens`.
   - `PerfilTab`/`EditarPerfilScreen` → `GET /api/portal/aluno/me`.
   - `SegurancaScreen` → `POST /api/portal/aluno/alterar-senha`.

### Prioridade 2 — Ajustes no backend

1. Criar `GET /api/portal/aluno/me/dashboard` (resumo académico para Home).
2. Criar `GET /api/portal/aluno/me/turma` (detalhes da turma do aluno).
3. Criar endpoint para justificar faltas.
4. Criar endpoint para editar perfil do aluno (campos permitidos).
5. Definir endpoint de "tarefa" para o professor ou reutilizar avaliações.

### Prioridade 3 — Fluxo de Professor

1. Implementar datasource/repository/usecase/BLoC para professor.
2. Conectar telas de professor aos endpoints `/api/escolar/*`.
3. Resolver autenticação: login do professor via `/api/auth/login` (não fake).

### Prioridade 4 — Encarregado

1. Implementar fluxo de login como `encarregado`.
2. Criar telas de parent dashboard consumindo `/api/portal/encarregado/*`.

---

## 8. Problemas estruturais encontrados

1. **`BYPASS_API=true` por padrão** — o app nunca usa o backend a menos que seja recompilado com `--dart-define=BYPASS_API=false`.
2. **Telas mockadas** — a maioria das telas tem dados hardcoded, dificultando a substituição por dados reais.
3. **StudentPortalRemoteDatasource "órfão"** — está registrado no DI, mas sem BLoC/repository/usecase.
4. **Cópia de telas de professor** — existem duas pastas (`lib/screens/teacher/` e `lib/teacher/`), sendo a segunda não utilizada.
5. **Cores hardcoded** — muitas telas não respeitam o tema escuro configurado.
6. **Sem tratamento de erro/loading** — telas mockadas não possuem estados de erro ou loading de rede.

---

## 9. Recomendação final

Para "completar" o mobile, o trabalho principal é **no próprio mobile**: implementar as camadas de repository/usecase/BLoC e conectar as telas aos endpoints que **já existem** no backend. O backend precisa de poucos ajustes:

- Resumo/dashboard do aluno.
- Detalhes da turma do aluno.
- Justificação de faltas.
- Edição de perfil do aluno.
- Endpoint de tarefas para professor.

Os demais endpoints (login, boletim, notas, frequência, financeiro, mensagens, eventos, etc.) já estão prontos no backend e só precisam ser consumidos.
