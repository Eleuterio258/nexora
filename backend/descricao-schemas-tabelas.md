# Descrição dos Schemas e Tabelas - nexora_erp


## Schema: `assinatura_digital`

**Função:** Registo/gestão de assinatura, digital.


### Tabelas

- **`assinatura_digital.convites`** — Registo/gestão de convites para assinatura.
- **`assinatura_digital.documentos`** — Registo/gestão de documentos.
- **`assinatura_digital.logs`** — Registo/gestão de logs.
- **`assinatura_digital.signatarios`** — Registo/gestão de signatários.
- **`assinatura_digital.validacoes`** — Registo/gestão de validações de assinaturas.
- **`assinatura_digital.versoes_assinadas`** — Registo/gestão de versões assinadas dos documentos.
- **`assinatura_digital.webhook_events`** — Registo/gestão de eventos recebidos por webhook.

## Schema: `assinaturas`

**Função:** Registo/gestão de assinaturas.


### Tabelas

- **`assinaturas.subscription_invoices`** — Registo/gestão de faturas, fatura, faturas de subscrição.
- **`assinaturas.subscription_plans`** — Registo/gestão de planos de subscrição, planos.
- **`assinaturas.subscription_usage`** — Registo/gestão de consumo/uso de subscrição.
- **`assinaturas.subscriptions`** — Registo/gestão de subscrições.

## Schema: `auditoria`

**Função:** Registo/gestão de auditoria.


### Tabelas

- **`auditoria.audit_events`** — Registo/gestão de eventos de auditoria com valor legal.
- **`auditoria.audit_logs`** — Registo/gestão de logs de auditoria operacional.

## Schema: `auth`

**Função:** Registo/gestão de auth.


### Tabelas

- **`auth.audit_logs`** — Registo/gestão de logs de auditoria operacional.
- **`auth.cargos`** — Registo/gestão de cargos/funções organizacionais.
- **`auth.email_verifications`** — Registo/gestão de verificações de email.
- **`auth.login_history`** — Registo/gestão de histórico de tentativas de login.
- **`auth.memberships`** — Registo/gestão de ligações utilizador-tenant (memberships).
- **`auth.oauth_access_token_revocations`** — Registo/gestão de revogações de tokens de acesso.
- **`auth.oauth_authorization_codes`** — Registo/gestão de códigos de autorização OAuth.
- **`auth.oauth_clients`** — Registo/gestão de clientes OAuth.
- **`auth.oauth_refresh_tokens`** — Registo/gestão de tokens de refresh OAuth.
- **`auth.password_resets`** — Registo/gestão de recuperações de password.
- **`auth.permissoes_cargo`** — Registo/gestão de permissões.
- **`auth.permissoes_diretas`** — Registo/gestão de permissões.
- **`auth.permissoes_tipo`** — Registo/gestão de permissões.
- **`auth.schema_migrations`** — Registo/gestão de controlo de migrações da base de dados.
- **`auth.sessions`** — Registo/gestão de sessões de login ativas, sessão.
- **`auth.superadmin_ip_allowlist`** — Registo/gestão de lista de IPs permitidos para superadmin.
- **`auth.superadmin_security_settings`** — Registo/gestão de configurações/parametrizações, configurações de segurança do superadmin.
- **`auth.user_auth_codes`** — Registo/gestão de utilizador, códigos/tokens de autenticação de utilizador.
- **`auth.users`** — Registo/gestão de utilizadores do sistema, utilizador.

## Schema: `autorizacao`

**Função:** Registo/gestão de autorizacao.


### Tabelas

- **`autorizacao.permissions`** — Registo/gestão de permissões de acesso.
- **`autorizacao.role_permissions`** — Registo/gestão de permissões de acesso, associação entre roles e permissões.
- **`autorizacao.roles`** — Registo/gestão de perfis/papéis de utilizador.
- **`autorizacao.user_roles`** — Registo/gestão de utilizador, perfis/papéis de utilizador, associação entre utilizadores e roles.

## Schema: `centros_custo`

**Função:** Registo/gestão de centros de custo.


### Tabelas

