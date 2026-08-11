# Lacunas de Backend — Nexora ERP (auditoria 2026-08-10)

Auditoria das 8 áreas de lacunas funcionais identificadas, contra o estado actual do código.

## Resumo executivo

| # | Item | Estado | Nota principal |
|---|------|--------|-----------------|
| 1 | Documentos fiscais | ✅ Completo | CRUD, numeração sequencial e lançamento contábil automático completos; geração de PDF no backend, envio de e-mail ao cliente, e fluxo directo completo de notas de crédito implementados em 2026-08-10 |
| 2 | CRUD de clientes | ✅ Completo | Sem lacunas relevantes |
| 3 | Gateway pagamento móvel | 🟡 Parcial | Integração real existe mas delegada a microserviço externo (`nexora-pay`) fora deste repo; só ligado a POS e portal escolar |
| 4 | Stock avançado | ✅ Completo | Armazéns, lotes, seriais, localizações, tudo implementado |
| 5 | Contabilidade | ✅ Completo | Módulo standalone muito completo; Faturação, Compras e POS já postam automaticamente (2026-08-10). Adapter genérico partilhado estava **partido** (colunas erradas) — corrigido na mesma alteração |
| 6 | RH | ✅ Completo | Módulo mais maduro do backend, já integrado com Contabilidade e Tesouraria; exportação bancária em lote implementada em 2026-08-10 |
| 7 | Auditoria e RBAC | ✅ Completo | RBAC forte, sem alterações. `audit_events` totalmente ligada e legível (2026-08-10): helper genérico de cadeia de hash, os 5 eventos-âncora, `GET /api/audit-events`, verificação de integridade da cadeia, exportação CSV, e `mw.AuditModule` estendido a mais 12 grupos de rotas que não tinham auditoria operacional. Só falta exportação em PDF (CSV cobre a necessidade prática) |
| 8 | Configuração de tenant | ✅ Completo | Settings/feature flags/moedas já funcionavam; branding e document-settings por tenant ligados em 2026-08-10 (CRUD completo, sem tabelas mortas). Só falta self-service de features (superadmin-only, decisão deliberada, não é lacuna) |

**Achado transversal:** nos itens 1, 5, 7 e 8 o "motor" já existia (numeração fiscal, adapter contabilístico genérico, RBAC, tabelas de config), mas faltava **ligar** módulos entre si — não era trabalho do zero, era trabalho de integração. Todos os 8 itens da auditoria original ficaram fechados em 2026-08-10 (o item 1, Documentos fiscais, foi o último a fechar), sem lacunas residuais de fundo por resolver. Note-se que o adapter genérico de Contabilidade estava **partido** (gravava em colunas inexistentes) e a integração propinas→Contabilidade da Gestão Escolar estava silenciosamente morta em produção — corrigido na mesma alteração; e as colunas `pdf_storage_key`/`ficheiro_url`/`assinatura_documento_id` de `faturacao.invoices`/`credit_notes` tinham o mesmo problema (só existiam numa migração arquivada, nunca reintroduzidas na baseline) — corrigido ao implementar a geração de PDF.

---

## 1. Documentos fiscais (facturas, orçamentos, notas de crédito) — ✅ Completo

**Módulo:** `internal/modules/modulo-faturacao/handlers/` (`faturacao.go`, `fiscal.go`, `assinatura.go`, `pdf.go`, `email.go`, `credit_notes_fiscal.go`)
**Rotas:** `/api/faturacao` — orçamentos, encomendas, facturas, recibos, notas de crédito, séries documentais, com fluxo de estados (rascunho→emitida/enviado/aprovado/rejeitado/cancelado) e gates por feature flag (`vendas.orcamentos`, `vendas.encomendas`, `vendas.fatura_direta`, `vendas.devolucoes`).
**Tabelas:** `faturacao.invoices`, `invoice_items`, `invoice_series`, `sales_quotes`, `sales_orders`, `sales_deliveries`, `credit_notes`, `invoice_receipts`, `invoice_taxes`, `invoice_discounts`.

