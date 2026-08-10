# Modelo de identidade: usuário, funcionário e terminal

> Documento de requisitos e análise do código Go, Python e Kotlin.
> Estado analisado em 9 de agosto de 2026.

## 1. Resumo executivo

No Nexora ERP, os três conceitos não são sinónimos:

| Conceito | O que representa | Faz login? | Tem dados de RH? | Pode operar o POS? |
|---|---|---:|---:|---:|
| **Usuário** | Uma conta de acesso à plataforma | Sim | Não necessariamente | Conforme permissões |
| **Funcionário** | Uma pessoa que trabalha para o tenant | Pode ter uma conta própria | Sim | Se tiver permissão |
| **Terminal** | Uma máquina/app de caixa registadora | Sim, por credencial técnica | Não | Sim, de forma limitada |

Em uma frase: **usuário é uma conta, funcionário é uma pessoa ligada ao RH e terminal é uma máquina; o terminal pode reutilizar a infraestrutura de autenticação dos usuários, mas nunca deve ser tratado como pessoa para assiduidade, contrato ou salário.**

O vínculo correto numa venda é:

```text
tenant
  ├── terminal físico ── conta técnica limitada
  └── funcionário ── conta pessoal
          │
          └── sessão/turno POS ── terminal utilizado
                    │
                    └── vendas
```

Assim, o sistema consegue responder separadamente:

- **em que máquina ocorreu a venda?** `terminal_id`;
- **quem realizou a venda?** `funcionario_id`, resolvido a partir do usuário operador;
- **qual conta autenticou a máquina?** `pos_terminals.user_id` (conta técnica).

## 2. Vocabulário oficial

### 2.1 Usuário

Usuário é qualquer conta presente em `auth.users` que possa autenticar-se no ERP ou num dos seus portais. É um conceito de **identidade e acesso**, não de Recursos Humanos.

Um usuário possui, entre outros dados:

- `id` da conta;
- nome de apresentação;
- email/login;
- hash da senha;
- estado da conta;
- memberships, papéis e permissões por tenant.

Um usuário pode representar um funcionário, aluno, encarregado, candidato ou uma identidade técnica. Portanto, a existência de `auth.users.id` não prova que existe um trabalhador no RH.

### 2.2 Funcionário

Funcionário é uma **pessoa que trabalha para um tenant**, registada em `rh.funcionarios`. É o identificador canónico para os processos de RH.

O funcionário possui dados como:

- `id` (`funcionario_id`);
- `tenant_id`;
- número de funcionário;
- nome, email e contacto;
- unidade, cargo e horário;
- contrato e data de admissão;
- salário base e histórico salarial;
- assiduidade, férias, ausências e recibos.

O campo opcional `rh.funcionarios.user_id` liga a pessoa à sua conta em `auth.users`. A relação esperada dentro do tenant é, no máximo, **um funcionário para uma conta de usuário**.

Consequências:

- um funcionário pode existir antes de receber acesso à plataforma (`user_id` nulo);
- uma conta pode existir sem ser funcionário;
- assiduidade, salário e contrato devem sempre referenciar `funcionario_id`, nunca apenas `user_id`.

### 2.3 Terminal

Terminal é uma **máquina ou instalação da aplicação POS**, registada em `pos.pos_terminals`. Não é uma pessoa e não deve ter registo em `rh.funcionarios`.

Possui:

- `id` (`terminal_id`);
- `tenant_id`;
- código e nome;
- armazém e caixa associados;
- estado ativo/inativo;
- `user_id` de uma conta técnica usada no login automático da máquina.

O código atual cria essa conta técnica em `auth.users` com `tipo='funcionario'` porque o domínio de autenticação ainda não admite um tipo técnico próprio. Isso é uma implementação de compatibilidade: **não transforma o terminal num funcionário de RH**.

Para evitar ambiguidades, a documentação e a interface devem chamá-la de **conta técnica do terminal**, e não de funcionário.

