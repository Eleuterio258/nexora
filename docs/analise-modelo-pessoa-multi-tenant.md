# Análise do Modelo de Dados Nexora ERP — Entidade Pessoa & Multi-Tenant

> Análise realizada sobre a base de dados `nexora_erp` em execução no container Docker `pg` (PostgreSQL), porta `5432`, com base nas migrations do backend Go e no código da aplicação.

---

## 1. Resumo Executivo

A base de dados actual **não é centrada numa entidade `Pessoa` única**. Em vez disso, existe uma **identidade global `auth.users`** (email único global) e várias **entidades de negócio isoladas** que duplicam dados pessoais:

- `rh.funcionarios` — dados do colaborador
- `gestao_escolar.school_students` — dados do aluno
- `gestao_escolar.school_guardians` — dados do encarregado
- `recrutamento.candidatos` / `candidaturas` — dados do candidato
- `gestao_escolar.school_teachers` — dados do professor

O multi-tenant é implementado por `saas.tenants`, com vínculo user-tenant-cargo em `auth.memberships`. Contudo, existem **limitações arquitecturais fortes** que impedem os cenários solicitados:

1. `auth.memberships.user_id` é **UNIQUE** → um user só pode pertencer a **um tenant**.
2. `auth.users.tipo` é um único valor (`superadmin`, `funcionario`, `aluno`, `encarregado`, `candidato`) → não suporta múltiplos papéis.
3. `rh.funcionarios.user_id`, `school_students.user_id`, `school_guardians.user_id`, `school_teachers.user_id` são campos opcionais 1:1 → impossibilitam um mesmo user/pessoa de ter papéis em tenants diferentes.
4. Não existe tabela central `pessoa` → dados pessoais estão espalhados e desnormalizados.

---

## 2. Estado Actual da Base de Dados (Docker `nexora_erp`)

### 2.1 Schemas e tabelas principais

```text
Schemas: 30 (auth, saas, empresas, rh, gestao_escolar, recrutamento, utilizadores, seguranca, ...)
Tabelas: 174+
```

Tabelas relevantes para a análise:

| Schema | Tabela | Função |
|--------|--------|--------|
| `auth` | `users` | Identidade global de autenticação |
| `auth` | `memberships` | Vínculo user ↔ tenant ↔ cargo |
| `auth` | `cargos` | Cargos por tenant |
| `auth` | `permissoes_cargo` | Permissões de cada cargo |
| `auth` | `permissoes_diretas` | Permissões directas a user |
| `auth` | `permissoes_tipo` | Permissões por tipo de user |
| `saas` | `tenants` | Entidades multi-tenant |
| `empresas` | `companies` | Empresas / organizações |
| `empresas` | `company_users` | Associação fraca user ↔ empresa |
| `rh` | `funcionarios` | Registo de colaborador |
| `gestao_escolar` | `school_students` | Registo de aluno |
| `gestao_escolar` | `school_guardians` | Registo de encarregado |
| `gestao_escolar` | `school_teachers` | Registo de professor |
| `recrutamento` | `candidatos` | Registo de candidato |
| `recrutamento` | `candidaturas` | Candidaturas a vagas |

### 2.2 Dados reais (container em execução)

```sql
-- Distribuição de users por tipo
 tipo        | count
-------------+-------
 aluno       |    31
 encarregado |    31
 funcionario |    39
 superadmin  |     1
 candidato   |     5

-- Users em múltiplos tenants: 0
-- Users com múltiplos papéis (mesmo nome/email): 0

-- Vínculos encontrados
 funcionarios com user_id:      33/34
 students com user_id:          31/31
 guardians com user_id:         31/31
 teachers com user_id:          32/32
 teachers com rh_employee_id:   32/32
 candidatos com user_id:         5/5

-- Tenants existentes
 id | codigo        | nome
  5 | enigma-school | Instituto Politecnico de Ciencias da Terra e Ambiente
  7 | e258tech      | e258tech, Lda
```

### 2.3 Constraints críticas que limitam a flexibilidade

