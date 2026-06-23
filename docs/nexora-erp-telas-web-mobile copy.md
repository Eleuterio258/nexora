# Nexora ERP — Telas Web e Mobile

## 1. Visão Geral dos Módulos

### Módulos Concluídos (23 módulos úteis)

| # | Módulo | Status |
|---|--------|--------|
| 1 | autenticacao | Concluído |
| 2 | autorizacao | Concluído |
| 3 | utilizadores | Concluído |
| 4 | empresas | Concluído |
| 5 | auditoria | Concluído |
| 6 | sistema-configuracao | Concluído |
| 7 | gestao-clientes | Concluído |
| 8 | gestao-produtos | Concluído |
| 9 | gestao-stock | Concluído |
| 10 | modulo-faturacao | Concluído |
| 11 | tesouraria | Concluído |
| 12 | financeiro | Concluído |
| 13 | contabilidade | Concluído |
| 14 | impostos | Concluído |
| 15 | multi-moeda | Concluído |
| 16 | compras | Concluído |
| 17 | pos | Concluído |
| 18 | logistica | Concluído |
| 19 | crm | Concluído |
| 20 | recursos-humanos | Concluído |
| 21 | assinaturas | Concluído |
| 22 | gestao-escolar | Concluído |
| 23 | centros-custo | Concluído |

### Módulo Descontinuado

| Módulo | Motivo |
|--------|--------|
| seguranca | Substituído pelos módulos: **autenticacao**, **autorizacao**, **auditoria** |

---

## 2. Módulo: Gestão Escolar

> **Objetivo:** gerir administração escolar, alunos, encarregados, professores, turmas, disciplinas, matrículas, avaliações, frequência, propinas, biblioteca, comunicação, relatórios e portais.

---

### 2.1. Tela de Dashboard Escolar

**Objetivo:** apresentar visão geral da escola.

#### Web
- **Cards:**
  - Alunos ativos
  - Professores ativos
  - Turmas abertas
  - Matrículas pendentes
  - Propinas em atraso
  - Frequência média
- **Gráficos:**
  - Alunos por turma
  - Pagamentos por mês
  - Desempenho académico
- **Lista de alertas:**
  - Propinas vencidas
  - Faltas elevadas
  - Notas pendentes
  - Comunicados recentes

#### Mobile
- Cards empilhados
- Alertas em lista
- Ações rápidas

#### Campos / Filtros
- Ano letivo
- Período
- Turma
- Ciclo
- Estado

#### Ações
- Nova matrícula
- Novo aluno
- Nova turma
- Lançar notas
- Registar pagamento
- Enviar comunicado

#### Estados
- Sem dados escolares
- Carregando
- Ano letivo não configurado
- Sem permissão

#### Permissões
- `school.dashboard.view`

#### Regras
- Dados devem ser filtrados por ano letivo ativo.
- Perfis diferentes veem dashboards diferentes: direção, secretaria, professor, financeiro.

---

### 2.2. Tela de Anos Letivos

**Objetivo:** gerir anos letivos da escola.

#### Web
- Tabela com: ano, data início, data fim, estado e períodos
- Botão "Novo ano letivo"

#### Mobile
- Cards por ano letivo

#### Campos
- Nome do ano letivo
- Data inicial
- Data final
- Estado: planeado, ativo, encerrado
- Observação

#### Ações
- Criar ano letivo
- Ativar
- Encerrar
- Gerar períodos
- Reabrir, se permitido

#### Estados
- Planeado
- Ativo
- Encerrado

#### Permissões
- `school_years.view`
- `school_years.manage`

#### Regras
- Apenas um ano letivo ativo por escola.
- Ano encerrado bloqueia alterações académicas críticas.
- Datas não devem sobrepor outro ano ativo.

---

### 2.3. Tela de Períodos Letivos

**Objetivo:** gerir trimestres, semestres ou períodos escolares.

#### Web
- Tabela com: período, ano letivo, datas, estado e ordem
- Botão "Novo período"

#### Mobile
- Lista por ano letivo

#### Campos
- Ano letivo
- Nome do período
- Data inicial
- Data final
- Ordem
- Estado

#### Ações
- Criar período
- Editar
- Ativar
- Encerrar

#### Estados
- Planeado
- Ativo
- Encerrado

#### Permissões
- `school_terms.view`
- `school_terms.manage`

