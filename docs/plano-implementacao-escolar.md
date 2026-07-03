# Plano de Implementação — Módulo Escolar

## Objectivo
Transformar os requisitos dos perfis **Professor**, **Director de Turma**, **Chefe de Turma**, **Aluno**, **Direcção** e **Secretaria** em funcionalidades entregáveis no Nexora ERP, organizadas por fases de menor risco e maior valor.

---

## Fase 0 — Fundações (preparação)

**Duração estimada:** 1–2 dias  
**Dependências:** Nenhuma

### Tarefas backend
- [ ] Garantir que os cargos `Professor`, `Director de Turma` e `Chefe de Turma` estão criados com permissões correctas (migration `093` já feita).
- [ ] Adicionar validação de escopo nos endpoints existentes (`/api/escolar/grades`, `/attendance`, `/classes`, `/timetables`) para que só permitam aceder a turmas/disciplinas do professor autenticado.
- [ ] Criar helper `GetTeacherAssignments(ctx, teacherID)` que retorna turmas + disciplinas atribuídas no ano lectivo activo.
- [ ] Criar view/endpoint de resumo do professor: `GET /api/escolar/professor/me`.

### Tarefas frontend
- [ ] Criar estrutura de layouts `frontend/src/View/templates/layouts/portal_professor_top.php` e `_bottom.php`.
- [ ] Criar estrutura de páginas `frontend/src/View/templates/portal_professor/`.
- [ ] Adicionar roteamento em `frontend/index.php` para `/portal/professor/*`.

### Critérios de conclusão
- Professor consegue fazer login num portal separado.
- Endpoint `/api/escolar/professor/me` retorna turmas e disciplinas atribuídas.

---

## Fase 1 — Portal do Professor (alto impacto, curto prazo)

**Duração estimada:** 1–2 semanas  
**Dependências:** Fase 0

### Tarefas backend
- [ ] `GET /api/escolar/professor/horario` — horário filtrado pelo professor.
- [ ] `GET /api/escolar/professor/turmas/{id}/alunos` — alunos da turma (limitado às turmas do professor).
- [ ] `GET /api/escolar/professor/turmas/{id}/frequencia` — frequência já registada.
- [ ] `POST /api/escolar/professor/frequencia` — lançar frequência para turma/disciplina atribuída.
- [ ] `GET /api/escolar/professor/turmas/{id}/avaliacoes` — avaliações da turma/disciplina.
- [ ] `POST /api/escolar/professor/notas` — lançar notas para avaliação da turma/disciplina atribuída.
- [ ] `GET /api/escolar/professor/alunos/{id}/historico` — notas, faltas e ocorrências do aluno (turmas do professor).
- [ ] `GET /api/escolar/professor/calendario` — eventos do calendário escolar.
- [ ] `GET /api/escolar/professor/comunicados` — comunicados recebidos/enviados.

### Tarefas frontend
- [ ] `portal_professor/login.php` — login do professor.
- [ ] `portal_professor/dashboard.php` — resumo do professor.
- [ ] `portal_professor/horario.php` — horário semanal.
- [ ] `portal_professor/turmas.php` — lista de turmas.
- [ ] `portal_professor/alunos.php` — alunos por turma.
- [ ] `portal_professor/frequencia.php` — lançamento de presenças/faltas.
- [ ] `portal_professor/notas.php` — lançamento de notas.
- [ ] `portal_professor/avaliacoes.php` — criação/publicação de avaliações.
- [ ] `portal_professor/calendario.php` — calendário escolar.
- [ ] `portal_professor/comunicados.php` — comunicados.

### Critérios de conclusão
- Professor consulta horário, turmas e alunos.
- Professor lança frequência e notas nas disciplinas atribuídas.
- Professor não consegue aceder a turmas/disciplinas de outros professores.

---

## Fase 2 — Director de Turma e Chefe de Turma