### 2.4 Dispositivo de assiduidade

Um leitor facial, NFC, QR ou relógio de ponto é um dispositivo de hardware, não um terminal POS e não um funcionário. Ele autentica chamadas de serviço por API Key/HMAC e informa qual funcionário marcou o ponto.

### 2.5 Escopo (ERP vs. portal escolar)

O contexto de autenticação (`AuthUser.Escopo`, valores `"erp"` ou `"escola"`) já bifurca o modelo de identidade hoje. No escopo `escola`, o módulo `gestao-escolar` implementa um modelo de professor **paralelo** ao deste documento: liga o professor diretamente a `user_id`, sem passar por `rh.funcionarios`, e faz reset de password do professor diretamente em `auth.users`. Ou seja, nem todo colaborador com acesso à plataforma tem necessariamente `funcionario_id` — professores no portal escolar são uma exceção intencional ao vocabulário da secção 2.2, e devem ser tratados como tal na documentação e na interface (não presumir `rh.funcionarios` para qualquer conta autenticada, mesmo quando representa uma pessoa que presta serviço ao tenant).

## 3. Modelo de relações

### 3.1 Relações existentes

```text
auth.users (conta pessoal) 1 ─── 0..1 rh.funcionarios
                                      via rh.funcionarios.user_id

auth.users (conta técnica) 1 ─── 1 pos.pos_terminals
                                      via pos.pos_terminals.user_id

auth.users (operador)      1 ─── N pos.pos_sessions
pos.pos_terminals          1 ─── N pos.pos_sessions
pos.pos_sessions           1 ─── N pos.pos_sales
```

`pos_sessions` é hoje a associação operacional entre uma pessoa e um terminal. Ao abrir o caixa, o backend grava simultaneamente:

- `terminal_id`: a máquina escolhida;
- `user_id`: a conta pessoal autenticada do operador;
- data/hora e valor de abertura.

Se esse `user_id` estiver ligado a `rh.funcionarios.user_id`, o ERP consegue chegar ao `funcionario_id` real.

### 3.2 Associação exigida entre terminal e funcionário

Para tenants que usam vendas, devem existir dois níveis distintos de associação:

1. **Associação operacional obrigatória por turno**: toda sessão POS deve ligar um terminal a um funcionário operador.
2. **Atribuição administrativa opcional**: o tenant pode limitar antecipadamente quais funcionários estão autorizados a usar cada terminal.

A associação por turno não deve ser gravada diretamente em `pos_terminals.funcionario_id`, porque um caixa pode ser usado por diferentes funcionários em turnos diferentes. Para a atribuição administrativa, recomenda-se uma tabela própria:

```sql
pos.terminal_funcionarios (
    tenant_id       BIGINT NOT NULL,
    terminal_id     BIGINT NOT NULL,
    funcionario_id  BIGINT NOT NULL,
    ativo            BOOLEAN NOT NULL DEFAULT TRUE,
    valido_de        TIMESTAMPTZ,
    valido_ate       TIMESTAMPTZ,
    atribuido_por    BIGINT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, terminal_id, funcionario_id)
)
```

Se o negócio garantir permanentemente “um terminal pertence a um único funcionário”, pode ser usado `pos_terminals.funcionario_id`. Contudo, esse modelo é menos flexível para troca de turnos, substituições e caixas partilhados.

## 4. Requisitos funcionais

### RF-ID-01 — Conta de usuário genérica

O sistema deve usar `auth.users` exclusivamente como raiz de autenticação e autorização. A conta não deve, por si só, criar salário, contrato ou assiduidade.

### RF-ID-02 — Funcionário como entidade de RH

Todo processamento de assiduidade, férias, contrato, benefícios, salário ou recibo deve referenciar `rh.funcionarios.id`.

### RF-ID-03 — Conta pessoal do funcionário

