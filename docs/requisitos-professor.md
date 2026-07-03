# Requisitos — Funcionalidade do Professor

## Contexto
Módulo de gestão de professores integrado na **Gestão Escolar** do Nexora ERP. O professor é um utilizador com permissões limitadas ao seu trabalho lectivo, devendo aceder apenas aos dados das suas turmas, disciplinas e alunos.

---

## 1. Requisitos Funcionais (RF)

### RF-01 — Consultar turmas, disciplinas e horários
- O professor deve consultar a lista das turmas e disciplinas que lecciona no ano lectivo activo.
- O sistema deve apresentar o horário semanal do professor com turma, disciplina, sala e período.

### RF-02 — Visualizar alunos por turma
- O professor deve ver a lista de alunos de cada turma que lecciona.
- A lista deve incluir dados académicos básicos (nome, número, foto opcional) e estado (activo, transferido, etc.).

### RF-03 — Registar presenças e faltas
- O professor deve registar presenças e faltas por aula e por turma.
- O sistema deve permitir justificar faltas e anexar documentos de comprovação.
- O sistema deve calcular o total de faltas por aluno e por disciplina.

### RF-04 — Lançar notas
- O professor deve lançar notas de testes, trabalhos, exames e avaliações contínuas.
- O sistema deve calcular médias ponderadas e estados (aprovado/reprovado) segundo as regras do ano lectivo.
- O professor só pode lançar notas nas disciplinas e turmas que lhe estão atribuídas.

### RF-05 — Consultar histórico académico dos alunos
- O professor deve consultar o histórico académico dos alunos das suas turmas (notas, frequências, ocorrências, anos lectivos anteriores).

### RF-06 — Planos de aula
- O professor deve criar planos de aula vinculados às disciplinas/turmas.
- Cada plano deve conter: tópicos, objectivos, recursos, data prevista e estado de execução.

### RF-07 — Registar conteúdos leccionados
- O professor deve registar o conteúdo dado em cada aula (tema, observações, progresso no plano).
- O sistema deve associar o registo à turma, disciplina e data.

### RF-08 — Comunicação com alunos e encarregados
- O professor deve enviar comunicados ou mensagens para alunos e/ou encarregados das suas turmas.
- O sistema deve manter histórico de comunicações enviadas.

### RF-09 — Calendário escolar, provas e eventos
- O professor deve consultar o calendário escolar com provas, avaliações e eventos.
- O sistema deve permitir filtrar por turma, disciplina ou tipo de evento.

### RF-10 — Gerar pautas e relatórios
- O professor deve gerar pautas, relatórios de aproveitamento e mapas de frequência.
- O sistema deve permitir exportar em PDF ou Excel.

### RF-11 — Observações pedagógicas
- O professor deve registar observações pedagógicas sobre alunos (desempenho, comportamento, dificuldades).
- As observações devem ser visíveis à direcção e secretaria quando autorizado.

### RF-12 — Solicitar correcção de notas
- O professor deve solicitar correcção de notas lançadas, indicando o motivo.
- A correcção só é aplicada após aprovação da direcção ou secretaria.

### RF-13 — Acompanhamento financeiro (condicional)
- O professor só deve consultar informações de pagamentos ou bloqueios académicos se a escola permitir esse acesso.
- O acesso deve ser configurado por perfil ou permissão específica.

### RF-14 — Portal do professor
- O professor deve aceder ao portal com permissões limitadas ao seu trabalho lectivo.
- O portal deve permitir consultar horários, turmas, alunos, notas, frequências e comunicações.

---

## 2. Restrições de Acesso

- O professor **não** tem acesso total ao sistema.
- O professor vê apenas dados das suas turmas, disciplinas e alunos.
- A direcção e a secretaria mantêm permissões administrativas completas.
- Acções administrativas (matrículas, configurações financeiras, gestão de utilizadores) não estão disponíveis para o professor.

---

## 3. Requisitos Não Funcionais (RNF)

### RNF-01 — Segurança
- Autenticação JWT e controlo de escopo (`erp`, `escola`, `ambos`).
- Auditoria de todas as acções de criação, edição e remoção.
- Senhas armazenadas com hash seguro.
- Dados pessoais protegidos e não expostos publicamente.

### RNF-02 — Usabilidade
- Interface responsiva, adaptada a tablets (uso em sala de aula).
- Design system consistente com o resto do Nexora ERP.
- Lançamento de notas e frequência com poucos cliques.

### RNF-03 — Performance
- Horário e lista de alunos devem carregar em menos de 2 segundos.
- Geração de pautas e relatórios não deve exceder 5 segundos.

### RNF-04 — Disponibilidade
- Alta disponibilidade durante períodos de lançamento de notas e frequência.
- Suporte a picos de utilização no início/fim de períodos de avaliação.

### RNF-05 — Compatibilidade
- Funcionamento nos principais browsers (Chrome, Edge, Firefox, Safari) e dispositivos móveis.

### RNF-06 — Privacidade
- Conformidade com LGPD/legislação local de protecção de dados.
- Dados de alunos e professores visíveis apenas dentro do âmbito de permissões.

### RNF-07 — Escalabilidade
- Regras de cálculo de médias configuráveis por ano lectivo.
- Estrutura que permita adicionar novos tipos de avaliação sem alterações estruturais.

### RNF-08 — Manutenibilidade
- Regras de negócio centralizadas no backend (Go) com testes unitários.
- Reutilização de componentes do frontend (tabelas, formulários, modais).

---

## 4. Integrações

- **Backend:** `/api/escolar/professores`, `/api/escolar/atribuicoes`, `/api/escolar/horarios`, `/api/escolar/alunos`, `/api/escolar/frequencia`, `/api/escolar/notas`, `/api/escolar/avaliacoes`, `/api/escolar/ocorrencias`, `/api/escolar/comunicacao`.
- **Frontend:** `/escola/professores`, `/escola/turmas`, `/escola/horarios`, `/escola/alunos`, `/escola/frequencia`, `/escola/notas`, `/escola/avaliacoes`, `/escola/calendario`, `/escola/comunicacao`.
- **Portal:** `/portal/professor` (futuro).

---

## 5. Critérios de Aceitação

- [ ] Professor consulta apenas as suas turmas, disciplinas e horários.
- [ ] Professor regista presenças/faltas e lança notas nas disciplinas atribuídas.
- [ ] Professor visualiza histórico académico dos alunos das suas turmas.
- [ ] Professor cria planos de aula e regista conteúdos leccionados.
- [ ] Professor envia comunicados para alunos/encarregados das suas turmas.
- [ ] Professor gera pautas, relatórios de aproveitamento e mapas de frequência.
- [ ] Professor não acede a funcionalidades administrativas nem a dados de outras turmas.
- [ ] Acessos financeiros são controlados por configuração da escola.
