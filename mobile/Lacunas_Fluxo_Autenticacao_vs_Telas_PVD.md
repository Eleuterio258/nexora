# Lacunas entre o Fluxo de Autenticação Recomendado e o Fluxo de Telas do PVD Mobile

> **Compara:** `Analise_Fluxo_Autenticacao_vs_Modelo_Nexora.md` (o que o modelo Nexora exige) com `Fluxo_Telas_PVD_Mobile.md` (o desenho de telas proposto para o PVD).
> **Objectivo:** apontar onde o desenho de telas ainda não reflecte as regras de autenticação já definidas, para que o desenho final não repita os mesmos problemas identificados no PayCore actual.

---

## 1. O login volta a misturar terminal com operador

O fluxo de autenticação recomendado define a activação do terminal como **configuração única do dispositivo**, feita uma vez, separada do login diário do operador.

O fluxo de telas do PVD, na tela de Login, descreve:

`Login → validação → seleccionar/confirmar terminal → Ponto de Venda`

Isto reintroduz a escolha/confirmação do terminal **dentro do login diário**, o mesmo problema apontado como erro no PayCore actual (login de terminal como etapa diária).

**Resolução sugerida:** o passo "seleccionar/confirmar terminal" só deve aparecer na primeira configuração do dispositivo. No uso diário, o terminal já está fixo e o login deve ir directo do operador para o Ponto de Venda (ou Abertura de Caixa).

---

## 2. Falta uma tela explícita de activação do terminal

O fluxo de autenticação prevê uma etapa clara de activação (serial + código de activação), executada uma única vez.

O fluxo de telas do PVD não tem nenhuma tela dedicada a isto — a Splash apenas "verifica empresa/loja/terminal", sem descrever o que acontece quando não há terminal configurado.

**Resolução sugerida:** acrescentar ao fluxo de telas um ecrã de "Configuração do Terminal" (serial + código de activação), acionado pela Splash apenas quando não existir terminal guardado, alinhado com a secção "Configuração inicial do dispositivo" do documento de autenticação.

---

## 3. As telas não especificam qual token é usado em cada operação

O ponto central do documento de autenticação é: **vender, abrir e fechar caixa devem usar o token pessoal do operador**, nunca o token do terminal.

O fluxo de telas do PVD (Abertura de Caixa, Ponto de Venda, Pagamento, Fecho de Caixa) não menciona autenticação/token em nenhum momento — trata tudo como se fosse apenas UI, sem indicar qual credencial acompanha cada chamada.

**Resolução sugerida:** anotar explicitamente, nas telas de Abertura de Caixa, Pagamento e Fecho de Caixa, que as chamadas usam o token pessoal do operador e enviam `terminal_id` como contexto — para que quem implementar não repita o erro do PayCore actual.

---

## 4. A sessão (terminal + operador) não aparece modelada nas telas

O documento de autenticação exige que a sessão aberta ligue `terminal_id`, `user_id` e `funcionario_id`, e que cada venda herde essa sessão.

O fluxo de telas trata "Caixa" e "Operador" como campos soltos de exibição (ex.: tela 3 "Abertura de Caixa", tela 20 "Caixa"), sem indicar que existe uma sessão de POS por trás que amarra esses três identificadores.

**Resolução sugerida:** a tela de Abertura de Caixa devia deixar explícito que o resultado é a criação de uma sessão (`pos_session_id`) que persiste até ao fecho, e que todas as vendas subsequentes referenciam essa sessão.

---

## 5. Troca de operador/turno não existe no fluxo de telas

O documento de autenticação dedica uma secção inteira (6.3) à troca de operador no mesmo terminal: fechar/bloquear a sessão actual e abrir nova sessão com o novo funcionário, sem reactivar o terminal.

O fluxo de telas do PVD não tem nenhuma tela ou acção de "Trocar operador" — o Menu Principal (tela 24) não lista essa opção, e não há fluxo equivalente a `Dashboard → Trocar operador`.

**Resolução sugerida:** acrescentar a acção "Trocar Operador" ao Menu Principal, reutilizando o fluxo já descrito na secção 6.3 do documento de autenticação.

---

## 6. Permissões (RBAC) tratadas apenas de forma pontual

O documento de autenticação liga permissões a acções específicas (`pos:operar_pos`, validação de autorização por terminal).

O fluxo de telas só menciona permissão uma vez, para Descontos ("o sistema deve verificar se o operador possui permissão"), e novamente para Devolução/Anulação ("dependendo das permissões"), sem critério consistente sobre quando outras acções (abrir caixa, editar preço no carrinho, gerir stock) também devem ser validadas por permissão.

**Resolução sugerida:** definir uma lista única de permissões do PVD (abrir caixa, vender, aplicar desconto, editar preço, anular venda, devolver, consultar stock, gerir terminal) e referenciá-la em cada tela relevante.

---

## 7. Gestão de terminal restrita a admins não aparece nas telas

O documento de autenticação regista como já correcto que a gestão de terminal deve ficar restrita a administradores (RF-ID-14a), mas nota que o mobile "não expõe essas ações".

O fluxo de telas do PVD continua sem expor nenhuma tela de gestão de terminal (reactivar, desvincular, listar terminais) — nem no Menu Principal nem nas Configurações.

**Resolução sugerida:** decidir deliberadamente se a gestão de terminal fica fora do PVD (feita só no ERP/backoffice) ou se entra nas Configurações do PVD restrita a perfil admin — e documentar essa decisão.

---

## 8. Modo Offline não trata a validade do token pessoal

O fluxo de telas introduz o Modo Offline (tela 25), mas o documento de autenticação não cobre o que acontece à autenticação pessoal quando não há ligação — token pessoal expirado, PIN local, etc.

**Resolução sugerida:** definir como o operador se autentica em modo offline (ex.: cache do PIN/token localmente com expiração) e como a venda offline referencia a sessão aberta antes da perda de ligação.

---

## 9. Resumo

| Lacuna | Secção (Autenticação) | Secção (Telas PVD) | Severidade |
|---|---|---|---|
| Login volta a pedir terminal diariamente | 6.2 | 2. Login | 🚨 Alta |
| Falta tela de activação do terminal | 6.1 | 1. Splash | 🚨 Alta |
| Telas não indicam qual token usar | 4.1, 6.2 | 3, 10, 21 | 🚨 Alta |
| Sessão terminal+operador não modelada | 2, 6.2 | 3, 20 | ⚠️ Média |
| Troca de operador ausente | 4.6, 6.3 | 24. Menu | ⚠️ Média |
| Permissões tratadas de forma pontual | 8 (validações backend) | 9, 18 | ⚠️ Média |
| Gestão de terminal (admin) ausente | 9 (RF-ID-14a) | — | ⚠️ Média |
| Autenticação offline não definida | — | 25. Offline | ⚠️ Média |

