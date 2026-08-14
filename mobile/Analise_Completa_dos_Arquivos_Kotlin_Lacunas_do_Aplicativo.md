# Análise Completa dos Arquivos Kotlin — Lacunas do Aplicativo PayCore Mobile

> **Escopo:** todos os arquivos `.kt` em `mobile/app/src/main/java/tech/e258tech/paycore/`  
> **Backend oficial:** Nexora (Go) — `https://api.nexora.e258tech.tech/api/`  
> **Data da análise:** 2026-08-10

---

## 1. Resumo Executivo

O aplicativo mobile PayCore possui uma arquitetura híbrida que mistura lógica de negócio/UI em singletons (`PosStore`, `ApiClient`, `SincronizacaoManager`), persistência local via Room e integração com o backend Nexora (Go). Embora os fluxos principais de login, abertura de caixa, vendas e sincronização tenham sido parcialmente adaptados para o Nexora, **existem lacunas críticas que impedem o funcionamento correto como POS**:

- Vendas de produtos "fixture" (catálogo demo) nunca sincronizam com o servidor.
- Filtros de totais "Hoje" não filtram por data, distorcendo resumo e fecho de caixa.
- Produtos desativados no backend continuam aparecendo no POS local.
- Controle de stock não existe; vendas podem exceder stock real.
- Autenticação não trata expiração de token nem redireciona automaticamente após refresh falhar.
- Fluxo de licença está desconectado do onboarding.
- Telas de cadastro de produto/usuário são rudimentares e propensas a erros de integração.

---

## 2. Legenda de Severidade

| Ícone | Severidade | Significado |
|-------|------------|-------------|
| 🔴 | Crítico | Impede fluxo principal ou causa perda/corrupção de dados |
| 🟠 | Alto | Causa erro ou comportamento incorreto em funcionalidade importante |
| 🟡 | Médio | Causa fricção, inconsistências ou UX ruim |
| 🟢 | Baixo | Refatoração, dead code, estilo, segurança |

---

## 3. Achados por Severidade

### 🔴 Crítico

#### 1. Vendas de produtos fixture nunca sincronizam
- **Arquivos:** `PosStore.kt` (linhas ~863–875, ~300–303, `processarPagamento` ~742–783)
- **Descrição:** `carregarCatalogoAsync()` retorna produtos de demonstração hardcoded com `id = "fx-001"` etc. Na sincronização, `produtoId!!.toLong()` lança `NumberFormatException` (capturado silenciosamente). A venda fica gravada localmente como "Aprovada", mas nunca chega ao backend.
- **Impacto:** Vendas realizadas em demo/offline são perdidas silenciosamente. Caixa fecha com valores divergentes do servidor.
- **Sugestão:** Remover fixtures do código de produção ou marcar `produtoId` como não-sincronizável; validar numérico antes de permitir venda.
- ✅ **Concluído (2026-08-11):** `PosStore.carregarCatalogoAsync()` deixou de fabricar o catálogo fixture; devolve os dados reais do Room/backend (vazio enquanto não sincroniza), eliminando de vez os `id = "fx-*"` que nunca sincronizavam.

#### 2. `totalVendasHoje()` e `quantidadeVendasHoje()` não filtram por data
- **Arquivo:** `PosStore.kt` (linhas ~826–830)
- **Descrição:** Os métodos filtram apenas por `estado == "Aprovado"`, ignorando a data. O nome indica "hoje", mas retorna todas as transações aprovadas em memória.
- **Impacto:** Dashboard e fecho de caixa mostram valores acumulados de dias anteriores, induzindo o operador a erro e causando diferenças de caixa.
- **Sugestão:** Filtrar transações por `dataHora >= inicioDoDia`.
- ✅ **Concluído (2026-08-11):** Adicionados `totalVendasSessaoAtual()`/`quantidadeVendasSessaoAtual()`, que consultam `TransacaoDao.getAprovadasPorSessao(sessaoAtualLocalId)` em vez do total histórico em memória; `DashboardActivity.atualizarResumo()` passou a usá-los.

