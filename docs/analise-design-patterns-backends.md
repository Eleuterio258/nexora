# Design Patterns nos backends do Nexora ERP

Análise de code (2026-09-04) aos dois backends do projecto, com evidências concretas (ficheiro:linha) em vez de suposições genéricas:

- **Backend Go** — `backend/` — monólito modular (~35 módulos em `internal/modules/*`), Nexora ERP.
- **Backend Python** — `assiduidade_system_backend/` — FastAPI + SQLAlchemy, sistema de assiduidade/biometria (FaceClock).

Os dois backends comunicam entre si em runtime (o Python chama o Go via `ERPClient`/`nexora_sdk`), mas foram construídos por equipas/momentos diferentes e usam idiomas distintos — daí padrões diferentes para o mesmo problema (ex.: Outbox existe nos dois, mas com implementações próprias).

---

## 1. Backend Go (`backend/`)

### 1.1 Adapter — Ports & Adapters (Hexagonal), padrão dominante

Documentado explicitamente no próprio código-fonte, não é uma inferência:

```go
// internal/shared/contracts/erp_ports.go:1-8
// Padrão: Ports & Adapters (Hexagonal Architecture).
// O módulo escolar depende apenas destas interfaces; as implementações
// concretas vivem nos adaptadores e são injectadas em runtime.
```

- **Port**: `TreasuryPort` — `internal/shared/contracts/erp_ports.go:18-20` (`RecordReceipt(ctx, TreasuryReceipt) error`), e mais 9 ports (Financial, Accounting, Invoicing, Notification, HR, Client, Approval, SystemConfig, Signature, LegalAudit — `erp_ports.go:18-284`).
- **Adapter concreto**: `internal/shared/adapters/treasury.go:12-22` — `TreasuryAdapter{db *pgxpool.Pool}`, `NewTreasuryAdapter(db)`, `RecordReceipt` faz `INSERT INTO tesouraria.movements`.
- `NotificationAdapter` (`internal/shared/adapters/notification.go:20-46`) vai mais longe: depende de uma interface mínima `DBTX` (não do pool concreto), permitindo correr dentro da transacção do chamador via `NewNotificationAdapterWithTx`.

**Porquê**: o módulo `gestao-escolar` nunca importa `tesouraria`, `contabilidade` ou `financeiro` directamente — só depende das interfaces em `contracts`; o `router.go` é quem liga os adaptadores concretos. Isto evita acoplamento circular entre os ~35 módulos.

### 1.2 Middleware chain (Chain of Responsibility / Decorator)

`internal/router/router.go` usa `go-chi`, compondo decoradores `func(http.Handler) http.Handler`:

```go
// router.go:190-195 (cadeia global)
r.Use(middleware.RealIP)
r.Use(middleware.Logger)
r.Use(middleware.Recoverer)
r.Use(idh.Middleware())
r.Use(cors.Handler(...))
```

```go
// router.go:236-237 (cadeia por grupo de rotas)
r.Group(func(r chi.Router) {
    r.Use(mw.RequireAuth(cfg.JWTSecret, db, oauthKeys), mw.EnforceTenantHost(tenantHosts))
```

Subgrupos aninhados empilham ainda `RequirePermission`/`RequirePermissionAny` (`router.go:247-249, 314-316, 331-333`) e auditoria (`AuditModule`, `router.go:228-229, 264-265, 376-378`). Cada middleware segue a forma padrão de closure, ex. `internal/middleware/auth.go:97-99` e `internal/middleware/ratelimit.go:12-42` (`RateLimit(max, window)`).

### 1.3 Repository — presente só em parte do código (achado importante)

- **Presente**: `internal/modules/gestao-escolar/repositories/*.go` (fee.go, class.go, enrollment.go, teacher.go, grade.go, calendar.go, incident.go, timetable.go, academic_structure.go). Ex.: `fee.go:12-20` — `FeeRepository{db DB}` / `NewFeeRepository(db)`, SQL encapsulado nos métodos.
- **Ausente noutros módulos**: `financeiro` e `auth` acedem à BD directamente nos handlers, sem camada de repositório — `internal/modules/financeiro/handlers/financeiro.go:15,57,90,140,237` (`h.db.QueryRow`/`h.db.Exec` com SQL inline) e `internal/modules/auth/handlers/auth.go:135,178,195,243,266`.

**Conclusão**: o repositório é uma convenção localizada ao módulo escolar, não um padrão aplicado ao projecto inteiro — a maioria dos módulos fala directamente com `*pgxpool.Pool` a partir do handler.

### 1.4 Factory

