# Cargos e Perfis de Acesso — Nexora ERP

> Arquitectura multi-tenant SaaS · Moçambique · v2026

---

## 1. Modelo RBAC

O Nexora ERP usa **Role-Based Access Control (RBAC)** com dois comportamentos distintos:

```text
superadmin  ─────────────────────────────────────► acesso total (sem verificações)

funcionario ──► cargo  ──┐
                directas ──┼──► permissões efectivas ──► Can(modulo, acao)?
                tipo    ──┘         filtradas por módulos activos do tenant
```

**Tabelas envolvidas:**

| Tabela | Schema | Função |
|---|---|---|
| `users` | `auth` | Utilizadores da plataforma — `tipo` define o perfil base |
| `memberships` | `auth` | Liga `user_id` ao `tenant_id` e ao `cargo_id` activo |
| `cargos` | `auth` | Catálogo de cargos do tenant (personalizáveis) |
| `permissoes_cargo` | `auth` | Permissões do cargo (`cargo_id, modulo, acao`) |
| `permissoes_diretas` | `auth` | Permissões adicionais directamente no utilizador |
| `permissoes_tipo` | `auth` | Permissões padrão por `tipo` de utilizador (baseline) |
| `tenant_modules` | `saas` | Módulos activos para cada tenant |
| `feature_catalog` | `saas` | Catálogo de features opcionais por módulo |
| `tenant_feature_flags` | `sistema_configuracao` | Overrides de features por tenant |

**Regra de resolução de permissões (para `funcionario`):**

```
Permissões efectivas =
    permissoes_cargo  ∪  permissoes_diretas  ∪  permissoes_tipo
    filtradas por saas.tenant_modules (módulos desactivados excluídos)
```

---

## 2. Tipos de Utilizador (`tipo`)

O campo `tipo` em `auth.users` tem um **CHECK constraint** na base de dados que aceita exactamente 2 valores:

```sql
CHECK (tipo IN ('superadmin', 'funcionario'))
```

| `tipo` | Âmbito | Comportamento no middleware | Descrição |
|---|---|---|---|
| `superadmin` | Plataforma | Bypassa **todo** o RBAC | Equipa Nexora. `tenant_id = 0`. Sem restrições. |
| `funcionario` | Tenant | RBAC completo via cargo | Todos os utilizadores da organização — professor, gestor de RH, contabilista, director escolar, recrutador. Acesso definido pelo cargo atribuído. |

**Regras fundamentais:**
- `tipo` responde a *"quem és na plataforma?"* — o `cargo` responde a *"o que podes fazer nesta organização?"*
- Um professor e um contabilista têm ambos `tipo = "funcionario"` — a diferença está no cargo, não no tipo
- O administrador da organização é um `funcionario` com cargo "Administrador" que tem permissões completas

### Lógica de verificação de permissão (middleware)

```
RequirePermission(modulo, acao)
│
├── superadmin?   → passa directo (sem verificações)
│
└── funcionario?  → LoadUserAccess()
                       permissoes_cargo ∪ permissoes_diretas ∪ permissoes_tipo
                       filtradas por saas.tenant_modules
                     → Can(modulo, acao)?
                       ├── sim → passa
                       └── não → 403
```

### Alteração de tipo

Apenas o `superadmin` pode alterar o `tipo` de um utilizador via `PUT /api/auth/utilizadores/{id}/tipo`.
Valores aceites: `"funcionario"` ou `"superadmin"`.

### Utilizadores de portais externos

Actores externos à organização **não têm registo em `auth.users`** — usam sistemas de autenticação separados:

| Actor | Mecanismo | Tabela de sessão |
|---|---|---|
| Aluno | JWT `tipo:"aluno"` + `RequireAlunoAuth` | `gestao_escolar.portal_sessions` |
| Candidato | Endpoints públicos sem autenticação | `recrutamento.candidaturas` |
| Encarregado de Educação | A implementar (portal separado) | — |

---

## 3. Módulos do ERP e Acções Disponíveis

Cada permissão é um par `(modulo, acao)`. Módulos registados no sistema:

| Módulo (`modulo`) | Cor | Área | Descrição |
|---|---|---|---|
| `auth` | Indigo `#6366F1` | Sistema | Gestão de utilizadores, cargos e sessões |
| `autorizacao` | Laranja `#F97316` | Sistema | Gestão de permissões e acessos |
| `empresa` | Azul `#2563EB` | Configuração | Dados da organização, filiais, configuração global |
| `sistema-configuracao` | Slate `#475569` | Configuração | Configurações técnicas, integrações, features |
| `auditoria` | Slate `#64748B` | Controlo | Logs de auditoria e rastreabilidade |
| `seguranca` | Vermelho `#DC2626` | Controlo | Políticas de segurança, bloqueios, 2FA |
| `clientes` | Violeta `#8B5CF6` | Comercial | Gestão de clientes (base CRM) |
| `crm` | Roxo `#A855F7` | Comercial | Oportunidades e pipeline de vendas |
| `vendas` | Azul `#3B82F6` | Comercial | Orçamentos, encomendas, contratos |
| `assinaturas` | Roxo `#9333EA` | Comercial | Subscrições e contratos recorrentes |
| `faturacao` | Indigo `#6366F1` | Financeiro | Emissão de faturas, notas de crédito |
| `pos` | Vermelho `#EF4444` | Financeiro | Ponto de venda presencial |
| `financeiro` | Teal `#14B8A6` | Financeiro | Contas a pagar/receber, gestão financeira |
| `tesouraria` | Verde `#059669` | Financeiro | Caixa, bancos, conciliação bancária |
| `contabilidade` | Ciano `#06B6D4` | Financeiro | Lançamentos contabilísticos, balancetes |
| `impostos` | Amarelo `#EAB308` | Financeiro | IVA, retenção na fonte, declarações fiscais |
| `multi-moeda` | Amber `#D97706` | Financeiro | Câmbio e transacções em moeda estrangeira |
| `centros-custo` | Stone `#78716C` | Financeiro | Centros de custo e análise por projecto |
| `stock` | Esmeralda `#10B981` | Operacional | Armazém, inventário, movimentos de stock |
| `compras` | Amber `#F59E0B` | Operacional | Requisições, fornecedores, ordens de compra |
| `logistica` | Lime `#84CC16` | Operacional | Expedição, entregas, rastreamento |
| `recrutamento` | Sky `#0284C7` | RH | Vagas, candidaturas, processo de selecção |
| `recursos-humanos` | Rosa `#EC4899` | RH | Funcionários, contratos, salários, avaliações |
| `pedido-ferias` | Rosa clara `#F472B6` | RH | Portal de pedidos de férias e licenças |
| `gestao-escolar` | Teal escuro `#0D9488` | Escolar | Alunos, turmas, notas, matrículas, biblioteca |
| `notificacoes` | Sky `#0EA5E9` | Transversal | Notificações e comunicados internos |

### Acções-padrão (CRUD)

A maioria dos módulos suporta estas acções:

| Acção | Descrição |
|---|---|
| `ver` | Listar e consultar registos |
| `criar` | Criar novos registos |
| `editar` | Actualizar registos existentes |
| `apagar` | Eliminar / arquivar registos |
| `exportar` | Exportar dados para Excel/PDF |
| `aprovar` | Aprovar fluxos que requerem autorização |
| `configurar` | Alterar configurações do módulo |
| `relatorios` | Aceder a relatórios e dashboards |

> Módulos com lógica específica definem acções adicionais — ver secções 4.3 (Recrutamento) e 4.6 (Gestão Escolar).

---

## 4. Cargos por Módulo

Os cargos são criados por tenant e totalmente personalizáveis. Abaixo os cargos-tipo recomendados por área.
A função `auth.criar_cargos_padrao(tenant_id)` cria automaticamente estes cargos ao provisionar um novo tenant.

---

### 4.1 Sistema e Administração

| Cargo | Módulos | Descrição |
|---|---|---|
| **Administrador** | Todos | Acesso total ao tenant. Gere utilizadores, cargos e configurações. |
| **Gestor de TI** | `auth`, `autorizacao`, `sistema-configuracao`, `auditoria`, `seguranca` | Gestão técnica, integrações e segurança. |
| **Auditor Interno** | `auditoria:ver,relatorios`, `financeiro:ver,relatorios`, `contabilidade:ver,relatorios` | Acesso de leitura para fins de auditoria. |

---

### 4.2 Recursos Humanos

| Cargo | Acções principais | Descrição |
|---|---|---|
| **Director de RH** | `recursos-humanos:*`, `pedido-ferias:ver,aprovar,relatorios` | Gestão estratégica de RH, aprovação de políticas. |
| **Gestor de RH** | `recursos-humanos:ver,criar,editar,relatorios,exportar`, `pedido-ferias:ver,aprovar` | Admissão, transferências, avaliações. |
| **Técnico de Processamento Salarial** | `recursos-humanos:ver,editar`, `contabilidade:ver` | Folha de salários, componentes salariais, benefícios. |
| **Técnico de RH** | `recursos-humanos:ver,criar,editar`, `pedido-ferias:ver` | Fichas de funcionários, formações, documentação. |

**Sub-módulos de Recursos Humanos:**

| Sub-módulo | Função |
|---|---|
| Hierarquia e organograma | Estrutura orgânica da organização |
| Componentes salariais | Rubricas salariais (base, subsídios, descontos) |
| Histórico salarial | Evolução remuneratória dos funcionários |
| Benefícios | Planos de benefícios por categoria |
| Formações | Plano de formação e registo de certificações |
| Avaliações de desempenho | Ciclos de avaliação e KPIs |
| Férias e licenças | Gestão de ausências, balanço de dias |
| Pedidos de férias | Portal de submissão e aprovação |
| Horários de trabalho | Turnos e escalas |
| Dados complementares | Documentos, contactos de emergência |

