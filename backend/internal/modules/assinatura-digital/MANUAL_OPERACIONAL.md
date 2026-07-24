# Manual operacional — módulo `assinatura-digital`

Guia para quem opera o backend em produção (deploy, configuração, rotina e
diagnóstico). Para a descrição técnica completa do módulo, ver
[README.md](./README.md). Para "o que fazer quando algo corre mal de forma
grave", ver [PROCEDIMENTO_INCIDENTES.md](./PROCEDIMENTO_INCIDENTES.md).

## 1. Antes de cada deploy

Checklist mínimo — confirmar cada um destes pontos:

- [ ] `SIGNATURE_ALLOW_INSECURE_PROVIDER` está definido no ambiente de
      destino. Desde a Fase 6, o servidor **recusa-se a arrancar** com os
      providers `dev`/`intic` (stub) sem esta variável a `true`. Se o
      ambiente ainda não tiver um provider real (INTIC/SCDM), definir
      explicitamente `true` — caso contrário o processo termina no arranque
      (`panic`), não apenas regista um aviso.
- [ ] `SIGNATURE_WEBHOOK_ENABLED` reflecte a intenção real: fica `false` a
      menos que o webhook tenha sido revisto e activado deliberadamente (ver
      README secção 6.9). Ativar sem um provider real ligado não tem
      utilidade e aumenta a superfície de ataque para nada.
- [ ] Migrations novas aplicadas — ver secção 2.
- [ ] `go build ./... && go test ./...` limpos (o CI/pipeline deve garantir
      isto, mas confirmar manualmente antes de um deploy manual).
- [ ] Se este deploy introduzir ou alterar um fork em `third_party/`, reler
      `third_party/digitorus-pdfsign/NEXORA_PATCH.md` e confirmar que o
      patch continua aplicado (um `go mod vendor`/`go mod tidy` mal feito
      pode silenciosamente reverter para o upstream sem patch).

## 2. Migrations

As migrations do módulo seguem a convenção geral do projecto
(`migrations/README.md`). Existe também um script específico que aplica só
as migrations cujo nome contém `assinatura_digital`:

```bash
cd backend
go run ./scripts/apply_migrations_assinatura_digital.go
```

Este script é aditivo (`ON CONFLICT`/`IF NOT EXISTS` nas migrations) e
idempotente — corrê-lo outra vez não duplica nada. Não substitui o
mecanismo geral de migrations do projecto; usa-se quando se quer aplicar só
as migrations deste módulo isoladamente (ex. ambiente de teste dedicado).

Migrations com teste de integração opt-in (requerem PostgreSQL real, nunca
correm por omissão em CI sem `TEST_DATABASE_URL`):

```bash
TEST_DATABASE_URL=postgres://... go test ./migrations -run Hardening
TEST_DATABASE_URL=postgres://... go test ./migrations -run Fase0
TEST_DATABASE_URL=postgres://... go test ./migrations -run LogsAppendOnly
```

## 3. Configuração — o que cada variável controla

Referência rápida; para o detalhe completo ver README secção 15.

| Variável | Efeito se mal configurada |
|---|---|
| `SIGNATURE_PROVIDER` | `dev`/`intic` nunca produzem valor jurídico (ver disclaimer no topo do README) |
| `SIGNATURE_ALLOW_INSECURE_PROVIDER` | Sem `true`, o servidor não arranca com `dev`/`intic` |
| `SIGNATURE_DEV_KEY_PATH` | Perder este ficheiro gera um certificado **novo** na próxima vez que o servidor arrancar — assinaturas antigas continuam válidas (o certificado usado fica gravado em `versoes_assinadas`), mas o certificado "actual" muda |
| `SIGNATURE_TSA_URL` | Vazio = sem carimbo temporal (nível B-B); só com timeout de 20s no cliente HTTP (patch, ver `third_party/digitorus-pdfsign/NEXORA_PATCH.md`) — uma TSA lenta atrasa a assinatura até 20s, nunca bloqueia indefinidamente |
| `SIGNATURE_CA_ROOTS_PEM` / `SIGNATURE_CA_INTERMEDIATES_PEM` | Sem isto, só as raízes do sistema operativo são usadas na validação — um certificado de uma CA privada (ex. INTIC) nunca aparecerá como confiável |
| `SIGNATURE_WEBHOOK_ENABLED` / `SIGNATURE_WEBHOOK_PROVIDERS` / `SIGNATURE_WEBHOOK_SECRET_<PROVIDER>` | Sem isto correctamente configurado, o webhook devolve `503`/`403`/`501` — ver README secção 6.9 para o significado de cada código |
| `STORAGE_PROVIDER`, `MINIO_*` / `STORAGE_LOCAL_DIR` | Ver `internal/storage` — evidências (`assinatura-digital/...`) nunca podem ser apagadas via `Provider.Delete`, independentemente do backend |

## 4. Rotina de monitorização

Sem um sistema de métricas dedicado configurado para este módulo ainda (ver
secção 6 — proposta), as seguintes consultas SQL diretas servem de
diagnóstico manual:

**Eventos de webhook falhados** (só relevante se `SIGNATURE_WEBHOOK_ENABLED=true`):

```sql
SELECT id, provider, event_id, event_type, erro, created_at
FROM assinatura_digital.webhook_events
WHERE processado = FALSE AND erro IS NOT NULL
ORDER BY created_at DESC;
```

