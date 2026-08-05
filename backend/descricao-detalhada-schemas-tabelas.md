# Descrição Detalhada dos Schemas e Tabelas - nexora_erp


## Schema: `assinatura_digital`
**Domínio:** assinatura digital de documentos (documentos, signatários, convites, versões assinadas, validações, webhooks)

### Tabelas

- **`assinatura_digital.convites`** — convites enviados para assinatura
- **`assinatura_digital.documentos`** — documentos a serem assinados digitalmente
- **`assinatura_digital.logs`** — logs de atividades
- **`assinatura_digital.signatarios`** — signatários dos documentos
- **`assinatura_digital.validacoes`** — validações de assinaturas digitais
- **`assinatura_digital.versoes_assinadas`** — versões finais assinadas dos documentos
- **`assinatura_digital.webhook_events`** — eventos recebidos por webhook de providers de assinatura

## Schema: `assinaturas`
**Domínio:** planos e subscrições SaaS dos tenants

### Tabelas

- **`assinaturas.subscription_invoices`** — faturas emitidas pelas subscrições
- **`assinaturas.subscription_plans`** — planos de subscrição disponíveis
- **`assinaturas.subscription_usage`** — consumo de recursos das subscrições
- **`assinaturas.subscriptions`** — subscrições ativas de cada tenant

## Schema: `auditoria`
**Domínio:** registo de eventos e logs de auditoria (operacional e legal/compliance)

### Tabelas

- **`auditoria.audit_events`** — eventos de auditoria com valor legal/compliance (imutáveis, com hash)
- **`auditoria.audit_logs`** — logs operacionais de auditoria

## Schema: `auth`
**Domínio:** autenticação, autorização, sessões, utilizadores, OAuth e permissões

### Tabelas

- **`auth.audit_logs`** — logs operacionais de auditoria
- **`auth.cargos`** — cargos/funções organizacionais
- **`auth.email_verifications`** — tokens/códigos de verificação de email
- **`auth.login_history`** — histórico de tentativas de autenticação
- **`auth.memberships`** — ligações entre utilizadores e tenants (acesso multi-empresa)
- **`auth.oauth_access_token_revocations`** — registo de revogação de tokens OAuth2
- **`auth.oauth_authorization_codes`** — códigos de autorização OAuth2
- **`auth.oauth_clients`** — aplicações cliente registadas no OAuth2
- **`auth.oauth_refresh_tokens`** — tokens de refresh OAuth2
- **`auth.password_resets`** — tokens/códigos de recuperação de password
- **`auth.permissoes_cargo`** — permissões associadas a cada cargo
- **`auth.permissoes_diretas`** — permissões atribuídas diretamente a utilizadores
- **`auth.permissoes_tipo`** — tipos/categorias de permissões disponíveis
- **`auth.schema_migrations`** — controlo de versões/migrações da base de dados
- **`auth.sessions`** — sessões de autenticação ativas
- **`auth.superadmin_ip_allowlist`** — lista de IPs autorizados para acesso de superadmin
- **`auth.superadmin_security_settings`** — configurações de segurança globais do superadmin
- **`auth.user_auth_codes`** — códigos/tokens de autenticação secundária (2FA/MFA/TOTP)
- **`auth.users`** — utilizadores registados no sistema

## Schema: `autorizacao`
**Domínio:** modelo de roles e permissões (RBAC) alternativo

### Tabelas

- **`autorizacao.permissions`** — permissões de acesso a funcionalidades
- **`autorizacao.role_permissions`** — permissões de perfil/papel
- **`autorizacao.roles`** — perfis/papéis de acesso
- **`autorizacao.user_roles`** — de utilizador: perfis/papéis de acesso

## Schema: `centros_custo`
**Domínio:** centros de custo, orçamentos e alocações de custos

### Tabelas

- **`centros_custo.cost_center_allocations`** — alocações de custos a centros de custo
- **`centros_custo.cost_center_budgets`** — orçamentos por centro de custo
- **`centros_custo.cost_centers`** — centros de custo

## Schema: `clientes`
**Domínio:** gestão de clientes, endereços, contactos, saldos e histórico

### Tabelas