- **`centros_custo.cost_center_allocations`** — Registo/gestão de cost, center, allocations.
- **`centros_custo.cost_center_budgets`** — Registo/gestão de cost, center, budgets.
- **`centros_custo.cost_centers`** — Registo/gestão de centros de custo.

## Schema: `clientes`

**Função:** Registo/gestão de clientes.


### Tabelas

- **`clientes.customer_addresses`** — Registo/gestão de cliente, endereços de clientes.
- **`clientes.customer_balances`** — Registo/gestão de cliente, saldos de clientes.
- **`clientes.customer_contacts`** — Registo/gestão de cliente, contactos de clientes.
- **`clientes.customer_credit_limits`** — Registo/gestão de cliente, limites de crédito de clientes.
- **`clientes.customer_discounts`** — Registo/gestão de cliente, descontos de clientes.
- **`clientes.customer_documents`** — Registo/gestão de cliente, documentos de clientes.
- **`clientes.customer_groups`** — Registo/gestão de cliente, grupos de clientes.
- **`clientes.customer_history`** — Registo/gestão de cliente.
- **`clientes.customer_notes`** — Registo/gestão de cliente.
- **`clientes.customer_payments`** — Registo/gestão de cliente, pagamentos.
- **`clientes.customer_tag_links`** — Registo/gestão de cliente.
- **`clientes.customer_tags`** — Registo/gestão de cliente.
- **`clientes.customers`** — Registo/gestão de clientes, cliente.

## Schema: `compras`

**Função:** Registo/gestão de compras.


### Tabelas

- **`compras.goods_receipt_items`** — Registo/gestão de goods, receipt, items.
- **`compras.goods_receipts`** — Registo/gestão de recibos.
- **`compras.purchase_invoice_items`** — Registo/gestão de fatura.
- **`compras.purchase_invoices`** — Registo/gestão de faturas, fatura.
- **`compras.purchase_order_items`** — Registo/gestão de purchase, order, items.
- **`compras.purchase_orders`** — Registo/gestão de ordens de compra.
- **`compras.purchase_payment_items`** — Registo/gestão de purchase, payment, items.
- **`compras.purchase_payments`** — Registo/gestão de pagamentos.
- **`compras.purchase_request_items`** — Registo/gestão de purchase, request, items.
- **`compras.purchase_requests`** — Registo/gestão de purchase, requests.
- **`compras.purchase_return_items`** — Registo/gestão de purchase, return, items.
- **`compras.purchase_returns`** — Registo/gestão de purchase, returns.
- **`compras.supplier_addresses`** — Registo/gestão de supplier, addresses.
- **`compras.supplier_contacts`** — Registo/gestão de supplier, contacts.
- **`compras.supplier_groups`** — Registo/gestão de supplier, groups.
- **`compras.suppliers`** — Registo/gestão de fornecedores.

## Schema: `contabilidade`

**Função:** Registo/gestão de contabilidade.


### Tabelas

- **`contabilidade.account_types`** — Registo/gestão de account, types.
- **`contabilidade.accounting_budgets`** — Registo/gestão de accounting, budgets.
- **`contabilidade.accounting_journals`** — Registo/gestão de accounting, journals.
- **`contabilidade.accounting_reports`** — Registo/gestão de accounting, reports.
- **`contabilidade.chart_of_accounts`** — Registo/gestão de plano de contas.
- **`contabilidade.depreciation_entries`** — Registo/gestão de depreciation, entries.
- **`contabilidade.fiscal_periods`** — Registo/gestão de fiscal, periods.
- **`contabilidade.fiscal_years`** — Registo/gestão de fiscal, years.
- **`contabilidade.fixed_assets`** — Registo/gestão de fixed, assets.
- **`contabilidade.journal_entries`** — Registo/gestão de journal, entries.
- **`contabilidade.journal_entry_lines`** — Registo/gestão de journal, entry, lines.
- **`contabilidade.journal_entry_sequences`** — Registo/gestão de journal, entry, sequences.
- **`contabilidade.period_closing_checks`** — Registo/gestão de period, closing, checks.
- **`contabilidade.period_closings`** — Registo/gestão de period, closings.

## Schema: `crm`