#### Regras
- Períodos devem estar dentro do ano letivo.
- Apenas um período ativo por ano, conforme política.
- Encerrado bloqueia lançamento normal de notas/frequência.

---

### 2.4. Tela de Turmas

**Objetivo:** gerir turmas, salas, turnos e professor diretor.

#### Web
- Tabela com: turma, classe/série, turno, sala, diretor de turma, número de alunos e estado
- Filtros por: ano, ciclo, turno e estado
- Botão "Nova turma"

#### Mobile
- Cards por turma
- Ações rápidas

#### Campos
- Ano letivo
- Nome da turma
- Classe/série
- Ciclo
- Turno
- Sala
- Capacidade
- Professor diretor
- Estado

#### Ações
- Criar turma
- Editar
- Ver alunos
- Ver horário
- Encerrar turma

#### Estados
- Aberta
- Lotada
- Encerrada
- Inativa

#### Permissões
- `classes.view`
- `classes.create`
- `classes.update`

#### Regras
- Turma não deve ultrapassar capacidade sem permissão.
- Turma pertence a um ano letivo.
- Professor diretor deve existir no cadastro de professores.

---

### 2.5. Tela de Alunos

**Objetivo:** gerir cadastro de alunos.

#### Web
- Tabela com: nome, código, turma, encarregado, contacto, estado e ano letivo
- Pesquisa por nome/código
- Filtros por: turma, estado, ano e ciclo
- Botão "Novo aluno"

#### Mobile
- Cards por aluno
- Pesquisa no topo

#### Campos Visíveis
- Nome
- Código
- Turma
- Encarregado
- Estado
- Contacto

#### Ações
- Criar aluno
- Ver detalhe
- Editar
- Matricular
- Transferir
- Ver notas
- Ver pagamentos

#### Estados
- Ativo
- Transferido
- Inativo
- Graduado
- Sem matrícula

#### Permissões
- `students.view`
- `students.create`
- `students.update`

#### Regras
- Código do aluno deve ser único por tenant.
- Aluno pode ter histórico de matrículas por ano.
- Dados pessoais são sensíveis.

---

### 2.6. Tela de Criar / Editar Aluno

**Objetivo:** cadastrar ou atualizar dados do aluno.

#### Web
- Formulário com tabs:
  - Dados pessoais
  - Encarregados
  - Morada
  - Documentos
  - Saúde/observações
  - Matrícula
- Botões "Guardar" e "Guardar e matricular"

#### Mobile
- Wizard:
  1. Dados do aluno
  2. Encarregado
  3. Escola/matrícula
  4. Revisão

#### Campos
- Nome completo
- Data de nascimento
- Sexo
- Documento/NUIT, se aplicável
- Nacionalidade
- Morada
- Contacto
- Foto
- Observações médicas
- Estado

#### Ações
- Guardar
- Adicionar encarregado
- Matricular
- Cancelar

#### Estados
- Dados inválidos
- Aluno criado
- Documento duplicado
- Sem permissão

#### Permissões
- `students.create`
- `students.update`

#### Regras
- Menor de idade deve ter encarregado obrigatório.
- Dados médicos exigem permissão especial.
- Alterações críticas devem ser auditadas.

---

### 2.7. Tela de Encarregados

**Objetivo:** gerir responsáveis financeiros e académicos do aluno.

#### Web
- Lista/tabela com: nome, relação, telefone, email, responsável financeiro e estado
- Botão "Novo encarregado"

#### Mobile
- Cards com ações rápidas

#### Campos
- Nome
- Relação com aluno
- Telefone
- Email
- Documento
- Responsável financeiro: sim/não
- Contacto principal: sim/não

#### Ações
- Criar encarregado
- Editar
- Associar aluno
- Definir responsável financeiro
- Enviar acesso ao portal

#### Estados
- Ativo
- Inativo
- Convite pendente

#### Permissões
- `student_guardians.view`
- `student_guardians.manage`

#### Regras
- Um aluno deve ter pelo menos um contacto principal.
- Pode haver mais de um encarregado.
- Responsável financeiro recebe cobranças/recibos.

---

### 2.8. Tela de Matrículas e Rematrículas

**Objetivo:** gerir matrícula anual dos alunos.