| Tabela / Constraint | Tipo | Efeito |
|---------------------|------|--------|
| `auth.users.uq_users_email` | UNIQUE(email) | Uma conta de login por email globalmente |
| `auth.users.users_tipo_check` | CHECK em ('superadmin','funcionario','aluno','encarregado','candidato') | Apenas um tipo por conta |
| `auth.memberships.memberships_user_id_key` | UNIQUE(user_id) | Um user só pode estar num tenant |
| `rh.funcionarios.uq_funcionarios_user_id` | UNIQUE(user_id) | Um user só pode ser funcionário uma vez |
| `gestao_escolar.school_students.uq_school_students` | UNIQUE(tenant_id, codigo) | Código único de aluno por tenant |
| `gestao_escolar.school_guardians` | — | Um encarregado é filho de um aluno, não de uma pessoa |
| `recrutamento.candidatos.candidatos_tenant_id_email_key` | UNIQUE(tenant_id, email) | Candidato único por email+tenant |

---

## 3. Mapeamento dos Cenários Solicitados vs Modelo Actual

| Cenário solicitado | Suportado hoje? | Porquê |
|--------------------|-----------------|--------|
| Pessoa apenas candidato | Sim | `auth.users.tipo = 'candidato'` + `recrutamento.candidatos` |
| Pessoa apenas aluno | Sim | `auth.users.tipo = 'aluno'` + `school_students` |
| Pessoa apenas funcionário | Sim | `auth.users.tipo = 'funcionario'` + `rh.funcionarios` |
| Pessoa apenas encarregado | Sim | `auth.users.tipo = 'encarregado'` + `school_guardians` |
| Aluno + funcionário no mesmo tenant | **Não** | `users.tipo` é um único valor |
| Aluno + funcionário em tenants diferentes | **Não** | `memberships.user_id` é UNIQUE; `funcionarios.user_id` é UNIQUE |
| Candidato → aluno | Parcialmente | Requer criar novo user e apagar/relinkar candidato |
| Candidato → funcionário | Parcialmente | Requer recriar dados em `rh.funcionarios` e novo user |
| Aluno + funcionário + candidato ao mesmo tempo | **Não** | `users.tipo` é único |
| Múltiplos cargos/funções no mesmo tenant | Parcialmente | `auth.cargos` por tenant, mas `memberships.cargo_id` é 1:1 |
| Cargos/funções diferentes em tenants distintos | **Não** | `memberships.user_id` é UNIQUE |
| Activa num tenant e inactiva noutro | **Não** | Um user só pode estar num tenant |
| Pertencer a múltiplas organizações | **Não** | `memberships.user_id` é UNIQUE |
| Diferentes níveis de acesso por tenant | **Não** | `permissoes_diretas.user_id` não tem tenant |
| Administrador num tenant e user comum noutro | **Não** | `memberships.user_id` é UNIQUE |
| Responsável por vários alunos | Sim | Vários registos em `school_guardians` com mesmo email/user_id |
| Aluno com vários responsáveis | Sim | `school_guardians.student_id` permite N guardians |
| Funcionário também encarregado | **Não** | `users.tipo` é único |
| Várias contas de autenticação para mesmos dados pessoais | **Não** | Não existe entidade Pessoa central; `users.email` é único |

---

## 4. Problemas Arquitecturais Identificados

### 4.1 Ausência de entidade `Pessoa` central
Não existe uma tabela `pessoa`/`person` que una identidade civil. Cada módulo duplica:
- Nome, email, telefone, endereço
- Documento de identificação / NIF
- Género, data de nascimento

**Impacto:**
- Não é possível garantir que "João" funcionário seja o mesmo "João" encarregado/aluno.
- GDPR/consentimentos são difíceis de rastrear.
- Atualizações de dados pessoais precisam ser feitas em várias tabelas.

### 4.2 `rh.funcionarios` desligado de `auth.users` (conceitualmente)
Embora exista `funcionarios.user_id` (único), não há garantia de integridade com os dados pessoais de `users`. O self-service de RH, férias, avaliações, etc., estão acopladas ao registo RH, não à pessoa.

### 4.3 `auth.users.tipo` é mutuamente exclusivo
Um user só pode ser `funcionario`, `aluno`, `encarregado` ou `candidato`. Isto impede completamente múltiplos papéis.

### 4.4 `auth.memberships.user_id` UNIQUE impede multi-tenant real
O vínculo user-tenant é 1:1. Um colaborador externo não pode trabalhar em dois clientes; um encarregado não pode ver educandos em duas escolas/tenants com a mesma conta.

### 4.5 Duplo sistema de papéis escolares
- RBAC: `auth.cargos` + `auth.permissoes_cargo`
- Funcional: `school_teacher_roles`, `school_student_roles`

Risco de divergência entre permissões de acesso e funções operacionais.

