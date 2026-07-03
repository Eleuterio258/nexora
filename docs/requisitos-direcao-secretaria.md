# Requisitos — Direcção e Secretaria

## Contexto
Perfis administrativos do módulo **Gestão Escolar** do Nexora ERP. A **Direcção** tem funções de controlo, aprovação e decisão estratégica. A **Secretaria** tem funções operacionais de registo, organização e atendimento ao dia-a-dia da escola.

---

## 1. Direcção

### 1.1 Requisitos Funcionais

#### RF-DIR-01 — Acompanhamento geral da escola
- A Direcção deve ter um dashboard executivo com indicadores globais da escola.
- O dashboard deve incluir: total de alunos, professores, turmas, taxas de aprovação/reprovação, inadimplência e ocorrências.

#### RF-DIR-02 — Relatórios diversos
- A Direcção deve aceder a relatórios de alunos, turmas, professores, notas e pagamentos.
- Os relatórios devem permitir filtros por ano lectivo, curso, turma, período e estado.

#### RF-DIR-03 — Aprovação de processos
- A Direcção deve aprovar ou rejeitar matrículas, transferências e outras decisões importantes.
- O sistema deve notificar os interessados (secretaria, encarregados) sobre a decisão.

#### RF-DIR-04 — Configuração académica
- A Direcção deve definir cursos, classes, anos lectivos, períodos de avaliação e regras académicas.
- O sistema deve permitir configurar regras de aprovação, cálculo de médias e propinas.

#### RF-DIR-05 — Acompanhamento de desempenho
- A Direcção deve acompanhar o desempenho dos professores (frequência de lançamentos, cobertura curricular).
- A Direcção deve analisar o aproveitamento dos alunos por turma, disciplina e professor.

#### RF-DIR-06 — Indicadores financeiros
- A Direcção deve consultar indicadores financeiros: propinas pagas, dívidas, receitas e inadimplência.
- O sistema deve apresentar gráficos e comparativos por período.

#### RF-DIR-07 — Autorização de alterações sensíveis
- A Direcção deve autorizar alterações sensíveis, como correcção de notas lançadas por professores.
- O sistema deve manter registo de quem autorizou e quando.

#### RF-DIR-08 — Comunicados oficiais
- A Direcção deve enviar comunicados oficiais para toda a escola, turmas específicas ou segmentos.
- O sistema deve controlar entregas e leituras dos comunicados.

#### RF-DIR-09 — Gestão de permissões
- A Direcção deve gerir permissões e controlar quem pode aceder a cada área do sistema.
- O sistema deve permitir criar perfis e atribuir permissões por módulo.

#### RF-DIR-10 — Suporte à decisão
- A Direcção deve tomar decisões com base em relatórios e indicadores consolidados do sistema.
- O sistema deve alertar sobre situações críticas (alunos em risco, inadimplência elevada, etc.).

---

## 2. Secretaria

### 2.1 Requisitos Funcionais

#### RF-SEC-01 — Cadastro de alunos
- A Secretaria deve cadastrar alunos no sistema com dados pessoais, contactos e documentos.
- O sistema deve validar campos obrigatórios e impedir duplicação por documento de identificação.

#### RF-SEC-02 — Inscrições e matrículas
- A Secretaria deve realizar inscrições e matrículas de novos alunos.
- O sistema deve gerar número de estudante e comprovativo de matrícula.

#### RF-SEC-03 — Actualização de dados
- A Secretaria deve actualizar dados dos alunos, encarregados e responsáveis.
- O sistema deve manter histórico de alterações.

#### RF-SEC-04 — Organização de turmas
- A Secretaria deve organizar alunos por turmas, turnos e anos lectivos.
- O sistema deve permitir mover alunos entre turmas com registo do motivo.

#### RF-SEC-05 — Emissão de documentos
- A Secretaria deve emitir declarações, certificados, boletins e outros documentos escolares.
- Os documentos devem ter número de controle e assinatura digital/quando aplicável.

#### RF-SEC-06 — Registo de pagamentos
- A Secretaria deve registar pagamentos ou confirmar comprovativos, quando permitido.
- O sistema deve gerar recibos e actualizar o estado financeiro do aluno.

#### RF-SEC-07 — Controlo administrativo
- A Secretaria deve controlar processos administrativos dos alunos (matrícula, rematrícula, transferência, desistência).
- O sistema deve apresentar o estado de cada processo.