#### Web
- Tabela com: aluno, ano letivo, turma, estado, data e responsável
- Botão "Nova matrícula"
- Filtros por: ano, turma e estado

#### Mobile
- Cards por matrícula

#### Campos
- Aluno
- Ano letivo
- Turma
- Data da matrícula
- Tipo: matrícula / rematrícula / transferência
- Estado
- Taxa de matrícula
- Observação

#### Ações
- Criar matrícula
- Confirmar
- Cancelar
- Transferir turma
- Gerar cobrança

#### Estados
- Pendente
- Confirmada
- Cancelada
- Transferida

#### Permissões
- `enrollments.view`
- `enrollments.create`
- `enrollments.confirm`
- `enrollments.cancel`

#### Regras
- Aluno não deve ter duas matrículas ativas no mesmo ano letivo.
- Matrícula confirmada pode gerar cobrança.
- Transferência deve manter histórico.

---

### 2.9. Tela de Professores

**Objetivo:** gerir cadastro de professores.

#### Web
- Tabela com: nome, contacto, disciplinas, turmas atribuídas e estado
- Botão "Novo professor"

#### Mobile
- Cards por professor

#### Campos
- Nome
- Telefone
- Email
- Documento
- Especialidade
- Estado
- Utilizador associado

#### Ações
- Criar professor
- Editar
- Atribuir disciplina/turma
- Enviar acesso ao portal
- Ver horário

#### Estados
- Ativo
- Inativo
- Sem utilizador associado

#### Permissões
- `teachers.view`
- `teachers.create`
- `teachers.update`

#### Regras
- Professor pode estar ligado a utilizadores.
- Professor inativo não deve receber novas atribuições.
- Dados podem integrar RH no futuro.

---

### 2.10. Tela de Disciplinas

**Objetivo:** gerir disciplinas e carga horária.

#### Web
- Tabela com: disciplina, código, classe/ciclo, carga horária e estado
- Botão "Nova disciplina"

#### Mobile
- Lista simples

#### Campos
- Nome da disciplina
- Código
- Ciclo/classe
- Carga horária
- Área académica
- Estado

#### Ações
- Criar disciplina
- Editar
- Desativar
- Ver turmas/professores

#### Estados
- Ativa
- Inativa

#### Permissões
- `subjects.view`
- `subjects.manage`

#### Regras
- Disciplina em uso não deve ser apagada.
- Código deve ser único por tenant/ano, conforme regra.

---

### 2.11. Tela de Atribuição Professor-Turma-Disciplina

**Objetivo:** ligar professores às turmas e disciplinas.

#### Web
- Matriz por turma/disciplina/professor
- Filtros por: ano letivo, turma e professor
- Botão "Nova atribuição"

#### Mobile
- Lista de atribuições

#### Campos
- Ano letivo
- Professor
- Turma
- Disciplina
- Carga horária
- Estado

#### Ações
- Criar atribuição
- Editar
- Remover
- Ver horário

#### Estados
- Atribuição ativa
- Conflito de horário
- Professor indisponível

#### Permissões
- `teacher_assignments.view`
- `teacher_assignments.manage`

#### Regras
- Professor só lança notas/frequência nas turmas atribuídas.
- Evitar duplicidade da mesma disciplina/turma.
- Conflitos de horário devem gerar alerta.

---

### 2.12. Tela de Frequência Escolar

**Objetivo:** registar presenças e faltas dos alunos.

#### Web
- Seleção de turma, disciplina, data e aula
- Lista de alunos com estado: presente, falta, atraso, justificado
- Botão "Guardar frequência"

#### Mobile
- Interface rápida para professor
- Checkboxes/toggles por aluno

#### Campos
- Turma
- Disciplina
- Data
- Aula
- Aluno
- Estado
- Observação

#### Ações
- Marcar todos presentes
- Registar faltas
- Justificar falta
- Guardar

#### Estados
- Frequência pendente
- Frequência guardada
- Aula sem alunos
- Período encerrado

#### Permissões
- `attendance_records.view`
- `attendance_records.create`
- `attendance_records.update`

#### Regras
- Professor só marca frequência de turmas atribuídas.
- Período encerrado bloqueia edição normal.
- Faltas podem gerar alerta ao encarregado.

---

### 2.13. Tela de Avaliações e Notas

**Objetivo:** gerir avaliações, notas, médias e boletins.