### 4.6 Credenciais de portal legadas
`school_students` e `school_guardians` ainda mantêm `portal_email`, `portal_password_hash`, tokens e sessões próprias (`portal_sessions`, `guardian_portal_sessions`), apesar da posterior unificação para `auth.users`.

### 4.7 Candidaturas sem ligação a pessoa/user
Contratar um candidato exige recriação manual de dados em `rh.funcionarios` e `auth.users`.

### 4.8 `empresas.company_users` é uma associação órfã
`company_users.user_id` não tem FK para `auth.users` nem para `auth.memberships`, podendo conter IDs inválidos.

### 4.9 Filiação desnormalizada
A relação entre alunos e encarregados está em `school_guardians` (filho do aluno), não numa entidade de relações entre pessoas. Não há histórico, não suporta tutores/dependentes genéricos e dificulta que uma pessoa seja encarregada de vários alunos sem duplicação.

### 4.10 Hierarquia de funcionários insuficiente
A hierarquia actual é apenas via `unidades_organizacionais.parent_id` + `responsavel_id`. Não existe `funcionarios.gestor_id` para gestor directo, não há histórico de hierarquia e os pedidos de férias (`rh.ausencias`) não usam a hierarquia para determinar o aprovador.

---

## 5. Proposta de Modelação Centrada na Entidade Pessoa

### 5.1 Princípios

1. **Pessoa é a entidade central** — guarda apenas dados pessoais/identidade civil.
2. **User é uma conta de autenticação** — uma pessoa pode ter várias contas (email, SSO, etc.).
3. **Tenant isola dados organizacionais** — cada papel/vínculo pertence a um tenant.
4. **Papel (Role) é separado da Pessoa** — um user assume um papel dentro de um tenant.
5. **Cargos/Funções são históricos** — um user pode ter vários cargos no mesmo tenant ao longo do tempo.
6. **Estado é por vínculo** — ativo/inativo por tenant, não globalmente.

### 5.2 Modelo conceitual proposto

```text
┌─────────────────┐     1:N     ┌─────────────────┐
│    pessoas      │─────────────│  auth.users     │
│  (dados civis)  │             │ (autenticação)  │
└────────┬────────┘             └─────────────────┘
         │
         │ 1:N
         ▼
┌───────────────────────────────────────────────┐
│         auth.memberships (vínculos)            │
│  (user_id + tenant_id + papel + cargo + ativo) │
└───────────────────────────────────────────────┘
         │
         │ 1:1 ou N:1 por tenant
         ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ rh.funcionarios│  │ school_students│  │ school_guardians│  │ candidatos    │
│ (registo RH)   │  │ (registo esc.) │  │ (registo esc.)  │  │ (registo rec.)│
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
```

### 5.3 Novas/alteradas tabelas (SQL exemplo)