---

### 4.3 Recrutamento

#### Acções do módulo `recrutamento`

| Acção | Descrição |
|---|---|
| `ver_vagas` | Consultar vagas publicadas e em rascunho |
| `gerir_vagas` | Criar, editar, publicar e fechar vagas |
| `ver_candidaturas` | Consultar candidaturas recebidas |
| `gerir_candidaturas` | Mover candidaturas no pipeline, registar entrevistas |
| `configurar_recrutamento` | Configurar pipelines, formulários e tipos de avaliação |

| Cargo | Acções principais | Descrição |
|---|---|---|
| **Gestor de Recrutamento** | `recrutamento:*`, `recursos-humanos:ver` | Aprova vagas, gere o processo end-to-end, integra com RH. |
| **Recrutador** | `recrutamento:ver_vagas,gerir_vagas,ver_candidaturas,gerir_candidaturas` | Publica vagas, triagem e gestão de candidaturas. |
| **Responsável de Entrevistas** | `recrutamento:ver_vagas,ver_candidaturas` | Avalia candidatos e regista feedback de entrevistas. |

**Portal Público de Candidaturas** (sem autenticação ERP):
- Acesso via `/api/public/recrutamento/*` — sem conta no ERP
- Consulta de vagas, submissão de candidatura, upload de documentos (CV, certificados)
- Consulta do estado da candidatura por email + código

---

### 4.4 Gestão de Clientes

| Cargo | Acções principais | Descrição |
|---|---|---|
| **Director Comercial** | `clientes:*`, `vendas:*`, `crm:*`, `faturacao:ver,relatorios` | Visão global, aprovação de descontos e contratos. |
| **Gestor de Conta** | `clientes:ver,editar`, `vendas:ver,criar,editar`, `crm:ver,criar,editar,apagar` | Carteira de clientes e oportunidades. |
| **Técnico Comercial** | `clientes:ver`, `vendas:ver,criar`, `crm:ver,editar` | Orçamentos e seguimento de oportunidades. |
| **Assistente Administrativo** | `clientes:ver,criar`, `faturacao:ver` | Registo de clientes e consulta de faturas. |

---

### 4.5 Financeiro e Contabilidade

| Cargo | Acções principais | Descrição |
|---|---|---|
| **Director Financeiro** | `financeiro:*`, `contabilidade:*`, `tesouraria:*`, `impostos:*`, `faturacao:*`, `centros-custo:ver,criar,editar,relatorios`, `multi-moeda:ver,criar,editar,configurar` | Supervisão total da área financeira. |
| **Contabilista** | `contabilidade:ver,criar,editar,relatorios,exportar`, `impostos:ver,criar,relatorios`, `financeiro:ver,relatorios` | Lançamentos contabilísticos, declarações fiscais. |
| **Tesoureiro** | `tesouraria:ver,criar,editar,apagar,exportar,relatorios`, `financeiro:ver,editar` | Caixa, bancos, conciliação. |
| **Caixa** | `pos:ver,criar,editar,relatorios`, `tesouraria:ver` | Operações de ponto de venda. |
| **Responsável de Faturação** | `faturacao:ver,criar,editar,relatorios,exportar`, `clientes:ver` | Emissão e gestão de faturas. |
| **Analista Financeiro** | `financeiro:ver,relatorios,exportar`, `contabilidade:ver,relatorios`, `centros-custo:ver,relatorios` | Análise financeira e reporting. |

---

### 4.6 Gestão Escolar

> Contexto: **Sistema Nacional de Educação de Moçambique (SNE)**

#### Estrutura do SNE

| Código | Subsistema | Designação | Classes / Duração |
|---|---|---|---|
| `PRE` | Pré-Escolar | Educação Pré-Escolar | Creche (0-3a) / Jardim (3-6a) |
| `EP1` | Ensino Primário | 1.º Grau | 1.ª – 5.ª classe |
| `EP2` | Ensino Primário | 2.º Grau | 6.ª – 7.ª classe |
| `ESG1` | Ens. Secundário Geral | 1.º Ciclo | 8.ª – 10.ª classe |
| `ESG2` | Ens. Secundário Geral | 2.º Ciclo | 11.ª – 12.ª classe |
| `ETB` | Ens. Técnico-Profissional | Técnico Básico | 3 anos (após EP2) |
| `ETM` | Ens. Técnico-Profissional | Técnico Médio | 3 anos (após ESG1) |
| `ETE` | Ens. Técnico-Profissional | Técnico Elementar | 1-2 anos (após EP1) |
| `ES-B` | Ensino Superior | Bacharelato | 3 anos |
| `ES-L` | Ensino Superior | Licenciatura | 4-5 anos |
| `ES-M` | Ensino Superior | Mestrado | 2 anos |
| `ES-D` | Ensino Superior | Doutoramento | 3+ anos |
| `CCD` | Formação Contínua | Curso de Curta Duração | Variável |