#### Web
- Seleção de turma, disciplina e período
- Lista de avaliações
- Grelha de lançamento de notas por aluno
- Cálculo automático de média
- Botão "Publicar notas"

#### Mobile
- Lançamento por avaliação ou por aluno
- Lista simplificada

#### Campos
- Turma
- Disciplina
- Período
- Avaliação
- Peso
- Nota
- Média
- Observação

#### Ações
- Criar avaliação
- Lançar notas
- Calcular médias
- Publicar
- Reabrir lançamento, se permitido

#### Estados
- Rascunho
- Lançada
- Publicada
- Período encerrado

#### Permissões
- `grades.view`
- `grades.create`
- `grades.publish`

#### Regras
- Nota deve respeitar escala configurada.
- Média deve considerar pesos.
- Publicação libera consulta em portais.
- Alterações após publicação devem ser auditadas.

---

### 2.14. Tela de Propinas e Cobranças Escolares

**Objetivo:** gerir planos de cobrança, propinas, matrículas, taxas, descontos e bolsas.

#### Web
- Tabela com: aluno, cobrança, vencimento, valor, pago, saldo e estado
- Filtros por: turma, período, vencidas e estado
- Botão "Nova cobrança"

#### Mobile
- Cards por cobrança
- Ação rápida para pagamento

#### Campos
- Aluno
- Tipo: propina, matrícula, exame, transporte, outro
- Período
- Valor
- Desconto/bolsa
- Vencimento
- Estado

#### Ações
- Gerar cobranças em lote
- Registar pagamento
- Aplicar desconto
- Emitir recibo
- Enviar lembrete

#### Estados
- Em aberto
- Parcialmente paga
- Paga
- Vencida
- Cancelada

#### Permissões
- `school_fees.view`
- `school_fees.create`
- `school_fees.update`
- `school_payments.create`

#### Regras
- Cobranças podem gerar contas a receber no financeiro.
- Pagamento movimenta tesouraria.
- Responsável financeiro recebe notificações.

---

### 2.15. Tela de Pagamento Escolar

**Objetivo:** registar pagamento de propina ou taxa.

#### Web
- Seleção de aluno/responsável
- Lista de cobranças em aberto
- Meio de pagamento e destino
- Botão "Confirmar pagamento"

#### Mobile
- Fluxo:
  1. Aluno
  2. Cobranças
  3. Pagamento
  4. Recibo

#### Campos
- Aluno
- Cobrança
- Valor pago
- Meio de pagamento
- Caixa/conta bancária
- Referência
- Data

#### Ações
- Selecionar cobrança
- Confirmar pagamento
- Emitir recibo
- Enviar recibo

#### Estados
- Sem cobranças
- Valor inválido
- Pagamento confirmado
- Erro de tesouraria

#### Permissões
- `school_payments.create`

#### Regras
- Valor pago reduz saldo da cobrança.
- Pode integrar com financeiro e tesouraria.
- Recibo deve ser emitido.

---

### 2.16. Tela de Biblioteca

**Objetivo:** gerir catálogo de livros, empréstimos e devoluções.

#### Web
- Tabs:
  - Livros
  - Empréstimos
  - Devoluções
  - Atrasos
- Tabela de livros com: título, autor, código, quantidade e estado

#### Mobile
- Lista de livros
- Leitura por código, se aplicável

#### Campos
- Livro
- Código
- Autor
- Categoria
- Quantidade
- Aluno/professor
- Data empréstimo
- Data prevista devolução

#### Ações
- Cadastrar livro
- Emprestar
- Devolver
- Renovar
- Marcar atraso/perda

#### Estados
- Disponível
- Emprestado
- Atrasado
- Perdido

#### Permissões
- `library_books.view`
- `library_books.manage`
- `library_loans.manage`

#### Regras
- Empréstimo reduz disponibilidade.
- Atraso pode gerar alerta.
- Perda pode gerar cobrança.

---

### 2.17. Tela de Comunicação Escolar

**Objetivo:** enviar comunicados para alunos, encarregados, professores e turmas.

#### Web
- Lista de mensagens/circulares
- Botão "Novo comunicado"
- Seleção de destinatários por turma, perfil ou aluno

#### Mobile
- Lista de comunicados
- Criação simples para perfis autorizados