```sql
-- ============================================================
-- 1. Entidade PESSOA central
-- ============================================================
CREATE TABLE pessoas (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo          VARCHAR(50) UNIQUE,           -- código interno opcional
    primeiro_nome   VARCHAR(100) NOT NULL,
    ultimo_nome     VARCHAR(100),
    nome_completo   VARCHAR(200) GENERATED ALWAYS AS (
        TRIM(COALESCE(primeiro_nome,'') || ' ' || COALESCE(ultimo_nome,''))
    ) STORED,
    data_nascimento DATE,
    genero          VARCHAR(20) CHECK (genero IN ('M','F','outro','nao_informado')),
    nuit            VARCHAR(30),                  -- NIF / NUIT
    tipo_documento  VARCHAR(30),
    numero_documento VARCHAR(60),
    nacionalidade   VARCHAR(60),
    estado_civil    VARCHAR(30),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_pessoas_documento UNIQUE (tipo_documento, numero_documento)
);

-- Contactos da pessoa (1:N — email, telefone, endereço)
CREATE TABLE pessoa_contatos (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pessoa_id       BIGINT NOT NULL REFERENCES pessoas(id) ON DELETE CASCADE,
    tipo            VARCHAR(30) NOT NULL CHECK (tipo IN ('email','telefone','whatsapp')),
    valor           VARCHAR(255) NOT NULL,
    principal       BOOLEAN NOT NULL DEFAULT FALSE,
    verificado      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE pessoa_enderecos (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pessoa_id       BIGINT NOT NULL REFERENCES pessoas(id) ON DELETE CASCADE,
    tipo            VARCHAR(30) NOT NULL DEFAULT 'residencia',
    provincia       VARCHAR(60),
    cidade          VARCHAR(60),
    bairro          VARCHAR(100),
    logradouro      TEXT,
    codigo_postal   VARCHAR(20),
    principal       BOOLEAN NOT NULL DEFAULT FALSE
);

-- ============================================================
-- 2. auth.users vira conta de autenticação ligada a pessoa
-- ============================================================
ALTER TABLE auth.users
    ADD COLUMN pessoa_id BIGINT REFERENCES pessoas(id) ON DELETE SET NULL,
    ADD COLUMN tipo_login VARCHAR(30) NOT NULL DEFAULT 'email' CHECK (tipo_login IN ('email','sso','ldap','magic_link')),
    -- remover ou deprecar a coluna `tipo` (papel passa para memberships)
    DROP CONSTRAINT IF EXISTS users_tipo_check;

-- Nota: a coluna `email` pode continuar na conta ou ser movida para pessoa_contatos.
-- Recomendação: manter email de login em users (obrigatório, único global) e replicar
-- o email principal da pessoa via trigger ou aplicação.

-- ============================================================
-- 3. auth.memberships: um user pode ter múltiplos vínculos
-- ============================================================
-- Remover a constraint UNIQUE(user_id)
ALTER TABLE auth.memberships
    DROP CONSTRAINT IF EXISTS memberships_user_id_key;

-- Adicionar chave composta única por (user_id, tenant_id, papel)
ALTER TABLE auth.memberships
    ADD CONSTRAINT uq_memberships_user_tenant_papel UNIQUE (user_id, tenant_id, escopo);

-- A coluna `escopo` passa a representar o papel/portal: erp, escola, portal_aluno, etc.
-- Novas colunas opcionais:
ALTER TABLE auth.memberships
    ADD COLUMN papel VARCHAR(50),       -- ex: 'funcionario', 'aluno', 'encarregado', 'candidato'
    ADD COLUMN data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    ADD COLUMN data_fim    DATE,
    ADD COLUMN ativo       BOOLEAN NOT NULL DEFAULT TRUE;

-- ============================================================
-- 4. Papéis de negócio passam a referenciar pessoa_id (além de user_id)
-- ============================================================
ALTER TABLE rh.funcionarios
    ADD COLUMN pessoa_id BIGINT REFERENCES pessoas(id) ON DELETE SET NULL;

ALTER TABLE gestao_escolar.school_students
    ADD COLUMN pessoa_id BIGINT REFERENCES pessoas(id) ON DELETE SET NULL;

ALTER TABLE gestao_escolar.school_guardians
    ADD COLUMN pessoa_id BIGINT REFERENCES pessoas(id) ON DELETE SET NULL;

ALTER TABLE recrutamento.candidatos
    ADD COLUMN pessoa_id BIGINT REFERENCES pessoas(id) ON DELETE SET NULL;

ALTER TABLE gestao_escolar.school_teachers
    ADD COLUMN pessoa_id BIGINT REFERENCES pessoas(id) ON DELETE SET NULL;

-- Garantir que uma pessoa pode ser aluno/funcionário/etc em múltiplos tenants
-- (remover UNIQUE(user_id) onde existir e, se necessário, adicionar
-- UNIQUE(tenant_id, pessoa_id) ou UNIQUE(tenant_id, numero_funcionario))
ALTER TABLE rh.funcionarios
    DROP CONSTRAINT IF EXISTS uq_funcionarios_user_id;

-- ============================================================
-- 5. Permissões directas por tenant
-- ============================================================
ALTER TABLE auth.permissoes_diretas
    ADD COLUMN tenant_id BIGINT REFERENCES saas.tenants(id) ON DELETE CASCADE;

-- Nova chave única considerando tenant
ALTER TABLE auth.permissoes_diretas
    DROP CONSTRAINT IF EXISTS permissoes_diretas_user_id_modulo_acao_key,
    ADD CONSTRAINT uq_permissoes_diretas UNIQUE (user_id, tenant_id, modulo, acao);
```

### 5.4 Exemplos de cenários com o novo modelo