- **`clientes.customer_addresses`** — endereços dos clientes
- **`clientes.customer_balances`** — saldos contabilísticos dos clientes
- **`clientes.customer_contacts`** — contactos dos clientes
- **`clientes.customer_credit_limits`** — limites de crédito dos clientes
- **`clientes.customer_discounts`** — descontos configurados para clientes
- **`clientes.customer_documents`** — documentos anexados aos clientes
- **`clientes.customer_groups`** — grupos/categorias de clientes
- **`clientes.customer_history`** — histórico de interações com clientes
- **`clientes.customer_notes`** — notas/observações sobre clientes
- **`clientes.customer_payments`** — pagamentos recebidos de clientes
- **`clientes.customer_tag_links`** — associação cliente ↔ tag
- **`clientes.customer_tags`** — tags/etiquetas de clientes
- **`clientes.customers`** — clientes

## Schema: `compras`
**Domínio:** ciclo de compras: fornecedores, requisições, ordens, receções, faturas e pagamentos

### Tabelas

- **`compras.goods_receipt_items`** — linhas das receções de mercadoria
- **`compras.goods_receipts`** — receções de mercadoria
- **`compras.purchase_invoice_items`** — linhas das faturas de compra
- **`compras.purchase_invoices`** — faturas de compra recebidas
- **`compras.purchase_order_items`** — linhas de ordens de compra
- **`compras.purchase_orders`** — ordens de compra a fornecedores
- **`compras.purchase_payment_items`** — linhas de pagamentos a fornecedores
- **`compras.purchase_payments`** — pagamentos efetuados a fornecedores
- **`compras.purchase_request_items`** — linhas de requisições de compra
- **`compras.purchase_requests`** — requisições internas de compra
- **`compras.purchase_return_items`** — linhas das devoluções a fornecedores
- **`compras.purchase_returns`** — devoluções a fornecedores
- **`compras.supplier_addresses`** — endereços dos fornecedores
- **`compras.supplier_contacts`** — contactos dos fornecedores
- **`compras.supplier_groups`** — grupos de fornecedores
- **`compras.suppliers`** — fornecedores

## Schema: `contabilidade`
**Domínio:** plano de contas, lançamentos, diários, períodos fiscais, ativos fixos e depreciações

### Tabelas

- **`contabilidade.account_types`** — tipos de contas contabilísticas
- **`contabilidade.accounting_budgets`** — orçamentos contabilísticos
- **`contabilidade.accounting_journals`** — diários contabilísticos
- **`contabilidade.accounting_reports`** — relatórios contabilísticos gerados
- **`contabilidade.chart_of_accounts`** — plano de contas contabilístico
- **`contabilidade.depreciation_entries`** — lançamentos de depreciação
- **`contabilidade.fiscal_periods`** — períodos fiscais/mensais
- **`contabilidade.fiscal_years`** — anos fiscais
- **`contabilidade.fixed_assets`** — ativos fixos/imobilizado
- **`contabilidade.journal_entries`** — lançamentos contabilísticos
- **`contabilidade.journal_entry_lines`** — linhas analíticas dos lançamentos contabilísticos
- **`contabilidade.journal_entry_sequences`** — numeração/sequências de lançamentos
- **`contabilidade.period_closing_checks`** — validações de fecho de período
- **`contabilidade.period_closings`** — fechos de período contabilístico

## Schema: `crm`
**Domínio:** gestão de relacionamento com clientes: leads, oportunidades e atividades

### Tabelas

- **`crm.atividades`** — atividades/interações comerciais
- **`crm.leads`** — leads
- **`crm.oportunidades`** — oportunidades de negócio

## Schema: `empresas`
**Domínio:** dados das empresas/tenants, filiais, configurações, licenças e contactos

### Tabelas

- **`empresas.companies`** — empresas/tenants registados
- **`empresas.company_addresses`** — endereços das empresas
- **`empresas.company_banks`** — contas bancárias das empresas
- **`empresas.company_branches`** — filiais/sucursais das empresas
- **`empresas.company_contacts`** — contactos das empresas
- **`empresas.company_documents`** — documentos associados às empresas
- **`empresas.company_licenses`** — licenças ativas das empresas
- **`empresas.company_settings`** — configurações específicas de cada empresa
- **`empresas.company_tax_info`** — informação fiscal das empresas
- **`empresas.company_users`** — associação empresa ↔ utilizador