#### Campos
- Título
- Mensagem
- Destinatários
- Canal: app, email, SMS
- Anexo
- Data de envio
- Estado

#### Ações
- Criar comunicado
- Enviar
- Agendar
- Ver leituras
- Cancelar

#### Estados
- Rascunho
- Enviado
- Agendado
- Cancelado

#### Permissões
- `school_messages.view`
- `school_messages.create`
- `school_messages.send`

#### Regras
- Envio para encarregados deve respeitar associação do aluno.
- Mensagens críticas podem exigir confirmação de leitura.
- Envio deve usar templates/notificações.

---

### 2.18. Portal do Aluno

**Objetivo:** permitir ao aluno consultar dados próprios.

#### Mobile / Web
- Dashboard com:
  - Horário
  - Notas
  - Frequência
  - Pagamentos
  - Comunicados
  - Biblioteca
- Navegação simples

#### Ações
- Ver notas
- Ver frequência
- Ver cobranças
- Baixar recibos
- Ver comunicados

#### Permissões
- `student_portal.view`

#### Regras
- Aluno vê apenas seus dados.
- Notas só aparecem após publicação.
- Pagamentos podem ser apenas consulta.

---

### 2.19. Portal do Professor

**Objetivo:** permitir ao professor gerir atividades académicas.

#### Mobile / Web
- Lista de turmas atribuídas
- Ações:
  - Lançar frequência
  - Lançar notas
  - Ver alunos
  - Enviar comunicado
  - Ver horário

#### Permissões
- `teacher_portal.view`

#### Regras
- Professor só acessa turmas/disciplinas atribuídas.
- Lançamentos após período encerrado exigem permissão.

---

### 2.20. Portal do Encarregado

**Objetivo:** permitir ao encarregado acompanhar educandos.

#### Mobile / Web
- Lista de educandos
- Para cada aluno:
  - Notas
  - Frequência
  - Cobranças
  - Pagamentos
  - Comunicados
  - Biblioteca

#### Ações
- Ver boletim
- Ver pagamentos
- Baixar recibo
- Receber comunicados

#### Permissões
- `guardian_portal.view`

#### Regras
- Encarregado vê apenas alunos associados.
- Responsável financeiro pode ver cobranças e recibos.

---

### 2.21. Relatórios Escolares

**Objetivo:** gerar relatórios académicos, financeiros e administrativos.

#### Web
- Lista:
  - Alunos por turma
  - Matrículas por ano
  - Frequência
  - Boletins
  - Notas por turma/disciplina
  - Propinas em atraso
  - Pagamentos
  - Biblioteca
  - Professores e atribuições
- Filtros e exportação

#### Mobile
- Seleção de relatório
- Resumo e exportação

#### Permissões
- `school_reports.view`
- `school_reports.export`

#### Regras
- Relatórios respeitam ano letivo e permissões.
- Exportações devem ser auditadas.

---

## 3. Módulo: Centros de Custo

> **Objetivo:** gerir centros de custo, rateios, alocação de despesas/receitas, orçamentos por centro, análise de rentabilidade e integração com contabilidade, financeiro, compras, RH e faturação.

---

### 3.1. Tela de Dashboard de Centros de Custo

**Objetivo:** apresentar visão geral de custos, receitas e rentabilidade por centro.

#### Web
- **Cards:**
  - Total de custos do período
  - Total de receitas alocadas
  - Resultado por centro
  - Centros acima do orçamento
  - Despesas sem centro de custo
  - Lançamentos pendentes de alocação
- **Gráficos:**
  - Custos por centro
  - Orçado vs realizado
  - Receita vs custo
- Lista de alertas

#### Mobile
- Cards empilhados
- Gráficos resumidos
- Lista de centros com maior desvio

#### Campos / Filtros
- Período
- Centro de custo
- Departamento
- Projeto
- Filial

#### Ações
- Novo centro de custo
- Nova regra de rateio
- Ver despesas sem alocação
- Gerar relatório

#### Estados
- Sem centros cadastrados
- Carregando
- Desvio acima do orçamento
- Sem permissão

#### Permissões
- `cost_centers.dashboard.view`

#### Regras
- Dados vêm da contabilidade e financeiro.
- Centros de custo pertencem ao tenant.
- Valores devem respeitar período fiscal.

---

### 3.2. Tela de Lista de Centros de Custo