#### RF-SEC-08 — Transferências, desistências e reingressos
- A Secretaria deve registar transferências, desistências e reingressos de alunos.
- O sistema deve gerar documentos oficiais e actualizar o histórico académico.

#### RF-SEC-09 — Apoio a utilizadores
- A Secretaria deve apoiar alunos, encarregados e professores com questões administrativas no sistema.
- O sistema deve permitir que a Secretaria consulte dados relevantes para resolver pedidos.

#### RF-SEC-10 — Manutenção de dados
- A Secretaria deve manter os dados escolares actualizados no sistema.
- O sistema deve alertar sobre dados incompletos ou pendentes de actualização.

---

## 3. Requisitos Não Funcionais (RNF)

### RNF-01 — Segurança e controlo de acesso
- Autenticação JWT com controlo de escopo (`erp`, `escola`, `ambos`).
- RBAC: permissões diferenciadas para Direcção e Secretaria.
- Auditoria de todas as acções administrativas (quem, quando, o quê).
- Dados sensíveis cifrados em repouso e em trânsito.

### RNF-02 — Usabilidade
- Dashboard direcção com KPIs claros e filtros intuitivos.
- Fluxos de matrícula e emissão de documentos simplificados para a Secretaria.
- Interface responsiva para uso em computadores e tablets.

### RNF-03 — Performance
- Dashboard da Direcção deve carregar em menos de 3 segundos.
- Relatórios consolidados não devem demorar mais de 5 segundos.
- Emissão de documentos deve ser imediata (geração PDF).

### RNF-04 — Disponibilidade
- Alta disponibilidade durante períodos de matrícula e lançamento de notas.
- Backup automático dos dados administrativos e académicos.

### RNF-05 — Compatibilidade
- Funcionamento nos principais browsers (Chrome, Edge, Firefox, Safari).
- Suporte a impressoras para emissão de documentos escolares.

### RNF-06 — Conformidade e privacidade
- Conformidade com LGPD/legislação local de protecção de dados.
- Controlo de quem pode aceder a dados pessoais de alunos e encarregados.
- Documentos emitidos devem respeitar modelos oficiais da escola.

### RNF-07 — Integridade de dados
- Validações que impeçam inconsistências (por exemplo, matrícula duplicada, turma sem ano lectivo).
- Histórico imutável de alterações sensíveis (notas, matrículas, transferências).

### RNF-08 — Manutenibilidade
- Regras de negócio centralizadas no backend (Go) com testes unitários.
- Reutilização de componentes do frontend para formulários, tabelas e relatórios.

---

## 4. Diferenças de permissões

| Área | Direcção | Secretaria |
|---|---|---|
| Configuração académica | Sim (criar/editar) | Não |
| Aprovar matrículas/transferências | Sim | Não |
| Efetuar matrículas/inscrições | Pode supervisionar | Sim (executar) |
| Emitir documentos | Pode autorizar modelos | Sim (emitir) |
| Relatórios financeiros | Sim (indicadores) | Limitado/condicional |
| Registar pagamentos | Não | Sim, se permitido |
| Correcção de notas | Autoriza | Não lança notas |
| Comunicados oficiais | Sim | Pode enviar rotineiros |
| Gestão de permissões | Sim | Não |

---

## 5. Integrações

- **Backend:** `/api/escolar/*`, `/api/faturacao/*`, `/api/auth/*`, `/api/relatorios/*`.
- **Frontend:** `/escola/*` para Gestão Escolar; `/nexora/*` para áreas ERP financeiras quando aplicável.
- **Portal:** direcção e secretaria acedem via painel administrativo; comunicados podem chegar a encarregados via portal.

---

## 6. Critérios de Aceitação

- [ ] Direcção visualiza dashboard executivo com indicadores da escola.
- [ ] Direcção aprova matrículas, transferências e correcções de notas.
- [ ] Direcção configura cursos, classes, anos lectivos e regras académicas.
- [ ] Direcção acede a relatórios financeiros e pedagógicos consolidados.
- [ ] Secretaria cadastra alunos e realiza matrículas/inscrições.
- [ ] Secretaria organiza turmas e actualiza dados de alunos/encarregados.
- [ ] Secretaria emite declarações, certificados e boletins.
- [ ] Secretaria regista transferências, desistências e reingressos.
- [ ] Secretaria regista pagamentos quando autorizada.
- [ ] Sistema audita todas as acções administrativas e aplica RBAC por perfil.