```sql
-- Uma pessoa é funcionária no tenant 5 e aluna no tenant 7
INSERT INTO pessoas (primeiro_nome, ultimo_nome, nuit) VALUES ('Ana', 'Silva', '123456789');
-- pessoa_id = 100

INSERT INTO auth.users (pessoa_id, email, password_hash, estado) VALUES (100, 'ana.silva@email.com', '...', 'ativo');
-- user_id = 200

INSERT INTO auth.memberships (user_id, tenant_id, escopo, papel, cargo_id, ativo)
VALUES (200, 5, 'erp', 'funcionario', 2, true);

INSERT INTO auth.memberships (user_id, tenant_id, escopo, papel, ativo)
VALUES (200, 7, 'escola', 'aluno', true);

INSERT INTO rh.funcionarios (tenant_id, pessoa_id, user_id, numero_funcionario, nome_completo, data_admissao)
VALUES (5, 100, 200, 'F0001', 'Ana Silva', CURRENT_DATE);

INSERT INTO gestao_escolar.school_students (tenant_id, pessoa_id, user_id, codigo, nome)
VALUES (7, 100, 200, 'A0001', 'Ana Silva');
```

---

## 6. Plano de Migração Sugerido

### Fase 1 — Preparação (sem downtime crítico)
1. Criar tabela `pessoas` e tabelas de contacto/endereço.
2. Adicionar `pessoa_id` em `auth.users`, `rh.funcionarios`, `school_students`, `school_guardians`, `school_teachers`, `recrutamento.candidatos`.
3. Preencher `pessoas` a partir de `auth.users` e das entidades de negócio existentes.
4. Criar relacionamentos (FKs) e índices.

### Fase 2 — Normalização dos vínculos
1. Remover `UNIQUE(user_id)` de `auth.memberships`.
2. Adicionar `papel` e datas de vigência em `auth.memberships`.
3. Ajustar `auth.permissoes_diretas` para suportar `tenant_id`.
4. Criar view `v_pessoa_papeis` para listar todos os papéis de uma pessoa.

### Fase 3 — Refactor do backend Go
1. Alterar `auth.models.UserAccess` para carregar **todos os vínculos** do user.
2. Alterar login para suportar escolha de tenant/papel quando houver múltiplos.
3. Alterar middleware para passar `MembershipID` além de `UserID`/`TenantID`.
4. Refactor handlers que assumem `users.tipo` único.
5. Criar serviço `PessoaService` para unificação/deduplicação.

### Fase 4 — Limpeza
1. Remover colunas `portal_email`, `portal_password_hash` de `school_students`/`school_guardians` (autenticação passa a usar `auth.users`).
2. Remover tabelas de sessões de portal separadas ou migrá-las para `auth.sessions`.
3. Deprecar `users.tipo` (ou remover após refactor completo).

---

## 7. Impacto no Código Go Existente

### 7.1 `auth/models/rbac.go`
- `LoadUserAccess` faz `LEFT JOIN auth.memberships ... AND m.ativo = true` e assume um único vínculo.
- Precisa de retornar `[]UserAccess` ou `UserAccess` com lista de memberships.
- `Can()` deve considerar o tenant/papel activo da request.

### 7.2 `auth/handlers/auth.go`
- Login faz `switch tipo` para redireccionar para portal aluno/encarregado/candidato.
- Com múltiplos papéis, o login deve retornar lista de vínculos e deixar o cliente escolher.
- Tokens JWT precisam de incluir `membership_id` ou `papel` além de `tid`/`tipo`.

### 7.3 `auth/handlers/utilizadores.go`
- `CriarUtilizador` cria user + membership única.
- Precisa de suportar criação de pessoa e múltiplos vínculos.
- `AlterarTipo` deve ser substituído por gestão de memberships/papéis.

### 7.4 Módulos RH e Gestão Escolar
- Criação de funcionário/aluno/encarregado deve primeiro criar/atualizar `pessoas`.
- Relacionamentos passam a usar `pessoa_id` como identidade estável.

---

## 8. Considerações de Segurança

1. **Isolamento de tenant:** Todas as queries devem continuar a filtrar por `tenant_id`.
2. **Consentimento GDPR:** A tabela `pessoas` deve ter campos de `consentimento_dados` e `data_consentimento`.
3. **Histórico de alterações:** Auditar alterações a `pessoas` e `pessoa_contatos`.
4. **Autenticação:** Manter `password_hash` apenas em `auth.users`; nunca duplicar.
5. **MFA:** `seguranca.security_mfa_enrollments` já tem `tenant_id` — continua válido por vínculo.

---

## 9. Filiação e Hierarquia de Funcionários

Além dos problemas de papéis multi-tenant, identificaram-se mais dois gaps importantes: **filiação** (relações familiares) e **hierarquia funcional** para aprovações.

### 9.1 Estado actual da filiação