**Objetivo:** consultar e gerir centros de custo.

#### Web
- Tabela com: código, nome, tipo, responsável, centro pai, orçamento, realizado e estado
- Visualização alternativa em árvore
- Filtros por: tipo, responsável e estado
- Botão "Novo centro"

#### Mobile
- Lista hierárquica em cards
- Pesquisa por código/nome

#### Campos Visíveis
- Código
- Nome
- Tipo
- Responsável
- Orçamento
- Realizado
- Estado

#### Ações
- Criar centro
- Editar
- Desativar
- Ver detalhes
- Ver lançamentos
- Ver relatório

#### Estados
- Nenhum centro
- Ativo
- Inativo
- Acima do orçamento

#### Permissões
- `cost_centers.view`
- `cost_centers.create`
- `cost_centers.update`
- `cost_centers.deactivate`

#### Regras
- Código deve ser único por tenant.
- Centro com movimentos não deve ser apagado.
- Pode existir hierarquia de centros.

---

### 3.3. Tela de Criar / Editar Centro de Custo

**Objetivo:** cadastrar ou atualizar centro de custo.

#### Web
- Formulário com: dados gerais, responsável, hierarquia e orçamento inicial
- Botões "Guardar" e "Cancelar"

#### Mobile
- Formulário em etapas:
  1. Dados gerais
  2. Responsável
  3. Orçamento
  4. Revisão

#### Campos
- Código
- Nome
- Descrição
- Tipo: departamento, projeto, filial, produto, serviço, campanha, outro
- Centro pai
- Responsável
- Data inicial
- Data final
- Orçamento inicial
- Estado

#### Ações
- Guardar
- Cancelar
- Validar código

#### Estados
- Código duplicado
- Data inválida
- Centro criado
- Centro atualizado

#### Permissões
- `cost_centers.create`
- `cost_centers.update`

#### Regras
- Data final não pode ser anterior à inicial.
- Centro pai não pode ser ele próprio.
- Alterações devem ser auditadas.

---

### 3.4. Tela de Detalhe do Centro de Custo

**Objetivo:** visualizar desempenho e movimentos do centro.

#### Web
- Cabeçalho com: código, nome, responsável e estado
- **Cards:**
  - Orçamento
  - Realizado
  - Disponível
  - Receita
  - Custo
  - Resultado
- **Tabs:**
  - Resumo
  - Lançamentos
  - Orçamento
  - Rateios
  - Documentos
  - Histórico

#### Mobile
- Cabeçalho compacto
- Cards empilhados
- Tabs horizontais

#### Ações
- Editar
- Ver lançamentos
- Criar orçamento
- Criar regra de rateio
- Exportar relatório

#### Estados
- Centro ativo
- Centro inativo
- Acima do orçamento
- Sem movimentos

#### Permissões
- `cost_centers.view_detail`
- `cost_center_movements.view`

#### Regras
- Valores realizados vêm de lançamentos contabilísticos.
- Disponível = orçamento - realizado.
- Centro inativo não deve receber novos lançamentos.

---

### 3.5. Tela de Hierarquia de Centros de Custo

**Objetivo:** organizar centros em níveis.

#### Web
- Árvore com drag-and-drop
- Painel lateral com detalhes do centro selecionado
- Botão "Mover centro"

#### Mobile
- Lista expansível
- Ação "Mover para"

#### Campos
- Centro
- Centro pai
- Nível
- Caminho hierárquico

#### Ações
- Mover centro
- Expandir/recolher
- Ver subcentros
- Exportar estrutura

#### Estados
- Estrutura carregada
- Movimento inválido
- Sem permissão

#### Permissões
- `cost_center_hierarchy.view`
- `cost_center_hierarchy.update`

#### Regras
- Não permitir ciclos na hierarquia.
- Movimentos devem manter histórico.
- Subcentros podem consolidar valores no centro pai.

---

### 3.6. Tela de Lançamentos por Centro de Custo

**Objetivo:** consultar lançamentos contabilísticos associados aos centros.

#### Web
- Tabela com: data, conta, documento, descrição, débito, crédito, centro de custo e origem
- Filtros por: período, conta, origem e centro
- Exportação

#### Mobile
- Lista cronológica
- Filtros compactos

#### Campos
- Data
- Conta contabilística
- Documento
- Centro de custo
- Débito
- Crédito
- Origem
- Descrição