**Função:** Registo/gestão de CRM (leads/oportunidades).


### Tabelas

- **`crm.atividades`** — Registo/gestão de atividades.
- **`crm.leads`** — Registo/gestão de leads.
- **`crm.oportunidades`** — Registo/gestão de oportunidades.

## Schema: `empresas`

**Função:** Registo/gestão de empresas/tenants, empresa.


### Tabelas

- **`empresas.companies`** — Registo/gestão de empresas.
- **`empresas.company_addresses`** — Registo/gestão de empresa.
- **`empresas.company_banks`** — Registo/gestão de empresa.
- **`empresas.company_branches`** — Registo/gestão de empresa.
- **`empresas.company_contacts`** — Registo/gestão de empresa.
- **`empresas.company_documents`** — Registo/gestão de empresa.
- **`empresas.company_licenses`** — Registo/gestão de empresa.
- **`empresas.company_settings`** — Registo/gestão de configurações/parametrizações, empresa.
- **`empresas.company_tax_info`** — Registo/gestão de empresa.
- **`empresas.company_users`** — Registo/gestão de utilizadores do sistema, utilizador, empresa.

## Schema: `faturacao`

**Função:** Registo/gestão de fatura.


### Tabelas

- **`faturacao.credit_note_items`** — Registo/gestão de credit, note, items.
- **`faturacao.credit_notes`** — Registo/gestão de notas de crédito.
- **`faturacao.invoice_discounts`** — Registo/gestão de fatura.
- **`faturacao.invoice_items`** — Registo/gestão de fatura.
- **`faturacao.invoice_receipts`** — Registo/gestão de fatura, recibos.
- **`faturacao.invoice_series`** — Registo/gestão de fatura, séries de documentação.
- **`faturacao.invoice_taxes`** — Registo/gestão de fatura, impostos.
- **`faturacao.invoices`** — Registo/gestão de faturas, fatura.
- **`faturacao.sales_deliveries`** — Registo/gestão de sales, deliveries.
- **`faturacao.sales_delivery_items`** — Registo/gestão de sales, delivery, items.
- **`faturacao.sales_order_items`** — Registo/gestão de sales, order, items.
- **`faturacao.sales_orders`** — Registo/gestão de sales, orders.
- **`faturacao.sales_quote_items`** — Registo/gestão de sales, quote, items.
- **`faturacao.sales_quotes`** — Registo/gestão de sales, quotes.
- **`faturacao.sales_return_items`** — Registo/gestão de sales, return, items.
- **`faturacao.sales_returns`** — Registo/gestão de sales, returns.

## Schema: `financeiro`

**Função:** Registo/gestão de financeiro.


### Tabelas

- **`financeiro.accounts_payable`** — Registo/gestão de accounts, payable.
- **`financeiro.accounts_payable_payments`** — Registo/gestão de pagamentos.
- **`financeiro.accounts_receivable`** — Registo/gestão de accounts, receivable.
- **`financeiro.accounts_receivable_payments`** — Registo/gestão de pagamentos.
- **`financeiro.cash_flow_entries`** — Registo/gestão de caixa/tesouraria.
- **`financeiro.financial_budgets`** — Registo/gestão de financial, budgets.
- **`financeiro.financial_categories`** — Registo/gestão de categorias.
- **`financeiro.payment_methods`** — Registo/gestão de payment, methods.
- **`financeiro.payments`** — Registo/gestão de pagamentos.

## Schema: `gestao_escolar`

**Função:** Registo/gestão de gestao, escolar.


### Tabelas