#### Acções do módulo `gestao-escolar`

| Acção | Rotas protegidas | Descrição |
|---|---|---|
| `ver` | `GET /api/escolar/*` | Consultar dados escolares gerais |
| `relatorios` | `GET /api/escolar/reports/*`, `/report-cards` | Pautas, boletins, relatórios de frequência |
| `gerir_turmas` | `/classes`, `/teachers`, `/subjects`, `/years`, `/levels`, `/series`, `/courses` | Turmas, professores, disciplinas, anos lectivos e estrutura académica |
| `gerir_alunos` | `/students`, `/guardians` | Criar, editar e arquivar alunos e encarregados |
| `gerir_matriculas` | `/enrollments` | Abrir, transferir e cancelar matrículas |
| `lancar_notas` | `/grades`, `/grade-items` | Registar e corrigir notas de avaliação |
| `gerir_presencas` | `/attendance` | Registar e justificar presenças/faltas |
| `gerir_horarios` | `/timetables`, `/time-slots` | Criar e publicar horários lectivos |
| `gerir_calendario` | `/calendar-events`, `/calendar-event-types` | Calendário escolar e eventos |
| `gerir_propinas` | `/fee-plans`, `/student-invoices`, `/payments`, `/config/financial` | Emitir e gerir cobranças de propinas |
| `gerir_biblioteca` | `/library/books`, `/loans` | Gestão de livros, empréstimos e devoluções |
| `gerir_ocorrencias` | `/incidents`, `/sanctions`, `/merits` | Registar incidentes, sanções e méritos |
| `gerir_comunicacao` | `/messages` | Criar e publicar avisos e comunicados escolares |
| `portal_aluno` | `/students/{id}/portal/*` | Activar/desactivar acesso de alunos ao portal |
| `configurar` | — | Configurações gerais do módulo |

#### Cargos escolares recomendados

**Gestão / Administração:**

| Cargo | Acções `gestao-escolar` | Descrição |
|---|---|---|
| **Director Escolar** | `*` | Acesso total. Homologa pautas, gere configurações. |
| **Director Adjunto Pedagógico** | `ver, gerir_turmas, gerir_horarios, gerir_calendario, gerir_presencas, gerir_ocorrencias, gerir_comunicacao, relatorios` | Supervisão pedagógica e aprovação de planos. |
| **Secretário Escolar** | `ver, gerir_alunos, gerir_matriculas, gerir_propinas, relatorios` | Matrículas, propinas, documentação. |
| **Bibliotecário** | `ver, gerir_biblioteca` | Gestão de acervo e empréstimos. |

**Professores:**

| Cargo | Acções `gestao-escolar` | Descrição |
|---|---|---|
| **Professor** | `ver, lancar_notas, gerir_presencas` | Notas e presenças das suas disciplinas/turmas. |
| **Director de Turma** | `ver, relatorios, lancar_notas, gerir_presencas, gerir_ocorrencias, gerir_comunicacao` | Acompanha pedagogicamente a turma, consulta relatórios e comunica com encarregados. |
| **Chefe de Turma** | `ver, gerir_comunicacao` | Apoia a comunicação e organização da turma. |
| **Coordenador de Disciplina** | `ver, lancar_notas, gerir_presencas, relatorios` | Coordena o grupo de professores da disciplina. |
| **Coordenador de Ciclo** | `ver, relatorios, gerir_ocorrencias` | Supervisiona um ciclo (EP1, ESG1, etc.). |
| **Chefe de Oficina / Lab.** | `ver, lancar_notas, gerir_presencas` | Componente prática do ensino técnico (ETP). |

**Cargos internos (Brigada de Turma — alunos):**

| Código | Designação | Nível |
|---|---|---|
| `ALUNO_CHEFE` | Chefe de Turma | EP2, ESG |
| `ALUNO_SUBCHEFE` | Subchefe de Turma | EP2, ESG |
| `ALUNO_HIGIENE` | Resp. Higiene e Embelezamento | EP, ESG |
| `ALUNO_INFORMACAO` | Resp. Informação e Cultura | EP, ESG |
| `ALUNO_SEGURANCA` | Resp. Ordem e Segurança | ESG |
| `EST_CHEFE_TURMA` | Chefe de Turma | ETB, ETM |
| `EST_DELEGADO_CURSO` | Delegado de Curso | ETM |
| `DELEGADO_TURMA` | Delegado de Turma | ES |
| `PRESIDENTE_AAE` | Presidente da Assoc. Académica | ES |

