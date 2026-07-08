# Fase 5 — Notificações e Permissão Granular

**Objetivo:** Notificar o candidato da contratação e restringir o botão "Contratar" a uma permissão específica.

## Ficheiros alterados

- `internal/modules/recrutamento/handlers/contratar.go`
- `internal/modules/recrutamento/handlers/notificacoes.go`
- `internal/modules/recrutamento/handlers/candidaturas.go`
- `internal/router/router.go`
- `migrations/20260705000002_recrutamento_contrutacao_rh.up.sql`
- `migrations/20260705000003_recrutamento_permissao_contratar.up.sql`
- `migrations/20260705000003_recrutamento_permissao_contratar.down.sql`

## Funcionalidades

### 1. Notificação automática de contratação

- Novo evento `contratado` no sistema de notificações.
- Template padrão com boas-vindas, número de funcionário e data de admissão.
- Variáveis disponíveis: `nome`, `vaga_titulo`, `codigo_acompanhamento`, `numero_funcionario`, `data_admissao`.
- Email/SMS inseridos na fila `notifications.notification_messages` dentro da transação.
- Push de boas-vindas enviado após `COMMIT`.

### 2. Permissão `recrutamento.contratar`

- Nova migration cria a permissão e herda-a automaticamente a quem já tem `gerir_candidaturas`.
- A rota `POST /api/recrutamento/candidaturas/{id}/contratar` passa a exigir:
  - `recrutamento.contratar` **ou**
  - `recrutamento.gerir_candidaturas`

### 3. Configuração de notificações

- Adicionada coluna `notificar_contratado` em `recrutamento.config_notificacoes`.
- Atualizados endpoints de configuração:
  - `GET /api/recrutamento/config-notificacoes`
  - `PUT /api/recrutamento/config-notificacoes`

### 4. Melhorias de mensagens

- Resposta do endpoint indica número de funcionário e data de admissão.
- Menção ao professor criado quando aplicável.
- Nota de sistema registada na candidatura.