- **`gestao_escolar.guardian_portal_sessions`** — Registo/gestão de sessões de login ativas, sessão.
- **`gestao_escolar.portal_sessions`** — Registo/gestão de sessões de login ativas, sessão.
- **`gestao_escolar.school_academic_config`** — Registo/gestão de school, academic, config.
- **`gestao_escolar.school_academic_transcripts`** — Registo/gestão de school, academic, transcripts.
- **`gestao_escolar.school_attendance`** — Registo/gestão de school, attendance.
- **`gestao_escolar.school_books`** — Registo/gestão de school, books.
- **`gestao_escolar.school_calendar_event_types`** — Registo/gestão de school, calendar, event.
- **`gestao_escolar.school_calendar_events`** — Registo/gestão de school, calendar, events.
- **`gestao_escolar.school_cargo_permissoes`** — Registo/gestão de permissões.
- **`gestao_escolar.school_classes`** — Registo/gestão de school, classes.
- **`gestao_escolar.school_course_subject_terms`** — Registo/gestão de school, course, subject.
- **`gestao_escolar.school_course_subjects`** — Registo/gestão de school, course, subjects.
- **`gestao_escolar.school_courses`** — Registo/gestão de school, courses.
- **`gestao_escolar.school_cycles`** — Registo/gestão de school, cycles.
- **`gestao_escolar.school_enrollments`** — Registo/gestão de school, enrollments.
- **`gestao_escolar.school_evaluation_types`** — Registo/gestão de school, evaluation, types.
- **`gestao_escolar.school_fee_generations`** — Registo/gestão de school, fee, generations.
- **`gestao_escolar.school_fee_plans`** — Registo/gestão de planos.
- **`gestao_escolar.school_fees`** — Registo/gestão de school, fees.
- **`gestao_escolar.school_financial_config`** — Registo/gestão de school, financial, config.
- **`gestao_escolar.school_grade_formulas`** — Registo/gestão de school, grade, formulas.
- **`gestao_escolar.school_grade_items`** — Registo/gestão de school, grade, items.
- **`gestao_escolar.school_grades`** — Registo/gestão de school, grades.
- **`gestao_escolar.school_guardians`** — Registo/gestão de school, guardians.
- **`gestao_escolar.school_incident_types`** — Registo/gestão de school, incident, types.
- **`gestao_escolar.school_levels`** — Registo/gestão de school, levels.
- **`gestao_escolar.school_library_loans`** — Registo/gestão de school, library, loans.
- **`gestao_escolar.school_messages`** — Registo/gestão de school, messages.
- **`gestao_escolar.school_payments`** — Registo/gestão de pagamentos.
- **`gestao_escolar.school_sanction_types`** — Registo/gestão de school, sanction, types.
- **`gestao_escolar.school_series`** — Registo/gestão de séries de documentação.
- **`gestao_escolar.school_student_fee_discounts`** — Registo/gestão de school, student, fee.
- **`gestao_escolar.school_student_incidents`** — Registo/gestão de school, student, incidents.
- **`gestao_escolar.school_student_merits`** — Registo/gestão de school, student, merits.
- **`gestao_escolar.school_student_roles`** — Registo/gestão de perfis/papéis de utilizador.
- **`gestao_escolar.school_student_sanctions`** — Registo/gestão de school, student, sanctions.
- **`gestao_escolar.school_students`** — Registo/gestão de school, students.
- **`gestao_escolar.school_subjects`** — Registo/gestão de school, subjects.
- **`gestao_escolar.school_tasks`** — Registo/gestão de tarefas.
- **`gestao_escolar.school_teacher_assignments`** — Registo/gestão de school, teacher, assignments.
- **`gestao_escolar.school_teacher_roles`** — Registo/gestão de perfis/papéis de utilizador.
- **`gestao_escolar.school_teachers`** — Registo/gestão de school, teachers.
- **`gestao_escolar.school_terms`** — Registo/gestão de school, terms.
- **`gestao_escolar.school_time_slots`** — Registo/gestão de school, time, slots.
- **`gestao_escolar.school_timetable_entries`** — Registo/gestão de school, timetable, entries.
- **`gestao_escolar.school_transcript_subjects`** — Registo/gestão de school, transcript, subjects.
- **`gestao_escolar.school_years`** — Registo/gestão de school, years.

## Schema: `hardware`

**Função:** Registo/gestão de equipamentos/hardware.


### Tabelas

- **`hardware.device_configs`** — Registo/gestão de device, configs.
- **`hardware.device_events`** — Registo/gestão de device, events.
- **`hardware.device_users`** — Registo/gestão de utilizadores do sistema, utilizador.
- **`hardware.devices`** — Registo/gestão de dispositivos.
- **`hardware.drivers`** — Registo/gestão de drivers.

