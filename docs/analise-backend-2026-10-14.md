# Análise do backend Nexora — 14/10/2026

## Alcance e método

Inventário e pesquisa estática sobre todo o código Go próprio de `backend`, seguidos de leitura dirigida dos pontos de entrada, configuração, autenticação, autorização, WebSocket, pagamentos, jobs, armazenamento, assiduidade offline e trechos dos módulos de negócio. Este documento não representa uma validação funcional exaustiva de cada função, nem uma auditoria do ambiente de produção.

Foram contabilizados **437 ficheiros Go, 86 629 linhas e 59 ficheiros de testes**, excluindo `third_party` e a cache. As linhas incluem comentários e testes. Existem **33 módulos de negócio** e **57 migrações SQL ativas de subida**, além do arquivo histórico. Não foram executadas migrações, scripts administrativos nem pedidos ao banco configurado na aplicação. Credenciais encontradas no código não são reproduzidas aqui.

## Arquitetura

O sistema é um monólito modular em Go, módulo `nexora`, com Go 1.25 declarado. `main.go` carrega configuração, valida parte dos segredos, cria a pool PostgreSQL, inicializa armazenamento e jobs/MQTT opcionais e serve o router Chi. `cmd/worker` permite executar os jobs separadamente.

O router central instancia handlers e adaptadores. Os módulos usam PostgreSQL através de pgx, frequentemente com SQL diretamente nos handlers; RH e gestão escolar também têm serviços e modelos. `internal/shared/contracts` define portas de integração entre módulos e `internal/shared/adapters` implementa-as. Existem tokens HS256 e RS256, sessões persistidas, memberships, RBAC e validação do host do tenant. As integrações incluem MinIO, Firebase, AWS SES, gateway Nexora Pay, FaceClock, MQTT e assinatura PDF com uma dependência modificada localmente.

## Problemas prioritários

### 1. Credenciais PostgreSQL incorporadas na configuração — alta

**Referência:** `backend/config/config.go:223`.

O fallback de `DATABASE_URL` contém utilizador, password e um host remoto concreto, com `sslmode=disable`. Uma execução sem a variável pode tentar ligar a esse servidor. `AssertProductionSecrets` não rejeita este DSN. A validade atual das credenciais e a exposição do servidor não foram verificadas.

**Recomendação:** remover o segredo do código, exigir `DATABASE_URL`, usar uma base local explícita em desenvolvimento e avaliar a rotação da credencial exposta. Para ligações remotas, configurar TLS com validação adequada.

### 2. Callbacks financeiros sem autenticação quando o segredo está vazio — alta

**Referências:** `backend/internal/modules/pos/handlers/pagamentos.go:184`, `backend/internal/modules/gestao-escolar/handlers/operacoes.go:95`, `backend/config/config.go:251`; contexto de implantação em `docker-compose.yml:22`.

Ambos os callbacks são públicos e só verificam HMAC quando `GatewayWebhookSecret != ""`. O segredo tem fallback vazio e o Compose permite esse valor. No POS, um ID de transação conhecido permite que o payload recebido siga para `ProcessCallback` e atualize a intenção e a confirmação. A deduplicação de eventos não autentica a origem.

**Recomendação:** recusar callbacks quando o segredo não estiver configurado e exigir a assinatura; validar a configuração de pagamentos em produção. Verificar os dados financeiros contra a intenção persistida e testar assinaturas ausentes/incorretas.

### 3. Reposição e alteração de password ignoram erros — alta

**Referências:** `backend/internal/modules/auth/handlers/auth.go:833`, `:903`, `:928`.

`ChangePassword` e `ResetPassword` ignoram o erro de `bcrypt.GenerateFromPassword` e das escritas SQL. O input valida apenas o comprimento mínimo; uma password com mais de 72 bytes pode fazer o bcrypt falhar e produzir um hash vazio que é enviado ao UPDATE. O endpoint pode responder sucesso apesar de falhas de persistência ou revogação de sessões.

`ResetPassword` também lê o token e efetua três escritas separadas, sem transação nem consumo condicional: dois pedidos concorrentes podem validar o mesmo token antes de qualquer um marcar `usado_em`.

**Recomendação:** tratar o erro de hash, limitar a password em bytes segundo o algoritmo e executar consumo do token, atualização da password e revogação numa transação. Usar bloqueio ou UPDATE condicional com RETURNING para assegurar uso único. Só confirmar sucesso após commit.

### 4. Participantes de chat não são validados contra o tenant — alta

