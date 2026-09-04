# Análise de viabilidade — Transactional Outbox Pattern

**Data da análise:** 2026-09-03
**Estado:** Fases 0–5 implementadas (2026-09-03/04) — ver secção 19 para o
detalhe por item e secção 36 para os critérios de aceitação revistos contra
o que foi de facto construído e testado nesta implementação.
**Diretórios analisados:**

- `D:\projecto\e-258tech\2026\factPro\assiduidade_system_backend`
- `D:\projecto\e-258tech\2026\factPro\backend`

## 1. Resumo executivo

A implementação do **Transactional Outbox Pattern** é altamente viável e recomendada para os dois backends, mas deve ser aplicada seletivamente.

O maior benefício está nos fluxos em que uma alteração na base de dados precisa provocar, com garantia, um efeito externo posterior:

- webhook do FaceClock para o ERP;
- email e SMS;
- notificações push;
- tarefas atualmente executadas em goroutines;
- integrações externas cujo resultado não precisa ser imediato;
- publicação futura de eventos para outros serviços.

O padrão não deve substituir transações locais nem ser aplicado automaticamente a todas as chamadas HTTP. Operações como verificação facial, enrollment e consultas de configuração precisam de resposta imediata e devem continuar síncronas.

**Viabilidade geral: alta — aproximadamente 8,5/10.**

O projeto já possui parte da infraestrutura necessária no backend Go, através da tabela `notifications.notification_messages` e do dispatcher existente. Contudo, essa implementação ainda não oferece as garantias completas de um outbox transacional.

## 2. Matriz de decisão

| Área | Situação atual | Padrão recomendado |
|---|---|---|
| FaceClock → ERP: re-enrollment | Pode perder o webhook depois do commit | Transactional Outbox no FaceClock |
| Email e SMS | Fila persistente parcial | Evoluir para outbox especializado |
| Push FCM | Envio direto e best-effort | Dispatcher persistente/outbox |
| Goroutines de notificações | Trabalho perdido em reinícios | Eventos persistentes |
| ERP → FaceClock: verify/enroll | Requer resposta imediata | REST síncrono |
| Nexora Pay | Chamada síncrona com resultado potencialmente desconhecido | Intenção persistente, idempotência e workflow/outbox |
| Consumo de prova facial + ponto | Duas escritas locais separadas | Transação PostgreSQL única |
| Consumo de QR + ponto | Duas escritas locais separadas | Transação PostgreSQL única |
| Eventos MQTT/hardware | Inbox parcial sem reprocessamento completo | Inbox persistente + retry |
| WebSocket | Atualização em tempo real não essencial | Best-effort com leitura posterior da BD |

## 3. Arquitetura atual

### 3.1 FaceClock

O `assiduidade_system_backend` é uma aplicação Python/FastAPI que utiliza:

- SQLAlchemy;
- PostgreSQL, com suporte alternativo a SQLite em testes;
- Redis para replay protection e cache;
- chamadas HTTP ao ERP através de `httpx`;
- templates faciais e digitais persistidos localmente;
- auditoria biométrica local.

Cada endpoint recebe uma sessão SQLAlchemy através de `get_db()`. Os commits são executados explicitamente nos handlers e serviços. Não existe atualmente uma tabela de outbox nem um worker persistente de publicação.

### 3.2 Backend ERP

O `backend` é uma aplicação Go que utiliza:

- PostgreSQL através de `pgxpool`;
- handlers HTTP com Chi;
- jobs executados dentro do processo da API;
- AWS SES;
- Twilio ou sender SMS configurável;
- Firebase Cloud Messaging;
- MQTT para terminais;
- HTTP para FaceClock e Nexora Pay;
- storage local ou MinIO.

O ERP já possui `notifications.notification_messages`, com estado, tentativas e data de envio. Essa tabela é uma boa base para um outbox especializado de notificações.

## 4. Principal candidato no FaceClock

O fluxo mais evidente ocorre quando a versão do modelo biométrico muda.

Em `assiduidade_system_backend/app/routers/biometric.py`, aproximadamente nas linhas 346–360, o FaceClock:

1. verifica que o template usa uma versão antiga;
2. altera o estado para `PENDING_REENROLL`;
3. executa `db.commit()`;
4. chama `erp_client.notify_reenroll_required()`.

O método em `assiduidade_system_backend/app/erp_client.py`, aproximadamente a partir da linha 186, é deliberadamente best-effort. Uma falha de rede só produz um log e não volta a colocar o evento numa fila.

Existe, portanto, a seguinte janela de perda:

```text
UPDATE do template
        ↓
COMMIT confirmado
        ↓
processo termina ou ERP fica indisponível
        ↓
webhook não é entregue
```

Como o envio só ocorre na primeira transição para `PENDING_REENROLL`, uma nova verificação pode não recriar a notificação. O template permanece desatualizado e o colaborador pode nunca receber o aviso.

### 4.1 Transação recomendada

```text
BEGIN
  UPDATE face_templates
     SET status = 'PENDING_REENROLL'
   WHERE id = ...;

  INSERT INTO outbox_events (
      id,
      tenant_id,
      event_type,
      aggregate_type,
      aggregate_id,
      payload,
      status,
      available_at,
      created_at
  ) VALUES (...);
COMMIT
```

Depois do commit, um worker independente envia o evento ao ERP. Se a rede ou o ERP falharem, a linha continua pendente e será reenviada.

### 4.2 Evento inicial recomendado

```json
{
  "event_id": "uuid",
  "event_type": "biometric.reenroll_required.v1",
  "occurred_at": "2026-09-03T10:00:00Z",
  "tenant_id": "123",
  "aggregate_type": "face_template",
  "aggregate_id": "template-uuid",
  "data": {
    "erp_user_id": "456",
    "old_model_version": "v1",
    "new_model_version": "v2"
  }
}
```

O payload não deve incluir embeddings, imagens, JWTs, chaves de API ou outros dados biométricos sensíveis.

## 5. Estado atual das notificações no ERP

A tabela `notifications.notification_messages`, definida em `backend/migrations/20260724080001_baseline_schema.up.sql`, aproximadamente na linha 4195, contém:

- `status`;
- `tentativas`;
- `erro`;
- `enviado_em`;
- payload e referência de origem.

Isso é semelhante a um outbox de entrega, mas há limitações importantes.

### 5.1 A inserção não é transacional com o negócio

Em `backend/internal/shared/adapters/notification.go`, o método `Send()` utiliza diretamente `pgxpool.Pool`.

Consequências:

- a operação de negócio pode confirmar e a inserção da notificação falhar;
- a falha é apenas escrita no log;
- o chamador não consegue incluir a notificação na própria transação;
- não existe garantia de que “negócio confirmado” implique “mensagem persistida”.

O adaptador precisa aceitar `pgx.Tx` ou uma interface comum implementada por `pgx.Tx` e `pgxpool.Pool`.

Exemplo conceitual:

```go
type DBTX interface {
    Exec(context.Context, string, ...any) (pgconn.CommandTag, error)
    QueryRow(context.Context, string, ...any) pgx.Row
}

func EnqueueNotification(ctx context.Context, q DBTX, n Notification) error
```

Assim, o handler pode inserir a entidade de negócio e a notificação antes do mesmo `Commit()`.

### 5.2 Reserva concorrente incompleta

Em `backend/internal/background/jobs.go`, aproximadamente nas linhas 121–128, o dispatcher executa:

```sql
SELECT ...
FROM notifications.notification_messages
WHERE status = 'pendente'
FOR UPDATE SKIP LOCKED
```

Porém, não existe uma transação explícita que mantenha ou transforme essas linhas numa reserva persistente. Com várias réplicas, mais de um worker pode selecionar a mesma mensagem depois de a instrução terminar.

O worker deve reservar as linhas dentro de uma transação curta:

```sql
WITH candidates AS (
    SELECT id
      FROM integration.outbox_events
     WHERE status = 'pending'
       AND available_at <= NOW()
     ORDER BY created_at
     LIMIT 50
     FOR UPDATE SKIP LOCKED
)
UPDATE integration.outbox_events o
   SET status = 'processing',
       locked_at = NOW(),
       locked_by = $1
  FROM candidates c
 WHERE o.id = c.id
 RETURNING o.*;
```

O envio HTTP/SES/FCM deve acontecer depois do commit dessa reserva, sem manter uma transação aberta durante chamadas externas.

### 5.3 Retry insuficiente

O dispatcher atual:

- limita-se a três tentativas;
- não utiliza backoff exponencial;
- não possui `available_at`;
- não considera `Retry-After`;
- não possui dead-letter operacional separada;
- não implementa lease e recuperação de mensagens abandonadas;
- descarta alguns erros de atualização de estado.

### 5.4 Possibilidade de duplicação

Mesmo com um outbox correto, existe esta janela:

```text
provider aceita a mensagem
          ↓
worker termina antes de marcar como publicada
          ↓
mensagem é reenviada
```

Por isso, a garantia real é **at-least-once**, não exactly-once. O consumidor ou provider deve aceitar uma chave idempotente baseada no `event_id`.

## 6. Goroutines frágeis

Foram identificadas goroutines iniciadas diretamente por handlers em fluxos como:

- publicação de comunicados escolares;
- publicação de notas;
- confirmação de pagamentos escolares;
- notificações de matrículas;
- criação automática de funcionário a partir de professor;
- outras tarefas secundárias.

Essas goroutines não sobrevivem a:

- reinício do container;
- término do processo;
- deployment;
- panic;
- timeout interno;
- indisponibilidade temporária da base de dados.

Para notificações, devem ser substituídas por inserções transacionais em `notification_messages` ou no outbox genérico.

Para operações entre módulos que usam a mesma base de dados, como criar professor e funcionário RH, deve-se preferir:

1. uma única transação local; ou
2. um workflow persistente, quando a operação precisar realmente ser assíncrona.

Não há vantagem em simular uma arquitetura distribuída entre módulos que partilham o mesmo PostgreSQL.

## 7. Push FCM

Em `backend/internal/push/push.go`, o envio é síncrono e best-effort:

- falhas são apenas registadas em log;
- o chamador não recebe o resultado;
- não há retry persistente;
- não existe correlação entre o evento de negócio e a entrega.

Em `backend/internal/modules/notifications/handlers/notificacoes.go`, a API pode enviar push antes de inserir a linha de histórico. Isso permite situações como:

- push entregue, mas histórico não gravado;
- envio falhou, mas mensagem marcada como enviada;
- credenciais FCM ausentes e operação considerada concluída.

Recomendação:

1. gravar primeiro a mensagem com estado `pending`, dentro da transação;
2. o worker procurar os tokens do destinatário;
3. enviar por FCM;
4. persistir o resultado por token ou por mensagem;
5. remover tokens inválidos;
6. aplicar retry apenas aos erros transitórios.

## 8. Webhook recebido pelo ERP

O endpoint `NotificarReenrollDevice`, em `backend/internal/modules/recursos-humanos/handlers/biometria_reenroll.go`, executa separadamente:

1. inserção em `auditoria.audit_logs`;
2. inserção em `notif_colaborador`.

Se a segunda escrita falhar, a auditoria fica criada, mas o utilizador não é avisado.

O `WHERE NOT EXISTS` reduz duplicações funcionais, mas não é suficiente contra concorrência sem uma restrição única adequada. A auditoria também pode ser duplicada em retries.

O endpoint deve:

```text
BEGIN
  INSERT integration.inbox_events ON CONFLICT DO NOTHING
  se já existia: devolver sucesso idempotente
  INSERT auditoria.audit_logs
  INSERT notif_colaborador ou notification_messages
COMMIT
```

A chave única recomendada é:

```text
UNIQUE(source_service, event_id)
```

## 9. Fluxos que precisam de transação local, não outbox

### 9.1 Prova facial e marcação de ponto

Em `backend/internal/modules/self-service/handlers/facial_verification.go`, o comprovativo facial é marcado como consumido em `rh.facial_verification_uses`.

Depois, `backend/internal/modules/self-service/handlers/ponto.go` chama `RegistarEvento()` para criar o ponto.

Se a inserção do ponto falhar depois de consumir o comprovativo, o utilizador fica com uma prova usada sem ter o ponto registado.

As duas operações devem utilizar a mesma `pgx.Tx`.

### 9.2 QR e marcação de ponto

O QR também é validado/consumido antes da inserção final do evento. O consumo do token e a criação do ponto devem ser atómicos.

### 9.3 Evento e auditoria

Em `backend/internal/modules/recursos-humanos/service/assiduidade/eventos.go`, o evento de assiduidade é inserido e, depois, `RegistarAuditoria()` é chamado separadamente.

Para auditoria obrigatória, ambas as escritas precisam estar na mesma transação. Um outbox só seria necessário se essa auditoria fosse enviada a outro sistema.

## 10. Hardware e MQTT: padrão Inbox

O `Processor.Process()` em `backend/internal/modules/hardware/service/processor.go` primeiro insere `hardware.device_events` com deduplicação por `event_hash` e depois cria o evento oficial de assiduidade.

Essa tabela funciona como uma **Inbox parcial**:

- guarda o evento bruto;
- possui idempotência;
- guarda o resultado de processamento;
- permite saber que um evento falhou.

Entretanto, não foi identificado reprocessamento automático das linhas que permanecem não processadas.

Recomendação:

- adicionar `attempts`, `available_at`, `locked_at` e `last_error`;
- criar worker de reprocessamento;
- diferenciar erro permanente de erro transitório;
- não confirmar a mensagem MQTT antes da persistência local quando a biblioteca/protocolo permitir;
- manter `event_hash` ou introduzir um `event_id` gerado no dispositivo.

Este fluxo é de entrada e deve ser tratado como Inbox, não como Outbox.

## 11. Chamadas ERP → FaceClock

As operações abaixo precisam de resposta imediata e devem continuar síncronas:

- verificação facial;
- liveness challenge/verify;
- enrollment facial;
- enrollment e identificação de impressão digital;
- consulta de configuração e consentimento.

Transformá-las em outbox mudaria o contrato da API para assíncrono e obrigaria a introduzir:

- estado `pending`;
- polling ou WebSocket para o resultado;
- expiração;
- cancelamento;
- compensação;
- uma experiência de utilização diferente.

O outbox só deve ser usado nesses fluxos caso o produto aceite explicitamente um comando assíncrono.

## 12. Nexora Pay

As chamadas ao Nexora Pay usam `Idempotency-Key`, o que é positivo. Contudo, em alguns fluxos a chave é gerada a partir da hora atual.

Se o cliente repetir a operação mais tarde, uma nova chave pode ser produzida e o provider pode interpretar o pedido como outro pagamento.

O desenho recomendado é:

```text
BEGIN
  INSERT payment_intent (
      operation_id,
      idempotency_key,
      status='pending'
  )
  INSERT outbox_event payment.requested
COMMIT
```

O `idempotency_key` deve ser estável e derivado de um identificador persistido, nunca de `time.Now()` a cada tentativa.

Para uma primeira fase, é possível manter a chamada síncrona, desde que:

- a intenção seja persistida antes da chamada;
- a mesma chave seja reutilizada em retries;
- timeouts resultem em estado `unknown`, não em falha definitiva;
- exista reconciliação por consulta ou webhook;
- callbacks sejam processados através de Inbox idempotente.

## 13. Arquitetura recomendada

Como FaceClock e ERP usam bases de dados diferentes, cada serviço deve possuir o seu próprio outbox.

```text
┌──────────────────────────────┐
│ PostgreSQL FaceClock         │
│                              │
│ face_templates               │
│ biometric_audit_logs         │
│ outbox_events                │
└──────────────┬───────────────┘
               │ polling
               ▼
┌──────────────────────────────┐
│ FaceClock Outbox Worker      │
└──────────────┬───────────────┘
               │ HTTP + HMAC + event_id
               ▼
┌──────────────────────────────┐
│ ERP Inbox Endpoint           │
│ integration.inbox_events     │
└──────────────────────────────┘

┌──────────────────────────────┐
│ PostgreSQL ERP               │
│                              │
│ tabelas de negócio           │
│ integration.outbox_events    │
│ notification_messages        │
└──────────────┬───────────────┘
               │ polling
               ▼
┌──────────────────────────────┐
│ ERP Delivery Workers         │
│ SES / SMS / FCM / HTTP       │
└──────────────────────────────┘
```

## 14. Tabela genérica recomendada

Exemplo conceitual PostgreSQL:

```sql
CREATE TABLE integration.outbox_events (
    id UUID PRIMARY KEY,
    tenant_id BIGINT,
    event_type VARCHAR(120) NOT NULL,
    aggregate_type VARCHAR(80) NOT NULL,
    aggregate_id VARCHAR(100) NOT NULL,
    schema_version INTEGER NOT NULL DEFAULT 1,
    payload JSONB NOT NULL,
    headers JSONB NOT NULL DEFAULT '{}'::jsonb,
    deduplication_key VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    attempts INTEGER NOT NULL DEFAULT 0,
    available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    locked_at TIMESTAMPTZ,
    locked_by VARCHAR(100),
    published_at TIMESTAMPTZ,
    last_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_outbox_deduplication UNIQUE (deduplication_key),
    CONSTRAINT ck_outbox_status CHECK (
        status IN ('pending', 'processing', 'published', 'dead', 'cancelled')
    )
);

CREATE INDEX idx_outbox_pending
    ON integration.outbox_events (available_at, created_at)
    WHERE status = 'pending';

CREATE INDEX idx_outbox_expired_leases
    ON integration.outbox_events (locked_at)
    WHERE status = 'processing';
```

No FaceClock, `tenant_id` pode continuar como `VARCHAR(36)` para respeitar o modelo atual.

## 15. Semântica de entrega

A garantia deve ser documentada como **at-least-once**.

### 15.1 Respostas HTTP

| Resultado | Ação do worker |
|---|---|
| `200`, `201`, `202`, `204` | Marcar como publicado |
| `409` por evento duplicado | Considerar publicado |
| `408`, `425`, `429` | Retry |
| `500`, `502`, `503`, `504` | Retry |
| Outros `4xx` | Dead-letter ou falha permanente |
| Timeout/conexão interrompida | Retry com a mesma chave |

### 15.2 Backoff

Sugestão inicial:

```text
30 segundos
1 minuto
2 minutos
5 minutos
10 minutos
30 minutos
1 hora
3 horas
6 horas
12 horas
```

Aplicar jitter para impedir que várias instâncias reenviem tudo ao mesmo tempo.

### 15.3 Leases

Uma mensagem `processing` com `locked_at` antigo deve voltar a `pending`. Isso recupera trabalho abandonado quando um worker termina durante o envio.

## 16. Broker de mensagens

Não é recomendada a introdução imediata de Kafka ou RabbitMQ.

O PostgreSQL atual é suficiente porque:

- já é dependência obrigatória dos dois serviços;
- o volume esperado de eventos é moderado;
- reduz a complexidade operacional;
- `FOR UPDATE SKIP LOCKED` permite múltiplos workers;
- o padrão pode publicar num broker posteriormente sem alterar os produtores.

Um broker passa a ser justificável quando houver:

- muitos consumidores independentes;
- volume muito elevado;
- retenção longa de eventos;
- necessidade de replay em massa;
- ordenação por partição;
- equipas independentes consumindo eventos.

## 17. Segurança e privacidade

O outbox deve respeitar os seguintes limites:

- nunca guardar embedding facial;
- nunca guardar template de impressão digital;
- nunca guardar imagem base64;
- nunca guardar JWT ou verification token;
- nunca guardar API keys ou segredos HMAC;
- guardar somente IDs e metadados mínimos;
- cifrar dados sensíveis residuais quando necessário;
- aplicar política de retenção;
- impedir acesso cross-tenant;
- sanitizar `last_error`, pois respostas externas podem conter dados sensíveis.

Para eventos biométricos, recomenda-se retenção curta dos eventos publicados, por exemplo 30 dias, mantendo somente auditoria legal necessária pelo prazo aplicável.

## 18. Observabilidade

Métricas mínimas:

```text
outbox_pending_total
outbox_processing_total
outbox_dead_total
outbox_oldest_pending_seconds
outbox_publish_attempts_total
outbox_publish_success_total
outbox_publish_failure_total
outbox_publish_duration_seconds
outbox_lease_recovered_total
inbox_duplicates_total
```

Alertas recomendados:

- evento mais antigo pendente acima de 2–5 minutos;
- qualquer dead-letter nova;
- worker sem heartbeat;
- taxa de falhas superior a um limite;
- crescimento contínuo do backlog;
- leases expiradas em quantidade anormal.

Os logs devem incluir:

- `event_id`;
- `event_type`;
- `tenant_id`;
- `aggregate_id`;
- número da tentativa;
- destino;
- status HTTP, sem corpo sensível;
- duração;
- próximo retry.

## 19. Estratégia de implementação

### Fase 0 — transações locais críticas

Estado em 2026-09-03: itens 1–5 concluídos.

1. [Concluído] Introduzir suporte a `pgx.Tx` nos serviços de assiduidade,
   através do contrato `DBTX`, do construtor `NewServiceWithTx` e de testes
   que exercitam serviço e auditoria na transação do chamador.
2. [Concluído] Tornar atómicos prova facial + ponto. Em
   `self-service/handlers/ponto.go`, `MarcarPonto` abre uma única `pgx.Tx`
   antes de validar NFC/QR/PIN/facial; `consumeFacialVerification` passou a
   receber essa transação (`assiduidade.DBTX`) em vez de usar sempre a pool.
   O comprovativo facial só fica definitivamente consumido se `RegistarEvento`
   também tiver sucesso e a transação for confirmada.
3. [Concluído] Tornar atómicos QR + ponto, na mesma transação do item 2:
   `ValidarEUsarQRToken` corre através de `assiduidade.NewServiceWithTx(tx)`,
   por isso o `UPDATE` que marca o QR como usado só fica confirmado junto com
   o evento.
4. [Concluído] Tornar atómicos evento + auditoria. `Service.RegistarEvento`
   passou a correr dentro de `Service.withTx`: quando o serviço já participa
   da transação de um chamador (`NewServiceWithTx`, como em `ponto.go`), usa
   essa transação; quando opera sobre a pool (`NewService`, caso de
   `hardware/service/processor.go` e dos handlers de RH), abre e fecha a sua
   própria transação. Em ambos os casos, uma falha ao gravar em
   `rh.auditoria_assiduidade` agora reverte também o `INSERT` em
   `rh.eventos_assiduidade` — o erro deixou de ser descartado (`_ =`). Isto é
   uma excepção deliberada à política geral de `RegistarAuditoria` (falhas de
   auditoria não bloqueiam o negócio nos restantes chamadores, ver
   `auditoria.go`); só o acoplamento evento+auditoria pedido aqui trata a
   auditoria como obrigatória.
5. [Concluído, âmbito local] Tornar atómicas a auditoria e a notificação do
   webhook de re-enrollment. Em
   `recursos-humanos/handlers/biometria_reenroll.go`,
   `NotificarReenrollDevice` passou a abrir uma `pgx.Tx` única para o `INSERT`
   em `auditoria.audit_logs` e o `INSERT`/`WHERE NOT EXISTS` em
   `notif_colaborador`. Não foi criada a tabela `integration.inbox_events`
   nem um `event_id` idempotente no contrato HTTP — essa parte fica para a
   Fase 1 (itens 4–6), que exige alterar também o cliente FaceClock
   (`assiduidade_system_backend`, outro repositório). O `WHERE NOT EXISTS`
   continua a ser a única deduplicação funcional deste endpoint.

### Fase 1 — MVP FaceClock → ERP

Estado em 2026-09-03: itens 1–7 concluídos.

1. [Concluído] Migration Alembic `outbox_events` no FaceClock
   (`alembic/versions/f3a1c9d02b47_add_outbox_events.py`), com o modelo
   `OutboxEvent` correspondente em `app/models.py` (mesmo estilo de
   `BiometricAuditLog`; `payload` em `JSON` genérico, não `JSONB`, por
   consistência com o resto do ficheiro).
2. [Concluído] `app/routers/biometric.py` passou a enfileirar
   `biometric.reenroll_required.v1` (via `app/services/outbox.py::enqueue`)
   na mesma sessão/`commit()` que muda `FaceTemplate.status` para
   `PENDING_REENROLL`, com `deduplication_key =
   reenroll:{tenant}:{template}:{nova_versão}`. A chamada síncrona
   `erp_client.notify_reenroll_required` deixou de ser invocada a partir
   daqui — o outbox + worker passaram a ser o único caminho de entrega deste
   evento (o método continua definido em `erp_client.py`, sem chamadores).
3. [Concluído] Worker separado `app/workers/outbox.py` (entry point de
   processo, `python -m app.workers.outbox`, nunca uma task do lifespan do
   FastAPI), com a lógica de claim/lease/retry/backoff/dead-letter em
   `app/services/outbox.py`. Novo serviço `outbox-worker` em
   `docker-compose.yml` (mesma imagem, `entrypoint-worker.sh`).
