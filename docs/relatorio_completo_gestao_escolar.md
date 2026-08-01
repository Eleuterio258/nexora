# Relatorio Completo - Modulo Gestao Escolar

**Data de actualizacao:** 2026-06-30  
**Projecto:** Nexora ERP / Painel Escola  
**Escopo:** Backend Go, frontend PHP, banco de dados, portais e permissoes  
**Base da analise:** estado actual do repositorio local em `D:\projecto\e-258tech\2026\factPro`

---

## 1. Resumo executivo

O modulo de **Gestao Escolar** ja nao e apenas um conjunto de ecras administrativos dentro do ERP. A implementacao actual separa a operacao escolar em tres frentes:

1. **Painel Escola (`/escola/*`)** para direccao, secretaria, professores e equipa administrativa.
2. **Portal do Aluno (`/portal/aluno/*`)** para auto-servico academico e financeiro do aluno.
3. **Portal do Encarregado (`/portal/encarregado/*`)** para acompanhamento dos educandos.

No backend, o modulo esta concentrado em `backend/internal/modules/gestao-escolar`, com handlers para estrutura academica, turmas, professores, alunos, matriculas, presencas, notas, propinas, biblioteca, comunicacao, horarios, calendario, ocorrencias, portal do aluno e portal do encarregado.

A realidade actual do sistema mostra uma evolucao importante desde o relatorio anterior:

- O endpoint antigo `/api/escolar/financial-config` ja nao e a rota principal. A configuracao financeira esta em `/api/escolar/config/financial`.
- Existem cargos e permissoes especificas para **Director de Turma** e **Chefe de Turma**.
- O login dos portais foi unificado em `auth.users`, com tipos `aluno` e `encarregado`.
- O escopo deixou de ficar apenas no utilizador e passou a ser tratado em `auth.memberships`.
- O modulo escolar esta separado do acesso ERP tradicional e usa painel proprio em `/escola/*`.
- Ha suporte para activacao, convite, reset de senha e gestao de sessoes do portal.

---

## 2. Stack tecnologica

| Camada | Tecnologia / padrao |
|---|---|
| Backend | Go, Chi Router, PostgreSQL, JWT, bcrypt |
| Frontend administrativo | PHP custom MVC, SSR, cURL para backend |
| Frontend portal | Templates PHP proprios para aluno e encarregado |
| Banco de dados | PostgreSQL com schemas por dominio |
| Comunicacao | REST JSON |
| Autorizacao | JWT + permissoes por modulo/accao + memberships |

---

## 3. Estado actual do backend escolar

Estrutura verificada:

```text
backend/internal/modules/gestao-escolar/
+-- handlers/       23 ficheiros Go
+-- models/          9 ficheiros Go
+-- repositories/   10 ficheiros Go
+-- services/       16 ficheiros Go, incluindo testes de servicos
```

Principais areas implementadas:

| Area | Estado no codigo |
|---|---|
| Anos lectivos e periodos | Implementado |
| Niveis, series e cursos | Implementado |
| Turmas e disciplinas | Implementado |
| Professores | Implementado |
| Atribuicoes de professores | Implementado |
| Alunos e encarregados | Implementado |
| Matriculas, transferencia e cancelamento | Implementado |
| Presencas / frequencia | Implementado |
| Avaliacoes, notas e boletins | Implementado |
| Propinas, cobrancas e pagamentos | Implementado |
| Configuracao financeira escolar | Implementado em `/api/escolar/config/financial` |
| Biblioteca e emprestimos | Implementado |
| Comunicacao e notificacoes | Implementado |
| Horarios e calendario | Implementado |
| Ocorrencias, sancoes e meritos | Implementado |
| Portal do aluno | Implementado |
| Portal do encarregado | Implementado |
| Cargos de alunos e professores | Implementado |
| Bolsas, parcelas e aging financeiro | Implementado |

---

## 4. Rotas reais do backend