#### Ações
- Filtrar
- Ver lançamento
- Ver documento origem
- Exportar

#### Estados
- Sem lançamentos
- Carregando
- Sem permissão

#### Permissões
- `cost_center_entries.view`
- `cost_center_entries.export`

#### Regras
- Lançamentos vêm de `journal_entry_lines`.
- Um lançamento pode ter centro direto ou rateio.
- Períodos encerrados são apenas consulta.

---

### 3.7. Tela de Alocação Manual

**Objetivo:** atribuir centro de custo a lançamentos ou despesas sem alocação.

#### Web
- Lista de lançamentos sem centro
- Seleção de centro de custo
- Aplicação individual ou em lote
- Justificativa obrigatória

#### Mobile
- Lista de pendências
- Alocação por item

#### Campos
- Lançamento
- Documento origem
- Valor
- Centro de custo
- Justificativa

#### Ações
- Alocar centro
- Alocar em lote
- Ignorar pendência
- Ver origem

#### Estados
- Pendente de alocação
- Alocado
- Justificativa obrigatória
- Período encerrado

#### Permissões
- `cost_center_allocations.view`
- `cost_center_allocations.create`

#### Regras
- Não alterar lançamentos em período encerrado sem reabertura/permissão.
- Alocação deve ser auditada.
- Valor total alocado deve bater com o valor do lançamento.

---

### 3.8. Tela de Regras de Rateio

**Objetivo:** configurar distribuição automática de valores entre centros.

#### Web
- Tabela com: nome da regra, base de rateio, centros envolvidos, percentuais e estado
- Botão "Nova regra"

#### Mobile
- Cards por regra
- Detalhe com percentuais

#### Campos
- Nome da regra
- Tipo: percentual, valor fixo, quantidade, headcount, receita
- Centros de custo
- Percentual/valor por centro
- Conta/categoria aplicável
- Estado

#### Ações
- Criar regra
- Editar
- Simular rateio
- Ativar/desativar

#### Estados
- Regra ativa
- Percentual inválido
- Soma diferente de 100%
- Regra em uso

#### Permissões
- `cost_allocation_rules.view`
- `cost_allocation_rules.manage`

#### Regras
- Rateio percentual deve somar 100%.
- Regras em uso devem preservar histórico.
- Aplicação automática deve registrar origem.

---

### 3.9. Tela de Simulação de Rateio

**Objetivo:** simular distribuição antes de aplicar.

#### Web
- Seleção de valor/documento/regra
- Resultado por centro
- Diferença de arredondamento
- Botão "Aplicar rateio"

#### Mobile
- Resumo por centro
- Confirmação final

#### Campos
- Regra de rateio
- Valor base
- Centros
- Percentual
- Valor calculado
- Diferença

#### Ações
- Simular
- Aplicar
- Exportar simulação

#### Estados
- Simulação calculada
- Diferença de arredondamento
- Regra inválida
- Rateio aplicado

#### Permissões
- `cost_allocation_simulation.view`
- `cost_allocations.apply`

#### Regras
- Soma dos valores distribuídos deve igualar valor base.
- Diferenças de arredondamento devem ser tratadas em um centro definido.
- Aplicação deve gerar registros rastreáveis.

---

### 3.10. Tela de Orçamento por Centro de Custo

**Objetivo:** planear custos/receitas por centro e período.

#### Web
- Grelha por centro, categoria/conta e mês
- Comparação orçado vs realizado
- Importação/exportação
- Alertas de desvio

#### Mobile
- Lista por centro e mês
- Barras de progresso

#### Campos
- Ano/período
- Centro de custo
- Conta/categoria
- Valor orçado
- Moeda
- Observação

#### Ações
- Criar orçamento
- Editar orçamento
- Importar
- Exportar
- Comparar realizado

#### Estados
- Sem orçamento
- Orçamento criado
- Realizado acima do orçado
- Valor inválido

#### Permissões
- `cost_center_budgets.view`
- `cost_center_budgets.manage`

#### Regras
- Valor orçado não pode ser negativo.
- Realizado vem dos lançamentos alocados.
- Alterações devem manter histórico.

---

### 3.11. Tela de Despesas Sem Centro de Custo

**Objetivo:** identificar valores que precisam de alocação.

