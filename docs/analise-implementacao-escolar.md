# Análise de Implementação — Módulo Escolar

## 1. Resumo executivo

O módulo **Gestão Escolar** já tem uma base sólida de backend em Go e um Painel Escolar independente (`/escola/*`) em PHP. A maioria das funcionalidades administrativas e financeiras da Secretaria/Direção está implementada, bem como o **Portal do Aluno** e o **Portal do Encarregado**.

O maior gap está na **experiência do Professor**, **Director de Turma** e **Chefe de Turma**: não existe um painel/portal específico com escopo limitado a turmas/disciplinas atribuídas, nem funcionalidades como planos de aula, conteúdos leccionados, pedidos do aluno e comunicados com controlo de leitura.

---

## 2. Backend Go — Endpoints `/api/escolar/*`

### 2.1 Estrutura académica e cadastro
| Área | Endpoints principais | Estado |
|---|---|---|
| Anos lectivos | `GET/POST/PUT /years`, `/years/{id}/activate`, `/close`, `/terms` | ✅ Implementado |
| Níveis de ensino | `GET/POST/PUT/DELETE /levels` | ✅ Implementado |
| Séries | `GET/POST/PUT/DELETE /series` | ✅ Implementado |
| Cursos | `GET/POST/PUT/DELETE /courses` | ✅ Implementado |
| Turmas | `GET/POST/PUT /classes`, `/classes/{id}/assign-teacher` | ✅ Implementado |
| Disciplinas | `GET/POST /subjects`, atribuições via `/teacher-assignments` | ✅ Implementado |

### 2.2 Alunos, professores e matrículas
| Área | Endpoints principais | Estado |
|---|---|---|
| Professores | `GET/POST/PUT/DELETE /teachers`, link a RH `/teachers/{id}/rh-link` | ✅ Implementado |
| Alunos | `GET/POST/PUT /students`, encarregados `/students/{id}/guardians`, link a cliente | ✅ Implementado |
| Matrículas | `GET/POST /enrollments`, `/enrollments/{id}/transfer`, `/cancel` | ✅ Implementado |
| Cargos alunos/professores | `/student-roles`, `/teacher-roles` | ✅ Implementado |

### 2.3 Frequência, notas e avaliações
| Área | Endpoints principais | Estado |
|---|---|---|
| Frequência | `GET/POST/PUT /attendance` | ✅ Implementado |
| Avaliações | `GET/POST /grade-items`, `/grade-items/{id}/publish` | ✅ Implementado |
| Notas | `GET/POST/PUT /grades` | ✅ Implementado |
| Boletins | `GET /report-cards/{student_id}` | ✅ Implementado |

### 2.4 Financeiro escolar
| Área | Endpoints principais | Estado |
|---|---|---|
| Planos de propinas | `GET/POST /fee-plans`, `/fee-plans/{id}/generate` | ✅ Implementado |
| Cobranças | `GET/POST /student-invoices`, emitir, cancelar, parcelar, descontos | ✅ Implementado |
| Pagamentos | `POST /payments`, callback, recibo | ✅ Implementado |
| Configuração financeira | `GET/POST /config/financial` | ✅ Implementado |
| Bolsas | `GET/POST/DELETE /bolsas` | ✅ Implementado |
| Aging | `GET /relatorios/aging` | ✅ Implementado |

### 2.5 Horários e calendário
| Área | Endpoints principais | Estado |
|---|---|---|
| Horários | `/time-slots`, `/timetables/class/{id}`, `/timetables/teacher/{id}`, CRUD horário | ✅ Implementado |
| Calendário | CRUD `/calendar-event-types` e `/calendar-events` | ✅ Implementado |

### 2.6 Ocorrências e biblioteca
| Área | Endpoints principais | Estado |
|---|---|---|
| Ocorrências | `/incident-types`, `/incidents`, `/sanctions`, `/merits` | ✅ Implementado |
| Biblioteca | `/library/books`, `/library/loans`, `/library/loans/{id}/return` | ✅ Implementado |