Um funcionário que acede à plataforma deve possuir uma conta pessoal própria, ligada por `rh.funcionarios.user_id`. Email e senha pertencem à conta; os dados laborais pertencem ao funcionário.

### RF-ID-04 — Funcionário sem login

O ERP deve permitir cadastrar funcionário sem conta de usuário. O acesso pode ser ativado posteriormente sem duplicar o funcionário.

### RF-ID-05 — Terminal como máquina

Cada terminal POS deve pertencer a exatamente um tenant e possuir código, nome, estado, armazém e caixa configuráveis. O terminal não deve ser inserido em `rh.funcionarios`.

### RF-ID-06 — Identidade técnica do terminal

O sistema deve criar ou associar uma credencial técnica ao terminal para ativação e comunicação automática. Essa identidade deve receber apenas as permissões técnicas estritamente necessárias ao POS.

Enquanto o esquema mantiver `auth.users.tipo='funcionario'` para terminais, a ausência de linha correspondente em `rh.funcionarios` deve ser garantida e testada. A evolução recomendada é um tipo explícito `terminal` ou, preferencialmente, uma tabela de credenciais de dispositivo separada.

### RF-ID-07 — Login humano separado do login da máquina

O login/ativação do terminal identifica **a máquina**. Antes de abrir o turno ou vender, deve existir autenticação da conta pessoal do operador, salvo quando o tenant estiver explicitamente configurado para operação não atribuída.

### RF-ID-08 — Associação do terminal ao funcionário

Ao abrir uma sessão de caixa, o sistema deve validar que:

1. o terminal está ativo e pertence ao mesmo tenant;
2. a conta autenticada está ligada a um funcionário ativo do mesmo tenant;
3. o funcionário possui permissão para operar o POS;
4. quando a lista de atribuições estiver habilitada, o funcionário está autorizado naquele terminal.

A sessão deve conservar `terminal_id`, `user_id` e `funcionario_id`. Guardar `funcionario_id` diretamente na sessão preserva o histórico mesmo se a conta for desligada ou reassociada no futuro.

### RF-ID-09 — Autoria da venda

Toda venda deve ser rastreável ao tenant, terminal, sessão e funcionário operador. A conta técnica do terminal nunca deve aparecer como vendedor humano em relatórios, comissões ou auditoria de RH.

### RF-ID-10 — Troca de operador

Para trocar de funcionário no mesmo terminal, a sessão atual deve ser fechada ou bloqueada e deve ser aberta uma nova sessão com o novo operador. Um operador não deve reutilizar silenciosamente a sessão de outro.

### RF-ID-11 — Processos de RH

Somente registros existentes em `rh.funcionarios` podem:

- marcar ponto;
- receber horários, férias ou ausências;
- possuir contratos e salário;
- entrar no processamento salarial;
- receber comissões de venda, quando aplicável.

### RF-ID-12 — Biometria

Templates faciais e digitais devem identificar a pessoa/funcionário. O identificador canónico de negócio deve ser `funcionario_id`; `user_id` pode ser mantido como referência auxiliar de autenticação e auditoria.

### RF-ID-13 — Isolamento por tenant

Toda resolução entre usuário, funcionário, terminal, sessão e venda deve incluir `tenant_id`. Um identificador válido noutro tenant deve ser tratado como inexistente.

### RF-ID-14a — Gestão administrativa do terminal restrita

Criar, ativar, editar, desativar ou rotacionar a credencial de um terminal são ações administrativas, distintas de **operar** o terminal num turno. Apenas uma conta com a permissão explícita `pos:gerir_terminais`, tipicamente atribuída a gestores/administradores do tenant, pode executá-las — nunca qualquer usuário autenticado nem o simples operador do POS.

**Estado: já implementado.** Confirmado no código atual, não é apenas uma proposta:

- `backend/internal/router/router.go` protege `GET/POST /api/pos/terminais` e `POST /api/pos/terminais/{id}/activar|desactivar` com `mw.RequirePermission(db, "pos", "gerir_terminais")`, num grupo de rotas separado do grupo protegido por `pos:operar_pos` (produtos, sessões, vendas, pagamentos);
- as migrations `20260727093000_permissoes_cargos_padrao_finas.up.sql` e `20260808180000_pos_supervisor_permissions.up.sql` introduzem `pos:gerir_terminais` e atribuem-na ao cargo padrão "Gerente de Loja";
- o cargo "Supervisor POS" recebe apenas `operar_pos`, `ver_vendas` e `supervisionar_pos` — **não** recebe `gerir_terminais`, confirmando a separação;
- o cargo sintético "Terminal POS" (criado para a conta técnica em `ensureCargoTerminalPOS`) só recebe `pos:operar_pos`, nunca `pos:gerir_terminais` — a própria máquina não pode gerir-se a si mesma nem a outros terminais.

Consequências:

- a permissão de gestão de terminal (`pos:gerir_terminais`) é distinta da permissão de operação (`pos:operar_pos`, ver RF-ID-08.3), seguindo a convenção do projeto `modulo:acao` (ex.: `pos:operar_pos`, `pos:gerir_terminais`, `pos:supervisionar_pos`, `crm:gerir_atividades`);
- um funcionário com permissão apenas para operar o POS não consegue criar, editar ou desativar terminais, nem ver/rotacionar o `activation_code` — verificado no backend via `mw.RequirePermission`, não apenas ocultado na UI;
- a validação considera sempre o `tenant_id` da conta (RF-ID-13): um gestor de um tenant não pode gerir terminais de outro.

Gap pendente (ver 7.1): a tabela `pos.terminal_funcionarios` (atribuição administrativa opcional de funcionários por terminal, secção 3.2) continua **apenas proposta** — confirmado por varredura completa do backend e das migrations, não existe ainda no código.

### RF-ID-14 — Desativação

- desativar um terminal deve impedir novos logins técnicos, refresh e sessões, sem apagar o histórico de vendas;
- desligar um funcionário deve impedir novos logins operacionais e sessões, sem apagar assiduidade, salários ou vendas anteriores;
- bloquear uma conta deve revogar as suas sessões, mas não eliminar o registo de funcionário.

## 5. Requisitos não funcionais e regras de segurança

### RNF-ID-01 — Privilégio mínimo

A conta técnica do terminal deve possuir apenas permissões de operação técnica necessárias. A conta do operador deve usar as permissões do cargo real do funcionário.

### RNF-ID-02 — Segredos diferentes

O código de ativação do terminal não é a senha do funcionário. Não deve ser mostrado novamente após a ativação e deve poder ser rotacionado.

### RNF-ID-03 — Auditoria dupla

Eventos POS devem registar, quando aplicável, dois atores distintos:

- `device_actor`: terminal/conta técnica;
- `human_actor`: usuário e funcionário operador.

### RNF-ID-04 — Integridade histórica

Vendas, sessões, pontos e folhas salariais não devem depender apenas de joins mutáveis. Os identificadores históricos relevantes devem permanecer gravados no evento de negócio.

### RNF-ID-05 — Unicidade correta

Código e email técnico do terminal devem ser únicos no âmbito correto. Como o código do terminal é único apenas por tenant, o email técnico não pode ser apenas `<codigo>@terminal.internal`; deve incluir o tenant ou usar outro identificador técnico não global.

### RNF-ID-06 — Terminologia de interface

As interfaces devem usar:

- **Conta/Usuário** para acesso;
- **Funcionário/Colaborador** para RH;
- **Terminal/Caixa** para máquina;
- **Operador** para o funcionário que está a usar o terminal num turno.

## 6. Fluxos de referência

### 6.1 Login de um funcionário no ERP/Android

1. A pessoa informa email e senha.
2. O ERP autentica `auth.users` e resolve a membership do tenant.
3. Para funcionalidades de RH, o backend resolve `rh.funcionarios` por `(tenant_id, user_id)`.
4. Assiduidade e salário passam a usar o `funcionario_id` resolvido.