4. [Concluído] `event_id` (o próprio `id` do outbox event) vai no corpo JSON
   do pedido HTTP que o worker envia ao ERP — decisão deliberada de não
   introduzir HMAC por evento nesta fase (ver nota abaixo).
5. [Concluído] Migration `integration.inbox_events` no ERP
   (`backend/migrations/20260903090000_integration_inbox_events.{up,down}.sql`),
   `UNIQUE (source_service, event_id)`.
6. [Concluído] `NotificarReenrollDevice`
   (`internal/modules/recursos-humanos/handlers/biometria_reenroll.go`)
   ganhou `event_id` opcional em `reenrollRequiredRequest`; quando presente,
   um `INSERT ... ON CONFLICT (source_service, event_id) DO NOTHING` em
   `integration.inbox_events`, na mesma transação já introduzida na Fase 0,
   decide se o pedido é duplicado — nesse caso salta por completo a
   auditoria e a notificação (`duplicate: true` na resposta), em vez de
   confiar só no `WHERE NOT EXISTS` heurístico de `notif_colaborador`. Sem
   `event_id` (chamador fora do caminho do worker), o comportamento anterior
   à Fase 1 é preservado.
7. [Concluído, âmbito reduzido] Métricas calculadas por query directa à
   tabela `outbox_events` (`app/outbox_metrics.py`, servidas em `GET
   /metrics` do FaceClock, que o ERP já expõe via proxy) — não em memória,
   porque o worker corre num processo separado da API e um contador em
   memória do worker nunca apareceria nesse endpoint. Do lado do ERP não foi
   criada nenhuma infraestrutura de métricas nova (não existe nenhuma
   reaproveitável em Go); `integration.inbox_events` fica directamente
   consultável. Testes de falha: `tests/test_outbox_enqueue.py` (atomicidade
   e rollback do enqueue, constraint única) e `tests/test_outbox_worker.py`
   (claim/lease, classificação de resposta HTTP, backoff, `200`→published,
   `429`/timeout→retry, `400`→dead-letter, `event_id` no corpo) do lado
   FaceClock; `biometria_reenroll_test.go` (evento novo, evento duplicado,
   pedido sem `event_id`) do lado ERP.

Decisão registada: `event_id` viaja no corpo JSON, não em headers HMAC — a
secção 33 deste documento é aspiracional (assinatura por pedido não existe
hoje neste caminho FaceClock→ERP, só `X-API-Key` via `RequireDeviceAuth`) e a
Fase 1 não pede HMAC por evento. Fica para uma fase futura, se vier a ser
necessário.

### Fase 2 — endurecimento das notificações ERP

Estado em 2026-09-03: itens 1–7 concluídos.

1. [Concluído] `notifications.notification_messages` foi evoluída no lugar
   (migration
   `backend/migrations/20260903100000_notification_messages_outbox.{up,down}.sql`),
   em vez de se criar um outbox genérico novo — a secção 29.1 deste
   documento já recomendava isto (o outbox genérico introduzido na Fase 1,
   `outbox_events`/`inbox_events`, fica reservado a integrações
   entre serviços, não à fila interna de email/SMS).
2. [Concluído] `internal/shared/adapters/notification.go`:
   `NotificationAdapter.db` passou de `*pgxpool.Pool` para uma interface
   `DBTX` mínima; novo `NewNotificationAdapterWithTx(tx pgx.Tx)` (mesmo
   padrão de `assiduidade.NewServiceWithTx`, Fase 0) torna possível
   enfileirar dentro da transacção do chamador. Nenhum dos 12 pontos de
   chamada existentes foi obrigado a adoptar isto — ficou disponível para
   quem precisar, sem re-plumbing de módulos não relacionados.
3. [Concluído] Novas colunas `available_at`, `locked_at`, `locked_by` (mesma
   migration do item 1); dead-letter é o estado `falha` já existente,
   alcançado depois de `notificationMaxAttempts` (6) tentativas.
4. [Concluído] `internal/background/jobs.go::claimPendingNotifications` —
   reserva atómica numa única instrução (`UPDATE ... FROM (SELECT ... FOR
   UPDATE SKIP LOCKED) RETURNING`, exactamente a query da secção 29.3),
   substituindo o `SELECT ... FOR UPDATE SKIP LOCKED` isolado que deixava o
   lock cair antes dos `UPDATE`s de status.
5. [Concluído] `notificationBackoffFor` — tabela exponencial (1m, 5m, 20m,
   1h, 4h, 12h) indexada pelo número de tentativas; mais curta que a do
   outbox FaceClock→ERP (Fase 1) por serem canais menos críticos.
6. [Concluído] Todo `Exec` do dispatcher (`finalizeNotification`,
   `recoverExpiredNotificationLeases`) verifica e loga o erro — acabou o
   `_, _ = db.Exec(...)` que já tinha mascarado um bug antes (comentário
   removido do código, já não se aplica). `NotificationPort.Send` também
   passou a devolver `error` em vez de só logar internamente.
7. [Concluído, opt-in] `RUN_BACKGROUND_JOBS` (default `true`, sem alteração
   de comportamento) e novo `backend/cmd/worker/main.go` — primeiro daemon
   Go de longa duração do projecto — permitem mover
   `background.StartJobs` para um processo separado da API quando for
   operacionalmente conveniente, sem forçar a mudança. Novo serviço
   `worker` (perfil `worker`, desligado por omissão) em `docker-compose.yml`
   e segundo binário `nexora-worker` no `Dockerfile`. O claim atómico do
   item 4 é o que torna seguro ligar API e worker ao mesmo tempo por engano.

Testes: `internal/shared/adapters/notification_test.go` e
`internal/background/jobs_test.go` (pastas sem testes antes desta fase),
usando `pgxmock` — padrão já estabelecido no projecto
(`internal/modules/assinatura-digital/...`), confirmado directamente no
código apesar de uma investigação inicial ter concluído o contrário.

### Fase 3 — push e goroutines

Estado em 2026-09-03: itens 1–5 concluídos.

1. [Concluído] `internal/push/push.go` deixou de falar directamente com o
   FCM a partir dos handlers. `SendToUser`/`SendToTenant`/`Send`
   (síncronos) foram removidos; `EnqueueToUser`/`EnqueueToTenant` gravam em
   `notification_messages` (via `contracts.NotificationPort`, já
   endurecido na Fase 2) e `SendOne` — a única função que ainda fala com o
   FCM — só é chamada pelo dispatcher persistente
   (`internal/background/jobs.go`, novo `case "push"`). Os 5 chamadores
   directos existentes (`candidato_push.go`, `pos.go`, `notificacoes.go`
   ×2, `cmd/broadcast_push/main.go`) foram todos migrados.
2. [Concluído] As 4 goroutines `go func() {...}()` de notificação em
   `internal/modules/gestao-escolar/handlers/{comunicacao,
   turmas_matriculas,grades,fees}.go` foram removidas — o mesmo corpo
   (resolver destinatários + `h.notification.Send`) passou a correr
   síncrono antes da resposta HTTP, seguro porque `Send` desde a Fase 0/2 é
   só um `INSERT` rápido. Já não há risco de perda em restart/deploy a meio
   (achado OUT-08).
3. [Concluído] Decisão de desenho central desta fase: os destinatários de
   push são resolvidos (tokens FCM) no momento de enfileirar, não no
   momento de entregar — uma linha em `notification_messages` por token.
   Evita a re-resolução tardia e o risco "destinatários podem ter mudado"
   (secção 25.2).
4. [Concluído, sem tabela nova] Consequência directa do item 3: como cada
   linha já corresponde a um único token, o mecanismo de estado/retry da
   Fase 2 (`status`, `tentativas`, `erro`, `locked_at`/`locked_by`) já É o
   resultado por token — nenhuma coluna ou tabela nova foi necessária.
   `notification_messages.payload` (coluna `jsonb` existente desde o
   baseline, nunca usada até agora) passou a transportar o `data` do FCM.
5. [Concluído] `POST /api/notificacoes/mensagens/{id}/reprocessar` e
   `POST /api/notificacoes/mensagens/reprocessar-falhas`
   (`notificacoes.go`, mesma permissão `notificacoes:gerir_notificacoes`
   já usada por `EnviarNotificacao`/`BroadcastPush`) repõem mensagens em
   `falha` como `pendente` com tentativas reiniciadas, para o dispatcher
   persistente as tentar de novo.