**Referências:** `backend/internal/modules/self-service/handlers/chat.go:73`, `:99`, `:118`; `backend/internal/ws/client.go:279`; baseline SQL `:4856` e `:9325`.

`CriarConversa` aceita IDs de participantes e insere-os sem verificar membership ativa na empresa do criador. A baseline tem FKs separadas para conversa e utilizador, sem vínculo composto ao tenant. Os acessos a mensagens e o WebSocket verificam participação, mas não a empresa da conversa. Um utilizador de outra empresa adicionado por esse fluxo pode satisfazer a verificação de participação.

As inserções de participantes e o commit também ignoram erros, permitindo resposta 201 apesar de rollback.

**Recomendação:** validar todos os participantes contra memberships ativas do tenant, incluir tenant nas verificações de acesso, tratar erros e commit e adicionar testes de duas empresas. Se conversas entre empresas forem desejadas, definir essa autorização explicitamente.

### 5. Presença online é partilhada entre tenants — média

**Referências:** `backend/internal/ws/hub.go:50`, `:58`, `:127`, `:139`; `backend/internal/ws/client.go:113`.

O hub é global: `Register`/`Unregister` difundem presença a todos os clientes e `OnlineUsers` lista todos os IDs ligados. `TenantID` não participa no filtro. Isto expõe IDs e estado online entre empresas; não demonstra por si só divulgação de todas as mensagens.

**Recomendação:** segmentar a presença por tenant e respeitar a membership selecionada, incluindo utilizadores com várias memberships.

### 6. Concorrência no hub pode causar panic ou terminar o processo — alta

**Referência:** `backend/internal/ws/hub.go:90`.

`BroadcastRoom` obtém o mapa da sala sob RLock, liberta-o e depois itera. `JoinRoom`, `LeaveRoom` e `Unregister` podem alterar esse mesmo mapa simultaneamente. Além disso, quando a fila está cheia, `BroadcastRoom` fecha `c.send` sem retirar o cliente ou coordenar os outros emissores. Novos broadcasts ou respostas do cliente podem escrever no canal fechado ou fechá-lo novamente.

Um panic nas goroutines WebSocket não é protegido pelo middleware HTTP `Recoverer`; acesso concorrente fatal a mapas também pode terminar o processo.

**Recomendação:** controlar a iteração e a mutação com sincronização consistente, definir um único responsável pelo encerramento e remover/desligar clientes lentos sem fechar um canal ainda usado por produtores. Validar com `go test -race` e testes de ligação/desligação sob carga.

### 7. IP de origem depende de headers sem fronteira de confiança no código — alta, condicionada à infraestrutura

**Referências:** `backend/internal/router/router.go:191`, `backend/internal/middleware/ratelimit.go:18`, `backend/internal/middleware/superadmin_security.go:38`.

`middleware.RealIP` é global. Rate limiting e allowlist do superadmin usam o `RemoteAddr` resultante. Não existe aqui uma verificação de proxy confiável antes da interpretação de headers de encaminhamento. Se um cliente conseguir controlar os headers preservados pelo proxy, ou aceder diretamente à API, pode manipular o IP considerado.

**Recomendação:** documentar e impor proxies confiáveis, substituir headers no proxy e impedir acesso direto. Testar explicitamente spoofing de `X-Forwarded-For`/`X-Real-IP`. A explorabilidade depende da rede e configuração efetivas.

### 8. Login/PIN/TOTP sem limitação de tentativas na aplicação — alta

**Referências:** `backend/internal/router/router.go:232`, `:258`, `:268`; `backend/internal/modules/auth/handlers/auth.go:164`; `backend/internal/modules/auth/handlers/authcode.go:153`.

As rotas de autenticação lidas não aplicam `RateLimit`; os handlers de password e PIN registam tentativas, mas não impõem bloqueio ou backoff. O PIN tem espaço de busca reduzido e bcrypt aumenta o custo de CPU por tentativa. Não foi confirmado se existe uma proteção equivalente no proxy.

**Recomendação:** limitar por conta e por IP, com backoff e armazenamento partilhado entre réplicas; incluir recuperação de password e OAuth. Evitar bloqueios permanentes que permitam negar serviço a outra conta.

### 9. Worker separado não recebe os segredos que exige — alta, operacional

**Referências:** `backend/cmd/worker/main.go:35`, `backend/config/config.go:188`, `docker-compose.yml:109`.