**Encarregados de Educação** (portal separado — a implementar):

| Código | Designação | Descrição |
|---|---|---|
| `PAI_TURMA` | Pai de Turma | Representante masculino no Conselho de Escola |
| `MAE_TURMA` | Mãe de Turma | Representante feminina no Conselho de Escola |
| `REP_CONSELHO` | Representante no Conselho | Membro do Conselho de Escola |

---

## 5. Portal do Aluno

Interface separada do ERP principal, com autenticação independente.

| Aspecto | Detalhe |
|---|---|
| **Tipo de utilizador** | `aluno_portal` (claim JWT `tipo:"aluno"`) |
| **JWT** | 8 horas de validade |
| **Sessão** | `gestao_escolar.portal_sessions` (token_hash, ativa, expira_em) |
| **Activação** | Admin activa via `POST /api/escolar/students/{id}/portal/activate` (requer `gestao-escolar:portal_aluno`) |
| **Primeiro acesso** | Token de convite 72h via `POST /api/escolar/students/{id}/portal/invite` |
| **URL base** | `/portal/aluno/` |

**Funcionalidades do portal:**

| Página | Endpoint | Descrição |
|---|---|---|
| Dashboard | `GET /api/portal/aluno/me` | Resumo, propinas pendentes, avisos |
| Perfil | `GET /api/portal/aluno/me` | Dados pessoais, encarregados, matrícula activa |
| Boletim | `GET /api/portal/aluno/me/boletim` | Notas por período, médias, resultado |
| Presenças | `GET /api/portal/aluno/me/presencas` | Assiduidade global e por disciplina |
| Horário | `GET /api/portal/aluno/me/horario` | Horário semanal com professor e sala |
| Propinas | `GET /api/portal/aluno/me/cobrancas` | Cobranças, estado, datas de vencimento |
| Avisos | `GET /api/portal/aluno/me/mensagens` | Comunicados da escola e da turma |
| Eventos | `GET /api/portal/aluno/me/eventos` | Calendário escolar |
| Ocorrências | `GET /api/portal/aluno/me/ocorrencias` | Incidentes, sanções e méritos |
| Biblioteca | `GET /api/portal/aluno/me/biblioteca` | Empréstimos activos e histórico |
| Alterar senha | `POST /api/portal/aluno/alterar-senha` | Gestão da conta do portal |

---

## 6. Matriz de Acesso por Perfil (Resumo)

| Módulo | superadmin | Administrador | Dir. Escolar | Professor | Sec. Escolar | Gestor RH | Recrutador | Dir. Financeiro |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `auth` / `autorizacao` | ✅ | ✅ | — | — | — | — | — | — |
| `gestao-escolar` | ✅ | ✅ | ✅ total | ✅ parcial | ✅ parcial | — | — | — |
| `recursos-humanos` | ✅ | ✅ | — | — | — | ✅ total | — | ✅ ver |
| `pedido-ferias` | ✅ | ✅ | — | — | — | ✅ | — | — |
| `recrutamento` | ✅ | ✅ | — | — | — | ✅ ver | ✅ | — |
| `clientes` | ✅ | ✅ | — | — | — | — | — | ✅ ver |
| `faturacao` | ✅ | ✅ | — | — | ✅ ver | — | — | ✅ |
| `financeiro` | ✅ | ✅ | — | — | — | — | — | ✅ |
| `contabilidade` | ✅ | ✅ | — | — | — | — | — | ✅ |
| `tesouraria` | ✅ | ✅ | — | — | — | — | — | ✅ |
| `auditoria` | ✅ | ✅ | — | — | — | — | — | ✅ ver |
| `sistema-configuracao` | ✅ | ✅ | — | — | — | — | — | — |

---

## 7. Endpoints de API

Base URL: `/api` · Header obrigatório: `Authorization: Bearer <token>`

### 7.1 Autenticação (`/api/auth`)

| Método | Endpoint | Acesso | Descrição |
|---|---|---|---|
| `POST` | `/api/auth/login` | Público | Autenticar utilizador (devolve JWT) |
| `POST` | `/api/auth/refresh` | Público | Renovar access token via refresh token |
| `POST` | `/api/auth/forgot-password` | Público | Enviar email de recuperação de senha |
| `POST` | `/api/auth/reset-password` | Público | Redefinir senha via token de email |
| `GET` | `/api/auth/me` | Autenticado | Perfil + módulos + permissões do utilizador |
| `GET` | `/api/auth/me/acesso` | Autenticado | Mapa completo de permissões efectivas |
| `POST` | `/api/auth/logout` | Autenticado | Revogar sessão activa |
| `POST` | `/api/auth/change-password` | Autenticado | Alterar própria senha |

### 7.2 Utilizadores e Cargos (`/api/auth/utilizadores`, `/api/auth/cargos`)

