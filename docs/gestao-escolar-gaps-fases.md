# Gestão Escolar — Gaps & Roadmap de Implementação

**Data de análise:** 2026-06-29  
**Módulo:** Gestão Escolar (backend + frontend + portal do aluno)  
**Estado actual:** 148 endpoints backend, 31 páginas admin, 15 páginas portal do aluno

---

## Contexto da Análise

A análise cobriu três áreas críticas do módulo:
1. **Handlers de Notas & Avaliações** — lançamento, publicação, boletins
2. **Fluxo de Pagamentos de Propinas** — planos, cobranças, integrações financeiras
3. **Portal do Aluno** — autenticação separada, dados do aluno, gestão admin

---

## Arquitectura Actual (Referência Rápida)

### Fluxo de Notas
```
CriarAvaliacaoV2 → publicado=false (rascunho)
  ↓
PublicarAvaliacao → publicado=true → email async aos alunos activos da turma
  ↓
LancarNotasV2 → upsert bulk (ON CONFLICT actualiza)
  ↓
ObterBoletimV2 → média ponderada SUM(nota×peso)/SUM(peso) — só avaliações publicadas
```

### Fluxo de Pagamentos
```
GerarCobrancasPlano → fees para todos os alunos activos do ano lectivo
  ↓
EmitirCobrancaAluno → pendente → emitida
  ↓
[Opcional] AplicarDescontoCobrancaV2
  ├── ApprovalPort existe → 202 Accepted (aguarda aprovação)
  └── Sem fluxo → aplica imediatamente → 204
  ↓
RegistarPagamentoEscolarV2 (transação)
  ├── TreasuryPort.RecordReceipt()        [se criar_movimento_tesouraria=true]
  ├── FinancialPort.RecordReceivable()    [se criar_movimento_financeiro=true]
  ├── AccountingPort.RecordJournalEntry() [se flags + contas configuradas]
  └── InvoicingPort.CreateReceipt()      [se flag + aluno tem client_id]
```

### Portal do Aluno — Auth
```
Aluno → POST /api/portal/aluno/login
  ↓ JWT (tipo:"aluno", 8h) + portal_sessions (hash, IP, user-agent)
  ↓ RequireAlunoAuth middleware (separado do auth principal)
  ↓ /api/portal/aluno/me/* (isolado por tenant_id + student_id)
```

---

## Fase 1 — Segurança & Estabilidade
> **Prioridade: Crítica — implementar antes do go-live do portal**

| # | Gap | Área | Esforço |
|---|---|---|---|
| 1.1 | Rate limiting no login do portal (protecção brute-force) | Portal Auth | Baixo |
| 1.2 | CSRF tokens nos formulários PHP do portal | Portal Frontend | Baixo |
| 1.3 | Account lockout após N tentativas de login falhadas | Portal Auth | Baixo |
| 1.4 | Verificação de assinatura na callback de pagamento do gateway | Pagamentos | Médio |
| 1.5 | Rollback explícito se algum port falhar dentro de `RegisterPayment` | Pagamentos | Médio |

### Detalhes Técnicos — Fase 1

**1.1 Rate Limiting**
- Implementar no middleware do portal antes do handler de login
- Sugestão: Redis com chave `portal:login:rate:{ip}` — max 5 tentativas / 15 min
- Alternativa simples: tabela `portal_login_attempts(ip, tentativas, bloqueado_ate)`

**1.2 CSRF**
- Gerar token em `PortalAlunoSession` e validar em cada POST
- Injectar como campo oculto em todos os formulários PHP do portal

**1.3 Account Lockout**
- Adicionar coluna `portal_login_tentativas int` e `portal_bloqueado_ate timestamptz` na `school_students`
- Incrementar a cada falha, resetar a cada sucesso
- Bloquear após 5 tentativas por 30 minutos

**1.4 Callback Signature**
- Gateway deve enviar assinatura HMAC no header (ex: `X-Gateway-Signature`)
- Validar no início de `CallbackPagamentoEscolar` antes de processar