O worker chama o mesmo `AssertProductionSecrets` da API. O Compose define produção, mas não passa JWT_SECRET, JWT_REFRESH_SECRET, FACIAL_VERIFICATION_SECRET nem as chaves FaceClock exigidas. Uma variável usada para interpolar o Compose não é automaticamente injetada num container. Com a definição lida, o worker falha antes de iniciar os jobs. Também faltam configurações do gateway/Firebase usadas no worker.

**Recomendação:** criar validação específica do worker e passar todas as configurações de que os seus jobs realmente precisam. Verificar API com jobs desligados e worker ligado para evitar ausência de despacho.

### 10. Callback pode fazer regredir um pagamento confirmado — alta

**Referências:** `backend/internal/pkg/nexorapay/service.go:207`, `:397`, `:431`.

`ProcessCallback` aceita eventos distintos de sucesso e de cancelamento. `finalizeIntent` atualiza por ID sem condição sobre o estado anterior. Um callback Cancelled/Expired posterior a Completed pode trocar `confirmed` por `failed`, mantendo `confirmed_at`. A deduplicação por evento não impede eventos diferentes fora de ordem.

**Recomendação:** definir transições legais e estados finais, aplicar UPDATE condicional/bloqueio e testar eventos repetidos, fora de ordem e concorrentes. Um estorno deve ter fluxo próprio, distinto de cancelamento de uma intenção pendente.

### 11. Reenvio de mensagem pode alterar texto de outro participante — média

**Referência:** `backend/internal/ws/client.go:287`.

O UPSERT de mensagens usa conflito em `(conversa_id, client_id)` e executa `DO UPDATE SET conteudo = EXCLUDED.conteudo` sem verificar o autor existente. A participação autoriza o envio, mas não deve autorizar alteração da mensagem de outro autor quando o client_id coincide. Mesmo para o mesmo autor, repetir um evento muda o conteúdo e não é uma deduplicação imutável.

**Recomendação:** limitar a chave de idempotência ao autor e devolver a mensagem já gravada sem modificar o texto; separar edição de mensagens e verificar autoria.

### 12. Limitações operacionais adicionais — média

- `internal/middleware/ratelimit.go:14`: o mapa de IPs nunca remove entradas abandonadas e o limite é por processo. Muitos IPs aumentam memória; múltiplas réplicas multiplicam o limite.
- `internal/ws/client.go:30`: qualquer Origin é aceite. O token ainda é necessário; isto não demonstra acesso anónimo. Validar origens autorizadas.
- `internal/router/router.go:192` e `:221`: o chat aceita token na query e passa pelo logger HTTP; proteger logs/URLs de credenciais, preferindo um ticket WebSocket curto e descartável.
- `internal/ws/client.go:91`: a autenticação do chat só verifica a sessão ativa no estabelecimento; não verifica o estado atual da conta/membership como a API nem revalida a expiração/revogação durante a ligação.
- `internal/db/db.go:11`: inicialização e Ping sem prazo explícito; `/health` apenas retorna status estático (`internal/router/router.go:216`). Separar liveness de readiness e limitar o arranque.
- `main.go:103`: resultado de Shutdown é ignorado; os jobs não têm espera explícita de conclusão antes de fechar a pool.
- `Dockerfile:16`: imagem final sem USER não privilegiado; não foi encontrado `.dockerignore` em backend, apesar de existirem backups e artefactos no contexto de build.

## Manutenção, dados e testes

O router central ultrapassa três mil linhas. Convém mover o registo de rotas para cada módulo preservando a composição de middlewares, com testes de autorização para evitar regressões. A aplicação já possui portas e adaptadores; a extração gradual de lógica transacional dos handlers pode aproveitar essa estrutura.

Valores financeiros aparecem como `float64` em POS, tesouraria e gateway. Isto é um risco de arredondamento, não prova de um saldo incorreto específico. Definir precisão, moeda e arredondamento e usar unidades mínimas/decimal exato nos cálculos críticos.

A pesquisa estática encontrou 420 usos de `json.NewDecoder` no código de produção dos módulos e cinco ocorrências de `MaxBytesReader`. Esses números não demonstram 415 endpoints vulneráveis: existem helpers e outros limites. Mostram a necessidade de verificar uma política comum de tamanho de corpo, profundidade e tamanho de coleções. `ReadTimeout` não limita o número de bytes.

Não foram encontradas políticas RLS nas migrações SQL pesquisadas. O isolamento depende sobretudo do SQL e da autorização da aplicação; isto torna indispensáveis testes de acesso entre tenants. A assinatura digital já usa algumas FKs compostas com tenant, o que pode servir de referência.