#### 3. `totaisPorMetodo()` não filtra por sessão nem por data
- **Arquivo:** `PosStore.kt` (linhas ~832–845)
- **Descrição:** Soma totais de **todas** as transações aprovadas em memória, independentemente de sessão de caixa ou dia.
- **Impacto:** No `FechoCaixaActivity`, o operador vê totais de vendas antigas misturados com a sessão atual.
- **Sugestão:** Receber `sessaoLocalId` e/ou data como parâmetro; usar `getAprovadasPorSessao`.
- ✅ **Concluído (2026-08-11):** Nova `totaisPorMetodoSessaoAtual()` em `PosStore.kt` usa `getAprovadasPorSessao(sessaoAtualLocalId)`; `FechoCaixaActivity.atualizarTotais()` passou a usá-la (junto com `totalVendasSessaoAtual()`), alinhando o que é mostrado ao operador com o que `registarFechoCaixa()` reconcilia.

#### 4. Produtos desativados no backend continuam vendáveis no POS
- **Arquivos:** `ProdutoEntity.kt`, `SincronizacaoManager.kt` (~167–175), `ApiModels.kt` (~364)
- **Descrição:** `ProdutoDTO` possui campo `ativo`, mas `ProdutoEntity` não o persiste. O sync incremental apenas faz `insertAll` (replace por id) sem campo ativo.
- **Impacto:** Produtos desativados/removidos no ERP continuam aparecendo e sendo vendidos no terminal.
- **Sugestão:** Adicionar `ativo: Boolean` a `ProdutoEntity` e ao filtro de exibição em `NovaVendaActivity`.
- ✅ **Concluído (2026-08-11):** `ProdutoEntity.ativo` adicionado (migração Room v10→v11), populado a partir de `ProdutoDTO.activo` em `SincronizacaoManager.sincronizar()`, e filtrado na origem por `ProdutoDao.getAll() WHERE ativo = 1` — produtos desativados deixam de chegar ao catálogo vendável.

#### 5. Ausência total de controle de stock
- **Arquivos:** `NovaVendaActivity.kt`, `PosStore.kt`
- **Descrição:** Não há verificação de stock ao adicionar itens nem decremento após venda. Vendas offline podem exceder stock real.
- **Impacto:** Vendas de produtos sem stock são sincronizadas e rejeitadas pelo backend, ou, pior, o operador entrega produto que não deveria vender.
- **Sugestão:** Adicionar campo `stock` em `ProdutoEntity`; validar quantidade no carrinho; reservar/decrementar stock localmente e sincronizar movimentos.
- ⚠️ **Parcialmente concluído (2026-08-11):** `ProdutoEntity.stock: Int?` adicionado (migração v10→v11) e `PosStore.adicionarItem()`/`incrementarItem()` já bloqueiam a quantidade acima do stock quando definido (toast "Sem stock disponível" em `NovaVendaActivity`). **Continua pendente:** o backend Nexora não expõe nenhum campo de stock/inventário por produto (confirmado — não existe em `ProdutoDTO` nem em nenhum endpoint de `ApiModels.kt`), por isso `stock` fica sempre `null` (ilimitado) na prática até o backend passar a enviá-lo. Falta trabalho do lado do backend para este item ficar realmente activo.