**1.5 Transaction Rollback**
- A transação DB faz rollback se o INSERT/UPDATE falhar
- Mas os ports externos (Treasury, Financial, etc.) não têm rollback
- Solução: registar estado dos ports numa tabela de log e reprocessar em caso de falha

---

## Fase 2 — Operações Administrativas
> **Prioridade: Alta — funcionalidades que o staff precisa diariamente**

| # | Gap | Área | Esforço |
|---|---|---|---|
| 2.1 | Página admin de gestão do portal por aluno (activar/desactivar/convidar/reset) | Portal Admin UI | Médio |
| 2.2 | Activação em massa do portal para uma turma inteira | Portal Admin | Médio |
| 2.3 | Relatório de acesso ao portal (sessões activas, último acesso) | Portal Admin | Médio |
| 2.4 | Webhook pós-aprovação de desconto (aplicar desconto após aprovação) | Pagamentos | Alto |
| 2.5 | Cancelamento de cobranças com campo de motivo | Pagamentos | Baixo |

### Detalhes Técnicos — Fase 2

**2.1 Página Admin de Portal**
- Backend: endpoints `GET /api/escolar/students/{id}/portal/status` já existe
- Frontend: criar página `escolar_portal_alunos.php` com tabela de alunos + acções
- Acções por linha: activar, desactivar, enviar convite, reset senha

**2.2 Activação em Massa**
- Novo endpoint: `POST /api/escolar/classes/{id}/portal/activate-all`
- Itera sobre matrículas activas da turma e activa portal para cada aluno
- Envia convite por email em batch (goroutine por aluno)

**2.3 Relatório de Acesso**
- Query na tabela `portal_sessions` agrupada por aluno
- Campos: aluno, último acesso, sessões activas, total sessões, IPs distintos

**2.4 Webhook Pós-Aprovação**
- Quando aprovador aprova o desconto, o módulo de aprovações deve chamar callback
- Callback: `POST /api/escolar/student-invoices/{id}/discount/apply` (novo endpoint interno)
- Aplica o desconto guardado na approval request

**2.5 Cancelamento com Motivo**
- Adicionar campo `cancelamento_motivo text` na tabela `school_fees`
- Actualizar endpoint de cancelamento para aceitar body `{motivo: string}`

---

## Fase 3 — Experiência do Aluno
> **Prioridade: Importante — aumenta utilidade do portal para os alunos**

| # | Gap | Área | Esforço |
|---|---|---|---|
| 3.1 | Download PDF do boletim | Portal | Médio |
| 3.2 | Download PDF do recibo de pagamento | Portal | Médio |
| 3.3 | Selector de período no boletim (backend existe, falta no frontend) | Portal | Baixo |
| 3.4 | Paginação em presenças e empréstimos (actualmente retorna tudo) | Portal | Baixo |
| 3.5 | Detalhe de notas por avaliação (actualmente só mostra média) | Portal | Médio |
| 3.6 | Verificação de email antes de activar o portal | Portal | Médio |

### Detalhes Técnicos — Fase 3

**3.1 & 3.2 PDF Downloads**
- Backend: novo endpoint `GET /api/portal/aluno/me/boletim/pdf` e `GET /api/portal/aluno/me/cobrancas/{id}/recibo/pdf`
- Usar biblioteca Go para gerar PDF (ex: `gofpdf` ou `chromedp` com template HTML)
- Frontend: botão "Descarregar PDF" nas páginas `boletim.php` e `cobrancas.php`

**3.3 Selector de Período**
- Endpoint já aceita `?term_id=X`
- Frontend `boletim.php`: adicionar `<select>` com os períodos do ano activo
- Popular o select via `GET /api/escolar/years/{ano_activo}/terms`

**3.4 Paginação**
- Adicionar `?page=1&limit=20` nos endpoints de presenças e empréstimos
- Frontend: navegação de páginas simples

**3.5 Detalhe de Notas**
- Novo endpoint: `GET /api/portal/aluno/me/notas?subject_id=X&term_id=Y`
- Retorna lista de avaliações com nota individual (não só média)
- Frontend: expandir secção do boletim com detalhe por disciplina