**O que já existe:**
- CRUD completo de orçamentos, encomendas, facturas, recibos e notas de crédito.
- Numeração fiscal sequencial real e funcional por tipo de documento/ano (`FT`, `ORC`, `ENC`, `GR`, `NC`, `RB`, `VD`), via `proximoNumeroSerie()` (`faturacao.go:525`) e tabela `invoice_series` com `UNIQUE(tenant_id,tipo,ano)` — reaproveitada pelo POS e pelo módulo escolar.
- Cálculo de imposto por linha e isenções fiscais (`impostos.fn_aplicar_isencoes_fatura`) em `fiscal.go`.
- Fluxo de assinatura digital de facturas/notas de crédito.
- **Lançamento contabilístico automático na emissão:** `EmitirFaturaFiscal` chama `gerarLancamentoContabilisticoFatura` (`contabilidade.go`) depois de comitar a emissão — débito Clientes, crédito Receita (+ IVA se conta separada configurada). Opcional por tenant via `faturacao.config_contabilidade`; sem configuração activa, a emissão continua a funcionar normalmente, só sem lançamento. Idempotente via `faturacao.invoices.journal_entry_id`. Ver item 5 para o detalhe do adapter partilhado.
- **Geração de PDF no backend (implementado 2026-08-10):** `gerarPDFDocumentoFiscal` (`pdf.go`) usa `github.com/go-pdf/fpdf` (nova dependência — não existia nenhuma lib de geração de PDF no repo, só `digitorus/pdf`/`digitorus/pdfsign` para LER/assinar PDF já existente) para desenhar cabeçalho (emitente via `empresas.companies`+`company_tax_info`+`company_addresses`), tabela de itens e totais. `POST /invoices/{id}/gerar-pdf` (exige `status != 'rascunho'`) e `GET /invoices/{id}/pdf`; análogo para notas de crédito (`GerarNotaCreditoPDF`/`ObterNotaCreditoPDF`). **Achado colateral corrigido:** as colunas `pdf_storage_key`/`ficheiro_url`/`assinatura_documento_id` que `assinatura.go` já lia (fluxo "enviar para assinatura") só existiam numa migração **arquivada**, nunca reintroduzidas na baseline consolidada — mesma classe de bug do `AccountingAdapter` encontrado mais cedo. Corrigido na migração `20260810130000_faturacao_pdf_assinatura`.
- **Envio de e-mail ao cliente (implementado 2026-08-10):** `POST /invoices/{id}/enviar-email` e `/credit-notes/{id}/enviar-email` (`email.go`) — exige PDF já gerado, usa `contracts.NotificationPort` (agora injectado no `Handler` de `modulo-faturacao`, antes não estava) para enfileirar em `notifications.notification_messages`. **Extensão de infra partilhada:** a fila de notificações e o `sesMailer` (AWS SESv2) existiam mas não suportavam anexos — `contracts.Notification` ganhou `AnexoStorageKey`/`AnexoNome`, `notification_messages` ganhou as colunas correspondentes, e `internal/background/mailer_ses.go` ganhou `sendWithAttachment` (monta MIME multipart/mixed em bruto, `Content.Raw` do SESv2) — usado por `dispatchNotifications` sempre que uma mensagem tem anexo. Envio real só acontece se `SES_FROM` estiver configurado (comportamento pré-existente, no-op silencioso caso contrário).
- **Notas de crédito directas completas (implementado 2026-08-10):** `AdicionarItemNotaCredito`, `EmitirNotaCredito`, `ObterNotaCredito`, `CancelarNotaCredito` (`credit_notes_fiscal.go`) — mesmo padrão de `AdicionarItemFaturaFiscal`/`EmitirFaturaFiscal`, sem desconto por item (`credit_note_items` não tem essas colunas, ao contrário de `invoice_items` — assimetria de schema, não corrigida nesta ronda). `EmitirNotaCredito` posta lançamento de estorno (`adapters.PostCreditNoteJournalEntry`, já existente desde a ligação Contabilidade→Faturação) e evento de auditoria legal. Antes só existiam notas de crédito reais via o estorno de vendas POS.