As rotas estao definidas em `backend/internal/router/router.go`.

### 4.1 API administrativa escolar

Prefixo protegido:

```text
/api/escolar
```

Requer autenticacao normal do ERP e auditoria do modulo `gestao-escolar`.

Permissoes usadas:

| Permissao | Uso |
|---|---|
| `ver` | Consultas gerais, dashboard, listagens |
| `relatorios` | Relatorios academicos e financeiros |
| `gerir_turmas` | Anos, turmas, disciplinas, estrutura academica, professores e cargos |
| `gerir_alunos` | Alunos, encarregados e ligacao com clientes |
| `gerir_matriculas` | Matriculas, transferencias e cancelamentos |
| `gerir_presencas` | Lancamento e correccao de presencas |
| `lancar_notas` | Avaliacoes e notas |
| `gerir_propinas` | Planos, cobrancas, pagamentos, bolsas, parcelas e config financeira |
| `gerir_biblioteca` | Livros e emprestimos |
| `gerir_comunicacao` | Mensagens e comunicados |
| `gerir_horarios` | Slots e horarios |
| `gerir_calendario` | Eventos e tipos de evento |
| `gerir_ocorrencias` | Ocorrencias, sancoes e meritos |
| `portal_aluno` | Gestao administrativa do portal do aluno e encarregado |

### 4.2 Rotas administrativas de leitura

Incluem:

- `/api/escolar/years`
- `/api/escolar/classes`
- `/api/escolar/subjects`
- `/api/escolar/students`
- `/api/escolar/enrollments`
- `/api/escolar/student-roles`
- `/api/escolar/teacher-roles`
- `/api/escolar/attendance`
- `/api/escolar/grades`
- `/api/escolar/grade-items`
- `/api/escolar/fee-plans`
- `/api/escolar/student-invoices`
- `/api/escolar/library/books`
- `/api/escolar/library/loans`
- `/api/escolar/messages`
- `/api/escolar/notificacoes`
- `/api/escolar/teachers`
- `/api/escolar/levels`
- `/api/escolar/series`
- `/api/escolar/courses`
- `/api/escolar/dashboard`
- `/api/escolar/dashboard/direction`

### 4.3 Relatorios

Rotas disponiveis:

- `/api/escolar/reports/academic-summary`
- `/api/escolar/reports/financial-summary`
- `/api/escolar/reports/delinquency`
- `/api/escolar/report-cards/{student_id}`
- `/api/escolar/relatorios/aging`

### 4.4 Financeiro escolar

Rotas principais:

- `/api/escolar/fee-plans`
- `/api/escolar/fee-plans/{id}/generate`
- `/api/escolar/student-invoices`
- `/api/escolar/student-invoices/{id}/emit`
- `/api/escolar/student-invoices/{id}/discount`
- `/api/escolar/student-invoices/{id}/cancel`
- `/api/escolar/student-invoices/{id}/parcelas`
- `/api/escolar/payments`
- `/api/escolar/payments/{id}`
- `/api/escolar/payments/{id}/receipt`
- `/api/escolar/config/financial`
- `/api/escolar/bolsas`

### 4.5 Portal do aluno - API

Prefixo:

```text
/api/portal/aluno
```

Rotas publicas:

- `POST /login`
- `POST /definir-senha`

Rotas autenticadas:

- `POST /logout`
- `GET /me`
- `POST /alterar-senha`
- `GET /me/boletim`
- `GET /me/notas`
- `GET /me/cobrancas`
- `GET /me/cobrancas/{id}/recibo`
- `GET /me/horario`
- `GET /me/mensagens`
- `GET /me/eventos`
- `GET /me/presencas`
- `GET /me/ocorrencias`
- `GET /me/biblioteca`
- `POST /me/cobrancas/{id}/pagar`
- `GET /me/cobrancas/{id}/pagamento/{gtid}`

### 4.6 Portal do encarregado - API