| Método | Endpoint | Permissão | Descrição |
|---|---|---|---|
| `GET` | `/api/auth/utilizadores` | `autorizacao:gerir_utilizadores` | Listar utilizadores do tenant |
| `POST` | `/api/auth/utilizadores` | `autorizacao:gerir_utilizadores` | Criar utilizador |
| `GET` | `/api/auth/utilizadores/{id}` | `autorizacao:gerir_utilizadores` | Obter utilizador |
| `PUT` | `/api/auth/utilizadores/{id}` | `autorizacao:gerir_utilizadores` | Actualizar utilizador |
| `POST` | `/api/auth/utilizadores/{id}/activar` | `autorizacao:gerir_utilizadores` | Activar utilizador |
| `POST` | `/api/auth/utilizadores/{id}/bloquear` | `autorizacao:gerir_utilizadores` | Bloquear utilizador |
| `POST` | `/api/auth/utilizadores/{id}/desactivar` | `autorizacao:gerir_utilizadores` | Desactivar utilizador |
| `PUT` | `/api/auth/utilizadores/{id}/cargo` | `autorizacao:gerir_utilizadores` | Atribuir cargo ao utilizador |
| `PUT` | `/api/auth/utilizadores/{id}/tipo` | `superadmin` apenas | Alterar tipo (funcionario/superadmin) |
| `PUT` | `/api/auth/utilizadores/{id}/permissoes` | `autorizacao:gerir_utilizadores` | Definir permissões directas |
| `GET` | `/api/auth/utilizadores/{id}/permissoes` | `autorizacao:gerir_utilizadores` | Listar permissões directas |
| `POST` | `/api/auth/utilizadores/{id}/reset-password` | `superadmin` apenas | Redefinir senha (admin) |
| `GET` | `/api/auth/cargos` | `autorizacao:gerir_perfis` | Listar cargos do tenant |
| `POST` | `/api/auth/cargos` | `autorizacao:gerir_perfis` | Criar cargo |
| `GET` | `/api/auth/cargos/{id}` | `autorizacao:gerir_perfis` | Obter cargo |
| `PUT` | `/api/auth/cargos/{id}` | `autorizacao:gerir_perfis` | Actualizar cargo |
| `POST` | `/api/auth/cargos/{id}/activar` | `autorizacao:gerir_perfis` | Activar cargo |
| `POST` | `/api/auth/cargos/{id}/desactivar` | `autorizacao:gerir_perfis` | Desactivar cargo |
| `GET` | `/api/auth/cargos/{id}/permissoes` | `autorizacao:gerir_perfis` | Listar permissões do cargo |
| `PUT` | `/api/auth/cargos/{id}/permissoes` | `autorizacao:gerir_perfis` | Substituir permissões do cargo |
| `GET` | `/api/auth/sessoes` | `autorizacao:gerir_utilizadores` | Listar sessões activas |
| `POST` | `/api/auth/sessoes/{id}/revogar` | `autorizacao:gerir_utilizadores` | Revogar sessão |

### 7.3 Gestão Escolar (`/api/escolar`)