### 6.2 Ativação de terminal POS

1. Um gestor cria o terminal no ERP.
2. O ERP gera/guarda a credencial técnica e liga-a a `pos.pos_terminals.user_id`.
3. A aplicação ativa a máquina com `codigo_terminal`, `activation_code` e tenant.
4. O token recebido identifica a máquina e não um trabalhador.

### 6.3 Início de turno e venda

1. O terminal já está ativado com a identidade técnica.
2. O funcionário autentica-se com a sua conta pessoal, PIN pessoal ou outro mecanismo aprovado.
3. O backend resolve o `funcionario_id` e valida a autorização naquele terminal.
4. A sessão é aberta com terminal, usuário e funcionário.
5. Cada venda herda a sessão e, por ela, os dois atores.

### 6.4 Marcação de assiduidade

1. A app ou dispositivo obtém a identidade apresentada.
2. O ERP resolve a identidade para `rh.funcionarios.id` no tenant correto.
3. O estado ativo, consentimento e método permitido são validados.
4. O evento é gravado contra `funcionario_id`.
5. O terminal POS, por não ter funcionário de RH, não pode marcar ponto.

## 7. Análise do código atual

### 7.1 Backend Go — ERP

O código já contém a maior parte da separação necessária:

- `auth.users` implementa a conta genérica e o login;
- `rh.funcionarios.user_id` liga opcionalmente funcionário e conta;
- o serviço `recursos-humanos/service/funcionario` declara `funcionario_id` como identificador canónico e resolve por ID, número, usuário ou email;
- `pos.pos_terminals.user_id` liga o terminal à sua conta técnica;
- `CriarTerminal` cria uma conta sintética, membership e cargo `Terminal POS` com a permissão `pos:operar_pos`;
- `PosLogin` separa `tipo=utilizador` de `tipo=terminal` e emite token de terminal com validade própria;
- `AbrirSessao` grava `terminal_id` e o `user.ID` do operador;
- vendas referenciam a sessão e o terminal.

Lacunas encontradas:

1. `AbrirSessao` valida o terminal, mas não exige que `user.ID` corresponda a um `rh.funcionarios` ativo.
2. `pos_sessions` guarda `user_id`, mas não `funcionario_id`; a autoria laboral depende de um join futuro e mutável.
3. Não existe lista explícita de funcionários autorizados por terminal.
4. O terminal sintético usa `auth.users.tipo='funcionario'`, embora não seja pessoa.
5. O email sintético usa somente o código (`<codigo>@terminal.internal`), mas o código é único por tenant e o email é globalmente único; dois tenants com o mesmo código podem colidir.
6. `ListarTerminais` não devolve a conta técnica nem os funcionários atribuídos, dificultando a administração da associação.
7. A regra documentada no POS diz “uma sessão aberta por terminal”, mas o handler atual impede apenas uma sessão aberta por usuário; é necessário também um índice/regra por terminal.
8. Existe uma segunda implementação ad hoc de resolução `user_id → funcionario_id` em `recursos-humanos/handlers/lgpd_consentimentos.go` (`resolverFuncionarioPorUserID`), que repete a mesma query já coberta pelo serviço canónico `recursos-humanos/service/funcionario.Service.PorUserID`. Deve ser consolidada para não divergir do ponto único de resolução.

Confirmado por implementação (não é mais proposta): `pos:gerir_terminais` já existe e já protege as rotas administrativas de terminal, distinta de `pos:operar_pos` — ver RF-ID-14a.

### 7.2 Backend Python — FaceClock

O Python distingue corretamente dispositivo e pessoa na autenticação de serviço:

- credenciais HMAC/API identificam a integração ou dispositivo;
- `DevicePublicKey.device_id` representa o aparelho;
- `FaceTemplate` e `FingerprintTemplate` armazenam `erp_user_id` e também possuem `erp_funcionario_id` opcional;
- o isolamento usa `tenant_id`.