As migrações `20260727093000_permissoes_cargos_padrao_finas.up.sql` e `20260727110000_rh_funcionarios_criado_por.up.sql` não têm par down. Isto não impede necessariamente a subida, mas exige explicitar a política de reversão. A ordem entre baseline e migrações anteriores precisa de teste numa base vazia e numa base atualizada; não foi aplicada nesta análise.

Pontos positivos observados: RBAC e escopo nos grupos de rotas; verificação de sessão persistida; enforcement do host do tenant; adaptação transacional de serviços; reserva de notificações com `FOR UPDATE SKIP LOCKED`; inbox para callbacks; armazenamento imutável de evidências; testes de isolamento em empresas/faturação; validação temporal e idempotência na assiduidade offline. Estas proteções são locais, não uma garantia de todo o sistema.

## Inventário dos módulos

Contagens incluem código e testes; “testes” conta ficheiros, não casos nem cobertura. Zero significa ausência de `_test.go` dentro do módulo, não ausência de qualquer teste indireto.

| Módulo | Ficheiros Go | Ficheiros de testes | Linhas |
|---|---:|---:|---:|
| aprovacoes | 5 | 0 | 803 |
| assinatura-digital | 32 | 16 | 5671 |
| assinaturas | 2 | 0 | 218 |
| auditoria | 4 | 0 | 630 |
| auth | 29 | 6 | 5028 |
| centros-custo | 4 | 0 | 598 |
| compras | 6 | 1 | 782 |
| contabilidade | 16 | 0 | 3979 |
| crm | 4 | 0 | 1251 |
| empresas | 6 | 1 | 924 |
| financeiro | 2 | 0 | 345 |
| gestao-clientes | 4 | 0 | 1323 |
| gestao-escolar | 63 | 6 | 11956 |
| gestao-produtos | 3 | 0 | 1455 |
| gestao-stock | 3 | 0 | 1785 |
| hardware | 15 | 2 | 2657 |
| impostos | 3 | 0 | 644 |
| logistica | 2 | 0 | 279 |
| modulo-faturacao | 10 | 2 | 2166 |
| monitoring | 1 | 0 | 60 |
| multi-moeda | 2 | 0 | 195 |
| notifications | 2 | 0 | 294 |
| pessoas | 2 | 0 | 88 |
| pos | 14 | 1 | 4036 |
| recrutamento | 17 | 0 | 4972 |
| recursos-humanos | 58 | 6 | 12786 |
| seguranca | 3 | 0 | 259 |
| self-service | 14 | 2 | 2455 |
| sistema-configuracao | 4 | 0 | 705 |
| superadmin | 11 | 0 | 1725 |
| tarefas | 4 | 0 | 613 |
| tesouraria | 3 | 0 | 352 |
| utilizadores | 11 | 0 | 998 |

Há 23 módulos sem ficheiros de testes próprios. A prioridade deve ser a qualidade dos testes de transações, acesso entre empresas, pagamentos e concorrência, não apenas aumentar a contagem.

## Validação e próximos passos

A primeira tentativa de `go test ./...` falhou por acesso negado à cache global do Go. A nova execução com cache dentro do projeto **passou, com exit code 0**, em todos os pacotes do módulo principal. `TEST_DATABASE_URL` não estava configurada; os testes de integração PostgreSQL foram ignorados, portanto este resultado não valida as migrações numa base real.

Também foi executado `go test ./...` dentro de `third_party/digitorus-pdfsign`, que tem o seu próprio go.mod. **Esta suite falhou, com exit code 1:** `TestCreateSignaturePlaceholder` ainda espera `/adbe.pkcs7.detached`, enquanto o patch local gera `/ETSI.CAdES.detached`; vários testes de assinatura falham ao remover ficheiros temporários ainda abertos no Windows. Os pacotes `cli` e `verify` passaram. A divergência de SubFilter já está documentada em `NEXORA_PATCH.md`; atualizar os testes do fork e corrigir o fecho dos ficheiros, sem reverter automaticamente o comportamento intencional do patch. Estas falhas não demonstram por si só invalidez das assinaturas produzidas pelo backend.

`go vet ./...` no módulo principal **passou, com exit code 0 e sem diagnósticos**. Não foi executado o detector de races nesta revisão; os problemas de concorrência do hub foram identificados pela leitura do código. A cache local criada para os checks foi removida no final.

Ordem recomendada: fechar autenticação dos callbacks e retirar credenciais incorporadas; corrigir passwords e isolamento do chat; corrigir concorrência do hub; garantir o arranque do worker; proteger transições financeiras e IP de origem; depois ampliar testes e dividir o router. Não foram feitas alterações no código funcional.