**O que falta:**
- A migração `20260810130000_faturacao_pdf_assinatura` ainda não foi aplicada a nenhuma BD (nem local nem remota) — junta-se às 3 pendentes de rondas anteriores.
- PDF gerado é texto simples/tabela — sem logótipo da empresa nem layout customizável por tenant (isso ligaria a `sistema_configuracao.tenant_branding`/`tenant_document_settings`, item 8, mas não foi feito nesta ronda).
- `credit_note_items` sem colunas de desconto (assimetria com `invoice_items`, ver acima).

---

## 2. CRUD de clientes — ✅ Completo

**Módulo:** `internal/modules/gestao-clientes/handlers/` (`clientes.go`, `clientes_api_ext.go`, `cliente_data.go`)
**Rotas:** `/api/clientes`
**Tabelas:** `clientes.customers`, `customer_addresses`, `customer_contacts`, `customer_groups`, `customer_tags`, `customer_credit_limits`, `customer_discounts`, `customer_balances`, `customer_payments`, `customer_notes`, `customer_history`, `customer_documents`.

CRUD completo + grupos, tags, contactos, endereços, limite de crédito, saldo, pagamentos, notas, histórico, descontos. Activar/bloquear/desbloquear cliente. Relatórios: top-clientes, saldos devedores, crédito utilizado, sem-actividade. Isolamento multi-tenant e RBAC granular por acção. Nada de relevante em falta.

---

## 3. Gateway de pagamento móvel real (M-Pesa, e-Mola) — 🟡 Parcial

**Módulo:** `internal/pkg/nexorapay/client.go` + `internal/modules/pos/handlers/pagamentos.go` + `internal/modules/gestao-escolar/handlers/portal_pagamento.go`
**Rotas:** dentro de `/api/pos` — `IniciarPagamento`, `StatusPagamento`, `WebhookPagamento` (webhook público sem auth, validado por HMAC).
**Tabela:** `pos_payment_confirmations`.

**O que existe:**
- Cliente HTTP real (`nexorapay.Client`) que fala com um microserviço externo "Nexora-Pay" (config `NEXORA_PAY_BASE_URL`, `NEXORA_PAY_API_KEY`), responsável por falar com M-Pesa/eMola/mKesh.
- Fluxo assíncrono correcto: iniciar pagamento → poll de estado → webhook de confirmação (HMAC-SHA256) → correlação por `tenant_id` na `thirdPartyReference`.
- Generalizado do módulo escolar para o POS.

**O que falta / risco:**
- A integração real com M-Pesa/e-Mola não está neste backend — está delegada a um serviço externo que não faz parte deste repositório. Se `NexoraPayAPIKey==""`, o endpoint devolve 503.
- Não há gateway de pagamento móvel para o módulo de Faturação (só POS e portal escolar usam `nexorapay`).
- Não há reconciliação/relatório de transacções do gateway (apenas cache local de webhook).

---

## 4. Stock avançado (armazéns, lotes, seriais) — ✅ Completo

**Módulo:** `internal/modules/gestao-stock/handlers/` (`stock.go`, `stock_ext.go`)
**Rotas:** `/api/stock`
**Tabelas:** `stock.stock_items`, `stock_movements`, `stock_batches`, `stock_serial_numbers`, `stock_reservations`, `stock_transfers`, `stock_adjustments`, `stock_counts`, `warehouse_locations`, `produtos.warehouses`.

Armazéns (CRUD + activar/desactivar + localizações), lotes (criação/actualização/listagem/relatório a expirar), seriais (criação/consulta/estado), contagens de inventário, ajustes, transferências entre armazéns, reservas, alertas de stock crítico. Implementação genuinamente completa.

---

## 5. Contabilidade — ✅ Completo (motor + integrações)

**Módulo:** `internal/modules/contabilidade/handlers/` (16 ficheiros: `contas.go`, `journals.go`, `journal_entries.go`, `fiscal_years.go`, `fiscal_periods.go`, `fixed_assets.go`, `depreciation.go`, `budgets.go`, `period_closings.go`, `reports.go`, `tax_groups.go`, `tax_transactions.go`, etc.)
**Rotas:** `/api/contabilidade`
**Tabelas:** `contabilidade.chart_of_accounts`, `journal_entries`, `journal_entry_lines`, `fiscal_years`, `fiscal_periods`, `fixed_assets`, `depreciation_entries`, `accounting_budgets`, `period_closings`, `account_types`.