## Schema: `faturacao`
**Domínio:** faturação e documentos de venda: faturas, notas de crédito, recibos, encomendas e guias

### Tabelas

- **`faturacao.credit_note_items`** — linhas das notas de crédito
- **`faturacao.credit_notes`** — notas de crédito emitidas
- **`faturacao.invoice_discounts`** — descontos aplicados nas faturas
- **`faturacao.invoice_items`** — linhas de artigos/serviços das faturas
- **`faturacao.invoice_receipts`** — associação entre faturas e recibos de pagamento
- **`faturacao.invoice_series`** — séries de numeração de faturas
- **`faturacao.invoice_taxes`** — impostos aplicados nas faturas
- **`faturacao.invoices`** — faturas de venda emitidas
- **`faturacao.sales_deliveries`** — guias de remessa/entregas de venda
- **`faturacao.sales_delivery_items`** — linhas das guias de remessa
- **`faturacao.sales_order_items`** — linhas de encomendas de venda
- **`faturacao.sales_orders`** — encomendas de venda
- **`faturacao.sales_quote_items`** — linhas de cotações/orçamentos
- **`faturacao.sales_quotes`** — cotações/orçamentos de venda
- **`faturacao.sales_return_items`** — linhas das devoluções de venda
- **`faturacao.sales_returns`** — devoluções de venda

## Schema: `financeiro`
**Domínio:** contas a pagar/receber, pagamentos, fluxo de caixa e orçamentos financeiros

### Tabelas

- **`financeiro.accounts_payable`** — contas a pagar (dívidas a fornecedores)
- **`financeiro.accounts_payable_payments`** — pagamentos de contas a pagar (dívidas a fornecedores)
- **`financeiro.accounts_receivable`** — contas a receber (créditos de clientes)
- **`financeiro.accounts_receivable_payments`** — pagamentos de contas a receber (créditos de clientes)
- **`financeiro.cash_flow_entries`** — movimentos de fluxo de caixa
- **`financeiro.financial_budgets`** — orçamentos financeiros
- **`financeiro.financial_categories`** — categorias financeiras
- **`financeiro.payment_methods`** — meios/formas de pagamento
- **`financeiro.payments`** — pagamentos registados no sistema

## Schema: `gestao_escolar`
**Domínio:** gestão escolar completa: alunos, professores, turmas, notas, propinas, horários

### Tabelas