#### 6. `ApiClient.isLoggedIn` não valida expiração do token
- **Arquivo:** `ApiClient.kt` (~linha 119)
- **Descrição:** `isLoggedIn` retorna `accessToken != null`, sem verificar `expires_at`. O app acredita estar autenticado com token expirado.
- **Impacto:** Chamadas à API falham com 401; o authenticator tenta refresh e, se falhar, limpa tokens silenciosamente sem notificar a UI. O usuário fica preso em telas.
- **Sugestão:** Validar expiração armazenada; expor estado de sessão expirada; redirecionar para login quando refresh falhar.
- ✅ **Concluído (2026-08-11):** `ApiClient` decodifica localmente o `exp` do JWT (`jwtExpirado()`) e tenta renovar proactivamente antes de enviar um token expirado; toda falha definitiva de refresh (sem refresh token, ou pedido de renovação rejeitado) agora chama `forcarLogoutEIrParaLogin()`, que limpa os tokens e redireciona para `LoginActivity` — o utilizador deixa de ficar preso numa tela morta. Falhas de rede transitórias continuam sem forçar logout (app é offline-first).

#### 7. `PinLoginActivity` pode abrir seleção de modo sem permissões carregadas
- **Arquivo:** `PinLoginActivity.kt` (~161–184)
- **Descrição:** Se `corpo.user` for null, `sincronizarSessaoApi` não é chamado. `operadorAtual` pode ser null e `modulosPermissao` vazio, mas ainda assim abre `SelecaoModoActivity`.
- **Impacto:** Usuário entra em tela sem permissões, com nome vazio, sem poder acessar nada.
- **Sugestão:** Exigir `user != null`; caso contrário, forçar login completo.

#### 8. `LoginActivity` permite entrada sem permissões em caso de falha de `meAcesso()`
- **Arquivo:** `LoginActivity.kt` (~72–84)
- **Descrição:** `me()` e `meAcesso()` estão dentro de `runCatching{}.getOrNull()`. Se falharem, o usuário entra com `modulos = emptyMap()`.
- **Impacto:** Em `SelecaoModoActivity` ambos os cards somem; o usuário fica preso.
- **Sugestão:** Se `meAcesso()` falhar, bloquear entrada e pedir retry; não redirecionar com permissões vazias.

#### 9. Duas sessões de caixa podem coexistir inadvertidamente
- **Arquivos:** `AberturaCaixaActivity.kt` (~76–87), `PosStore.kt` (~467–478)
- **Descrição:** Se não houver rede, abre sessão offline sem consultar `obterSessaoAtual()`. Se outro terminal já abriu caixa para o mesmo operador, ao sincronizar haverá conflito.
- **Impacto:** Sessões duplicadas, vendas associadas à sessão errada, rejeição pelo backend.
- **Sugestão:** Antes de abrir offline, tentar consultar sessão atual; se houver rede e já existir, associar venda à sessão existente.

#### 10. Transações pendentes ficam presas para sempre em vários cenários
- **Arquivo:** `PosStore.kt` (~280–324)
- **Descrição:** `continue` é usado quando: (a) `resolverServerSessionId` retorna null, (b) itens têm `produtoId` inválido. Não há fila de retry separada nem marcação de erro.
- **Impacto:** Vendas válidas podem nunca sincronizar; não há visibilidade de falha.
- **Sugestão:** Adicionar contador de tentativas e estado de erro; notificar na UI/SincronizacaoActivity.
- ✅ **Concluído (2026-08-11):** Novo `SyncStatus` (PENDENTE/EM_RETRY/FALHADO/SINCRONIZADO), aditivo aos booleanos existentes, com `tentativas`/`ultimoErro`/`ultimaTentativaEm` em `TransacaoPDVEntity`/`SessaoCaixaEntity`/`EstornoEntity` (migração Room v12→v13). Os `continue` silenciosos passaram a registar a falha classificada (4xx do backend = permanente/`FALHADO`, deixa de ser tentado; rede ou 5xx = transitório/`EM_RETRY`, continua a ser tentado). O `break` que travava o lote inteiro de aberturas de sessão pendentes ao primeiro falhado passou a `continue` por sessão — uma sessão presa deixou de bloquear todas as outras. Nova secção "Pendências" em `SincronizacaoActivity` (só leitura) mostra contagens e o último erro, algo que antes não existia em lado nenhum.