- `internal/storage/storage.go:84-93` — `New(cfg Config) (Provider, error)` escolhe `NewLocalProvider` ou `NewMinioProvider` por `cfg.Provider` (factory polimórfica real, devolve interface).
- `internal/pkg/antivirus/antivirus.go:32-43` — `New(cfg Config) Verificador` escolhe `clamav` ou `noop{}` (duplica como **Null Object**).
- `internal/modules/auth/oauthkeys.NewProvider(...)`, chamado em `router.go:85`.
- `internal/db/db.go:10-20` — `Connect(dsn string) *pgxpool.Pool`, factory de pool de ligação (criado uma vez em `main.go:29`, distribuído por DI).
- Cada módulo expõe `handlers.New(db, cfg, ...)` como construtor/factory do seu `Handler`.

### 1.5 Singleton — deliberadamente ausente

Não há `sync.Once` em lado nenhum de `backend/` nem globals mutáveis para BD/config/logger. O pool `*pgxpool.Pool` é criado uma vez em `main.go:29-30` e passado por injecção de dependências, não guardado numa variável global. É uma escolha arquitectural — DI em vez de Singleton.

### 1.6 Strategy

- `internal/modules/assinatura-digital/pki/provider.go:29-41` — `SignatureProvider` (dev vs intic), seleccionado em `router.go:118-142` por `cfg.SignatureProvider`.
- `internal/storage/storage.go:37-51` — `Provider` (local vs MinIO).
- `internal/pkg/antivirus/antivirus.go:20-22` — `Verificador` (noop vs clamav).
- `internal/background/jobs.go:27-30,36-39` — `notificationDB`/`pushSender` como interfaces mínimas, permitindo trocar produção por dublês de teste sem alterar a lógica de despacho.

### 1.7 Observer / Pub-Sub / Outbox

- **WebSocket Hub** (broadcaster clássico): `internal/ws/hub.go` — `Hub` (38), `NewHub()` (44), `Register`/`Unregister` (51, 58), `BroadcastRoom` (92), `SendToUser` (106), `BroadcastAll` (127); clientes subscrevem salas via `JoinRoom`/`LeaveRoom` (71, 80).
- **Transactional Outbox**, documentado à parte em [`analise-transactional-outbox-backends.md`](analise-transactional-outbox-backends.md) e implementado em `internal/background/jobs.go`:
  - Claim atómico com `FOR UPDATE SKIP LOCKED` — `jobs.go:311-342` (`claimPendingNotifications`).
  - Lease/timeout para recuperar workers mortos — `jobs.go:243,288-301` (`notificationLeaseTimeout = 5*time.Minute`).
  - O mesmo idioma claim/lease/retry é reaproveitado para reconciliação de pagamentos `nexorapay` (`jobs.go:117-153`) e eventos de hardware (`jobs.go:155-181`).
  - Poller genérico `runInterval(ctx, name, interval, fn)` (`jobs.go:217`) usado para os três fluxos (30s notificações, 2min pagamentos, 1min hardware — `jobs.go:48,55,66`).

### 1.8 Dependency Injection

100% baseada em construtores — sem framework/container de DI.

```go
// main.go:24-80
cfg := config.Load()
pool := db.Connect(...)
store, _ := storage.New(...)
background.StartJobs(ctx, pool, adapters.NewNotificationAdapter(pool), push.New(...), paySvc, ..., cfg, store)
router.New(pool, cfg)
```

`router.New` (`router.go:64,90-180`) constrói ~30 handlers de módulo, cada um via `New(db, cfg, ...)`, injectando instâncias partilhadas (`wsHub`, `pushSvc`, `paySvc`, `store`) e adaptadores. O struct `escolarH.Ports` (`handler.go:31-56`) funciona como um "saco" tipado de dependências (10 ports), permitindo injectar dublês em testes.

### 1.9 Facade

- `escolarH.Ports` agrega 10 ports cross-módulo num único ponto de entrada.
- A pilha de assinatura digital (`router.go:118-172`: `sigProvider`, `chainValidator`, `assDPki.NewPDFSigner`) esconde a complexidade de certificados/cadeia/algoritmo atrás de `PDFSigner.Sign(...)` (`pki/signer.go:51`).

### 1.10 Options / Builder — não encontrado

Sem functional options (`With...`) nem builders fluentes; configuração feita por structs simples passados por valor.

---

## 2. Backend Python (`assiduidade_system_backend/`)

Estrutura: `app/` (routers, services, security, workers, schemas), `nexora_sdk/` (SDK cliente externo). **Não existe** `repositories/` nem um `CRUDBase` genérico — o acesso a dados é feito directamente com `Session` do SQLAlchemy dentro de routers/services.

### 2.1 Dependency Injection — via `Depends()`