Prefixo:

```text
/api/portal/encarregado
```

Rotas publicas:

- `POST /login`
- `POST /definir-senha`

Rotas autenticadas:

- `POST /logout`
- `GET /me`
- `POST /alterar-senha`
- `GET /me/educandos/{id}/boletim`
- `GET /me/educandos/{id}/cobrancas`
- `GET /me/educandos/{id}/presencas`
- `GET /me/educandos/{id}/ocorrencias`

---

## 5. Estado actual do frontend

### 5.1 Painel Escola

O frontend escolar administrativo esta separado em rotas proprias no ficheiro:

```text
frontend/src/Routing/SchoolAdminRoutes.php
```

O comentario do proprio ficheiro indica a mudanca de arquitectura:

```text
As rotas ERP (/nexora/gestao-escolar/*) foram removidas; o modulo escolar
agora so e acedido via Painel Escola.
```

Prefixo principal:

```text
/escola/*
```

Existem 30 paginas administrativas `escolar_*.php`, incluindo:

- Dashboard escolar;
- Anos lectivos;
- Niveis, series e cursos;
- Turmas;
- Disciplinas;
- Professores;
- Atribuicoes;
- Horarios;
- Calendario;
- Alunos;
- Matriculas;
- Cargos de alunos;
- Cargos de professores;
- Ocorrencias;
- Frequencia;
- Avaliacoes;
- Notas;
- Boletins;
- Planos de propinas;
- Cobrancas;
- Pagamentos;
- Aging / inadimplencia;
- Biblioteca;
- Emprestimos;
- Comunicacao;
- Resumo academico;
- Resumo financeiro;
- Configuracao financeira.

### 5.2 Modulo Aluno administrativo

Existe tambem roteamento em:

```text
frontend/src/Routing/StudentAdminRoutes.php
```

Prefixo:

```text
/aluno
```

Actualmente aponta para `aluno_portal.php`, usado como area de gestao do portal do aluno.

### 5.3 Portal do Aluno

Templates verificados em:

```text
frontend/src/View/templates/portal/
```

Paginas existentes:

- `login.php`
- `definir_senha.php`
- `dashboard.php`
- `perfil.php`
- `boletim.php`
- `boletim_print.php`
- `presencas.php`
- `horario.php`
- `cobrancas.php`
- `recibo_print.php`
- `mensagens.php`
- `eventos.php`
- `ocorrencias.php`
- `biblioteca.php`
- `conta.php`
- `layout_top.php`
- `layout_bottom.php`

### 5.4 Portal do Encarregado

Templates verificados em:

```text
frontend/src/View/templates/portal_encarregado/
```

Paginas existentes:

- `login.php`
- `definir_senha.php`
- `dashboard.php`
- `boletim.php`
- `presencas.php`
- `cobrancas.php`
- `ocorrencias.php`
- `conta.php`
- `layout_top.php`
- `layout_bottom.php`

---

## 6. Banco de dados e migrations

O directorio `backend/migrations` contem **97 migrations `.up.sql`**.

As migrations antigas numeradas `002_*.sql`, `003_*.sql`, etc. foram substituidas por migrations timestampadas no padrao:

```text
20260629000001_*.up.sql
```

Migrations escolares relevantes:

| Migration | Finalidade |
|---|---|
| `20260629000036_gestao_escolar.up.sql` | Base inicial do modulo escolar |
| `20260629000062_gestao_escolar_foundation.up.sql` | Fundacao escolar mais estruturada |
| `20260629000063_gestao_escolar_horarios_calendario.up.sql` | Horarios e calendario |
| `20260629000064_gestao_escolar_ocorrencias.up.sql` | Ocorrencias escolares |
| `20260629000065_gestao_escolar_configuracao_avancada.up.sql` | Configuracao avancada |
| `20260629000066_permissoes_gestao_escolar.up.sql` | Permissoes escolares |
| `20260629000067_gestao_escolar_financeiro.up.sql` | Financeiro escolar |
| `20260629000075_gestao_escolar_integracao_dependencias.up.sql` | Integracoes com dependencias |
| `20260629000076_gestao_escolar_ligacoes_rh_clientes.up.sql` | Ligacoes com RH e clientes |
| `20260629000077_gestao_escolar_config_integracao_completa.up.sql` | Configuracao completa de integracao |
| `20260629000079_portal_aluno.up.sql` | Portal do aluno |
| `20260629000082_portal_fase3.up.sql` | Evolucao do portal |
| `20260629000083_escola_notif_fase4.up.sql` | Notificacoes escolares |
| `20260629000084_portal_encarregado.up.sql` | Portal do encarregado |
| `20260629000085_escola_fase6.up.sql` | Parcelas, bolsas, referencias e aging |
| `20260629000086_permissoes_escolares_alinhamento.up.sql` | Alinhamento de permissoes |
| `20260629000088_users_escopo.up.sql` | Escopo de utilizador |
| `20260629000089_seed_utilizadores_teste_escopo.up.sql` | Seeds de teste por escopo |
| `20260629000090_classificar_utilizadores_por_escopo.up.sql` | Classificacao de utilizadores |
| `20260629000091_portal_aluno_lockout.up.sql` | Seguranca/lockout do portal |
| `20260629000092_gestao_escolar_fase2.up.sql` | Continuacao funcional do escolar |
| `20260629000093_cargos_turma.up.sql` | Director de Turma e Chefe de Turma |
| `20260629000094_separar_tipo_escopo.up.sql` | Separa `tipo` e `escopo` |
| `20260629000095_aluno_user_id.up.sql` | Liga aluno a `auth.users` |
| `20260629000096_unificar_login_portal.up.sql` | Login dos portais em `auth.users` |
| `20260629000097_backfill_portal_users.up.sql` | Backfill de utilizadores de portal |

---

## 7. Utilizadores, escopo e cargos

### 7.1 Tipos de utilizador

A realidade actual permite estes tipos em `auth.users`:

- `superadmin`
- `funcionario`
- `aluno`
- `encarregado`

Isto foi consolidado pelas migrations `094`, `095` e `096`.

### 7.2 Escopo

O escopo passa a estar associado a membership, nao apenas ao utilizador:

```text
auth.memberships.escopo IN ('erp', 'escola', 'ambos')
```

Este desenho permite que um funcionario exista no sistema, mas tenha acesso apenas ao ERP, apenas a escola ou aos dois contextos.

### 7.3 Cargos escolares

O sistema ja contempla cargos escolares alem da secretaria e direccao.

**Director de Turma**

Permissoes provisionadas:

- `ver`
- `relatorios`
- `lancar_notas`
- `gerir_presencas`
- `gerir_ocorrencias`
- `gerir_comunicacao`

Papel esperado no sistema:

- Acompanhar pedagogicamente a turma;
- Consultar relatorios da turma;
- Ver notas e presencas;
- Registar/corrigir presencas, quando autorizado;
- Acompanhar ocorrencias;
- Comunicar com alunos e encarregados.

**Chefe de Turma**

Permissoes provisionadas:

- `ver`
- `gerir_comunicacao`

Papel esperado no sistema:

- Apoiar a comunicacao da turma;
- Consultar informacao autorizada;
- Servir como ligacao entre colegas, director de turma e professores.

---

## 8. Integracoes com outros modulos

O modulo escolar esta integrado com:

| Modulo | Uso |
|---|---|
| Clientes | Ligacao de alunos/encarregados como clientes |
| Recursos Humanos | Ligacao de professores a funcionarios |
| Tesouraria | Registo de recebimentos |
| Financeiro | Contas a receber e pagamentos |
| Contabilidade | Lancamentos contabilisticos |
| Faturacao | Emissao de recibos |
| Aprovacoes | Descontos e fluxos que exigem aprovacao |
| Notificacoes | Avisos de cobrancas, mensagens e portal |
| Configuracao do sistema | Parametros por tenant |