#### Alunos / Encarregados
A filiação está modelada apenas em `gestao_escolar.school_guardians`:

```sql
-- Colunas existentes
parentesco      VARCHAR(50)    -- Pai, Mae, Tio, Tia, Avo, Tutor, Irmao
principal       BOOLEAN        -- encarregado principal
autorizado_recolher BOOLEAN
```

**Problemas:**
- O encarregado é **filho do aluno**, não de uma pessoa central. Um mesmo encarregado de vários alunos fica com vários registos duplicados.
- Não existe entidade inversa: "quais são os dependentes/tutelados desta pessoa?"
- Não suporta histórico de guarda/tutela.
- Não liga filiação à entidade `Pessoa` (quando existir).

#### Funcionários
Existe apenas `rh.contactos_emergencia`:

```sql
funcionario_id  BIGINT
nome            VARCHAR(150)
parentesco      VARCHAR(50)    -- ex: conjuge, pai, filho
telefone        VARCHAR(30)
email           VARCHAR(150)
```

**Problemas:**
- São apenas contactos de emergência, não são pessoas do sistema.
- Não há relação com `pessoas`, `auth.users` ou `funcionarios`.
- Não permite modelar dependentes para benefícios, seguros, etc.

### 9.2 Estado actual da hierarquia de funcionários

Existe uma hierarquia baseada em **unidades organizacionais**:

```sql
rh.unidades_organizacionais
  - id
  - parent_id              -- unidade pai (hierarquia)
  - responsavel_id         -- funcionário responsável pela unidade
```

E no código (`backend/internal/modules/recursos-humanos/handlers/hierarquia.go`) existe a função `IsResponsavelHierarquico` que sobe pela árvore de unidades para verificar se um funcionário é responsável hierárquico de outro.

**Problemas:**
1. A hierarquia é **indirecta** (via unidade), não permite definir um gestor directo específico.
2. `rh.ausencias` tem `aprovado_por`, mas **não usa a hierarquia** para determinar quem deve aprovar.
3. Os fluxos de aprovação (`saas.approval_flows`) são **genéricos e desligados da hierarquia** — os `niveis` são um JSONB com `cargo_id`, não com referência a gestor.
4. Um funcionário pode mudar de unidade, mas não há histórico de hierarquia.

### 9.3 Proposta de modelação

> **Decisão de arquitectura:** mantém-se a hierarquia por unidades organizacionais (já existente) e adiciona-se **gestor directo/funcional/substituto** por funcionário. Cada tenant configura os seus próprios approval flows, podendo escolher entre aprovação por gestor hierárquico, cargo específico ou utilizador.

#### a) Tabela de relações entre pessoas (filiação/dependência)

```sql
CREATE TABLE pessoa_relacoes (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id       BIGINT REFERENCES saas.tenants(id) ON DELETE CASCADE,
    pessoa_id       BIGINT NOT NULL REFERENCES pessoas(id) ON DELETE CASCADE,
    pessoa_relacionada_id BIGINT NOT NULL REFERENCES pessoas(id) ON DELETE CASCADE,
    tipo_relacao    VARCHAR(50) NOT NULL CHECK (tipo_relacao IN (
        'pai', 'mae', 'tutor', 'encarregado', 'filho', 'filha',
        'conjuge', 'irmao', 'irma', 'avo', 'avo_materno', 'avo_paterno',
        'tio', 'tia', 'outro'
    )),
    responsavel_legal BOOLEAN NOT NULL DEFAULT FALSE,
    principal       BOOLEAN NOT NULL DEFAULT FALSE,
    data_inicio     DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim        DATE,
    observacoes     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_pessoa_relacao UNIQUE (tenant_id, pessoa_id, pessoa_relacionada_id, tipo_relacao, data_inicio)
);

CREATE INDEX idx_pessoa_relacoes_pessoa ON pessoa_relacoes(tenant_id, pessoa_id);
CREATE INDEX idx_pessoa_relacoes_relacionada ON pessoa_relacoes(tenant_id, pessoa_relacionada_id);
```

**Benefícios:**
- Uma pessoa pode ser encarregado/dependente de várias outras.
- Aluno pode ter vários encarregados; encarregado pode ter vários alunos/dependentes.
- Funcionário pode ter dependentes para benefícios/RH.
- Histórico de relações (com `data_inicio`/`data_fim`).

#### b) Hierarquia: unidades organizacionais + gestores directos

Mantém-se a hierarquia por unidades organizacionais existente:

```sql
rh.unidades_organizacionais
  - id
  - parent_id              -- unidade pai
  - responsavel_id         -- funcionário responsável pela unidade
```

Adiciona-se à tabela `rh.funcionarios` a possibilidade de definir gestores directos, funcionais e substitutos:

```sql
ALTER TABLE rh.funcionarios
    ADD COLUMN gestor_id BIGINT REFERENCES rh.funcionarios(id) ON DELETE SET NULL,
    ADD COLUMN gestor_funcional_id BIGINT REFERENCES rh.funcionarios(id) ON DELETE SET NULL,
    ADD COLUMN gestor_substituto_id BIGINT REFERENCES rh.funcionarios(id) ON DELETE SET NULL;

-- Histórico de hierarquia/gestão
CREATE TABLE rh.funcionario_hierarquia_historico (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id       BIGINT NOT NULL REFERENCES saas.tenants(id) ON DELETE CASCADE,
    funcionario_id  BIGINT NOT NULL REFERENCES rh.funcionarios(id) ON DELETE CASCADE,
    gestor_id       BIGINT REFERENCES rh.funcionarios(id) ON DELETE SET NULL,
    tipo_vinculo    VARCHAR(30) NOT NULL DEFAULT 'gestor_direto'
        CHECK (tipo_vinculo IN ('gestor_direto','gestor_funcional','gestor_substituto','responsavel_unidade')),
    data_inicio     DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim        DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Regras de resolução de aprovador (prioridade):**

1. Se existir `gestor_id` → usa gestor directo.
2. Se não existir `gestor_id` mas existir `gestor_funcional_id` → usa gestor funcional.
3. Se não existir nenhum dos anteriores → sobe pela hierarquia de unidades organizacionais (`parent_id` + `responsavel_id`).
4. Se `gestor_substituto_id` estiver definido e o gestor principal estiver ausente/inactivo → usa substituto.

#### c) Approval flows configuráveis por tenant

A tabela `saas.approval_flows` já existe e é por tenant. Os `niveis` (JSONB) devem ser estendidos para suportar os vários tipos de aprovador:

```json
{
  "niveis": [
    { "tipo": "gestor_direto" },
    { "tipo": "gestor_funcional" },
    { "tipo": "responsavel_unidade", "niveis_subir": 2 },
    { "tipo": "cargo", "cargo_id": 5 },
    { "tipo": "pessoa", "user_id": 42 }
  ]
}
```

Tipos de aprovador suportados:

| Tipo | Significado |
|------|-------------|
| `gestor_direto` | Gestor directo do funcionário (`funcionarios.gestor_id`) |
| `gestor_funcional` | Gestor funcional do funcionário (`funcionarios.gestor_funcional_id`) |
| `gestor_substituto` | Substituto do gestor (`funcionarios.gestor_substituto_id`) |
| `responsavel_unidade` | Responsável pela unidade organizacional (sobe N níveis) |
| `cargo` | Qualquer user com um cargo específico no tenant |
| `pessoa` | Utilizador específico |

Função para resolver o aprovador:

```sql
CREATE OR REPLACE FUNCTION rh.resolve_aprovador(
    p_funcionario_id BIGINT,
    p_tenant_id BIGINT,
    p_tipo_aprovador VARCHAR(30),
    p_parametro JSONB DEFAULT '{}'::jsonb
) RETURNS BIGINT AS $$
DECLARE
    v_aprovador_id BIGINT;
    v_gestor_id BIGINT;
    v_niveis_subir INT;