Testes: `internal/push/push_test.go` (novo), casos adicionais em
`internal/background/jobs_test.go` para o `case "push"` do dispatcher
(via um stub `pushSender` local, mesmo padrão de `notificationDB`) e em
`internal/shared/adapters/notification_test.go` para o novo campo
`Payload`.

### Fase 4 — pagamentos

Estado em 2026-09-03: itens 1–5 concluídos.

1. [Concluído] `integration.payment_intents`
   (`backend/migrations/20260903110000_payment_intents.{up,down}.sql`) —
   uma linha por tentativa de pagamento, partilhada entre POS e o portal
   escolar. Índice único parcial `uq_payment_intents_active_reference`
   (tenant+módulo+referência, só quando o estado ainda está activo) garante
   no máximo um intent em curso por cobrança escolar; o POS não tem
   `reference_id` estável (a venda só é criada depois do pagamento
   confirmado) — limitação conhecida e documentada no código, não resolvida
   nesta fase.
2. [Concluído] `internal/pkg/nexorapay.PaymentService.Initiate` grava o
   intent (`status='pending'`) **antes** de chamar o gateway, usando o
   próprio `id` (UUID) do intent como `Idempotency-Key` — estável mesmo
   que a reconciliação tenha de reenviar o pedido mais tarde. Substituiu as
   duas chaves antigas derivadas de `time.Now()`
   (`pos-%d-%d`/`escola-%s-%d-%d`) nos dois chamadores reais
   (`IniciarPagamento`, `PortalIniciarPagamento`).
3. [Concluído] Estados `pending`/`processing`/`confirmed`/`failed`/`unknown`
   geridos por `Initiate`/`Reconcile`/`ProcessCallback`. Erro de rede/timeout
   a chamar o gateway passou a gravar `unknown` (nunca mais silencioso);
   `Reconcile` resolve `unknown`/`processing` vencidos consultando o
   estado (quando já se conhece `gateway_transaction_id`) ou reenviando o
   `POST` original com a mesma `idempotency_key` (quando não se conhece).
4. [Concluído] `pos.WebhookPagamento` passa por
   `PaymentService.ProcessCallback` (mesmo padrão de
   `processReenrollWebhook`/`integration.inbox_events` da Fase 1:
   `INSERT ... ON CONFLICT (source_service, event_id) DO NOTHING RETURNING
   id`, `pgx.ErrNoRows` ⇒ duplicado) antes de tocar em
   `pos.pos_payment_confirmations` — um callback repetido deduplica em vez
   de reprocessar sempre os campos como o `UPSERT` antigo fazia. Ganho
   lateral: o `tenant_id` deixou de depender do parsing frágil de
   `thirdPartyReference`, vem do `payment_intent` encontrado por
   `gateway_transaction_id`. Não foi criado um webhook novo para o fluxo
   escolar (não existia antes, só poll) — `PortalStatusPagamento` passou a
   sincronizar o `payment_intent` correspondente
   (`MarkConfirmedByGatewayTxnID`) quando confirma por poll, para o estado
   ficar coerente independentemente do caminho.
5. [Concluído] `internal/background/jobs.go::reconcilePaymentIntents`,
   novo `runInterval` a cada 2 minutos em `StartJobs` — recupera leases
   expiradas, reserva um lote atomicamente (mesmo padrão de
   `claimPendingNotifications`, Fase 2) e chama `Reconcile` por intent.
   Backoff mais curto que o das notificações (30s, 1m, 2m, 5m, 15m; tecto
   de 5 tentativas antes de `failed`) — confirmação de pagamento móvel
   deve resolver-se em minutos, não horas.

Testes: `internal/pkg/nexorapay/service_test.go` (12 casos, cobrindo
`Initiate`, `ClaimForReconciliation`, `RecoverExpiredLeases`, `Reconcile` e
`ProcessCallback`) e 2 casos novos em `internal/background/jobs_test.go`
para `reconcilePaymentIntents` (via stub `paymentReconciler`).

### Fase 5 — hardware Inbox

Estado em 2026-09-04: itens 1–4 concluídos. Última fase do plano de
implementação — Fases 0–5 completas.

1. [Concluído] `hardware.device_events` ganhou `attempts`,
   `available_at`, `locked_at`/`locked_by` e `normalized_payload`
   (`backend/migrations/20260903120000_hardware_device_events_retry.{up,down}.sql`).
   `normalized_payload` (o `NormalizedEvent` já processado pelo adapter,
   distinto de `raw_payload` que só guarda os bytes brutos do dispositivo)
   é o que torna possível repetir `processEntity` mais tarde sem o pedido
   HTTP/MQTT original — sem isto nem o retry automático nem o replay
   manual eram possíveis. Novo `internal/background/jobs.go::retryHardwareEvents`,
   `runInterval` a cada 1 minuto, mesmo padrão de claim atómico/lease das
   Fases 2 e 4 (`Processor.RecoverExpiredLeases`/`ClaimForRetry`/`Retry`).
2. [Concluído] `ProcessResult` ganhou `Permanent bool`, decidido na origem
   dentro de `processEntity` (tenant sem empresa associada, método de
   assiduidade desactivado, credential_type sem mapeamento, entity_type
   não suportado — problemas de configuração, não se resolvem sozinhos) em
   vez de inferido por texto depois. Falha permanente marca
   `permanent_failure=TRUE` e nunca mais entra no retry automático; falha
   transitória (`employee_no` ainda não mapeado, funcionário inactivo, erro
   a registar o evento) agenda nova tentativa com backoff exponencial
   (1m, 5m, 15m, 30m, 1h; tecto de 5 tentativas).
3. [Concluído] `ListarEventos`
   (`internal/modules/hardware/handlers/events.go`) já paginava/filtrava
   por `processed`/`device_id`/etc. — passou a devolver também `attempts`,
   `permanent_failure` e `available_at`, para o painel distinguir "a
   aguardar retry" de "esgotou as tentativas, precisa de replay manual".
4. [Concluído] `POST /api/hardware/events/{id}/reprocessar` e
   `POST /api/hardware/events/reprocessar-nao-processados` (mesmo padrão
   dos endpoints de reprocessamento da Fase 3), protegidos pela nova
   permissão `hardware:gerir_eventos`
   (`backend/migrations/20260903120001_permissao_hardware_gerir_eventos.{up,down}.sql`,
   backfill apenas — ver nota abaixo). "Seguro" porque não corre
   `processEntity` sincronamente no pedido: só repõe a linha como elegível
   para o job de retry a processar a seguir, e nunca actua sobre um evento
   já `processed=TRUE`.
   - **Bug corrigido pelo caminho** (fora da lista original, mas
     directamente relacionado): a deduplicação por `event_hash` em
     `Process()` devolvia sempre `Processed: true` para um evento repetido,
     mesmo que a tentativa original tivesse falhado — corrigido para
     devolver o estado real (`processed`/`error_message`) da linha
     existente.
   - **Limitação aceite e documentada**: o worker MQTT
     (`internal/modules/hardware/mqtt/worker.go`) confirma sempre a
     mensagem MQTT independentemente do resultado de `Process()` — a
     biblioteca `paho.mqtt.golang` não expõe forma de recusar o ack a
     partir do `MessageHandler`. Corrigir isto exigiria mudar para ack
     manual, fora do âmbito desta fase.
   - **Regressão pré-existente, não corrigida aqui**: confirmado que
     `auth.criar_cargos_padrao()`, na sua versão actual
     (`20260812070001_cargos_padrao_pos.up.sql`), já não atribui nenhuma
     permissão do módulo `hardware` a cargo nenhum para tenants novos —
     foi perdida numa migração anterior que substituiu por completo o
     corpo da função. A migração desta fase só faz backfill para tenants
     existentes; corrigir a função para tenants futuros fica registado
     como problema conhecido, fora do âmbito de "hardware Inbox".

## 20. Estratégia de rollout

O rollout pode ser feito sem downtime:

1. adicionar tabelas e colunas sem remover comportamento existente;
2. publicar código que escreve no outbox, mantendo o worker desligado;
3. validar criação das linhas;
4. ligar o worker apenas para tenants internos;
5. comparar eventos criados e entregues;
6. expandir gradualmente;
7. remover o envio direto depois de confirmar estabilidade;
8. manter ferramenta de replay e inspeção.

Durante a transição, deve-se evitar enviar diretamente e pelo outbox sem uma chave idempotente comum, pois isso produziria duplicações.

## 21. Testes obrigatórios

### Testes transacionais

