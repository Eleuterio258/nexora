# Requisitos — Aluno, Director de Turma e Chefe de Turma

## Contexto
Perfis do módulo **Gestão Escolar** do Nexora ERP. Cada perfil tem um nível diferente de acesso e responsabilidade dentro do ecossistema escolar.

- **Aluno:** consulta e acompanhamento da sua vida escolar.
- **Director de Turma:** controlo, orientação e acompanhamento pedagógico da turma.
- **Chefe de Turma:** apoio à comunicação e organização da turma.

---

## 1. Aluno

### 1.1 Requisitos Funcionais

#### RF-ALU-01 — Dados pessoais e académicos
- O aluno deve consultar os seus dados pessoais e académicos no sistema.
- O sistema deve permitir solicitar actualização de dados quando necessário.

#### RF-ALU-02 — Horário das aulas
- O aluno deve visualizar o horário semanal das suas aulas (disciplina, professor, sala, hora).

#### RF-ALU-03 — Notas e pautas
- O aluno deve consultar as notas de testes, trabalhos, exames e avaliações contínuas.
- O sistema deve apresentar médias, estados (aprovado/reprovado) e pautas por período.

#### RF-ALU-04 — Faltas e presenças
- O aluno deve consultar o registo de faltas e presenças por disciplina e período.
- O sistema deve mostrar o total de faltas justificadas e injustificadas.

#### RF-ALU-05 — Calendário escolar
- O aluno deve consultar o calendário escolar com testes, exames, eventos e feriados.

#### RF-ALU-06 — Materiais de aula
- O aluno deve aceder a materiais (documentos, links, tarefas) enviados pelos professores.
- Os materiais devem estar organizados por disciplina e data.

#### RF-ALU-07 — Comunicados da escola
- O aluno deve receber e visualizar comunicados oficiais da escola.
- O sistema deve marcar comunicados como lidos.

#### RF-ALU-08 — Situação de matrícula
- O aluno deve consultar o estado da sua matrícula (activa, suspensa, concluída, etc.).

#### RF-ALU-09 — Propinas e pagamentos
- O aluno deve consultar propinas e pagamentos, apenas se a escola permitir.
- O sistema deve mostrar valores pagos, pendentes e em atraso.

#### RF-ALU-10 — Pedidos simples
- O aluno deve fazer pedidos simples, tais como:
  - Pedido de declaração.
  - Reclamação de nota.
  - Actualização de dados.
- O sistema deve notificar a secretaria ou direcção sobre os pedidos.

---

## 2. Director de Turma

### 2.1 Requisitos Funcionais

#### RF-DT-01 — Visualização dos alunos da turma
- O director de turma deve ver todos os alunos da sua turma.
- A lista deve incluir dados académicos, contactos e estado do aluno.

#### RF-DT-02 — Acompanhamento de assiduidade
- O director de turma deve acompanhar a assiduidade dos alunos (faltas, atrasos, presenças).
- O sistema deve alertar sobre faltas excessivas.

#### RF-DT-03 — Acompanhamento de comportamento
- O director de turma deve consultar ocorrências disciplinares e registar observações de comportamento.

#### RF-DT-04 — Acompanhamento de aproveitamento
- O director de turma deve consultar notas lançadas pelos professores da turma.
- O sistema deve apresentar indicadores de aproveitamento por aluno e disciplina.

#### RF-DT-05 — Relatórios da turma
- O director de turma deve emitir ou acompanhar relatórios da turma (pautas, mapas de frequência, relatório de aproveitamento).

#### RF-DT-06 — Observações pedagógicas
- O director de turma deve registar observações pedagógicas sobre alunos.
- As observações devem ser partilhadas com a direcção e secretaria quando necessário.

#### RF-DT-07 — Comunicação
- O director de turma deve comunicar com alunos, encarregados, professores e direcção.
- O sistema deve permitir envio de mensagens individuais ou em grupo.

#### RF-DT-08 — Casos especiais
- O director de turma deve acompanhar casos de indisciplina, faltas excessivas ou baixo rendimento.
- O sistema deve permitir encaminhar situações para a direcção ou secretaria.

#### RF-DT-09 — Validação de informações
- O director de turma deve validar informações da turma antes de reuniões ou conselhos de notas.
- O sistema deve marcar dados como validados ou pendentes.

#### RF-DT-10 — Organização de reuniões
- O director de turma deve apoiar na organização de reuniões de turma (data, pauta, convocados).

---

## 3. Chefe de Turma

### 3.1 Requisitos Funcionais

#### RF-CT-01 — Informações básicas da turma
- O chefe de turma deve visualizar informações básicas da sua turma (horário, calendário, lista de alunos).

#### RF-CT-02 — Comunicados da turma
- O chefe de turma deve receber comunicados oficiais e partilhá-los com os colegas.
- O sistema deve permitir encaminhar comunicados para o grupo da turma.

#### RF-CT-03 — Comunicação com o director de turma
- O chefe de turma deve informar o director de turma sobre problemas da turma.
- O sistema deve permitir enviar mensagens ou abrir chamados simples.