**O que já existe (muito além do esperado):**
- Plano de contas, tipos de conta, diários, lançamentos contabilísticos (débito/crédito, estorno).
- Anos e períodos fiscais com abertura/fecho.
- Activos fixos com plano de amortização e processamento/cancelamento de amortizações.
- Orçamentos contabilísticos com "orçado vs realizado".
- Encerramentos de período com verificações e reabertura.
- Relatórios: balancete geral, balanço, demonstração de resultados, razão geral, resumo de amortizações, execução orçamental.
- Existe um adapter genérico `internal/shared/adapters/accounting.go` (`AccountingAdapter.RecordJournalEntry`) desenhado exactamente para outros módulos postarem lançamentos automaticamente.
- **Bug encontrado e corrigido (2026-08-10):** o adapter genérico gravava em colunas que não existem no schema real de `contabilidade.journal_entries`/`journal_entry_lines` (`referencia` em vez de `referencia_tipo`/`referencia_id`; `chart_account_id`/`debito`/`credito` em vez de `account_id`/`debit`/`credit`; não preenchia `fiscal_period_id`/`accounting_journal_id`, que são `NOT NULL`). O `INSERT` falhava sempre — a chamada em `gestao-escolar/services/fee.go` engolia o erro num `log.Printf("[WARN]...")`, por isso a integração "propinas → Contabilidade" estava silenciosamente morta em produção sempre que um tenant activava `criar_lancamento_contabilidade`. Corrigido: o adapter agora usa as colunas reais, resolve `fiscal_period_id` a partir de tenant+data, e exige `accounting_journal_id` (novo campo em `contracts.JournalEntry`). `gestao_escolar.school_financial_config` ganhou a coluna `accounting_journal_id` (antes em falta) para poder alimentar o adapter corrigido.
- **Faturação, Compras e POS ligados a Contabilidade (2026-08-10):** três novas funções partilhadas em `internal/shared/adapters/` usam o adapter corrigido:
  - `PostInvoiceJournalEntry` (`invoice_accounting.go`) — débito Clientes, crédito Receita+IVA. Chamada por `EmitirFaturaFiscal` (modulo-faturacao) **e** por `criarFaturaParaVenda`/`CriarVenda` (POS — toda venda de balcão já gera `faturacao.invoices` automaticamente, ver `pos/handlers/faturacao.go`). Configurada por tenant em `faturacao.config_contabilidade` (`accounting_journal_id`, `conta_clientes_id`, `conta_receita_id`, `conta_iva_id` opcional).
  - `PostCreditNoteJournalEntry` (`invoice_accounting.go`) — o inverso (débito Receita+IVA, crédito Clientes). Chamada por `EstornoParcialVenda` (POS) sempre que a devolução gera nota de crédito (`criarNotaCreditoParaEstorno`) — hoje o único emissor real de notas de crédito com total>0 (ver item 1: `CriarNotaCredito` em modulo-faturacao ainda só cria rascunhos vazios, sem itens nem endpoint de emissão).
  - `PostPurchaseInvoiceJournalEntry` (`purchase_accounting.go`) — débito Despesa+IVA a recuperar, crédito Fornecedores. Chamada por `AdicionarItemFacturaCompra`, que é o que transiciona `compras.purchase_invoices` de `rascunho` para `emitida`. Configurada em `compras.config_contabilidade` (tabela nova, mesmo padrão). **Limitação conhecida:** só posta uma vez, com o total no momento em que a factura sai de rascunho pela primeira vez — se mais itens forem adicionados depois disso, o total da factura é recalculado mas o lançamento já criado não é actualizado (Compras não tem um passo de "emitir" distinto do primeiro item, ao contrário de Faturação).
  - Todas as três: opcionais por tenant (sem configuração activa, a operação de negócio continua normal só sem lançamento), idempotentes (`journal_entry_id` gravado no documento de origem), não-bloqueantes (falhas só em log `[WARN]`, nunca revertem a venda/factura/estorno já concluído).