#### 11. Licença e registro estão fora do fluxo de onboarding
- **Arquivos:** `SplashActivity.kt`, `AtivacaoLicencaActivity.kt`, `RegistroActivity.kt`
- **Descrição:** `SplashActivity` pula `AtivacaoLicencaActivity`; `RegistroActivity` não é referenciada no fluxo.
- **Impacto:** Nenhuma validação de licença ocorre; telas de registro são dead code.
- **Sugestão:** Inserir `AtivacaoLicencaActivity` após onboarding (se não houver licença ativa); remover ou integrar `RegistroActivity`.
- ✅ **Concluído (2026-08-11):** `AtivacaoLicencaActivity` integrada no fluxo real — `SplashActivity`/`OnboardingActivity` passam por ela quando não há `tenantId` activado no aparelho, antes do login; o bypass `CHAVE_DEMO` só funciona em builds de debug. `RegistroActivity` foi removida por completo (activity, layout e `PosStore.registarOperador`) — confirmado sem nenhuma navegação a apontar para ela.

#### 12. Pagamentos eletrônicos não são confirmados externamente
- **Arquivos:** `PagamentoActivity.kt`, `PosStore.kt` (~699–785)
- **Descrição:** Cartão, M-Pesa, e-Mola e QR Code registram venda como "Aprovada" sem integração com TPA/gateway/QR.
- **Impacto:** Vendas podem ser registradas sem pagamento efetivo. Chargebacks e fraudes.
- **Sugestão:** Implementar integração real ou, no mínimo, fluxo de confirmação manual com referência/supervisor.

---

### 🟠 Alto

#### 13. 2FA não é implementado no app
- **Arquivo:** `LoginActivity.kt` (~60–64)
- **Descrição:** Quando o backend responde `twoFactorRequired = true`, o app apenas mostra mensagem de erro.
- **Impacto:** Usuários com 2FA ativo não conseguem fazer login.
- **Sugestão:** Implementar tela de 2FA usando `tempToken`.

#### 14. Refresh de token do terminal ignora `expiresIn` do backend
- **Arquivo:** `TerminalTokenManager.kt` (~23–24, ~88–90)
- **Descrição:** Usa TTL fixo de 30 dias em vez de `response.expiresIn`.
- **Impacto:** Token pode ser considerado válido além do prazo real ou refresh prematuro.
- **Sugestão:** Calcular `expiresAt` a partir de `expiresIn` retornado.

#### 15. `saveProduto()` pode deixar produto sem preço no backend
- **Arquivo:** `AdminApiRepository.kt` (~193–248)
- **Descrição:** Cria produto, depois preço, depois barcode. Se o preço falhar, o produto já existe no backend sem preço; nova tentativa de criar o mesmo código falha.
- **Impacto:** Estado inconsistente; produto não vendável; erro repetido.
- **Sugestão:** Implementar rollback/desativar produto em caso de falha do preço, ou usar endpoint transacional.

#### 16. `AdminFixtures` são exibidos como dados reais em falha de API
- **Arquivos:** `AdminInicioActivity.kt`, `AdminProdutosActivity.kt`, `AdminTerminaisActivity.kt`, etc.
- **Descrição:** Em `.onFailure`, os ecrãs mostram fixtures hardcoded sem indicação clara de que são dados locais/demo.
- **Impacto:** Administrador pode tomar decisões baseado em dados fictícios.
- **Sugestão:** Mostrar mensagem de erro e esconder dados, ou marcar claramente como "dados de exemplo".

