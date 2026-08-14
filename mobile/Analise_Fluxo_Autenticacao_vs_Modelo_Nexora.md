# Análise do Fluxo de Autenticação PayCore Mobile vs Modelo Nexora

> **Escopo:** todos os arquivos `.kt` de `mobile/app/src/main/java/tech/e258tech/paycore/`  
> **Data:** 2026-08-10

---

## 1. Veredito Executivo

**O fluxo atual do PayCore mobile é logicamente confuso e tecnicamente inconsistente com o modelo Nexora.**

O aplicativo trata o login de terminal como uma **etapa diária do operador** e usa o **token da máquina** para vender, quando deveria usar o **token pessoal do funcionário** e tratar o terminal como **configuração do dispositivo**.

---

## 2. O que o Modelo Nexora Estabelece

| Conceito | Representa | Faz login? | Pode operar POS? |
|----------|------------|-----------:|-----------------:|
| **Usuário** | Conta de acesso à plataforma | Sim | Conforme permissões |
| **Funcionário** | Pessoa que trabalha para o tenant | Pode ter conta | Se tiver permissão |
| **Terminal** | Máquina/app de caixa registradora | Sim, por credencial técnica | Sim, de forma limitada |

**Regra de ouro (RF-ID-07):**

> O login/ativação do terminal identifica **a máquina**. Antes de abrir o turno ou vender, deve existir autenticação da conta pessoal do operador.

**Fluxo correto (secção 6.3):**

```text
1. Terminal já está ativado (identidade técnica)
2. Funcionário autentica-se com conta pessoal / PIN
3. Backend resolve funcionario_id e valida autorização no terminal
4. Sessão é aberta com terminal_id, user_id e funcionario_id
5. Cada venda herda a sessão e, por ela, os dois atores
```

**Contrato recomendado para abrir sessão (8.2):**

```json
POST /api/pos/sessoes
Authorization: Bearer <token-pessoal-do-operador>
{
  "terminal_id": 12,
  "opening_amount": 5000.00
}
```

---

## 3. Fluxo Atual do Mobile PayCore

```text
SplashActivity
    ↓
LoginActivity / PinLoginActivity   ← token PESSOAL do funcionário
    ↓
SelecaoModoActivity
    ↓
LoginTerminalActivity              ← serial + activation code
    ↓
DashboardActivity                  ← agora usa token do TERMINAL
    ↓
Abrir caixa / Vender / Fechar caixa  ← tudo com token do TERMINAL
```

---

## 4. Problemas Lógicos Identificados

### 4.1. Token errado para operar o POS 🚨

**Documento exige:** vender e abrir sessão com **token pessoal do operador**.  
**Mobile faz:** após `LoginTerminalActivity`, o token ativo passa a ser o do terminal (`ApiClient.saveTerminalToken`).

Em `PosStore.processarPagamento()` e `AberturaCaixaActivity`, todas as chamadas usam `ApiClient.service` com o token do terminal. Isso viola RF-ID-07 e o contrato 8.2.

**Impacto:** A venda é registrada como originada pela máquina, sem identificar claramente o operador humano. Relatórios de comissão e auditoria de RH ficam comprometidos.

---

### 4.2. Login de terminal como etapa diária 🚨

**Documento exige:** ativação do terminal é **configuração inicial do dispositivo**.  
**Mobile faz:** toda vez que o operador quer vender, ele precisa digitar serial + activation code.

Isso é como pedir a chave de instalação do Windows toda vez que liga o computador. O `activation_code` é um segredo de configuração, não credencial de uso diário (RNF-ID-02).

---

### 4.3. Funcionario_id não é propagado para a sessão 🚨

**Documento exige:** ao abrir sessão, o backend deve gravar `funcionario_id`.  
**Mobile faz:** abre sessão com token de terminal. O backend só recebe `terminal_id` do token.

**Impacto:** A sessão não associa operador humano. RF-ID-08 e RF-ID-09 não são cumpridos.

---

### 4.4. Dupla autenticação cansativa e redundante

O funcionário loga duas vezes:

1. Email/senha ou PIN (conta pessoal)
2. Serial + activation code (máquina)

Isso não reflete a realidade de um POS, onde o terminal é fixo e cada turno troca apenas o operador.

---

### 4.5. SelecaoModoActivity força escolha artificial

Depois do login pessoal, o funcionário escolhe "Terminal de Venda". Mas se o dispositivo **é** um terminal, essa escolha deveria ser automática ou inexistente.

A escolha só faz sentido se um mesmo app/dispositivo pudesse alternar entre "modo POS" e "modo admin". Mas mesmo assim, o admin deveria ser acessível de dentro do dashboard, não no login.

---

### 4.6. Troca de turno é mal suportada

