# Análise: Assiduidade para Empresas (RH) vs. Escolas — 2026-07-14

## Resumo

Hoje existem **dois sistemas de presença completamente separados** dentro do
mesmo Nexora ERP — não é um módulo único adaptado a dois contextos:

- **RH (empresas)**: assiduidade de funcionários — o próprio funcionário
  "bate o ponto" (app FaceClock / `nexora_assiduidade`).
- **Gestão Escolar**: frequência de alunos — o professor regista quem
  esteve presente na aula.

Os dois nunca se cruzam, excepto num único ponto técnico (o processador de
eventos de hardware biométrico). A lacuna mais relevante é o **professor**:
é uma pessoa que devia aparecer nos dois sistemas (como quem lança a
presença dos alunos, e como funcionário que também bate o seu próprio
ponto), mas hoje só existe no primeiro papel.

Ver também [`nexora_assiduidade_requisitos.md`](nexora_assiduidade_requisitos.md)
(requisitos originais do subsistema de assiduidade, focado exclusivamente em
RH/colaboradores — não cobre o contexto escolar) e
[`analise-modelo-pessoa-multi-tenant.md`](analise-modelo-pessoa-multi-tenant.md)
(modelo de identidade unificada `pessoas.pessoas`, implementado em
2026-07-13, que já liga `auth.users`↔`rh.funcionarios`↔`school_teachers`↔
`school_students` — potencial base para, no futuro, unificar a assiduidade).

---

## 1. Como funciona hoje — Empresa (RH)

Um funcionário normal (ex.: contabilista, técnico) usa a app **FaceClock**
(`nexora_assiduidade`, Android) no telemóvel para bater o ponto:

- Faz login na app (via `POST /api/auth/login`, ou PIN/TOTP).
- Bate o ponto por vários métodos, todos "self-service": QR code, NFC, PIN,
  biometria facial/impressão digital, selfie+GPS, ou registo manual.
- Cada dia gera **uma linha** na tabela `rh.presencas`: entrada, saída,
  horas extra, tipo (`presente`/`atraso`/`falta`/`saida_antecipada`).
- Se esquecer de bater o ponto, pode submeter um pedido de correcção que o
  gestor aprova/rejeita.
- Um gestor pode também registar manualmente a presença de um funcionário
  (`RegistoManualFragment` na app).

Tabela: `rh.presencas` (`backend/migrations/20260629000023_rh_presencas.up.sql`)
```
id, tenant_id, funcionario_id, data, hora_entrada, hora_saida,
horas_extra, observacoes, tipo, created_at
UNIQUE(funcionario_id, data)
```

Este lado está **bem construído e completo**: múltiplos métodos de
identificação, app dedicada, fluxo de correcção/aprovação.

## 2. Como funciona hoje — Escola (alunos)

Aqui o "presente/ausente" não é do professor — é dos **alunos**:

- O professor entra no **portal do professor** (via browser/PWA, não na app
  FaceClock) e, tipicamente no fim da aula, marca cada aluno da turma como
  presente/ausente/justificado/atrasado.
- Endpoint principal: `POST/GET /api/portal/professor/me/presencas`
  (`backend/internal/modules/gestao-escolar/handlers/portal_professor.go:288-386`),
  que valida que a turma pertence às atribuições do professor
  (`school_teacher_assignments`).
- Existe também um caminho administrativo equivalente
  (`POST /api/escolar/attendance` → `LancarFrequencia`,
  `backend/internal/modules/gestao-escolar/handlers/academico.go:109-133`).
- O aluno só consulta e pode justificar uma falta; o encarregado de educação
  só consulta.

Tabela: `gestao_escolar.school_attendance`
(`backend/migrations/20260629000062_gestao_escolar_foundation.up.sql:275-289`)
```
id, tenant_id, class_id, student_id, subject_id (opcional), enrollment_id,
attendance_date, estado ('presente'|'ausente'|'justificado'|'atrasado'),
observacoes, created_by, created_at, updated_at
UNIQUE(tenant_id, class_id, student_id, attendance_date, COALESCE(subject_id,0))
```

Este lado também funciona bem, mas é um **sistema à parte**: outra tabela,
outros ecrãs, outra granularidade (por turma/aula, sem horas de
entrada/saída — só um "estado" categórico por dia/disciplina).

## 3. A lacuna: o professor fica "no meio"

Um professor é uma pessoa com dois papéis em simultâneo:

1. **Como professor** — regista a presença dos alunos (funciona, ponto 2).
2. **Como funcionário da escola** — devia também bater o próprio ponto
   (entrada de manhã, saída à tarde), tal como qualquer outro colaborador.

**O papel 2 não existe na prática.** Já existe, na base de dados, uma
ligação entre "este professor" e "este funcionário do RH"
(`school_teachers.rh_employee_id → rh.funcionarios.id`, geríeel via
`GET/POST /api/escolar/teachers/{id}/rh-link` em
`backend/internal/modules/gestao-escolar/handlers/ligacoes.go:14-66`) — mas
essa ligação **é só um dado passivo**, usado para relatórios e folha de
pagamento. Não activa nenhuma assiduidade automática, não cria nenhum botão
"bater o ponto" para o professor, e a app FaceClock não tem qualquer noção
de professores, alunos, turmas ou escolas (confirmado por grep exaustivo a
todo o código Kotlin: zero ocorrências).