#### 17. Formulários de produto/usuário usam campos de texto livre para IDs e roles
- **Arquivos:** `AdminProdutoFormActivity.kt`, `AdminUtilizadorFormActivity.kt`
- **Descrição:** Categoria é digitada como ID numérico; role é texto livre. Sem dropdowns/validação.
- **Impacto:** Erros comuns causam falhas 400/422 no backend.
- **Sugestão:** Usar spinners/dropdowns alimentados pelos dados do tenant.
- ✅ **Concluído (2026-08-11):** Categoria em `AdminProdutoFormActivity` passou a ser um dropdown fechado (`AutoCompleteTextView` + `ExposedDropdownMenu`) alimentado por `AdminApiRepository.loadCategorias()` — já não se digita o ID à mão. Role em `AdminUtilizadorFormActivity` passou a ter sugestões via dropdown, mas continua a aceitar texto livre — o ERP modela isto como "cargo" configurável por tenant, não existe endpoint para listar os valores válidos, por isso bloquear a um conjunto fixo reintroduziria o mesmo risco de 400/422 para tenants com cargos próprios.

#### 18. `RegistroActivity` cria operador local sem autenticação backend
- **Arquivo:** `RegistroActivity.kt`
- **Descrição:** Permite registrar operador localmente (`PosStore.registarOperador`), mas não cria no ERP.
- **Impacto:** "Operador" não pode logar no backend; dados desconectados.
- **Sugestão:** Integrar com endpoint de criação de utilizador ou remover tela.
- ✅ **Concluído (2026-08-11):** Ecrã removido por completo (ver item 11) — era inatingível por qualquer navegação e a sua única lógica de negócio (`PosStore.registarOperador`) só gravava em memória, sem ligação real ao ERP.

#### 19. `NotificacoesActivity` exibe notificações hardcoded
- **Arquivo:** `NotificacoesActivity.kt` (~26–33)
- **Descrição:** Lista fixa de notificações; não consome endpoint nem FCM.
- **Impacto:** Notificações reais nunca aparecem.
- **Sugestão:** Criar entidade Room para notificações; consumir endpoint/broadcast push.
- ✅ **Concluído (2026-08-11):** Nova tabela Room `notificacoes` (migração v11→v12); `PayCoreFirebaseMessagingService.onMessageReceived` passou a persistir cada push recebido e a mostrar uma notificação Android real (com guarda de permissão `POST_NOTIFICATIONS`, Android 13+); `NotificacoesActivity` lê da Room em vez da lista hardcoded. Não existe endpoint no backend para *listar* notificações (só `POST notificacoes/broadcast`, que é para enviar), por isso "reais" aqui significa os pushes efectivamente recebidos pelo aparelho, não um histórico sincronizado do servidor.

#### 20. `ComprovativoActivity` permite voltar para `PagamentoActivity`
- **Arquivo:** `ComprovativoActivity.kt` (~51–55)
- **Descrição:** Não limpa a pilha de atividades; ao pressionar voltar, retorna a `PagamentoActivity` com venda já concluída.
- **Impacto:** Risco de pagamento duplicado/confusão do operador.
- **Sugestão:** Usar `FLAG_ACTIVITY_CLEAR_TOP` ou chamar `finish()` em `PagamentoActivity` ao abrir comprovante.

#### 21. `DetalheTransacaoActivity` não atualiza estado local após devolução parcial
- **Arquivo:** `DetalheTransacaoActivity.kt` (~149–172)
- **Impacto:** Usuário vê transação original; nova devolução pode exceder limite.
- **Sugestão:** Atualizar `TransacaoPDVEntity` com novo estado/total e recarregar histórico.

#### 22. Estorno exige rede obrigatoriamente
- **Arquivo:** `EstornoActivity.kt`
- **Descrição:** Valida PIN de supervisor online. Sem internet, não é possível estornar.
- **Impacto:** Operação legítima de estorno bloqueada em condições offline.
- **Sugestão:** Permitir estorno offline com PIN local e sincronizar posteriormente, ou manter PIN de supervisor em cache seguro.

#### 23. `SincronizacaoActivity` só sincroniza catálogo
- **Arquivos:** `SincronizacaoActivity.kt`, `ConfiguracoesActivity.kt`
- **Descrição:** Botão "Logs/Sync" abre tela que só sincroniza produtos/categorias, não vendas/sessões/estornos pendentes.
- **Impacto:** Operador não tem visibilidade/controle sobre fila de vendas pendentes.
- **Sugestão:** Adicionar sincronização manual de sessões/vendas/estornos e listar pendentes.