**3.6 Verificação de Email**
- Ao activar portal, enviar email de verificação antes de gravar `portal_ativo=true`
- Token de verificação separado do token de convite
- Adicionar coluna `portal_email_verificado boolean` na `school_students`

---

## Fase 4 — Notificações & Comunicação
> **Prioridade: Médio Prazo — automatismos que reduzem trabalho manual**

| # | Gap | Área | Esforço |
|---|---|---|---|
| 4.1 | Email ao aluno quando novas notas são publicadas (já parcialmente implementado) | Notas | Baixo |
| 4.2 | Email/SMS de cobrança vencida (reminder automático) | Pagamentos | Médio |
| 4.3 | Email de confirmação de pagamento recebido | Pagamentos | Baixo |
| 4.4 | Notificação ao aluno quando nova mensagem/aviso é publicado | Portal | Médio |
| 4.5 | Log de auditoria de envio de notificações | Geral | Baixo |

### Detalhes Técnicos — Fase 4

**4.1 Email de Notas**
- Já existe goroutine em `PublicarAvaliacao` que envia email aos alunos
- Gap: apenas envia email se aluno tem `user_id` linkado — completar para usar `portal_email`

**4.2 Reminder de Cobrança Vencida**
- Job agendado (cron diário) que busca `school_fees WHERE status IN ('emitida','parcial') AND data_vencimento < NOW()`
- Envia email/SMS via NotificationPort
- Controlar via tabela `escola_notification_log` para não repetir no mesmo dia

**4.3 Confirmação de Pagamento**
- Após `RegistarPagamentoEscolarV2` com sucesso, chamar NotificationPort com template de confirmação
- Incluir: valor, referência, saldo restante

**4.4 Notificação de Mensagens**
- Em `PublicarMensagemEscolar`, adicionar goroutine similar ao de notas
- Envia email aos alunos da turma alvo (ou todos, conforme `audience_type`)

**4.5 Log de Notificações**
```sql
CREATE TABLE gestao_escolar.notification_log (
    id            bigserial PRIMARY KEY,
    tenant_id     bigint NOT NULL,
    tipo          text,   -- 'email', 'sms'
    destinatario  text,
    assunto       text,
    enviado_em    timestamptz DEFAULT NOW(),
    sucesso       boolean,
    erro          text
);
```

---

## Fase 5 — Portal do Encarregado
> **Prioridade: Q3 2026 — extensão natural do portal do aluno**

| # | Gap | Área | Esforço |
|---|---|---|---|
| 5.1 | Autenticação separada para encarregados (tipo: "encarregado") | Portal | Alto |
| 5.2 | Dashboard do encarregado: notas, presenças, cobranças do educando | Portal | Alto |
| 5.3 | Encarregado com múltiplos educandos (troca de contexto) | Portal | Médio |
| 5.4 | Notificações ao encarregado por email/SMS | Portal | Médio |
| 5.5 | Ligação encarregado → cliente (integração com módulo de clientes) | Portal | Médio |

### Detalhes Técnicos — Fase 5

**5.1 Auth do Encarregado**
- Nova tabela `portal_encarregado_sessions`
- JWT com `tipo: "encarregado"` + `guardian_id`
- Novo middleware `RequireEncarregadoAuth`
- Credenciais na tabela `school_guardians` (adicionar `portal_email`, `portal_password_hash`, `portal_ativo`)

**5.2 & 5.3 Dashboard Multi-Educando**
- Endpoint: `GET /api/portal/encarregado/me/educandos` — lista educandos
- Endpoint: `GET /api/portal/encarregado/educando/{id}/boletim`
- Endpoint: `GET /api/portal/encarregado/educando/{id}/cobrancas`
- Frontend: selector de educando no topo do portal

**5.5 Ligação com Clientes**
- Encarregado "principal" já pode ter `client_id` em `school_guardians`
- Usar essa ligação para emitir recibos de pagamento no nome do encarregado