**Duração estimada:** 1–2 semanas  
**Dependências:** Fase 1

### Tarefas backend
- [ ] Nova tabela `gestao_escolar.observacoes_pedagogicas` (aluno_id, professor_id, turma_id, tipo, descricao, data, visivel_direcao).
- [ ] `GET /api/escolar/director-turma/resumo` — resumo da turma (alunos, faltas, notas, ocorrências).
- [ ] `GET /api/escolar/director-turma/alertas` — alertas de faltas excessivas, baixo rendimento, indisciplina.
- [ ] `POST /api/escolar/director-turma/observacoes` — registar observação pedagógica.
- [ ] `GET /api/escolar/director-turma/observacoes` — listar observações da turma.
- [ ] `POST /api/escolar/director-turma/mensagens` — enviar mensagem para encarregados/professores da turma.
- [ ] `POST /api/escolar/director-turma/encaminhar` — encaminhar caso para direcção/secretaria.
- [ ] `GET /api/escolar/chefe-turma/turma` — informações básicas da turma.
- [ ] `POST /api/escolar/chefe-turma/pedidos` — registar pedido/reclamação da turma.
- [ ] `POST /api/escolar/chefe-turma/comunicados` — partilhar comunicado com turma.

### Tarefas frontend
- [ ] Criar páginas `frontend/src/View/templates/pages/director_turma_*.php`.
- [ ] Mapear rotas `/escola/director-turma/*`.
- [ ] Dashboard do director de turma.
- [ ] Página de alertas da turma.
- [ ] Página de observações pedagógicas.
- [ ] Página de comunicação da turma.
- [ ] Criar páginas `frontend/src/View/templates/pages/chefe_turma_*.php`.
- [ ] Mapear rotas `/escola/chefe-turma/*`.
- [ ] Dashboard do chefe de turma.
- [ ] Página de pedidos/reclamações da turma.

### Critérios de conclusão
- Director de Turma visualiza resumo e alertas da sua turma.
- Director de Turma regista observações pedagógicas.
- Chefe de Turma partilha comunicados e abre pedidos.

---

## Fase 3 — Materiais, planos e conteúdos de aula

**Duração estimada:** 1–2 semanas  
**Dependências:** Fase 1

### Tarefas backend
- [ ] Nova tabela `gestao_escolar.lesson_plans` (plano de aula).
- [ ] Nova tabela `gestao_escolar.lesson_contents` (conteúdo dado em cada aula).
- [ ] Nova tabela `gestao_escolar.class_materials` (materiais de aula: ficheiros/links).
- [ ] CRUD endpoints para planos, conteúdos e materiais.
- [ ] `GET /api/portal/aluno/materiais` — aluno acede a materiais das suas turmas.
- [ ] `GET /api/escolar/professor/materiais` — professor gere materiais.

### Tarefas frontend
- [ ] Páginas no portal do professor para planos, conteúdos e materiais.
- [ ] Página no portal do aluno para consultar materiais por disciplina.
- [ ] Upload/visualização de ficheiros.

### Critérios de conclusão
- Professor cria planos de aula e regista conteúdos.
- Professor anexa materiais às aulas.
- Aluno consulta materiais no portal.

---

## Fase 4 — Workflows de aprovação e pedidos

**Duração estimada:** 2 semanas  
**Dependências:** Fase 1, Fase 2

### Tarefas backend
- [ ] Nova tabela `gestao_escolar.pedidos` (tipo, solicitante_id, aluno_id, turma_id, estado, motivo, resposta).
- [ ] Tipos de pedido: declaração, reclamação de nota, correção de nota, actualização de dados.
- [ ] Workflow de estados: `pendente` → `em_analise` → `aprovado`/`rejeitado`.
- [ ] `POST /api/escolar/pedidos` — criar pedido.
- [ ] `GET /api/escolar/pedidos` — listar pedidos por perfil (aluno vê os seus; direcção/secretaria vê todos).
- [ ] `POST /api/escolar/pedidos/{id}/decisao` — aprovar/rejeitar com motivo.
- [ ] Workflow de aprovação de matrículas e transferências (estado `pendente` → `aprovada`).
- [ ] Controlo de leitura de comunicados (`comunicado_leituras`).