#### 24. `SplashActivity` tem race condition com `PosStore.init`
- **Arquivos:** `SplashActivity.kt` (~35–39), `PosStore.kt` (~203–233)
- **Descrição:** `PosStore.init` inicia `Thread` para carregar sessão. `SplashActivity.onCreate` pode executar antes da Thread terminar.
- **Impacto:** Usuário com sessão salva pode ser enviado a `LoginActivity` desnecessariamente.
- **Sugestão:** Usar corrotina suspensa ou callback de inicialização antes do routing.

---

### 🟡 Médio

#### 25. `ProdutosActivity` e `ClientesActivity` são telas vazias/placeholders
- **Arquivos:** `ProdutosActivity.kt`, `ClientesActivity.kt`
- **Sugestão:** Implementar ou remover do menu.

#### 26. `DashboardActivity` não indica status da sessão de caixa
- **Arquivo:** `DashboardActivity.kt` (~54–61)
- **Impacto:** Operador não sabe se precisa abrir caixa antes de vender.
- **Sugestão:** Adicionar indicador "Caixa aberta/fechada".

#### 27. `NovaVendaActivity` não recarrega catálogo em `onResume`
- **Arquivo:** `NovaVendaActivity.kt` (~90–96)
- **Impacto:** Se o catálogo for sincronizado em background, a UI não atualiza.
- **Sugestão:** Recarregar `carregarCatalogoAsync` em `onResume` ou observar mudanças.

#### 28. `ScannerActivity` não solicita permissão de câmera de forma robusta
- **Arquivo:** `ScannerActivity.kt`
- **Descrição:** Depende da biblioteca Zxing mostrar diálogo; não há launcher de permissão na activity.
- **Impacto:** Em alguns cenários de negação, não há fallback.
- **Sugestão:** Implementar `RequestPermission` launcher e guiar usuário às configurações.

#### 29. `LoginTerminalActivity` bloqueia botão voltar
- **Arquivo:** `LoginTerminalActivity.kt` (~336–339)
- **Impacto:** Usuário não pode voltar a `SelecaoModoActivity`.
- **Sugestão:** Permitir voltar com confirmação.

#### 30. `SincronizacaoManager` roda em `Thread` não gerenciada
- **Arquivo:** `SincronizacaoManager.kt` (~93–188)
- **Impacto:** Possível vazamento se activity for destruída; uso de `runBlocking` dentro de thread.
- **Sugestão:** Usar corrotina com `lifecycleScope`/`viewModelScope`.

#### 31. Endpoint de descontos pode não existir no backend
- **Arquivos:** `ApiModels.kt` (~268–270), `AdminDescontosActivity.kt`
- **Descrição:** Comentário indica que entidade autônoma de descontos POS ainda não existe no backend.
- **Impacto:** Gestão de descontos quebrada.
- **Sugestão:** Confirmar existência do endpoint no Nexora; desabilitar tela se não existir.

#### 32. `RemoteImageLoader` não tem cache em disco (só memória)
- **Arquivo:** `RemoteImageLoader.kt`
- **Impacto:** Imagens são baixadas repetidamente.
- **Sugestão:** Usar Coil/Glide ou adicionar cache em disco.

#### 33. `PayCoreApp` não registra token FCM existente após login
- **Arquivo:** `PayCoreApp.kt` (~34–41)
- **Descrição:** Obtém token apenas para log; `onNewToken` só dispara quando token muda.
- **Impacto:** Após login, token pode não ser enviado ao backend até reinstall/refresh.
- **Sugestão:** Enviar token após login bem-sucedido e configuração de terminal.

---

### 🟢 Baixo

