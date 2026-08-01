# Análise: PayCore Mobile → Nexora ERP (factPro/backend) como backend único

Data: 2026-07-23
Âmbito: `D:\projecto\e-258tech\2026\PayCore\mobile` (app Android/Kotlin) vs `D:\projecto\e-258tech\2026\factPro\backend` (Go/Nexora ERP)

Objetivo: avaliar se — e como — o backend Go do Nexora ERP pode substituir o backend Node.js atual (`PayCore/backend`) como backend único da app móvel PayCore, tornando-a mais um cliente do ERP em vez de um produto com backend próprio.

---

## 1. Resumo executivo

- A app PayCore tem hoje o seu **próprio backend Node.js/Express** (`PayCore/backend`, package `paycore-backend`), com um contrato REST claro e estável: 27 endpoints sob `v1/`, cobrindo auth, utilizadores, catálogo (produtos/categorias), terminais, caixa, descontos, transações e tenant. É esse contrato que a app realmente fala — não Firebase (que está configurado mas morto no código) e não o Nexora ERP.
- O Nexora ERP já tem um módulo **`pos`** funcional (748 LOC), mais os módulos de apoio **gestao-clientes**, **gestao-produtos**, **gestao-stock** e **modulo-faturacao**, que são maduros e cobrem largamente as necessidades de catálogo/stock/faturação do PayCore. **Financeiro** e **Tesouraria** são imaturos (~260-310 LOC). **Multi-moeda** e **notifications** são utilitários finos mas suficientes.
- As três análises "ERP Mobile" já existentes no backend (`analise-erp-mobile.md`, `erp-mobile-detalhado.md`, `erp-mobile-prioridade-modulos.md`) **não consideraram POS/pagamentos** — foram pensadas para um ERP mobile de gestão interna (aprovações, tarefas, RH self-service). Isto significa que a estratégia de mobile já desenhada para o Nexora **não cobre o caso PayCore** e precisa de ser complementada, não apenas seguida.
- **Não existe hoje nenhum conceito de "terminal/dispositivo POS" ligado a um utilizador móvel no ERP.** O `device_auth.go` existente é para hardware físico (relógios de ponto), e o `pos_terminals` do módulo POS não tem autenticação própria por dispositivo — é um gap a construir de raiz, tal como o PayCore Node.js já tem (`v1/terminals/login`, `v1/terminals/refresh`).
- **Existe um gateway de pagamento móvel moçambicano pronto no ERP (Nexora-Pay: M-Pesa/eMola/mKesh)**, mas só está integrado no portal de pagamentos escolares — não no POS. É a peça mais valiosa a reaproveitar/generalizar, porque o PayCore atual só grava o método de pagamento como enum, sem chamar gateway nenhum.
- Push (FCM) e WebSocket já são genéricos por utilizador no ERP — falta só o endpoint HTTP de registo de token para utilizadores do ERP (hoje só existe para candidatos a emprego) e eventos de negócio de venda/pagamento.
- **A app em si tem dívida técnica que precisa de ser resolvida independentemente do backend escolhido**: login de utilizador (email/senha e PIN) é mock/hardcoded, `BASE_URL` está fixo num IP LAN sem build variants, há código morto (modelo de terminal alternativo num pacote órfão), e o único fluxo de auth real hoje é o login de terminal.

**Conclusão**: a migração é viável mas é um projeto de médio porte, não um "trocar a URL". Requer construir no ERP um domínio POS-mobile novo (terminais/dispositivos, sessões de caixa tal como o PayCore as modela, descontos, estorno) por cima dos módulos já maduros de clientes/produtos/stock/faturação, mais generalizar autenticação, push e pagamento móvel.

---

## 2. Contrato atual da app (o que tem de ser satisfeito)

Fonte: `ApiService.kt` + `ApiModels.kt` da app, confirmado a apontar hoje para `PayCore/backend` (Node/Express, SQL puro, mesmas tabelas `products/categories/terminals/transactions/discounts/cash-drawers/tenants`).