BEGIN
    CASE p_tipo_aprovador
        WHEN 'gestor_direto' THEN
            SELECT gestor_id INTO v_aprovador_id
            FROM rh.funcionarios
            WHERE id = p_funcionario_id AND tenant_id = p_tenant_id;

        WHEN 'gestor_funcional' THEN
            SELECT gestor_funcional_id INTO v_aprovador_id
            FROM rh.funcionarios
            WHERE id = p_funcionario_id AND tenant_id = p_tenant_id;

        WHEN 'gestor_substituto' THEN
            SELECT gestor_substituto_id INTO v_aprovador_id
            FROM rh.funcionarios
            WHERE id = p_funcionario_id AND tenant_id = p_tenant_id;

        WHEN 'responsavel_unidade' THEN
            v_niveis_subir := COALESCE((p_parametro->>'niveis_subir')::INT, 1);
            
            WITH RECURSIVE unidade_hierarquia AS (
                SELECT u.id, u.parent_id, u.responsavel_id, 1 AS nivel
                FROM rh.funcionarios f
                JOIN rh.unidades_organizacionais u ON u.id = f.unit_id
                WHERE f.id = p_funcionario_id AND f.tenant_id = p_tenant_id
                UNION ALL
                SELECT p.id, p.parent_id, p.responsavel_id, uh.nivel + 1
                FROM rh.unidades_organizacionais p
                JOIN unidade_hierarquia uh ON p.id = uh.parent_id
                WHERE uh.nivel < v_niveis_subir
            )
            SELECT responsavel_id INTO v_aprovador_id
            FROM unidade_hierarquia
            WHERE nivel = v_niveis_subir;

        WHEN 'cargo' THEN
            SELECT m.user_id INTO v_aprovador_id
            FROM auth.memberships m
            WHERE m.tenant_id = p_tenant_id
              AND m.cargo_id = (p_parametro->>'cargo_id')::BIGINT
              AND m.ativo = TRUE
            LIMIT 1;

        WHEN 'pessoa' THEN
            v_aprovador_id := (p_parametro->>'user_id')::BIGINT;

        ELSE
            v_aprovador_id := NULL;
    END CASE;

    RETURN v_aprovador_id;
END;
$$ LANGUAGE plpgsql;
```

#### d) Integração com pedidos de férias/ausências

```sql
-- Quando um pedido de férias é submetido:
-- 1. Verifica se existe approval flow ativo para "rh.ferias" no tenant
-- 2. Para cada nível do flow, resolve o aprovador com rh.resolve_aprovador
-- 3. Cria approval_request com nivel_atual = 1
-- 4. Notifica o aprovador
```

Exemplo de uso:

```sql
SELECT rh.resolve_aprovador(
    p_funcionario_id := 123,
    p_tenant_id := 5,
    p_tipo_aprovador := 'responsavel_unidade',
    p_parametro := '{"niveis_subir": 1}'::jsonb
);
```

### 9.4 Cenários resolvidos

| Cenário | Resolução |
|---------|-----------|
| Aluno com pai e mãe | `pessoa_relacoes` com `tipo_relacao = 'pai'` e `'mae'` |
| Encarregado de vários alunos | Mesma `pessoa_id` em várias `pessoa_relacoes` |
| Funcionário com dependentes | `pessoa_relacoes` tipo `'filho'`/`'filha'`/`'conjuge'` |
| Aprovação de férias pelo gestor directo | Approval flow `"gestor_direto"` |
| Aprovação por responsável de unidade | Approval flow `"responsavel_unidade"` |
| Aprovação por gestor funcional | Approval flow `"gestor_funcional"` |
| Aprovação por cargo (ex: Director RH) | Approval flow `"cargo"` com `cargo_id` |
| Histórico de mudança de gestor | `rh.funcionario_hierarquia_historico` |
| Substituto durante ausência do gestor | Approval flow `"gestor_substituto"` |

---

## 10. Conclusão e Próximos Passos

A base de dados `nexora_erp` actual implementa multi-tenant através de `saas.tenants` e `auth.memberships`, mas com limitações fortes que impedem uma pessoa de assumir múltiplos papéis e de pertencer a múltiplos tenants. Os dados pessoais estão duplicados pelas entidades de negócio, não existe uma entidade `Pessoa` central, a filiação está desnormalizada e a hierarquia de aprovações é insuficiente.

**Recomendação principal:** introduzir uma tabela `pessoas` central, transformar `auth.users` numa conta de autenticação 1:N por pessoa, e alterar `auth.memberships` para permitir múltiplos vínculos user-tenant-papel. Este refactor é substancial e exige alterações no schema, nas migrations, no backend Go e nos portais, mas é o caminho necessário para suportar os cenários de negócio solicitados.

**Próximos passos sugeridos:**
1. Validar a proposta com stakeholders de RH, Escola e Recrutamento.
2. Criar migration de transição (Fase 1) para introduzir `pessoas` sem quebrar o sistema actual.
3. Criar `pessoa_relacoes` e migrar `school_guardians` + `contactos_emergencia` para o novo modelo.
4. Adicionar `funcionarios.gestor_id` e `funcionario_hierarquia_historico`.
5. Integrar approval flows com gestor hierárquico para férias/ausências.
6. Implementar `PessoaService` no backend e actualizar handlers de criação de users.
7. Planejar testes de integração para todos os cenários de múltiplos papéis, filiação e aprovações.