## Schema: `impostos`

**Função:** Registo/gestão de impostos/taxas.


### Tabelas

- **`impostos.tax_certificates`** — Registo/gestão de tax, certificates.
- **`impostos.tax_exemptions`** — Registo/gestão de tax, exemptions.
- **`impostos.tax_groups`** — Registo/gestão de tax, groups.
- **`impostos.tax_regimes`** — Registo/gestão de tax, regimes.
- **`impostos.tax_return_lines`** — Registo/gestão de tax, return, lines.
- **`impostos.tax_returns`** — Registo/gestão de tax, returns.
- **`impostos.tax_rules`** — Registo/gestão de tax, rules.
- **`impostos.tax_transactions`** — Registo/gestão de transações financeiras.
- **`impostos.taxes`** — Registo/gestão de impostos.
- **`impostos.withholding_tax_transactions`** — Registo/gestão de transações financeiras.
- **`impostos.withholding_taxes`** — Registo/gestão de impostos.

## Schema: `lgpd`

**Função:** Registo/gestão de dados de privacidade/LGPD.


### Tabelas

- **`lgpd.consentimentos`** — Registo/gestão de consentimentos.

## Schema: `logistica`

**Função:** Registo/gestão de logística/transporte.


### Tabelas

- **`logistica.logistics_drivers`** — Registo/gestão de logistics, drivers.
- **`logistica.logistics_routes`** — Registo/gestão de logistics, routes.
- **`logistica.logistics_shipments`** — Registo/gestão de logistics, shipments.
- **`logistica.logistics_tracking_events`** — Registo/gestão de logistics, tracking, events.
- **`logistica.logistics_vehicles`** — Registo/gestão de logistics, vehicles.

## Schema: `multi_moeda`

**Função:** Registo/gestão de multi, moeda.


### Tabelas

- **`multi_moeda.currencies`** — Registo/gestão de moedas.
- **`multi_moeda.exchange_rates`** — Registo/gestão de taxas de câmbio.
- **`multi_moeda.tenant_currencies`** — Registo/gestão de tenant, moedas.

## Schema: `notifications`

**Função:** Registo/gestão de notificações.


### Tabelas

- **`notifications.notification_channels`** — Registo/gestão de notification, channels.
- **`notifications.notification_messages`** — Registo/gestão de notification, messages.
- **`notifications.notification_templates`** — Registo/gestão de notification, templates.
- **`notifications.push_tokens`** — Registo/gestão de push, tokens.

## Schema: `pessoas`

**Função:** Registo/gestão de pessoas (entidade master), pessoa.


### Tabelas

- **`pessoas.pessoa_contatos`** — Registo/gestão de pessoa.
- **`pessoas.pessoa_enderecos`** — Registo/gestão de pessoa.
- **`pessoas.pessoa_relacoes`** — Registo/gestão de pessoa.
- **`pessoas.pessoas`** — Registo/gestão de pessoas (entidade master), pessoa.

## Schema: `pos`

**Função:** Registo/gestão de pos.


### Tabelas

- **`pos.pos_catalog_items`** — Registo/gestão de pos, catalog, items.
- **`pos.pos_sale_items`** — Registo/gestão de pos, sale, items.
- **`pos.pos_sale_payments`** — Registo/gestão de pagamentos.
- **`pos.pos_sales`** — Registo/gestão de pos, sales.
- **`pos.pos_sessions`** — Registo/gestão de sessões de login ativas, sessão.
- **`pos.pos_terminals`** — Registo/gestão de pos, terminals.

## Schema: `produtos`

**Função:** Registo/gestão de produtos/serviços.


### Tabelas