- **`gestao_escolar.guardian_portal_sessions`** — sessões do portal dos encarregados
- **`gestao_escolar.portal_sessions`** — sessões do portal escolar
- **`gestao_escolar.school_academic_config`** — configuração académica
- **`gestao_escolar.school_academic_transcripts`** — históricos académicos
- **`gestao_escolar.school_attendance`** — presenças/faltas dos alunos
- **`gestao_escolar.school_books`** — livros escolares/biblioteca
- **`gestao_escolar.school_calendar_event_types`** — tipos de eventos do calendário
- **`gestao_escolar.school_calendar_events`** — eventos do calendário escolar
- **`gestao_escolar.school_cargo_permissoes`** — Registo/gestão de cargo/função.
- **`gestao_escolar.school_classes`** — turmas
- **`gestao_escolar.school_course_subject_terms`** — períodos/trimestres de disciplinas associadas a cursos
- **`gestao_escolar.school_course_subjects`** — disciplinas associadas a cursos
- **`gestao_escolar.school_courses`** — cursos
- **`gestao_escolar.school_cycles`** — ciclos de ensino
- **`gestao_escolar.school_enrollments`** — matrículas de alunos
- **`gestao_escolar.school_evaluation_types`** — Tabela auxiliar relacionada com school/evaluation/types.
- **`gestao_escolar.school_fee_generations`** — gerações de propinas
- **`gestao_escolar.school_fee_plans`** — planos de pagamento de propinas
- **`gestao_escolar.school_fees`** — propinas/taxas escolares
- **`gestao_escolar.school_financial_config`** — configuração financeira escolar
- **`gestao_escolar.school_grade_formulas`** — fórmulas de cálculo de notas
- **`gestao_escolar.school_grade_items`** — itens/componentes de avaliação
- **`gestao_escolar.school_grades`** — notas/avaliações
- **`gestao_escolar.school_guardians`** — encarregados/guardiões
- **`gestao_escolar.school_incident_types`** — tipos de incidentes disciplinares
- **`gestao_escolar.school_levels`** — níveis de ensino
- **`gestao_escolar.school_library_loans`** — empréstimos da biblioteca
- **`gestao_escolar.school_messages`** — mensagens internas do portal escolar
- **`gestao_escolar.school_payments`** — pagamentos escolares
- **`gestao_escolar.school_sanction_types`** — tipos de sanções
- **`gestao_escolar.school_series`** — séries/turmas agrupadas
- **`gestao_escolar.school_student_fee_discounts`** — Tabela auxiliar relacionada com school/student/fee.
- **`gestao_escolar.school_student_incidents`** — incidentes dos alunos
- **`gestao_escolar.school_student_merits`** — méritos/reconhecimentos dos alunos
- **`gestao_escolar.school_student_roles`** — papéis/perfil dos alunos
- **`gestao_escolar.school_student_sanctions`** — sanções aplicadas aos alunos
- **`gestao_escolar.school_students`** — alunos matriculados
- **`gestao_escolar.school_subjects`** — disciplinas
- **`gestao_escolar.school_tasks`** — escolar: tarefas
- **`gestao_escolar.school_teacher_assignments`** — atribuições de professores a turmas/disciplinas
- **`gestao_escolar.school_teacher_roles`** — papéis dos professores
- **`gestao_escolar.school_teachers`** — professores/docentes
- **`gestao_escolar.school_terms`** — trimestres/períodos letivos
- **`gestao_escolar.school_time_slots`** — slots/periodos de horário
- **`gestao_escolar.school_timetable_entries`** — entradas de horário
- **`gestao_escolar.school_transcript_subjects`** — Tabela auxiliar relacionada com school/transcript/subjects.
- **`gestao_escolar.school_years`** — Tabela auxiliar relacionada com school/years.

## Schema: `hardware`
**Domínio:** equipamentos, dispositivos e terminais físicos

### Tabelas

- **`hardware.device_configs`** — Tabela auxiliar relacionada com device/configs.
- **`hardware.device_events`** — eventos de dispositivos
- **`hardware.device_users`** — utilizadores de dispositivos
- **`hardware.devices`** — dispositivos
- **`hardware.drivers`** — Tabela auxiliar relacionada com drivers.

## Schema: `impostos`
**Domínio:** configuração de impostos, taxas e retenções fiscais

### Tabelas

- **`impostos.tax_certificates`** — Tabela auxiliar relacionada com tax/certificates.
- **`impostos.tax_exemptions`** — Tabela auxiliar relacionada com tax/exemptions.
- **`impostos.tax_groups`** — Tabela auxiliar relacionada com tax/groups.
- **`impostos.tax_regimes`** — Tabela auxiliar relacionada com tax/regimes.
- **`impostos.tax_return_lines`** — Tabela auxiliar relacionada com tax/return/lines.
- **`impostos.tax_returns`** — Tabela auxiliar relacionada com tax/returns.
- **`impostos.tax_rules`** — Tabela auxiliar relacionada com tax/rules.
- **`impostos.tax_transactions`** — Tabela auxiliar relacionada com tax/transactions.
- **`impostos.taxes`** — impostos
- **`impostos.withholding_tax_transactions`** — Tabela auxiliar relacionada com withholding/tax/transactions.
- **`impostos.withholding_taxes`** — Registo/gestão de impostos.

## Schema: `lgpd`
**Domínio:** dados de privacidade e consentimentos (LGPD)

### Tabelas

- **`lgpd.consentimentos`** — consentimentos

## Schema: `logistica`
**Domínio:** operações logísticas, transportes e entregas

### Tabelas