- Injecção simples de recursos: `db: Session = Depends(get_db)`, definido em `app/database.py:30-35`; usado em `app/routers/admin.py:42,155,201`, `app/routers/biometric.py:205,233,468`, etc.
- **Factory de dependência parametrizada**: `app/security/nexora_auth.py:166-274` define `_require_nexora_signature(permission) -> Callable`, exposto por `require_nexora_signature(permission)` (277-288):
  ```python
  actor: ActorContext = Depends(require_nexora_signature("biometric:verify"))
  ```
  Esta dependência encadeia outros `Depends`/`Header` (171-178) e chama `get_active_credential(db, ...)` internamente — DI em cadeia router → dependência de auth → acesso a dados.

### 2.2 Repository — não encontrado (achado a documentar como lacuna)

Sem classes `Repository`/`Repo` nem `CRUDBase[Model, CreateSchema, UpdateSchema]`. Acesso a dados inline em `app/routers/*.py` e `app/services/*.py` com `select`/`db.add`/`db.commit` directos (ex.: `app/services/outbox.py:59-82`).

### 2.3 Service layer

`app/services/` separa claramente a lógica de negócio dos routers: `attendance_validation.py`, `audit_log.py`, `biometric.py`, `outbox.py`, `suspicious_activity.py`, `device_registry.py`, `api_credentials.py`, `challenge_store.py`, `liveness_challenge.py`, `face_detectors.py`, `embedding_models.py`, `fingerprint_matching.py`. Os routers orquestram estes serviços em vez de embutir lógica de ML/negócio.

### 2.4 Strategy — o padrão mais forte deste backend

Interfaces `ABC` com implementações intercambiáveis, escolhidas em runtime por variável de ambiente (`Settings`):

| Interface (ABC) | Implementações | Selecção |
|---|---|---|
| `FaceDetector` — `app/services/face_detectors.py:38-42` | `BlazeFaceDetector` (45), `YuNetDetector` (89) | `BIOMETRIC_FACE_DETECTOR` |
| `FaceEmbeddingModel` — `embedding_models.py:26-49` | `FaceNetEmbeddingModel` (62), `ArcFaceEmbeddingModel` (115) | `BIOMETRIC_MODEL` |
| `LivenessModel` — `liveness_models.py:23-28` | `HeuristicLivenessModel` (31), `AntiSpoofingONNXModel` (94) | `LIVENESS_MODEL` |
| `ChallengeStore` — `challenge_store.py:24-34` | `MemoryChallengeStore` (37), `RedisChallengeStore` (74) | `LIVENESS_CHALLENGE_STORE` |
| `SuspiciousActivityStore` — `suspicious_activity.py:29-42` | `MemorySuspiciousActivityStore` (45), `RedisSuspiciousActivityStore` (86) | — |

Nota: o eixo de variação é o algoritmo de reconhecimento/liveness, não drivers de hardware físico — "FaceClock" é o nome do próprio produto/API, não uma abstracção de dispositivo cliente.

### 2.5 Factory (emparelhada com cada Strategy)

Cada módulo de estratégia acima expõe uma factory com `_REGISTRY: dict[str, type[...]]` e cache de instância:
`get_face_detector()` (`face_detectors.py:149-171`), `get_embedding_model()` (`embedding_models.py:168-181`), `get_liveness_model()` (`liveness_models.py:184-201`), `get_challenge_store()`/`get_suspicious_activity_store()` (memoizam singleton em `_store`).

`SessionLocal = sessionmaker(bind=engine, ...)` (`app/database.py:12`) é a factory de `Session`, invocada em `app/workers/outbox.py:33` e `app/main.py:44,136`.

### 2.6 Singleton — manual, sem `lru_cache`

Ao contrário do idioma FastAPI típico (`@lru_cache get_settings()`), aqui `settings = Settings()` é instanciado uma vez no import (`app/config.py:145`) — singleton de módulo genuíno. Mesmo padrão em `engine`/`SessionLocal` (`app/database.py:11-12`) e `erp_client = ERPClient()` (`app/erp_client.py:226`).

### 2.7 Observer / Event-driven — Transactional Outbox

Implementado explicitamente (ver também `docs/analise-transactional-outbox-backends.md`):
- `OutboxEvent` — `app/models.py:93`.
- `enqueue()` escreve o evento **dentro da transacção do chamador, sem commit** — `app/services/outbox.py:35-56`, chamado em `app/routers/biometric.py:359-370` junto da mutação de `FaceTemplate.status`, garantindo atomicidade.
- Worker separado (`app/workers/outbox.py:26-53`) reclama lote com `claim_batch()` (`FOR UPDATE SKIP LOCKED`, `outbox.py:59-82`), entrega via `deliver()` (152-172) a um webhook do ERP Go, e classifica o resultado (`classify_response()`, 98-108) com backoff exponencial + jitter (`backoff_seconds()`, 111-117).

### 2.8 Adapter (duas camadas)