---

## Fase 6 — Pagamento Directo & Financeiro Avançado
> **Prioridade: Q4 2026 — integração de gateways e funcionalidades financeiras avançadas**

| # | Gap | Área | Esforço |
|---|---|---|---|
| 6.1 | Pagamento M-Pesa directo no portal do aluno | Pagamentos | Alto |
| 6.2 | Pagamento por transferência bancária com referência automática | Pagamentos | Alto |
| 6.3 | Planos de parcelamento de propinas | Pagamentos | Alto |
| 6.4 | Isenções e bolsas com fluxo de aprovação | Pagamentos | Médio |
| 6.5 | Relatório de inadimplência avançado com aging (30/60/90 dias) | Pagamentos | Médio |

### Detalhes Técnicos — Fase 6

**6.1 Integração M-Pesa**
- Usar M-Pesa Mozambique API (C2B — Customer to Business)
- Gerar referência de pagamento e QR code no portal
- Callback já existe: `POST /api/escolar/payments/callback`
- Adicionar verificação de assinatura específica do M-Pesa (ver Fase 1.4)

**6.2 Referência Bancária**
- Integrar com sistema de referências do banco (ATM/Internet Banking)
- Gerar entidade + referência automática por cobrança
- Campos já existem: `school_fees.entidade` e `school_fees.referencia`

**6.3 Parcelamento**
- Nova tabela `school_fee_installments(fee_id, numero, valor, data_vencimento, pago)`
- Endpoint: `POST /api/escolar/student-invoices/{id}/installments` — divide cobrança
- Cada parcela gera registo separado de pagamento

**6.4 Isenções e Bolsas**
- Tabela já existe: `school_student_fee_discounts`
- Adicionar endpoint de criação de isenção total (`tipo: "isencao_total"`)
- Fluxo de aprovação via ApprovalPort (mesmo mecanismo do desconto)

**6.5 Aging de Inadimplência**
```sql
SELECT
    CASE
        WHEN data_vencimento >= NOW() - INTERVAL '30 days' THEN '0-30 dias'
        WHEN data_vencimento >= NOW() - INTERVAL '60 days' THEN '31-60 dias'
        WHEN data_vencimento >= NOW() - INTERVAL '90 days' THEN '61-90 dias'
        ELSE '+90 dias'
    END AS faixa,
    COUNT(*) cobranças,
    SUM(valor_total - desconto - valor_pago) saldo_em_dívida
FROM gestao_escolar.school_fees
WHERE tenant_id=$1 AND status IN ('emitida','parcial')
GROUP BY 1 ORDER BY 1
```

---

## Resumo Executivo

| Fase | Foco | Nº Items | Quando |
|---|---|---|---|
| **1** | Segurança crítica | 5 | Antes do go-live |
| **2** | Operações admin em falta | 5 | Sprint 1–2 |
| **3** | Experiência do aluno no portal | 6 | Sprint 3–4 |
| **4** | Notificações automáticas | 5 | Sprint 5–6 |
| **5** | Portal do encarregado | 5 | Q3 2026 |
| **6** | Pagamento directo & financeiro avançado | 5 | Q4 2026 |
| **Total** | | **31 gaps** | |

---

## Dependências Entre Fases

```
Fase 1 (Segurança)
  └── deve preceder todas as outras fases

Fase 2 (Admin)
  └── 2.4 (webhook pós-aprovação) depende do módulo de Aprovações estar configurado

Fase 3 (Experiência Aluno)
  └── 3.6 (verificação email) pode ser feita em paralelo com 3.1-3.5

Fase 4 (Notificações)
  └── depende de NotificationPort estar wired para email/SMS real

Fase 5 (Portal Encarregado)
  └── depende de Fase 3 estar completa (portal aluno estável)

Fase 6 (Pagamento Directo)
  └── 6.1 M-Pesa depende de Fase 1.4 (validação de callback)
  └── 6.3 Parcelamento depende de Fase 2.5 (cancelamento de cobranças)
```