- **`logistica.logistics_drivers`** — Tabela auxiliar relacionada com logistics/drivers.
- **`logistica.logistics_routes`** — Tabela auxiliar relacionada com logistics/routes.
- **`logistica.logistics_shipments`** — Tabela auxiliar relacionada com logistics/shipments.
- **`logistica.logistics_tracking_events`** — Tabela auxiliar relacionada com logistics/tracking/events.
- **`logistica.logistics_vehicles`** — Tabela auxiliar relacionada com logistics/vehicles.

## Schema: `multi_moeda`
**Domínio:** moedas, taxas de câmbio e conversões

### Tabelas

- **`multi_moeda.currencies`** — moedas
- **`multi_moeda.exchange_rates`** — taxas de câmbio
- **`multi_moeda.tenant_currencies`** — Registo/gestão de moedas e tenant.

## Schema: `notifications`
**Domínio:** notificações do sistema e preferências

### Tabelas

- **`notifications.notification_channels`** — Tabela auxiliar relacionada com notification/channels.
- **`notifications.notification_messages`** — Tabela auxiliar relacionada com notification/messages.
- **`notifications.notification_templates`** — Tabela auxiliar relacionada com notification/templates.
- **`notifications.push_tokens`** — Tabela auxiliar relacionada com push/tokens.

## Schema: `pessoas`
**Domínio:** entidade master de pessoas (funcionários, clientes, fornecedores)

### Tabelas

- **`pessoas.pessoa_contatos`** — Registo/gestão de pessoa.
- **`pessoas.pessoa_enderecos`** — Registo/gestão de pessoa.
- **`pessoas.pessoa_relacoes`** — Registo/gestão de pessoa.
- **`pessoas.pessoas`** — registo master de pessoas (funcionários, clientes, fornecedores)

## Schema: `pos`
**Domínio:** ponto de venda: vendas, terminais, sessões de caixa e pagamentos

### Tabelas

- **`pos.pos_catalog_items`** — Tabela auxiliar relacionada com pos/catalog/items.
- **`pos.pos_sale_items`** — Tabela auxiliar relacionada com pos/sale/items.
- **`pos.pos_sale_payments`** — Registo/gestão de pagamentos registados no sistema.
- **`pos.pos_sales`** — Tabela auxiliar relacionada com pos/sales.
- **`pos.pos_sessions`** — Registo/gestão de sessões de autenticação ativas e sessão de autenticação.
- **`pos.pos_terminals`** — Tabela auxiliar relacionada com pos/terminals.

## Schema: `produtos`
**Domínio:** catálogo de produtos/serviços, categorias, preços e unidades

### Tabelas

- **`produtos.product_attribute_values`** — Registo/gestão de produto/serviço.
- **`produtos.product_attributes`** — Registo/gestão de produto/serviço.
- **`produtos.product_barcodes`** — Registo/gestão de produto/serviço.
- **`produtos.product_brands`** — Registo/gestão de produto/serviço.
- **`produtos.product_categories`** — de produtos: categorias de produtos/serviços
- **`produtos.product_discounts`** — descontos de produto/serviço
- **`produtos.product_images`** — Registo/gestão de produto/serviço.
- **`produtos.product_kit_items`** — Registo/gestão de produto/serviço.
- **`produtos.product_kits`** — Registo/gestão de produto/serviço.
- **`produtos.product_prices`** — preços dos produtos ao longo do tempo
- **`produtos.product_subcategories`** — Registo/gestão de categorias de produtos/serviços e produto/serviço.
- **`produtos.product_tag_links`** — associações de tags com produto/serviço
- **`produtos.product_tags`** — tags/etiquetas de produto/serviço
- **`produtos.product_units`** — unidades de medida dos produtos
- **`produtos.product_variants`** — Registo/gestão de produto/serviço.
- **`produtos.products`** — produtos e serviços
- **`produtos.warehouses`** — armazéns/locais de armazenamento

## Schema: `public`
**Domínio:** tabelas públicas/compartilhadas do sistema

### Tabelas