- **`produtos.product_attribute_values`** — Registo/gestão de produto.
- **`produtos.product_attributes`** — Registo/gestão de produto.
- **`produtos.product_barcodes`** — Registo/gestão de produto.
- **`produtos.product_brands`** — Registo/gestão de produto.
- **`produtos.product_categories`** — Registo/gestão de produto, categorias.
- **`produtos.product_discounts`** — Registo/gestão de produto.
- **`produtos.product_images`** — Registo/gestão de produto.
- **`produtos.product_kit_items`** — Registo/gestão de produto.
- **`produtos.product_kits`** — Registo/gestão de produto.
- **`produtos.product_prices`** — Registo/gestão de produto.
- **`produtos.product_subcategories`** — Registo/gestão de produto, categorias.
- **`produtos.product_tag_links`** — Registo/gestão de produto.
- **`produtos.product_tags`** — Registo/gestão de produto.
- **`produtos.product_units`** — Registo/gestão de produto.
- **`produtos.product_variants`** — Registo/gestão de produto.
- **`produtos.products`** — Registo/gestão de produtos, produto.
- **`produtos.warehouses`** — Registo/gestão de warehouses.

## Schema: `public`

**Função:** Registo/gestão de dados públicos/compartilhados.


### Tabelas

- **`public.chat_conversas`** — Registo/gestão de chat, conversas.
- **`public.chat_mensagens`** — Registo/gestão de chat, mensagens.
- **`public.chat_participantes`** — Registo/gestão de chat, participantes.
- **`public.comunicados`** — Registo/gestão de comunicados.
- **`public.comunicados_lidos`** — Registo/gestão de comunicados, lidos.
- **`public.notif_colaborador`** — Registo/gestão de notif, colaborador.
- **`public.schema_migrations`** — Registo/gestão de controlo de migrações da base de dados.

## Schema: `recrutamento`

**Função:** Registo/gestão de processo de recrutamento.


### Tabelas

- **`recrutamento.candidato_experiencias`** — Registo/gestão de candidato.
- **`recrutamento.candidato_formacoes`** — Registo/gestão de candidato.
- **`recrutamento.candidato_notificacoes`** — Registo/gestão de candidato.
- **`recrutamento.candidato_sessions`** — Registo/gestão de sessões de login ativas, sessão, candidato.
- **`recrutamento.candidatos`** — Registo/gestão de candidatos a vagas, candidato.
- **`recrutamento.candidatura_campos_custom`** — Registo/gestão de candidatura, campos, custom.
- **`recrutamento.candidatura_notas`** — Registo/gestão de notas/avaliações.
- **`recrutamento.candidatura_respostas_vaga`** — Registo/gestão de candidatura, respostas, vaga.
- **`recrutamento.candidatura_valores_custom`** — Registo/gestão de candidatura, valores, custom.
- **`recrutamento.candidaturas`** — Registo/gestão de candidaturas.
- **`recrutamento.config_notificacoes`** — Registo/gestão de config, notificacoes.
- **`recrutamento.contactos`** — Registo/gestão de contactos.
- **`recrutamento.vaga_campos`** — Registo/gestão de vaga, campos.
- **`recrutamento.vagas`** — Registo/gestão de vagas de emprego.

## Schema: `rh`

**Função:** Registo/gestão de rh.


### Tabelas