| Grupo | Endpoints | Módulo ERP mais próximo | Existe hoje no ERP? |
|---|---|---|---|
| Auth utilizador | `POST auth/login`, `refresh`, `logout`, `GET auth/me` | `api/auth` | Sim, pipeline JWT+sessão equivalente |
| Auth terminal | `POST terminals/login`, `terminals/refresh` | — | **Não existe.** `pos_terminals` não tem login próprio; `device_auth.go` é para hardware, não serve |
| Utilizadores | CRUD `v1/users` | `api/utilizadores`, RBAC (`auth.cargos`) | Sim, mais rico (cargos/permissões finas) |
| Catálogo | `products/categories`, `products` (CRUD) | `api/produtos` (gestao-produtos) | Sim, e mais completo (variantes, kits, marcas, atributos) |
| Terminais | CRUD `v1/terminals` + status | `api/pos` terminais (`ListarTerminais`, `CriarTerminal`) | Parcial — CRUD existe, falta ciclo de vida de token/ativação |
| Caixa | `GET cash-drawers` | `api/pos` sessões (`AbrirSessao`, `FecharSessao`, `ObterSessaoAtual`) | Parcial — conceito existe mas modelo de dados diferente (abertura/fecho vs. "cash-drawer" simples) |
| Descontos | CRUD `v1/discounts` | `api/produtos` descontos, ou `api/pos` | Parcial — descontos existem no produto, não como entidade POS autónoma com min/max/validade |
| Sync catálogo | `GET tenants/{id}/sync/download?since=` | — | Não existe (endpoint incremental por `since`); nota: a própria app hoje **não chama** este endpoint apesar de o backend Node o ter |
| Transações | `POST transactions`, `reverse`, `GET transactions` | `api/pos` (`CriarVenda`, `CancelarVenda`, `ListarVendas`) | Sim, conceitualmente — falta mapear campos (referência, método CASH/CARD/NFC/QR_CODE, desconto/acréscimo, estorno) |
| Tenant | `GET admin/tenants/{id}` | `api/superadmin` / `empresas` | Sim |

**Nota de nomenclatura**: os DTOs da app aceitam tanto português (`nome`, `preco`, `activo`) como inglês (`name`, `price`, `active`) via `@SerializedName(alternate=...)`. Isto dá margem para o ERP (que é predominantemente em português: `produtos`, `clientes`, `stock`) ser consumido sem alterar a app, desde que se confirme cada campo caso a caso.

---

## 3. Gaps a construir no ERP

Por ordem de bloqueio (do que impede tudo, para o que é incremental):

1. **Autenticação de terminal/dispositivo móvel POS** — hoje inexistente. Precisa de:
   - Tabela nova (ex. `pos.terminal_devices` ou reaproveitar/estender `pos_terminals`) com `serial_number`, `activation_code`, hash de token, `terminal_token`/`terminal_refresh_token`, validade (a app espera refresh proativo a 7 dias de expirar, validade de 30 dias).
   - Middleware novo tipo `RequirePOSTerminalAuth`, análogo ao `device_auth.go` mas para o conceito de terminal-do-utilizador-final, não hardware físico. Não reaproveitar `hardware.devices` — são domínios diferentes (confirmado na exploração: `pos_terminals` já é uma tabela distinta de `hardware.devices`).
2. **Escopo/claim mobile no JWT de utilizador** — os 3 documentos de análise já recomendam um escopo `mobile_erp` com refresh token mais longo; isto serve tanto para RH self-service como para operadores POS a fazer login por email/senha.
3. **Sessão de caixa (cash drawer) alinhada ao modelo da app** — o ERP tem `AbrirSessao`/`FecharSessao`/`ObterSessaoAtual`; confirmar que cobre abertura com valor inicial, fecho com contagem, e histórico consultável por `terminalId`/`status` como o endpoint `GET cash-drawers?status=&terminalId=&limit=` espera.
4. **Descontos como entidade autónoma** (percentagem/valor fixo, min/max, validade, CRUD) — hoje os descontos parecem estar acoplados a produto; a app trata desconto como recurso independente aplicável numa venda.
5. **Estorno de venda** — confirmar que `CancelarVenda` cobre semântica de "reverse" com motivo (`EstornoRequest{reason}`), e que devolve o mesmo formato de `TransacaoResponse`.
6. **Sync incremental de catálogo** (`since=`) — não existe; é uma funcionalidade nova, mesmo que de baixa prioridade (a própria app hoje não a chama, mas seria desejável para operação offline-first em catálogos grandes).
7. **Endpoint HTTP genérico de registo de push token** para utilizadores `RequireAuth` (o serviço `internal/push` já suporta qualquer `user_id` — só falta o endpoint, hoje restrito a candidatos).
8. **Eventos de negócio no WebSocket/push para vendas e pagamentos** (ex. `venda_criada`, `pagamento_recebido`) — hoje o Hub só emite eventos de chat/notificações genéricas.
9. **Gateway de pagamento móvel (Nexora-Pay: M-Pesa/eMola/mKesh) generalizado para o POS** — hoje só chamado a partir do portal de pagamentos escolares. É o maior upgrade funcional face ao que a app tem agora (que só regista o método como enum, sem processar o pagamento).
10. **Financeiro e Tesouraria** precisam de mais trabalho (261–308 LOC hoje) se o PayCore vier a expor relatórios de caixa/fluxo consolidados além do que já existe no módulo POS.

## 4. Do lado da app (independente do backend escolhido)

Estes problemas devem ser corrigidos de qualquer forma, mesmo antes/durante a troca de backend:

- **Login de utilizador é mock**: `LoginActivity` usa uma lista fixa de 3 utilizadores demo e nunca chama a API; `PinLoginActivity` usa PIN fixo `"1234"`. O único fluxo de auth real hoje é o login de terminal. Isto tem de ser corrigido para a app poder falar com qualquer backend real, ERP incluído.
- **`BASE_URL` hardcoded** em `ApiClient.kt` (IP LAN de desenvolvimento), sem build variants dev/staging/prod nem `BuildConfig` field — vai ser preciso introduzir isto para apontar de facto ao Nexora ERP sem recompilar cada vez.
- **Logging OkHttp em modo `BODY` sempre ativo** — expõe tokens/credenciais em logs; corrigir antes de qualquer ligação a um backend com dados reais.
- **Código morto a decidir**: `com.paycore.mobile.api.model.TerminalModels.kt` tem um contrato de terminal mais rico (geolocalização, `settings`, `appVersion`) não referenciado em lado nenhum — vale a pena avaliar se esse contrato (não o atual, mais pobre) deveria ser o alvo do novo backend de terminais no ERP.
- **Firebase configurado mas não usado** (google-services.json de outro projeto, "sbcdsaude") — limpar ou decidir se passa a ser usado a sério para push (o ERP já usa Firebase Admin SDK do lado do servidor, com um `FIREBASE_CREDENTIALS_FILE` próprio — a app teria de usar o `google-services.json` correspondente ao projeto Firebase do Nexora, não o atual).

## 5. Autenticação — proposta de convergência

Hoje há dois mundos:

- **App PayCore**: dois tokens paralelos — utilizador (`accessToken`/`refreshToken`, JWT) e terminal (`terminalToken`, 30 dias, refresh a 7 dias de expirar).
- **ERP**: JWT + validação de sessão em `auth.sessions` (via `auth.memberships`, multi-tenant/multi-empresa), escopos `erp`/`escola`, sem qualquer noção de terminal POS.

Proposta:
1. Utilizador humano (operador de caixa, gerente, admin) passa a autenticar-se contra `POST /api/auth/login` do ERP, com escopo novo `mobile_erp` (ou `pos`), mantendo o modelo de sessão em BD já existente (revogação remota fica de graça).
2. Terminal (o dispositivo físico onde a app corre) passa a ter um fluxo próprio novo, análogo ao atual `v1/terminals/login`, mas implementado no ERP como extensão do módulo `pos` — **não reaproveitar `device_auth.go`** (é para hardware tipo relógio de ponto, semântica diferente).
3. Manter os dois tokens em paralelo tal como a app já faz hoje (não é preciso fundir), só trocando o backend-alvo de cada um.

## 6. Plano de integração faseado (proposta)

1. **Fase 0 — higiene da app**: corrigir login mock, extrair `BASE_URL` para build config, desligar logging `BODY` em release. Não depende do ERP, desbloqueia testes reais mais cedo.
2. **Fase 1 — auth**: escopo `mobile_erp`/`pos` no ERP + endpoint de login de terminal novo. Validar `POST auth/login` e `POST terminals/login` a partir da app apontando para o ERP em ambiente de dev.
3. **Fase 2 — catálogo e stock**: ligar `v1/products`, `v1/products/categories` a `gestao-produtos`/`gestao-stock` (já maduros). Resolver mapeamento de nomes de campos.
4. **Fase 3 — POS core**: sessões de caixa, vendas, estorno, descontos, terminais — construir o que falta em cima do módulo `pos` existente.
5. **Fase 4 — pagamento real**: generalizar Nexora-Pay (M-Pesa/eMola/mKesh) para o fluxo de venda POS, substituindo o enum sem processamento real que a app tem hoje.
6. **Fase 5 — push/real-time**: endpoint genérico de push token + eventos de venda/pagamento no Hub WS, ligados a `NotificacoesActivity`/dashboard.
7. **Fase 6 — sync incremental e clientes**: implementar `sync/download?since=` se justificado, e decidir o que fazer com `ClientesActivity` (hoje placeholder) face ao módulo `gestao-clientes`, que é rico e poderia alimentar essa tela pela primeira vez.

## 7. Decisões em aberto para o cliente/produto

- O contrato "mais rico" de terminal em `com.paycore.mobile.api.model.TerminalModels.kt` (código morto) deve ser adotado como alvo, ou mantém-se o contrato atual mais simples?
- Financeiro/Tesouraria do ERP ficam com o nível atual (básico) ou o PayCore precisa de relatórios de caixa consolidados que forcem investir mais ali primeiro?
- Vale a pena reaproveitar o escopo `mobile_erp` já pensado para RH/aprovações/tarefas (dos documentos prévios) no mesmo produto PayCore, ou o operador de POS deve ver só o essencial (venda/caixa/catálogo), sem o resto do ERP?
- Multi-tenant: o PayCore usa `tenant_slug` no login; confirmar mapeamento para o modelo de duplo espaço de IDs do ERP (`empresas.companies.id` vs `saas.tenants.id`, ver `internal/pkg/tenantid`) para não repetir o bug já registado noutro módulo (Enigma School).