| Método | Endpoint | Permissão | Descrição |
|---|---|---|---|
| `GET` | `/api/escolar/years` | `ver` | Listar anos lectivos |
| `POST` | `/api/escolar/years` | `gerir_turmas` | Criar ano lectivo |
| `PUT` | `/api/escolar/years/{id}` | `gerir_turmas` | Actualizar ano lectivo |
| `POST` | `/api/escolar/years/{id}/activar` | `gerir_turmas` | Activar ano lectivo |
| `POST` | `/api/escolar/years/{id}/close` | `gerir_turmas` | Encerrar ano lectivo |
| `POST` | `/api/escolar/years/{id}/terms` | `gerir_turmas` | Criar período lectivo |
| `GET` | `/api/escolar/classes` | `ver` | Listar turmas |
| `POST` | `/api/escolar/classes` | `gerir_turmas` | Criar turma |
| `PUT` | `/api/escolar/classes/{id}` | `gerir_turmas` | Actualizar turma |
| `POST` | `/api/escolar/classes/{id}/assign-teacher` | `gerir_turmas` | Atribuir director de turma |
| `GET` | `/api/escolar/subjects` | `ver` | Listar disciplinas |
| `POST` | `/api/escolar/subjects` | `gerir_turmas` | Criar disciplina |
| `POST` | `/api/escolar/teacher-assignments` | `gerir_turmas` | Atribuir professor a disciplina/turma |
| `GET` | `/api/escolar/teachers` | `ver` | Listar professores |
| `POST` | `/api/escolar/teachers` | `gerir_turmas` | Criar professor |
| `PUT` | `/api/escolar/teachers/{id}` | `gerir_turmas` | Actualizar professor |
| `DELETE` | `/api/escolar/teachers/{id}` | `gerir_turmas` | Remover professor |
| `GET` | `/api/escolar/students` | `ver` | Listar alunos |
| `POST` | `/api/escolar/students` | `gerir_alunos` | Criar aluno |
| `PUT` | `/api/escolar/students/{id}` | `gerir_alunos` | Actualizar aluno |
| `POST` | `/api/escolar/students/{id}/guardians` | `gerir_alunos` | Adicionar encarregado |
| `POST` | `/api/escolar/enrollments` | `gerir_matriculas` | Criar matrícula |
| `POST` | `/api/escolar/enrollments/{id}/transfer` | `gerir_matriculas` | Transferir matrícula |
| `POST` | `/api/escolar/enrollments/{id}/cancel` | `gerir_matriculas` | Cancelar matrícula |
| `POST` | `/api/escolar/attendance` | `gerir_presencas` | Lançar presenças |
| `PUT` | `/api/escolar/attendance/{id}` | `gerir_presencas` | Corrigir presença |
| `POST` | `/api/escolar/grade-items` | `lancar_notas` | Criar avaliação |
| `POST` | `/api/escolar/grade-items/{id}/publish` | `lancar_notas` | Publicar avaliação |
| `POST` | `/api/escolar/grades` | `lancar_notas` | Lançar notas |
| `PUT` | `/api/escolar/grades/{id}` | `lancar_notas` | Corrigir nota |
| `GET` | `/api/escolar/report-cards/{student_id}` | `ver` ou `relatorios` | Obter boletim do aluno |
| `GET` | `/api/escolar/reports/academic-summary` | `ver` ou `relatorios` | Relatório académico |
| `GET` | `/api/escolar/reports/financial-summary` | `ver` ou `relatorios` | Relatório financeiro escolar |
| `GET` | `/api/escolar/reports/delinquency` | `ver` ou `relatorios` | Relatório de inadimplência |
| `POST` | `/api/escolar/fee-plans` | `gerir_propinas` | Criar plano de propinas |
| `POST` | `/api/escolar/fee-plans/{id}/generate` | `gerir_propinas` | Gerar cobranças do plano |
| `POST` | `/api/escolar/student-invoices` | `gerir_propinas` | Gerar cobrança individual |
| `POST` | `/api/escolar/student-invoices/{id}/emit` | `gerir_propinas` | Emitir cobrança |
| `POST` | `/api/escolar/payments` | `gerir_propinas` | Registar pagamento |
| `POST` | `/api/escolar/library/books` | `gerir_biblioteca` | Criar livro |
| `POST` | `/api/escolar/library/loans` | `gerir_biblioteca` | Registar empréstimo |
| `POST` | `/api/escolar/library/loans/{id}/return` | `gerir_biblioteca` | Confirmar devolução |
| `POST` | `/api/escolar/messages` | `gerir_comunicacao` | Criar mensagem escolar |
| `POST` | `/api/escolar/messages/{id}/publish` | `gerir_comunicacao` | Publicar mensagem |
| `GET` | `/api/escolar/timetables/class/{id}` | `ver` | Horário da turma |
| `POST` | `/api/escolar/timetables` | `gerir_horarios` | Criar horário |
| `PUT` | `/api/escolar/timetables/{id}` | `gerir_horarios` | Actualizar horário |
| `DELETE` | `/api/escolar/timetables/{id}` | `gerir_horarios` | Remover horário |
| `GET` | `/api/escolar/calendar-events` | `ver` | Listar eventos do calendário |
| `POST` | `/api/escolar/calendar-events` | `gerir_calendario` | Criar evento |
| `PUT` | `/api/escolar/calendar-events/{id}` | `gerir_calendario` | Actualizar evento |
| `DELETE` | `/api/escolar/calendar-events/{id}` | `gerir_calendario` | Remover evento |
| `GET` | `/api/escolar/incidents` | `ver` | Listar ocorrências |
| `POST` | `/api/escolar/incidents` | `gerir_ocorrencias` | Criar ocorrência |
| `PUT` | `/api/escolar/incidents/{id}` | `gerir_ocorrencias` | Actualizar ocorrência |
| `POST` | `/api/escolar/sanctions` | `gerir_ocorrencias` | Registar sanção |
| `POST` | `/api/escolar/merits` | `gerir_ocorrencias` | Registar mérito |
| `GET` | `/api/escolar/dashboard/direction` | `ver` | Dashboard da direcção |

> Todas as permissões acima são do módulo `gestao-escolar`.

### 7.4 Portal do Aluno (`/api/portal/aluno`)