- **`rh.adiantamentos`** — Registo/gestão de adiantamentos.
- **`rh.auditoria_assiduidade`** — Registo/gestão de auditoria, assiduidade.
- **`rh.ausencias`** — Registo/gestão de ausencias.
- **`rh.avaliacao_criterios`** — Registo/gestão de avaliacao, criterios.
- **`rh.avaliacoes`** — Registo/gestão de avaliações.
- **`rh.beneficios`** — Registo/gestão de benefícios.
- **`rh.cargos`** — Registo/gestão de cargos/funções organizacionais.
- **`rh.componentes_salariais`** — Registo/gestão de componentes, salariais.
- **`rh.config_contabilidade_folha`** — Registo/gestão de config, contabilidade, folha.
- **`rh.contactos_emergencia`** — Registo/gestão de contactos, emergencia.
- **`rh.contratos`** — Registo/gestão de contratos de trabalho.
- **`rh.correcoes_evento`** — Registo/gestão de correcoes, evento.
- **`rh.criterios_avaliacao`** — Registo/gestão de criterios, avaliacao.
- **`rh.documentos_funcionario`** — Registo/gestão de funcionário, documentos.
- **`rh.emprestimos`** — Registo/gestão de emprestimos.
- **`rh.eventos_assiduidade`** — Registo/gestão de eventos, assiduidade.
- **`rh.folhas_pagamento`** — Registo/gestão de folhas, pagamento.
- **`rh.formacoes`** — Registo/gestão de formacoes.
- **`rh.funcionario_beneficios`** — Registo/gestão de funcionário, benefícios.
- **`rh.funcionario_componentes_salariais`** — Registo/gestão de funcionário.
- **`rh.funcionario_formacoes`** — Registo/gestão de funcionário.
- **`rh.funcionario_horarios`** — Registo/gestão de funcionário.
- **`rh.funcionarios`** — Registo/gestão de funcionários, funcionário.
- **`rh.historico_salarial`** — Registo/gestão de historico, salarial.
- **`rh.horarios_dias`** — Registo/gestão de horarios, dias.
- **`rh.horarios_trabalho`** — Registo/gestão de horarios, trabalho.
- **`rh.irps_escaloes`** — Registo/gestão de irps, escaloes.
- **`rh.justificacoes`** — Registo/gestão de justificacoes.
- **`rh.marcacoes_interpretadas`** — Registo/gestão de marcacoes, interpretadas.
- **`rh.metodos_marcacao`** — Registo/gestão de metodos, marcacao.
- **`rh.nfc_tags`** — Registo/gestão de nfc, tags.
- **`rh.periodos_avaliacao`** — Registo/gestão de periodos, avaliacao.
- **`rh.presencas`** — Registo/gestão de registo de presenças.
- **`rh.processos_disciplinares`** — Registo/gestão de processos, disciplinares.
- **`rh.qr_tokens`** — Registo/gestão de qr, tokens.
- **`rh.recibo_vencimento_itens`** — Registo/gestão de recibo.
- **`rh.recibos_vencimento`** — Registo/gestão de recibos, recibo, recibos de vencimento.
- **`rh.regras_assiduidade`** — Registo/gestão de regras, assiduidade.
- **`rh.resultados_diarios`** — Registo/gestão de diários contabilísticos.
- **`rh.resultados_periodos`** — Registo/gestão de resultados, periodos.
- **`rh.saldos_ausencia`** — Registo/gestão de saldos, ausencia.
- **`rh.tipos_ausencia`** — Registo/gestão de tipos, ausencia.
- **`rh.tipos_evento`** — Registo/gestão de tipos, evento.
- **`rh.tipos_regra`** — Registo/gestão de tipos, regra.
- **`rh.unidades_organizacionais`** — Registo/gestão de unidades, organizacionais.

## Schema: `saas`

**Função:** Registo/gestão de saas.


### Tabelas

- **`saas.approval_decisions`** — Registo/gestão de approval, decisions.
- **`saas.approval_flows`** — Registo/gestão de approval, flows.
- **`saas.approval_requests`** — Registo/gestão de approval, requests.
- **`saas.feature_catalog`** — Registo/gestão de feature, catalog.
- **`saas.global_settings`** — Registo/gestão de configurações/parametrizações.
- **`saas.module_catalog`** — Registo/gestão de module, catalog.
- **`saas.module_dependencies`** — Registo/gestão de module, dependencies.
- **`saas.plan_modules`** — Registo/gestão de plan, modules.
- **`saas.plans`** — Registo/gestão de planos.
- **`saas.tenant_dominios`** — Registo/gestão de tenant.
- **`saas.tenant_modules`** — Registo/gestão de tenant.
- **`saas.tenant_subscriptions`** — Registo/gestão de tenant, subscrições.
- **`saas.tenants`** — Registo/gestão de tenants/clientes do SaaS, tenant.

## Schema: `seguranca`

**Função:** Registo/gestão de seguranca.


### Tabelas

- **`seguranca.security_ip_allowlist`** — Registo/gestão de security, ip, allowlist.
- **`seguranca.security_mfa_enrollments`** — Registo/gestão de security, mfa, enrollments.
- **`seguranca.security_policies`** — Registo/gestão de security, policies.

## Schema: `sistema_configuracao`

**Função:** Registo/gestão de configurações do sistema.


### Tabelas