### O backend já foi pensado para isto — mas ficou a meio

Ao investigar, encontrei uma peça de infra-estrutura que já foi construída
com esta ideia em mente, só que nunca foi ligada até ao fim:

- `hardware.device_users.entity_type` (tabela de mapeamento entre um
  terminal biométrico e uma pessoa do ERP) já aceita explicitamente os 3
  valores: `'funcionario'`, `'aluno'`, `'professor'`
  (`backend/migrations/20260710000001_hardware.up.sql:29-30`).
- `hardware.device_events` já tem **duas colunas de destino**:
  `presenca_id` (aponta para `rh.presencas`) e `attendance_id` (aponta para
  `school_attendance`) — preparado desde o desenho da tabela para escrever
  nos dois mundos.
- O processador de eventos
  (`backend/internal/modules/hardware/service/processor.go:105-143`) já
  sabe: quando o evento é de tipo `funcionario` **ou `professor`**, escreve
  em `rh.presencas` usando `entity_id` como `rh.funcionarios.id`; quando é
  `aluno`, escreve em `school_attendance` resolvendo a turma pela matrícula
  activa.

O que falta para isto funcionar de ponta a ponta:

1. **Validação do `entity_id`** — `CriarDeviceUser`
   (`backend/internal/modules/hardware/handlers/devices.go:313-352`) aceita
   qualquer `entity_id` sem confirmar que existe na tabela certa
   (`rh.funcionarios` para professor/funcionário, `school_students` para
   aluno).
2. **Automação da ligação** — nada cria automaticamente um
   `hardware.device_users` para um professor a partir do
   `rh_employee_id` já registado; teria de ser feito manualmente pelo
   admin, dispositivo a dispositivo.
3. **Endpoints equivalentes para aluno/professor** — o grupo de rotas que a
   app FaceClock consome (`/api/hardware/assiduidade/*` — listar
   funcionários, geofence, QR, NFC) só existe para `funcionario`
   (`router.go:2477-2489`). Não há `/api/hardware/assiduidade/alunos` nem
   equivalente; o caminho `aluno`/`professor` só é alcançável pelos
   endpoints genéricos de terminal (Hikvision/ZKTeco/webhook), não pelo
   fluxo self-service usado pela app.
4. **A app em si** — mesmo resolvendo 1-3, a app `nexora_assiduidade` teria
   de ganhar noção de "sou professor" para, por exemplo, mostrar as duas
   acções (bater o meu ponto + lançar presença da turma) no mesmo sítio.

## 4. Rotas — confirmação de que são mundos separados

**RH** (`backend/internal/router/router.go`):
- `GET/POST /api/rh/{id}/presencas` (linhas 1770, 1775)
- `GET /api/rh/presencas` (linha 1677)
- `POST/PUT/DELETE /api/rh/correcoes-ponto/*` (linha 1837)
- `GET/POST /api/self-service/assiduidade/*` (linhas 2282-2299)
- `POST /api/hardware/*` — eventos, dispositivos, `device_users`, e o bloco
  `/assiduidade/*` específico de RH (linhas 2466-2519)

**Escola**:
- `GET /api/escolar/attendance[/{id}]` (linhas 804-805)
- `POST /api/escolar/attendance`, `PUT /api/escolar/attendance/{id}`
  (linhas 918-920)
- `GET/POST /api/portal/professor/me/presencas` (linhas 1097-1098)
- `GET /api/portal/aluno/me/presencas[/{id}/justificar]` (linhas 1071, 1081)
- `GET /api/portal/encarregado/me/educandos/{id}/presencas` (linha 1116)

**Único ponto de convergência técnica hoje**: o `hardware/service/processor.go`
— é o único código que escreve tanto em `rh.presencas` como em
`school_attendance`, a partir do mesmo pipeline de eventos biométricos.

## 5. Oportunidade futura

A migration `pessoas_fase1` (`backend/migrations/20260713000001_pessoas_fase1.up.sql`,
2026-07-13) introduziu `pessoas.pessoas` como identidade central, já
ligando `auth.users`, `rh.funcionarios`, `school_teachers` e
`school_students` à mesma pessoa quando aplicável. Isto é uma base já
pronta para, no futuro, tratar um professor como **uma pessoa só** com
presença própria (RH) e presença que lança dos alunos (escola) — mas essa
ligação ainda não chega a `rh.presencas`/`school_attendance`; hoje o
`pessoa_id` só resolve identidade, não assiduidade.

## 6. Próximos passos possíveis (não implementados)

Por ordem de esforço crescente:

1. **Validar `entity_id` em `CriarDeviceUser`** — pequeno, evita
   configurações inválidas silenciosas.
2. **Botão "bater o ponto" no portal do professor**, que escreve
   directamente em `rh.presencas` via `rh_employee_id` — não depende de
   hardware nem da app, resolve a lacuna mais visível com menos esforço.
3. **Automatizar a criação de `device_users` para professores** a partir da
   ligação `rh_employee_id` já existente, quando o admin associa um
   dispositivo à escola.
4. **Dar à app `nexora_assiduidade` noção de "professor"** — maior esforço,
   exige a app saber distinguir os dois papéis e, possivelmente, também
   ecrãs de lançamento de presença de turma (hoje só no portal web).