### 2.7 Comunicação, relatórios e dashboards
| Área | Endpoints principais | Estado |
|---|---|---|
| Dashboards | `/dashboard`, `/dashboard/direction` | ✅ Implementado |
| Relatórios | `/reports/academic-summary`, `/reports/financial-summary`, `/reports/delinquency` | ✅ Implementado |
| Comunicação | `GET/POST /messages`, `/messages/{id}/publish`, notificações | ✅ Implementado (básico) |

### 2.8 Portal do aluno e encarregado
| Área | Endpoints principais | Estado |
|---|---|---|
| Auth portal | `/api/portal/aluno/login`, `/definir-senha`, `/alterar-senha` | ✅ Implementado |
| Dados aluno | `/api/portal/aluno/me`, boletim, notas, cobranças, recibo, horário, mensagens, eventos, presenças, ocorrências, biblioteca | ✅ Implementado |
| Pagamentos online | `/api/portal/aluno/me/cobrancas/{id}/pagar`, `/pagamento/{gtid}` | ✅ Implementado |
| Portal encarregado | `/api/portal/encarregado/*` (login, me, boletim, cobranças, presenças, ocorrências) | ✅ Implementado |
| Gestão admin do portal | `/api/escolar/portal/*`, convites, reset de senha, ativação | ✅ Implementado |

---

## 3. Frontend PHP — Páginas e Rotas

### 3.1 Painel Escolar (`/escola/*`)

**Páginas existentes** (`frontend/src/View/templates/pages/escolar_*.php`):

- `escolar_dashboard.php`
- `escolar_anos_lectivos.php`
- `escolar_niveis.php`
- `escolar_series.php`
- `escolar_cursos.php`
- `escolar_turmas.php`
- `escolar_disciplinas.php`
- `escolar_professores.php`
- `escolar_atribuicoes.php`
- `escolar_horarios.php`
- `escolar_calendario.php`
- `escolar_alunos.php`
- `escolar_matriculas.php`
- `escolar_cargos_alunos.php`
- `escolar_cargos_professores.php`
- `escolar_ocorrencias.php`
- `escolar_frequencia.php`
- `escolar_avaliacoes.php`
- `escolar_notas.php`
- `escolar_boletins.php`
- `escolar_planos_cobranca.php`
- `escolar_cobrancas.php`
- `escolar_pagamentos.php`
- `escolar_inadimplencia.php` (também usada para bolsas temporariamente)
- `escolar_biblioteca.php`
- `escolar_emprestimos.php`
- `escolar_comunicacao.php`
- `escolar_resumo_academico.php`
- `escolar_resumo_financeiro.php`
- `escolar_config_financeira.php`

**Rotas mapeadas** em `frontend/index.php` e `frontend/src/Routing/SchoolAdminRoutes.php`: todas as páginas acima estão disponíveis sob `/escola/<slug>`.

### 3.2 Portal do Aluno (`/portal/aluno/*`)

**Páginas existentes** (`frontend/src/View/templates/portal/*.php`):

- `login.php`, `definir_senha.php`
- `dashboard.php`
- `perfil.php`, `conta.php`
- `boletim.php`, `boletim_print.php`
- `cobrancas.php`, `recibo_print.php`
- `horario.php`
- `ocorrencias.php`
- `biblioteca.php`
- `mensagens.php`
- `eventos.php`
- `presencas.php`

**Rotas mapeadas** em `frontend/index.php`: `/portal/aluno/dashboard`, `/perfil`, `/boletim`, `/boletim/imprimir`, `/cobrancas`, `/horario`, `/ocorrencias`, `/biblioteca`, `/mensagens`, `/eventos`, `/presencas`, `/conta`, etc.

### 3.3 Portal do Encarregado (`/portal/encarregado/*`)

**Páginas existentes** (`frontend/src/View/templates/portal_encarregado/*.php`):

- `login.php`, `definir_senha.php`
- `dashboard.php`
- `boletim.php`
- `cobrancas.php`
- `presencas.php`
- `ocorrencias.php`
- `conta.php`

### 3.4 Portal do Professor / Director de Turma / Chefe de Turma