- `nexora_sdk/client.py` — `NexoraClient` (14-102) envolve chamadas `httpx` cruas numa interface de domínio, compondo `BiometricClient`/`AttendanceClient` (linha 38).
- `app/erp_client.py` — `ERPClient` (46-224) adapta `httpx` async ao contrato HTTP do ERP Go, traduzindo erros em excepções de domínio `ERPUnavailableError`/`ERPResponseError` (26-43).
- `app/security/nexora_auth.py` — `NexoraAuth` (61-134) adapta primitivas de assinatura HMAC numa interface reutilizável, partilhada entre servidor e `nexora_sdk/signer.py`.

### 2.9 Unit of Work — ad hoc via `Session`

Sem classe `UnitOfWork` dedicada, mas o conceito é aplicado e testado: `outbox.py:6-10` documenta que `enqueue()` nunca faz commit ("participa da transacção do chamador"), enquanto `claim_batch`/`mark_published`/`mark_retry`/`mark_dead` gerem e fecham a sua própria unidade de trabalho (`outbox.py:81,94-95,125,135,143`), por correrem no worker standalone. Testado em `tests/test_outbox_enqueue.py:16-30`.

### 2.10 Decorator

- Rate limiting com `slowapi`: `limiter = Limiter(...)` (`app/limiter.py:16`), aplicado como decorador `@limiter.limit("20/hour")` em `app/routers/biometric.py:201,229,464` e em `fingerprint.py`/`liveness.py`.
- Middleware ASGI `@app.middleware("http")` — `structured_logging_middleware` (`app/main.py:148-184`), forma padrão de Chain-of-Responsibility via decorador (`await call_next(request)`).
- `@asynccontextmanager lifespan` (`app/main.py:27-54`) — hook de composição da aplicação (arranque/paragem).

### 2.11 Builder — não encontrado

Sem builders fluentes; queries SQLAlchemy construídas directamente (`select(...).where(...).order_by(...).limit(...)`).

### 2.12 State machine — parcial (enum + mutação directa, sem classe State)

`TemplateStatus` (`app/schemas/common.py:25-29`: `ACTIVE`, `REVOKED`, `DELETED`, `PENDING_REENROLL`) e `OutboxEvent.status` (`pending → processing → published/dead`) mudam por atribuição directa de campo (ex. `app/routers/biometric.py:351`), não por uma hierarquia de classes State do GoF — é uma máquina de estados implícita, não o padrão State formal.

---

## 3. Comparação entre os dois backends

| Padrão | Go (`backend/`) | Python (`assiduidade_system_backend/`) |
|---|---|---|
| Adapter | Forte — Ports & Adapters explícito (`erp_ports.go`) | Forte — `ERPClient`, `NexoraClient` (SDK) |
| Repository | Parcial — só no módulo escolar | Ausente — acesso directo via `Session` |
| Service layer | Não é convenção formal (lógica nos handlers) | Forte — `app/services/*` |
| Factory | Forte — `storage.New`, `antivirus.New`, `db.Connect` | Forte — `get_face_detector()` e afins, `sessionmaker` |
| Singleton | Evitado deliberadamente (DI em vez disso) | Presente — `settings`, `engine`, `erp_client` |
| Strategy | Forte — `SignatureProvider`, `storage.Provider`, `Verificador` | Muito forte — 5 ABCs de biometria/liveness |
| Observer/Outbox | Forte — Outbox genérico (notificações, pagamentos, hardware) + WS Hub | Forte — Outbox dedicado a eventos biométricos |
| Dependency Injection | Forte — 100% construtores, sem framework | Forte — `Depends()` do FastAPI |
| Facade | Moderado — `escolarH.Ports`, pilha PKI | Moderado — `NexoraClient` sobre `httpx` |
| Decorator | Middleware chi (`r.Use`) | `slowapi` `@limiter.limit`, middleware ASGI |
| Options/Builder | Não encontrado | Não encontrado |
| State (formal) | Não encontrado | Não encontrado (enum + if/else) |

**Observação transversal**: os dois backends implementam o **mesmo padrão de Outbox transaccional de forma independente e não partilhada** — cada um com o seu modelo `OutboxEvent`/tabela e worker próprio. Isto já estava mapeado em [`analise-transactional-outbox-backends.md`](analise-transactional-outbox-backends.md); esta análise confirma que a escolha do padrão é consistente nos dois lados da integração, mesmo sem código partilhado.

O achado mais relevante para manutenção futura é a **inconsistência do Repository pattern no backend Go**: existe só no módulo `gestao-escolar`, enquanto `financeiro` e `auth` (e provavelmente a maioria dos outros ~33 módulos) acedem à BD directamente nos handlers. Se se quiser generalizar o padrão, o módulo escolar já serve de referência interna.