- **`sistema_configuracao.api_logs`** — Registo/gestão de api, logs.
- **`sistema_configuracao.cities`** — Registo/gestão de cities.
- **`sistema_configuracao.countries`** — Registo/gestão de countries.
- **`sistema_configuracao.currencies`** — Registo/gestão de moedas.
- **`sistema_configuracao.email_templates`** — Registo/gestão de email, templates.
- **`sistema_configuracao.exchange_rates`** — Registo/gestão de taxas de câmbio.
- **`sistema_configuracao.integrations`** — Registo/gestão de integrations.
- **`sistema_configuracao.languages`** — Registo/gestão de languages.
- **`sistema_configuracao.settings`** — Registo/gestão de configurações/parametrizações.
- **`sistema_configuracao.sms_templates`** — Registo/gestão de sms, templates.
- **`sistema_configuracao.system_logs`** — Registo/gestão de system, logs.
- **`sistema_configuracao.tenant_branding`** — Registo/gestão de tenant.
- **`sistema_configuracao.tenant_defaults`** — Registo/gestão de tenant.
- **`sistema_configuracao.tenant_document_settings`** — Registo/gestão de configurações/parametrizações, tenant.
- **`sistema_configuracao.tenant_feature_flags`** — Registo/gestão de tenant.
- **`sistema_configuracao.tenant_integrations`** — Registo/gestão de tenant.

## Schema: `stock`

**Função:** Registo/gestão de movimentos/saldos de stock.


### Tabelas

- **`stock.stock_adjustments`** — Registo/gestão de movimentos/saldos de stock.
- **`stock.stock_alerts`** — Registo/gestão de movimentos/saldos de stock.
- **`stock.stock_batches`** — Registo/gestão de movimentos/saldos de stock.
- **`stock.stock_count_items`** — Registo/gestão de movimentos/saldos de stock.
- **`stock.stock_counts`** — Registo/gestão de movimentos/saldos de stock.
- **`stock.stock_items`** — Registo/gestão de movimentos/saldos de stock.
- **`stock.stock_logs`** — Registo/gestão de movimentos/saldos de stock.
- **`stock.stock_movements`** — Registo/gestão de movimentos/saldos de stock.
- **`stock.stock_reservations`** — Registo/gestão de movimentos/saldos de stock.
- **`stock.stock_serial_numbers`** — Registo/gestão de movimentos/saldos de stock.
- **`stock.stock_transfer_items`** — Registo/gestão de movimentos/saldos de stock.
- **`stock.stock_transfers`** — Registo/gestão de movimentos/saldos de stock.
- **`stock.warehouse_locations`** — Registo/gestão de warehouse, locations.

## Schema: `tarefas`

**Função:** Registo/gestão de tarefas.


### Tabelas

- **`tarefas.cartoes`** — Registo/gestão de cartoes.
- **`tarefas.listas`** — Registo/gestão de listas.
- **`tarefas.quadros`** — Registo/gestão de quadros.

## Schema: `tesouraria`

**Função:** Registo/gestão de movimentos de tesouraria/caixa.


### Tabelas

- **`tesouraria.bank_accounts`** — Registo/gestão de contas bancárias.
- **`tesouraria.cash_registers`** — Registo/gestão de caixa/tesouraria.
- **`tesouraria.movements`** — Registo/gestão de movements.
- **`tesouraria.reconciliations`** — Registo/gestão de reconciliations.

## Schema: `utilizadores`

**Função:** Registo/gestão de utilizadores.


### Tabelas

- **`utilizadores.profiles`** — Registo/gestão de profiles.
- **`utilizadores.user_activity`** — Registo/gestão de utilizador.
- **`utilizadores.user_avatar`** — Registo/gestão de utilizador.
- **`utilizadores.user_devices`** — Registo/gestão de utilizador, dispositivos.
- **`utilizadores.user_notifications`** — Registo/gestão de utilizador, notificações.
- **`utilizadores.user_preferences`** — Registo/gestão de utilizador.
- **`utilizadores.user_security_logs`** — Registo/gestão de utilizador.
- **`utilizadores.user_settings`** — Registo/gestão de utilizador, configurações/parametrizações.
- **`utilizadores.user_tokens`** — Registo/gestão de utilizador.