#### 34. Logging de HTTP Body em produção
- **Arquivo:** `ApiClient.kt` (~142–144)
- **Impacto:** Vazamento de dados sensíveis em logs.
- **Sugestão:** Usar `BODY` apenas em debug; `HEADERS` ou `NONE` em release.
- ✅ **Concluído (2026-08-11):** `loggingInterceptor` passou a usar `Level.BODY` só quando `BuildConfig.DEBUG`; `Level.NONE` em release — nenhum log de HTTP (incl. tokens nos headers) em builds de produção.

#### 35. `allowBackup=true` pode expor dados
- **Arquivo:** `AndroidManifest.xml` (~linha 20)
- **Impacto:** Backup de tokens/sessão para Google Drive.
- **Sugestão:** Desabilitar backup ou excluir prefs/room do backup.
- ✅ **Concluído (2026-08-11):** `android:allowBackup="false"` no manifesto; os ficheiros `backup_rules.xml`/`data_extraction_rules.xml` (boilerplate sem regras reais) foram removidos por ficarem órfãos.

#### 36. SharedPreferences fragmentadas
- **Arquivos:** `ApiClient.kt`, `PosStore.kt`, `LoginTerminalActivity.kt`, `TerminalTokenManager.kt`
- **Impacto:** Dificulta manutenção e pode causar inconsistência de estado.
- **Sugestão:** Centralizar em repositório de sessão.

#### 37. Uso de `Thread {}.start()` sem nome/tratamento de exceção
- **Arquivo:** `PosStore.kt` (~217–232)
- **Sugestão:** Substituir por corrotina com `SupervisorJob`.

#### 38. `AdminInicioActivity` e outras admin bloqueiam `onBackPressed`
- **Sugestão:** Permitir navegação ou mostrar confirmação.

#### 39. Código em português misturado com inglês em nomes de classes/variáveis
- **Sugestão:** Padronizar (ex.: todas as entidades/activities em inglês ou em português).

---

## 4. Problemas Arquiteturais Transversais

1. **Singletons com múltiplas responsabilidades:** `PosStore` faz cache em memória, acesso a banco, formatação, sync, permissões e lógica de venda. Deveria ser dividido em `CatalogRepository`, `SessionRepository`, `SaleRepository`, `SyncRepository`.
   - ⚠️ **Parcialmente concluído — Fase 1 (2026-08-11):** `CatalogRepository` e `SaleRepository` extraídos do `PosStore`, com `SincronizacaoManager` a passar a fetcher puro (Room/rede → dados), sem chamar de volta para dentro do `PosStore` — resolvido o ciclo `PosStore ↔ SincronizacaoManager`.
   - ⚠️ **Parcialmente concluído — Fase 2 (2026-08-11):** `SessionRepository` extraído (tenant/terminal/operador/permissões — `temPermissao`/`temPermissaoAdmin`/`atualizarPermissoes`/`sincronizarSessaoApi`/etc.), o bloco de maior risco (`PermissaoHelper` tem ~25 ficheiros a jusante, mas só 7 pontos de chamada internos, que foram os únicos a mudar — os 25 importadores ficaram intocados). Mesma mitigação de ciclo da Fase 1: `SessionRepository` não importa `LoginTerminalActivity`, duplica as chaves de prefs localmente. `logoutFuncionario()`/`logout()`/`verificarTrocaTenant()` ficam no `PosStore` por serem orquestração transversal (tocam carrinho + caixa + auth).
   - **Continua pendente (Fase 3):** `CashSessionRepository` (abertura/fecho de caixa), `TransactionRepository` (histórico/sync de vendas), `SyncRepository` (orquestração `SincronizacaoManager`/`SyncWorker`), e corrigir a dependência inversa `ApiClient → LoginActivity`.