- **`public.chat_conversas`** — Tabela auxiliar relacionada com chat/conversas.
- **`public.chat_mensagens`** — Tabela auxiliar relacionada com chat/mensagens.
- **`public.chat_participantes`** — Tabela auxiliar relacionada com chat/participantes.
- **`public.comunicados`** — Tabela auxiliar relacionada com comunicados.
- **`public.comunicados_lidos`** — Tabela auxiliar relacionada com comunicados/lidos.
- **`public.notif_colaborador`** — Tabela auxiliar relacionada com notif/colaborador.
- **`public.schema_migrations`** — controlo de versões/migrações da base de dados

## Schema: `recrutamento`
**Domínio:** processo de recrutamento: vagas, candidaturas, entrevistas e avaliações

### Tabelas

- **`recrutamento.candidato_experiencias`** — Tabela auxiliar relacionada com candidato/experiencias.
- **`recrutamento.candidato_formacoes`** — Tabela auxiliar relacionada com candidato/formacoes.
- **`recrutamento.candidato_notificacoes`** — Tabela auxiliar relacionada com candidato/notificacoes.
- **`recrutamento.candidato_sessions`** — Registo/gestão de sessões de autenticação ativas e sessão de autenticação.
- **`recrutamento.candidatos`** — candidatos a vagas de emprego
- **`recrutamento.candidatura_campos_custom`** — Tabela auxiliar relacionada com candidatura/campos/custom.
- **`recrutamento.candidatura_notas`** — Tabela auxiliar relacionada com candidatura/notas.
- **`recrutamento.candidatura_respostas_vaga`** — Tabela auxiliar relacionada com candidatura/respostas/vaga.
- **`recrutamento.candidatura_valores_custom`** — Tabela auxiliar relacionada com candidatura/valores/custom.
- **`recrutamento.candidaturas`** — Tabela auxiliar relacionada com candidaturas.
- **`recrutamento.config_notificacoes`** — Tabela auxiliar relacionada com config/notificacoes.
- **`recrutamento.contactos`** — Tabela auxiliar relacionada com contactos.
- **`recrutamento.vaga_campos`** — Tabela auxiliar relacionada com vaga/campos.
- **`recrutamento.vagas`** — Tabela auxiliar relacionada com vagas.

## Schema: `rh`
**Domínio:** recursos humanos: funcionários, contratos, salários, faltas, presenças e benefícios

### Tabelas