#### RF-CT-04 — Apoio na confirmação de presenças
- O chefe de turma deve apoiar na confirmação de presenças ou ocorrências, se autorizado.
- O sistema deve registrar quem confirmou e quando.

#### RF-CT-05 — Horário, calendário e actividades
- O chefe de turma deve consultar o horário, calendário escolar e actividades da turma.

#### RF-CT-06 — Pedidos e reclamações da turma
- O chefe de turma deve registar pedidos ou reclamações da turma (por exemplo, material, horário, eventos).
- O sistema deve encaminhar os pedidos ao director de turma ou à direcção.

#### RF-CT-07 — Ligação entre alunos, director de turma e professores
- O chefe de turma deve servir como ponto de ligação, podendo comunicar dúvidas ou avisos entre alunos, director de turma e professores.

---

## 4. Requisitos Não Funcionais (RNF)

### RNF-01 — Segurança e privacidade
- Autenticação JWT com controlo de escopo (`erp`, `escola`, `ambos`).
- Cada perfil vê apenas dados autorizados:
  - Aluno vê apenas os seus dados.
  - Director de Turma vê apenas dados da sua turma.
  - Chefe de Turma vê apenas informações básicas da sua turma.
- Dados pessoais protegidos e não expostos publicamente.

### RNF-02 — Usabilidade
- Interface simples e adaptada a dispositivos móveis para os alunos.
- Dashboard claro para o director de turma com alertas e indicadores.
- Acesso rápido a horários, notas e comunicados.

### RNF-03 — Performance
- Horário e notas devem carregar em menos de 2 segundos.
- Relatórios da turma não devem demorar mais de 5 segundos.

### RNF-04 — Disponibilidade
- Portal do aluno disponível durante o horário lectivo e fora dele.
- Alta disponibilidade durante períodos de exames e lançamento de notas.

### RNF-05 — Compatibilidade
- Funcionamento nos principais browsers (Chrome, Edge, Firefox, Safari) e dispositivos móveis.

### RNF-06 — Notificações
- O sistema deve notificar alunos sobre novas notas, comunicados, faltas e eventos.
- O director de turma deve receber alertas sobre casos especiais da turma.

### RNF-07 — Audit trail
- O sistema deve registar acções sensíveis (reclamações de nota, alteração de dados, confirmações de presença).

### RNF-08 — Manutenibilidade
- Regras de permissão centralizadas no backend (Go) com testes unitários.
- Componentes do frontend reutilizáveis para horários, notas e comunicados.

---

## 5. Matriz de Permissões

| Funcionalidade | Aluno | Director de Turma | Chefe de Turma |
|---|---|---|---|
| Dados pessoais | Próprios | Alunos da turma | Básicos da turma |
| Horário | Próprio | Turma | Turma |
| Notas | Próprias | Turma | Não |
| Faltas | Próprias | Turma | Confirmar se autorizado |
| Calendário | Sim | Sim | Sim |
| Materiais | Sim | Sim | Sim |
| Comunicados | Receber | Enviar/receber | Partilhar |
| Situação de matrícula | Própria | Visualizar | Não |
| Pagamentos | Se permitido | Não | Não |
| Pedidos (declaração, reclamação) | Sim | Encaminhar | Registar da turma |
| Relatórios da turma | Não | Sim | Não |
| Observações pedagógicas | Não | Sim | Não |
| Casos especiais | Não | Sim | Informar |
| Validar informações da turma | Não | Sim | Não |

---

## 6. Integrações

- **Backend:** `/api/portal/aluno/*`, `/api/escolar/alunos`, `/api/escolar/turmas`, `/api/escolar/notas`, `/api/escolar/frequencia`, `/api/escolar/horarios`, `/api/escolar/ocorrencias`, `/api/escolar/comunicacao`, `/api/escolar/atribuicoes`.
- **Frontend:**
  - Aluno: `/portal/aluno/*`
  - Director de Turma: `/escola/director-turma/*` ou dentro de `/escola/turmas`
  - Chefe de Turma: `/escola/chefe-turma/*` ou dentro de `/escola/turmas`

---

## 7. Critérios de Aceitação

- [ ] Aluno consulta dados pessoais, horário, notas, faltas e calendário.
- [ ] Aluno acede a materiais e comunicados.
- [ ] Aluno consulta situação de matrícula e propinas (se permitido).
- [ ] Aluno faz pedidos de declaração, reclamação de nota e actualização de dados.
- [ ] Director de Turma visualiza alunos, assiduidade, comportamento e aproveitamento da turma.
- [ ] Director de Turma consulta notas lançadas pelos professores da turma.
- [ ] Director de Turma emite relatórios e regista observações pedagógicas.
- [ ] Director de Turma comunica com alunos, encarregados, professores e direcção.
- [ ] Director de Turma encaminha casos especiais para direcção/secretaria.
- [ ] Chefe de Turma visualiza informações básicas da turma.
- [ ] Chefe de Turma partilha comunicados e informa o director de turma.
- [ ] Chefe de Turma apoia confirmação de presenças quando autorizado.
- [ ] Cada perfil vê apenas os dados permitidos pelo seu âmbito de acesso.