Lacuna principal: a maioria dos fluxos biométricos ainda procura templates por `erp_user_id`, enquanto `erp_funcionario_id` permanece opcional. Isso mantém a identidade biométrica presa à conta de login. Para RH, o funcionário deve ser a identidade canónica; troca ou recriação da conta não deve exigir recriar a biometria da pessoa.

Recomendação: tornar `(tenant_id, erp_funcionario_id)` a chave funcional dos templates novos, mantendo `erp_user_id` apenas para auditoria/compatibilidade durante a migração.

### 7.3 Android/Kotlin — Nexora Assiduidade

O Android autentica uma pessoa no OAuth do ERP, guarda `userId` e consome endpoints distintos para conta e funcionário. Os endpoints de equipa e assiduidade usam corretamente `funcionarioId`.

Lacunas encontradas:

1. No login, `employeeCode` é preenchido com `me.email`, embora o código correto seja `rh.funcionarios.numero_funcionario`.
2. `ClockRegisterRequest` chama o identificador de `user_id`, enquanto o repositório tenta convertê-lo em `employeeCode`; os nomes misturam conta, funcionário e número funcional.
3. Eventos offline preservam esse campo ambíguo, aumentando o risco de sincronizar uma conta como se fosse funcionário.
4. Alguns DTOs biométricos usam `erp_user_id`, apesar de o processo representar o funcionário.

Recomendação: guardar separadamente em `SessionManager`:

- `userId`: conta autenticada;
- `funcionarioId`: entidade de RH resolvida;
- `numeroFuncionario`: código funcional;
- `deviceId`: instalação/aparelho.

Os pedidos novos devem usar nomes explícitos (`funcionario_id` ou `numero_funcionario`) e nunca chamar email de `employeeCode`.

### 7.4 Outros módulos Go (visão transversal)

Varredura por todos os 32 submódulos de `backend/internal/modules/`. A maioria (`assinaturas`, `compras`, `financeiro`, `gestao-clientes`, `gestao-produtos`, `gestao-stock`, `impostos`, `logistica`, `modulo-faturacao`, `monitoring`, `multi-moeda`, `sistema-configuracao`, `tarefas`) não referencia `funcionario_id`/`user_id`/`terminal_id` e é irrelevante para este modelo. `pessoas` usa apenas `pessoa_id` (entidade genérica), sem tocar `funcionario_id` diretamente. `centros-custo`, `crm`, `empresas` referenciam `user_id` apenas em papéis administrativos (gestor de centro de custo, responsável de lead, atribuição a empresa/filial) sem envolver o par funcionário/terminal.

Módulos com relevância directa para o modelo de identidade:

- **`auth`**: o contexto de autenticação (`middleware.AuthUser`) contém `ID, TenantID, SessionID, MembershipID, Tipo, Escopo, ReauthAt` — **não contém `FuncionarioID`**. Qualquer módulo que precise do funcionário tem sempre de o resolver explicitamente via `rh.funcionarios WHERE user_id=...`; nunca vem pronto na sessão. `RequirePermission`/`RequirePermissionAny` implementam o RBAC `modulo:acao`; superadmin faz bypass total.
- **`hardware`**: módulo dos dispositivos biométricos/QR de assiduidade (distinto de `pos.pos_terminals`). Autentica o próprio dispositivo por `api_key_hash`/`api_key_prefix` (não login `auth.users`) e resolve a pessoa via `funcionario_id`, `employee_no` ou `user_id`, reutilizando o serviço canónico `recursos-humanos/service/funcionario.Service`. Não há sobreposição de tabelas com `pos.pos_terminals`, mas há sobreposição conceptual de "dispositivo com identidade própria" com dois mecanismos de autenticação distintos (API key vs. conta técnica).
- **`recrutamento`**: é o ponto de origem do par `user_id`/`funcionario_id` para novos colaboradores — `contratar.go` cria `auth.memberships`, depois `rh.funcionarios` (ligando `user_id` e `pessoa_id`), e marca a candidatura com `rh_funcionario_id`.
- **`aprovacoes`** e **`assinatura-digital`**: seguem consistentemente o padrão "ator = `user_id`, sujeito do pedido = `funcionario_id`/`pessoa_id`". Em `assinatura-digital`, `signatarios.user_id` é opcional e, quando presente, tem de coincidir com o `user_id` da sessão que assina (testado); sem `user_id`, a assinatura só ocorre por convite externo. Regra testada: um gestor não pode assinar por terceiro nem usar `user_id` de outro tenant.
- **`gestao-escolar`**: ver secção 2.5 — modelo paralelo de professor via `user_id` directo, sem `rh.funcionarios`, sob `escopo='escola'`.
- **`seguranca`**, **`superadmin`**, **`auditoria`**, **`notifications`**: sem relação directa com o par funcionário/terminal; `auditoria.audit_logs` regista apenas `user_id`.