- rollback da operação também remove o evento do outbox;
- commit da operação sempre persiste o evento;
- falha ao inserir no outbox impede o commit do negócio quando o evento é obrigatório;
- prova facial não fica consumida se o ponto falhar;
- QR não fica consumido se o ponto falhar.

### Testes do worker

- ERP indisponível mantém evento pendente;
- timeout agenda retry;
- `429` respeita `Retry-After`;
- `400` permanente vai para dead-letter;
- crash depois do envio provoca retry seguro;
- lease expirada é recuperada;
- duas instâncias não reservam simultaneamente a mesma linha;
- backlog é processado depois de reiniciar o container.

### Testes do consumidor

- mesmo `event_id` duas vezes produz um único efeito;
- dois pedidos concorrentes com o mesmo `event_id` produzem um único efeito;
- evento de outro tenant é recusado;
- evento inválido não é marcado como processado;
- auditoria e notificação são confirmadas na mesma transação.

### Testes de segurança

- payload não contém embedding ou imagem;
- logs não contêm segredos;
- credencial de um tenant não publica para outro;
- assinatura HMAC inválida é recusada;
- timestamp/nonce fora da tolerância é recusado.

## 22. Estimativa de esforço

| Entrega | Estimativa |
|---|---:|
| Transações locais críticas | 4–7 dias úteis |
| MVP FaceClock → ERP | 5–8 dias úteis |
| Endurecimento das notificações Go | 5–8 dias úteis |
| Migração de goroutines e push | 5–8 dias úteis |
| Testes de falha, observabilidade e rollout | 5–8 dias úteis |

**Total estimado para implementação completa:** 24–39 dias de engenharia.

O MVP de maior valor pode ser concluído em aproximadamente **8–12 dias úteis**, combinando:

- correção da transação de marcação facial;
- outbox de re-enrollment no FaceClock;
- Inbox idempotente no ERP;
- métricas e testes essenciais.

## 23. Riscos

| Risco | Mitigação |
|---|---|
| Duplicação de entregas | Consumidores idempotentes e `event_id` único |
| Backlog crescer silenciosamente | Métricas e alertas por idade/quantidade |
| Worker preso em `processing` | Lease com recuperação automática |
| Payload conter biometria | Contratos mínimos e testes de segurança |
| Ordem incorreta de eventos | Sequência por aggregate quando realmente necessária |
| Migração gerar envio duplicado | Feature flag e chave idempotente comum |
| API competir com worker por recursos | Pool separado ou limites por processo |
| Dead letters esquecidas | Painel, alerta e comando seguro de replay |

## 24. Decisão recomendada

Recomenda-se avançar com o Transactional Outbox, nesta ordem:

1. corrigir primeiro as fronteiras transacionais locais;
2. implementar `biometric.reenroll_required.v1` no FaceClock;
3. criar Inbox idempotente no ERP;
4. endurecer `notification_messages` como outbox de entrega;
5. substituir goroutines e push direto;
6. tratar pagamentos com intenção persistente e idempotência estável;
7. adicionar reprocessamento à Inbox de hardware.

O PostgreSQL deve ser usado como fila persistente inicial. Não é necessário introduzir Kafka ou RabbitMQ nesta fase.

A primeira implementação elimina a perda silenciosa mais clara entre os dois backends e cria uma fundação reutilizável para notificações, pagamentos, integrações e expansão futura da arquitetura.

## 25. Auditoria profunda das janelas de falha

Esta secção detalha o resultado possível quando ocorre uma falha de processo,
base de dados, rede ou provider. A distinção entre "efeito local confirmado" e
"efeito externo confirmado" determina quando usar outbox.

### 25.1 FaceClock: transição para re-enrollment

| Instante da falha | Estado resultante | Recuperação atual | Risco |
|---|---|---|---|
| Antes do `db.commit()` | Template continua `ACTIVE` | Nova chamada repete a lógica | Baixo |
| Depois do commit e antes do HTTP | Template fica `PENDING_REENROLL`; ERP não sabe | Não existe fila | Crítico |
| Durante timeout HTTP | ERP pode ter recebido ou não | Não existe reconciliação | Crítico |
| ERP responde `4xx` ou `5xx` | FaceClock ignora o status | Evento considerado implicitamente concluído | Crítico |
| ERP aceita e FaceClock termina | ERP contém o aviso | Não é necessário retry | Baixo |

O método `notify_reenroll_required()` executa `await client.post(...)`, mas não
chama `raise_for_status()` nem examina `response.status_code`. Respostas `401`,
`403`, `404`, `429` ou `500` não entram no `except httpx.RequestError`.
Atualmente, uma rejeição explícita do ERP é indistinguível de sucesso.

O outbox deve considerar uma entrega concluída apenas depois de classificar o
status HTTP recebido.

### 25.2 ERP: criação de notificação

| Instante da falha | Estado resultante | Risco |
|---|---|---|
| Negócio falha depois de uma notificação inserida numa ligação separada | Pode existir notificação de algo que não ocorreu | Inconsistência |
| Negócio confirma e processo termina antes de `Send()` | Negócio existe; mensagem não existe | Perda definitiva |
| `Send()` falha | Erro fica apenas no log | Perda definitiva |
| Goroutine ainda não iniciou e processo termina | Trabalho nunca é persistido | Perda definitiva |
| Audiência é resolvida muito depois do evento | Destinatários podem ter mudado | Inconsistência temporal |

O contrato atual `NotificationPort.Send()` não devolve erro. Isso impede o
produtor de incluir a escrita na transação ou decidir se a falha deve abortar a
operação.

### 25.3 ERP: despacho de email e SMS

| Instante/condição | Estado resultante | Risco |
|---|---|---|
| Duas réplicas selecionam o mesmo lote | Ambas podem enviar | Duplicação |
| Provider aceita antes do `UPDATE enviado` | Mensagem continua pendente | Duplicação no retry |
| `UPDATE` de sucesso falha | Erro é descartado | Duplicação repetida |
| `UPDATE` de falha falha | Contador não avança | Retry invisível |
| SES não inicializa | `send()` desativado devolve `nil` | Falso sucesso |
| SMS está em modo `noop` | Sender devolve sucesso | Falso sucesso |
| Canal é push/WhatsApp | Dispatcher não suporta | Termina em falha após retries |

`newSMSSender()` devolve um `noopSMSSender` quando o provider está vazio. Logo,
a condição que só para o dispatcher quando email está desativado e `sms == nil`
não o interrompe. Em paralelo, o mailer desativado devolve `nil` no `send()`.
Uma mensagem pode ser marcada como enviada sem ter saído do sistema.

### 25.4 Push FCM

O push pode ser enviado antes da inserção do histórico, e `push.Service` não
devolve ao chamador o resultado agregado. Portanto, `status='enviado'`
significa hoje "o handler tentou", não "FCM aceitou".

Os estados devem ter semântica formal:

- `pending`: ainda não reservado;
- `processing`: reservado por um worker;
- `accepted`: provider aceitou;
- `delivered`: apenas quando houver confirmação real;
- `dead`: falha permanente ou tentativas esgotadas.

Para SES, SMS e FCM, normalmente é possível garantir apenas `accepted`, não a
entrega efetiva à pessoa ou ao dispositivo.

### 25.5 Pagamentos

Um timeout pode ocorrer depois de o provider ter criado a transação. O ERP não
pode interpretar timeout como "pagamento não criado". O estado correto é
`unknown` ou `reconciliation_required`, seguido de consulta com a mesma chave
idempotente antes de iniciar outra cobrança.

## 26. Classificação dos achados

| ID | Severidade | Achado | Impacto |
|---|---|---|---|
| OUT-01 | Crítica | Commit de `PENDING_REENROLL` antes do webhook sem fila | Perda definitiva do aviso |
| OUT-02 | Crítica | Status `4xx/5xx` do webhook não é validado | Rejeições tratadas como sucesso |
| OUT-03 | Crítica | Prova facial pode ser consumida antes do ponto | Utilizador sem ponto e sem prova reutilizável |
| OUT-04 | Alta | QR pode ser consumido antes do ponto | Token usado sem evento correspondente |
| OUT-05 | Alta | `NotificationAdapter` usa ligação separada e ignora erros | Negócio e mensagem não são atómicos |
| OUT-06 | Alta | `SKIP LOCKED` sem reserva transacional explícita | Duplicação entre réplicas |
| OUT-07 | Alta | Providers desativados podem produzir falso sucesso | Histórico incorreto |
| OUT-08 | Alta | Goroutines de handlers não são persistentes | Perda em restart/deploy |
| OUT-09 | Alta | Idempotency key de pagamento baseada no relógio | Retry pode duplicar cobrança |
| OUT-10 | Média | Hardware Inbox sem worker de reprocessamento | Eventos falhados ficam parados |
| OUT-11 | Média | Índice da fila começa por `tenant_id`, mas worker é global | Scan crescente |
| OUT-12 | Média | Jobs são iniciados dentro de cada réplica da API | Duplicação ao escalar |
| OUT-13 | Média | Auditoria e negócio usam escritas independentes | Auditoria incompleta |
| OUT-14 | Média | `erp_sync_metrics` é exposto mas não atualizado pelo cliente | Falsa confiança operacional |
| OUT-15 | Arquitetural | Credenciais globais sem routing multi-tenant explícito | Associação ao tenant errado |