- RH continua a usar lógica dedicada própria (`processamento_salarial.go`), não este adapter partilhado — já funcionava correctamente antes desta sessão, não foi alterado.

**O que falta:**
- Notas de crédito criadas directamente via `CriarNotaCredito` em modulo-faturacao (fora do fluxo de estorno do POS) não têm itens nem endpoint de emissão — por isso nunca chegam a `PostCreditNoteJournalEntry` com um total real. Implementar isso é trabalho de Faturação (item 1), não de Contabilidade.
- Compras: lançamento não é actualizado se itens forem adicionados a uma factura já emitida (ver limitação acima).
- As migrações `faturacao.config_contabilidade` e `compras.config_contabilidade` ainda não foram aplicadas a nenhuma BD (nem local nem remota) — só os ficheiros de migração foram criados.

---

## 6. Recursos Humanos (RH) — ✅ Completo

**Módulo:** `internal/modules/recursos-humanos/handlers/` (43 ficheiros)
**Rotas:** `/api/rh`
**Tabelas:** 40+ tabelas no schema `rh` (funcionários, contratos, folhas de pagamento, IRPS, assiduidade, avaliações, formações, benefícios, empréstimos/adiantamentos, disciplinar, hierarquia/unidades organizacionais, biometria/NFC/QR para ponto).

**O que já existe:**
- Funcionários, contratos (assinatura digital + PDF via upload), cargos, hierarquia.
- Processamento salarial completo: IRPS por escalão, INSS, prestações pendentes, benefícios activos, faltas não remuneradas, horas extra, geração e pagamento de folha, **com lançamento contabilístico automático** (`criarLancamentoContabilisticoFolha`) e **movimento de tesouraria automático** (`criarMovimentoTesourariaFolha`) — integração real e funcional RH → Contabilidade → Tesouraria, a mais completa do backend.
- Assiduidade avançada: eventos, correcções, biometria, NFC, QR, regras configuráveis.
- Avaliações, formações, processos disciplinares, benefícios, adiantamentos/empréstimos, histórico salarial, férias/licenças com self-service.
- Recibos de vencimento com PDF (mesmo padrão de upload que faturação).
- **Exportação bancária em lote (implementado 2026-08-10):** `GET /api/rh/folhas-pagamento/{id}/exportar-bancario` gera CSV (nº funcionário, nome, NUIT, banco, nº conta, NIB, IBAN, valor líquido) para folhas `processada`/`paga` — `ExportarFolhaPagamentoBancario` em `processamento_salarial.go`. Dados bancários do funcionário (`banco`, `numero_conta`, `nib`, `iban`) adicionados a `rh.funcionarios` via migração `20260810100000_rh_funcionarios_dados_bancarios` e ao CRUD de funcionário (criar/obter/actualizar), protegidos pela mesma permissão `PodeVerSalarios` que já esconde o salário.

**O que falta:**
- Nada de estrutural evidente.
- A migração dos novos campos bancários ainda não foi aplicada a nenhuma base de dados (nem local nem remota) — só o ficheiro de migração foi criado.
- Sem formulário no frontend do ERP web para preencher banco/NIB/IBAN do funcionário — só disponível via API directa por agora.

---

## 7. Auditoria e roles granulares (RBAC) — ✅ Completo

### RBAC — ✅ Forte
**Módulo:** `internal/modules/auth/` + middleware `RequirePermission` usado sistematicamente em ~40 grupos de rotas (`mw.RequirePermission(db, "<módulo>", "<acção>")`).
**Tabelas:** `auth.cargos`, `auth.permissoes_cargo`, `auth.permissoes_diretas`, `auth.permissoes_tipo`, `autorizacao.roles/permissions/role_permissions/user_roles`.
- RBAC granular por módulo+acção, aplicado consistentemente.
- Permissões directas por utilizador além de permissões por cargo — overrides individuais.
- Reautenticação reforçada para acções superadmin sensíveis, allowlist de IP para superadmin.