Achado transversal (nota técnica, não é inconsistência de modelo): o handler `EnviarXParaAssinatura` está duplicado, com pequenas variações, em seis módulos (`seguranca`, `aprovacoes`, `auditoria`, `contabilidade`, `tesouraria`, além da integração central em `assinatura-digital`). Em todos os casos o signatário resolve sempre para `user_id`, nunca `funcionario_id` directo — consistente com este modelo, mas candidato a extração para função partilhada.

## 8. Contratos de API recomendados

### 8.1 Criar terminal

```json
POST /api/pos/terminais
{
  "codigo": "CX-01",
  "nome": "Caixa principal",
  "warehouse_id": 10,
  "caixa_id": 4,
  "activation_code": "segredo-de-ativacao",
  "funcionarios_autorizados": [82, 91]
}
```

O servidor deve derivar internamente a identidade técnica; o cliente não escolhe `user_id` para o terminal.

### 8.2 Abrir sessão

```json
POST /api/pos/sessoes
Authorization: Bearer <token-pessoal-do-operador>
{
  "terminal_id": 12,
  "opening_amount": 5000.00
}
```

Resposta:

```json
{
  "id": 301,
  "terminal_id": 12,
  "user_id": 129,
  "funcionario_id": 82,
  "opened_at": "2026-08-09T08:00:00+02:00",
  "status": "aberta"
}
```

### 8.3 Consultar terminal

```json
{
  "id": 12,
  "codigo": "CX-01",
  "nome": "Caixa principal",
  "activo": true,
  "warehouse_id": 10,
  "caixa_id": 4,
  "conta_tecnica": {
    "user_id": 240,
    "estado": "ativo"
  },
  "funcionarios_autorizados": [
    {"funcionario_id": 82, "nome": "Ana", "ativo": true}
  ]
}
```

## 9. Critérios de aceitação

1. Criar um usuário sem funcionário não cria contrato, salário nem assiduidade.
2. Criar um funcionário sem login deixa `user_id` nulo e não impede a gestão de RH.
3. Ligar uma conta a um funcionário permite resolver univocamente `funcionario_id` no mesmo tenant.
4. Criar um terminal gera uma identidade técnica limitada, sem linha em `rh.funcionarios`.
5. Um terminal inativo não consegue autenticar, renovar token ou abrir sessão.
6. Um usuário sem funcionário ativo não consegue abrir uma sessão POS configurada para operador humano.
7. Um funcionário não autorizado para o terminal recebe `403` ao tentar abrir a sessão.
8. Uma sessão aberta conserva terminal, usuário e funcionário.
9. Dois funcionários podem usar o mesmo terminal em turnos diferentes e o histórico identifica corretamente cada um.
10. Duas sessões abertas simultaneamente para o mesmo terminal são rejeitadas.
11. A conta técnica do terminal nunca aparece na folha salarial, assiduidade ou comissão como funcionário.
12. Um tenant não consegue associar ao seu terminal um funcionário de outro tenant.
13. Dois tenants podem usar o mesmo código de terminal sem colisão de credencial técnica.
14. Trocar a conta pessoal ligada ao funcionário não perde os templates biométricos vinculados ao `funcionario_id`.
15. Um operador com apenas `pos:operar_pos` recebe `403` ao tentar criar, editar, ativar, desativar ou listar administrativamente terminais; a conta técnica do próprio terminal também recebe `403` nessas ações. *(já cumprido em produção — ver RF-ID-14a).*