**Não existe** pasta `frontend/src/View/templates/portal_professor/`.

---

## 4. Gaps vs. Requisitos

### 4.1 Requisitos do Professor

| Requisito | Backend | Frontend | Observação |
|---|---|---|---|
| RF-01 — Consultar turmas/disciplinas/horários | ✅ Parcial | ❌ | Existe backend admin; falta API e portal com escopo do professor |
| RF-02 — Alunos por turma | ✅ Parcial | ❌ | Backend genérico; falta filtro "turmas do professor" |
| RF-03 — Presenças/faltas | ✅ | ❌ | Endpoint existe, mas sem interface para professor |
| RF-04 — Lançar notas | ✅ | ❌ | Endpoint existe, mas sem interface para professor |
| RF-05 — Histórico académico dos alunos | ✅ Parcial | ❌ | Falta endpoint/read-model para o professor consultar |
| RF-06 — Planos de aula | ❌ | ❌ | Não existe tabela/endpoint |
| RF-07 — Conteúdos leccionados | ❌ | ❌ | Não existe |
| RF-08 — Comunicar com alunos/encarregados | ✅ Parcial | ❌ | Endpoint de mensagens existe, mas não segmentado por turma do professor |
| RF-09 — Calendário escolar | ✅ | ❌ | Sem interface professor |
| RF-10 — Pautas e relatórios | ✅ Parcial | ❌ | Relatórios académicos existem, mas sem geração de pauta por professor |
| RF-11 — Observações pedagógicas | ❌ | ❌ | Não existe |
| RF-12 — Solicitar correção de notas | ❌ | ❌ | Não existe fluxo de aprovação |
| RF-13 — Acompanhamento financeiro condicional | ❌ | ❌ | Não existe configuração/permissão |
| RF-14 — Portal do professor | ❌ | ❌ | Não existe |

### 4.2 Requisitos de Direcção e Secretaria

| Requisito | Backend | Frontend | Observação |
|---|---|---|---|
| Dashboard executivo | ✅ | ✅ | Existem `/dashboard` e `/dashboard/direction` |
| Relatórios diversos | ✅ Parcial | ✅ | Faltam filtros avançados por período/estado em alguns relatórios |
| Aprovação de matrículas/transferências | ❌ | ❌ | Matrículas/transferências são executadas diretamente; sem workflow de aprovação |
| Configuração académica | ✅ | ✅ | Anos, cursos, turmas, disciplinas implementados |
| Desempenho de professores | ❌ | ❌ | Não existe |
| Indicadores financeiros | ✅ Parcial | ✅ | Resumo financeiro e inadimplência existem |
| Autorizar correção de notas | ❌ | ❌ | Não existe fluxo |
| Comunicados oficiais com leitura | ✅ Parcial | ❌ | Mensagens existem, mas sem controlo de entrega/leitura |
| Gestão de permissões | ✅ (módulo auth) | ✅ | Implementado globalmente |

### 4.3 Requisitos — Aluno, Director de Turma e Chefe de Turma

| Requisito | Backend | Frontend | Observação |
|---|---|---|---|
| Aluno consulta dados/horário/notas/faltas/calendário | ✅ | ✅ | Portal do aluno cobre a maioria |
| Aluno acede a materiais de aula | ❌ | ❌ | Não existe |
| Aluno recebe comunicados como lidos | ❌ | ❌ | Não existe leitura/ack |
| Aluno consulta situação de matrícula | ✅ Parcial | ❌ | Falta no portal |
| Aluno faz pedidos (declaração, reclamação) | ❌ | ❌ | Não existe |
| Director de Turma — visualização da turma | ❌ | ❌ | Não existe painel |
| Director de Turma — assiduidade/comportamento/aproveitamento | ❌ | ❌ | Não existe |
| Director de Turma — relatórios e observações pedagógicas | ❌ | ❌ | Não existe |
| Director de Turma — comunicação e casos especiais | ❌ | ❌ | Não existe |
| Chefe de Turma — informações básicas/comunicados | ❌ | ❌ | Não existe |

---

## 5. Sugestão de fases de implementação