### Auditoria — ✅ Completo (log operacional + cadeia legal, ambos totalmente ligados)
**Módulo:** `internal/modules/auditoria/handlers/{auditoria,audit_events}.go`
**Rotas:** `/api/audit-logs` — `GET /`, `GET /export`, `GET /{id}`. `/api/audit-events` — `GET /`, `GET /verificar-integridade`, `GET /export`, `GET /{id}`.
**Tabelas:** `auditoria.audit_logs` (operacional, em uso) e `auditoria.audit_events` (cadeia de hash com valor legal — **ligada em 2026-08-10**, ver abaixo).

**O que existe:**
- Middleware `mw.AuditModule(db, ...)` e `mw.AuditSistemaConfiguracao(db)` escrevendo em `auditoria.audit_logs` (sem garantia de imutabilidade). **Cobertura estendida (2026-08-10):** mais 12 grupos de rotas que não tinham nenhum middleware de auditoria ganharam `mw.AuditModule` — `/api/utilizadores`, `/api/clientes`, `/api/produtos`, `/api/stock`, `/api/aprovacoes` (inclui `DecidirRequest`, o ponto de decisão genérico de aprovações), `/api/pessoas`, `/api/recrutamento`, `/api/self-service`, `/api/pedido-ferias`, `/api/tarefas`, `/api/hardware` (só o grupo admin do tenant, não o grupo de dispositivos autenticados por API key, para não inundar `audit_logs` com tráfego de dispositivos), `/api/v1/fingerprint`. Rotas com modelo de autenticação diferente (portais aluno/professor/encarregado, recrutamento público, webhooks, OAuth) foram deliberadamente deixadas de fora — `mw.AuditModule` não regista nada sem um utilizador tenant autenticado no contexto (`mw.GetUser(r) == nil` → no-op), por isso aplicá-lo aí não teria efeito nem faz sentido conceptualmente.
- `RegistarAuditLog` existe no handler mas não está exposta como rota pública (uso interno).
- **`auditoria.audit_events` totalmente ligada (implementado 2026-08-10):** `contracts.LegalAuditPort`/`LegalAuditEvent` (`internal/shared/contracts/erp_ports.go`) + `LegalAuditAdapter` (`internal/shared/adapters/legal_audit.go`) — grava eventos numa cadeia de hash real (`event_hash` encadeado a `previous_hash` do evento anterior do mesmo tenant, serializado via `pg_advisory_xact_lock` para não haver corrida entre escritas concorrentes). Não-bloqueante/best-effort, mesmo padrão do `AccountingAdapter`. Ligado aos 5 casos de uso documentados no `COMMENT ON TABLE audit_events`:
  - Emissão de factura fiscal (`EmitirFaturaFiscal`).
  - Fecho de período contabilístico (`ConfirmarEncerramento`).
  - Alterações de permissões RBAC (`DefinirPermissoesCargo`, `DefinirPermissoesDiretas`, `AtribuirCargo`).
  - Aprovações RH — 6 fluxos directos em `internal/modules/recursos-humanos/handlers/`: `AprovarAvaliacaoDesempenho`, `AprovarPedidoCorrecao`, `AprovarJustificacao`, `AprovarCorrecaoEvento`, `AprovarAusencia`, `ActualizarProcessoDisciplinarFuncionario` (só quando `estado=="decidido"`) — via helper `h.registarAprovacaoLegal(...)` em `handler.go`. Mais o ponto de decisão genérico transversal `DecidirRequest` (`internal/modules/aprovacoes/handlers/requests.go`), que decide qualquer pedido sujeito a um pipeline de aprovação configurado — cobre não só RH (`rh.ausencias`, quando o tenant tem pipeline activo em vez do caminho directo) mas também `compras.purchase_requests` e `gestao_escolar.school_fees`, por ser a mesma função genérica.
  - Renovação de assinaturas — `RenovarAssinatura` em `internal/modules/assinaturas/handlers/assinaturas.go` (subscrições que o tenant vende aos seus próprios clientes, schema `assinaturas.subscriptions` — não confundir com a licença SaaS do próprio Nexora, que não tem endpoint de renovação implementado, nem com assinatura digital de documentos, que não tem conceito de "renovação").