| Método | Endpoint | Acesso | Descrição |
|---|---|---|---|
| `POST` | `/api/portal/aluno/login` | Público | Login do aluno (JWT `tipo:"aluno"`) |
| `POST` | `/api/portal/aluno/definir-senha` | Público | Definir senha via token de convite |
| `POST` | `/api/portal/aluno/logout` | Portal | Terminar sessão |
| `GET` | `/api/portal/aluno/me` | Portal | Dados e matrícula activa |
| `POST` | `/api/portal/aluno/alterar-senha` | Portal | Alterar senha |
| `GET` | `/api/portal/aluno/me/boletim` | Portal | Notas por período |
| `GET` | `/api/portal/aluno/me/presencas` | Portal | Assiduidade |
| `GET` | `/api/portal/aluno/me/horario` | Portal | Horário semanal |
| `GET` | `/api/portal/aluno/me/cobrancas` | Portal | Propinas |
| `GET` | `/api/portal/aluno/me/mensagens` | Portal | Avisos e comunicados |
| `GET` | `/api/portal/aluno/me/eventos` | Portal | Calendário escolar |
| `GET` | `/api/portal/aluno/me/ocorrencias` | Portal | Incidentes, sanções e méritos |
| `GET` | `/api/portal/aluno/me/biblioteca` | Portal | Empréstimos activos e histórico |

### 7.5 Gestão do Portal pelo Admin

| Método | Endpoint | Permissão | Descrição |
|---|---|---|---|
| `GET` | `/api/escolar/students/{id}/portal/status` | `gestao-escolar:portal_aluno` | Estado do portal do aluno |
| `POST` | `/api/escolar/students/{id}/portal/activate` | `gestao-escolar:portal_aluno` | Activar acesso ao portal |
| `POST` | `/api/escolar/students/{id}/portal/deactivate` | `gestao-escolar:portal_aluno` | Desactivar acesso |
| `POST` | `/api/escolar/students/{id}/portal/invite` | `gestao-escolar:portal_aluno` | Gerar link de convite (72h) |
| `POST` | `/api/escolar/students/{id}/portal/reset-senha` | `gestao-escolar:portal_aluno` | Redefinir senha do aluno |

### 7.6 Superadmin (`/api/superadmin`)

> Todas estas rotas requerem `tipo = "superadmin"`.

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/api/superadmin/tenants` | Listar tenants |
| `POST` | `/api/superadmin/tenants` | Criar tenant (cria cargos-padrão automaticamente) |
| `GET` | `/api/superadmin/tenants/{id}` | Obter tenant |
| `PUT` | `/api/superadmin/tenants/{id}` | Actualizar tenant |
| `DELETE` | `/api/superadmin/tenants/{id}` | Eliminar tenant |
| `POST` | `/api/superadmin/tenants/{id}/suspender` | Suspender tenant |
| `POST` | `/api/superadmin/tenants/{id}/reativar` | Reactivar tenant |
| `POST` | `/api/superadmin/tenants/{id}/inativar` | Inactivar tenant |
| `POST` | `/api/superadmin/tenants/{id}/cargos-padrao` | Provisionar cargos-padrão (idempotente) |
| `GET` | `/api/superadmin/modules/tenants/{id}` | Módulos activos do tenant |
| `POST` | `/api/superadmin/modules/tenants/{id}/{modulo}` | Activar/desactivar módulo |
| `GET` | `/api/superadmin/features/tenants/{id}` | Feature flags do tenant |
| `POST` | `/api/superadmin/features/tenants/{id}/{key}` | Alterar feature flag |

---

## 8. Códigos de Erro HTTP

| Código | Significado | Contexto típico |
|---|---|---|
| `401` | Token ausente, inválido ou expirado | Qualquer rota autenticada |
| `403` | Sem permissão para a operação | RBAC — cargo não tem a permissão |
| `404` | Recurso não encontrado | ID inexistente no tenant |
| `409` | Conflito — recurso já existe | Email duplicado, matrícula já activa |
| `422` | Entidade inprocessável | Validação falhou (ex.: pauta fechada) |

**Formato de erro padrão:**

```json
{
  "error": "Sem permissão"
}
```

---

## 9. Extensibilidade

- **Cargos são por tenant** — cada organização cria os seus próprios cargos com as permissões que necessita.
- **Cargos-padrão** — ao criar um tenant, `auth.criar_cargos_padrao(tenant_id)` é chamado automaticamente; pode ser re-aplicado via `POST /api/superadmin/tenants/{id}/cargos-padrao`.
- **Permissões directas** — um utilizador pode ter permissões adicionais além do seu cargo, sem alterar o cargo.
- **Módulos por tenant** — o superadmin pode activar/desactivar módulos (`saas.tenant_modules`) para cada organização.
- **Feature flags** — funcionalidades opcionais dentro de cada módulo são controladas via `saas.feature_catalog` + `tenant_feature_flags`.
- **Múltiplos cargos (futuro)** — actualmente 1 cargo activo por utilizador; a arquitectura de tabelas permite extensão para múltiplos cargos simultâneos.