Um evento aqui não é necessariamente crítico — o provider pode reenviá-lo
(a Fase 3 implementou reprocessamento: um `event_id` repetido com
`processado=false` é reprocessado, não tratado como duplicado). Mas um
volume crescente de erros para o mesmo `provider`/`event_type` indica um
problema a investigar (ex. mudança de esquema do payload do provider).

**Signatários presos em `convidado` além do prazo de expiração do convite**:

```sql
SELECT s.id, s.documento_id, s.nome, s.status, c.expira_em, c.usado_em
FROM assinatura_digital.signatarios s
JOIN assinatura_digital.convites c ON c.signatario_id = s.id
WHERE s.status IN ('pendente', 'convidado')
  AND c.expira_em < NOW()
  AND c.usado_em IS NULL
ORDER BY c.expira_em;
```

**Documentos parados em `parcialmente_assinado` há muito tempo** (pode
indicar um signatário que nunca vai responder):

```sql
SELECT id, titulo, tenant_id, status, updated_at
FROM assinatura_digital.documentos
WHERE status = 'parcialmente_assinado'
  AND updated_at < NOW() - INTERVAL '30 days'
ORDER BY updated_at;
```

**Certificados próximos da expiração** (relevante sobretudo quando houver
um provider real — o certificado `dev` tem validade de 2 anos a partir da
primeira geração):

```sql
SELECT DISTINCT provider, certificado_subject, certificado_validade_fim
FROM assinatura_digital.versoes_assinadas
WHERE certificado_validade_fim < NOW() + INTERVAL '30 days'
ORDER BY certificado_validade_fim;
```

## 5. Tarefas comuns

**Reprocessar manualmente um evento de webhook falhado**: não existe (ainda)
um endpoint dedicado — a forma actual é o próprio provider reenviar o
evento (o mesmo `event_id`, o que a aplicação trata correctamente como
retry, não duplicado). Se for preciso forçar localmente, marcar o registo
como não-existente e aceitar o reenvio: **não apagar a linha** de
`webhook_events` diretamente (documentar a razão, e preferir esperar pelo
reenvio natural do provider).

**Rodar o certificado `dev`**: apagar o ficheiro em `SIGNATURE_DEV_KEY_PATH`
e reiniciar o servidor — gera um certificado novo automaticamente.
Assinaturas já produzidas com o certificado antigo continuam
criptograficamente válidas (o certificado fica embutido no PDF e registado
em `versoes_assinadas`); só as *novas* assinaturas passam a usar o
certificado novo.

**Verificar se o patch do `third_party/digitorus-pdfsign` continua activo**:

```bash
cd backend
go list -m github.com/digitorus/pdfsign
# deve mostrar "=> ./third_party/digitorus-pdfsign"
```

Se não mostrar o `=>`, o `replace` foi removido do `go.mod` (acidental ou
deliberadamente) e as assinaturas voltam a usar `SubFilter
adbe.pkcs7.detached` (não-PAdES) sem nenhum aviso — ver
`third_party/digitorus-pdfsign/NEXORA_PATCH.md`.

## 6. Proposta de monitorização, SLA e processo de revogação (rascunho)

**Isto é uma proposta de desenho, não uma política aprovada** — precisa de
decisão de negócio antes de ser considerada em vigor.

### Métricas sugeridas

- Taxa de falha de `POST /webhooks/{provider}` por tipo de erro (`403`
  provider não permitido, `401` HMAC inválido, `409` nonce reutilizado,
  `422` erro de processamento) — um pico de `401`/`409` pode indicar um
  segredo comprometido ou um ataque de replay;
- Taxa de falha de `ValidarOTP` (`401` código errado, `429` limite excedido)
  por signatário/IP — um pico pode indicar força bruta;
- Latência e taxa de erro de `GET /validacao` — inclui chamadas HTTP
  externas (OCSP/CRL) com timeout de 10s (biblioteca) que podem degradar a
  latência percebida;
- Idade do evento de webhook mais antigo com `processado=false` — alerta se
  ultrapassar, por exemplo, 24h sem reprocessamento;
- Contagem de documentos em `parcialmente_assinado` há mais de N dias (ver
  consulta na secção 4).

### SLA (proposta, a validar com o negócio)

- Disponibilidade do endpoint de assinatura interno: alinhada com o SLA
  geral do backend Nexora ERP (não é um serviço isolado);
- Tempo de resposta a incidentes de segurança (ver
  `PROCEDIMENTO_INCIDENTES.md`): a definir consoante a severidade;
- Sem SLA de disponibilidade para o webhook enquanto não houver um provider
  real ligado (`SIGNATURE_WEBHOOK_ENABLED=false` por omissão).

### Processo de revogação (proposta)

Hoje não existe um mecanismo de "revogar" uma assinatura ou um acesso de
signatário para além do que já existe:

- Um convite pode ser deixado expirar (`convites.expira_em`) — não há
  endpoint para invalidar um convite antes do prazo;
- Não há forma de revogar um documento já `assinado` — só `cancelar`
  (permitido em `rascunho`/`pendente`, nunca depois de concluído);
- Quando houver um provider real: o processo de revogação de certificado é
  responsabilidade da CA (SCDM/INTIC), e este sistema teria de tratar o
  evento `certificate.revoked` do webhook (já implementado desde a Fase 3 —
  regista uma validação `invalido` para as versões afectadas, sem apagar a
  evidência original).

Decisões pendentes de negócio: quem pode invalidar um convite antes do
prazo, e se deve existir um mecanismo formal de "documento assinado sob
suspeita" distinto de simplesmente registar uma nova validação.
