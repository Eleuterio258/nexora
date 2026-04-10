# Notifications Service

O `notifications-service` centraliza canais, templates, mensagens e relatórios simples de notificações por tenant.

Base path no gateway:

- `/api/notifications`

Health check direto no container:

- `GET /health`

## Estado atual

O serviço já permite:

- gerir canais de notificação
- gerir templates por canal
- registar mensagens
- atualizar o estado de envio
- consultar resumo por tenant

O serviço ainda nao faz envio real por SMTP, SMS, WhatsApp ou Push. Hoje o endpoint de envio apenas muda o estado da mensagem na base de dados.

## Autenticação

Todas as rotas em `/api/notifications/*` exigem `Bearer token`.

Headers relevantes:

- `Authorization: Bearer <token>`

O tenant e o utilizador autenticado sao inferidos do JWT.

## Variáveis de ambiente

- `PORT`
- `DATABASE_URL`
- `JWT_SECRET`
- `RABBITMQ_URL`
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USER`
- `SMTP_PASS`
- `SMTP_FROM`
- `CORS_ORIGIN`
- `NODE_ENV`

Nota: as variáveis `SMTP_*` já estão previstas no `docker-compose`, mas ainda nao são usadas para envio efetivo.

## Modelo de dados

### 1. `notification_channels`

Representa o canal/configuração lógica de envio por tenant.

Campos principais:

- `codigo`
- `nome`
- `tipo`: `email | sms | whatsapp | push`
- `configuracao` (`JSONB`)
- `activo`

### 2. `notification_templates`

Templates reutilizáveis por tenant e por tipo de canal.

Campos principais:

- `codigo`
- `canal_tipo`: `email | sms | whatsapp | push`
- `assunto`
- `corpo`
- `variaveis` (`JSONB`)
- `activo`

### 3. `notification_messages`

Mensagens geradas para envio ou reprocessamento.

Campos principais:

- `channel_id`
- `template_id`
- `canal_tipo`
- `destinatario`
- `assunto`
- `corpo`
- `payload` (`JSONB`)
- `referencia_tipo`
- `referencia_id`
- `status`: `pendente | enviado | falha | cancelado`
- `tentativas`
- `erro`
- `enviado_em`

## Endpoints

### Canais

#### `GET /api/notifications/channels`

Lista os canais do tenant autenticado.

Resposta `200`:

```json
[
  {
    "id": 1,
    "tenant_id": 10,
    "codigo": "EMAIL_PADRAO",
    "nome": "Email principal",
    "tipo": "email",
    "activo": true,
    "updated_by": 7,
    "created_at": "2026-03-17T09:00:00.000Z",
    "updated_at": "2026-03-17T09:00:00.000Z"
  }
]
```

#### `POST /api/notifications/channels`

Cria ou atualiza um canal por `tenant_id + codigo`.

Body:

```json
{
  "codigo": "EMAIL_PADRAO",
  "nome": "Email principal",
  "tipo": "email",
  "configuracao": {
    "from": "noreply@nexora.co.mz",
    "reply_to": "suporte@nexora.co.mz"
  },
  "activo": true
}
```

Campos obrigatórios:

- `codigo`
- `nome`
- `tipo`

Resposta `200`:

```json
{
  "id": 1,
  "tenant_id": 10,
  "codigo": "EMAIL_PADRAO",
  "nome": "Email principal",
  "tipo": "email",
  "activo": true,
  "updated_by": 7,
  "created_at": "2026-03-17T09:00:00.000Z",
  "updated_at": "2026-03-17T09:00:00.000Z"
}
```

### Templates

#### `GET /api/notifications/templates`

Lista templates do tenant.

Query params opcionais:

- `canal_tipo`

Exemplo:

`GET /api/notifications/templates?canal_tipo=email`

#### `POST /api/notifications/templates`

Cria ou atualiza um template por `tenant_id + codigo + canal_tipo`.

Body:

```json
{
  "codigo": "FATURA_EMITIDA",
  "canal_tipo": "email",
  "assunto": "Nova fatura emitida",
  "corpo": "O documento {{numero}} foi emitido com total {{total}}.",
  "variaveis": ["numero", "total"],
  "activo": true
}
```

Campos obrigatórios:

- `codigo`
- `canal_tipo`
- `corpo`

### Mensagens

#### `GET /api/notifications/messages`

Lista mensagens do tenant.

Query params opcionais:

- `status`
- `canal_tipo`

Exemplo:

`GET /api/notifications/messages?status=pendente&canal_tipo=email`

#### `POST /api/notifications/messages`

Regista uma nova mensagem.

Body:

```json
{
  "channel_id": 1,
  "template_id": 3,
  "canal_tipo": "email",
  "destinatario": "cliente@empresa.co.mz",
  "assunto": "Bem-vindo",
  "corpo": "O seu acesso foi criado com sucesso.",
  "payload": {
    "customer_id": 55
  },
  "referencia_tipo": "cliente",
  "referencia_id": 55
}
```

Campos obrigatórios:

- `canal_tipo`
- `destinatario`
- `corpo`

Resposta `201`:

```json
{
  "id": 10,
  "tenant_id": 10,
  "channel_id": 1,
  "template_id": 3,
  "canal_tipo": "email",
  "destinatario": "cliente@empresa.co.mz",
  "assunto": "Bem-vindo",
  "corpo": "O seu acesso foi criado com sucesso.",
  "payload": {
    "customer_id": 55
  },
  "referencia_tipo": "cliente",
  "referencia_id": 55,
  "status": "pendente",
  "tentativas": 0,
  "erro": null,
  "enviado_em": null,
  "created_by": 7,
  "created_at": "2026-03-17T09:10:00.000Z"
}
```

#### `POST /api/notifications/messages/:id/send`

Atualiza o estado de envio da mensagem.

Importante: este endpoint nao envia a mensagem para um provider externo. Ele apenas atualiza o registo local.

Body:

```json
{
  "sucesso": true,
  "erro": null
}
```

Comportamento:

- `sucesso=true` marca `status=enviado`
- `sucesso=false` marca `status=falha`
- incrementa `tentativas`
- preenche `enviado_em` quando houver sucesso

### Relatórios

#### `GET /api/notifications/reports/summary`

Devolve resumo agregado das mensagens do tenant.

Resposta `200`:

```json
{
  "total": "15",
  "pendentes": "4",
  "enviados": "9",
  "falhas": "2",
  "por_canal": [
    {
      "canal_tipo": "email",
      "total": "11"
    },
    {
      "canal_tipo": "sms",
      "total": "4"
    }
  ]
}
```

## Códigos de erro comuns

- `400` quando faltam campos obrigatórios
- `401` quando o token nao é enviado ou é inválido
- `404` quando a mensagem nao existe ou nao pode ser processada pelo endpoint `/send`
- `500` para erros internos

## Limitações atuais

- nao existe integração real com SMTP
- nao existe worker assíncrono para processamento em fila
- nao existe publisher/consumer RabbitMQ implementado
- nao existe rendering de template com substituição de variáveis
- nao existe cancelamento explícito de mensagem por endpoint
- nao existe reprocessamento automático por política de retry

## Próximo passo recomendado

Para transformar este serviço em módulo de produção, a próxima iteração deve incluir:

- dispatcher SMTP real para `email`
- publicação/consumo via RabbitMQ
- rendering de templates com `payload`
- retry policy e dead-letter handling
- integração direta com `auth-service`, `faturacao-service` e `compras-service`