---

## 9. O que cada perfil faz no sistema

### Direccao

- Ver dashboard geral e dashboard de direccao;
- Consultar relatorios academicos e financeiros;
- Acompanhar turmas, alunos, professores, matriculas, notas e propinas;
- Autorizar decisoes sensiveis, conforme permissoes;
- Supervisionar inadimplencia, aging e desempenho escolar;
- Acompanhar ocorrencias disciplinares;
- Definir ou validar politicas academicas e financeiras.

### Secretaria

- Cadastrar alunos e encarregados;
- Fazer e actualizar matriculas;
- Organizar turmas;
- Emitir documentos e boletins, quando autorizado;
- Actualizar dados administrativos;
- Apoiar activacao do portal do aluno e encarregado;
- Controlar processos diarios da escola.

### Professor

- Consultar turmas, disciplinas e horarios;
- Lancar presencas;
- Criar avaliacoes;
- Lancar e corrigir notas, conforme permissao;
- Consultar alunos das suas turmas;
- Comunicar com alunos e direccao;
- Registar ou acompanhar ocorrencias, quando autorizado.

### Director de Turma

- Acompanhar a turma de forma pedagogica;
- Consultar aproveitamento e assiduidade;
- Acompanhar ocorrencias;
- Comunicar com encarregados;
- Preparar relatorios para reunioes e conselhos de notas.

### Chefe de Turma

- Apoiar a organizacao e comunicacao da turma;
- Consultar informacao basica permitida;
- Encaminhar reclamacoes ou pedidos ao director de turma;
- Ajudar na circulacao de comunicados.

### Aluno

- Entrar no portal;
- Consultar perfil, matricula, boletim, notas, presencas e horario;
- Consultar cobrancas e recibos;
- Ver mensagens, eventos, ocorrencias e biblioteca;
- Iniciar pagamento de cobranca quando disponivel.

### Encarregado

- Entrar no portal do encarregado;
- Consultar educandos ligados ao seu registo;
- Ver boletim, cobrancas, presencas e ocorrencias dos educandos;
- Alterar senha e gerir a sua conta.

---

## 10. Pontos fortes actuais

- Separacao clara entre ERP, Painel Escola, Portal do Aluno e Portal do Encarregado.
- Backend com rotas REST organizadas por dominio.
- Permissoes granulares por accao.
- Evolucao de autenticacao dos portais para `auth.users`.
- Suporte a cargos escolares reais: Director de Turma e Chefe de Turma.
- Integracao financeira mais completa: cobrancas, pagamentos, recibos, parcelas, bolsas e aging.
- Gestao administrativa de convites, activacao e reset de senha do portal.
- Templates especificos para aluno e encarregado.

---

## 11. Pendencias e riscos reais

| # | Pendencia / risco | Impacto |
|---|---|---|
| 1 | Nao ha validacao neste relatorio contra uma base de dados em execucao | Os dados reais de producao/dev podem divergir do codigo |
| 2 | Frontend ainda usa muitos formularios operacionais genericos | UX pode ser fraca para secretaria e utilizadores nao tecnicos |
| 3 | Algumas paginas dependem de IDs e operacoes manuais | Risco de erro humano |
| 4 | Testes cobrem parte dos services, mas nao ha evidencia de cobertura ponta-a-ponta dos portais | Risco em fluxos de login, convite, pagamento e permissoes |
| 5 | O relatorio anterior citava endpoints e dados de tenant especificos ja ultrapassados | Nao usar os numeros antigos como referencia operacional |
| 6 | Comentarios/codigo em alguns ficheiros ainda apresentam mojibake | Pode dificultar manutencao e documentacao tecnica |
| 7 | As permissoes sao granulares, mas precisam ser validadas por perfil real | Risco de acesso indevido ou bloqueio de funcoes legitimas |