**Documento exige (RF-ID-10):** trocar de operador no mesmo terminal deve fechar/bloquear a sessão atual e abrir nova com novo operador.  
**Mobile faz:** para trocar de operador, precisa fazer logout de funcionário, mas o terminal também desloga? Não está claro. O `PosStore.logoutFuncionario()` não limpa o terminal.

Isso cria ambiguidade: o próximo funcionário reusa o terminal ativado ou precisa ativar de novo?

---

## 5. Onde o Mobile Está Correto

| Aspecto | Avaliação |
|---------|-----------|
| `SplashActivity` restaurar `tenantId` do terminal | ✅ Correto |
| `PinLoginActivity` autenticar operador por PIN | ✅ Correto |
| `LoginTerminalActivity` como ativação técnica | ✅ Correto (mas usado no lugar errado) |
| `PosStore.operadorAtual` separado de terminal | ✅ Correto |
| Proteger `LoginTerminalActivity` para exigir funcionário logado | ⚠️ Parcialmente correto, mas não resolve o token |

---

## 6. Fluxo Recomendado (Alinhado com o Modelo Nexora)

### 6.1. Configuração inicial do dispositivo (uma vez)

```text
SplashActivity
    ↓
Nenhum terminal salvo?
    ↓
LoginTerminalActivity  (serial + activation code)
    ↓
Salva terminalId, tenantId, terminalToken? em prefs
    ↓
Vai para LoginActivity
```

> Nota: o `terminalToken` pode ser guardado para chamadas técnicas raras, mas **não** para vender.

### 6.2. Uso diário

```text
SplashActivity
    ↓
Terminal já salvo?
    ├── Funcionário logado?  → PinLoginActivity (PIN/biometria)
    └── Não logado?          → LoginActivity (email/senha)
                ↓
        DashboardActivity
                ↓
    Abrir caixa: POST /api/pos/sessoes
                 Authorization: Bearer <token-pessoal>
                 Body: { "terminal_id": X, "opening_amount": Y }
                ↓
    Vender: POST /api/pos/sales
            Authorization: Bearer <token-pessoal>
                ↓
    Fechar caixa, movimentos, estornos...
```

### 6.3. Troca de operador no mesmo turno

```text
Dashboard → "Trocar operador"
    ↓
Fecha sessão atual (ou bloqueia)
    ↓
PinLoginActivity / LoginActivity com novo funcionário
    ↓
Nova sessão com novo funcionario_id no mesmo terminal_id
```

---

## 8. Impacto no Backend Nexora

Para suportar o fluxo correto, o backend também precisa evoluir:

1. **`POST /api/pos/sessoes`** deve aceitar `terminal_id` no body e usar token pessoal do operador.
2. Deve validar que o operador tem `pos:operar_pos`.
3. Deve resolver `funcionario_id` a partir do `user_id` do token.
4. Deve validar autorização naquele terminal (quando `pos.terminal_funcionarios` existir).
5. **`POST /api/pos/sales`** deve usar token pessoal e herdar `terminal_id`/`funcionario_id` da sessão.

Alguns desses pontos já estão parcialmente implementados no backend, mas o contrato de API e as permissões precisam ser revisitados.

---

## 9. Critérios de Aceitação do Modelo Nexora Relevantes

| Critério | Estado no mobile PayCore |
|----------|-------------------------|
| RF-ID-07: login humano separado do login da máquina | ❌ Não cumprido |
| RF-ID-08: sessão liga terminal, usuário e funcionário | ❌ Não cumprido |
| RF-ID-09: autoria da venda rastreável ao funcionário | ⚠️ Parcialmente (nome do operador em cache, mas token é da máquina) |
| RF-ID-10: troca de operador fecha/abre nova sessão | ⚠️ Não implementado |
| RF-ID-14a: gestão de terminal restrita a admins | ✅ Backend já protege; mobile não expõe essas ações |
| RNF-ID-02: activation_code não é senha de uso diário | ❌ Usado todo dia |
| RNF-ID-06: terminologia correta (Terminal/Caixa vs Operador) | ⚠️ Misturado |

---

## 10. Conclusão

> **Login de funcionário primeiro e depois login de terminal, na forma como está implementado hoje, é lógica e tecnicamente errado.**

O correto segundo o modelo Nexora é:

1. **Terminal** é configurado uma vez no dispositivo (ativação).
2. **Funcionário** faz login a cada turno com conta pessoal.
3. O funcionário opera o POS usando **seu próprio token**, não o da máquina.
4. O terminal é enviado como contexto (`terminal_id`) nas operações de caixa e venda.

O mobile PayCore precisa de um **redesign do fluxo de autenticação** para inverter essa lógica.

Essa mudança estrutural resolve a raiz da confusão entre máquina e operador e alinha o aplicativo com o modelo de identidade do Nexora.