2. **Estado duplicado:** Listas em memória (`transacoes`, `produtos`, `categorias`) coexistem com Room. Risco de divergência. **Ainda por fazer** — não fez parte de nenhuma das duas fases do refactor.
3. **Ausência de ViewModel:** Activities acessam repositories diretamente em `lifecycleScope`, dificultando testes e lifecycle.
   - ⚠️ **Parcialmente concluído (2026-08-11):** Primeiros `ViewModel`s do projecto — `NovaVendaViewModel`/`PagamentoViewModel`, já em uso em `NovaVendaActivity`/`PagamentoActivity` (dependência `androidx.lifecycle:lifecycle-viewmodel-ktx` adicionada). `PedidosActivity` chama `SaleRepository` directamente (baixo risco, um ficheiro, sem ViewModel dedicado). As restantes activities continuam a aceder repositories/`PosStore` directamente.
4. **Fluxo offline/online frágil:** Não há máquina de estados clara para vendas/sessões pendentes; erros são engolidos por `runCatching`.
   - ✅ **Concluído (2026-08-11):** Ver detalhe no achado nº10 (`SyncStatus` + registo de tentativas/erro + UI de pendências).
5. **Integração backend não uniforme:** Parte do código ainda reflete backend Node antigo (fixtures, endpoints comentados, campos camelCase vs snake_case). **Ainda por fazer** — não foi escolhido para esta ronda.
6. **Permissões cacheadas sem revalidação periódica:** `permissoesEstaoDesactualizadas` existe, mas é usada apenas no estorno.
   - ✅ **Concluído (2026-08-11):** `SessionRepository.revalidarPermissoesSeNecessario()` (melhor esforço, só chama `meAcesso()` se a cache já estiver desactualizada) ligado ao `SyncWorker`, que já corre a cada 15 min + em reconexão — deixou de depender só do ponto único em `EstornoActivity` ou de um 403 reactivo.

---

## 5. Recomendações Prioritárias

### Imediatamente (Crítico)
- [x] Remover catálogo fixture da produção ou bloquear venda de produtos não numéricos. *(concluído 2026-08-11)*
- [x] Corrigir filtros de data/sessão em totais do dashboard e fecho de caixa. *(concluído 2026-08-11)*
- [x] Adicionar campo `ativo` e `stock` em `ProdutoEntity` e respeitá-los na venda. *(concluído 2026-08-11 — `ativo` totalmente activo; `stock` implementado e a bloquear vendas, mas inerte até o backend Nexora expor um campo de inventário)*
- [x] Validar expiração de token e redirecionar para login quando refresh falhar. *(concluído 2026-08-11)*

### Curto Prazo (Alto)
- [ ] Implementar 2FA.
- [ ] Integrar pagamentos eletrônicos ou adicionar confirmação manual.
- [ ] Corrigir refresh de token do terminal com `expiresIn` real.
- [ ] Adicionar rollback em criação de produto.
- [ ] Atualizar estado local após devoluções/estornos.

### Médio Prazo (Médio/Baixo)
- [x] Refatorar `PosStore` em repositories especializados com ViewModel. *(Fase 1+2 concluídas 2026-08-11 — Catalog/Sale/SessionRepository + primeiros ViewModels; Caixa/Transações/Sync ficam para uma Fase 3, ver secção 4)*
- [x] Implementar tela de notificações real. *(concluído 2026-08-11)*
- [x] Melhorar UX dos formulários admin com dropdowns. *(concluído 2026-08-11)*
- [x] Remover dead code (`RegistroActivity`, `AtivacaoLicencaActivity` se não integrada). *(concluído 2026-08-11 — `RegistroActivity` removida, `AtivacaoLicencaActivity` integrada no fluxo)*
- [x] Adicionar logs seguros e desabilitar backup. *(concluído 2026-08-11)*

---

## 6. Conclusão

A maior ameaça atual é a **venda de produtos fixture/demos que nunca sincronizam**, seguida pela **ausência de controle de stock e filtros de data/sessão incorretos**, que podem gerar perdas financeiras reais e inconsistências entre caixa e backend. A correção imediata desses itens críticos é essencial antes de colocar o aplicativo em produção.