---

## 12. Recomendacoes

### Curto prazo

1. Validar o sistema com uma base de dados limpa aplicando as 97 migrations.
2. Testar login e fluxos completos dos portais de aluno e encarregado.
3. Criar utilizadores reais para direccao, secretaria, professor, director de turma, chefe de turma, aluno e encarregado.
4. Validar permissoes perfil por perfil.
5. Corrigir mojibake em comentarios e documentacao tecnica.

### Medio prazo

6. Melhorar formularios com selects pesquisaveis para aluno, turma, professor, curso e disciplina.
7. Adicionar testes de integracao para rotas criticas.
8. Criar seed escolar realista com alunos, matriculas, propinas, notas, horarios e encarregados.
9. Melhorar mensagens de erro no frontend PHP.
10. Documentar o fluxo de pagamento escolar ponta-a-ponta.

### Longo prazo

11. Criar paineis especializados por perfil: Direccao, Secretaria, Professor, Director de Turma e Chefe de Turma.
12. Adicionar trilhas de auditoria visiveis para alteracoes sensiveis, como notas e pagamentos.
13. Criar relatorios pedagogicos mais completos por turma, professor, disciplina e periodo.
14. Automatizar notificacoes de cobranca, faltas, ocorrencias e publicacao de notas.

---

## 13. Ficheiros principais

Backend:

- `backend/internal/router/router.go`
- `backend/internal/modules/gestao-escolar/handlers/`
- `backend/internal/modules/gestao-escolar/models/`
- `backend/internal/modules/gestao-escolar/repositories/`
- `backend/internal/modules/gestao-escolar/services/`
- `backend/internal/middleware/portal_auth.go`
- `backend/internal/middleware/portal_encarregado_auth.go`
- `backend/internal/background/jobs.go`

Frontend:

- `frontend/src/Routing/SchoolAdminRoutes.php`
- `frontend/src/Routing/StudentAdminRoutes.php`
- `frontend/src/Controller/Admin/Api/GestaoEscolarController.php`
- `frontend/src/Model/Service/School/SchoolService.php`
- `frontend/src/View/templates/pages/escolar_*.php`
- `frontend/src/View/templates/portal/*.php`
- `frontend/src/View/templates/portal_encarregado/*.php`

Migrations:

- `backend/migrations/20260629000036_gestao_escolar.up.sql`
- `backend/migrations/20260629000062_gestao_escolar_foundation.up.sql`
- `backend/migrations/20260629000067_gestao_escolar_financeiro.up.sql`
- `backend/migrations/20260629000079_portal_aluno.up.sql`
- `backend/migrations/20260629000084_portal_encarregado.up.sql`
- `backend/migrations/20260629000093_cargos_turma.up.sql`
- `backend/migrations/20260629000094_separar_tipo_escopo.up.sql`
- `backend/migrations/20260629000095_aluno_user_id.up.sql`
- `backend/migrations/20260629000096_unificar_login_portal.up.sql`
- `backend/migrations/20260629000097_backfill_portal_users.up.sql`

---

## 14. Conclusao

O modulo de Gestao Escolar encontra-se numa fase avancada de implementacao. A realidade actual do sistema inclui backend, painel administrativo escolar, portal do aluno, portal do encarregado, financeiro escolar, biblioteca, comunicacao, ocorrencias, horarios, calendario e permissoes por perfil.

O ponto mais importante e que a arquitectura mudou: o escolar ja esta tratado como **Painel Escola independente**, nao apenas como uma pagina dentro do ERP. A proxima etapa deve ser validar tudo com dados reais e perfis reais, garantindo que direccao, secretaria, professores, directores de turma, chefes de turma, alunos e encarregados tem exactamente os acessos necessarios para operar sem depender de permissoes administrativas amplas.