### Fase 1 — Portal do Professor (curto prazo, alto impacto)
**Objetivo:** Permitir que professores consultem e lancem dados das suas turmas.

- Criar permissões específicas para professor (`professor`, `professor_lancar_notas`, `professor_frequencia`, etc.).
- Criar API `/api/escolar/professor/*` (ou `/api/portal/professor/*`):
  - `GET /professor/me` — dados do professor, turmas e disciplinas atribuídas.
  - `GET /professor/turmas/{id}/alunos`
  - `GET /professor/horario`
  - `GET/POST /professor/frequencia` (escopo: turmas/disciplinas atribuídas)
  - `GET/POST /professor/notas` (escopo: turmas/disciplinas atribuídas)
  - `GET /professor/alunos/{id}/historico`
- Criar frontend `frontend/src/View/templates/portal_professor/` com:
  - login, dashboard, turmas, alunos, frequência, notas, horário, calendário, comunicados.
- Reutilizar endpoints existentes (`/api/escolar/attendance`, `/api/escolar/grades`) adicionando validação de escopo no backend.

**Já dá para fazer com backend existente:** ✅ sim, com pequenas adaptações de permissão/escopo.

---

### Fase 2 — Director de Turma e Chefe de Turma (curto/médio prazo)
**Objetivo:** Dar visão pedagógica da turma.

- Endpoint `/api/escolar/director-turma/*`:
  - Resumo da turma (alunos, faltas, notas, ocorrências).
  - Alertas de faltas excessivas.
  - Observações pedagógicas (nova entidade).
  - Comunicação com encarregados/professores da turma.
- Endpoint `/api/escolar/chefe-turma/*`:
  - Visualização básica da turma.
  - Partilha de comunicados.
  - Abertura de pedidos/reclamações da turma.
- Frontend: páginas dentro de `/escola/director-turma/*` e `/escola/chefe-turma/*`.

**Já dá para fazer com backend existente:** ⚠️ parcialmente; é necessário novo backend para observações pedagógicas, alertas e pedidos.

---

### Fase 3 — Materiais de aula, planos de aula e conteúdos leccionados (médio prazo)
**Objetivo:** Suportar a prática pedagógica.

- Novas entidades no backend:
  - `lesson_plans` (plano de aula)
  - `lesson_contents` (conteúdo dado)
  - `class_materials` (materiais de aula)
- Endpoints CRUD.
- Frontend no portal do professor e no portal do aluno.

**Já dá para fazer com backend existente:** ❌ requer novo backend.

---

### Fase 4 — Workflows de aprovação e pedidos (médio prazo)
**Objetivo:** Atender Direcção e Secretaria em processos sensíveis.

- Workflow de aprovação de matrículas e transferências.
- Solicitação e aprovação de correção de notas.
- Pedidos do aluno (declaração, reclamação de nota, atualização de dados).
- Controlo de leitura de comunicados.

**Já dá para fazer com backend existente:** ❌ requer novo backend.

---

### Fase 5 — Relatórios avançados e indicadores (médio prazo)
**Objetivo:** Fortalecer a decisão da Direcção.

- Relatórios de desempenho de professores.
- Pautas em PDF/Excel.
- Mapas de frequência.
- Indicadores de aproveitamento por turma/disciplina/professor.
- Alertas automáticos (alunos em risco, inadimplência).

**Já dá para fazer com backend existente:** ⚠️ parcialmente; alguns relatórios podem ser construídos sobre dados existentes, mas alertas e indicadores de professor exigem novo backend.

---

## 6. Conclusão

- **Backend está bastante maduro** para as operações administrativas, financeiras e de portal do aluno/encarregado.
- **Frontend do Painel Escolar cobre** praticamente todas as áreas administrativas existentes.
- **Principais gaps:** portal do professor, director de turma, chefe de turma, planos/conteúdos de aula, materiais de aula, workflows de aprovação, pedidos do aluno e controlo de leitura de comunicados.
- **Recomendação imediata:** iniciar pela **Fase 1 (Portal do Professor)**, pois reutiliza grande parte do backend existente e tem alto impacto pedagógico.