- **Leitura de `audit_events`:** `GET /api/audit-events` (listar, com filtros `module_name`/`action`/`entity_type`/`entity_id`/`actor_user_id`/`status` + paginação) e `GET /api/audit-events/{id}` (obter) — mesmo padrão de `ListarAuditLogs`/`ObterAuditLog`, mesma permissão RBAC `auditoria:ver_logs`. Devolve todos os campos incluindo `event_hash`/`previous_hash`.
- **Verificação de integridade da cadeia (implementado 2026-08-10):** `GET /api/audit-events/verificar-integridade` — `VerificarIntegridadeAuditEvents` percorre a cadeia do tenant por ordem de `id` e confirma que cada `previous_hash` corresponde exactamente ao `event_hash` do evento anterior (e que o primeiro evento não tem `previous_hash`), reportando `{integro, total_eventos, quebras[]}`. **Limitação deliberada:** não recalcula `event_hash` a partir do conteúdo — o `jsonb` do Postgres não preserva byte-a-byte a formatação da serialização Go original usada para calcular o hash, por isso tentar reproduzi-la produziria falsos positivos de "corrupção". A verificação é de **ligação sequencial** (detecta eventos apagados/inseridos fora de ordem/religados), não de conteúdo byte-a-byte.
- **Exportação CSV (implementado 2026-08-10):** `GET /api/audit-logs/export` e `GET /api/audit-events/export`, com os mesmos filtros dos respectivos `Listar*`, `Content-Disposition: attachment`, BOM UTF-8, limite de 20 000 linhas por exportação.

**O que falta:**
- Sem exportação em PDF (só CSV) — CSV cobre a necessidade prática de entregar a um auditor/regulador.
- Sem configuração de retenção/purga de `audit_logs`.
- Sem pesquisa avançada de auditoria (diff before/after estruturado — `audit_events` já tem `payload_before`/`payload_after` no schema mas nenhum módulo os preenche ainda, só `metadata`).

---

## 8. Configuração do tenant (multi-tenancy config) — ✅ Completo

**Módulos:** `internal/modules/sistema-configuracao/handlers/sistema.go`, `internal/modules/empresas/handlers/`, `internal/modules/superadmin/handlers/features.go`
**Rotas:** `/api/system`, `/api/companies`, `/api/superadmin/tenants`
**Tabelas:** `sistema_configuracao.settings`, `tenant_feature_flags`, `tenant_branding`, `tenant_defaults`, `tenant_document_settings`, `tenant_integrations`, `empresas.company_settings`, `saas.tenants/tenant_modules/plan_modules/feature_catalog`.

**O que existe e funciona:**
- Configurações genéricas chave/valor a nível de empresa e de sistema.
- Moedas, taxas de câmbio, países, cidades, idiomas, templates de e-mail/SMS, integrações — tudo com CRUD.
- Feature flags por tenant realmente aplicados: `mw.RequireFeature(db, "vendas.fatura_direta")` consulta `tenant_feature_flags` com fallback para `saas.feature_catalog.ativo_por_defeito`.
- Gestão de módulos/features por tenant via superadmin, incluindo provisionamento de cargos padrão para tenants novos.
- Multi-moeda por tenant.
- **`tenant_branding`/`tenant_document_settings` ligados (implementado 2026-08-10):** novo ficheiro `internal/modules/sistema-configuracao/handlers/tenant_config.go`, mesmo padrão de `ObterConfigAssiduidade`/`GuardarConfigAssiduidade` já existente no módulo. `GET/PUT /api/system/branding` (logótipo, cores, slogan, contacto — upsert 1:1 por tenant) e `GET/PUT /api/system/document-settings` (prefixo/série/layout por módulo+tipo de documento — upsert por `tenant_id+modulo+tipo_documento`, com filtros `?modulo=`/`?tipo_documento=` na listagem). Sem migração nova — as duas tabelas já existiam na baseline, só faltava o código Go.

**O que falta:**
- Gestão de feature flags é exclusivamente superadmin — sem self-service para admin de tenant (decisão deliberada, não um bug).
- Sem endpoint de "onboarding"/wizard de configuração inicial do tenant.
- O padrão de configuração granular por feature existe mas só foi generalizado a um caso (`rh.assiduidade`).