## 27. Decisão obrigatória de multi-tenant

Antes do outbox FaceClock → ERP, deve ser confirmado o modelo de deployment.

### Modelo A — uma instância FaceClock por tenant

- cada deployment possui a sua base FaceClock;
- a credencial ERP → FaceClock pertence ao mesmo tenant;
- a `ERP_API_KEY` FaceClock → ERP aponta para um device desse tenant;
- `tenant_id` funciona como validação adicional.

Este modelo simplifica routing, mas aumenta o custo operacional por tenant.

### Modelo B — FaceClock partilhado

A configuração atual usa uma única `FACECLOCK_ACCESS_KEY_ID`, uma única
`FACECLOCK_SECRET_ACCESS_KEY` e uma única `ERP_API_KEY`. Se as credenciais
estiverem vinculadas a um tenant, isso não oferece routing forte para vários
tenants.

Soluções possíveis:

1. credencial cifrada por tenant, escolhida pelo worker;
2. service account global autorizada a delegar um tenant num header assinado;
3. OAuth2 Client Credentials com scopes e tenant autorizado.

A opção 1 exige menos alterações; a opção 3 oferece a evolução de segurança
mais forte. Nunca se deve confiar no `tenant_id` do JSON sem o vincular à
credencial autenticada.

Se o FaceClock é partilhado, esta decisão é pré-requisito do rollout. O outbox
garante entrega, mas não corrige routing incorreto.

## 28. Desenho detalhado do Outbox no FaceClock

### 28.1 Chave de deduplicação

Para re-enrollment:

```text
reenroll:{tenant_id}:{template_id}:{new_model_version}
```

Isso permite um evento por template e nova versão. Um enrollment posterior que
gere outro template pode criar legitimamente outro evento.

### 28.2 Fronteira transacional

O helper de domínio não deve executar `commit()` antes do enqueue. Ele deve:

1. alterar o template;
2. adicionar o outbox à mesma `Session`;
3. deixar o boundary de aplicação executar um único commit.

### 28.3 Processo do worker

O worker deve ser um processo/container separado, não uma task criada no
lifespan do FastAPI. Uma task por worker Uvicorn geraria dispatchers duplicados
e misturaria recursos de ML e entrega HTTP.

```text
loop
  reservar até 50 eventos
  para cada evento
    escolher credencial/destino pelo tenant
    enviar com event_id e correlation_id
    classificar resposta
    persistir sucesso, retry ou dead
  aguardar NOTIFY ou intervalo curto com jitter
```

`LISTEN/NOTIFY` pode reduzir a latência, mas deve servir apenas para acordar o
worker. Não é uma fila durável; o outbox permanece a fonte de verdade.

## 29. Desenho detalhado no ERP

### 29.1 Relação com `notification_messages`

Há duas alternativas:

**Manter como outbox especializado:** menor alteração e compatibilidade com a
UI. Exige adicionar `event_id`, `deduplication_key`, `available_at`, `locked_at`,
`locked_by`, `updated_at`, `processing`, `dead` e índice parcial.

**Outbox genérico + projeção de notificações:** melhor desacoplamento, mas maior
complexidade e consistência eventual adicional.

Recomendação: manter `notification_messages` como outbox especializado e usar
um outbox genérico apenas para integrações entre serviços.

### 29.2 Índice do dispatcher

O índice atual começa por `tenant_id`, mas o dispatcher não filtra tenant. Deve
existir um índice alinhado com a consulta global:

```sql
CREATE INDEX IF NOT EXISTS idx_notification_dispatch_pending
    ON notifications.notification_messages (available_at, created_at, id)
    WHERE status = 'pendente';
```

### 29.3 Claim correto

```sql
WITH candidates AS (
    SELECT id
      FROM notifications.notification_messages
     WHERE status = 'pendente'
       AND available_at <= NOW()
     ORDER BY available_at, created_at, id
     LIMIT $1
     FOR UPDATE SKIP LOCKED
)
UPDATE notifications.notification_messages m
   SET status = 'processing',
       locked_at = NOW(),
       locked_by = $2,
       updated_at = NOW()
  FROM candidates c
 WHERE m.id = c.id
 RETURNING m.*;
```

Esse bloco deve executar em uma transação curta. O envio externo ocorre depois
do commit da reserva.

## 30. Estado, retry e leases

```text
pending ──claim──► processing ──2xx──► accepted/published
   ▲                    │
   │                    ├──erro transitório──► pending + available_at
   │                    │
   └──lease expirada────┘
                        │
                        └──erro permanente/tentativas──► dead

dead ──replay administrativo auditado──► pending
```

Regras:

- somente `pending` vencido pode ser reservado;
- somente o `locked_by` atual pode concluir a tentativa;
- retry preserva o mesmo `event_id`;
- payload publicado é imutável;
- uma correção cria novo evento e referencia o anterior;
- lease expirada devolve o evento a `pending`;
- `Retry-After` deve prevalecer sobre o backoff calculado.

## 31. Concorrência e ordenação

Não é necessário impor ordem global. Quando a ordem for requisito de um
aggregate, usar:

```text
partition_key = tenant_id + ':' + aggregate_type + ':' + aggregate_id
aggregate_version = 1, 2, 3...
```

A inferência entrada/saída pela contagem de eventos também possui uma corrida:
dois pedidos simultâneos podem observar a mesma contagem e inferir o mesmo
tipo. Esse problema não é de outbox. Se a alternância exata for requisito,
usar advisory lock por funcionário/dia, linha de estado com `FOR UPDATE` ou
tipo explícito vindo de fonte confiável.

## 32. Plano de alteração por ficheiro

### FaceClock

| Ficheiro | Alteração proposta |
|---|---|
| `app/models.py` | Adicionar `OutboxEvent` |
| `alembic/versions/<nova>_add_outbox_events.py` | Tabela, constraints e índices |
| `app/routers/biometric.py` | Update + enqueue na mesma transação |
| `app/erp_client.py` | Classificar status HTTP e enviar `event_id` |
| `app/services/outbox.py` | Enqueue, claim, success, retry, dead e recovery |
| `app/config.py` | Batch, polling, retry, lease e retenção |
| `app/erp_sync_metrics.py` | Ligar métricas às tentativas reais |
| `app/main.py` | Não iniciar worker dentro de cada processo web |
| `app/workers/outbox.py` | Entry point separado |
| `docker-compose.yml` | Adicionar `outbox-worker` |
| `tests/test_outbox.py` | Atomicidade, retry, lease e concorrência |
| `tests/test_api.py` | Verificar enqueue na mudança de versão |

### ERP Go

| Ficheiro | Alteração proposta |
|---|---|
| `migrations/<nova>_transactional_outbox.up.sql` | Tabelas, colunas e índices |
| `internal/outbox/store.go` | Store sobre interface `DBTX` |
| `internal/outbox/worker.go` | Claim, dispatch, retry e lease recovery |
| `internal/outbox/policy.go` | Classificação HTTP e backoff |
| `internal/shared/adapters/notification.go` | Retornar erro e aceitar `pgx.Tx` |
| `internal/background/jobs.go` | Remover dispatcher antigo após migração |
| `internal/modules/recursos-humanos/handlers/biometria_reenroll.go` | Inbox e transação única |
| `internal/modules/self-service/handlers/facial_verification.go` | Consumir prova via `pgx.Tx` |
| `internal/modules/self-service/handlers/ponto.go` | Prova/QR/evento/auditoria atómicos |
| `internal/modules/recursos-humanos/service/assiduidade/eventos.go` | Receber `DBTX` |
| `internal/modules/hardware/service/processor.go` | Retry/reprocessamento da Inbox |
| `internal/push/push.go` | Retornar resultados classificados |
| `internal/pkg/nexorapay/client.go` | Timeout explícito e operação persistida |
| `internal/modules/pos/handlers/pagamentos.go` | Chave idempotente persistida |
| `internal/modules/gestao-escolar/handlers/portal_pagamento.go` | Reutilizar a mesma chave |
| `main.go` | Separar modo API e worker |
| `docker-compose.yml` | Adicionar serviço worker |