## 10. Decisão arquitetural recomendada

Manter quatro identificadores explícitos e não intercambiáveis:

| Identificador | Entidade | Uso |
|---|---|---|
| `user_id` | `auth.users` | login, sessão, permissões e auditoria da conta |
| `funcionario_id` | `rh.funcionarios` | RH, assiduidade, salário e identidade do operador |
| `terminal_id` | `pos.pos_terminals` | máquina de venda, caixa e armazém |
| `device_id` | dispositivo/app | segurança do aparelho e origem técnica do evento |

A conta técnica do terminal pode continuar temporariamente em `auth.users`, mas deve ser identificada explicitamente como técnica e nunca convertida em `rh.funcionarios`. A associação de negócio entre terminal e funcionário deve acontecer na sessão POS e, quando necessário, numa tabela de autorizações por terminal.

## 11. Ficheiros usados na análise

### Go

- `backend/internal/modules/auth/handlers/auth.go`
- `backend/internal/modules/auth/handlers/pos_login.go`
- `backend/internal/modules/auth/handlers/pos_pin_login.go`
- `backend/internal/middleware/auth.go`
- `backend/internal/router/router.go`
- `backend/internal/modules/pos/handlers/pos.go`
- `backend/internal/modules/recursos-humanos/handlers/rh.go`
- `backend/internal/modules/recursos-humanos/handlers/lgpd_consentimentos.go`
- `backend/internal/modules/recursos-humanos/handlers/hierarquia.go`
- `backend/internal/modules/recursos-humanos/service/funcionario/funcionario.go`
- `backend/internal/modules/hardware/handlers/fingerprint.go`
- `backend/internal/modules/recrutamento/handlers/contratar.go`
- `backend/internal/modules/aprovacoes/handlers/requests.go`
- `backend/internal/modules/assinatura-digital/handlers/assinatura_digital.go`
- `backend/internal/modules/gestao-escolar/repositories/teacher.go`
- `backend/internal/modules/gestao-escolar/handlers/portal_professor.go`
- `backend/migrations/20260724080001_baseline_schema.up.sql`
- `backend/migrations/20260724090001_pos_terminals_user_id.up.sql`
- `backend/migrations/20260727093000_permissoes_cargos_padrao_finas.up.sql`
- `backend/migrations/20260808180000_pos_supervisor_permissions.up.sql`

### Python

- `assiduidade_system_backend/app/models.py`
- `assiduidade_system_backend/app/security/nexora_auth.py`
- `assiduidade_system_backend/app/erp_client.py`
- `assiduidade_system_backend/app/routers/biometric.py`
- `assiduidade_system_backend/app/routers/liveness.py`

### Kotlin

- `nexora_assiduidade/app/src/main/java/tech/e258tech/nexora_assiduidade/ui/auth/LoginActivity.kt`
- `nexora_assiduidade/app/src/main/java/tech/e258tech/nexora_assiduidade/data/network/ErpApiService.kt`
- `nexora_assiduidade/app/src/main/java/tech/e258tech/nexora_assiduidade/data/repository/AttendanceRepository.kt`
- `nexora_assiduidade/app/src/main/java/tech/e258tech/nexora_assiduidade/data/model/ClockRegisterRequest.kt`
- `nexora_assiduidade/app/src/main/java/tech/e258tech/nexora_assiduidade/utils/SessionManager.kt`