#### Web
- Tabela com: data, documento, conta, valor, origem e responsável
- Filtros por: período, origem e conta
- Ação "Alocar"

#### Mobile
- Lista de pendências

#### Campos
- Data
- Documento
- Origem
- Conta
- Valor
- Responsável

#### Ações
- Alocar
- Ignorar
- Ver documento
- Exportar

#### Estados
- Sem pendências
- Pendente
- Ignorada
- Alocada

#### Permissões
- `cost_center_unallocated.view`
- `cost_center_allocations.create`

#### Regras
- Pendências devem excluir contas que não exigem centro.
- Ignorar deve exigir motivo.
- Pendências podem alimentar alertas.

---

### 3.12. Tela de Rentabilidade por Centro

**Objetivo:** analisar resultado financeiro por centro de custo.

#### Web
- Tabela com: centro, receitas, custos diretos, custos rateados, resultado e margem
- Gráfico de comparação
- Drill-down para documentos e lançamentos

#### Mobile
- Cards por centro
- Margem destacada

#### Campos / Filtros
- Período
- Centro
- Tipo
- Departamento
- Projeto

#### Ações
- Filtrar
- Ver detalhes
- Exportar
- Comparar períodos

#### Estados
- Sem dados
- Centro lucrativo
- Centro deficitário

#### Permissões
- `cost_center_profitability.view`
- `cost_center_profitability.export`

#### Regras
- Receita pode vir de faturação/contabilidade.
- Custos diretos e rateados devem ser separados.
- Margem = resultado / receita, quando receita > 0.

---

### 3.13. Tela de Configurações de Centros de Custo

**Objetivo:** definir políticas de uso.

#### Web
- Secções:
  - Obrigatoriedade por módulo
  - Contas que exigem centro
  - Aprovação de rateios
  - Orçamentos
  - Alertas de desvio
- Toggles e campos

#### Mobile
- Lista de configurações

#### Campos
- Exigir centro em compras
- Exigir centro em despesas financeiras
- Exigir centro em RH/folha
- Exigir centro em lançamentos manuais
- Percentual de alerta de orçamento
- Permitir alocação após encerramento
- Exigir aprovação de rateio

#### Ações
- Guardar configurações
- Restaurar padrão

#### Estados
- Configurações guardadas
- Erro de validação
- Sem permissão

#### Permissões
- `cost_center_settings.view`
- `cost_center_settings.update`

#### Regras
- Alterações devem ser auditadas.
- Exigência de centro deve validar documentos antes de emissão/aprovação.
- Períodos encerrados devem ser protegidos.

---

### 3.14. Tela de Relatórios de Centros de Custo

**Objetivo:** gerar relatórios gerenciais.

#### Web
- Lista:
  - Custos por centro
  - Orçado vs realizado
  - Rentabilidade por centro
  - Despesas sem centro
  - Rateios aplicados
  - Lançamentos por centro
  - Comparativo por período
- Filtros e exportação

#### Mobile
- Seleção de relatório
- Resumo e exportação

#### Campos / Filtros
- Período
- Centro de custo
- Conta
- Departamento
- Projeto
- Formato

#### Ações
- Gerar relatório
- Exportar PDF/XLSX/CSV
- Agendar envio

#### Estados
- Sem dados
- Gerando
- Relatório pronto
- Erro

#### Permissões
- `cost_center_reports.view`
- `cost_center_reports.export`

#### Regras
- Relatórios devem respeitar permissões financeiras/contabilísticas.
- Exportações devem ser auditadas.

---

## 4. Status Final

| Métrica | Valor |
|---------|-------|
| Módulos úteis concluídos | 23 |
| Módulos descontinuados | 1 (`seguranca`) |
| Módulos pendentes | 0 |

### Módulo Descontinuado
O módulo **seguranca** foi descontinuado e substituído pelos módulos:
- `autenticacao`
- `autorizacao`
- `auditoria`

---

## 5. Próximos Passos Recomendados

1. **Mapa completo de módulos** — consolidar em diagrama
2. **Lista final de telas Web** — extração de todas as telas documentadas
3. **Lista final de telas Mobile** — extração de adaptações mobile
4. **Permissões por módulo** — matriz de permissões completa
5. **Ordem recomendada de implementação** — priorização técnica
6. **MVP inicial do Nexora ERP** — definição do escopo mínimo viável