## 33. Contrato HTTP FaceClock → ERP

```http
POST /api/hardware/assiduidade/events
Content-Type: application/json
X-Event-ID: 4c26705e-...
X-Correlation-ID: 6edbca91-...
X-Nexora-Access-Key: ...
X-Nexora-Timestamp: ...
X-Nexora-Nonce: ...
X-Nexora-Content-SHA256: ...
X-Nexora-Signature: ...
```

Resposta nova ou duplicada:

```json
{
  "event_id": "4c26705e-...",
  "status": "accepted",
  "duplicate": false
}
```

É preferível devolver `200` para evento duplicado já aplicado. Se for usado
`409`, o worker deve distinguir duplicação de outros conflitos.

## 34. Capacidade e dimensionamento

Sem métricas de produção não é possível estimar throughput exato. Um exemplo
conservador com batch 50, quatro workers e latência externa média de 200 ms
permite aproximadamente 20 entregas por segundo, ou mais de 1,7 milhão por
dia. Quotas dos providers provavelmente serão o limite antes do PostgreSQL.

Para comunicados com milhares de destinatários:

1. criar uma mensagem por destinatário se o lote for limitado;
2. ou criar evento de fan-out e materializar destinatários em batches;
3. guardar snapshot da audiência quando a regra exige os destinatários do
   instante da publicação.

## 35. Deployment e múltiplas réplicas

Os jobs Go são iniciados em `main.go`; cada réplica da API iniciará todos os
jobs. Para outbox, múltiplos workers só são seguros com claim correto. Jobs
diários não protegidos ainda podem duplicar.

Deployment recomendado:

```text
nexora-api       N réplicas; sem jobs recorrentes
nexora-worker    M réplicas; outbox e jobs atribuídos
faceclock-api    N réplicas; biometria
faceclock-worker M réplicas; outbox HTTP
```

O `container_name` fixo no Compose impede escala simples com `docker compose
--scale`. Deve ser removido ao adotar várias réplicas.

No shutdown, o worker deve parar claims, concluir tentativas dentro de um prazo
curto e deixar leases não concluídas expirarem para recuperação.

## 36. Cobertura de testes e critérios de aceitação

Há testes relevantes de HMAC, prova facial, eventos de assiduidade, webhooks de
assinatura e cliente Nexora Pay. Não foi encontrada cobertura dedicada para:

- atomicidade negócio + notificação;
- dois dispatchers concorrentes;
- crash depois da aceitação pelo provider;
- recuperação de lease;
- dead-letter e replay;
- `4xx/5xx` no webhook de re-enrollment;
- SES desativado sem falso sucesso;
- retry de `hardware.device_events`.

Concorrência deve ser testada com PostgreSQL real, não apenas mocks.

### Critérios do MVP

Estado revisto em 2026-09-03/04 após a implementação das Fases 0-5 (ver
secção 19). "Verdadeiro por desenho" significa que a lógica está implementada
e testada com `pgxmock`/`pytest`, mas nunca correu contra Postgres real com
concorrência/falhas de infra a sério — nenhuma fase desta implementação
correu testes de integração com BD real.

- [x] `PENDING_REENROLL` e outbox confirmados na mesma transação — Fase 1, item 2.
- [ ] ERP indisponível por 10 minutos não perde o evento — verdadeiro por
      desenho (retry+backoff no worker do outbox), nunca testado com o ERP
      realmente em baixo 10 minutos.
- [ ] Restart do FaceClock/worker não perde o evento — verdadeiro por
      desenho (`recover_expired_leases`), nunca testado com restart real.
- [~] ERP `500` gera retry; `401/403` gera dead-letter e alerta — retry e
      dead-letter implementados (`classify_response`); o "alerta" (envio
      activo a alguém, ex. email/Slack ao operador) nunca foi implementado
      em nenhuma fase.
- [x] Mesmo `event_id` repetido cria um único efeito — Fase 1, item 6
      (`deduplication_key` único + `integration.inbox_events`).
- [x] Inbox, auditoria e aviso no ERP são atómicos — Fase 1.
- [ ] Duas réplicas não possuem simultaneamente a mesma lease — verdadeiro
      por desenho (`FOR UPDATE SKIP LOCKED` em todo o lado), nunca testado
      com duas réplicas reais concorrentes.
- [ ] Payload e logs não contêm biometria nem segredos — razoavelmente
      verdadeiro por desenho; não houve uma passagem dedicada de auditoria
      de segurança a confirmar isto em todos os payloads novos.
- [x] Métrica da idade do evento mais antigo está disponível —
      `outbox_oldest_pending_seconds` (Fase 1, `app/outbox_metrics.py`).
- [~] Replay de dead-letter é auditado — implementado para notificações
      (Fase 3) e eventos de hardware (Fase 5); **não** implementado
      especificamente para o outbox do FaceClock (Fase 1 não criou um
      endpoint de replay administrativo).
- [ ] Estratégia multi-tenant está definida e testada — não endereçado; a
      decisão Modelo A/B da secção 27 continua por tomar.

### Critérios da implementação completa

- [~] Notificações de negócio são enfileiradas na mesma transação — a
      capacidade existe (`NewNotificationAdapterWithTx`, Fase 2), mas os 12
      pontos de chamada existentes não foram retrofitados para a usar
      (decisão de âmbito explícita da Fase 2: só o caminho novo/crítico usa
      `WithTx`, o resto continua a enfileirar fora da transação de negócio).
- [x] Goroutines não executam trabalho obrigatório — Fase 3 (envio de push
      passou a síncrono/via fila em todos os handlers identificados).
- [~] Email, SMS e push distinguem desativado, aceite e falha — push sim
      (Fase 3); o bug de falso sucesso do email/SMS quando o provedor está
      desativado (achado OUT-07 do documento) não foi corrigido nesta
      implementação.
- [~] Retry usa backoff, jitter e `Retry-After` — backoff existe em todas as
      filas (FaceClock outbox, notificações, pagamentos, hardware); jitter
      só existe no worker Python do outbox do FaceClock, nenhuma das filas
      Go tem jitter; suporte ao cabeçalho `Retry-After` do provider nunca
      foi implementado em lado nenhum.
- [x] Pagamentos reutilizam idempotency key persistida — Fase 4 (UUID do
      `payment_intent` como Idempotency-Key, persistido antes da chamada).
- [x] Timeout de pagamento entra em reconciliação — Fase 4 (estado
      `unknown` + job `reconciliar-pagamentos`).
- [x] Eventos hardware falhados possuem retry e painel — Fase 5.
- [x] Prova facial, QR, evento e auditoria são atómicos — Fase 0.
- [ ] Retenção, limpeza, métricas e alertas estão ativos — jobs de
      retenção/limpeza nunca foram implementados para nenhuma das tabelas
      novas ou existentes; métricas existem só do lado FaceClock (ERP
      ficou fora de âmbito, decisão da Fase 1/2); alertas activos não
      existem em nenhuma fase.

## 37. Limites e conclusão aprofundada

Esta análise é estática. Não foram disponibilizados volumes reais, número de
tenants/réplicas, SLAs, quotas dos providers, planos de execução PostgreSQL ou
histórico de incidentes. Esses dados afetam batches, workers, retenção e prazo,
mas não alteram a conclusão de viabilidade.

O sistema já possui bases corretas: PostgreSQL como fonte de verdade,
deduplicação de hardware, prova facial de uso único, fila persistente de
notificações e idempotência parcial. A fragilidade aparece na fronteira entre a
escrita local e o efeito externo.

A sequência correta é:

1. corrigir atomicidade local, pois outbox não substitui transações;
2. garantir FaceClock → ERP;
3. tornar `notification_messages` uma fila confiável;
4. eliminar trabalho obrigatório em goroutines;
5. persistir workflows de pagamentos;
6. operacionalizar Inbox, dead-letter, métricas e replay.

Essa evolução não exige Kafka, RabbitMQ nem reescrita dos backends. PostgreSQL
é suficiente, desde que claim, leases, idempotência e observabilidade sejam
tratados como requisitos centrais.