### Tarefas frontend
- [ ] Página no portal do aluno para criar/listar pedidos.
- [ ] Páginas no painel escolar para secretaria/direcção gerirem pedidos.
- [ ] Página de comunicados com indicador de leitura.

### Critérios de conclusão
- Aluno faz pedidos de declaração/reclamação/correcção.
- Direcção/Secretaria aprovam ou rejeitam pedidos.
- Matrículas e transferências passam por workflow de aprovação.
- Comunicados têm controlo de leitura.

---

## Fase 5 — Relatórios avançados e indicadores

**Duração estimada:** 2 semanas  
**Dependências:** Fase 1, Fase 2, Fase 4

### Tarefas backend
- [ ] Relatório de desempenho de professores (cobertura curricular, lançamentos de notas/frequência).
- [ ] Pautas em PDF/Excel por turma/período.
- [ ] Mapas de frequência por turma/disciplina.
- [ ] Indicadores de aproveitamento por turma/disciplina/professor.
- [ ] Alertas automáticos (alunos em risco, inadimplência elevada, faltas excessivas).
- [ ] Endpoints para exportação de relatórios.

### Tarefas frontend
- [ ] Dashboard da Direcção com indicadores e alertas.
- [ ] Páginas de relatórios no painel escolar.
- [ ] Geração e download de pautas/relatórios.

### Critérios de conclusão
- Direcção consulta indicadores e alertas.
- Sistema gera pautas e relatórios de aproveitamento/frequência.
- Alertas automáticos são enviados/visíveis.

---

## Fase 6 — Portal do Encarregado (complementos)

**Duração estimada:** 3–5 dias  
**Dependências:** Fase 3, Fase 4

### Tarefas backend
- [ ] `GET /api/portal/encarregado/materiais` — materiais dos educandos.
- [ ] `GET /api/portal/encarregado/pedidos` — pedidos feitos pelos educandos.
- [ ] `POST /api/portal/encarregado/pedidos` — encarregado pode criar pedido em nome do educando.
- [ ] Controlo de leitura de comunicados no portal do encarregado.

### Tarefas frontend
- [ ] Actualizar `portal_encarregado/dashboard.php` e páginas relacionadas.
- [ ] Página de materiais no portal do encarregado.
- [ ] Página de pedidos no portal do encarregado.

### Critérios de conclusão
- Encarregado consulta materiais e pedidos dos educandos.

---

## Dependências entre fases

```
Fase 0 ──► Fase 1 ──► Fase 2 ──► Fase 4 ──► Fase 5
              │         │          ▲
              ▼         ▼          │
            Fase 3 ◄───────────────┘
              │
              ▼
            Fase 6
```

---

## Ordem recomendada de entrega

1. **Fase 0** — preparação (1–2 dias)
2. **Fase 1** — Portal do Professor (1–2 semanas)
3. **Fase 2** — Director de Turma e Chefe de Turma (1–2 semanas)
4. **Fase 3** — Materiais, planos e conteúdos (1–2 semanas)
5. **Fase 4** — Workflows de aprovação e pedidos (2 semanas)
6. **Fase 5** — Relatórios e indicadores (2 semanas)
7. **Fase 6** — Complementos no portal do encarregado (3–5 dias)

---

## Notas

- As fases 1 e 2 têm o melhor custo-benefício porque reutilizam grande parte do backend existente.
- As fases 3, 4 e 5 exigem novas entidades e lógica de negócio.
- Cada fase deve ter testes de backend (`*_test.go`) e validação manual no frontend.
- Recomenda-se entregar uma fase de cada vez e recolher feedback antes de avançar.