- **`rh.adiantamentos`** — Tabela auxiliar relacionada com adiantamentos.
- **`rh.auditoria_assiduidade`** — Tabela auxiliar relacionada com auditoria/assiduidade.
- **`rh.ausencias`** — Tabela auxiliar relacionada com ausencias.
- **`rh.avaliacao_criterios`** — Tabela auxiliar relacionada com avaliacao/criterios.
- **`rh.avaliacoes`** — Tabela auxiliar relacionada com avaliacoes.
- **`rh.beneficios`** — benefícios atribuídos aos funcionários
- **`rh.cargos`** — cargos/funções organizacionais
- **`rh.componentes_salariais`** — Tabela auxiliar relacionada com componentes/salariais.
- **`rh.config_contabilidade_folha`** — Tabela auxiliar relacionada com config/contabilidade/folha.
- **`rh.contactos_emergencia`** — Tabela auxiliar relacionada com contactos/emergencia.
- **`rh.contratos`** — contratos de trabalho
- **`rh.correcoes_evento`** — Tabela auxiliar relacionada com correcoes/evento.
- **`rh.criterios_avaliacao`** — Tabela auxiliar relacionada com criterios/avaliacao.
- **`rh.documentos_funcionario`** — Registo/gestão de funcionário e documentos a serem assinados digitalmente.
- **`rh.emprestimos`** — Tabela auxiliar relacionada com emprestimos.
- **`rh.eventos_assiduidade`** — Tabela auxiliar relacionada com eventos/assiduidade.
- **`rh.folhas_pagamento`** — Tabela auxiliar relacionada com folhas/pagamento.
- **`rh.formacoes`** — Tabela auxiliar relacionada com formacoes.
- **`rh.funcionario_beneficios`** — benefícios por funcionário
- **`rh.funcionario_componentes_salariais`** — Registo/gestão de funcionário.
- **`rh.funcionario_formacoes`** — Registo/gestão de funcionário.
- **`rh.funcionario_horarios`** — Registo/gestão de funcionário.
- **`rh.funcionarios`** — funcionários/colaboradores
- **`rh.historico_salarial`** — Tabela auxiliar relacionada com historico/salarial.
- **`rh.horarios_dias`** — Tabela auxiliar relacionada com horarios/dias.
- **`rh.horarios_trabalho`** — Tabela auxiliar relacionada com horarios/trabalho.
- **`rh.irps_escaloes`** — Tabela auxiliar relacionada com irps/escaloes.
- **`rh.justificacoes`** — Tabela auxiliar relacionada com justificacoes.
- **`rh.marcacoes_interpretadas`** — Tabela auxiliar relacionada com marcacoes/interpretadas.
- **`rh.metodos_marcacao`** — Tabela auxiliar relacionada com metodos/marcacao.
- **`rh.nfc_tags`** — Tabela auxiliar relacionada com nfc/tags.
- **`rh.periodos_avaliacao`** — Tabela auxiliar relacionada com periodos/avaliacao.
- **`rh.presencas`** — registo de presenças/ponto
- **`rh.processos_disciplinares`** — Tabela auxiliar relacionada com processos/disciplinares.
- **`rh.qr_tokens`** — Tabela auxiliar relacionada com qr/tokens.
- **`rh.recibo_vencimento_itens`** — Tabela auxiliar relacionada com recibo/vencimento/itens.
- **`rh.recibos_vencimento`** — recibos de vencimento
- **`rh.regras_assiduidade`** — Tabela auxiliar relacionada com regras/assiduidade.
- **`rh.resultados_diarios`** — Tabela auxiliar relacionada com resultados/diarios.
- **`rh.resultados_periodos`** — Tabela auxiliar relacionada com resultados/periodos.
- **`rh.saldos_ausencia`** — Tabela auxiliar relacionada com saldos/ausencia.
- **`rh.tipos_ausencia`** — Tabela auxiliar relacionada com tipos/ausencia.
- **`rh.tipos_evento`** — Tabela auxiliar relacionada com tipos/evento.
- **`rh.tipos_regra`** — Tabela auxiliar relacionada com tipos/regra.
- **`rh.unidades_organizacionais`** — Tabela auxiliar relacionada com unidades/organizacionais.

## Schema: `saas`
**Domínio:** dados da plataforma SaaS: tenants, quotas, módulos e faturamento

### Tabelas

- **`saas.approval_decisions`** — Tabela auxiliar relacionada com approval/decisions.
- **`saas.approval_flows`** — Tabela auxiliar relacionada com approval/flows.
- **`saas.approval_requests`** — Tabela auxiliar relacionada com approval/requests.
- **`saas.feature_catalog`** — Tabela auxiliar relacionada com feature/catalog.
- **`saas.global_settings`** — Registo/gestão de configurações.
- **`saas.module_catalog`** — Tabela auxiliar relacionada com module/catalog.
- **`saas.module_dependencies`** — Tabela auxiliar relacionada com module/dependencies.
- **`saas.plan_modules`** — Registo/gestão de módulos do sistema.
- **`saas.plans`** — Tabela auxiliar relacionada com plans.
- **`saas.tenant_dominios`** — Registo/gestão de tenant.
- **`saas.tenant_modules`** — Registo/gestão de módulos do sistema e tenant.
- **`saas.tenant_subscriptions`** — Registo/gestão de subscrições ativas de cada tenant e tenant.
- **`saas.tenants`** — tenants/clientes do SaaS

## Schema: `seguranca`
**Domínio:** segurança: allowlists, políticas e logs de segurança

### Tabelas

- **`seguranca.security_ip_allowlist`** — Tabela auxiliar relacionada com security/ip/allowlist.
- **`seguranca.security_mfa_enrollments`** — Tabela auxiliar relacionada com security/mfa/enrollments.
- **`seguranca.security_policies`** — Tabela auxiliar relacionada com security/policies.

## Schema: `sistema_configuracao`
**Domínio:** configurações globais e parâmetros do sistema

### Tabelas

- **`sistema_configuracao.api_logs`** — Registo/gestão de logs de atividades.
- **`sistema_configuracao.cities`** — Tabela auxiliar relacionada com cities.
- **`sistema_configuracao.countries`** — Tabela auxiliar relacionada com countries.
- **`sistema_configuracao.currencies`** — moedas
- **`sistema_configuracao.email_templates`** — Tabela auxiliar relacionada com email/templates.
- **`sistema_configuracao.exchange_rates`** — taxas de câmbio
- **`sistema_configuracao.integrations`** — Tabela auxiliar relacionada com integrations.
- **`sistema_configuracao.languages`** — Tabela auxiliar relacionada com languages.
- **`sistema_configuracao.settings`** — configurações
- **`sistema_configuracao.sms_templates`** — Tabela auxiliar relacionada com sms/templates.
- **`sistema_configuracao.system_logs`** — Registo/gestão de logs de atividades.
- **`sistema_configuracao.tenant_branding`** — Registo/gestão de tenant.
- **`sistema_configuracao.tenant_defaults`** — Registo/gestão de tenant.
- **`sistema_configuracao.tenant_document_settings`** — Registo/gestão de configurações e tenant.
- **`sistema_configuracao.tenant_feature_flags`** — Registo/gestão de tenant.
- **`sistema_configuracao.tenant_integrations`** — Registo/gestão de tenant.

## Schema: `stock`
**Domínio:** inventário, armazéns, movimentos de stock e contagens

### Tabelas

- **`stock.stock_adjustments`** — Tabela auxiliar relacionada com stock/adjustments.
- **`stock.stock_alerts`** — Tabela auxiliar relacionada com stock/alerts.
- **`stock.stock_batches`** — Tabela auxiliar relacionada com stock/batches.
- **`stock.stock_count_items`** — Tabela auxiliar relacionada com stock/count/items.
- **`stock.stock_counts`** — Tabela auxiliar relacionada com stock/counts.
- **`stock.stock_items`** — Tabela auxiliar relacionada com stock/items.
- **`stock.stock_logs`** — Registo/gestão de logs de atividades.
- **`stock.stock_movements`** — Tabela auxiliar relacionada com stock/movements.
- **`stock.stock_reservations`** — Tabela auxiliar relacionada com stock/reservations.
- **`stock.stock_serial_numbers`** — Tabela auxiliar relacionada com stock/serial/numbers.
- **`stock.stock_transfer_items`** — Tabela auxiliar relacionada com stock/transfer/items.
- **`stock.stock_transfers`** — Tabela auxiliar relacionada com stock/transfers.
- **`stock.warehouse_locations`** — Tabela auxiliar relacionada com warehouse/locations.

## Schema: `tarefas`
**Domínio:** gestão de tarefas e atribuições

### Tabelas

- **`tarefas.cartoes`** — Tabela auxiliar relacionada com cartoes.
- **`tarefas.listas`** — Tabela auxiliar relacionada com listas.
- **`tarefas.quadros`** — Tabela auxiliar relacionada com quadros.

## Schema: `tesouraria`
**Domínio:** caixa/tesouraria: contas e movimentos de caixa

### Tabelas

- **`tesouraria.bank_accounts`** — contas bancárias
- **`tesouraria.cash_registers`** — Tabela auxiliar relacionada com cash/registers.
- **`tesouraria.movements`** — Tabela auxiliar relacionada com movements.
- **`tesouraria.reconciliations`** — Tabela auxiliar relacionada com reconciliations.

## Schema: `utilizadores`
**Domínio:** perfil e dados de utilizadores do ERP

### Tabelas

- **`utilizadores.profiles`** — Tabela auxiliar relacionada com profiles.
- **`utilizadores.user_activity`** — Registo/gestão de utilizador.
- **`utilizadores.user_avatar`** — Registo/gestão de utilizador.
- **`utilizadores.user_devices`** — de utilizador: dispositivos
- **`utilizadores.user_notifications`** — de utilizador: notificações enviadas aos utilizadores
- **`utilizadores.user_preferences`** — Registo/gestão de utilizador.
- **`utilizadores.user_security_logs`** — Registo/gestão de utilizador e logs de atividades.
- **`utilizadores.user_settings`** — de utilizador: configurações
- **`utilizadores.user_tokens`** — tokens de utilizador