--
-- PostgreSQL database dump
--

\restrict iAhGjcg1cd8t3fAklZSYQOhZPUgxgUhb7nBGnjG0xtppwgHrh7e6TKkDYq5um2h

-- Dumped from database version 15.15 (Debian 15.15-1.pgdg13+1)
-- Dumped by pg_dump version 18.1 (Debian 18.1-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY tesouraria.reconciliations DROP CONSTRAINT IF EXISTS reconciliations_bank_account_id_fkey;
ALTER TABLE IF EXISTS ONLY tesouraria.movements DROP CONSTRAINT IF EXISTS movements_cash_register_id_fkey;
ALTER TABLE IF EXISTS ONLY tesouraria.movements DROP CONSTRAINT IF EXISTS movements_bank_account_id_fkey;
ALTER TABLE IF EXISTS ONLY tesouraria.reconciliacoes_bancarias DROP CONSTRAINT IF EXISTS fk_reconciliacoes_conta;
ALTER TABLE IF EXISTS ONLY tesouraria.movimentos_financeiros DROP CONSTRAINT IF EXISTS fk_mov_conta;
ALTER TABLE IF EXISTS ONLY tesouraria.movimentos_financeiros DROP CONSTRAINT IF EXISTS fk_mov_caixa;
ALTER TABLE IF EXISTS ONLY stock.warehouse_locations DROP CONSTRAINT IF EXISTS fk_warehouse_locations_warehouse;
ALTER TABLE IF EXISTS ONLY stock.stock_serial_numbers DROP CONSTRAINT IF EXISTS fk_stock_serial_numbers_item;
ALTER TABLE IF EXISTS ONLY stock.stock_reservations DROP CONSTRAINT IF EXISTS fk_stock_reservations_item;
ALTER TABLE IF EXISTS ONLY stock.stock_movements DROP CONSTRAINT IF EXISTS fk_stock_movements_item;
ALTER TABLE IF EXISTS ONLY stock.stock_count_items DROP CONSTRAINT IF EXISTS fk_stock_count_items_count;
ALTER TABLE IF EXISTS ONLY stock.stock_batches DROP CONSTRAINT IF EXISTS fk_stock_batches_item;
ALTER TABLE IF EXISTS ONLY stock.stock_alerts DROP CONSTRAINT IF EXISTS fk_stock_alerts_item;
ALTER TABLE IF EXISTS ONLY stock.stock_adjustments DROP CONSTRAINT IF EXISTS fk_stock_adjustments_item;
ALTER TABLE IF EXISTS ONLY stock.stock_transfer_items DROP CONSTRAINT IF EXISTS fk_sti_transfer;
ALTER TABLE IF EXISTS ONLY stock.stock_transfer_items DROP CONSTRAINT IF EXISTS fk_sti_item;
ALTER TABLE IF EXISTS ONLY rh.saldos_ausencia DROP CONSTRAINT IF EXISTS saldos_ausencia_tipo_ausencia_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.saldos_ausencia DROP CONSTRAINT IF EXISTS saldos_ausencia_funcionario_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.presencas DROP CONSTRAINT IF EXISTS presencas_funcionario_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.justificacoes DROP CONSTRAINT IF EXISTS justificacoes_funcionario_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.justificacoes DROP CONSTRAINT IF EXISTS justificacoes_aprovado_por_fkey;
ALTER TABLE IF EXISTS ONLY rh.historico_salarial DROP CONSTRAINT IF EXISTS historico_salarial_funcionario_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.funcionarios DROP CONSTRAINT IF EXISTS funcionarios_horario_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.funcionarios DROP CONSTRAINT IF EXISTS funcionarios_cargo_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.funcionario_formacoes DROP CONSTRAINT IF EXISTS funcionario_formacoes_funcionario_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.funcionario_formacoes DROP CONSTRAINT IF EXISTS funcionario_formacoes_formacao_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.funcionario_componentes_salariais DROP CONSTRAINT IF EXISTS funcionario_componentes_salariais_funcionario_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.funcionario_componentes_salariais DROP CONSTRAINT IF EXISTS funcionario_componentes_salariais_componente_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.funcionario_beneficios DROP CONSTRAINT IF EXISTS funcionario_beneficios_funcionario_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.funcionario_beneficios DROP CONSTRAINT IF EXISTS funcionario_beneficios_beneficio_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.unidades_organizacionais DROP CONSTRAINT IF EXISTS fk_unidades_organizacionais_responsavel;
ALTER TABLE IF EXISTS ONLY rh.unidades_organizacionais DROP CONSTRAINT IF EXISTS fk_unidades_organizacionais_parent;
ALTER TABLE IF EXISTS ONLY rh.recibos_vencimento DROP CONSTRAINT IF EXISTS fk_recibos_vencimento_funcionario;
ALTER TABLE IF EXISTS ONLY rh.recibos_vencimento DROP CONSTRAINT IF EXISTS fk_recibos_vencimento_folha;
ALTER TABLE IF EXISTS ONLY rh.recibo_vencimento_itens DROP CONSTRAINT IF EXISTS fk_recibo_vencimento_itens_recibo;
ALTER TABLE IF EXISTS ONLY rh.processos_disciplinares DROP CONSTRAINT IF EXISTS fk_processos_disciplinares_funcionario;
ALTER TABLE IF EXISTS ONLY rh.funcionarios DROP CONSTRAINT IF EXISTS fk_funcionarios_user;
ALTER TABLE IF EXISTS ONLY rh.funcionarios DROP CONSTRAINT IF EXISTS fk_funcionarios_unidade;
ALTER TABLE IF EXISTS ONLY rh.contratos DROP CONSTRAINT IF EXISTS fk_contratos_funcionario;
ALTER TABLE IF EXISTS ONLY rh.avaliacoes DROP CONSTRAINT IF EXISTS fk_avaliacoes_periodo;
ALTER TABLE IF EXISTS ONLY rh.avaliacoes DROP CONSTRAINT IF EXISTS fk_avaliacoes_funcionario;
ALTER TABLE IF EXISTS ONLY rh.ausencias DROP CONSTRAINT IF EXISTS fk_ausencias_funcionario;
ALTER TABLE IF EXISTS ONLY rh.documentos_funcionario DROP CONSTRAINT IF EXISTS documentos_funcionario_funcionario_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.contactos_emergencia DROP CONSTRAINT IF EXISTS contactos_emergencia_funcionario_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.avaliacao_criterios DROP CONSTRAINT IF EXISTS avaliacao_criterios_criterio_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.avaliacao_criterios DROP CONSTRAINT IF EXISTS avaliacao_criterios_avaliacao_id_fkey;
ALTER TABLE IF EXISTS ONLY rh.ausencias DROP CONSTRAINT IF EXISTS ausencias_tipo_id_fkey;
ALTER TABLE IF EXISTS ONLY recursos_humanos.payroll_runs DROP CONSTRAINT IF EXISTS fk_payroll_runs_period;
ALTER TABLE IF EXISTS ONLY recursos_humanos.payroll_run_lines DROP CONSTRAINT IF EXISTS fk_payroll_run_lines_run;
ALTER TABLE IF EXISTS ONLY recursos_humanos.payroll_run_lines DROP CONSTRAINT IF EXISTS fk_payroll_run_lines_employee;
ALTER TABLE IF EXISTS ONLY recursos_humanos.employees DROP CONSTRAINT IF EXISTS fk_employees_department;
ALTER TABLE IF EXISTS ONLY recursos_humanos.employee_bank_accounts DROP CONSTRAINT IF EXISTS fk_employee_bank_accounts_employee;
ALTER TABLE IF EXISTS ONLY recrutamento.candidaturas DROP CONSTRAINT IF EXISTS fk_candidaturas_vaga;
ALTER TABLE IF EXISTS ONLY recrutamento.candidatura_notas DROP CONSTRAINT IF EXISTS fk_candidatura_notas_candidatura;
ALTER TABLE IF EXISTS ONLY public.notif_colaborador DROP CONSTRAINT IF EXISTS notif_colaborador_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.comunicados_lidos DROP CONSTRAINT IF EXISTS comunicados_lidos_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.comunicados_lidos DROP CONSTRAINT IF EXISTS comunicados_lidos_comunicado_id_fkey;
ALTER TABLE IF EXISTS ONLY public.comunicados DROP CONSTRAINT IF EXISTS comunicados_autor_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_participantes DROP CONSTRAINT IF EXISTS chat_participantes_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_participantes DROP CONSTRAINT IF EXISTS chat_participantes_conversa_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_mensagens DROP CONSTRAINT IF EXISTS chat_mensagens_conversa_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_mensagens DROP CONSTRAINT IF EXISTS chat_mensagens_autor_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_conversas DROP CONSTRAINT IF EXISTS chat_conversas_criado_por_fkey;
ALTER TABLE IF EXISTS ONLY produtos.products DROP CONSTRAINT IF EXISTS fk_products_warehouse;
ALTER TABLE IF EXISTS ONLY produtos.products DROP CONSTRAINT IF EXISTS fk_products_unit;
ALTER TABLE IF EXISTS ONLY produtos.products DROP CONSTRAINT IF EXISTS fk_products_subcategory;
ALTER TABLE IF EXISTS ONLY produtos.products DROP CONSTRAINT IF EXISTS fk_products_category;
ALTER TABLE IF EXISTS ONLY produtos.products DROP CONSTRAINT IF EXISTS fk_products_brand;
ALTER TABLE IF EXISTS ONLY produtos.product_variants DROP CONSTRAINT IF EXISTS fk_product_variants_product;
ALTER TABLE IF EXISTS ONLY produtos.product_tag_links DROP CONSTRAINT IF EXISTS fk_product_tag_links_tag;
ALTER TABLE IF EXISTS ONLY produtos.product_tag_links DROP CONSTRAINT IF EXISTS fk_product_tag_links_product;
ALTER TABLE IF EXISTS ONLY produtos.product_subcategories DROP CONSTRAINT IF EXISTS fk_product_subcategories_category;
ALTER TABLE IF EXISTS ONLY produtos.product_prices DROP CONSTRAINT IF EXISTS fk_product_prices_variant;
ALTER TABLE IF EXISTS ONLY produtos.product_prices DROP CONSTRAINT IF EXISTS fk_product_prices_product;
ALTER TABLE IF EXISTS ONLY produtos.product_kits DROP CONSTRAINT IF EXISTS fk_product_kits_product;
ALTER TABLE IF EXISTS ONLY produtos.product_kit_items DROP CONSTRAINT IF EXISTS fk_product_kit_items_variant;
ALTER TABLE IF EXISTS ONLY produtos.product_kit_items DROP CONSTRAINT IF EXISTS fk_product_kit_items_product;
ALTER TABLE IF EXISTS ONLY produtos.product_kit_items DROP CONSTRAINT IF EXISTS fk_product_kit_items_kit;
ALTER TABLE IF EXISTS ONLY produtos.product_images DROP CONSTRAINT IF EXISTS fk_product_images_product;
ALTER TABLE IF EXISTS ONLY produtos.product_discounts DROP CONSTRAINT IF EXISTS fk_product_discounts_variant;
ALTER TABLE IF EXISTS ONLY produtos.product_discounts DROP CONSTRAINT IF EXISTS fk_product_discounts_product;
ALTER TABLE IF EXISTS ONLY produtos.product_categories DROP CONSTRAINT IF EXISTS fk_product_categories_parent;
ALTER TABLE IF EXISTS ONLY produtos.product_barcodes DROP CONSTRAINT IF EXISTS fk_product_barcodes_product;
ALTER TABLE IF EXISTS ONLY produtos.product_attribute_values DROP CONSTRAINT IF EXISTS fk_product_attribute_values_variant;
ALTER TABLE IF EXISTS ONLY produtos.product_attribute_values DROP CONSTRAINT IF EXISTS fk_product_attribute_values_product;
ALTER TABLE IF EXISTS ONLY produtos.product_attribute_values DROP CONSTRAINT IF EXISTS fk_product_attribute_values_attribute;
ALTER TABLE IF EXISTS ONLY pos.pos_sessions DROP CONSTRAINT IF EXISTS fk_pos_sessions_terminal;
ALTER TABLE IF EXISTS ONLY pos.pos_sales DROP CONSTRAINT IF EXISTS fk_pos_sales_terminal;
ALTER TABLE IF EXISTS ONLY pos.pos_sales DROP CONSTRAINT IF EXISTS fk_pos_sales_session;
ALTER TABLE IF EXISTS ONLY pos.pos_sale_payments DROP CONSTRAINT IF EXISTS fk_pos_sale_payments_sale;
ALTER TABLE IF EXISTS ONLY pos.pos_sale_items DROP CONSTRAINT IF EXISTS fk_pos_sale_items_sale;
ALTER TABLE IF EXISTS ONLY notifications.notification_messages DROP CONSTRAINT IF EXISTS fk_notification_messages_template;
ALTER TABLE IF EXISTS ONLY notifications.notification_messages DROP CONSTRAINT IF EXISTS fk_notification_messages_channel;
ALTER TABLE IF EXISTS ONLY multi_moeda.tenant_currencies DROP CONSTRAINT IF EXISTS fk_tenant_currencies_currency;
ALTER TABLE IF EXISTS ONLY multi_moeda.exchange_rates DROP CONSTRAINT IF EXISTS fk_exchange_rates_quote;
ALTER TABLE IF EXISTS ONLY multi_moeda.exchange_rates DROP CONSTRAINT IF EXISTS fk_exchange_rates_base;
ALTER TABLE IF EXISTS ONLY logistica.shipments DROP CONSTRAINT IF EXISTS shipments_vehicle_id_fkey;
ALTER TABLE IF EXISTS ONLY logistica.shipments DROP CONSTRAINT IF EXISTS shipments_status_id_fkey;
ALTER TABLE IF EXISTS ONLY logistica.shipments DROP CONSTRAINT IF EXISTS shipments_route_id_fkey;
ALTER TABLE IF EXISTS ONLY logistica.shipments DROP CONSTRAINT IF EXISTS shipments_driver_id_fkey;
ALTER TABLE IF EXISTS ONLY logistica.shipment_items DROP CONSTRAINT IF EXISTS shipment_items_shipment_id_fkey;
ALTER TABLE IF EXISTS ONLY logistica.logistics_tracking_events DROP CONSTRAINT IF EXISTS fk_logistics_tracking_events_shipment;
ALTER TABLE IF EXISTS ONLY logistica.logistics_shipments DROP CONSTRAINT IF EXISTS fk_logistics_shipments_vehicle;
ALTER TABLE IF EXISTS ONLY logistica.logistics_shipments DROP CONSTRAINT IF EXISTS fk_logistics_shipments_route;
ALTER TABLE IF EXISTS ONLY logistica.logistics_shipments DROP CONSTRAINT IF EXISTS fk_logistics_shipments_driver;
ALTER TABLE IF EXISTS ONLY logistica.delivery_tracking DROP CONSTRAINT IF EXISTS delivery_tracking_status_id_fkey;
ALTER TABLE IF EXISTS ONLY logistica.delivery_tracking DROP CONSTRAINT IF EXISTS delivery_tracking_shipment_id_fkey;
ALTER TABLE IF EXISTS ONLY impostos.taxes DROP CONSTRAINT IF EXISTS taxes_tax_group_id_fkey;
ALTER TABLE IF EXISTS ONLY impostos.withholding_tax_transactions DROP CONSTRAINT IF EXISTS fk_wtt_wt;
ALTER TABLE IF EXISTS ONLY impostos.tax_transactions DROP CONSTRAINT IF EXISTS fk_tax_transactions_tax;
ALTER TABLE IF EXISTS ONLY impostos.tax_transactions DROP CONSTRAINT IF EXISTS fk_tax_transactions_period;
ALTER TABLE IF EXISTS ONLY impostos.tax_rules DROP CONSTRAINT IF EXISTS fk_tax_rules_tax;
ALTER TABLE IF EXISTS ONLY impostos.tax_returns DROP CONSTRAINT IF EXISTS fk_tax_returns_substitui;
ALTER TABLE IF EXISTS ONLY impostos.tax_return_lines DROP CONSTRAINT IF EXISTS fk_tax_return_lines_return;
ALTER TABLE IF EXISTS ONLY impostos.tax_exemptions DROP CONSTRAINT IF EXISTS fk_tax_exemptions_tax;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_terms DROP CONSTRAINT IF EXISTS school_terms_school_year_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_teacher_roles DROP CONSTRAINT IF EXISTS school_teacher_roles_school_year_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_teacher_assignments DROP CONSTRAINT IF EXISTS school_teacher_assignments_subject_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_teacher_assignments DROP CONSTRAINT IF EXISTS school_teacher_assignments_school_year_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_teacher_assignments DROP CONSTRAINT IF EXISTS school_teacher_assignments_class_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_student_roles DROP CONSTRAINT IF EXISTS school_student_roles_student_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_student_roles DROP CONSTRAINT IF EXISTS school_student_roles_class_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_payments DROP CONSTRAINT IF EXISTS school_payments_student_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_payments DROP CONSTRAINT IF EXISTS school_payments_school_fee_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_library_loans DROP CONSTRAINT IF EXISTS school_library_loans_student_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_library_loans DROP CONSTRAINT IF EXISTS school_library_loans_book_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_guardians DROP CONSTRAINT IF EXISTS school_guardians_student_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_grades DROP CONSTRAINT IF EXISTS school_grades_student_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_grades DROP CONSTRAINT IF EXISTS school_grades_grade_item_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_grades DROP CONSTRAINT IF EXISTS school_grades_enrollment_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_grade_items DROP CONSTRAINT IF EXISTS school_grade_items_term_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_grade_items DROP CONSTRAINT IF EXISTS school_grade_items_subject_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_grade_items DROP CONSTRAINT IF EXISTS school_grade_items_class_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_fees DROP CONSTRAINT IF EXISTS school_fees_student_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_fees DROP CONSTRAINT IF EXISTS school_fees_fee_plan_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_fee_plans DROP CONSTRAINT IF EXISTS school_fee_plans_school_year_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_enrollments DROP CONSTRAINT IF EXISTS school_enrollments_school_year_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_classes DROP CONSTRAINT IF EXISTS school_classes_school_year_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_attendance DROP CONSTRAINT IF EXISTS school_attendance_subject_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_attendance DROP CONSTRAINT IF EXISTS school_attendance_enrollment_id_fkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_fees DROP CONSTRAINT IF EXISTS fk_school_fees_enrollment;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_enrollments DROP CONSTRAINT IF EXISTS fk_school_enrollments_student;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_enrollments DROP CONSTRAINT IF EXISTS fk_school_enrollments_class;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_attendance DROP CONSTRAINT IF EXISTS fk_school_attendance_student;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_attendance DROP CONSTRAINT IF EXISTS fk_school_attendance_class;
ALTER TABLE IF EXISTS ONLY financeiro.payments DROP CONSTRAINT IF EXISTS fk_payments_method;
ALTER TABLE IF EXISTS ONLY financeiro.payments DROP CONSTRAINT IF EXISTS fk_payments_category;
ALTER TABLE IF EXISTS ONLY financeiro.financial_categories DROP CONSTRAINT IF EXISTS fk_financial_categories_parent;
ALTER TABLE IF EXISTS ONLY financeiro.cash_flow_entries DROP CONSTRAINT IF EXISTS fk_cashflow_category;
ALTER TABLE IF EXISTS ONLY financeiro.financial_budgets DROP CONSTRAINT IF EXISTS fk_budgets_category;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_receivable_payments DROP CONSTRAINT IF EXISTS fk_ar_payments_payment;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_receivable_payments DROP CONSTRAINT IF EXISTS fk_ar_payments_ar;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_receivable DROP CONSTRAINT IF EXISTS fk_ar_category;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_payable_payments DROP CONSTRAINT IF EXISTS fk_ap_payments_payment;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_payable_payments DROP CONSTRAINT IF EXISTS fk_ap_payments_ap;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_payable DROP CONSTRAINT IF EXISTS fk_ap_category;
ALTER TABLE IF EXISTS ONLY faturacao.sales_returns DROP CONSTRAINT IF EXISTS fk_returns_invoice;
ALTER TABLE IF EXISTS ONLY faturacao.sales_returns DROP CONSTRAINT IF EXISTS fk_returns_cn;
ALTER TABLE IF EXISTS ONLY faturacao.sales_return_items DROP CONSTRAINT IF EXISTS fk_return_items_return;
ALTER TABLE IF EXISTS ONLY faturacao.invoice_receipts DROP CONSTRAINT IF EXISTS fk_receipts_serie;
ALTER TABLE IF EXISTS ONLY faturacao.invoice_receipts DROP CONSTRAINT IF EXISTS fk_receipts_invoice;
ALTER TABLE IF EXISTS ONLY faturacao.sales_quotes DROP CONSTRAINT IF EXISTS fk_quotes_serie;
ALTER TABLE IF EXISTS ONLY faturacao.sales_quote_items DROP CONSTRAINT IF EXISTS fk_quote_items_quote;
ALTER TABLE IF EXISTS ONLY faturacao.sales_orders DROP CONSTRAINT IF EXISTS fk_orders_serie;
ALTER TABLE IF EXISTS ONLY faturacao.sales_orders DROP CONSTRAINT IF EXISTS fk_orders_quote;
ALTER TABLE IF EXISTS ONLY faturacao.sales_order_items DROP CONSTRAINT IF EXISTS fk_order_items_order;
ALTER TABLE IF EXISTS ONLY faturacao.invoices DROP CONSTRAINT IF EXISTS fk_invoices_serie;
ALTER TABLE IF EXISTS ONLY faturacao.invoices DROP CONSTRAINT IF EXISTS fk_invoices_order;
ALTER TABLE IF EXISTS ONLY faturacao.invoice_taxes DROP CONSTRAINT IF EXISTS fk_invoice_taxes_invoice;
ALTER TABLE IF EXISTS ONLY faturacao.invoice_items DROP CONSTRAINT IF EXISTS fk_invoice_items_tax_exemption;
ALTER TABLE IF EXISTS ONLY faturacao.invoice_items DROP CONSTRAINT IF EXISTS fk_invoice_items_invoice;
ALTER TABLE IF EXISTS ONLY faturacao.invoice_discounts DROP CONSTRAINT IF EXISTS fk_invoice_discounts_invoice;
ALTER TABLE IF EXISTS ONLY faturacao.sales_delivery_items DROP CONSTRAINT IF EXISTS fk_delivery_items_delivery;
ALTER TABLE IF EXISTS ONLY faturacao.sales_deliveries DROP CONSTRAINT IF EXISTS fk_deliveries_serie;
ALTER TABLE IF EXISTS ONLY faturacao.sales_deliveries DROP CONSTRAINT IF EXISTS fk_deliveries_order;
ALTER TABLE IF EXISTS ONLY faturacao.credit_notes DROP CONSTRAINT IF EXISTS fk_credit_notes_serie;
ALTER TABLE IF EXISTS ONLY faturacao.credit_notes DROP CONSTRAINT IF EXISTS fk_credit_notes_invoice;
ALTER TABLE IF EXISTS ONLY faturacao.credit_note_items DROP CONSTRAINT IF EXISTS fk_credit_note_items_nc;
ALTER TABLE IF EXISTS ONLY empresas.company_users DROP CONSTRAINT IF EXISTS fk_company_users_company;
ALTER TABLE IF EXISTS ONLY empresas.company_users DROP CONSTRAINT IF EXISTS fk_company_users_branch;
ALTER TABLE IF EXISTS ONLY empresas.company_tax_info DROP CONSTRAINT IF EXISTS fk_company_tax_info_company;
ALTER TABLE IF EXISTS ONLY empresas.company_settings DROP CONSTRAINT IF EXISTS fk_company_settings_company;
ALTER TABLE IF EXISTS ONLY empresas.company_licenses DROP CONSTRAINT IF EXISTS fk_company_licenses_company;
ALTER TABLE IF EXISTS ONLY empresas.company_documents DROP CONSTRAINT IF EXISTS fk_company_documents_company;
ALTER TABLE IF EXISTS ONLY empresas.company_contacts DROP CONSTRAINT IF EXISTS fk_company_contacts_company;
ALTER TABLE IF EXISTS ONLY empresas.company_contacts DROP CONSTRAINT IF EXISTS fk_company_contacts_branch;
ALTER TABLE IF EXISTS ONLY empresas.company_branches DROP CONSTRAINT IF EXISTS fk_company_branches_company;
ALTER TABLE IF EXISTS ONLY empresas.company_banks DROP CONSTRAINT IF EXISTS fk_company_banks_company;
ALTER TABLE IF EXISTS ONLY empresas.company_addresses DROP CONSTRAINT IF EXISTS fk_company_addresses_company;
ALTER TABLE IF EXISTS ONLY empresas.company_addresses DROP CONSTRAINT IF EXISTS fk_company_addresses_branch;
ALTER TABLE IF EXISTS ONLY empresa.company_users DROP CONSTRAINT IF EXISTS fk_company_users_company;
ALTER TABLE IF EXISTS ONLY empresa.company_users DROP CONSTRAINT IF EXISTS fk_company_users_branch;
ALTER TABLE IF EXISTS ONLY empresa.company_tax_info DROP CONSTRAINT IF EXISTS fk_company_tax_info_company;
ALTER TABLE IF EXISTS ONLY empresa.company_settings DROP CONSTRAINT IF EXISTS fk_company_settings_company;
ALTER TABLE IF EXISTS ONLY empresa.company_licenses DROP CONSTRAINT IF EXISTS fk_company_licenses_company;
ALTER TABLE IF EXISTS ONLY empresa.company_documents DROP CONSTRAINT IF EXISTS fk_company_documents_company;
ALTER TABLE IF EXISTS ONLY empresa.company_contacts DROP CONSTRAINT IF EXISTS fk_company_contacts_company;
ALTER TABLE IF EXISTS ONLY empresa.company_contacts DROP CONSTRAINT IF EXISTS fk_company_contacts_branch;
ALTER TABLE IF EXISTS ONLY empresa.company_branches DROP CONSTRAINT IF EXISTS fk_company_branches_company;
ALTER TABLE IF EXISTS ONLY empresa.company_banks DROP CONSTRAINT IF EXISTS fk_company_banks_company;
ALTER TABLE IF EXISTS ONLY empresa.company_addresses DROP CONSTRAINT IF EXISTS fk_company_addresses_company;
ALTER TABLE IF EXISTS ONLY empresa.company_addresses DROP CONSTRAINT IF EXISTS fk_company_addresses_branch;
ALTER TABLE IF EXISTS ONLY crm.oportunidades DROP CONSTRAINT IF EXISTS fk_oportunidades_lead;
ALTER TABLE IF EXISTS ONLY crm.crm_pipeline_stages DROP CONSTRAINT IF EXISTS fk_crm_pipeline_stages_pipeline;
ALTER TABLE IF EXISTS ONLY crm.crm_opportunities DROP CONSTRAINT IF EXISTS fk_crm_opportunities_stage;
ALTER TABLE IF EXISTS ONLY crm.crm_opportunities DROP CONSTRAINT IF EXISTS fk_crm_opportunities_pipeline;
ALTER TABLE IF EXISTS ONLY crm.crm_opportunities DROP CONSTRAINT IF EXISTS fk_crm_opportunities_lead;
ALTER TABLE IF EXISTS ONLY crm.crm_leads DROP CONSTRAINT IF EXISTS fk_crm_leads_source;
ALTER TABLE IF EXISTS ONLY crm.crm_activities DROP CONSTRAINT IF EXISTS fk_crm_activities_opportunity;
ALTER TABLE IF EXISTS ONLY crm.crm_activities DROP CONSTRAINT IF EXISTS fk_crm_activities_lead;
ALTER TABLE IF EXISTS ONLY crm.atividades DROP CONSTRAINT IF EXISTS fk_atividades_oportunidade;
ALTER TABLE IF EXISTS ONLY crm.atividades DROP CONSTRAINT IF EXISTS fk_atividades_lead;
ALTER TABLE IF EXISTS ONLY contabilidade.journal_entry_sequences DROP CONSTRAINT IF EXISTS journal_entry_sequences_accounting_journal_id_fkey;
ALTER TABLE IF EXISTS ONLY contabilidade.period_closings DROP CONSTRAINT IF EXISTS fk_period_closings_period;
ALTER TABLE IF EXISTS ONLY contabilidade.period_closing_checks DROP CONSTRAINT IF EXISTS fk_period_closing_checks_closing;
ALTER TABLE IF EXISTS ONLY contabilidade.journal_entry_lines DROP CONSTRAINT IF EXISTS fk_journal_entry_lines_entry;
ALTER TABLE IF EXISTS ONLY contabilidade.journal_entry_lines DROP CONSTRAINT IF EXISTS fk_journal_entry_lines_account;
ALTER TABLE IF EXISTS ONLY contabilidade.journal_entries DROP CONSTRAINT IF EXISTS fk_journal_entries_period;
ALTER TABLE IF EXISTS ONLY contabilidade.journal_entries DROP CONSTRAINT IF EXISTS fk_journal_entries_journal;
ALTER TABLE IF EXISTS ONLY contabilidade.fixed_assets DROP CONSTRAINT IF EXISTS fk_fixed_assets_depr_account;
ALTER TABLE IF EXISTS ONLY contabilidade.fixed_assets DROP CONSTRAINT IF EXISTS fk_fixed_assets_accum_account;
ALTER TABLE IF EXISTS ONLY contabilidade.fixed_assets DROP CONSTRAINT IF EXISTS fk_fixed_assets_account;
ALTER TABLE IF EXISTS ONLY contabilidade.depreciation_entries DROP CONSTRAINT IF EXISTS fk_depreciation_entries_period;
ALTER TABLE IF EXISTS ONLY contabilidade.depreciation_entries DROP CONSTRAINT IF EXISTS fk_depreciation_entries_journal;
ALTER TABLE IF EXISTS ONLY contabilidade.depreciation_entries DROP CONSTRAINT IF EXISTS fk_depreciation_entries_asset;
ALTER TABLE IF EXISTS ONLY contabilidade.chart_of_accounts DROP CONSTRAINT IF EXISTS fk_chart_parent;
ALTER TABLE IF EXISTS ONLY contabilidade.accounting_budgets DROP CONSTRAINT IF EXISTS fk_accounting_budgets_year;
ALTER TABLE IF EXISTS ONLY contabilidade.accounting_budgets DROP CONSTRAINT IF EXISTS fk_accounting_budgets_account;
ALTER TABLE IF EXISTS ONLY contabilidade.fiscal_periods DROP CONSTRAINT IF EXISTS fiscal_periods_fiscal_year_id_fkey;
ALTER TABLE IF EXISTS ONLY contabilidade.chart_of_accounts DROP CONSTRAINT IF EXISTS chart_of_accounts_account_type_id_fkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_request_items DROP CONSTRAINT IF EXISTS purchase_request_items_purchase_request_id_fkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_payments DROP CONSTRAINT IF EXISTS purchase_payments_supplier_id_fkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_payment_items DROP CONSTRAINT IF EXISTS purchase_payment_items_purchase_payment_id_fkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_payment_items DROP CONSTRAINT IF EXISTS purchase_payment_items_purchase_invoice_id_fkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_orders DROP CONSTRAINT IF EXISTS purchase_orders_purchase_request_id_fkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_invoices DROP CONSTRAINT IF EXISTS purchase_invoices_supplier_id_fkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_invoices DROP CONSTRAINT IF EXISTS purchase_invoices_purchase_order_id_fkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_invoices DROP CONSTRAINT IF EXISTS purchase_invoices_goods_receipt_id_fkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_invoice_items DROP CONSTRAINT IF EXISTS purchase_invoice_items_purchase_order_item_id_fkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_invoice_items DROP CONSTRAINT IF EXISTS purchase_invoice_items_purchase_invoice_id_fkey;
ALTER TABLE IF EXISTS ONLY compras.suppliers DROP CONSTRAINT IF EXISTS fk_suppliers_group;
ALTER TABLE IF EXISTS ONLY compras.supplier_contacts DROP CONSTRAINT IF EXISTS fk_supplier_contacts_supplier;
ALTER TABLE IF EXISTS ONLY compras.supplier_addresses DROP CONSTRAINT IF EXISTS fk_supplier_addresses_supplier;
ALTER TABLE IF EXISTS ONLY compras.purchase_returns DROP CONSTRAINT IF EXISTS fk_purchase_returns_supplier;
ALTER TABLE IF EXISTS ONLY compras.purchase_returns DROP CONSTRAINT IF EXISTS fk_purchase_returns_receipt;
ALTER TABLE IF EXISTS ONLY compras.purchase_return_items DROP CONSTRAINT IF EXISTS fk_purchase_return_items_return;
ALTER TABLE IF EXISTS ONLY compras.purchase_return_items DROP CONSTRAINT IF EXISTS fk_purchase_return_items_receipt_item;
ALTER TABLE IF EXISTS ONLY compras.purchase_orders DROP CONSTRAINT IF EXISTS fk_purchase_orders_supplier;
ALTER TABLE IF EXISTS ONLY compras.purchase_order_items DROP CONSTRAINT IF EXISTS fk_purchase_order_items_order;
ALTER TABLE IF EXISTS ONLY compras.goods_receipts DROP CONSTRAINT IF EXISTS fk_goods_receipts_supplier;
ALTER TABLE IF EXISTS ONLY compras.goods_receipts DROP CONSTRAINT IF EXISTS fk_goods_receipts_order;
ALTER TABLE IF EXISTS ONLY compras.goods_receipt_items DROP CONSTRAINT IF EXISTS fk_goods_receipt_items_receipt;
ALTER TABLE IF EXISTS ONLY compras.goods_receipt_items DROP CONSTRAINT IF EXISTS fk_goods_receipt_items_order_item;
ALTER TABLE IF EXISTS ONLY clientes.customers DROP CONSTRAINT IF EXISTS fk_customers_group;
ALTER TABLE IF EXISTS ONLY clientes.customer_tag_links DROP CONSTRAINT IF EXISTS fk_customer_tag_links_tag;
ALTER TABLE IF EXISTS ONLY clientes.customer_tag_links DROP CONSTRAINT IF EXISTS fk_customer_tag_links_customer;
ALTER TABLE IF EXISTS ONLY clientes.customer_payments DROP CONSTRAINT IF EXISTS fk_customer_payments_customer;
ALTER TABLE IF EXISTS ONLY clientes.customer_notes DROP CONSTRAINT IF EXISTS fk_customer_notes_customer;
ALTER TABLE IF EXISTS ONLY clientes.customer_history DROP CONSTRAINT IF EXISTS fk_customer_history_customer;
ALTER TABLE IF EXISTS ONLY clientes.customer_documents DROP CONSTRAINT IF EXISTS fk_customer_documents_customer;
ALTER TABLE IF EXISTS ONLY clientes.customer_discounts DROP CONSTRAINT IF EXISTS fk_customer_discounts_customer;
ALTER TABLE IF EXISTS ONLY clientes.customer_credit_limits DROP CONSTRAINT IF EXISTS fk_customer_credit_limits_customer;
ALTER TABLE IF EXISTS ONLY clientes.customer_contacts DROP CONSTRAINT IF EXISTS fk_customer_contacts_customer;
ALTER TABLE IF EXISTS ONLY clientes.customer_balances DROP CONSTRAINT IF EXISTS fk_customer_balances_customer;
ALTER TABLE IF EXISTS ONLY clientes.customer_addresses DROP CONSTRAINT IF EXISTS fk_customer_addresses_customer;
ALTER TABLE IF EXISTS ONLY centros_custo.cost_centers DROP CONSTRAINT IF EXISTS fk_cost_centers_parent;
ALTER TABLE IF EXISTS ONLY centros_custo.cost_center_budgets DROP CONSTRAINT IF EXISTS fk_cost_center_budgets_center;
ALTER TABLE IF EXISTS ONLY centros_custo.cost_center_allocations DROP CONSTRAINT IF EXISTS fk_cost_center_allocations_center;
ALTER TABLE IF EXISTS ONLY autorizacao.user_roles DROP CONSTRAINT IF EXISTS fk_user_roles_role;
ALTER TABLE IF EXISTS ONLY autorizacao.role_permissions DROP CONSTRAINT IF EXISTS fk_role_permissions_role;
ALTER TABLE IF EXISTS ONLY autorizacao.role_permissions DROP CONSTRAINT IF EXISTS fk_role_permissions_permission;
ALTER TABLE IF EXISTS ONLY auth.permissoes_diretas DROP CONSTRAINT IF EXISTS permissoes_diretas_user_id_fkey;
ALTER TABLE IF EXISTS ONLY auth.permissoes_cargo DROP CONSTRAINT IF EXISTS permissoes_cargo_cargo_id_fkey;
ALTER TABLE IF EXISTS ONLY auth.users DROP CONSTRAINT IF EXISTS fk_users_cargo;
ALTER TABLE IF EXISTS ONLY auth.sessions DROP CONSTRAINT IF EXISTS fk_sessions_user;
ALTER TABLE IF EXISTS ONLY auth.password_resets DROP CONSTRAINT IF EXISTS fk_password_resets_user;
ALTER TABLE IF EXISTS ONLY auth.login_history DROP CONSTRAINT IF EXISTS fk_login_history_user;
ALTER TABLE IF EXISTS ONLY auth.email_verifications DROP CONSTRAINT IF EXISTS fk_email_verifications_user;
ALTER TABLE IF EXISTS ONLY auth.api_keys DROP CONSTRAINT IF EXISTS fk_api_keys_user;
ALTER TABLE IF EXISTS ONLY assinaturas.subscriptions DROP CONSTRAINT IF EXISTS fk_subscriptions_plan;
ALTER TABLE IF EXISTS ONLY assinaturas.subscription_usage DROP CONSTRAINT IF EXISTS fk_subscription_usage_subscription;
ALTER TABLE IF EXISTS ONLY assinaturas.subscription_invoices DROP CONSTRAINT IF EXISTS fk_subscription_invoices_subscription;
DROP TRIGGER IF EXISTS tax_returns_immutable ON impostos.tax_returns;
DROP TRIGGER IF EXISTS tax_return_lines_immutable ON impostos.tax_return_lines;
DROP INDEX IF EXISTS utilizadores.idx_user_tokens_user_id;
DROP INDEX IF EXISTS utilizadores.idx_user_settings_user_id;
DROP INDEX IF EXISTS utilizadores.idx_user_security_logs_user_id;
DROP INDEX IF EXISTS utilizadores.idx_user_notifications_user_id;
DROP INDEX IF EXISTS utilizadores.idx_user_notifications_lida;
DROP INDEX IF EXISTS utilizadores.idx_user_devices_user_id;
DROP INDEX IF EXISTS utilizadores.idx_user_avatar_user_id;
DROP INDEX IF EXISTS utilizadores.idx_user_activity_user_id;
DROP INDEX IF EXISTS utilizadores.idx_profiles_user_id;
DROP INDEX IF EXISTS tesouraria.idx_treasury_reconciliations_tenant_status;
DROP INDEX IF EXISTS tesouraria.idx_treasury_movements_tenant_date;
DROP INDEX IF EXISTS tesouraria.idx_reconciliacoes_conta_id;
DROP INDEX IF EXISTS tesouraria.idx_movimentos_tenant_id;
DROP INDEX IF EXISTS tesouraria.idx_contas_bancarias_tenant_id;
DROP INDEX IF EXISTS tesouraria.idx_caixas_tenant_id;
DROP INDEX IF EXISTS stock.uq_stock_count_items;
DROP INDEX IF EXISTS stock.idx_stock_transfers_tenant;
DROP INDEX IF EXISTS stock.idx_stock_reservations_tenant_status;
DROP INDEX IF EXISTS stock.idx_stock_movements_tenant;
DROP INDEX IF EXISTS stock.idx_stock_movements_item;
DROP INDEX IF EXISTS stock.idx_stock_movements_date;
DROP INDEX IF EXISTS stock.idx_stock_items_tenant;
DROP INDEX IF EXISTS stock.idx_stock_items_product_warehouse;
DROP INDEX IF EXISTS stock.idx_stock_items_product;
DROP INDEX IF EXISTS stock.idx_stock_counts_tenant_status;
DROP INDEX IF EXISTS stock.idx_stock_batches_expiry;
DROP INDEX IF EXISTS stock.idx_stock_alerts_tenant_status;
DROP INDEX IF EXISTS stock.idx_stock_alerts_tenant;
DROP INDEX IF EXISTS sistema_configuracao.idx_tenant_integrations_tenant;
DROP INDEX IF EXISTS sistema_configuracao.idx_tenant_feature_flags_tenant;
DROP INDEX IF EXISTS sistema_configuracao.idx_tenant_document_settings_tenant;
DROP INDEX IF EXISTS sistema_configuracao.idx_tenant_defaults_tenant;
DROP INDEX IF EXISTS seguranca.idx_security_policies_tenant;
DROP INDEX IF EXISTS seguranca.idx_security_mfa_enrollments_tenant;
DROP INDEX IF EXISTS seguranca.idx_security_ip_allowlist_tenant;
DROP INDEX IF EXISTS rh.uq_funcionarios_tenant_numero;
DROP INDEX IF EXISTS rh.idx_unidades_organizacionais_tenant_id;
DROP INDEX IF EXISTS rh.idx_unidades_organizacionais_parent_id;
DROP INDEX IF EXISTS rh.idx_tipos_ausencia_tenant_id;
DROP INDEX IF EXISTS rh.idx_saldos_ausencia_funcionario_id;
DROP INDEX IF EXISTS rh.idx_recibos_vencimento_tenant_id;
DROP INDEX IF EXISTS rh.idx_recibos_vencimento_funcionario_id;
DROP INDEX IF EXISTS rh.idx_recibos_vencimento_folha_id;
DROP INDEX IF EXISTS rh.idx_recibo_vencimento_itens_recibo_id;
DROP INDEX IF EXISTS rh.idx_processos_disciplinares_tenant_id;
DROP INDEX IF EXISTS rh.idx_processos_disciplinares_funcionario_id;
DROP INDEX IF EXISTS rh.idx_processos_disciplinares_estado;
DROP INDEX IF EXISTS rh.idx_presencas_tenant_data;
DROP INDEX IF EXISTS rh.idx_presencas_funcionario_id;
DROP INDEX IF EXISTS rh.idx_periodos_avaliacao_tenant_id;
DROP INDEX IF EXISTS rh.idx_justif_tenant_estado;
DROP INDEX IF EXISTS rh.idx_justif_funcionario;
DROP INDEX IF EXISTS rh.idx_horarios_trabalho_tenant_id;
DROP INDEX IF EXISTS rh.idx_historico_salarial_funcionario_id;
DROP INDEX IF EXISTS rh.idx_funcionarios_user_id;
DROP INDEX IF EXISTS rh.idx_funcionarios_unit_id;
DROP INDEX IF EXISTS rh.idx_funcionarios_tenant_id;
DROP INDEX IF EXISTS rh.idx_funcionarios_horario_id;
DROP INDEX IF EXISTS rh.idx_funcionarios_cargo_id;
DROP INDEX IF EXISTS rh.idx_funcionario_formacoes_funcionario_id;
DROP INDEX IF EXISTS rh.idx_funcionario_formacoes_formacao_id;
DROP INDEX IF EXISTS rh.idx_funcionario_componentes_funcionario_id;
DROP INDEX IF EXISTS rh.idx_funcionario_beneficios_funcionario_id;
DROP INDEX IF EXISTS rh.idx_formacoes_tenant_id;
DROP INDEX IF EXISTS rh.idx_folhas_pagamento_tenant_id;
DROP INDEX IF EXISTS rh.idx_documentos_funcionario_funcionario_id;
DROP INDEX IF EXISTS rh.idx_criterios_avaliacao_tenant_id;
DROP INDEX IF EXISTS rh.idx_contratos_tenant_id;
DROP INDEX IF EXISTS rh.idx_contratos_funcionario_id;
DROP INDEX IF EXISTS rh.idx_contactos_emergencia_funcionario_id;
DROP INDEX IF EXISTS rh.idx_componentes_salariais_tenant_id;
DROP INDEX IF EXISTS rh.idx_cargos_tenant_id;
DROP INDEX IF EXISTS rh.idx_beneficios_tenant_id;
DROP INDEX IF EXISTS rh.idx_avaliacoes_tenant_id;
DROP INDEX IF EXISTS rh.idx_avaliacoes_periodo_id;
DROP INDEX IF EXISTS rh.idx_avaliacoes_funcionario_id;
DROP INDEX IF EXISTS rh.idx_avaliacao_criterios_avaliacao_id;
DROP INDEX IF EXISTS rh.idx_ausencias_tipo_id;
DROP INDEX IF EXISTS rh.idx_ausencias_tenant_id;
DROP INDEX IF EXISTS rh.idx_ausencias_funcionario_id;
DROP INDEX IF EXISTS rh.idx_ausencias_estado;
DROP INDEX IF EXISTS recursos_humanos.idx_payroll_runs_tenant;
DROP INDEX IF EXISTS recursos_humanos.idx_payroll_run_lines_run;
DROP INDEX IF EXISTS recursos_humanos.idx_payroll_periods_tenant;
DROP INDEX IF EXISTS recursos_humanos.idx_hr_departments_tenant;
DROP INDEX IF EXISTS recursos_humanos.idx_employees_tenant;
DROP INDEX IF EXISTS recursos_humanos.idx_employees_department;
DROP INDEX IF EXISTS recrutamento.idx_vagas_tenant_id;
DROP INDEX IF EXISTS recrutamento.idx_vagas_ativa;
DROP INDEX IF EXISTS recrutamento.idx_contactos_tenant_id;
DROP INDEX IF EXISTS recrutamento.idx_contactos_lido;
DROP INDEX IF EXISTS recrutamento.idx_candidaturas_vaga_id;
DROP INDEX IF EXISTS recrutamento.idx_candidaturas_tenant_id;
DROP INDEX IF EXISTS recrutamento.idx_candidaturas_estado;
DROP INDEX IF EXISTS recrutamento.idx_candidaturas_email;
DROP INDEX IF EXISTS recrutamento.idx_candidatura_notas_candidatura_id;
DROP INDEX IF EXISTS public.idx_notif_colab_user;
DROP INDEX IF EXISTS public.idx_notif_colab_nao_lida;
DROP INDEX IF EXISTS public.idx_comunicados_tenant;
DROP INDEX IF EXISTS public.idx_chat_part_user;
DROP INDEX IF EXISTS public.idx_chat_msg_conversa;
DROP INDEX IF EXISTS public.idx_chat_msg_autor;
DROP INDEX IF EXISTS public.idx_chat_conversas_tenant;
DROP INDEX IF EXISTS produtos.idx_warehouses_tenant_id;
DROP INDEX IF EXISTS produtos.idx_warehouses_tenant;
DROP INDEX IF EXISTS produtos.idx_products_tenant_id;
DROP INDEX IF EXISTS produtos.idx_products_tenant;
DROP INDEX IF EXISTS produtos.idx_product_variants_product_sku;
DROP INDEX IF EXISTS produtos.idx_product_variants_product_id;
DROP INDEX IF EXISTS produtos.idx_product_variants_product;
DROP INDEX IF EXISTS produtos.idx_product_units_tenant_id;
DROP INDEX IF EXISTS produtos.idx_product_units_tenant;
DROP INDEX IF EXISTS produtos.idx_product_tag_links_product_id;
DROP INDEX IF EXISTS produtos.idx_product_subcategories_category_id;
DROP INDEX IF EXISTS produtos.idx_product_prices_product_id;
DROP INDEX IF EXISTS produtos.idx_product_prices_product_active;
DROP INDEX IF EXISTS produtos.idx_product_prices_product;
DROP INDEX IF EXISTS produtos.idx_product_kits_product_id;
DROP INDEX IF EXISTS produtos.idx_product_kit_items_kit_id;
DROP INDEX IF EXISTS produtos.idx_product_images_product_id;
DROP INDEX IF EXISTS produtos.idx_product_discounts_product_id;
DROP INDEX IF EXISTS produtos.idx_product_discounts_product_active;
DROP INDEX IF EXISTS produtos.idx_product_categories_tenant_id;
DROP INDEX IF EXISTS produtos.idx_product_categories_tenant;
DROP INDEX IF EXISTS produtos.idx_product_categories_parent;
DROP INDEX IF EXISTS produtos.idx_product_brands_tenant_id;
DROP INDEX IF EXISTS produtos.idx_product_brands_tenant;
DROP INDEX IF EXISTS produtos.idx_product_barcodes_product_id;
DROP INDEX IF EXISTS produtos.idx_product_barcodes_product;
DROP INDEX IF EXISTS produtos.idx_product_attribute_values_product_id;
DROP INDEX IF EXISTS pos.idx_pos_terminals_tenant;
DROP INDEX IF EXISTS pos.idx_pos_sessions_tenant;
DROP INDEX IF EXISTS pos.idx_pos_sales_tenant;
DROP INDEX IF EXISTS pos.idx_pos_sales_session;
DROP INDEX IF EXISTS pos.idx_pos_sale_payments_sale;
DROP INDEX IF EXISTS pos.idx_pos_sale_items_sale;
DROP INDEX IF EXISTS pos.idx_pos_catalog_items_tenant;
DROP INDEX IF EXISTS notifications.idx_notification_templates_tenant;
DROP INDEX IF EXISTS notifications.idx_notification_messages_tenant_status;
DROP INDEX IF EXISTS notifications.idx_notification_channels_tenant;
DROP INDEX IF EXISTS multi_moeda.idx_tenant_currencies_tenant;
DROP INDEX IF EXISTS multi_moeda.idx_exchange_rates_tenant_date;
DROP INDEX IF EXISTS multi_moeda.idx_exchange_rates_pair;
DROP INDEX IF EXISTS logistica.idx_logistics_vehicles_tenant;
DROP INDEX IF EXISTS logistica.idx_logistics_tracking_shipment;
DROP INDEX IF EXISTS logistica.idx_logistics_tracking_events_tenant;
DROP INDEX IF EXISTS logistica.idx_logistics_shipments_tenant_status;
DROP INDEX IF EXISTS logistica.idx_logistics_routes_tenant;
DROP INDEX IF EXISTS logistica.idx_logistics_drivers_tenant;
DROP INDEX IF EXISTS impostos.uq_tax_returns_substituicao;
DROP INDEX IF EXISTS impostos.uq_tax_returns_original;
DROP INDEX IF EXISTS impostos.uq_tax_regime_principal;
DROP INDEX IF EXISTS impostos.idx_wtt_tenant;
DROP INDEX IF EXISTS impostos.idx_taxes_tenant;
DROP INDEX IF EXISTS impostos.idx_taxes_tax_group;
DROP INDEX IF EXISTS impostos.idx_tax_transactions_tenant;
DROP INDEX IF EXISTS impostos.idx_tax_transactions_tax;
DROP INDEX IF EXISTS impostos.idx_tax_transactions_ref;
DROP INDEX IF EXISTS impostos.idx_tax_transactions_period;
DROP INDEX IF EXISTS impostos.idx_tax_rules_tax;
DROP INDEX IF EXISTS impostos.idx_tax_returns_tenant;
DROP INDEX IF EXISTS impostos.idx_tax_return_lines_return;
DROP INDEX IF EXISTS impostos.idx_tax_return_lines_reference;
DROP INDEX IF EXISTS impostos.idx_tax_regimes_tenant;
DROP INDEX IF EXISTS impostos.idx_tax_exemptions_tenant;
DROP INDEX IF EXISTS impostos.idx_tax_exemptions_entity;
DROP INDEX IF EXISTS impostos.idx_tax_exemptions_active;
DROP INDEX IF EXISTS impostos.idx_tax_certificates_validade;
DROP INDEX IF EXISTS impostos.idx_tax_certificates_entity;
DROP INDEX IF EXISTS gestao_escolar.uq_school_student_class_year;
DROP INDEX IF EXISTS gestao_escolar.uq_school_attendance_entry;
DROP INDEX IF EXISTS gestao_escolar.idx_school_years_tenant;
DROP INDEX IF EXISTS gestao_escolar.idx_school_terms_year;
DROP INDEX IF EXISTS gestao_escolar.idx_school_students_tenant_estado;
DROP INDEX IF EXISTS gestao_escolar.idx_school_students_tenant;
DROP INDEX IF EXISTS gestao_escolar.idx_school_payments_fee;
DROP INDEX IF EXISTS gestao_escolar.idx_school_messages_tenant_status;
DROP INDEX IF EXISTS gestao_escolar.idx_school_loans_status;
DROP INDEX IF EXISTS gestao_escolar.idx_school_guardians_student;
DROP INDEX IF EXISTS gestao_escolar.idx_school_grades_student;
DROP INDEX IF EXISTS gestao_escolar.idx_school_fees_tenant;
DROP INDEX IF EXISTS gestao_escolar.idx_school_fees_filters;
DROP INDEX IF EXISTS gestao_escolar.idx_school_enrollments_tenant_year;
DROP INDEX IF EXISTS gestao_escolar.idx_school_enrollments_tenant;
DROP INDEX IF EXISTS gestao_escolar.idx_school_classes_tenant_year;
DROP INDEX IF EXISTS gestao_escolar.idx_school_classes_tenant;
DROP INDEX IF EXISTS gestao_escolar.idx_school_attendance_tenant;
DROP INDEX IF EXISTS gestao_escolar.idx_school_attendance_filters;
DROP INDEX IF EXISTS gestao_escolar.idx_school_assignments_class;
DROP INDEX IF EXISTS financeiro.idx_payments_tenant;
DROP INDEX IF EXISTS financeiro.idx_payments_referencia;
DROP INDEX IF EXISTS financeiro.idx_payments_data;
DROP INDEX IF EXISTS financeiro.idx_payment_methods_tenant;
DROP INDEX IF EXISTS financeiro.idx_financial_categories_tenant;
DROP INDEX IF EXISTS financeiro.idx_cashflow_tenant_data;
DROP INDEX IF EXISTS financeiro.idx_budgets_tenant;
DROP INDEX IF EXISTS financeiro.idx_ar_vencimento;
DROP INDEX IF EXISTS financeiro.idx_ar_tenant_status;
DROP INDEX IF EXISTS financeiro.idx_ar_customer;
DROP INDEX IF EXISTS financeiro.idx_ap_vencimento;
DROP INDEX IF EXISTS financeiro.idx_ap_tenant_status;
DROP INDEX IF EXISTS faturacao.idx_sales_returns_invoice;
DROP INDEX IF EXISTS faturacao.idx_sales_quotes_tenant;
DROP INDEX IF EXISTS faturacao.idx_sales_quotes_customer;
DROP INDEX IF EXISTS faturacao.idx_sales_orders_tenant;
DROP INDEX IF EXISTS faturacao.idx_sales_orders_quote;
DROP INDEX IF EXISTS faturacao.idx_sales_orders_customer;
DROP INDEX IF EXISTS faturacao.idx_sales_deliveries_order;
DROP INDEX IF EXISTS faturacao.idx_receipts_invoice;
DROP INDEX IF EXISTS faturacao.idx_invoices_tenant;
DROP INDEX IF EXISTS faturacao.idx_invoices_order;
DROP INDEX IF EXISTS faturacao.idx_invoices_due_date;
DROP INDEX IF EXISTS faturacao.idx_invoices_customer;
DROP INDEX IF EXISTS faturacao.idx_invoice_series_tenant;
DROP INDEX IF EXISTS faturacao.idx_invoice_receipts_invoice;
DROP INDEX IF EXISTS faturacao.idx_credit_notes_tenant;
DROP INDEX IF EXISTS faturacao.idx_credit_notes_invoice;
DROP INDEX IF EXISTS empresas.idx_company_users_company_id;
DROP INDEX IF EXISTS empresas.idx_company_settings_company_id;
DROP INDEX IF EXISTS empresas.idx_company_licenses_company_id;
DROP INDEX IF EXISTS empresas.idx_company_documents_company_id;
DROP INDEX IF EXISTS empresas.idx_company_contacts_company_id;
DROP INDEX IF EXISTS empresas.idx_company_branches_company_id;
DROP INDEX IF EXISTS empresas.idx_company_banks_company_id;
DROP INDEX IF EXISTS empresas.idx_company_addresses_company_id;
DROP INDEX IF EXISTS empresa.idx_company_users_user_id;
DROP INDEX IF EXISTS empresa.idx_company_users_company_id;
DROP INDEX IF EXISTS empresa.idx_company_settings_company_id;
DROP INDEX IF EXISTS empresa.idx_company_licenses_company_id;
DROP INDEX IF EXISTS empresa.idx_company_documents_company_id;
DROP INDEX IF EXISTS empresa.idx_company_contacts_company_id;
DROP INDEX IF EXISTS empresa.idx_company_branches_company_id;
DROP INDEX IF EXISTS empresa.idx_company_banks_company_id;
DROP INDEX IF EXISTS empresa.idx_company_addresses_company_id;
DROP INDEX IF EXISTS crm.idx_oportunidades_tenant_id;
DROP INDEX IF EXISTS crm.idx_oportunidades_responsavel;
DROP INDEX IF EXISTS crm.idx_oportunidades_lead_id;
DROP INDEX IF EXISTS crm.idx_oportunidades_estagio;
DROP INDEX IF EXISTS crm.idx_oportunidades_cliente_id;
DROP INDEX IF EXISTS crm.idx_leads_tenant_id;
DROP INDEX IF EXISTS crm.idx_leads_responsavel;
DROP INDEX IF EXISTS crm.idx_leads_estado;
DROP INDEX IF EXISTS crm.idx_leads_email;
DROP INDEX IF EXISTS crm.idx_crm_pipelines_tenant;
DROP INDEX IF EXISTS crm.idx_crm_pipeline_stages_pipeline;
DROP INDEX IF EXISTS crm.idx_crm_opportunities_tenant_estado;
DROP INDEX IF EXISTS crm.idx_crm_opportunities_stage;
DROP INDEX IF EXISTS crm.idx_crm_leads_tenant_estado;
DROP INDEX IF EXISTS crm.idx_crm_lead_sources_tenant;
DROP INDEX IF EXISTS crm.idx_crm_activities_tenant;
DROP INDEX IF EXISTS crm.idx_atividades_tipo;
DROP INDEX IF EXISTS crm.idx_atividades_tenant_id;
DROP INDEX IF EXISTS crm.idx_atividades_oportunidade_id;
DROP INDEX IF EXISTS crm.idx_atividades_lead_id;
DROP INDEX IF EXISTS crm.idx_atividades_data;
DROP INDEX IF EXISTS crm.idx_atividades_concluida;
DROP INDEX IF EXISTS contabilidade.uq_accounting_budgets_anual;
DROP INDEX IF EXISTS contabilidade.idx_period_closings_tenant;
DROP INDEX IF EXISTS contabilidade.idx_period_closings_status;
DROP INDEX IF EXISTS contabilidade.idx_period_closing_checks_closing;
DROP INDEX IF EXISTS contabilidade.idx_journal_entry_lines_entry;
DROP INDEX IF EXISTS contabilidade.idx_journal_entry_lines_account;
DROP INDEX IF EXISTS contabilidade.idx_journal_entries_tenant_date;
DROP INDEX IF EXISTS contabilidade.idx_journal_entries_status;
DROP INDEX IF EXISTS contabilidade.idx_journal_entries_fiscal_period;
DROP INDEX IF EXISTS contabilidade.idx_fixed_assets_tenant;
DROP INDEX IF EXISTS contabilidade.idx_fixed_assets_account;
DROP INDEX IF EXISTS contabilidade.idx_fiscal_periods_fiscal_year;
DROP INDEX IF EXISTS contabilidade.idx_depreciation_entries_tenant;
DROP INDEX IF EXISTS contabilidade.idx_depreciation_entries_period;
DROP INDEX IF EXISTS contabilidade.idx_depreciation_entries_journal;
DROP INDEX IF EXISTS contabilidade.idx_depreciation_entries_asset;
DROP INDEX IF EXISTS contabilidade.idx_chart_of_accounts_tenant;
DROP INDEX IF EXISTS contabilidade.idx_chart_of_accounts_account_type;
DROP INDEX IF EXISTS contabilidade.idx_accounting_reports_tenant;
DROP INDEX IF EXISTS contabilidade.idx_accounting_periods_tenant;
DROP INDEX IF EXISTS contabilidade.idx_accounting_journals_tenant;
DROP INDEX IF EXISTS contabilidade.idx_accounting_budgets_tenant;
DROP INDEX IF EXISTS contabilidade.idx_accounting_budgets_account;
DROP INDEX IF EXISTS compras.idx_suppliers_tenant;
DROP INDEX IF EXISTS compras.idx_supplier_groups_tenant;
DROP INDEX IF EXISTS compras.idx_purchase_returns_tenant_date;
DROP INDEX IF EXISTS compras.idx_purchase_return_items_return;
DROP INDEX IF EXISTS compras.idx_purchase_requests_tenant_status;
DROP INDEX IF EXISTS compras.idx_purchase_request_items_request;
DROP INDEX IF EXISTS compras.idx_purchase_payments_tenant_date;
DROP INDEX IF EXISTS compras.idx_purchase_payment_items_payment;
DROP INDEX IF EXISTS compras.idx_purchase_orders_tenant_status;
DROP INDEX IF EXISTS compras.idx_purchase_orders_supplier;
DROP INDEX IF EXISTS compras.idx_purchase_order_items_order;
DROP INDEX IF EXISTS compras.idx_purchase_invoices_tenant_status;
DROP INDEX IF EXISTS compras.idx_purchase_invoice_items_invoice;
DROP INDEX IF EXISTS compras.idx_goods_receipts_tenant_date;
DROP INDEX IF EXISTS compras.idx_goods_receipt_items_receipt;
DROP INDEX IF EXISTS clientes.idx_customers_tenant_id;
DROP INDEX IF EXISTS clientes.idx_customers_tenant_estado;
DROP INDEX IF EXISTS clientes.idx_customers_group_id;
DROP INDEX IF EXISTS clientes.idx_customer_tag_links_customer_id;
DROP INDEX IF EXISTS clientes.idx_customer_payments_tenant_pago_em;
DROP INDEX IF EXISTS clientes.idx_customer_payments_customer_id;
DROP INDEX IF EXISTS clientes.idx_customer_notes_customer_id;
DROP INDEX IF EXISTS clientes.idx_customer_history_customer_id;
DROP INDEX IF EXISTS clientes.idx_customer_history_customer_created;
DROP INDEX IF EXISTS clientes.idx_customer_groups_tenant_id;
DROP INDEX IF EXISTS clientes.idx_customer_documents_customer_id;
DROP INDEX IF EXISTS clientes.idx_customer_discounts_customer_id;
DROP INDEX IF EXISTS clientes.idx_customer_contacts_customer_id;
DROP INDEX IF EXISTS clientes.idx_customer_addresses_customer_id;
DROP INDEX IF EXISTS centros_custo.idx_cost_centers_tenant;
DROP INDEX IF EXISTS centros_custo.idx_cost_center_budgets_tenant;
DROP INDEX IF EXISTS centros_custo.idx_cost_center_allocations_tenant;
DROP INDEX IF EXISTS centros_custo.idx_cost_center_allocations_source;
DROP INDEX IF EXISTS autorizacao.idx_user_roles_user_id;
DROP INDEX IF EXISTS autorizacao.idx_user_roles_role_id;
DROP INDEX IF EXISTS autorizacao.idx_roles_tenant_id;
DROP INDEX IF EXISTS autorizacao.idx_role_permissions_role_id;
DROP INDEX IF EXISTS auth.idx_users_tenant_id;
DROP INDEX IF EXISTS auth.idx_sessions_user_id;
DROP INDEX IF EXISTS auth.idx_sessions_token_hash;
DROP INDEX IF EXISTS auth.idx_sessions_ativa;
DROP INDEX IF EXISTS auth.idx_permissoes_tipo_tipo;
DROP INDEX IF EXISTS auth.idx_permissoes_diretas_user_id;
DROP INDEX IF EXISTS auth.idx_permissoes_cargo_cargo_id;
DROP INDEX IF EXISTS auth.idx_password_resets_user_id;
DROP INDEX IF EXISTS auth.idx_login_history_tenant_id;
DROP INDEX IF EXISTS auth.idx_cargos_tenant_id;
DROP INDEX IF EXISTS auth.idx_api_keys_tenant_id;
DROP INDEX IF EXISTS auth.idx_api_keys_key_prefix;
DROP INDEX IF EXISTS auditoria.uq_audit_events_hash;
DROP INDEX IF EXISTS auditoria.idx_audit_logs_user_id;
DROP INDEX IF EXISTS auditoria.idx_audit_logs_tenant_id;
DROP INDEX IF EXISTS auditoria.idx_audit_logs_modulo;
DROP INDEX IF EXISTS auditoria.idx_audit_logs_created_at;
DROP INDEX IF EXISTS auditoria.idx_audit_events_tenant_service;
DROP INDEX IF EXISTS auditoria.idx_audit_events_tenant_entity;
DROP INDEX IF EXISTS auditoria.idx_audit_events_tenant_created;
DROP INDEX IF EXISTS assinaturas.idx_subscriptions_tenant_status;
DROP INDEX IF EXISTS assinaturas.idx_subscription_usage_tenant_periodo;
DROP INDEX IF EXISTS assinaturas.idx_subscription_plans_tenant;
DROP INDEX IF EXISTS assinaturas.idx_subscription_invoices_tenant_status;
ALTER TABLE IF EXISTS ONLY utilizadores.user_tokens DROP CONSTRAINT IF EXISTS user_tokens_pkey;
ALTER TABLE IF EXISTS ONLY utilizadores.user_settings DROP CONSTRAINT IF EXISTS user_settings_pkey;
ALTER TABLE IF EXISTS ONLY utilizadores.user_security_logs DROP CONSTRAINT IF EXISTS user_security_logs_pkey;
ALTER TABLE IF EXISTS ONLY utilizadores.user_preferences DROP CONSTRAINT IF EXISTS user_preferences_pkey;
ALTER TABLE IF EXISTS ONLY utilizadores.user_notifications DROP CONSTRAINT IF EXISTS user_notifications_pkey;
ALTER TABLE IF EXISTS ONLY utilizadores.user_devices DROP CONSTRAINT IF EXISTS user_devices_pkey;
ALTER TABLE IF EXISTS ONLY utilizadores.user_avatar DROP CONSTRAINT IF EXISTS user_avatar_pkey;
ALTER TABLE IF EXISTS ONLY utilizadores.user_activity DROP CONSTRAINT IF EXISTS user_activity_pkey;
ALTER TABLE IF EXISTS ONLY utilizadores.user_settings DROP CONSTRAINT IF EXISTS uq_user_settings;
ALTER TABLE IF EXISTS ONLY utilizadores.user_preferences DROP CONSTRAINT IF EXISTS uq_user_preferences;
ALTER TABLE IF EXISTS ONLY utilizadores.user_devices DROP CONSTRAINT IF EXISTS uq_user_devices;
ALTER TABLE IF EXISTS ONLY utilizadores.user_avatar DROP CONSTRAINT IF EXISTS uq_user_avatar;
ALTER TABLE IF EXISTS ONLY utilizadores.profiles DROP CONSTRAINT IF EXISTS uq_profiles_user;
ALTER TABLE IF EXISTS ONLY utilizadores.profiles DROP CONSTRAINT IF EXISTS profiles_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.reconciliations DROP CONSTRAINT IF EXISTS reconciliations_tenant_id_bank_account_id_periodo_inicio_pe_key;
ALTER TABLE IF EXISTS ONLY tesouraria.reconciliations DROP CONSTRAINT IF EXISTS reconciliations_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.reconciliacoes_bancarias DROP CONSTRAINT IF EXISTS reconciliacoes_bancarias_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.movimentos_financeiros DROP CONSTRAINT IF EXISTS movimentos_financeiros_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.movements DROP CONSTRAINT IF EXISTS movements_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.contas_bancarias DROP CONSTRAINT IF EXISTS contas_bancarias_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.cash_registers DROP CONSTRAINT IF EXISTS cash_registers_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY tesouraria.cash_registers DROP CONSTRAINT IF EXISTS cash_registers_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.caixas DROP CONSTRAINT IF EXISTS caixas_pkey;
ALTER TABLE IF EXISTS ONLY tesouraria.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY tesouraria.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_tenant_id_banco_numero_conta_key;
ALTER TABLE IF EXISTS ONLY tesouraria.bank_accounts DROP CONSTRAINT IF EXISTS bank_accounts_pkey;
ALTER TABLE IF EXISTS ONLY stock.warehouse_locations DROP CONSTRAINT IF EXISTS warehouse_locations_pkey;
ALTER TABLE IF EXISTS ONLY stock.warehouse_locations DROP CONSTRAINT IF EXISTS uq_warehouse_locations;
ALTER TABLE IF EXISTS ONLY stock.stock_transfers DROP CONSTRAINT IF EXISTS uq_stock_transfers;
ALTER TABLE IF EXISTS ONLY stock.stock_serial_numbers DROP CONSTRAINT IF EXISTS uq_stock_serial_numbers;
ALTER TABLE IF EXISTS ONLY stock.stock_items DROP CONSTRAINT IF EXISTS uq_stock_items;
ALTER TABLE IF EXISTS ONLY stock.stock_counts DROP CONSTRAINT IF EXISTS uq_stock_counts;
ALTER TABLE IF EXISTS ONLY stock.stock_batches DROP CONSTRAINT IF EXISTS uq_stock_batches;
ALTER TABLE IF EXISTS ONLY stock.stock_transfers DROP CONSTRAINT IF EXISTS stock_transfers_pkey;
ALTER TABLE IF EXISTS ONLY stock.stock_transfer_items DROP CONSTRAINT IF EXISTS stock_transfer_items_pkey;
ALTER TABLE IF EXISTS ONLY stock.stock_serial_numbers DROP CONSTRAINT IF EXISTS stock_serial_numbers_pkey;
ALTER TABLE IF EXISTS ONLY stock.stock_reservations DROP CONSTRAINT IF EXISTS stock_reservations_pkey;
ALTER TABLE IF EXISTS ONLY stock.stock_movements DROP CONSTRAINT IF EXISTS stock_movements_pkey;
ALTER TABLE IF EXISTS ONLY stock.stock_logs DROP CONSTRAINT IF EXISTS stock_logs_pkey;
ALTER TABLE IF EXISTS ONLY stock.stock_items DROP CONSTRAINT IF EXISTS stock_items_pkey;
ALTER TABLE IF EXISTS ONLY stock.stock_counts DROP CONSTRAINT IF EXISTS stock_counts_pkey;
ALTER TABLE IF EXISTS ONLY stock.stock_count_items DROP CONSTRAINT IF EXISTS stock_count_items_pkey;
ALTER TABLE IF EXISTS ONLY stock.stock_batches DROP CONSTRAINT IF EXISTS stock_batches_pkey;
ALTER TABLE IF EXISTS ONLY stock.stock_alerts DROP CONSTRAINT IF EXISTS stock_alerts_pkey;
ALTER TABLE IF EXISTS ONLY stock.stock_adjustments DROP CONSTRAINT IF EXISTS stock_adjustments_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.tenant_integrations DROP CONSTRAINT IF EXISTS uq_tenant_integrations;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.tenant_feature_flags DROP CONSTRAINT IF EXISTS uq_tenant_feature_flags;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.tenant_document_settings DROP CONSTRAINT IF EXISTS uq_tenant_document_settings;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.tenant_defaults DROP CONSTRAINT IF EXISTS uq_tenant_defaults;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.languages DROP CONSTRAINT IF EXISTS uq_languages;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.currencies DROP CONSTRAINT IF EXISTS uq_currencies;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.countries DROP CONSTRAINT IF EXISTS uq_countries;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.tenant_integrations DROP CONSTRAINT IF EXISTS tenant_integrations_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.tenant_feature_flags DROP CONSTRAINT IF EXISTS tenant_feature_flags_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.tenant_document_settings DROP CONSTRAINT IF EXISTS tenant_document_settings_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.tenant_defaults DROP CONSTRAINT IF EXISTS tenant_defaults_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.tenant_branding DROP CONSTRAINT IF EXISTS tenant_branding_tenant_id_key;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.tenant_branding DROP CONSTRAINT IF EXISTS tenant_branding_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.system_logs DROP CONSTRAINT IF EXISTS system_logs_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.sms_templates DROP CONSTRAINT IF EXISTS sms_templates_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.settings DROP CONSTRAINT IF EXISTS settings_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.languages DROP CONSTRAINT IF EXISTS languages_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.integrations DROP CONSTRAINT IF EXISTS integrations_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.exchange_rates DROP CONSTRAINT IF EXISTS exchange_rates_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.email_templates DROP CONSTRAINT IF EXISTS email_templates_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.currencies DROP CONSTRAINT IF EXISTS currencies_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.countries DROP CONSTRAINT IF EXISTS countries_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.cities DROP CONSTRAINT IF EXISTS cities_pkey;
ALTER TABLE IF EXISTS ONLY sistema_configuracao.api_logs DROP CONSTRAINT IF EXISTS api_logs_pkey;
ALTER TABLE IF EXISTS ONLY seguranca.security_policies DROP CONSTRAINT IF EXISTS uq_security_policies;
ALTER TABLE IF EXISTS ONLY seguranca.security_mfa_enrollments DROP CONSTRAINT IF EXISTS uq_security_mfa_user_method;
ALTER TABLE IF EXISTS ONLY seguranca.security_ip_allowlist DROP CONSTRAINT IF EXISTS uq_security_ip_allowlist;
ALTER TABLE IF EXISTS ONLY seguranca.security_policies DROP CONSTRAINT IF EXISTS security_policies_pkey;
ALTER TABLE IF EXISTS ONLY seguranca.security_mfa_enrollments DROP CONSTRAINT IF EXISTS security_mfa_enrollments_pkey;
ALTER TABLE IF EXISTS ONLY seguranca.security_ip_allowlist DROP CONSTRAINT IF EXISTS security_ip_allowlist_pkey;
ALTER TABLE IF EXISTS ONLY rh.unidades_organizacionais DROP CONSTRAINT IF EXISTS uq_unidades_organizacionais_tenant_codigo;
ALTER TABLE IF EXISTS ONLY rh.tipos_ausencia DROP CONSTRAINT IF EXISTS uq_tipos_ausencia_tenant_codigo;
ALTER TABLE IF EXISTS ONLY rh.saldos_ausencia DROP CONSTRAINT IF EXISTS uq_saldos_ausencia;
ALTER TABLE IF EXISTS ONLY rh.recibos_vencimento DROP CONSTRAINT IF EXISTS uq_recibos_vencimento_folha_funcionario;
ALTER TABLE IF EXISTS ONLY rh.presencas DROP CONSTRAINT IF EXISTS uq_presencas_funcionario_data;
ALTER TABLE IF EXISTS ONLY rh.periodos_avaliacao DROP CONSTRAINT IF EXISTS uq_periodos_avaliacao_tenant_nome;
ALTER TABLE IF EXISTS ONLY rh.horarios_trabalho DROP CONSTRAINT IF EXISTS uq_horarios_trabalho_tenant_codigo;
ALTER TABLE IF EXISTS ONLY rh.funcionarios DROP CONSTRAINT IF EXISTS uq_funcionarios_user_id;
ALTER TABLE IF EXISTS ONLY rh.funcionario_componentes_salariais DROP CONSTRAINT IF EXISTS uq_funcionario_componente;
ALTER TABLE IF EXISTS ONLY rh.funcionario_beneficios DROP CONSTRAINT IF EXISTS uq_funcionario_beneficio;
ALTER TABLE IF EXISTS ONLY rh.formacoes DROP CONSTRAINT IF EXISTS uq_formacoes_tenant_codigo;
ALTER TABLE IF EXISTS ONLY rh.folhas_pagamento DROP CONSTRAINT IF EXISTS uq_folhas_pagamento_tenant_ano_mes;
ALTER TABLE IF EXISTS ONLY rh.criterios_avaliacao DROP CONSTRAINT IF EXISTS uq_criterios_avaliacao_tenant_codigo;
ALTER TABLE IF EXISTS ONLY rh.componentes_salariais DROP CONSTRAINT IF EXISTS uq_componentes_salariais_tenant_codigo;
ALTER TABLE IF EXISTS ONLY rh.cargos DROP CONSTRAINT IF EXISTS uq_cargos_tenant_codigo;
ALTER TABLE IF EXISTS ONLY rh.beneficios DROP CONSTRAINT IF EXISTS uq_beneficios_tenant_codigo;
ALTER TABLE IF EXISTS ONLY rh.avaliacao_criterios DROP CONSTRAINT IF EXISTS uq_avaliacao_criterios;
ALTER TABLE IF EXISTS ONLY rh.tipos_ausencia DROP CONSTRAINT IF EXISTS tipos_ausencia_pkey;
ALTER TABLE IF EXISTS ONLY rh.saldos_ausencia DROP CONSTRAINT IF EXISTS saldos_ausencia_pkey;
ALTER TABLE IF EXISTS ONLY rh.recibos_vencimento DROP CONSTRAINT IF EXISTS recibos_vencimento_pkey;
ALTER TABLE IF EXISTS ONLY rh.recibo_vencimento_itens DROP CONSTRAINT IF EXISTS recibo_vencimento_itens_pkey;
ALTER TABLE IF EXISTS ONLY rh.processos_disciplinares DROP CONSTRAINT IF EXISTS processos_disciplinares_pkey;
ALTER TABLE IF EXISTS ONLY rh.presencas DROP CONSTRAINT IF EXISTS presencas_pkey;
ALTER TABLE IF EXISTS ONLY rh.periodos_avaliacao DROP CONSTRAINT IF EXISTS periodos_avaliacao_pkey;
ALTER TABLE IF EXISTS ONLY rh.justificacoes DROP CONSTRAINT IF EXISTS justificacoes_pkey;
ALTER TABLE IF EXISTS ONLY rh.horarios_trabalho DROP CONSTRAINT IF EXISTS horarios_trabalho_pkey;
ALTER TABLE IF EXISTS ONLY rh.historico_salarial DROP CONSTRAINT IF EXISTS historico_salarial_pkey;
ALTER TABLE IF EXISTS ONLY rh.funcionarios DROP CONSTRAINT IF EXISTS funcionarios_pkey;
ALTER TABLE IF EXISTS ONLY rh.funcionario_formacoes DROP CONSTRAINT IF EXISTS funcionario_formacoes_pkey;
ALTER TABLE IF EXISTS ONLY rh.funcionario_componentes_salariais DROP CONSTRAINT IF EXISTS funcionario_componentes_salariais_pkey;
ALTER TABLE IF EXISTS ONLY rh.funcionario_beneficios DROP CONSTRAINT IF EXISTS funcionario_beneficios_pkey;
ALTER TABLE IF EXISTS ONLY rh.formacoes DROP CONSTRAINT IF EXISTS formacoes_pkey;
ALTER TABLE IF EXISTS ONLY rh.folhas_pagamento DROP CONSTRAINT IF EXISTS folhas_pagamento_pkey;
ALTER TABLE IF EXISTS ONLY rh.documentos_funcionario DROP CONSTRAINT IF EXISTS documentos_funcionario_pkey;
ALTER TABLE IF EXISTS ONLY rh.unidades_organizacionais DROP CONSTRAINT IF EXISTS departamentos_pkey;
ALTER TABLE IF EXISTS ONLY rh.criterios_avaliacao DROP CONSTRAINT IF EXISTS criterios_avaliacao_pkey;
ALTER TABLE IF EXISTS ONLY rh.contratos DROP CONSTRAINT IF EXISTS contratos_pkey;
ALTER TABLE IF EXISTS ONLY rh.contactos_emergencia DROP CONSTRAINT IF EXISTS contactos_emergencia_pkey;
ALTER TABLE IF EXISTS ONLY rh.componentes_salariais DROP CONSTRAINT IF EXISTS componentes_salariais_pkey;
ALTER TABLE IF EXISTS ONLY rh.cargos DROP CONSTRAINT IF EXISTS cargos_pkey;
ALTER TABLE IF EXISTS ONLY rh.beneficios DROP CONSTRAINT IF EXISTS beneficios_pkey;
ALTER TABLE IF EXISTS ONLY rh.avaliacoes DROP CONSTRAINT IF EXISTS avaliacoes_pkey;
ALTER TABLE IF EXISTS ONLY rh.avaliacao_criterios DROP CONSTRAINT IF EXISTS avaliacao_criterios_pkey;
ALTER TABLE IF EXISTS ONLY rh.ausencias DROP CONSTRAINT IF EXISTS ausencias_pkey;
ALTER TABLE IF EXISTS ONLY recursos_humanos.payroll_runs DROP CONSTRAINT IF EXISTS uq_payroll_runs;
ALTER TABLE IF EXISTS ONLY recursos_humanos.payroll_run_lines DROP CONSTRAINT IF EXISTS uq_payroll_run_employee;
ALTER TABLE IF EXISTS ONLY recursos_humanos.payroll_periods DROP CONSTRAINT IF EXISTS uq_payroll_periods;
ALTER TABLE IF EXISTS ONLY recursos_humanos.hr_departments DROP CONSTRAINT IF EXISTS uq_hr_departments;
ALTER TABLE IF EXISTS ONLY recursos_humanos.employees DROP CONSTRAINT IF EXISTS uq_employees_tenant_nuit;
ALTER TABLE IF EXISTS ONLY recursos_humanos.employees DROP CONSTRAINT IF EXISTS uq_employees_tenant_codigo;
ALTER TABLE IF EXISTS ONLY recursos_humanos.payroll_runs DROP CONSTRAINT IF EXISTS payroll_runs_pkey;
ALTER TABLE IF EXISTS ONLY recursos_humanos.payroll_run_lines DROP CONSTRAINT IF EXISTS payroll_run_lines_pkey;
ALTER TABLE IF EXISTS ONLY recursos_humanos.payroll_periods DROP CONSTRAINT IF EXISTS payroll_periods_pkey;
ALTER TABLE IF EXISTS ONLY recursos_humanos.hr_departments DROP CONSTRAINT IF EXISTS hr_departments_pkey;
ALTER TABLE IF EXISTS ONLY recursos_humanos.employees DROP CONSTRAINT IF EXISTS employees_pkey;
ALTER TABLE IF EXISTS ONLY recursos_humanos.employee_bank_accounts DROP CONSTRAINT IF EXISTS employee_bank_accounts_pkey;
ALTER TABLE IF EXISTS ONLY recrutamento.vagas DROP CONSTRAINT IF EXISTS vagas_pkey;
ALTER TABLE IF EXISTS ONLY recrutamento.contactos DROP CONSTRAINT IF EXISTS contactos_pkey;
ALTER TABLE IF EXISTS ONLY recrutamento.candidaturas DROP CONSTRAINT IF EXISTS candidaturas_pkey;
ALTER TABLE IF EXISTS ONLY recrutamento.candidatura_notas DROP CONSTRAINT IF EXISTS candidatura_notas_pkey;
ALTER TABLE IF EXISTS ONLY public.notif_colaborador DROP CONSTRAINT IF EXISTS notif_colaborador_pkey;
ALTER TABLE IF EXISTS ONLY public.comunicados DROP CONSTRAINT IF EXISTS comunicados_pkey;
ALTER TABLE IF EXISTS ONLY public.comunicados_lidos DROP CONSTRAINT IF EXISTS comunicados_lidos_pkey;
ALTER TABLE IF EXISTS ONLY public.chat_participantes DROP CONSTRAINT IF EXISTS chat_participantes_pkey;
ALTER TABLE IF EXISTS ONLY public.chat_mensagens DROP CONSTRAINT IF EXISTS chat_mensagens_pkey;
ALTER TABLE IF EXISTS ONLY public.chat_conversas DROP CONSTRAINT IF EXISTS chat_conversas_pkey;
ALTER TABLE IF EXISTS ONLY produtos.warehouses DROP CONSTRAINT IF EXISTS warehouses_pkey;
ALTER TABLE IF EXISTS ONLY produtos.warehouses DROP CONSTRAINT IF EXISTS uq_warehouses;
ALTER TABLE IF EXISTS ONLY produtos.products DROP CONSTRAINT IF EXISTS uq_products;
ALTER TABLE IF EXISTS ONLY produtos.product_variants DROP CONSTRAINT IF EXISTS uq_product_variants;
ALTER TABLE IF EXISTS ONLY produtos.product_units DROP CONSTRAINT IF EXISTS uq_product_units;
ALTER TABLE IF EXISTS ONLY produtos.product_tags DROP CONSTRAINT IF EXISTS uq_product_tags;
ALTER TABLE IF EXISTS ONLY produtos.product_tag_links DROP CONSTRAINT IF EXISTS uq_product_tag_links;
ALTER TABLE IF EXISTS ONLY produtos.product_subcategories DROP CONSTRAINT IF EXISTS uq_product_subcategories;
ALTER TABLE IF EXISTS ONLY produtos.product_kits DROP CONSTRAINT IF EXISTS uq_product_kits;
ALTER TABLE IF EXISTS ONLY produtos.product_categories DROP CONSTRAINT IF EXISTS uq_product_categories;
ALTER TABLE IF EXISTS ONLY produtos.product_brands DROP CONSTRAINT IF EXISTS uq_product_brands;
ALTER TABLE IF EXISTS ONLY produtos.product_barcodes DROP CONSTRAINT IF EXISTS uq_product_barcodes;
ALTER TABLE IF EXISTS ONLY produtos.product_attributes DROP CONSTRAINT IF EXISTS uq_product_attributes;
ALTER TABLE IF EXISTS ONLY produtos.products DROP CONSTRAINT IF EXISTS products_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_variants DROP CONSTRAINT IF EXISTS product_variants_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_units DROP CONSTRAINT IF EXISTS product_units_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_tags DROP CONSTRAINT IF EXISTS product_tags_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_tag_links DROP CONSTRAINT IF EXISTS product_tag_links_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_subcategories DROP CONSTRAINT IF EXISTS product_subcategories_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_prices DROP CONSTRAINT IF EXISTS product_prices_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_kits DROP CONSTRAINT IF EXISTS product_kits_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_kit_items DROP CONSTRAINT IF EXISTS product_kit_items_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_images DROP CONSTRAINT IF EXISTS product_images_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_discounts DROP CONSTRAINT IF EXISTS product_discounts_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_categories DROP CONSTRAINT IF EXISTS product_categories_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_brands DROP CONSTRAINT IF EXISTS product_brands_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_barcodes DROP CONSTRAINT IF EXISTS product_barcodes_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_attributes DROP CONSTRAINT IF EXISTS product_attributes_pkey;
ALTER TABLE IF EXISTS ONLY produtos.product_attribute_values DROP CONSTRAINT IF EXISTS product_attribute_values_pkey;
ALTER TABLE IF EXISTS ONLY pos.pos_terminals DROP CONSTRAINT IF EXISTS uq_pos_terminals;
ALTER TABLE IF EXISTS ONLY pos.pos_sales DROP CONSTRAINT IF EXISTS uq_pos_sales;
ALTER TABLE IF EXISTS ONLY pos.pos_catalog_items DROP CONSTRAINT IF EXISTS uq_pos_catalog_items;
ALTER TABLE IF EXISTS ONLY pos.pos_terminals DROP CONSTRAINT IF EXISTS pos_terminals_pkey;
ALTER TABLE IF EXISTS ONLY pos.pos_sessions DROP CONSTRAINT IF EXISTS pos_sessions_pkey;
ALTER TABLE IF EXISTS ONLY pos.pos_sales DROP CONSTRAINT IF EXISTS pos_sales_pkey;
ALTER TABLE IF EXISTS ONLY pos.pos_sale_payments DROP CONSTRAINT IF EXISTS pos_sale_payments_pkey;
ALTER TABLE IF EXISTS ONLY pos.pos_sale_items DROP CONSTRAINT IF EXISTS pos_sale_items_pkey;
ALTER TABLE IF EXISTS ONLY pos.pos_catalog_items DROP CONSTRAINT IF EXISTS pos_catalog_items_pkey;
ALTER TABLE IF EXISTS ONLY notifications.notification_templates DROP CONSTRAINT IF EXISTS uq_notification_templates;
ALTER TABLE IF EXISTS ONLY notifications.notification_channels DROP CONSTRAINT IF EXISTS uq_notification_channels;
ALTER TABLE IF EXISTS ONLY notifications.notification_templates DROP CONSTRAINT IF EXISTS notification_templates_pkey;
ALTER TABLE IF EXISTS ONLY notifications.notification_messages DROP CONSTRAINT IF EXISTS notification_messages_pkey;
ALTER TABLE IF EXISTS ONLY notifications.notification_channels DROP CONSTRAINT IF EXISTS notification_channels_pkey;
ALTER TABLE IF EXISTS ONLY multi_moeda.tenant_currencies DROP CONSTRAINT IF EXISTS uq_tenant_currencies;
ALTER TABLE IF EXISTS ONLY multi_moeda.exchange_rates DROP CONSTRAINT IF EXISTS uq_exchange_rates;
ALTER TABLE IF EXISTS ONLY multi_moeda.tenant_currencies DROP CONSTRAINT IF EXISTS tenant_currencies_pkey;
ALTER TABLE IF EXISTS ONLY multi_moeda.exchange_rates DROP CONSTRAINT IF EXISTS exchange_rates_pkey;
ALTER TABLE IF EXISTS ONLY multi_moeda.currencies DROP CONSTRAINT IF EXISTS currencies_pkey;
ALTER TABLE IF EXISTS ONLY multi_moeda.currencies DROP CONSTRAINT IF EXISTS currencies_code_key;
ALTER TABLE IF EXISTS ONLY logistica.logistics_vehicles DROP CONSTRAINT IF EXISTS uq_logistics_vehicles_matricula;
ALTER TABLE IF EXISTS ONLY logistica.logistics_vehicles DROP CONSTRAINT IF EXISTS uq_logistics_vehicles_codigo;
ALTER TABLE IF EXISTS ONLY logistica.logistics_shipments DROP CONSTRAINT IF EXISTS uq_logistics_shipments;
ALTER TABLE IF EXISTS ONLY logistica.logistics_routes DROP CONSTRAINT IF EXISTS uq_logistics_routes;
ALTER TABLE IF EXISTS ONLY logistica.logistics_drivers DROP CONSTRAINT IF EXISTS uq_logistics_drivers;
ALTER TABLE IF EXISTS ONLY logistica.shipments DROP CONSTRAINT IF EXISTS shipments_tenant_id_numero_key;
ALTER TABLE IF EXISTS ONLY logistica.shipments DROP CONSTRAINT IF EXISTS shipments_pkey;
ALTER TABLE IF EXISTS ONLY logistica.shipment_items DROP CONSTRAINT IF EXISTS shipment_items_pkey;
ALTER TABLE IF EXISTS ONLY logistica.logistics_vehicles DROP CONSTRAINT IF EXISTS logistics_vehicles_pkey;
ALTER TABLE IF EXISTS ONLY logistica.logistics_tracking_events DROP CONSTRAINT IF EXISTS logistics_tracking_events_pkey;
ALTER TABLE IF EXISTS ONLY logistica.logistics_shipments DROP CONSTRAINT IF EXISTS logistics_shipments_pkey;
ALTER TABLE IF EXISTS ONLY logistica.logistics_routes DROP CONSTRAINT IF EXISTS logistics_routes_pkey;
ALTER TABLE IF EXISTS ONLY logistica.logistics_drivers DROP CONSTRAINT IF EXISTS logistics_drivers_pkey;
ALTER TABLE IF EXISTS ONLY logistica.delivery_vehicles DROP CONSTRAINT IF EXISTS delivery_vehicles_tenant_id_matricula_key;
ALTER TABLE IF EXISTS ONLY logistica.delivery_vehicles DROP CONSTRAINT IF EXISTS delivery_vehicles_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY logistica.delivery_vehicles DROP CONSTRAINT IF EXISTS delivery_vehicles_pkey;
ALTER TABLE IF EXISTS ONLY logistica.delivery_tracking DROP CONSTRAINT IF EXISTS delivery_tracking_pkey;
ALTER TABLE IF EXISTS ONLY logistica.delivery_statuses DROP CONSTRAINT IF EXISTS delivery_statuses_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY logistica.delivery_statuses DROP CONSTRAINT IF EXISTS delivery_statuses_pkey;
ALTER TABLE IF EXISTS ONLY logistica.delivery_routes DROP CONSTRAINT IF EXISTS delivery_routes_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY logistica.delivery_routes DROP CONSTRAINT IF EXISTS delivery_routes_pkey;
ALTER TABLE IF EXISTS ONLY logistica.delivery_drivers DROP CONSTRAINT IF EXISTS delivery_drivers_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY logistica.delivery_drivers DROP CONSTRAINT IF EXISTS delivery_drivers_pkey;
ALTER TABLE IF EXISTS ONLY impostos.withholding_taxes DROP CONSTRAINT IF EXISTS withholding_taxes_pkey;
ALTER TABLE IF EXISTS ONLY impostos.withholding_tax_transactions DROP CONSTRAINT IF EXISTS withholding_tax_transactions_pkey;
ALTER TABLE IF EXISTS ONLY impostos.withholding_taxes DROP CONSTRAINT IF EXISTS uq_withholding_taxes;
ALTER TABLE IF EXISTS ONLY impostos.taxes DROP CONSTRAINT IF EXISTS uq_taxes;
ALTER TABLE IF EXISTS ONLY impostos.tax_regimes DROP CONSTRAINT IF EXISTS uq_tax_regimes;
ALTER TABLE IF EXISTS ONLY impostos.tax_groups DROP CONSTRAINT IF EXISTS uq_tax_groups;
ALTER TABLE IF EXISTS ONLY impostos.tax_certificates DROP CONSTRAINT IF EXISTS uq_tax_certificates;
ALTER TABLE IF EXISTS ONLY impostos.taxes DROP CONSTRAINT IF EXISTS taxes_pkey;
ALTER TABLE IF EXISTS ONLY impostos.tax_transactions DROP CONSTRAINT IF EXISTS tax_transactions_pkey;
ALTER TABLE IF EXISTS ONLY impostos.tax_rules DROP CONSTRAINT IF EXISTS tax_rules_pkey;
ALTER TABLE IF EXISTS ONLY impostos.tax_returns DROP CONSTRAINT IF EXISTS tax_returns_pkey;
ALTER TABLE IF EXISTS ONLY impostos.tax_return_lines DROP CONSTRAINT IF EXISTS tax_return_lines_pkey;
ALTER TABLE IF EXISTS ONLY impostos.tax_regimes DROP CONSTRAINT IF EXISTS tax_regimes_pkey;
ALTER TABLE IF EXISTS ONLY impostos.tax_groups DROP CONSTRAINT IF EXISTS tax_groups_pkey;
ALTER TABLE IF EXISTS ONLY impostos.tax_exemptions DROP CONSTRAINT IF EXISTS tax_exemptions_pkey;
ALTER TABLE IF EXISTS ONLY impostos.tax_certificates DROP CONSTRAINT IF EXISTS tax_certificates_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_students DROP CONSTRAINT IF EXISTS uq_school_students;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_fees DROP CONSTRAINT IF EXISTS uq_school_fees;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_enrollments DROP CONSTRAINT IF EXISTS uq_school_enrollments;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_classes DROP CONSTRAINT IF EXISTS uq_school_classes;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_years DROP CONSTRAINT IF EXISTS school_years_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_years DROP CONSTRAINT IF EXISTS school_years_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_terms DROP CONSTRAINT IF EXISTS school_terms_tenant_id_school_year_id_codigo_key;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_terms DROP CONSTRAINT IF EXISTS school_terms_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_teacher_roles DROP CONSTRAINT IF EXISTS school_teacher_roles_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_teacher_assignments DROP CONSTRAINT IF EXISTS school_teacher_assignments_tenant_id_class_id_subject_id_te_key;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_teacher_assignments DROP CONSTRAINT IF EXISTS school_teacher_assignments_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_subjects DROP CONSTRAINT IF EXISTS school_subjects_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_subjects DROP CONSTRAINT IF EXISTS school_subjects_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_students DROP CONSTRAINT IF EXISTS school_students_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_student_roles DROP CONSTRAINT IF EXISTS school_student_roles_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_payments DROP CONSTRAINT IF EXISTS school_payments_tenant_id_external_id_key;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_payments DROP CONSTRAINT IF EXISTS school_payments_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_messages DROP CONSTRAINT IF EXISTS school_messages_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_library_loans DROP CONSTRAINT IF EXISTS school_library_loans_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_guardians DROP CONSTRAINT IF EXISTS school_guardians_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_grades DROP CONSTRAINT IF EXISTS school_grades_tenant_id_grade_item_id_student_id_key;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_grades DROP CONSTRAINT IF EXISTS school_grades_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_grade_items DROP CONSTRAINT IF EXISTS school_grade_items_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_fees DROP CONSTRAINT IF EXISTS school_fees_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_fee_plans DROP CONSTRAINT IF EXISTS school_fee_plans_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_fee_plans DROP CONSTRAINT IF EXISTS school_fee_plans_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_enrollments DROP CONSTRAINT IF EXISTS school_enrollments_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_classes DROP CONSTRAINT IF EXISTS school_classes_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_books DROP CONSTRAINT IF EXISTS school_books_tenant_id_codigo_key;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_books DROP CONSTRAINT IF EXISTS school_books_pkey;
ALTER TABLE IF EXISTS ONLY gestao_escolar.school_attendance DROP CONSTRAINT IF EXISTS school_attendance_pkey;
ALTER TABLE IF EXISTS ONLY financeiro.payments DROP CONSTRAINT IF EXISTS uq_payments;
ALTER TABLE IF EXISTS ONLY financeiro.payment_methods DROP CONSTRAINT IF EXISTS uq_payment_methods;
ALTER TABLE IF EXISTS ONLY financeiro.financial_budgets DROP CONSTRAINT IF EXISTS uq_financial_budgets;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_receivable_payments DROP CONSTRAINT IF EXISTS uq_ar_payments;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_payable_payments DROP CONSTRAINT IF EXISTS uq_ap_payments;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_receivable DROP CONSTRAINT IF EXISTS uq_accounts_receivable;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_payable DROP CONSTRAINT IF EXISTS uq_accounts_payable;
ALTER TABLE IF EXISTS ONLY financeiro.payments DROP CONSTRAINT IF EXISTS payments_pkey;
ALTER TABLE IF EXISTS ONLY financeiro.payment_methods DROP CONSTRAINT IF EXISTS payment_methods_pkey;
ALTER TABLE IF EXISTS ONLY financeiro.financial_categories DROP CONSTRAINT IF EXISTS financial_categories_pkey;
ALTER TABLE IF EXISTS ONLY financeiro.financial_budgets DROP CONSTRAINT IF EXISTS financial_budgets_pkey;
ALTER TABLE IF EXISTS ONLY financeiro.cash_flow_entries DROP CONSTRAINT IF EXISTS cash_flow_entries_pkey;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_receivable DROP CONSTRAINT IF EXISTS accounts_receivable_pkey;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_receivable_payments DROP CONSTRAINT IF EXISTS accounts_receivable_payments_pkey;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_payable DROP CONSTRAINT IF EXISTS accounts_payable_pkey;
ALTER TABLE IF EXISTS ONLY financeiro.accounts_payable_payments DROP CONSTRAINT IF EXISTS accounts_payable_payments_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.sales_returns DROP CONSTRAINT IF EXISTS uq_sales_returns;
ALTER TABLE IF EXISTS ONLY faturacao.sales_quotes DROP CONSTRAINT IF EXISTS uq_sales_quotes;
ALTER TABLE IF EXISTS ONLY faturacao.sales_orders DROP CONSTRAINT IF EXISTS uq_sales_orders;
ALTER TABLE IF EXISTS ONLY faturacao.sales_deliveries DROP CONSTRAINT IF EXISTS uq_sales_deliveries;
ALTER TABLE IF EXISTS ONLY faturacao.invoices DROP CONSTRAINT IF EXISTS uq_invoices;
ALTER TABLE IF EXISTS ONLY faturacao.invoice_series DROP CONSTRAINT IF EXISTS uq_invoice_series;
ALTER TABLE IF EXISTS ONLY faturacao.invoice_receipts DROP CONSTRAINT IF EXISTS uq_invoice_receipts;
ALTER TABLE IF EXISTS ONLY faturacao.credit_notes DROP CONSTRAINT IF EXISTS uq_credit_notes;
ALTER TABLE IF EXISTS ONLY faturacao.sales_returns DROP CONSTRAINT IF EXISTS sales_returns_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.sales_return_items DROP CONSTRAINT IF EXISTS sales_return_items_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.sales_quotes DROP CONSTRAINT IF EXISTS sales_quotes_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.sales_quote_items DROP CONSTRAINT IF EXISTS sales_quote_items_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.sales_orders DROP CONSTRAINT IF EXISTS sales_orders_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.sales_order_items DROP CONSTRAINT IF EXISTS sales_order_items_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.sales_delivery_items DROP CONSTRAINT IF EXISTS sales_delivery_items_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.sales_deliveries DROP CONSTRAINT IF EXISTS sales_deliveries_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.invoices DROP CONSTRAINT IF EXISTS invoices_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.invoice_taxes DROP CONSTRAINT IF EXISTS invoice_taxes_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.invoice_series DROP CONSTRAINT IF EXISTS invoice_series_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.invoice_receipts DROP CONSTRAINT IF EXISTS invoice_receipts_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.invoice_items DROP CONSTRAINT IF EXISTS invoice_items_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.invoice_discounts DROP CONSTRAINT IF EXISTS invoice_discounts_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.credit_notes DROP CONSTRAINT IF EXISTS credit_notes_pkey;
ALTER TABLE IF EXISTS ONLY faturacao.credit_note_items DROP CONSTRAINT IF EXISTS credit_note_items_pkey;
ALTER TABLE IF EXISTS ONLY empresas.company_users DROP CONSTRAINT IF EXISTS uq_company_users;
ALTER TABLE IF EXISTS ONLY empresas.company_tax_info DROP CONSTRAINT IF EXISTS uq_company_tax_info_nuit;
ALTER TABLE IF EXISTS ONLY empresas.company_tax_info DROP CONSTRAINT IF EXISTS uq_company_tax_info_company;
ALTER TABLE IF EXISTS ONLY empresas.company_settings DROP CONSTRAINT IF EXISTS uq_company_settings;
ALTER TABLE IF EXISTS ONLY empresas.company_branches DROP CONSTRAINT IF EXISTS uq_company_branches;
ALTER TABLE IF EXISTS ONLY empresas.companies DROP CONSTRAINT IF EXISTS uq_companies_codigo;
ALTER TABLE IF EXISTS ONLY empresas.company_users DROP CONSTRAINT IF EXISTS company_users_pkey;
ALTER TABLE IF EXISTS ONLY empresas.company_tax_info DROP CONSTRAINT IF EXISTS company_tax_info_pkey;
ALTER TABLE IF EXISTS ONLY empresas.company_settings DROP CONSTRAINT IF EXISTS company_settings_pkey;
ALTER TABLE IF EXISTS ONLY empresas.company_licenses DROP CONSTRAINT IF EXISTS company_licenses_pkey;
ALTER TABLE IF EXISTS ONLY empresas.company_documents DROP CONSTRAINT IF EXISTS company_documents_pkey;
ALTER TABLE IF EXISTS ONLY empresas.company_contacts DROP CONSTRAINT IF EXISTS company_contacts_pkey;
ALTER TABLE IF EXISTS ONLY empresas.company_branches DROP CONSTRAINT IF EXISTS company_branches_pkey;
ALTER TABLE IF EXISTS ONLY empresas.company_banks DROP CONSTRAINT IF EXISTS company_banks_pkey;
ALTER TABLE IF EXISTS ONLY empresas.company_addresses DROP CONSTRAINT IF EXISTS company_addresses_pkey;
ALTER TABLE IF EXISTS ONLY empresas.companies DROP CONSTRAINT IF EXISTS companies_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_users DROP CONSTRAINT IF EXISTS uq_company_users;
ALTER TABLE IF EXISTS ONLY empresa.company_tax_info DROP CONSTRAINT IF EXISTS uq_company_tax_info_nuit;
ALTER TABLE IF EXISTS ONLY empresa.company_tax_info DROP CONSTRAINT IF EXISTS uq_company_tax_info_company;
ALTER TABLE IF EXISTS ONLY empresa.company_settings DROP CONSTRAINT IF EXISTS uq_company_settings;
ALTER TABLE IF EXISTS ONLY empresa.company_branches DROP CONSTRAINT IF EXISTS uq_company_branches;
ALTER TABLE IF EXISTS ONLY empresa.companies DROP CONSTRAINT IF EXISTS uq_companies_codigo;
ALTER TABLE IF EXISTS ONLY empresa.company_users DROP CONSTRAINT IF EXISTS company_users_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_tax_info DROP CONSTRAINT IF EXISTS company_tax_info_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_settings DROP CONSTRAINT IF EXISTS company_settings_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_licenses DROP CONSTRAINT IF EXISTS company_licenses_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_documents DROP CONSTRAINT IF EXISTS company_documents_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_contacts DROP CONSTRAINT IF EXISTS company_contacts_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_branches DROP CONSTRAINT IF EXISTS company_branches_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_banks DROP CONSTRAINT IF EXISTS company_banks_pkey;
ALTER TABLE IF EXISTS ONLY empresa.company_addresses DROP CONSTRAINT IF EXISTS company_addresses_pkey;
ALTER TABLE IF EXISTS ONLY empresa.companies DROP CONSTRAINT IF EXISTS companies_pkey;
ALTER TABLE IF EXISTS ONLY crm.crm_pipelines DROP CONSTRAINT IF EXISTS uq_crm_pipelines;
ALTER TABLE IF EXISTS ONLY crm.crm_pipeline_stages DROP CONSTRAINT IF EXISTS uq_crm_pipeline_stages;
ALTER TABLE IF EXISTS ONLY crm.crm_opportunities DROP CONSTRAINT IF EXISTS uq_crm_opportunities;
ALTER TABLE IF EXISTS ONLY crm.crm_leads DROP CONSTRAINT IF EXISTS uq_crm_leads;
ALTER TABLE IF EXISTS ONLY crm.crm_lead_sources DROP CONSTRAINT IF EXISTS uq_crm_lead_sources;
ALTER TABLE IF EXISTS ONLY crm.oportunidades DROP CONSTRAINT IF EXISTS oportunidades_pkey;
ALTER TABLE IF EXISTS ONLY crm.leads DROP CONSTRAINT IF EXISTS leads_pkey;
ALTER TABLE IF EXISTS ONLY crm.crm_pipelines DROP CONSTRAINT IF EXISTS crm_pipelines_pkey;
ALTER TABLE IF EXISTS ONLY crm.crm_pipeline_stages DROP CONSTRAINT IF EXISTS crm_pipeline_stages_pkey;
ALTER TABLE IF EXISTS ONLY crm.crm_opportunities DROP CONSTRAINT IF EXISTS crm_opportunities_pkey;
ALTER TABLE IF EXISTS ONLY crm.crm_leads DROP CONSTRAINT IF EXISTS crm_leads_pkey;
ALTER TABLE IF EXISTS ONLY crm.crm_lead_sources DROP CONSTRAINT IF EXISTS crm_lead_sources_pkey;
ALTER TABLE IF EXISTS ONLY crm.crm_activities DROP CONSTRAINT IF EXISTS crm_activities_pkey;
ALTER TABLE IF EXISTS ONLY crm.atividades DROP CONSTRAINT IF EXISTS atividades_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.journal_entry_sequences DROP CONSTRAINT IF EXISTS uq_journal_entry_sequences;
ALTER TABLE IF EXISTS ONLY contabilidade.journal_entries DROP CONSTRAINT IF EXISTS uq_journal_entries;
ALTER TABLE IF EXISTS ONLY contabilidade.fixed_assets DROP CONSTRAINT IF EXISTS uq_fixed_assets_codigo;
ALTER TABLE IF EXISTS ONLY contabilidade.fiscal_years DROP CONSTRAINT IF EXISTS uq_fiscal_years;
ALTER TABLE IF EXISTS ONLY contabilidade.depreciation_entries DROP CONSTRAINT IF EXISTS uq_depreciation_entries_asset_period;
ALTER TABLE IF EXISTS ONLY contabilidade.chart_of_accounts DROP CONSTRAINT IF EXISTS uq_chart_of_accounts;
ALTER TABLE IF EXISTS ONLY contabilidade.fiscal_periods DROP CONSTRAINT IF EXISTS uq_accounting_periods;
ALTER TABLE IF EXISTS ONLY contabilidade.accounting_journals DROP CONSTRAINT IF EXISTS uq_accounting_journals;
ALTER TABLE IF EXISTS ONLY contabilidade.accounting_budgets DROP CONSTRAINT IF EXISTS uq_accounting_budgets_conta_ano_mes;
ALTER TABLE IF EXISTS ONLY contabilidade.account_types DROP CONSTRAINT IF EXISTS uq_account_types;
ALTER TABLE IF EXISTS ONLY contabilidade.period_closings DROP CONSTRAINT IF EXISTS period_closings_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.period_closing_checks DROP CONSTRAINT IF EXISTS period_closing_checks_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.journal_entry_sequences DROP CONSTRAINT IF EXISTS journal_entry_sequences_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.journal_entry_lines DROP CONSTRAINT IF EXISTS journal_entry_lines_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.journal_entries DROP CONSTRAINT IF EXISTS journal_entries_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.fixed_assets DROP CONSTRAINT IF EXISTS fixed_assets_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.fiscal_years DROP CONSTRAINT IF EXISTS fiscal_years_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.depreciation_entries DROP CONSTRAINT IF EXISTS depreciation_entries_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.chart_of_accounts DROP CONSTRAINT IF EXISTS chart_of_accounts_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.accounting_reports DROP CONSTRAINT IF EXISTS accounting_reports_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.fiscal_periods DROP CONSTRAINT IF EXISTS accounting_periods_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.accounting_journals DROP CONSTRAINT IF EXISTS accounting_journals_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.accounting_budgets DROP CONSTRAINT IF EXISTS accounting_budgets_pkey;
ALTER TABLE IF EXISTS ONLY contabilidade.account_types DROP CONSTRAINT IF EXISTS account_types_pkey;
ALTER TABLE IF EXISTS ONLY compras.suppliers DROP CONSTRAINT IF EXISTS uq_suppliers_tenant_nuit;
ALTER TABLE IF EXISTS ONLY compras.suppliers DROP CONSTRAINT IF EXISTS uq_suppliers_tenant_codigo;
ALTER TABLE IF EXISTS ONLY compras.supplier_groups DROP CONSTRAINT IF EXISTS uq_supplier_groups;
ALTER TABLE IF EXISTS ONLY compras.purchase_returns DROP CONSTRAINT IF EXISTS uq_purchase_returns;
ALTER TABLE IF EXISTS ONLY compras.purchase_orders DROP CONSTRAINT IF EXISTS uq_purchase_orders;
ALTER TABLE IF EXISTS ONLY compras.goods_receipts DROP CONSTRAINT IF EXISTS uq_goods_receipts;
ALTER TABLE IF EXISTS ONLY compras.suppliers DROP CONSTRAINT IF EXISTS suppliers_pkey;
ALTER TABLE IF EXISTS ONLY compras.supplier_groups DROP CONSTRAINT IF EXISTS supplier_groups_pkey;
ALTER TABLE IF EXISTS ONLY compras.supplier_contacts DROP CONSTRAINT IF EXISTS supplier_contacts_pkey;
ALTER TABLE IF EXISTS ONLY compras.supplier_addresses DROP CONSTRAINT IF EXISTS supplier_addresses_pkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_returns DROP CONSTRAINT IF EXISTS purchase_returns_pkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_return_items DROP CONSTRAINT IF EXISTS purchase_return_items_pkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_requests DROP CONSTRAINT IF EXISTS purchase_requests_tenant_id_numero_key;
ALTER TABLE IF EXISTS ONLY compras.purchase_requests DROP CONSTRAINT IF EXISTS purchase_requests_pkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_request_items DROP CONSTRAINT IF EXISTS purchase_request_items_pkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_payments DROP CONSTRAINT IF EXISTS purchase_payments_tenant_id_numero_key;
ALTER TABLE IF EXISTS ONLY compras.purchase_payments DROP CONSTRAINT IF EXISTS purchase_payments_pkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_payment_items DROP CONSTRAINT IF EXISTS purchase_payment_items_purchase_payment_id_purchase_invoice_key;
ALTER TABLE IF EXISTS ONLY compras.purchase_payment_items DROP CONSTRAINT IF EXISTS purchase_payment_items_pkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_orders DROP CONSTRAINT IF EXISTS purchase_orders_pkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_order_items DROP CONSTRAINT IF EXISTS purchase_order_items_pkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_invoices DROP CONSTRAINT IF EXISTS purchase_invoices_tenant_id_supplier_id_supplier_invoice_nu_key;
ALTER TABLE IF EXISTS ONLY compras.purchase_invoices DROP CONSTRAINT IF EXISTS purchase_invoices_tenant_id_numero_key;
ALTER TABLE IF EXISTS ONLY compras.purchase_invoices DROP CONSTRAINT IF EXISTS purchase_invoices_pkey;
ALTER TABLE IF EXISTS ONLY compras.purchase_invoice_items DROP CONSTRAINT IF EXISTS purchase_invoice_items_pkey;
ALTER TABLE IF EXISTS ONLY compras.goods_receipts DROP CONSTRAINT IF EXISTS goods_receipts_pkey;
ALTER TABLE IF EXISTS ONLY compras.goods_receipt_items DROP CONSTRAINT IF EXISTS goods_receipt_items_pkey;
ALTER TABLE IF EXISTS ONLY clientes.customers DROP CONSTRAINT IF EXISTS uq_customers_tenant_nuit;
ALTER TABLE IF EXISTS ONLY clientes.customers DROP CONSTRAINT IF EXISTS uq_customers_tenant_codigo;
ALTER TABLE IF EXISTS ONLY clientes.customer_tags DROP CONSTRAINT IF EXISTS uq_customer_tags;
ALTER TABLE IF EXISTS ONLY clientes.customer_tag_links DROP CONSTRAINT IF EXISTS uq_customer_tag_links;
ALTER TABLE IF EXISTS ONLY clientes.customer_groups DROP CONSTRAINT IF EXISTS uq_customer_groups;
ALTER TABLE IF EXISTS ONLY clientes.customer_credit_limits DROP CONSTRAINT IF EXISTS uq_customer_credit_limits_customer;
ALTER TABLE IF EXISTS ONLY clientes.customer_balances DROP CONSTRAINT IF EXISTS uq_customer_balances_customer;
ALTER TABLE IF EXISTS ONLY clientes.customers DROP CONSTRAINT IF EXISTS customers_pkey;
ALTER TABLE IF EXISTS ONLY clientes.customer_tags DROP CONSTRAINT IF EXISTS customer_tags_pkey;
ALTER TABLE IF EXISTS ONLY clientes.customer_tag_links DROP CONSTRAINT IF EXISTS customer_tag_links_pkey;
ALTER TABLE IF EXISTS ONLY clientes.customer_payments DROP CONSTRAINT IF EXISTS customer_payments_pkey;
ALTER TABLE IF EXISTS ONLY clientes.customer_notes DROP CONSTRAINT IF EXISTS customer_notes_pkey;
ALTER TABLE IF EXISTS ONLY clientes.customer_history DROP CONSTRAINT IF EXISTS customer_history_pkey;
ALTER TABLE IF EXISTS ONLY clientes.customer_groups DROP CONSTRAINT IF EXISTS customer_groups_pkey;
ALTER TABLE IF EXISTS ONLY clientes.customer_documents DROP CONSTRAINT IF EXISTS customer_documents_pkey;
ALTER TABLE IF EXISTS ONLY clientes.customer_discounts DROP CONSTRAINT IF EXISTS customer_discounts_pkey;
ALTER TABLE IF EXISTS ONLY clientes.customer_credit_limits DROP CONSTRAINT IF EXISTS customer_credit_limits_pkey;
ALTER TABLE IF EXISTS ONLY clientes.customer_contacts DROP CONSTRAINT IF EXISTS customer_contacts_pkey;
ALTER TABLE IF EXISTS ONLY clientes.customer_balances DROP CONSTRAINT IF EXISTS customer_balances_pkey;
ALTER TABLE IF EXISTS ONLY clientes.customer_addresses DROP CONSTRAINT IF EXISTS customer_addresses_pkey;
ALTER TABLE IF EXISTS ONLY centros_custo.cost_centers DROP CONSTRAINT IF EXISTS uq_cost_centers;
ALTER TABLE IF EXISTS ONLY centros_custo.cost_center_budgets DROP CONSTRAINT IF EXISTS uq_cost_center_budgets;
ALTER TABLE IF EXISTS ONLY centros_custo.cost_centers DROP CONSTRAINT IF EXISTS cost_centers_pkey;
ALTER TABLE IF EXISTS ONLY centros_custo.cost_center_budgets DROP CONSTRAINT IF EXISTS cost_center_budgets_pkey;
ALTER TABLE IF EXISTS ONLY centros_custo.cost_center_allocations DROP CONSTRAINT IF EXISTS cost_center_allocations_pkey;
ALTER TABLE IF EXISTS ONLY autorizacao.user_roles DROP CONSTRAINT IF EXISTS user_roles_pkey;
ALTER TABLE IF EXISTS ONLY autorizacao.user_roles DROP CONSTRAINT IF EXISTS uq_user_roles;
ALTER TABLE IF EXISTS ONLY autorizacao.roles DROP CONSTRAINT IF EXISTS uq_roles_tenant_codigo;
ALTER TABLE IF EXISTS ONLY autorizacao.role_permissions DROP CONSTRAINT IF EXISTS uq_role_permissions;
ALTER TABLE IF EXISTS ONLY autorizacao.permissions DROP CONSTRAINT IF EXISTS uq_permissions_codigo;
ALTER TABLE IF EXISTS ONLY autorizacao.roles DROP CONSTRAINT IF EXISTS roles_pkey;
ALTER TABLE IF EXISTS ONLY autorizacao.role_permissions DROP CONSTRAINT IF EXISTS role_permissions_pkey;
ALTER TABLE IF EXISTS ONLY autorizacao.permissions DROP CONSTRAINT IF EXISTS permissions_pkey;
ALTER TABLE IF EXISTS ONLY auth.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY auth.users DROP CONSTRAINT IF EXISTS uq_users_email;
ALTER TABLE IF EXISTS ONLY auth.permissoes_tipo DROP CONSTRAINT IF EXISTS uq_permissoes_tipo;
ALTER TABLE IF EXISTS ONLY auth.sessions DROP CONSTRAINT IF EXISTS sessions_token_hash_key;
ALTER TABLE IF EXISTS ONLY auth.sessions DROP CONSTRAINT IF EXISTS sessions_pkey;
ALTER TABLE IF EXISTS ONLY auth.permissoes_tipo DROP CONSTRAINT IF EXISTS permissoes_tipo_pkey;
ALTER TABLE IF EXISTS ONLY auth.permissoes_diretas DROP CONSTRAINT IF EXISTS permissoes_diretas_user_id_modulo_acao_key;
ALTER TABLE IF EXISTS ONLY auth.permissoes_diretas DROP CONSTRAINT IF EXISTS permissoes_diretas_pkey;
ALTER TABLE IF EXISTS ONLY auth.permissoes_cargo DROP CONSTRAINT IF EXISTS permissoes_cargo_pkey;
ALTER TABLE IF EXISTS ONLY auth.permissoes_cargo DROP CONSTRAINT IF EXISTS permissoes_cargo_cargo_id_modulo_acao_key;
ALTER TABLE IF EXISTS ONLY auth.password_resets DROP CONSTRAINT IF EXISTS password_resets_token_hash_key;
ALTER TABLE IF EXISTS ONLY auth.password_resets DROP CONSTRAINT IF EXISTS password_resets_pkey;
ALTER TABLE IF EXISTS ONLY auth.login_history DROP CONSTRAINT IF EXISTS login_history_pkey;
ALTER TABLE IF EXISTS ONLY auth.email_verifications DROP CONSTRAINT IF EXISTS email_verifications_token_hash_key;
ALTER TABLE IF EXISTS ONLY auth.email_verifications DROP CONSTRAINT IF EXISTS email_verifications_pkey;
ALTER TABLE IF EXISTS ONLY auth.cargos DROP CONSTRAINT IF EXISTS cargos_tenant_id_nome_key;
ALTER TABLE IF EXISTS ONLY auth.cargos DROP CONSTRAINT IF EXISTS cargos_pkey;
ALTER TABLE IF EXISTS ONLY auth.api_keys DROP CONSTRAINT IF EXISTS api_keys_pkey;
ALTER TABLE IF EXISTS ONLY auth.api_keys DROP CONSTRAINT IF EXISTS api_keys_key_hash_key;
ALTER TABLE IF EXISTS ONLY auditoria.audit_logs DROP CONSTRAINT IF EXISTS audit_logs_pkey;
ALTER TABLE IF EXISTS ONLY auditoria.audit_events DROP CONSTRAINT IF EXISTS audit_events_pkey;
ALTER TABLE IF EXISTS ONLY assinaturas.subscriptions DROP CONSTRAINT IF EXISTS uq_subscriptions;
ALTER TABLE IF EXISTS ONLY assinaturas.subscription_plans DROP CONSTRAINT IF EXISTS uq_subscription_plans;
ALTER TABLE IF EXISTS ONLY assinaturas.subscription_invoices DROP CONSTRAINT IF EXISTS uq_subscription_invoices;
ALTER TABLE IF EXISTS ONLY assinaturas.subscriptions DROP CONSTRAINT IF EXISTS subscriptions_pkey;
ALTER TABLE IF EXISTS ONLY assinaturas.subscription_usage DROP CONSTRAINT IF EXISTS subscription_usage_pkey;
ALTER TABLE IF EXISTS ONLY assinaturas.subscription_plans DROP CONSTRAINT IF EXISTS subscription_plans_pkey;
ALTER TABLE IF EXISTS ONLY assinaturas.subscription_invoices DROP CONSTRAINT IF EXISTS subscription_invoices_pkey;
ALTER TABLE IF EXISTS rh.justificacoes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.notif_colaborador ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.comunicados ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.chat_mensagens ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.chat_conversas ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS auth.permissoes_tipo ALTER COLUMN id DROP DEFAULT;
DROP TABLE IF EXISTS utilizadores.user_tokens;
DROP TABLE IF EXISTS utilizadores.user_settings;
DROP TABLE IF EXISTS utilizadores.user_security_logs;
DROP TABLE IF EXISTS utilizadores.user_preferences;
DROP TABLE IF EXISTS utilizadores.user_notifications;
DROP TABLE IF EXISTS utilizadores.user_devices;
DROP TABLE IF EXISTS utilizadores.user_avatar;
DROP TABLE IF EXISTS utilizadores.user_activity;
DROP TABLE IF EXISTS utilizadores.profiles;
DROP TABLE IF EXISTS tesouraria.reconciliations;
DROP TABLE IF EXISTS tesouraria.reconciliacoes_bancarias;
DROP TABLE IF EXISTS tesouraria.movimentos_financeiros;
DROP TABLE IF EXISTS tesouraria.movements;
DROP TABLE IF EXISTS tesouraria.contas_bancarias;
DROP TABLE IF EXISTS tesouraria.cash_registers;
DROP TABLE IF EXISTS tesouraria.caixas;
DROP TABLE IF EXISTS tesouraria.bank_accounts;
DROP TABLE IF EXISTS stock.warehouse_locations;
DROP TABLE IF EXISTS stock.stock_transfers;
DROP TABLE IF EXISTS stock.stock_transfer_items;
DROP TABLE IF EXISTS stock.stock_serial_numbers;
DROP TABLE IF EXISTS stock.stock_reservations;
DROP TABLE IF EXISTS stock.stock_movements;
DROP TABLE IF EXISTS stock.stock_logs;
DROP TABLE IF EXISTS stock.stock_items;
DROP TABLE IF EXISTS stock.stock_counts;
DROP TABLE IF EXISTS stock.stock_count_items;
DROP TABLE IF EXISTS stock.stock_batches;
DROP TABLE IF EXISTS stock.stock_alerts;
DROP TABLE IF EXISTS stock.stock_adjustments;
DROP TABLE IF EXISTS sistema_configuracao.tenant_integrations;
DROP TABLE IF EXISTS sistema_configuracao.tenant_feature_flags;
DROP TABLE IF EXISTS sistema_configuracao.tenant_document_settings;
DROP TABLE IF EXISTS sistema_configuracao.tenant_defaults;
DROP TABLE IF EXISTS sistema_configuracao.tenant_branding;
DROP TABLE IF EXISTS sistema_configuracao.system_logs;
DROP TABLE IF EXISTS sistema_configuracao.sms_templates;
DROP TABLE IF EXISTS sistema_configuracao.settings;
DROP TABLE IF EXISTS sistema_configuracao.languages;
DROP TABLE IF EXISTS sistema_configuracao.integrations;
DROP TABLE IF EXISTS sistema_configuracao.exchange_rates;
DROP TABLE IF EXISTS sistema_configuracao.email_templates;
DROP TABLE IF EXISTS sistema_configuracao.currencies;
DROP TABLE IF EXISTS sistema_configuracao.countries;
DROP TABLE IF EXISTS sistema_configuracao.cities;
DROP TABLE IF EXISTS sistema_configuracao.api_logs;
DROP TABLE IF EXISTS seguranca.security_policies;
DROP TABLE IF EXISTS seguranca.security_mfa_enrollments;
DROP TABLE IF EXISTS seguranca.security_ip_allowlist;
DROP TABLE IF EXISTS rh.tipos_ausencia;
DROP TABLE IF EXISTS rh.saldos_ausencia;
DROP TABLE IF EXISTS rh.recibos_vencimento;
DROP TABLE IF EXISTS rh.recibo_vencimento_itens;
DROP TABLE IF EXISTS rh.processos_disciplinares;
DROP TABLE IF EXISTS rh.presencas;
DROP TABLE IF EXISTS rh.periodos_avaliacao;
DROP SEQUENCE IF EXISTS rh.justificacoes_id_seq;
DROP TABLE IF EXISTS rh.justificacoes;
DROP TABLE IF EXISTS rh.horarios_trabalho;
DROP TABLE IF EXISTS rh.historico_salarial;
DROP TABLE IF EXISTS rh.funcionarios;
DROP TABLE IF EXISTS rh.funcionario_formacoes;
DROP TABLE IF EXISTS rh.funcionario_componentes_salariais;
DROP TABLE IF EXISTS rh.funcionario_beneficios;
DROP TABLE IF EXISTS rh.formacoes;
DROP TABLE IF EXISTS rh.folhas_pagamento;
DROP TABLE IF EXISTS rh.documentos_funcionario;
DROP TABLE IF EXISTS rh.unidades_organizacionais;
DROP TABLE IF EXISTS rh.criterios_avaliacao;
DROP TABLE IF EXISTS rh.contratos;
DROP TABLE IF EXISTS rh.contactos_emergencia;
DROP TABLE IF EXISTS rh.componentes_salariais;
DROP TABLE IF EXISTS rh.cargos;
DROP TABLE IF EXISTS rh.beneficios;
DROP TABLE IF EXISTS rh.avaliacoes;
DROP TABLE IF EXISTS rh.avaliacao_criterios;
DROP TABLE IF EXISTS rh.ausencias;
DROP TABLE IF EXISTS recursos_humanos.payroll_runs;
DROP TABLE IF EXISTS recursos_humanos.payroll_run_lines;
DROP TABLE IF EXISTS recursos_humanos.payroll_periods;
DROP TABLE IF EXISTS recursos_humanos.hr_departments;
DROP TABLE IF EXISTS recursos_humanos.employees;
DROP TABLE IF EXISTS recursos_humanos.employee_bank_accounts;
DROP TABLE IF EXISTS recrutamento.vagas;
DROP TABLE IF EXISTS recrutamento.contactos;
DROP TABLE IF EXISTS recrutamento.candidaturas;
DROP TABLE IF EXISTS recrutamento.candidatura_notas;
DROP SEQUENCE IF EXISTS public.notif_colaborador_id_seq;
DROP TABLE IF EXISTS public.notif_colaborador;
DROP TABLE IF EXISTS public.comunicados_lidos;
DROP SEQUENCE IF EXISTS public.comunicados_id_seq;
DROP TABLE IF EXISTS public.comunicados;
DROP TABLE IF EXISTS public.chat_participantes;
DROP SEQUENCE IF EXISTS public.chat_mensagens_id_seq;
DROP TABLE IF EXISTS public.chat_mensagens;
DROP SEQUENCE IF EXISTS public.chat_conversas_id_seq;
DROP TABLE IF EXISTS public.chat_conversas;
DROP TABLE IF EXISTS produtos.warehouses;
DROP TABLE IF EXISTS produtos.products;
DROP TABLE IF EXISTS produtos.product_variants;
DROP TABLE IF EXISTS produtos.product_units;
DROP TABLE IF EXISTS produtos.product_tags;
DROP TABLE IF EXISTS produtos.product_tag_links;
DROP TABLE IF EXISTS produtos.product_subcategories;
DROP TABLE IF EXISTS produtos.product_prices;
DROP TABLE IF EXISTS produtos.product_kits;
DROP TABLE IF EXISTS produtos.product_kit_items;
DROP TABLE IF EXISTS produtos.product_images;
DROP TABLE IF EXISTS produtos.product_discounts;
DROP TABLE IF EXISTS produtos.product_categories;
DROP TABLE IF EXISTS produtos.product_brands;
DROP TABLE IF EXISTS produtos.product_barcodes;
DROP TABLE IF EXISTS produtos.product_attributes;
DROP TABLE IF EXISTS produtos.product_attribute_values;
DROP TABLE IF EXISTS pos.pos_terminals;
DROP TABLE IF EXISTS pos.pos_sessions;
DROP TABLE IF EXISTS pos.pos_sales;
DROP TABLE IF EXISTS pos.pos_sale_payments;
DROP TABLE IF EXISTS pos.pos_sale_items;
DROP TABLE IF EXISTS pos.pos_catalog_items;
DROP TABLE IF EXISTS notifications.notification_templates;
DROP TABLE IF EXISTS notifications.notification_messages;
DROP TABLE IF EXISTS notifications.notification_channels;
DROP TABLE IF EXISTS multi_moeda.tenant_currencies;
DROP TABLE IF EXISTS multi_moeda.exchange_rates;
DROP TABLE IF EXISTS multi_moeda.currencies;
DROP TABLE IF EXISTS logistica.shipments;
DROP TABLE IF EXISTS logistica.shipment_items;
DROP TABLE IF EXISTS logistica.logistics_vehicles;
DROP TABLE IF EXISTS logistica.logistics_tracking_events;
DROP TABLE IF EXISTS logistica.logistics_shipments;
DROP TABLE IF EXISTS logistica.logistics_routes;
DROP TABLE IF EXISTS logistica.logistics_drivers;
DROP TABLE IF EXISTS logistica.delivery_vehicles;
DROP TABLE IF EXISTS logistica.delivery_tracking;
DROP TABLE IF EXISTS logistica.delivery_statuses;
DROP TABLE IF EXISTS logistica.delivery_routes;
DROP TABLE IF EXISTS logistica.delivery_drivers;
DROP TABLE IF EXISTS impostos.withholding_taxes;
DROP TABLE IF EXISTS impostos.withholding_tax_transactions;
DROP TABLE IF EXISTS impostos.taxes;
DROP TABLE IF EXISTS impostos.tax_transactions;
DROP TABLE IF EXISTS impostos.tax_rules;
DROP TABLE IF EXISTS impostos.tax_returns;
DROP TABLE IF EXISTS impostos.tax_return_lines;
DROP TABLE IF EXISTS impostos.tax_regimes;
DROP TABLE IF EXISTS impostos.tax_groups;
DROP TABLE IF EXISTS impostos.tax_exemptions;
DROP TABLE IF EXISTS impostos.tax_certificates;
DROP TABLE IF EXISTS gestao_escolar.school_years;
DROP TABLE IF EXISTS gestao_escolar.school_terms;
DROP TABLE IF EXISTS gestao_escolar.school_teacher_roles;
DROP TABLE IF EXISTS gestao_escolar.school_teacher_assignments;
DROP TABLE IF EXISTS gestao_escolar.school_subjects;
DROP TABLE IF EXISTS gestao_escolar.school_students;
DROP TABLE IF EXISTS gestao_escolar.school_student_roles;
DROP TABLE IF EXISTS gestao_escolar.school_payments;
DROP TABLE IF EXISTS gestao_escolar.school_messages;
DROP TABLE IF EXISTS gestao_escolar.school_library_loans;
DROP TABLE IF EXISTS gestao_escolar.school_guardians;
DROP TABLE IF EXISTS gestao_escolar.school_grades;
DROP TABLE IF EXISTS gestao_escolar.school_grade_items;
DROP TABLE IF EXISTS gestao_escolar.school_fees;
DROP TABLE IF EXISTS gestao_escolar.school_fee_plans;
DROP TABLE IF EXISTS gestao_escolar.school_enrollments;
DROP TABLE IF EXISTS gestao_escolar.school_classes;
DROP TABLE IF EXISTS gestao_escolar.school_books;
DROP TABLE IF EXISTS gestao_escolar.school_attendance;
DROP TABLE IF EXISTS financeiro.payments;
DROP TABLE IF EXISTS financeiro.payment_methods;
DROP TABLE IF EXISTS financeiro.financial_categories;
DROP TABLE IF EXISTS financeiro.financial_budgets;
DROP TABLE IF EXISTS financeiro.cash_flow_entries;
DROP TABLE IF EXISTS financeiro.accounts_receivable_payments;
DROP TABLE IF EXISTS financeiro.accounts_receivable;
DROP TABLE IF EXISTS financeiro.accounts_payable_payments;
DROP TABLE IF EXISTS financeiro.accounts_payable;
DROP TABLE IF EXISTS faturacao.sales_returns;
DROP TABLE IF EXISTS faturacao.sales_return_items;
DROP TABLE IF EXISTS faturacao.sales_quotes;
DROP TABLE IF EXISTS faturacao.sales_quote_items;
DROP TABLE IF EXISTS faturacao.sales_orders;
DROP TABLE IF EXISTS faturacao.sales_order_items;
DROP TABLE IF EXISTS faturacao.sales_delivery_items;
DROP TABLE IF EXISTS faturacao.sales_deliveries;
DROP TABLE IF EXISTS faturacao.invoices;
DROP TABLE IF EXISTS faturacao.invoice_taxes;
DROP TABLE IF EXISTS faturacao.invoice_series;
DROP TABLE IF EXISTS faturacao.invoice_receipts;
DROP TABLE IF EXISTS faturacao.invoice_items;
DROP TABLE IF EXISTS faturacao.invoice_discounts;
DROP TABLE IF EXISTS faturacao.credit_notes;
DROP TABLE IF EXISTS faturacao.credit_note_items;
DROP TABLE IF EXISTS empresas.company_users;
DROP TABLE IF EXISTS empresas.company_tax_info;
DROP TABLE IF EXISTS empresas.company_settings;
DROP TABLE IF EXISTS empresas.company_licenses;
DROP TABLE IF EXISTS empresas.company_documents;
DROP TABLE IF EXISTS empresas.company_contacts;
DROP TABLE IF EXISTS empresas.company_branches;
DROP TABLE IF EXISTS empresas.company_banks;
DROP TABLE IF EXISTS empresas.company_addresses;
DROP TABLE IF EXISTS empresas.companies;
DROP TABLE IF EXISTS empresa.company_users;
DROP TABLE IF EXISTS empresa.company_tax_info;
DROP TABLE IF EXISTS empresa.company_settings;
DROP TABLE IF EXISTS empresa.company_licenses;
DROP TABLE IF EXISTS empresa.company_documents;
DROP TABLE IF EXISTS empresa.company_contacts;
DROP TABLE IF EXISTS empresa.company_branches;
DROP TABLE IF EXISTS empresa.company_banks;
DROP TABLE IF EXISTS empresa.company_addresses;
DROP TABLE IF EXISTS empresa.companies;
DROP TABLE IF EXISTS crm.oportunidades;
DROP TABLE IF EXISTS crm.leads;
DROP TABLE IF EXISTS crm.crm_pipelines;
DROP TABLE IF EXISTS crm.crm_pipeline_stages;
DROP TABLE IF EXISTS crm.crm_opportunities;
DROP TABLE IF EXISTS crm.crm_leads;
DROP TABLE IF EXISTS crm.crm_lead_sources;
DROP TABLE IF EXISTS crm.crm_activities;
DROP TABLE IF EXISTS crm.atividades;
DROP TABLE IF EXISTS contabilidade.period_closings;
DROP TABLE IF EXISTS contabilidade.period_closing_checks;
DROP TABLE IF EXISTS contabilidade.journal_entry_sequences;
DROP TABLE IF EXISTS contabilidade.journal_entry_lines;
DROP TABLE IF EXISTS contabilidade.journal_entries;
DROP TABLE IF EXISTS contabilidade.fixed_assets;
DROP TABLE IF EXISTS contabilidade.fiscal_years;
DROP TABLE IF EXISTS contabilidade.depreciation_entries;
DROP TABLE IF EXISTS contabilidade.chart_of_accounts;
DROP TABLE IF EXISTS contabilidade.accounting_reports;
DROP TABLE IF EXISTS contabilidade.fiscal_periods;
DROP TABLE IF EXISTS contabilidade.accounting_journals;
DROP TABLE IF EXISTS contabilidade.accounting_budgets;
DROP TABLE IF EXISTS contabilidade.account_types;
DROP TABLE IF EXISTS compras.suppliers;
DROP TABLE IF EXISTS compras.supplier_groups;
DROP TABLE IF EXISTS compras.supplier_contacts;
DROP TABLE IF EXISTS compras.supplier_addresses;
DROP TABLE IF EXISTS compras.purchase_returns;
DROP TABLE IF EXISTS compras.purchase_return_items;
DROP TABLE IF EXISTS compras.purchase_requests;
DROP TABLE IF EXISTS compras.purchase_request_items;
DROP TABLE IF EXISTS compras.purchase_payments;
DROP TABLE IF EXISTS compras.purchase_payment_items;
DROP TABLE IF EXISTS compras.purchase_orders;
DROP TABLE IF EXISTS compras.purchase_order_items;
DROP TABLE IF EXISTS compras.purchase_invoices;
DROP TABLE IF EXISTS compras.purchase_invoice_items;
DROP TABLE IF EXISTS compras.goods_receipts;
DROP TABLE IF EXISTS compras.goods_receipt_items;
DROP TABLE IF EXISTS clientes.customers;
DROP TABLE IF EXISTS clientes.customer_tags;
DROP TABLE IF EXISTS clientes.customer_tag_links;
DROP TABLE IF EXISTS clientes.customer_payments;
DROP TABLE IF EXISTS clientes.customer_notes;
DROP TABLE IF EXISTS clientes.customer_history;
DROP TABLE IF EXISTS clientes.customer_groups;
DROP TABLE IF EXISTS clientes.customer_documents;
DROP TABLE IF EXISTS clientes.customer_discounts;
DROP TABLE IF EXISTS clientes.customer_credit_limits;
DROP TABLE IF EXISTS clientes.customer_contacts;
DROP TABLE IF EXISTS clientes.customer_balances;
DROP TABLE IF EXISTS clientes.customer_addresses;
DROP TABLE IF EXISTS centros_custo.cost_centers;
DROP TABLE IF EXISTS centros_custo.cost_center_budgets;
DROP TABLE IF EXISTS centros_custo.cost_center_allocations;
DROP TABLE IF EXISTS autorizacao.user_roles;
DROP TABLE IF EXISTS autorizacao.roles;
DROP TABLE IF EXISTS autorizacao.role_permissions;
DROP TABLE IF EXISTS autorizacao.permissions;
DROP TABLE IF EXISTS auth.users;
DROP TABLE IF EXISTS auth.sessions;
DROP SEQUENCE IF EXISTS auth.permissoes_tipo_id_seq;
DROP TABLE IF EXISTS auth.permissoes_tipo;
DROP TABLE IF EXISTS auth.permissoes_diretas;
DROP TABLE IF EXISTS auth.permissoes_cargo;
DROP TABLE IF EXISTS auth.password_resets;
DROP TABLE IF EXISTS auth.login_history;
DROP TABLE IF EXISTS auth.email_verifications;
DROP TABLE IF EXISTS auth.cargos;
DROP TABLE IF EXISTS auth.api_keys;
DROP TABLE IF EXISTS auditoria.audit_logs;
DROP TABLE IF EXISTS auditoria.audit_events;
DROP TABLE IF EXISTS assinaturas.subscriptions;
DROP TABLE IF EXISTS assinaturas.subscription_usage;
DROP TABLE IF EXISTS assinaturas.subscription_plans;
DROP TABLE IF EXISTS assinaturas.subscription_invoices;
DROP FUNCTION IF EXISTS stock.fn_reservar_stock(p_tenant_id bigint, p_stock_item_id bigint, p_quantity numeric, p_reference_type character varying, p_reference_id bigint);
DROP FUNCTION IF EXISTS stock.fn_liberar_reserva(p_tenant_id bigint, p_reservation_id bigint);
DROP FUNCTION IF EXISTS stock.fn_consumir_reserva(p_tenant_id bigint, p_reservation_id bigint);
DROP FUNCTION IF EXISTS impostos.trg_tax_return_lines_immutable();
DROP FUNCTION IF EXISTS impostos.trg_tax_return_immutable();
DROP FUNCTION IF EXISTS impostos.fn_aplicar_isencoes_fatura(p_tenant_id bigint, p_invoice_id bigint);
DROP EXTENSION IF EXISTS "uuid-ossp";
DROP EXTENSION IF EXISTS pgcrypto;
DROP SCHEMA IF EXISTS utilizadores;
DROP SCHEMA IF EXISTS tesouraria;
DROP SCHEMA IF EXISTS stock;
DROP SCHEMA IF EXISTS sistema_configuracao;
DROP SCHEMA IF EXISTS seguranca;
DROP SCHEMA IF EXISTS rh;
DROP SCHEMA IF EXISTS recursos_humanos;
DROP SCHEMA IF EXISTS recrutamento;
DROP SCHEMA IF EXISTS produtos;
DROP SCHEMA IF EXISTS pos;
DROP SCHEMA IF EXISTS notifications;
DROP SCHEMA IF EXISTS multi_moeda;
DROP SCHEMA IF EXISTS logistica;
DROP SCHEMA IF EXISTS impostos;
DROP SCHEMA IF EXISTS gestao_escolar;
DROP SCHEMA IF EXISTS financeiro;
DROP SCHEMA IF EXISTS faturacao;
DROP SCHEMA IF EXISTS empresas;
DROP SCHEMA IF EXISTS empresa;
DROP SCHEMA IF EXISTS crm;
DROP SCHEMA IF EXISTS contabilidade;
DROP SCHEMA IF EXISTS compras;
DROP SCHEMA IF EXISTS clientes;
DROP SCHEMA IF EXISTS centros_custo;
DROP SCHEMA IF EXISTS autorizacao;
DROP SCHEMA IF EXISTS auth;
DROP SCHEMA IF EXISTS auditoria;
DROP SCHEMA IF EXISTS assinaturas;
--
-- Name: assinaturas; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA assinaturas;


--
-- Name: auditoria; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auditoria;


--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: autorizacao; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA autorizacao;


--
-- Name: centros_custo; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA centros_custo;


--
-- Name: clientes; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA clientes;


--
-- Name: compras; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA compras;


--
-- Name: contabilidade; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA contabilidade;


--
-- Name: crm; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA crm;


--
-- Name: empresa; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA empresa;


--
-- Name: empresas; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA empresas;


--
-- Name: faturacao; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA faturacao;


--
-- Name: financeiro; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA financeiro;


--
-- Name: gestao_escolar; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA gestao_escolar;


--
-- Name: impostos; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA impostos;


--
-- Name: logistica; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA logistica;


--
-- Name: multi_moeda; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA multi_moeda;


--
-- Name: notifications; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA notifications;


--
-- Name: pos; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pos;


--
-- Name: produtos; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA produtos;


--
-- Name: recrutamento; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA recrutamento;


--
-- Name: recursos_humanos; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA recursos_humanos;


--
-- Name: rh; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA rh;


--
-- Name: seguranca; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA seguranca;


--
-- Name: sistema_configuracao; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sistema_configuracao;


--
-- Name: stock; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA stock;


--
-- Name: tesouraria; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tesouraria;


--
-- Name: utilizadores; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA utilizadores;


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: fn_aplicar_isencoes_fatura(bigint, bigint); Type: FUNCTION; Schema: impostos; Owner: -
--

CREATE FUNCTION impostos.fn_aplicar_isencoes_fatura(p_tenant_id bigint, p_invoice_id bigint) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_count INTEGER;
BEGIN
    WITH aplicaveis AS (
        SELECT i.id AS item_id, e.id AS exemption_id, e.tax_id,
               ROW_NUMBER() OVER (
                   PARTITION BY i.id
                   ORDER BY CASE e.entity_type
                       WHEN 'product' THEN 1
                       WHEN 'product_category' THEN 2
                       WHEN 'customer' THEN 3
                       ELSE 4 END, e.id DESC
               ) AS prioridade
          FROM faturacao.invoice_items i
          JOIN faturacao.invoices f ON f.id=i.invoice_id
          LEFT JOIN produtos.products p ON p.id=i.product_id
          JOIN impostos.tax_exemptions e ON e.tenant_id=f.tenant_id AND e.ativo
           AND e.data_inicio<=f.invoice_date
           AND (e.validade IS NULL OR e.validade>=f.invoice_date)
           AND (
               (e.entity_type='customer' AND e.entity_id=f.customer_id) OR
               (e.entity_type='product' AND e.entity_id=i.product_id) OR
               (e.entity_type='product_category' AND e.entity_id=p.product_category_id)
           )
         WHERE f.id=p_invoice_id AND f.tenant_id=p_tenant_id AND f.status='rascunho'
    )
    UPDATE faturacao.invoice_items i
       SET tax_id=a.tax_id,
           tax_exemption_id=a.exemption_id,
           imposto_percent=0,
           imposto_valor=0,
           total=i.subtotal
      FROM aplicaveis a
     WHERE a.item_id=i.id AND a.prioridade=1;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    UPDATE faturacao.invoices f
       SET subtotal=COALESCE(x.subtotal,0),
           imposto_total=COALESCE(x.imposto,0),
           total=COALESCE(x.total,0)
      FROM (
        SELECT invoice_id,SUM(subtotal) subtotal,SUM(imposto_valor) imposto,SUM(total) total
          FROM faturacao.invoice_items WHERE invoice_id=p_invoice_id GROUP BY invoice_id
      ) x
     WHERE f.id=x.invoice_id AND f.tenant_id=p_tenant_id;

    RETURN v_count;
END $$;


--
-- Name: trg_tax_return_immutable(); Type: FUNCTION; Schema: impostos; Owner: -
--

CREATE FUNCTION impostos.trg_tax_return_immutable() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF OLD.status IN ('submetida','paga') THEN
        RAISE EXCEPTION 'Declaracao submetida e imutavel; crie uma substituicao';
    END IF;
    RETURN NEW;
END $$;


--
-- Name: trg_tax_return_lines_immutable(); Type: FUNCTION; Schema: impostos; Owner: -
--

CREATE FUNCTION impostos.trg_tax_return_lines_immutable() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_return_id BIGINT;
    v_status VARCHAR(20);
BEGIN
    IF TG_OP='DELETE' THEN
        v_return_id := OLD.tax_return_id;
    ELSE
        v_return_id := NEW.tax_return_id;
    END IF;
    SELECT status INTO v_status FROM impostos.tax_returns WHERE id=v_return_id;
    IF v_status IN ('submetida','paga') THEN
        RAISE EXCEPTION 'Linhas de declaracao submetida sao imutaveis';
    END IF;
    IF TG_OP='DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END $$;


--
-- Name: fn_consumir_reserva(bigint, bigint); Type: FUNCTION; Schema: stock; Owner: -
--

CREATE FUNCTION stock.fn_consumir_reserva(p_tenant_id bigint, p_reservation_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_item BIGINT;
    v_quantity NUMERIC;
BEGIN
    SELECT stock_item_id,quantity INTO v_item,v_quantity
      FROM stock.stock_reservations
     WHERE id=p_reservation_id AND tenant_id=p_tenant_id AND status='ativa'
     FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reserva activa nao encontrada';
    END IF;

    UPDATE stock.stock_items
       SET quantity=quantity-v_quantity,
           reserved_quantity=GREATEST(reserved_quantity-v_quantity,0),
           updated_at=NOW()
     WHERE id=v_item AND tenant_id=p_tenant_id AND quantity>=v_quantity;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Stock insuficiente para consumir a reserva';
    END IF;

    UPDATE stock.stock_reservations
       SET status='consumida',updated_at=NOW()
     WHERE id=p_reservation_id;
    INSERT INTO stock.stock_movements(
        tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id
    ) VALUES (
        p_tenant_id,v_item,'saida',v_quantity,'stock_reservation',p_reservation_id
    );
END $$;


--
-- Name: fn_liberar_reserva(bigint, bigint); Type: FUNCTION; Schema: stock; Owner: -
--

CREATE FUNCTION stock.fn_liberar_reserva(p_tenant_id bigint, p_reservation_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_item BIGINT;
    v_quantity NUMERIC;
BEGIN
    SELECT stock_item_id,quantity INTO v_item,v_quantity
      FROM stock.stock_reservations
     WHERE id=p_reservation_id AND tenant_id=p_tenant_id AND status='ativa'
     FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reserva activa nao encontrada';
    END IF;

    UPDATE stock.stock_items
       SET reserved_quantity=GREATEST(reserved_quantity-v_quantity,0),updated_at=NOW()
     WHERE id=v_item AND tenant_id=p_tenant_id;
    UPDATE stock.stock_reservations
       SET status='cancelada',updated_at=NOW()
     WHERE id=p_reservation_id;
    INSERT INTO stock.stock_movements(
        tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id
    ) VALUES (
        p_tenant_id,v_item,'liberacao',v_quantity,'stock_reservation',p_reservation_id
    );
END $$;


--
-- Name: fn_reservar_stock(bigint, bigint, numeric, character varying, bigint); Type: FUNCTION; Schema: stock; Owner: -
--

CREATE FUNCTION stock.fn_reservar_stock(p_tenant_id bigint, p_stock_item_id bigint, p_quantity numeric, p_reference_type character varying DEFAULT NULL::character varying, p_reference_id bigint DEFAULT NULL::bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_available NUMERIC;
    v_id BIGINT;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'A quantidade deve ser positiva';
    END IF;

    SELECT available_quantity INTO v_available
      FROM stock.stock_items
     WHERE id=p_stock_item_id AND tenant_id=p_tenant_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Posicao de stock nao encontrada';
    END IF;
    IF v_available < p_quantity THEN
        RAISE EXCEPTION 'Stock disponivel insuficiente';
    END IF;

    UPDATE stock.stock_items
       SET reserved_quantity=reserved_quantity+p_quantity, updated_at=NOW()
     WHERE id=p_stock_item_id;

    INSERT INTO stock.stock_reservations(
        tenant_id,stock_item_id,quantity,reference_type,reference_id
    ) VALUES (
        p_tenant_id,p_stock_item_id,p_quantity,p_reference_type,p_reference_id
    ) RETURNING id INTO v_id;

    INSERT INTO stock.stock_movements(
        tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id
    ) VALUES (
        p_tenant_id,p_stock_item_id,'reserva',p_quantity,'stock_reservation',v_id
    );

    RETURN v_id;
END $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: subscription_invoices; Type: TABLE; Schema: assinaturas; Owner: -
--

CREATE TABLE assinaturas.subscription_invoices (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    subscription_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    billing_period_start date NOT NULL,
    billing_period_end date NOT NULL,
    due_date date NOT NULL,
    valor_total numeric(18,2) DEFAULT 0 NOT NULL,
    valor_pago numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    status character varying(20) DEFAULT 'emitida'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT subscription_invoices_status_check CHECK (((status)::text = ANY ((ARRAY['emitida'::character varying, 'paga'::character varying, 'cancelada'::character varying, 'vencida'::character varying])::text[])))
);


--
-- Name: subscription_invoices_id_seq; Type: SEQUENCE; Schema: assinaturas; Owner: -
--

ALTER TABLE assinaturas.subscription_invoices ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME assinaturas.subscription_invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: subscription_plans; Type: TABLE; Schema: assinaturas; Owner: -
--

CREATE TABLE assinaturas.subscription_plans (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    billing_period character varying(20) DEFAULT 'mensal'::character varying NOT NULL,
    preco numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    limites jsonb,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT subscription_plans_billing_period_check CHECK (((billing_period)::text = ANY ((ARRAY['mensal'::character varying, 'trimestral'::character varying, 'anual'::character varying])::text[])))
);


--
-- Name: subscription_plans_id_seq; Type: SEQUENCE; Schema: assinaturas; Owner: -
--

ALTER TABLE assinaturas.subscription_plans ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME assinaturas.subscription_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: subscription_usage; Type: TABLE; Schema: assinaturas; Owner: -
--

CREATE TABLE assinaturas.subscription_usage (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    subscription_id bigint NOT NULL,
    recurso character varying(100) NOT NULL,
    quantidade numeric(18,2) DEFAULT 0 NOT NULL,
    periodo date DEFAULT CURRENT_DATE NOT NULL,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: subscription_usage_id_seq; Type: SEQUENCE; Schema: assinaturas; Owner: -
--

ALTER TABLE assinaturas.subscription_usage ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME assinaturas.subscription_usage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: subscriptions; Type: TABLE; Schema: assinaturas; Owner: -
--

CREATE TABLE assinaturas.subscriptions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    company_id bigint,
    plan_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    starts_at date NOT NULL,
    ends_at date,
    next_billing_date date,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    unit_price numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    auto_renew boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT subscriptions_status_check CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'activa'::character varying, 'suspensa'::character varying, 'cancelada'::character varying, 'expirada'::character varying])::text[])))
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: assinaturas; Owner: -
--

ALTER TABLE assinaturas.subscriptions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME assinaturas.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: audit_events; Type: TABLE; Schema: auditoria; Owner: -
--

CREATE TABLE auditoria.audit_events (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    actor_user_id bigint,
    actor_email character varying(150),
    actor_nome character varying(150),
    service_name character varying(100) NOT NULL,
    module_name character varying(100) NOT NULL,
    action character varying(50) NOT NULL,
    entity_type character varying(100) NOT NULL,
    entity_id character varying(100),
    status character varying(20) DEFAULT 'sucesso'::character varying NOT NULL,
    ip_address character varying(64),
    user_agent text,
    metadata jsonb,
    payload_before jsonb,
    payload_after jsonb,
    previous_hash character varying(64),
    event_hash character varying(64) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT audit_events_status_check CHECK (((status)::text = ANY ((ARRAY['sucesso'::character varying, 'falha'::character varying, 'alerta'::character varying])::text[])))
);


--
-- Name: audit_events_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: -
--

ALTER TABLE auditoria.audit_events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.audit_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: audit_logs; Type: TABLE; Schema: auditoria; Owner: -
--

CREATE TABLE auditoria.audit_logs (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    user_id bigint,
    modulo character varying(100) NOT NULL,
    entidade character varying(100) NOT NULL,
    entidade_id bigint,
    acao character varying(100) NOT NULL,
    detalhes jsonb,
    ip_address character varying(64),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: -
--

ALTER TABLE auditoria.audit_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: api_keys; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.api_keys (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    user_id bigint,
    nome character varying(120) NOT NULL,
    key_prefix character varying(20) NOT NULL,
    key_hash text NOT NULL,
    ultimo_uso_em timestamp with time zone,
    expira_em timestamp with time zone,
    ativa boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: api_keys_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.api_keys ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.api_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cargos; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.cargos (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: cargos_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.cargos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.cargos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: email_verifications; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.email_verifications (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token_hash text NOT NULL,
    expira_em timestamp with time zone NOT NULL,
    usado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: email_verifications_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.email_verifications ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.email_verifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: login_history; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.login_history (
    id bigint NOT NULL,
    user_id bigint,
    tenant_id bigint NOT NULL,
    email_tentado character varying(150),
    sucesso boolean NOT NULL,
    ip_address character varying(64),
    user_agent text,
    motivo_falha character varying(255),
    criado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: login_history_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.login_history ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.login_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: password_resets; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.password_resets (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token_hash text NOT NULL,
    expira_em timestamp with time zone NOT NULL,
    usado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: password_resets_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.password_resets ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.password_resets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: permissoes_cargo; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.permissoes_cargo (
    id bigint NOT NULL,
    cargo_id bigint NOT NULL,
    modulo character varying(60) NOT NULL,
    acao character varying(60) NOT NULL
);


--
-- Name: permissoes_cargo_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.permissoes_cargo ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.permissoes_cargo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: permissoes_diretas; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.permissoes_diretas (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    modulo character varying(60) NOT NULL,
    acao character varying(60) NOT NULL
);


--
-- Name: permissoes_diretas_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.permissoes_diretas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.permissoes_diretas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: permissoes_tipo; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.permissoes_tipo (
    id bigint NOT NULL,
    tipo text NOT NULL,
    modulo text NOT NULL,
    acao text NOT NULL
);


--
-- Name: permissoes_tipo_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.permissoes_tipo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permissoes_tipo_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.permissoes_tipo_id_seq OWNED BY auth.permissoes_tipo.id;


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token_hash text NOT NULL,
    ip_address character varying(64),
    user_agent text,
    iniciado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expira_em timestamp with time zone NOT NULL,
    encerrado_em timestamp with time zone,
    ativa boolean DEFAULT true NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    password_hash text NOT NULL,
    telefone character varying(30),
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    email_verificado boolean DEFAULT false NOT NULL,
    ultimo_login_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tipo character varying(20) DEFAULT 'funcionario'::character varying NOT NULL,
    cargo_id bigint,
    permissoes_atualizadas_em timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_estado_check CHECK (((estado)::text = ANY ((ARRAY['ativo'::character varying, 'bloqueado'::character varying, 'pendente'::character varying, 'inativo'::character varying])::text[]))),
    CONSTRAINT users_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['superadmin'::character varying, 'funcionario'::character varying])::text[])))
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

ALTER TABLE auth.users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auth.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: permissions; Type: TABLE; Schema: autorizacao; Owner: -
--

CREATE TABLE autorizacao.permissions (
    id bigint NOT NULL,
    codigo character varying(100) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    recurso character varying(100),
    acao character varying(50),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: autorizacao; Owner: -
--

ALTER TABLE autorizacao.permissions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME autorizacao.permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: role_permissions; Type: TABLE; Schema: autorizacao; Owner: -
--

CREATE TABLE autorizacao.role_permissions (
    id bigint NOT NULL,
    role_id bigint NOT NULL,
    permission_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: role_permissions_id_seq; Type: SEQUENCE; Schema: autorizacao; Owner: -
--

ALTER TABLE autorizacao.role_permissions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME autorizacao.role_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: roles; Type: TABLE; Schema: autorizacao; Owner: -
--

CREATE TABLE autorizacao.roles (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: autorizacao; Owner: -
--

ALTER TABLE autorizacao.roles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME autorizacao.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_roles; Type: TABLE; Schema: autorizacao; Owner: -
--

CREATE TABLE autorizacao.user_roles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    role_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: autorizacao; Owner: -
--

ALTER TABLE autorizacao.user_roles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME autorizacao.user_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cost_center_allocations; Type: TABLE; Schema: centros_custo; Owner: -
--

CREATE TABLE centros_custo.cost_center_allocations (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    cost_center_id bigint NOT NULL,
    source_service character varying(100) NOT NULL,
    source_type character varying(100) NOT NULL,
    source_id bigint NOT NULL,
    source_line_id bigint,
    descricao character varying(255),
    valor numeric(18,2) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    allocation_percent numeric(8,4) DEFAULT 100 NOT NULL,
    referencia_tipo character varying(50),
    referencia_id bigint,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT cost_center_allocations_allocation_percent_check CHECK (((allocation_percent > (0)::numeric) AND (allocation_percent <= (100)::numeric))),
    CONSTRAINT cost_center_allocations_valor_check CHECK ((valor >= (0)::numeric))
);


--
-- Name: cost_center_allocations_id_seq; Type: SEQUENCE; Schema: centros_custo; Owner: -
--

ALTER TABLE centros_custo.cost_center_allocations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME centros_custo.cost_center_allocations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cost_center_budgets; Type: TABLE; Schema: centros_custo; Owner: -
--

CREATE TABLE centros_custo.cost_center_budgets (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    cost_center_id bigint NOT NULL,
    ano integer NOT NULL,
    mes integer,
    valor_orcamentado numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT cost_center_budgets_mes_check CHECK (((mes >= 1) AND (mes <= 12)))
);


--
-- Name: cost_center_budgets_id_seq; Type: SEQUENCE; Schema: centros_custo; Owner: -
--

ALTER TABLE centros_custo.cost_center_budgets ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME centros_custo.cost_center_budgets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cost_centers; Type: TABLE; Schema: centros_custo; Owner: -
--

CREATE TABLE centros_custo.cost_centers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    parent_id bigint,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    tipo character varying(20) DEFAULT 'centro'::character varying NOT NULL,
    gestor_user_id bigint,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT cost_centers_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['centro'::character varying, 'departamento'::character varying, 'projecto'::character varying])::text[])))
);


--
-- Name: cost_centers_id_seq; Type: SEQUENCE; Schema: centros_custo; Owner: -
--

ALTER TABLE centros_custo.cost_centers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME centros_custo.cost_centers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customer_addresses; Type: TABLE; Schema: clientes; Owner: -
--

CREATE TABLE clientes.customer_addresses (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    tipo character varying(30) DEFAULT 'principal'::character varying NOT NULL,
    endereco character varying(255) NOT NULL,
    cidade character varying(100),
    provincia character varying(100),
    pais character varying(100) DEFAULT 'Mocambique'::character varying NOT NULL,
    codigo_postal character varying(30),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT customer_addresses_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['principal'::character varying, 'entrega'::character varying, 'cobranca'::character varying, 'fiscal'::character varying])::text[])))
);


--
-- Name: customer_addresses_id_seq; Type: SEQUENCE; Schema: clientes; Owner: -
--

ALTER TABLE clientes.customer_addresses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customer_balances; Type: TABLE; Schema: clientes; Owner: -
--

CREATE TABLE clientes.customer_balances (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    saldo_atual numeric(18,2) DEFAULT 0 NOT NULL,
    saldo_vencido numeric(18,2) DEFAULT 0 NOT NULL,
    credito_disponivel numeric(18,2) DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: customer_balances_id_seq; Type: SEQUENCE; Schema: clientes; Owner: -
--

ALTER TABLE clientes.customer_balances ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_balances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customer_contacts; Type: TABLE; Schema: clientes; Owner: -
--

CREATE TABLE clientes.customer_contacts (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    cargo character varying(100),
    telefone character varying(30),
    email character varying(120),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: customer_contacts_id_seq; Type: SEQUENCE; Schema: clientes; Owner: -
--

ALTER TABLE clientes.customer_contacts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customer_credit_limits; Type: TABLE; Schema: clientes; Owner: -
--

CREATE TABLE clientes.customer_credit_limits (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    limite_credito numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    inicio_em date,
    fim_em date,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    motivo text,
    updated_by bigint,
    CONSTRAINT customer_credit_limits_limite_credito_check CHECK ((limite_credito >= (0)::numeric))
);


--
-- Name: customer_credit_limits_id_seq; Type: SEQUENCE; Schema: clientes; Owner: -
--

ALTER TABLE clientes.customer_credit_limits ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_credit_limits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customer_discounts; Type: TABLE; Schema: clientes; Owner: -
--

CREATE TABLE clientes.customer_discounts (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    tipo character varying(20) NOT NULL,
    valor numeric(18,2) NOT NULL,
    motivo character varying(150),
    ativo boolean DEFAULT true NOT NULL,
    inicio_em date,
    fim_em date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT customer_discounts_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['percentual'::character varying, 'valor_fixo'::character varying])::text[]))),
    CONSTRAINT customer_discounts_valor_check CHECK ((valor >= (0)::numeric))
);


--
-- Name: customer_discounts_id_seq; Type: SEQUENCE; Schema: clientes; Owner: -
--

ALTER TABLE clientes.customer_discounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_discounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customer_documents; Type: TABLE; Schema: clientes; Owner: -
--

CREATE TABLE clientes.customer_documents (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    numero character varying(100),
    ficheiro_url text,
    emitido_em date,
    expira_em date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT customer_documents_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['contrato'::character varying, 'nuit'::character varying, 'bi'::character varying, 'comprovativo'::character varying, 'outro'::character varying])::text[])))
);


--
-- Name: customer_documents_id_seq; Type: SEQUENCE; Schema: clientes; Owner: -
--

ALTER TABLE clientes.customer_documents ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customer_groups; Type: TABLE; Schema: clientes; Owner: -
--

CREATE TABLE clientes.customer_groups (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: customer_groups_id_seq; Type: SEQUENCE; Schema: clientes; Owner: -
--

ALTER TABLE clientes.customer_groups ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customer_history; Type: TABLE; Schema: clientes; Owner: -
--

CREATE TABLE clientes.customer_history (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    evento character varying(100) NOT NULL,
    descricao text,
    referencia_tipo character varying(50),
    referencia_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint
);


--
-- Name: customer_history_id_seq; Type: SEQUENCE; Schema: clientes; Owner: -
--

ALTER TABLE clientes.customer_history ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customer_notes; Type: TABLE; Schema: clientes; Owner: -
--

CREATE TABLE clientes.customer_notes (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    nota text NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: customer_notes_id_seq; Type: SEQUENCE; Schema: clientes; Owner: -
--

ALTER TABLE clientes.customer_notes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customer_payments; Type: TABLE; Schema: clientes; Owner: -
--

CREATE TABLE clientes.customer_payments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    documento_id bigint,
    metodo character varying(30) NOT NULL,
    referencia character varying(100),
    valor numeric(18,2) NOT NULL,
    pago_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    observacao text,
    created_by bigint,
    CONSTRAINT customer_payments_metodo_check CHECK (((metodo)::text = ANY ((ARRAY['dinheiro'::character varying, 'transferencia'::character varying, 'mpesa'::character varying, 'emola'::character varying, 'cartao'::character varying])::text[]))),
    CONSTRAINT customer_payments_valor_check CHECK ((valor > (0)::numeric))
);


--
-- Name: customer_payments_id_seq; Type: SEQUENCE; Schema: clientes; Owner: -
--

ALTER TABLE clientes.customer_payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customer_tag_links; Type: TABLE; Schema: clientes; Owner: -
--

CREATE TABLE clientes.customer_tag_links (
    id bigint NOT NULL,
    customer_id bigint NOT NULL,
    customer_tag_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: customer_tag_links_id_seq; Type: SEQUENCE; Schema: clientes; Owner: -
--

ALTER TABLE clientes.customer_tag_links ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_tag_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customer_tags; Type: TABLE; Schema: clientes; Owner: -
--

CREATE TABLE clientes.customer_tags (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    cor character varying(20),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: customer_tags_id_seq; Type: SEQUENCE; Schema: clientes; Owner: -
--

ALTER TABLE clientes.customer_tags ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customer_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customers; Type: TABLE; Schema: clientes; Owner: -
--

CREATE TABLE clientes.customers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    customer_group_id bigint,
    codigo character varying(50),
    nome character varying(150) NOT NULL,
    nuit character varying(30),
    telefone character varying(30),
    email character varying(120),
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    observacao text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    bloqueio_motivo text,
    bloqueado_em timestamp with time zone,
    CONSTRAINT customers_estado_check CHECK (((estado)::text = ANY ((ARRAY['ativo'::character varying, 'inativo'::character varying, 'bloqueado'::character varying])::text[])))
);


--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: clientes; Owner: -
--

ALTER TABLE clientes.customers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME clientes.customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: goods_receipt_items; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.goods_receipt_items (
    id bigint NOT NULL,
    goods_receipt_id bigint NOT NULL,
    purchase_order_item_id bigint NOT NULL,
    product_id bigint,
    quantity_received numeric(18,3) NOT NULL,
    returned_quantity numeric(18,3) DEFAULT 0 NOT NULL,
    unit_cost numeric(18,2) NOT NULL,
    lote character varying(80),
    validade date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT goods_receipt_items_quantity_received_check CHECK ((quantity_received > (0)::numeric)),
    CONSTRAINT goods_receipt_items_returned_quantity_check CHECK ((returned_quantity >= (0)::numeric)),
    CONSTRAINT goods_receipt_items_unit_cost_check CHECK ((unit_cost >= (0)::numeric))
);


--
-- Name: goods_receipt_items_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.goods_receipt_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.goods_receipt_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: goods_receipts; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.goods_receipts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    purchase_order_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    receipt_date date DEFAULT CURRENT_DATE NOT NULL,
    warehouse_id bigint,
    status character varying(20) DEFAULT 'confirmado'::character varying NOT NULL,
    observacoes text,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    supplier_document character varying(100),
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT goods_receipts_status_check CHECK (((status)::text = ANY ((ARRAY['confirmado'::character varying, 'cancelado'::character varying])::text[])))
);


--
-- Name: goods_receipts_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.goods_receipts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.goods_receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: purchase_invoice_items; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.purchase_invoice_items (
    id bigint NOT NULL,
    purchase_invoice_id bigint NOT NULL,
    purchase_order_item_id bigint,
    product_id bigint,
    descricao character varying(255) NOT NULL,
    unidade character varying(20) DEFAULT 'UN'::character varying NOT NULL,
    quantity numeric(18,4) NOT NULL,
    unit_price numeric(18,2) NOT NULL,
    desconto numeric(18,2) DEFAULT 0 NOT NULL,
    tax_rate numeric(8,4) DEFAULT 0 NOT NULL,
    tax_amount numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_invoice_items_desconto_check CHECK ((desconto >= (0)::numeric)),
    CONSTRAINT purchase_invoice_items_quantity_check CHECK ((quantity > (0)::numeric)),
    CONSTRAINT purchase_invoice_items_tax_amount_check CHECK ((tax_amount >= (0)::numeric)),
    CONSTRAINT purchase_invoice_items_tax_rate_check CHECK ((tax_rate >= (0)::numeric)),
    CONSTRAINT purchase_invoice_items_total_check CHECK ((total >= (0)::numeric)),
    CONSTRAINT purchase_invoice_items_unit_price_check CHECK ((unit_price >= (0)::numeric))
);


--
-- Name: purchase_invoice_items_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.purchase_invoice_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_invoice_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: purchase_invoices; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.purchase_invoices (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    purchase_order_id bigint,
    goods_receipt_id bigint,
    numero character varying(60) NOT NULL,
    supplier_invoice_number character varying(100),
    invoice_date date DEFAULT CURRENT_DATE NOT NULL,
    due_date date NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_total numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    valor_pago numeric(18,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    observacoes text,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_invoices_status_check CHECK (((status)::text = ANY ((ARRAY['rascunho'::character varying, 'emitida'::character varying, 'parcial'::character varying, 'paga'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: purchase_invoices_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.purchase_invoices ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: purchase_order_items; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.purchase_order_items (
    id bigint NOT NULL,
    purchase_order_id bigint NOT NULL,
    product_id bigint,
    descricao character varying(255) NOT NULL,
    unidade character varying(30) DEFAULT 'UN'::character varying NOT NULL,
    quantity numeric(18,3) NOT NULL,
    received_quantity numeric(18,3) DEFAULT 0 NOT NULL,
    unit_price numeric(18,2) NOT NULL,
    desconto numeric(18,2) DEFAULT 0 NOT NULL,
    tax_rate numeric(8,4) DEFAULT 0 NOT NULL,
    tax_amount numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT purchase_order_items_desconto_check CHECK ((desconto >= (0)::numeric)),
    CONSTRAINT purchase_order_items_quantity_check CHECK ((quantity > (0)::numeric)),
    CONSTRAINT purchase_order_items_received_quantity_check CHECK ((received_quantity >= (0)::numeric)),
    CONSTRAINT purchase_order_items_tax_amount_check CHECK ((tax_amount >= (0)::numeric)),
    CONSTRAINT purchase_order_items_tax_rate_check CHECK ((tax_rate >= (0)::numeric)),
    CONSTRAINT purchase_order_items_total_check CHECK ((total >= (0)::numeric)),
    CONSTRAINT purchase_order_items_unit_price_check CHECK ((unit_price >= (0)::numeric))
);


--
-- Name: purchase_order_items_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.purchase_order_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: purchase_orders; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.purchase_orders (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    order_date date DEFAULT CURRENT_DATE NOT NULL,
    expected_date date,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_total numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    observacoes text,
    criado_por bigint,
    aprovado_por bigint,
    aprovado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    purchase_request_id bigint,
    payment_terms character varying(120),
    CONSTRAINT purchase_orders_status_check CHECK (((status)::text = ANY ((ARRAY['rascunho'::character varying, 'aprovada'::character varying, 'parcial'::character varying, 'recebida'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: purchase_orders_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.purchase_orders ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: purchase_payment_items; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.purchase_payment_items (
    id bigint NOT NULL,
    purchase_payment_id bigint NOT NULL,
    purchase_invoice_id bigint NOT NULL,
    valor numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_payment_items_valor_check CHECK ((valor > (0)::numeric))
);


--
-- Name: purchase_payment_items_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.purchase_payment_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_payment_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: purchase_payments; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.purchase_payments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    numero character varying(60) NOT NULL,
    payment_date date DEFAULT CURRENT_DATE NOT NULL,
    metodo character varying(30) NOT NULL,
    referencia character varying(100),
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    valor numeric(18,2) NOT NULL,
    valor_alocado numeric(18,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'confirmado'::character varying NOT NULL,
    observacoes text,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_payments_status_check CHECK (((status)::text = ANY ((ARRAY['rascunho'::character varying, 'confirmado'::character varying, 'cancelado'::character varying])::text[]))),
    CONSTRAINT purchase_payments_valor_alocado_check CHECK ((valor_alocado >= (0)::numeric)),
    CONSTRAINT purchase_payments_valor_check CHECK ((valor > (0)::numeric))
);


--
-- Name: purchase_payments_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.purchase_payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: purchase_request_items; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.purchase_request_items (
    id bigint NOT NULL,
    purchase_request_id bigint NOT NULL,
    product_id bigint,
    descricao character varying(255) NOT NULL,
    unidade character varying(20) DEFAULT 'UN'::character varying NOT NULL,
    quantity numeric(18,4) NOT NULL,
    estimated_unit_price numeric(18,2) DEFAULT 0 NOT NULL,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_request_items_estimated_unit_price_check CHECK ((estimated_unit_price >= (0)::numeric)),
    CONSTRAINT purchase_request_items_quantity_check CHECK ((quantity > (0)::numeric))
);


--
-- Name: purchase_request_items_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.purchase_request_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_request_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: purchase_requests; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.purchase_requests (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    request_date date DEFAULT CURRENT_DATE NOT NULL,
    required_date date,
    department character varying(120),
    requested_by bigint,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    prioridade character varying(20) DEFAULT 'normal'::character varying NOT NULL,
    justificacao text,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_requests_prioridade_check CHECK (((prioridade)::text = ANY ((ARRAY['baixa'::character varying, 'normal'::character varying, 'alta'::character varying, 'urgente'::character varying])::text[]))),
    CONSTRAINT purchase_requests_status_check CHECK (((status)::text = ANY ((ARRAY['rascunho'::character varying, 'submetida'::character varying, 'aprovada'::character varying, 'rejeitada'::character varying, 'convertida'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: purchase_requests_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.purchase_requests ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: purchase_return_items; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.purchase_return_items (
    id bigint NOT NULL,
    purchase_return_id bigint NOT NULL,
    goods_receipt_item_id bigint NOT NULL,
    product_id bigint,
    quantity numeric(18,3) NOT NULL,
    unit_cost numeric(18,2) NOT NULL,
    total numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT purchase_return_items_quantity_check CHECK ((quantity > (0)::numeric)),
    CONSTRAINT purchase_return_items_total_check CHECK ((total >= (0)::numeric)),
    CONSTRAINT purchase_return_items_unit_cost_check CHECK ((unit_cost >= (0)::numeric))
);


--
-- Name: purchase_return_items_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.purchase_return_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_return_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: purchase_returns; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.purchase_returns (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    goods_receipt_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    return_date date DEFAULT CURRENT_DATE NOT NULL,
    motivo character varying(255) NOT NULL,
    status character varying(20) DEFAULT 'confirmada'::character varying NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    observacoes text,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    warehouse_id bigint,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT purchase_returns_status_check CHECK (((status)::text = ANY ((ARRAY['confirmada'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: purchase_returns_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.purchase_returns ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.purchase_returns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: supplier_addresses; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.supplier_addresses (
    id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    tipo character varying(30) DEFAULT 'principal'::character varying NOT NULL,
    endereco character varying(255) NOT NULL,
    cidade character varying(100),
    provincia character varying(100),
    pais character varying(100) DEFAULT 'Mocambique'::character varying NOT NULL,
    codigo_postal character varying(30),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT supplier_addresses_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['principal'::character varying, 'entrega'::character varying, 'cobranca'::character varying, 'fiscal'::character varying])::text[])))
);


--
-- Name: supplier_addresses_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.supplier_addresses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.supplier_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: supplier_contacts; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.supplier_contacts (
    id bigint NOT NULL,
    supplier_id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    cargo character varying(100),
    telefone character varying(30),
    email character varying(120),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: supplier_contacts_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.supplier_contacts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.supplier_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: supplier_groups; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.supplier_groups (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: supplier_groups_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.supplier_groups ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.supplier_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: suppliers; Type: TABLE; Schema: compras; Owner: -
--

CREATE TABLE compras.suppliers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    supplier_group_id bigint,
    codigo character varying(50),
    nome character varying(150) NOT NULL,
    nuit character varying(30),
    telefone character varying(30),
    email character varying(120),
    moeda_padrao character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    prazo_pagamento_dias integer DEFAULT 0 NOT NULL,
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    observacao text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT suppliers_estado_check CHECK (((estado)::text = ANY ((ARRAY['ativo'::character varying, 'inativo'::character varying, 'bloqueado'::character varying])::text[])))
);


--
-- Name: suppliers_id_seq; Type: SEQUENCE; Schema: compras; Owner: -
--

ALTER TABLE compras.suppliers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME compras.suppliers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: account_types; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.account_types (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(20) NOT NULL,
    nome character varying(100) NOT NULL,
    classe character varying(20) NOT NULL,
    natureza character varying(20) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT account_types_classe_check CHECK (((classe)::text = ANY ((ARRAY['ativo'::character varying, 'passivo'::character varying, 'capital'::character varying, 'rendimento'::character varying, 'gasto'::character varying])::text[]))),
    CONSTRAINT account_types_natureza_check CHECK (((natureza)::text = ANY ((ARRAY['devedora'::character varying, 'credora'::character varying])::text[])))
);


--
-- Name: account_types_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.account_types ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.account_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: accounting_budgets; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.accounting_budgets (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    chart_account_id bigint NOT NULL,
    fiscal_year_id bigint NOT NULL,
    mes integer,
    valor_orcamentado numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_accounting_budgets_mes CHECK (((mes IS NULL) OR ((mes >= 1) AND (mes <= 12)))),
    CONSTRAINT chk_accounting_budgets_valor CHECK ((valor_orcamentado >= (0)::numeric))
);


--
-- Name: accounting_budgets_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.accounting_budgets ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.accounting_budgets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: accounting_journals; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.accounting_journals (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(20) NOT NULL,
    nome character varying(120) NOT NULL,
    tipo character varying(20) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT accounting_journals_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['geral'::character varying, 'vendas'::character varying, 'compras'::character varying, 'tesouraria'::character varying, 'folha'::character varying, 'ajuste'::character varying])::text[])))
);


--
-- Name: accounting_journals_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.accounting_journals ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.accounting_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fiscal_periods; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.fiscal_periods (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    ano integer NOT NULL,
    mes integer NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    status character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    fechado_em timestamp with time zone,
    fechado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fiscal_year_id bigint,
    CONSTRAINT accounting_periods_mes_check CHECK (((mes >= 1) AND (mes <= 12))),
    CONSTRAINT accounting_periods_status_check CHECK (((status)::text = ANY ((ARRAY['aberto'::character varying, 'fechado'::character varying])::text[])))
);


--
-- Name: accounting_periods_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.fiscal_periods ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.accounting_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: accounting_reports; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.accounting_reports (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    parametros jsonb DEFAULT '{}'::jsonb NOT NULL,
    conteudo jsonb DEFAULT '{}'::jsonb NOT NULL,
    gerado_por bigint,
    gerado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_accounting_reports_tipo CHECK (((tipo)::text = ANY ((ARRAY['trial_balance'::character varying, 'balance_sheet'::character varying, 'income_statement'::character varying, 'general_ledger'::character varying, 'depreciation_summary'::character varying, 'budget_execution'::character varying])::text[])))
);


--
-- Name: accounting_reports_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.accounting_reports ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.accounting_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: chart_of_accounts; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.chart_of_accounts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    parent_id bigint,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    aceita_lancamento boolean DEFAULT true NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    account_type_id bigint
);


--
-- Name: chart_of_accounts_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.chart_of_accounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.chart_of_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: depreciation_entries; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.depreciation_entries (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    fixed_asset_id bigint NOT NULL,
    fiscal_period_id bigint NOT NULL,
    numero_parcela integer NOT NULL,
    valor_amortizacao numeric(18,2) NOT NULL,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    journal_entry_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_depreciation_entries_status CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'processado'::character varying, 'cancelado'::character varying])::text[]))),
    CONSTRAINT chk_depreciation_entries_valor CHECK ((valor_amortizacao >= (0)::numeric))
);


--
-- Name: depreciation_entries_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.depreciation_entries ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.depreciation_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fiscal_years; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.fiscal_years (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    ano integer NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    status character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    fechado_em timestamp with time zone,
    fechado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fiscal_years_status_check CHECK (((status)::text = ANY ((ARRAY['aberto'::character varying, 'fechado'::character varying])::text[])))
);


--
-- Name: fiscal_years_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.fiscal_years ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.fiscal_years_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fixed_assets; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.fixed_assets (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    chart_account_id bigint NOT NULL,
    depreciation_account_id bigint NOT NULL,
    accumulated_depreciation_account_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    data_aquisicao date NOT NULL,
    valor_aquisicao numeric(18,2) NOT NULL,
    valor_residual numeric(18,2) DEFAULT 0 NOT NULL,
    vida_util_meses integer NOT NULL,
    metodo character varying(20) DEFAULT 'linha_recta'::character varying NOT NULL,
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    data_alienacao date,
    valor_alienacao numeric(18,2),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_fixed_assets_estado CHECK (((estado)::text = ANY ((ARRAY['ativo'::character varying, 'alienado'::character varying])::text[]))),
    CONSTRAINT chk_fixed_assets_metodo CHECK (((metodo)::text = 'linha_recta'::text)),
    CONSTRAINT chk_fixed_assets_valor_aquisicao CHECK ((valor_aquisicao > (0)::numeric)),
    CONSTRAINT chk_fixed_assets_valor_residual CHECK ((valor_residual >= (0)::numeric)),
    CONSTRAINT chk_fixed_assets_vida_util CHECK ((vida_util_meses > 0))
);


--
-- Name: fixed_assets_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.fixed_assets ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.fixed_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: journal_entries; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.journal_entries (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    fiscal_period_id bigint NOT NULL,
    accounting_journal_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    entry_date date NOT NULL,
    descricao character varying(255) NOT NULL,
    referencia_tipo character varying(50),
    referencia_id bigint,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    total_debito numeric(18,2) DEFAULT 0 NOT NULL,
    total_credito numeric(18,2) DEFAULT 0 NOT NULL,
    criado_por bigint,
    publicado_por bigint,
    publicado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT journal_entries_status_check CHECK (((status)::text = ANY ((ARRAY['rascunho'::character varying, 'publicado'::character varying, 'anulado'::character varying])::text[])))
);


--
-- Name: journal_entries_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.journal_entries ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.journal_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: journal_entry_lines; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.journal_entry_lines (
    id bigint NOT NULL,
    journal_entry_id bigint NOT NULL,
    account_id bigint NOT NULL,
    descricao character varying(255),
    debit numeric(18,2) DEFAULT 0 NOT NULL,
    credit numeric(18,2) DEFAULT 0 NOT NULL,
    reference_type character varying(50),
    reference_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT journal_entry_lines_credit_check CHECK ((credit >= (0)::numeric)),
    CONSTRAINT journal_entry_lines_debit_check CHECK ((debit >= (0)::numeric))
);


--
-- Name: journal_entry_lines_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.journal_entry_lines ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.journal_entry_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: journal_entry_sequences; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.journal_entry_sequences (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    accounting_journal_id bigint NOT NULL,
    ano integer NOT NULL,
    proxima_sequencia integer DEFAULT 1 NOT NULL
);


--
-- Name: journal_entry_sequences_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.journal_entry_sequences ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.journal_entry_sequences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: period_closing_checks; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.period_closing_checks (
    id bigint NOT NULL,
    period_closing_id bigint NOT NULL,
    verificacao character varying(100) NOT NULL,
    passou boolean NOT NULL,
    detalhe text,
    verificado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: period_closing_checks_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.period_closing_checks ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.period_closing_checks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: period_closings; Type: TABLE; Schema: contabilidade; Owner: -
--

CREATE TABLE contabilidade.period_closings (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    fiscal_period_id bigint NOT NULL,
    status character varying(20) DEFAULT 'em_curso'::character varying NOT NULL,
    iniciado_por bigint,
    iniciado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    encerrado_por bigint,
    encerrado_em timestamp with time zone,
    justificacao_reabertura text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_period_closings_status CHECK (((status)::text = ANY ((ARRAY['em_curso'::character varying, 'verificado'::character varying, 'encerrado'::character varying, 'reaberto'::character varying])::text[])))
);


--
-- Name: period_closings_id_seq; Type: SEQUENCE; Schema: contabilidade; Owner: -
--

ALTER TABLE contabilidade.period_closings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME contabilidade.period_closings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: atividades; Type: TABLE; Schema: crm; Owner: -
--

CREATE TABLE crm.atividades (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    lead_id bigint,
    oportunidade_id bigint,
    tipo character varying(20) DEFAULT 'nota'::character varying NOT NULL,
    titulo character varying(200) NOT NULL,
    descricao text,
    data_atividade timestamp with time zone,
    concluida boolean DEFAULT false NOT NULL,
    responsavel character varying(100),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT atividades_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['nota'::character varying, 'tarefa'::character varying, 'chamada'::character varying, 'reuniao'::character varying, 'email'::character varying])::text[]))),
    CONSTRAINT chk_atividades_link CHECK (((lead_id IS NOT NULL) OR (oportunidade_id IS NOT NULL)))
);


--
-- Name: atividades_id_seq; Type: SEQUENCE; Schema: crm; Owner: -
--

ALTER TABLE crm.atividades ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.atividades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: crm_activities; Type: TABLE; Schema: crm; Owner: -
--

CREATE TABLE crm.crm_activities (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    lead_id bigint,
    opportunity_id bigint,
    tipo character varying(30) NOT NULL,
    assunto character varying(150) NOT NULL,
    descricao text,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    agendado_para timestamp with time zone,
    concluido_em timestamp with time zone,
    owner_user_id bigint,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT crm_activities_status_check CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'concluida'::character varying, 'cancelada'::character varying])::text[]))),
    CONSTRAINT crm_activities_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['chamada'::character varying, 'email'::character varying, 'reuniao'::character varying, 'nota'::character varying, 'tarefa'::character varying, 'whatsapp'::character varying])::text[])))
);


--
-- Name: crm_activities_id_seq; Type: SEQUENCE; Schema: crm; Owner: -
--

ALTER TABLE crm.crm_activities ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.crm_activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: crm_lead_sources; Type: TABLE; Schema: crm; Owner: -
--

CREATE TABLE crm.crm_lead_sources (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: crm_lead_sources_id_seq; Type: SEQUENCE; Schema: crm; Owner: -
--

ALTER TABLE crm.crm_lead_sources ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.crm_lead_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: crm_leads; Type: TABLE; Schema: crm; Owner: -
--

CREATE TABLE crm.crm_leads (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    lead_source_id bigint,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    empresa character varying(150),
    email character varying(150),
    telefone character varying(30),
    estado character varying(20) DEFAULT 'novo'::character varying NOT NULL,
    interesse character varying(255),
    observacoes text,
    owner_user_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT crm_leads_estado_check CHECK (((estado)::text = ANY ((ARRAY['novo'::character varying, 'qualificado'::character varying, 'convertido'::character varying, 'perdido'::character varying])::text[])))
);


--
-- Name: crm_leads_id_seq; Type: SEQUENCE; Schema: crm; Owner: -
--

ALTER TABLE crm.crm_leads ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.crm_leads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: crm_opportunities; Type: TABLE; Schema: crm; Owner: -
--

CREATE TABLE crm.crm_opportunities (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    pipeline_id bigint NOT NULL,
    stage_id bigint NOT NULL,
    lead_id bigint,
    customer_id bigint,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    valor_estimado numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    probabilidade numeric(5,2) DEFAULT 0 NOT NULL,
    expected_close_date date,
    estado character varying(20) DEFAULT 'aberta'::character varying NOT NULL,
    owner_user_id bigint,
    observacoes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT crm_opportunities_estado_check CHECK (((estado)::text = ANY ((ARRAY['aberta'::character varying, 'ganha'::character varying, 'perdida'::character varying, 'cancelada'::character varying])::text[]))),
    CONSTRAINT crm_opportunities_probabilidade_check CHECK (((probabilidade >= (0)::numeric) AND (probabilidade <= (100)::numeric)))
);


--
-- Name: crm_opportunities_id_seq; Type: SEQUENCE; Schema: crm; Owner: -
--

ALTER TABLE crm.crm_opportunities ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.crm_opportunities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: crm_pipeline_stages; Type: TABLE; Schema: crm; Owner: -
--

CREATE TABLE crm.crm_pipeline_stages (
    id bigint NOT NULL,
    pipeline_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    ordem integer NOT NULL,
    probabilidade numeric(5,2) DEFAULT 0 NOT NULL,
    ganho boolean DEFAULT false NOT NULL,
    perdido boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT crm_pipeline_stages_probabilidade_check CHECK (((probabilidade >= (0)::numeric) AND (probabilidade <= (100)::numeric)))
);


--
-- Name: crm_pipeline_stages_id_seq; Type: SEQUENCE; Schema: crm; Owner: -
--

ALTER TABLE crm.crm_pipeline_stages ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.crm_pipeline_stages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: crm_pipelines; Type: TABLE; Schema: crm; Owner: -
--

CREATE TABLE crm.crm_pipelines (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: crm_pipelines_id_seq; Type: SEQUENCE; Schema: crm; Owner: -
--

ALTER TABLE crm.crm_pipelines ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.crm_pipelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: leads; Type: TABLE; Schema: crm; Owner: -
--

CREATE TABLE crm.leads (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    empresa character varying(150),
    email character varying(255),
    telefone character varying(30),
    origem character varying(50) DEFAULT 'outro'::character varying NOT NULL,
    estado character varying(20) DEFAULT 'novo'::character varying NOT NULL,
    responsavel character varying(100),
    notas text,
    cliente_id bigint,
    convertido_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT leads_estado_check CHECK (((estado)::text = ANY ((ARRAY['novo'::character varying, 'contactado'::character varying, 'qualificado'::character varying, 'desqualificado'::character varying, 'convertido'::character varying])::text[]))),
    CONSTRAINT leads_origem_check CHECK (((origem)::text = ANY ((ARRAY['site'::character varying, 'referencia'::character varying, 'redes_sociais'::character varying, 'evento'::character varying, 'chamada_fria'::character varying, 'email'::character varying, 'anuncio'::character varying, 'outro'::character varying])::text[])))
);


--
-- Name: leads_id_seq; Type: SEQUENCE; Schema: crm; Owner: -
--

ALTER TABLE crm.leads ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.leads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: oportunidades; Type: TABLE; Schema: crm; Owner: -
--

CREATE TABLE crm.oportunidades (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    titulo character varying(200) NOT NULL,
    lead_id bigint,
    cliente_id bigint,
    estagio character varying(20) DEFAULT 'novo'::character varying NOT NULL,
    valor_estimado numeric(18,2) DEFAULT 0,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    probabilidade smallint DEFAULT 0 NOT NULL,
    data_fecho_prevista date,
    data_fecho_real date,
    motivo_perda text,
    responsavel character varying(100),
    descricao text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT oportunidades_estagio_check CHECK (((estagio)::text = ANY ((ARRAY['novo'::character varying, 'qualificado'::character varying, 'proposta'::character varying, 'negociacao'::character varying, 'ganho'::character varying, 'perdido'::character varying])::text[]))),
    CONSTRAINT oportunidades_probabilidade_check CHECK (((probabilidade >= 0) AND (probabilidade <= 100))),
    CONSTRAINT oportunidades_valor_estimado_check CHECK ((valor_estimado >= (0)::numeric))
);


--
-- Name: oportunidades_id_seq; Type: SEQUENCE; Schema: crm; Owner: -
--

ALTER TABLE crm.oportunidades ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME crm.oportunidades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: companies; Type: TABLE; Schema: empresa; Owner: -
--

CREATE TABLE empresa.companies (
    id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    nome_comercial character varying(150),
    tipo character varying(30) DEFAULT 'empresa'::character varying NOT NULL,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    moeda_base character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    timezone character varying(60) DEFAULT 'Africa/Maputo'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT companies_status_check CHECK (((status)::text = ANY ((ARRAY['ativa'::character varying, 'suspensa'::character varying, 'inativa'::character varying])::text[]))),
    CONSTRAINT companies_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['empresa'::character varying, 'organizacao'::character varying, 'holding'::character varying, 'filial_independente'::character varying])::text[])))
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: empresa; Owner: -
--

ALTER TABLE empresa.companies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_addresses; Type: TABLE; Schema: empresa; Owner: -
--

CREATE TABLE empresa.company_addresses (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    branch_id bigint,
    tipo character varying(30) DEFAULT 'principal'::character varying NOT NULL,
    endereco character varying(255) NOT NULL,
    cidade character varying(100),
    provincia character varying(100),
    pais character varying(100) DEFAULT 'Mocambique'::character varying NOT NULL,
    codigo_postal character varying(30),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_addresses_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['principal'::character varying, 'fiscal'::character varying, 'entrega'::character varying, 'filial'::character varying, 'cobranca'::character varying])::text[])))
);


--
-- Name: company_addresses_id_seq; Type: SEQUENCE; Schema: empresa; Owner: -
--

ALTER TABLE empresa.company_addresses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_banks; Type: TABLE; Schema: empresa; Owner: -
--

CREATE TABLE empresa.company_banks (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    banco character varying(120) NOT NULL,
    numero_conta character varying(60) NOT NULL,
    nib character varying(60),
    iban character varying(60),
    swift character varying(30),
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: company_banks_id_seq; Type: SEQUENCE; Schema: empresa; Owner: -
--

ALTER TABLE empresa.company_banks ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_banks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_branches; Type: TABLE; Schema: empresa; Owner: -
--

CREATE TABLE empresa.company_branches (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_branches_status_check CHECK (((status)::text = ANY ((ARRAY['ativa'::character varying, 'inativa'::character varying])::text[])))
);


--
-- Name: company_branches_id_seq; Type: SEQUENCE; Schema: empresa; Owner: -
--

ALTER TABLE empresa.company_branches ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_branches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_contacts; Type: TABLE; Schema: empresa; Owner: -
--

CREATE TABLE empresa.company_contacts (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    branch_id bigint,
    tipo character varying(30) DEFAULT 'geral'::character varying NOT NULL,
    nome character varying(150),
    telefone character varying(30),
    email character varying(150),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_contacts_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['geral'::character varying, 'financeiro'::character varying, 'comercial'::character varying, 'suporte'::character varying, 'rh'::character varying])::text[])))
);


--
-- Name: company_contacts_id_seq; Type: SEQUENCE; Schema: empresa; Owner: -
--

ALTER TABLE empresa.company_contacts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_documents; Type: TABLE; Schema: empresa; Owner: -
--

CREATE TABLE empresa.company_documents (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    numero character varying(100),
    ficheiro_url text,
    emitido_em date,
    expira_em date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_documents_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['alvara'::character varying, 'certidao'::character varying, 'contrato_social'::character varying, 'licenca'::character varying, 'outro'::character varying])::text[])))
);


--
-- Name: company_documents_id_seq; Type: SEQUENCE; Schema: empresa; Owner: -
--

ALTER TABLE empresa.company_documents ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_licenses; Type: TABLE; Schema: empresa; Owner: -
--

CREATE TABLE empresa.company_licenses (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    plano character varying(50) NOT NULL,
    licenca_chave character varying(120),
    limite_usuarios integer,
    limite_filiais integer,
    inicia_em date NOT NULL,
    expira_em date,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_licenses_status_check CHECK (((status)::text = ANY ((ARRAY['ativa'::character varying, 'expirada'::character varying, 'suspensa'::character varying])::text[])))
);


--
-- Name: company_licenses_id_seq; Type: SEQUENCE; Schema: empresa; Owner: -
--

ALTER TABLE empresa.company_licenses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_licenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_settings; Type: TABLE; Schema: empresa; Owner: -
--

CREATE TABLE empresa.company_settings (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    chave character varying(100) NOT NULL,
    valor text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: company_settings_id_seq; Type: SEQUENCE; Schema: empresa; Owner: -
--

ALTER TABLE empresa.company_settings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_tax_info; Type: TABLE; Schema: empresa; Owner: -
--

CREATE TABLE empresa.company_tax_info (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    nuit character varying(30) NOT NULL,
    regime_iva character varying(50),
    taxa_iva_padrao numeric(5,2) DEFAULT 17.00 NOT NULL,
    inicio_atividade date,
    reparticao_fiscal character varying(150),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_tax_info_taxa_iva_padrao_check CHECK ((taxa_iva_padrao >= (0)::numeric))
);


--
-- Name: company_tax_info_id_seq; Type: SEQUENCE; Schema: empresa; Owner: -
--

ALTER TABLE empresa.company_tax_info ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_tax_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_users; Type: TABLE; Schema: empresa; Owner: -
--

CREATE TABLE empresa.company_users (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    user_id bigint NOT NULL,
    branch_id bigint,
    perfil_empresa character varying(50),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: company_users_id_seq; Type: SEQUENCE; Schema: empresa; Owner: -
--

ALTER TABLE empresa.company_users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresa.company_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: companies; Type: TABLE; Schema: empresas; Owner: -
--

CREATE TABLE empresas.companies (
    id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    nome_comercial character varying(150),
    tipo character varying(30) DEFAULT 'empresa'::character varying NOT NULL,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    moeda_base character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    timezone character varying(60) DEFAULT 'Africa/Maputo'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT companies_status_check CHECK (((status)::text = ANY ((ARRAY['ativa'::character varying, 'suspensa'::character varying, 'inativa'::character varying])::text[]))),
    CONSTRAINT companies_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['empresa'::character varying, 'organizacao'::character varying, 'holding'::character varying, 'filial_independente'::character varying])::text[])))
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: empresas; Owner: -
--

ALTER TABLE empresas.companies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_addresses; Type: TABLE; Schema: empresas; Owner: -
--

CREATE TABLE empresas.company_addresses (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    branch_id bigint,
    tipo character varying(30) DEFAULT 'principal'::character varying NOT NULL,
    endereco character varying(255) NOT NULL,
    cidade character varying(100),
    provincia character varying(100),
    pais character varying(100) DEFAULT 'Mocambique'::character varying NOT NULL,
    codigo_postal character varying(30),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_addresses_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['principal'::character varying, 'fiscal'::character varying, 'entrega'::character varying, 'filial'::character varying, 'cobranca'::character varying])::text[])))
);


--
-- Name: company_addresses_id_seq; Type: SEQUENCE; Schema: empresas; Owner: -
--

ALTER TABLE empresas.company_addresses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_banks; Type: TABLE; Schema: empresas; Owner: -
--

CREATE TABLE empresas.company_banks (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    banco character varying(120) NOT NULL,
    numero_conta character varying(60) NOT NULL,
    nib character varying(60),
    iban character varying(60),
    swift character varying(30),
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: company_banks_id_seq; Type: SEQUENCE; Schema: empresas; Owner: -
--

ALTER TABLE empresas.company_banks ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_banks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_branches; Type: TABLE; Schema: empresas; Owner: -
--

CREATE TABLE empresas.company_branches (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_branches_status_check CHECK (((status)::text = ANY ((ARRAY['ativa'::character varying, 'inativa'::character varying])::text[])))
);


--
-- Name: company_branches_id_seq; Type: SEQUENCE; Schema: empresas; Owner: -
--

ALTER TABLE empresas.company_branches ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_branches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_contacts; Type: TABLE; Schema: empresas; Owner: -
--

CREATE TABLE empresas.company_contacts (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    branch_id bigint,
    tipo character varying(30) DEFAULT 'geral'::character varying NOT NULL,
    nome character varying(150),
    telefone character varying(30),
    email character varying(150),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_contacts_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['geral'::character varying, 'financeiro'::character varying, 'comercial'::character varying, 'suporte'::character varying, 'rh'::character varying])::text[])))
);


--
-- Name: company_contacts_id_seq; Type: SEQUENCE; Schema: empresas; Owner: -
--

ALTER TABLE empresas.company_contacts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_documents; Type: TABLE; Schema: empresas; Owner: -
--

CREATE TABLE empresas.company_documents (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    numero character varying(100),
    ficheiro_url text,
    emitido_em date,
    expira_em date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_documents_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['alvara'::character varying, 'certidao'::character varying, 'contrato_social'::character varying, 'licenca'::character varying, 'outro'::character varying])::text[])))
);


--
-- Name: company_documents_id_seq; Type: SEQUENCE; Schema: empresas; Owner: -
--

ALTER TABLE empresas.company_documents ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_licenses; Type: TABLE; Schema: empresas; Owner: -
--

CREATE TABLE empresas.company_licenses (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    plano character varying(50) NOT NULL,
    licenca_chave character varying(120),
    limite_usuarios integer,
    limite_filiais integer,
    inicia_em date NOT NULL,
    expira_em date,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_licenses_status_check CHECK (((status)::text = ANY ((ARRAY['ativa'::character varying, 'expirada'::character varying, 'suspensa'::character varying])::text[])))
);


--
-- Name: company_licenses_id_seq; Type: SEQUENCE; Schema: empresas; Owner: -
--

ALTER TABLE empresas.company_licenses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_licenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_settings; Type: TABLE; Schema: empresas; Owner: -
--

CREATE TABLE empresas.company_settings (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    chave character varying(100) NOT NULL,
    valor text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: company_settings_id_seq; Type: SEQUENCE; Schema: empresas; Owner: -
--

ALTER TABLE empresas.company_settings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_tax_info; Type: TABLE; Schema: empresas; Owner: -
--

CREATE TABLE empresas.company_tax_info (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    nuit character varying(30) NOT NULL,
    regime_iva character varying(50),
    taxa_iva_padrao numeric(5,2) DEFAULT 17.00 NOT NULL,
    inicio_atividade date,
    reparticao_fiscal character varying(150),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT company_tax_info_taxa_iva_padrao_check CHECK ((taxa_iva_padrao >= (0)::numeric))
);


--
-- Name: company_tax_info_id_seq; Type: SEQUENCE; Schema: empresas; Owner: -
--

ALTER TABLE empresas.company_tax_info ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_tax_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_users; Type: TABLE; Schema: empresas; Owner: -
--

CREATE TABLE empresas.company_users (
    id bigint NOT NULL,
    company_id bigint NOT NULL,
    user_id bigint NOT NULL,
    branch_id bigint,
    perfil_empresa character varying(50),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: company_users_id_seq; Type: SEQUENCE; Schema: empresas; Owner: -
--

ALTER TABLE empresas.company_users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME empresas.company_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: credit_note_items; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.credit_note_items (
    id bigint NOT NULL,
    credit_note_id bigint NOT NULL,
    product_id bigint,
    descricao character varying(255) NOT NULL,
    quantidade numeric(18,4) DEFAULT 1 NOT NULL,
    preco_unitario numeric(18,4) DEFAULT 0 NOT NULL,
    tax_id bigint,
    imposto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    imposto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL
);


--
-- Name: credit_note_items_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.credit_note_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.credit_note_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: credit_notes; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.credit_notes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    serie_id bigint,
    customer_id bigint NOT NULL,
    invoice_id bigint,
    numero character varying(50) NOT NULL,
    credit_date date DEFAULT CURRENT_DATE NOT NULL,
    motivo character varying(255) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    observacoes text,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    emitida_em timestamp with time zone,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT credit_notes_status_check CHECK (((status)::text = ANY ((ARRAY['rascunho'::character varying, 'emitida'::character varying, 'aplicada'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: credit_notes_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.credit_notes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.credit_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: invoice_discounts; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.invoice_discounts (
    id bigint NOT NULL,
    invoice_id bigint NOT NULL,
    tipo character varying(20) NOT NULL,
    valor numeric(18,2) NOT NULL,
    descricao text,
    CONSTRAINT invoice_discounts_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['percentual'::character varying, 'valor_fixo'::character varying])::text[]))),
    CONSTRAINT invoice_discounts_valor_check CHECK ((valor > (0)::numeric))
);


--
-- Name: invoice_discounts_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.invoice_discounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.invoice_discounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: invoice_items; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.invoice_items (
    id bigint NOT NULL,
    invoice_id bigint NOT NULL,
    product_id bigint NOT NULL,
    descricao character varying(255),
    quantidade numeric(18,4) NOT NULL,
    preco_unitario numeric(18,4) NOT NULL,
    desconto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    desconto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    tax_id bigint,
    imposto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    imposto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    tax_exemption_id bigint,
    CONSTRAINT invoice_items_preco_unitario_check CHECK ((preco_unitario >= (0)::numeric)),
    CONSTRAINT invoice_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);


--
-- Name: invoice_items_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.invoice_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.invoice_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: invoice_receipts; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.invoice_receipts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    serie_id bigint,
    invoice_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    payment_date date DEFAULT CURRENT_DATE NOT NULL,
    payment_method_id bigint,
    valor numeric(18,2) NOT NULL,
    referencia character varying(100),
    observacoes text,
    status character varying(20) DEFAULT 'confirmado'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT invoice_receipts_status_check CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'confirmado'::character varying, 'cancelado'::character varying])::text[]))),
    CONSTRAINT invoice_receipts_valor_check CHECK ((valor > (0)::numeric))
);


--
-- Name: invoice_receipts_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.invoice_receipts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.invoice_receipts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: invoice_series; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.invoice_series (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    tipo character varying(10) NOT NULL,
    prefixo character varying(20) NOT NULL,
    ano integer NOT NULL,
    sequencia integer DEFAULT 0 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT invoice_series_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['ORC'::character varying, 'ENC'::character varying, 'GR'::character varying, 'FT'::character varying, 'NC'::character varying, 'RB'::character varying, 'VD'::character varying])::text[])))
);


--
-- Name: invoice_series_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.invoice_series ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.invoice_series_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: invoice_taxes; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.invoice_taxes (
    id bigint NOT NULL,
    invoice_id bigint NOT NULL,
    tax_id bigint,
    nome_imposto character varying(100) NOT NULL,
    taxa numeric(8,4) NOT NULL,
    base_imponivel numeric(18,2) NOT NULL,
    valor_imposto numeric(18,2) NOT NULL
);


--
-- Name: invoice_taxes_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.invoice_taxes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.invoice_taxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: invoices; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.invoices (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    serie_id bigint,
    customer_id bigint NOT NULL,
    sales_order_id bigint,
    numero character varying(50) NOT NULL,
    invoice_date date DEFAULT CURRENT_DATE NOT NULL,
    due_date date,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    taxa_cambio numeric(14,6) DEFAULT 1 NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_total numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    valor_pago numeric(18,2) DEFAULT 0 NOT NULL,
    saldo_pendente numeric(18,2) GENERATED ALWAYS AS ((total - valor_pago)) STORED,
    payment_terms character varying(100),
    observacoes text,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    emitida_em timestamp with time zone,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tipo character varying(20) DEFAULT 'normal'::character varying NOT NULL,
    CONSTRAINT invoices_status_check CHECK (((status)::text = ANY ((ARRAY['rascunho'::character varying, 'emitida'::character varying, 'parcialmente_paga'::character varying, 'paga'::character varying, 'cancelada'::character varying, 'vencida'::character varying])::text[]))),
    CONSTRAINT invoices_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['normal'::character varying, 'proforma'::character varying])::text[])))
);


--
-- Name: invoices_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.invoices ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sales_deliveries; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.sales_deliveries (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    serie_id bigint,
    sales_order_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    delivery_date date DEFAULT CURRENT_DATE NOT NULL,
    morada_entrega text,
    observacoes text,
    status character varying(20) DEFAULT 'emitida'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT sales_deliveries_status_check CHECK (((status)::text = ANY ((ARRAY['emitida'::character varying, 'em_transito'::character varying, 'entregue'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: sales_deliveries_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.sales_deliveries ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_deliveries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sales_delivery_items; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.sales_delivery_items (
    id bigint NOT NULL,
    sales_delivery_id bigint NOT NULL,
    sales_order_item_id bigint,
    product_id bigint NOT NULL,
    quantidade_entregue numeric(18,4) NOT NULL,
    CONSTRAINT sales_delivery_items_quantidade_entregue_check CHECK ((quantidade_entregue > (0)::numeric))
);


--
-- Name: sales_delivery_items_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.sales_delivery_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_delivery_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sales_order_items; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.sales_order_items (
    id bigint NOT NULL,
    sales_order_id bigint NOT NULL,
    product_id bigint NOT NULL,
    descricao character varying(255),
    quantidade numeric(18,4) NOT NULL,
    quantidade_entregue numeric(18,4) DEFAULT 0 NOT NULL,
    preco_unitario numeric(18,4) NOT NULL,
    desconto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    desconto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    tax_id bigint,
    imposto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    imposto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    CONSTRAINT sales_order_items_preco_unitario_check CHECK ((preco_unitario >= (0)::numeric)),
    CONSTRAINT sales_order_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);


--
-- Name: sales_order_items_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.sales_order_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sales_orders; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.sales_orders (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    serie_id bigint,
    customer_id bigint NOT NULL,
    sales_quote_id bigint,
    numero character varying(50) NOT NULL,
    order_date date DEFAULT CURRENT_DATE NOT NULL,
    data_entrega_prevista date,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_total numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    observacoes text,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT sales_orders_status_check CHECK (((status)::text = ANY ((ARRAY['rascunho'::character varying, 'confirmada'::character varying, 'parcial'::character varying, 'entregue'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: sales_orders_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.sales_orders ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sales_quote_items; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.sales_quote_items (
    id bigint NOT NULL,
    sales_quote_id bigint NOT NULL,
    product_id bigint NOT NULL,
    descricao character varying(255),
    quantidade numeric(18,4) NOT NULL,
    preco_unitario numeric(18,4) NOT NULL,
    desconto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    desconto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    tax_id bigint,
    imposto_percent numeric(8,4) DEFAULT 0 NOT NULL,
    imposto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    CONSTRAINT sales_quote_items_preco_unitario_check CHECK ((preco_unitario >= (0)::numeric)),
    CONSTRAINT sales_quote_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);


--
-- Name: sales_quote_items_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.sales_quote_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_quote_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sales_quotes; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.sales_quotes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    serie_id bigint,
    customer_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    quote_date date DEFAULT CURRENT_DATE NOT NULL,
    validade date,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_total numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    observacoes text,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT sales_quotes_status_check CHECK (((status)::text = ANY ((ARRAY['rascunho'::character varying, 'enviado'::character varying, 'aprovado'::character varying, 'rejeitado'::character varying, 'convertido'::character varying, 'expirado'::character varying])::text[])))
);


--
-- Name: sales_quotes_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.sales_quotes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_quotes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sales_return_items; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.sales_return_items (
    id bigint NOT NULL,
    sales_return_id bigint NOT NULL,
    product_id bigint NOT NULL,
    quantidade numeric(18,4) NOT NULL,
    motivo text,
    estado_produto character varying(20) DEFAULT 'bom'::character varying,
    CONSTRAINT sales_return_items_estado_produto_check CHECK (((estado_produto)::text = ANY ((ARRAY['bom'::character varying, 'danificado'::character varying, 'defeito'::character varying])::text[]))),
    CONSTRAINT sales_return_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);


--
-- Name: sales_return_items_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.sales_return_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_return_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sales_returns; Type: TABLE; Schema: faturacao; Owner: -
--

CREATE TABLE faturacao.sales_returns (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    customer_id bigint NOT NULL,
    invoice_id bigint,
    credit_note_id bigint,
    numero character varying(50) NOT NULL,
    return_date date DEFAULT CURRENT_DATE NOT NULL,
    observacoes text,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT sales_returns_status_check CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'recebida'::character varying, 'processada'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: sales_returns_id_seq; Type: SEQUENCE; Schema: faturacao; Owner: -
--

ALTER TABLE faturacao.sales_returns ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME faturacao.sales_returns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: accounts_payable; Type: TABLE; Schema: financeiro; Owner: -
--

CREATE TABLE financeiro.accounts_payable (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    supplier_id bigint,
    financial_category_id bigint,
    origem_tipo character varying(50),
    origem_id bigint,
    descricao character varying(255),
    valor_total numeric(18,2) NOT NULL,
    valor_pago numeric(18,2) DEFAULT 0 NOT NULL,
    valor_pendente numeric(18,2) GENERATED ALWAYS AS ((valor_total - valor_pago)) STORED,
    data_emissao date NOT NULL,
    data_vencimento date NOT NULL,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT accounts_payable_status_check CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'parcial'::character varying, 'liquidada'::character varying, 'cancelada'::character varying, 'vencida'::character varying])::text[]))),
    CONSTRAINT accounts_payable_valor_total_check CHECK ((valor_total > (0)::numeric))
);


--
-- Name: accounts_payable_id_seq; Type: SEQUENCE; Schema: financeiro; Owner: -
--

ALTER TABLE financeiro.accounts_payable ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.accounts_payable_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: accounts_payable_payments; Type: TABLE; Schema: financeiro; Owner: -
--

CREATE TABLE financeiro.accounts_payable_payments (
    id bigint NOT NULL,
    accounts_payable_id bigint NOT NULL,
    payment_id bigint NOT NULL,
    valor_imputado numeric(18,2) NOT NULL,
    data_imputacao timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT accounts_payable_payments_valor_imputado_check CHECK ((valor_imputado > (0)::numeric))
);


--
-- Name: accounts_payable_payments_id_seq; Type: SEQUENCE; Schema: financeiro; Owner: -
--

ALTER TABLE financeiro.accounts_payable_payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.accounts_payable_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: accounts_receivable; Type: TABLE; Schema: financeiro; Owner: -
--

CREATE TABLE financeiro.accounts_receivable (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    customer_id bigint NOT NULL,
    financial_category_id bigint,
    origem_tipo character varying(50),
    origem_id bigint,
    descricao character varying(255),
    valor_total numeric(18,2) NOT NULL,
    valor_pago numeric(18,2) DEFAULT 0 NOT NULL,
    valor_pendente numeric(18,2) GENERATED ALWAYS AS ((valor_total - valor_pago)) STORED,
    data_emissao date NOT NULL,
    data_vencimento date NOT NULL,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT accounts_receivable_status_check CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'parcial'::character varying, 'liquidada'::character varying, 'cancelada'::character varying, 'vencida'::character varying])::text[]))),
    CONSTRAINT accounts_receivable_valor_total_check CHECK ((valor_total > (0)::numeric))
);


--
-- Name: accounts_receivable_id_seq; Type: SEQUENCE; Schema: financeiro; Owner: -
--

ALTER TABLE financeiro.accounts_receivable ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.accounts_receivable_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: accounts_receivable_payments; Type: TABLE; Schema: financeiro; Owner: -
--

CREATE TABLE financeiro.accounts_receivable_payments (
    id bigint NOT NULL,
    accounts_receivable_id bigint NOT NULL,
    payment_id bigint NOT NULL,
    valor_imputado numeric(18,2) NOT NULL,
    data_imputacao timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT accounts_receivable_payments_valor_imputado_check CHECK ((valor_imputado > (0)::numeric))
);


--
-- Name: accounts_receivable_payments_id_seq; Type: SEQUENCE; Schema: financeiro; Owner: -
--

ALTER TABLE financeiro.accounts_receivable_payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.accounts_receivable_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cash_flow_entries; Type: TABLE; Schema: financeiro; Owner: -
--

CREATE TABLE financeiro.cash_flow_entries (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    financial_category_id bigint,
    tipo character varying(20) NOT NULL,
    origem character varying(30) NOT NULL,
    data date NOT NULL,
    valor numeric(18,2) NOT NULL,
    descricao character varying(255),
    referencia_tipo character varying(50),
    referencia_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT cash_flow_entries_origem_check CHECK (((origem)::text = ANY ((ARRAY['realizado'::character varying, 'previsto'::character varying])::text[]))),
    CONSTRAINT cash_flow_entries_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['entrada'::character varying, 'saida'::character varying])::text[]))),
    CONSTRAINT cash_flow_entries_valor_check CHECK ((valor > (0)::numeric))
);


--
-- Name: cash_flow_entries_id_seq; Type: SEQUENCE; Schema: financeiro; Owner: -
--

ALTER TABLE financeiro.cash_flow_entries ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.cash_flow_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: financial_budgets; Type: TABLE; Schema: financeiro; Owner: -
--

CREATE TABLE financeiro.financial_budgets (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    financial_category_id bigint NOT NULL,
    ano integer NOT NULL,
    mes integer,
    valor_orcamentado numeric(18,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT financial_budgets_mes_check CHECK (((mes >= 1) AND (mes <= 12)))
);


--
-- Name: financial_budgets_id_seq; Type: SEQUENCE; Schema: financeiro; Owner: -
--

ALTER TABLE financeiro.financial_budgets ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.financial_budgets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: financial_categories; Type: TABLE; Schema: financeiro; Owner: -
--

CREATE TABLE financeiro.financial_categories (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    parent_id bigint,
    codigo character varying(30),
    nome character varying(120) NOT NULL,
    tipo character varying(20) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    CONSTRAINT financial_categories_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['receita'::character varying, 'despesa'::character varying, 'transferencia'::character varying])::text[])))
);


--
-- Name: financial_categories_id_seq; Type: SEQUENCE; Schema: financeiro; Owner: -
--

ALTER TABLE financeiro.financial_categories ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.financial_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: payment_methods; Type: TABLE; Schema: financeiro; Owner: -
--

CREATE TABLE financeiro.payment_methods (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    tipo character varying(30) DEFAULT 'outro'::character varying NOT NULL,
    requer_referencia boolean DEFAULT false NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    CONSTRAINT payment_methods_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['numerario'::character varying, 'transferencia'::character varying, 'tpa'::character varying, 'cheque'::character varying, 'credito'::character varying, 'debito'::character varying, 'mpesa'::character varying, 'emola'::character varying, 'outro'::character varying])::text[])))
);


--
-- Name: payment_methods_id_seq; Type: SEQUENCE; Schema: financeiro; Owner: -
--

ALTER TABLE financeiro.payment_methods ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.payment_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: payments; Type: TABLE; Schema: financeiro; Owner: -
--

CREATE TABLE financeiro.payments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    payment_method_id bigint,
    financial_category_id bigint,
    tipo character varying(20) NOT NULL,
    data_pagamento date NOT NULL,
    valor numeric(18,2) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    referencia_tipo character varying(50),
    referencia_id bigint,
    descricao text,
    status character varying(20) DEFAULT 'confirmado'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT payments_status_check CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'confirmado'::character varying, 'cancelado'::character varying])::text[]))),
    CONSTRAINT payments_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['recebimento'::character varying, 'pagamento'::character varying])::text[]))),
    CONSTRAINT payments_valor_check CHECK ((valor > (0)::numeric))
);


--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: financeiro; Owner: -
--

ALTER TABLE financeiro.payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME financeiro.payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_attendance; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_attendance (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    class_id bigint NOT NULL,
    student_id bigint NOT NULL,
    attendance_date date NOT NULL,
    estado character varying(20) NOT NULL,
    observacoes text,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    subject_id bigint,
    enrollment_id bigint,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_attendance_estado_check CHECK (((estado)::text = ANY ((ARRAY['presente'::character varying, 'ausente'::character varying, 'justificado'::character varying, 'atrasado'::character varying])::text[])))
);


--
-- Name: school_attendance_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_attendance ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_attendance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_books; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_books (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    isbn character varying(30),
    codigo character varying(40) NOT NULL,
    titulo character varying(200) NOT NULL,
    autor character varying(150),
    editora character varying(120),
    ano_publicacao integer,
    categoria character varying(80),
    exemplares_total integer DEFAULT 1 NOT NULL,
    exemplares_disponiveis integer DEFAULT 1 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_books_exemplares_disponiveis_check CHECK ((exemplares_disponiveis >= 0)),
    CONSTRAINT school_books_exemplares_total_check CHECK ((exemplares_total >= 0))
);


--
-- Name: school_books_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_books ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_books_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_classes; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_classes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    nivel character varying(50),
    ano_lectivo character varying(20) NOT NULL,
    turma character varying(20),
    capacidade integer,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    school_year_id bigint,
    director_teacher_id bigint,
    sala character varying(50),
    horario jsonb DEFAULT '[]'::jsonb NOT NULL
);


--
-- Name: school_classes_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_classes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_classes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_enrollments; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_enrollments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    student_id bigint NOT NULL,
    class_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    data_matricula date DEFAULT CURRENT_DATE NOT NULL,
    status character varying(20) DEFAULT 'activa'::character varying NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    school_year_id bigint,
    observacoes text,
    transferred_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_enrollments_status_check CHECK (((status)::text = ANY ((ARRAY['activa'::character varying, 'cancelada'::character varying, 'concluida'::character varying])::text[])))
);


--
-- Name: school_enrollments_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_enrollments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_fee_plans; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_fee_plans (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    school_year_id bigint,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    tipo character varying(30) DEFAULT 'propina'::character varying NOT NULL,
    valor numeric(18,2) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    periodicidade character varying(20) DEFAULT 'mensal'::character varying NOT NULL,
    dia_vencimento integer,
    classe_nivel character varying(80),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_fee_plans_valor_check CHECK ((valor >= (0)::numeric))
);


--
-- Name: school_fee_plans_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_fee_plans ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_fee_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_fees; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_fees (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    enrollment_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    descricao character varying(150) NOT NULL,
    mes_referencia character varying(20),
    data_vencimento date NOT NULL,
    valor_total numeric(18,2) DEFAULT 0 NOT NULL,
    valor_pago numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fee_plan_id bigint,
    student_id bigint,
    desconto numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_motivo text,
    entidade character varying(20),
    referencia character varying(40),
    emitida_em timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_fees_status_check CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'emitida'::character varying, 'parcial'::character varying, 'paga'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: school_fees_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_fees ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_fees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_grade_items; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_grade_items (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    class_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    term_id bigint NOT NULL,
    nome character varying(120) NOT NULL,
    tipo character varying(30) DEFAULT 'teste'::character varying NOT NULL,
    data_avaliacao date,
    nota_maxima numeric(6,2) DEFAULT 20 NOT NULL,
    peso numeric(6,2) DEFAULT 1 NOT NULL,
    publicado boolean DEFAULT false NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: school_grade_items_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_grade_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_grade_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_grades; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_grades (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    grade_item_id bigint NOT NULL,
    student_id bigint NOT NULL,
    enrollment_id bigint,
    nota numeric(6,2),
    observacoes text,
    lancado_por bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: school_grades_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_grades ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_grades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_guardians; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_guardians (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    student_id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    parentesco character varying(50),
    telefone character varying(30) NOT NULL,
    email character varying(120),
    nuit character varying(30),
    endereco text,
    principal boolean DEFAULT false NOT NULL,
    autorizado_recolher boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: school_guardians_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_guardians ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_guardians_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_library_loans; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_library_loans (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    book_id bigint NOT NULL,
    student_id bigint,
    borrower_type character varying(20) DEFAULT 'aluno'::character varying NOT NULL,
    borrower_id bigint,
    emprestado_em date DEFAULT CURRENT_DATE NOT NULL,
    devolucao_prevista date NOT NULL,
    devolvido_em date,
    status character varying(20) DEFAULT 'emprestado'::character varying NOT NULL,
    observacoes text,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_library_loans_status_check CHECK (((status)::text = ANY ((ARRAY['emprestado'::character varying, 'devolvido'::character varying, 'atrasado'::character varying, 'perdido'::character varying])::text[])))
);


--
-- Name: school_library_loans_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_library_loans ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_library_loans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_messages; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_messages (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    titulo character varying(180) NOT NULL,
    conteudo text NOT NULL,
    tipo character varying(30) DEFAULT 'comunicado'::character varying NOT NULL,
    audience_type character varying(30) DEFAULT 'todos'::character varying NOT NULL,
    audience_id bigint,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    publicado_em timestamp with time zone,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_messages_status_check CHECK (((status)::text = ANY ((ARRAY['rascunho'::character varying, 'publicado'::character varying, 'arquivado'::character varying])::text[])))
);


--
-- Name: school_messages_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_messages ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_payments; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_payments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    school_fee_id bigint NOT NULL,
    student_id bigint NOT NULL,
    external_id character varying(100),
    metodo character varying(30) NOT NULL,
    referencia character varying(100),
    valor numeric(18,2) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    status character varying(20) DEFAULT 'confirmado'::character varying NOT NULL,
    conciliado boolean DEFAULT false NOT NULL,
    pago_em timestamp with time zone DEFAULT now() NOT NULL,
    created_by bigint,
    payload_gateway jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_payments_status_check CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'confirmado'::character varying, 'falhado'::character varying, 'estornado'::character varying])::text[]))),
    CONSTRAINT school_payments_valor_check CHECK ((valor > (0)::numeric))
);


--
-- Name: school_payments_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_student_roles; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_student_roles (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    student_id bigint NOT NULL,
    class_id bigint,
    cargo character varying(100) NOT NULL,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    activo boolean DEFAULT true NOT NULL,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: school_student_roles_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_student_roles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_student_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_students; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_students (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    data_nascimento date,
    genero character varying(20),
    encarregado_nome character varying(150),
    encarregado_telefone character varying(30),
    encarregado_email character varying(150),
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    documento_tipo character varying(30),
    documento_numero character varying(60),
    nuit character varying(30),
    telefone character varying(30),
    email character varying(120),
    endereco text,
    fotografia_url text,
    CONSTRAINT school_students_estado_check CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'inactivo'::character varying, 'transferido'::character varying, 'graduado'::character varying])::text[])))
);


--
-- Name: school_students_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_students ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_students_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_subjects; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_subjects (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    carga_horaria integer,
    nota_minima numeric(6,2) DEFAULT 10 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: school_subjects_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_subjects ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_subjects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_teacher_assignments; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_teacher_assignments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    school_year_id bigint,
    class_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    teacher_id bigint NOT NULL,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: school_teacher_assignments_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_teacher_assignments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_teacher_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_teacher_roles; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_teacher_roles (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    teacher_id bigint NOT NULL,
    cargo character varying(100) NOT NULL,
    school_year_id bigint,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    activo boolean DEFAULT true NOT NULL,
    observacoes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: school_teacher_roles_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_teacher_roles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_teacher_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_terms; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_terms (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    school_year_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    peso numeric(6,2) DEFAULT 1 NOT NULL,
    status character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_terms_check CHECK ((data_fim >= data_inicio)),
    CONSTRAINT school_terms_status_check CHECK (((status)::text = ANY ((ARRAY['aberto'::character varying, 'encerrado'::character varying])::text[])))
);


--
-- Name: school_terms_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_terms ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_terms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: school_years; Type: TABLE; Schema: gestao_escolar; Owner: -
--

CREATE TABLE gestao_escolar.school_years (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_years_check CHECK ((data_fim >= data_inicio)),
    CONSTRAINT school_years_status_check CHECK (((status)::text = ANY ((ARRAY['rascunho'::character varying, 'activo'::character varying, 'encerrado'::character varying])::text[])))
);


--
-- Name: school_years_id_seq; Type: SEQUENCE; Schema: gestao_escolar; Owner: -
--

ALTER TABLE gestao_escolar.school_years ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gestao_escolar.school_years_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tax_certificates; Type: TABLE; Schema: impostos; Owner: -
--

CREATE TABLE impostos.tax_certificates (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    entity_type character varying(30) NOT NULL,
    entity_id bigint NOT NULL,
    tipo character varying(40) NOT NULL,
    numero character varying(80) NOT NULL,
    data_emissao date NOT NULL,
    validade date,
    ficheiro_url text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tax_certificates_entity_type_check CHECK (((entity_type)::text = ANY ((ARRAY['tenant'::character varying, 'customer'::character varying, 'supplier'::character varying, 'employee'::character varying])::text[]))),
    CONSTRAINT tax_certificates_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['isencao'::character varying, 'bom_contribuinte'::character varying, 'residencia_fiscal'::character varying, 'outro'::character varying])::text[])))
);


--
-- Name: tax_certificates_id_seq; Type: SEQUENCE; Schema: impostos; Owner: -
--

ALTER TABLE impostos.tax_certificates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_certificates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tax_exemptions; Type: TABLE; Schema: impostos; Owner: -
--

CREATE TABLE impostos.tax_exemptions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    tax_id bigint NOT NULL,
    entity_type character varying(30) NOT NULL,
    entity_id bigint NOT NULL,
    motivo character varying(255),
    numero_isencao character varying(60),
    validade date,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tax_exemptions_entity_type_check CHECK (((entity_type)::text = ANY ((ARRAY['customer'::character varying, 'supplier'::character varying, 'product'::character varying, 'product_category'::character varying])::text[])))
);


--
-- Name: tax_exemptions_id_seq; Type: SEQUENCE; Schema: impostos; Owner: -
--

ALTER TABLE impostos.tax_exemptions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_exemptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tax_groups; Type: TABLE; Schema: impostos; Owner: -
--

CREATE TABLE impostos.tax_groups (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(20) NOT NULL,
    nome character varying(100) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tax_groups_id_seq; Type: SEQUENCE; Schema: impostos; Owner: -
--

ALTER TABLE impostos.tax_groups ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tax_regimes; Type: TABLE; Schema: impostos; Owner: -
--

CREATE TABLE impostos.tax_regimes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    tipo character varying(20) DEFAULT 'normal'::character varying NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    data_inicio date,
    data_fim date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tax_regimes_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['simplificado'::character varying, 'normal'::character varying, 'isento'::character varying])::text[])))
);


--
-- Name: tax_regimes_id_seq; Type: SEQUENCE; Schema: impostos; Owner: -
--

ALTER TABLE impostos.tax_regimes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_regimes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tax_return_lines; Type: TABLE; Schema: impostos; Owner: -
--

CREATE TABLE impostos.tax_return_lines (
    id bigint NOT NULL,
    tax_return_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    descricao character varying(255) NOT NULL,
    natureza character varying(20) NOT NULL,
    base_imponivel numeric(18,2) DEFAULT 0 NOT NULL,
    taxa numeric(8,4) DEFAULT 0 NOT NULL,
    valor numeric(18,2) DEFAULT 0 NOT NULL,
    referencia_tipo character varying(50),
    referencia_id bigint,
    documento_numero character varying(80),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tax_return_lines_natureza_check CHECK (((natureza)::text = ANY ((ARRAY['debito'::character varying, 'credito'::character varying, 'retencao'::character varying])::text[])))
);


--
-- Name: tax_return_lines_id_seq; Type: SEQUENCE; Schema: impostos; Owner: -
--

ALTER TABLE impostos.tax_return_lines ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_return_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tax_returns; Type: TABLE; Schema: impostos; Owner: -
--

CREATE TABLE impostos.tax_returns (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    periodo character varying(20) NOT NULL,
    tipo character varying(30) NOT NULL,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    total_base numeric(18,2) DEFAULT 0 NOT NULL,
    total_imposto numeric(18,2) DEFAULT 0 NOT NULL,
    total_credito numeric(18,2) DEFAULT 0 NOT NULL,
    total_a_pagar numeric(18,2) DEFAULT 0 NOT NULL,
    data_submissao timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    periodo_inicio date,
    periodo_fim date,
    substitui_id bigint,
    submetida_por bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    total_a_recuperar numeric(18,2) DEFAULT 0 NOT NULL,
    CONSTRAINT tax_returns_status_check CHECK (((status)::text = ANY ((ARRAY['rascunho'::character varying, 'submetida'::character varying, 'paga'::character varying, 'cancelada'::character varying])::text[]))),
    CONSTRAINT tax_returns_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['iva'::character varying, 'irps'::character varying, 'irpc'::character varying, 'retencoes'::character varying])::text[])))
);


--
-- Name: tax_returns_id_seq; Type: SEQUENCE; Schema: impostos; Owner: -
--

ALTER TABLE impostos.tax_returns ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_returns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tax_rules; Type: TABLE; Schema: impostos; Owner: -
--

CREATE TABLE impostos.tax_rules (
    id bigint NOT NULL,
    tax_id bigint NOT NULL,
    valor_minimo numeric(18,2) DEFAULT 0 NOT NULL,
    valor_maximo numeric(18,2),
    taxa numeric(8,4) DEFAULT 0 NOT NULL,
    ordem integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_tax_rules_intervalo CHECK (((valor_maximo IS NULL) OR (valor_maximo > valor_minimo))),
    CONSTRAINT chk_tax_rules_taxa CHECK ((taxa >= (0)::numeric))
);


--
-- Name: tax_rules_id_seq; Type: SEQUENCE; Schema: impostos; Owner: -
--

ALTER TABLE impostos.tax_rules ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tax_transactions; Type: TABLE; Schema: impostos; Owner: -
--

CREATE TABLE impostos.tax_transactions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    tax_id bigint NOT NULL,
    referencia_tipo character varying(30) NOT NULL,
    referencia_id bigint,
    fiscal_period_id bigint,
    base_tributavel numeric(18,2) DEFAULT 0 NOT NULL,
    taxa_aplicada numeric(8,4) DEFAULT 0 NOT NULL,
    valor_imposto numeric(18,2) DEFAULT 0 NOT NULL,
    transaction_date date NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_tax_transactions_base CHECK ((base_tributavel >= (0)::numeric)),
    CONSTRAINT chk_tax_transactions_valor CHECK ((valor_imposto >= (0)::numeric))
);


--
-- Name: tax_transactions_id_seq; Type: SEQUENCE; Schema: impostos; Owner: -
--

ALTER TABLE impostos.tax_transactions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.tax_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: taxes; Type: TABLE; Schema: impostos; Owner: -
--

CREATE TABLE impostos.taxes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    taxa numeric(8,4) DEFAULT 0 NOT NULL,
    tipo character varying(20) DEFAULT 'iva'::character varying NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tax_group_id bigint,
    CONSTRAINT taxes_taxa_check CHECK ((taxa >= (0)::numeric)),
    CONSTRAINT taxes_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['iva'::character varying, 'isento'::character varying, 'zero'::character varying, 'outro'::character varying])::text[])))
);


--
-- Name: taxes_id_seq; Type: SEQUENCE; Schema: impostos; Owner: -
--

ALTER TABLE impostos.taxes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.taxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: withholding_tax_transactions; Type: TABLE; Schema: impostos; Owner: -
--

CREATE TABLE impostos.withholding_tax_transactions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    withholding_tax_id bigint NOT NULL,
    referencia_tipo character varying(50),
    referencia_id bigint,
    base_imponivel numeric(18,2) NOT NULL,
    taxa_aplicada numeric(8,4) NOT NULL,
    valor_retido numeric(18,2) NOT NULL,
    transaction_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entity_type character varying(30),
    entity_id bigint,
    documento_numero character varying(80),
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: withholding_tax_transactions_id_seq; Type: SEQUENCE; Schema: impostos; Owner: -
--

ALTER TABLE impostos.withholding_tax_transactions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.withholding_tax_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: withholding_taxes; Type: TABLE; Schema: impostos; Owner: -
--

CREATE TABLE impostos.withholding_taxes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    taxa numeric(8,4) NOT NULL,
    aplica_em character varying(30) NOT NULL,
    tipo_entidade character varying(30),
    ativo boolean DEFAULT true NOT NULL,
    tipo character varying(10) DEFAULT 'IRPS'::character varying NOT NULL,
    descricao text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT withholding_taxes_aplica_em_check CHECK (((aplica_em)::text = ANY ((ARRAY['pagamento'::character varying, 'fatura'::character varying])::text[]))),
    CONSTRAINT withholding_taxes_taxa_check CHECK ((taxa >= (0)::numeric)),
    CONSTRAINT withholding_taxes_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['IRPS'::character varying, 'IRPC'::character varying])::text[]))),
    CONSTRAINT withholding_taxes_tipo_entidade_check CHECK (((tipo_entidade)::text = ANY ((ARRAY['pessoa_singular'::character varying, 'pessoa_colectiva'::character varying, 'todos'::character varying])::text[])))
);


--
-- Name: withholding_taxes_id_seq; Type: SEQUENCE; Schema: impostos; Owner: -
--

ALTER TABLE impostos.withholding_taxes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME impostos.withholding_taxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: delivery_drivers; Type: TABLE; Schema: logistica; Owner: -
--

CREATE TABLE logistica.delivery_drivers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    nome character varying(150) NOT NULL,
    telefone character varying(30),
    documento character varying(80),
    carta_conducao character varying(80),
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT delivery_drivers_estado_check CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'inactivo'::character varying, 'suspenso'::character varying])::text[])))
);


--
-- Name: delivery_drivers_id_seq; Type: SEQUENCE; Schema: logistica; Owner: -
--

ALTER TABLE logistica.delivery_drivers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.delivery_drivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: delivery_routes; Type: TABLE; Schema: logistica; Owner: -
--

CREATE TABLE logistica.delivery_routes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    nome character varying(150) NOT NULL,
    origem character varying(200) NOT NULL,
    destino character varying(200) NOT NULL,
    distancia_km numeric(12,2),
    duracao_estimada_min integer,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: delivery_routes_id_seq; Type: SEQUENCE; Schema: logistica; Owner: -
--

ALTER TABLE logistica.delivery_routes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.delivery_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: delivery_statuses; Type: TABLE; Schema: logistica; Owner: -
--

CREATE TABLE logistica.delivery_statuses (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    nome character varying(100) NOT NULL,
    ordem integer DEFAULT 0 NOT NULL,
    final boolean DEFAULT false NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: delivery_statuses_id_seq; Type: SEQUENCE; Schema: logistica; Owner: -
--

ALTER TABLE logistica.delivery_statuses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.delivery_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: delivery_tracking; Type: TABLE; Schema: logistica; Owner: -
--

CREATE TABLE logistica.delivery_tracking (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    shipment_id bigint NOT NULL,
    status_id bigint NOT NULL,
    latitude numeric(10,7),
    longitude numeric(10,7),
    localizacao character varying(200),
    observacoes text,
    registado_por bigint,
    registado_em timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: delivery_tracking_id_seq; Type: SEQUENCE; Schema: logistica; Owner: -
--

ALTER TABLE logistica.delivery_tracking ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.delivery_tracking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: delivery_vehicles; Type: TABLE; Schema: logistica; Owner: -
--

CREATE TABLE logistica.delivery_vehicles (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    matricula character varying(30) NOT NULL,
    marca character varying(80),
    modelo character varying(80),
    capacidade_kg numeric(18,2),
    estado character varying(20) DEFAULT 'disponivel'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT delivery_vehicles_estado_check CHECK (((estado)::text = ANY ((ARRAY['disponivel'::character varying, 'em_rota'::character varying, 'manutencao'::character varying, 'inactivo'::character varying])::text[])))
);


--
-- Name: delivery_vehicles_id_seq; Type: SEQUENCE; Schema: logistica; Owner: -
--

ALTER TABLE logistica.delivery_vehicles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.delivery_vehicles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: logistics_drivers; Type: TABLE; Schema: logistica; Owner: -
--

CREATE TABLE logistica.logistics_drivers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    telefone character varying(30),
    carta_numero character varying(50),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: logistics_drivers_id_seq; Type: SEQUENCE; Schema: logistica; Owner: -
--

ALTER TABLE logistica.logistics_drivers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_drivers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: logistics_routes; Type: TABLE; Schema: logistica; Owner: -
--

CREATE TABLE logistica.logistics_routes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    origem character varying(150) NOT NULL,
    destino character varying(150) NOT NULL,
    distancia_km numeric(18,2),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: logistics_routes_id_seq; Type: SEQUENCE; Schema: logistica; Owner: -
--

ALTER TABLE logistica.logistics_routes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: logistics_shipments; Type: TABLE; Schema: logistica; Owner: -
--

CREATE TABLE logistica.logistics_shipments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    source_service character varying(100) NOT NULL,
    source_type character varying(100) NOT NULL,
    source_id bigint NOT NULL,
    logistics_route_id bigint,
    vehicle_id bigint,
    driver_id bigint,
    customer_id bigint,
    delivery_address text,
    scheduled_date date,
    status character varying(20) DEFAULT 'planeada'::character varying NOT NULL,
    observacoes text,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT logistics_shipments_status_check CHECK (((status)::text = ANY ((ARRAY['planeada'::character varying, 'despachada'::character varying, 'em_transito'::character varying, 'entregue'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: logistics_shipments_id_seq; Type: SEQUENCE; Schema: logistica; Owner: -
--

ALTER TABLE logistica.logistics_shipments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_shipments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: logistics_tracking_events; Type: TABLE; Schema: logistica; Owner: -
--

CREATE TABLE logistica.logistics_tracking_events (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    shipment_id bigint NOT NULL,
    evento character varying(30) NOT NULL,
    localizacao character varying(255),
    latitude numeric(10,7),
    longitude numeric(10,7),
    observacoes text,
    event_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT logistics_tracking_events_evento_check CHECK (((evento)::text = ANY ((ARRAY['planeado'::character varying, 'despachado'::character varying, 'em_transito'::character varying, 'entregue'::character varying, 'falha_entrega'::character varying, 'cancelado'::character varying])::text[])))
);


--
-- Name: logistics_tracking_events_id_seq; Type: SEQUENCE; Schema: logistica; Owner: -
--

ALTER TABLE logistica.logistics_tracking_events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_tracking_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: logistics_vehicles; Type: TABLE; Schema: logistica; Owner: -
--

CREATE TABLE logistica.logistics_vehicles (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    matricula character varying(30) NOT NULL,
    descricao character varying(150),
    capacidade_kg numeric(18,2),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: logistics_vehicles_id_seq; Type: SEQUENCE; Schema: logistica; Owner: -
--

ALTER TABLE logistica.logistics_vehicles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.logistics_vehicles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: shipment_items; Type: TABLE; Schema: logistica; Owner: -
--

CREATE TABLE logistica.shipment_items (
    id bigint NOT NULL,
    shipment_id bigint NOT NULL,
    product_id bigint,
    descricao character varying(255) NOT NULL,
    quantidade numeric(18,4) NOT NULL,
    peso_kg numeric(18,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT shipment_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);


--
-- Name: shipment_items_id_seq; Type: SEQUENCE; Schema: logistica; Owner: -
--

ALTER TABLE logistica.shipment_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.shipment_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: shipments; Type: TABLE; Schema: logistica; Owner: -
--

CREATE TABLE logistica.shipments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(60) NOT NULL,
    reference_type character varying(60),
    reference_id bigint,
    customer_id bigint,
    route_id bigint,
    driver_id bigint,
    vehicle_id bigint,
    status_id bigint,
    endereco_entrega text NOT NULL,
    contacto_entrega character varying(120),
    data_prevista timestamp with time zone,
    data_entrega timestamp with time zone,
    observacoes text,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: shipments_id_seq; Type: SEQUENCE; Schema: logistica; Owner: -
--

ALTER TABLE logistica.shipments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logistica.shipments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: currencies; Type: TABLE; Schema: multi_moeda; Owner: -
--

CREATE TABLE multi_moeda.currencies (
    id bigint NOT NULL,
    code character varying(10) NOT NULL,
    name character varying(100) NOT NULL,
    symbol character varying(10),
    decimals integer DEFAULT 2 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT currencies_decimals_check CHECK (((decimals >= 0) AND (decimals <= 6)))
);


--
-- Name: currencies_id_seq; Type: SEQUENCE; Schema: multi_moeda; Owner: -
--

ALTER TABLE multi_moeda.currencies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME multi_moeda.currencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: exchange_rates; Type: TABLE; Schema: multi_moeda; Owner: -
--

CREATE TABLE multi_moeda.exchange_rates (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    base_currency_id bigint NOT NULL,
    quote_currency_id bigint NOT NULL,
    rate numeric(18,6) NOT NULL,
    source character varying(50) DEFAULT 'manual'::character varying NOT NULL,
    effective_date date DEFAULT CURRENT_DATE NOT NULL,
    is_official boolean DEFAULT false NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_exchange_rate_pair CHECK ((base_currency_id <> quote_currency_id)),
    CONSTRAINT exchange_rates_rate_check CHECK ((rate > (0)::numeric))
);


--
-- Name: exchange_rates_id_seq; Type: SEQUENCE; Schema: multi_moeda; Owner: -
--

ALTER TABLE multi_moeda.exchange_rates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME multi_moeda.exchange_rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tenant_currencies; Type: TABLE; Schema: multi_moeda; Owner: -
--

CREATE TABLE multi_moeda.tenant_currencies (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    currency_id bigint NOT NULL,
    is_base boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tenant_currencies_id_seq; Type: SEQUENCE; Schema: multi_moeda; Owner: -
--

ALTER TABLE multi_moeda.tenant_currencies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME multi_moeda.tenant_currencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notification_channels; Type: TABLE; Schema: notifications; Owner: -
--

CREATE TABLE notifications.notification_channels (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    tipo character varying(20) NOT NULL,
    configuracao jsonb,
    activo boolean DEFAULT true NOT NULL,
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT notification_channels_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['email'::character varying, 'sms'::character varying, 'whatsapp'::character varying, 'push'::character varying])::text[])))
);


--
-- Name: notification_channels_id_seq; Type: SEQUENCE; Schema: notifications; Owner: -
--

ALTER TABLE notifications.notification_channels ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME notifications.notification_channels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notification_messages; Type: TABLE; Schema: notifications; Owner: -
--

CREATE TABLE notifications.notification_messages (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    channel_id bigint,
    template_id bigint,
    canal_tipo character varying(20) NOT NULL,
    destinatario character varying(180) NOT NULL,
    assunto character varying(150),
    corpo text NOT NULL,
    payload jsonb,
    referencia_tipo character varying(50),
    referencia_id bigint,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    tentativas integer DEFAULT 0 NOT NULL,
    erro text,
    enviado_em timestamp with time zone,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT notification_messages_canal_tipo_check CHECK (((canal_tipo)::text = ANY ((ARRAY['email'::character varying, 'sms'::character varying, 'whatsapp'::character varying, 'push'::character varying])::text[]))),
    CONSTRAINT notification_messages_status_check CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'enviado'::character varying, 'falha'::character varying, 'cancelado'::character varying])::text[])))
);


--
-- Name: notification_messages_id_seq; Type: SEQUENCE; Schema: notifications; Owner: -
--

ALTER TABLE notifications.notification_messages ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME notifications.notification_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notification_templates; Type: TABLE; Schema: notifications; Owner: -
--

CREATE TABLE notifications.notification_templates (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    canal_tipo character varying(20) NOT NULL,
    assunto character varying(150),
    corpo text NOT NULL,
    variaveis jsonb,
    activo boolean DEFAULT true NOT NULL,
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT notification_templates_canal_tipo_check CHECK (((canal_tipo)::text = ANY ((ARRAY['email'::character varying, 'sms'::character varying, 'whatsapp'::character varying, 'push'::character varying])::text[])))
);


--
-- Name: notification_templates_id_seq; Type: SEQUENCE; Schema: notifications; Owner: -
--

ALTER TABLE notifications.notification_templates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME notifications.notification_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pos_catalog_items; Type: TABLE; Schema: pos; Owner: -
--

CREATE TABLE pos.pos_catalog_items (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_variant_id bigint,
    codigo_barra character varying(80),
    preco_venda numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: pos_catalog_items_id_seq; Type: SEQUENCE; Schema: pos; Owner: -
--

ALTER TABLE pos.pos_catalog_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos.pos_catalog_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pos_sale_items; Type: TABLE; Schema: pos; Owner: -
--

CREATE TABLE pos.pos_sale_items (
    id bigint NOT NULL,
    pos_sale_id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_variant_id bigint,
    descricao character varying(255),
    quantidade numeric(18,2) NOT NULL,
    preco_unitario numeric(18,2) NOT NULL,
    desconto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_valor numeric(18,2) DEFAULT 0 NOT NULL,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pos_sale_items_preco_unitario_check CHECK ((preco_unitario >= (0)::numeric)),
    CONSTRAINT pos_sale_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);


--
-- Name: pos_sale_items_id_seq; Type: SEQUENCE; Schema: pos; Owner: -
--

ALTER TABLE pos.pos_sale_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos.pos_sale_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pos_sale_payments; Type: TABLE; Schema: pos; Owner: -
--

CREATE TABLE pos.pos_sale_payments (
    id bigint NOT NULL,
    pos_sale_id bigint NOT NULL,
    payment_method_id bigint,
    tipo character varying(20) NOT NULL,
    valor numeric(18,2) NOT NULL,
    referencia character varying(100),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pos_sale_payments_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['numerario'::character varying, 'transferencia'::character varying, 'tpa'::character varying, 'mpesa'::character varying, 'emola'::character varying, 'outro'::character varying])::text[]))),
    CONSTRAINT pos_sale_payments_valor_check CHECK ((valor > (0)::numeric))
);


--
-- Name: pos_sale_payments_id_seq; Type: SEQUENCE; Schema: pos; Owner: -
--

ALTER TABLE pos.pos_sale_payments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos.pos_sale_payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pos_sales; Type: TABLE; Schema: pos; Owner: -
--

CREATE TABLE pos.pos_sales (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    pos_session_id bigint NOT NULL,
    terminal_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    customer_id bigint,
    subtotal numeric(18,2) DEFAULT 0 NOT NULL,
    desconto_total numeric(18,2) DEFAULT 0 NOT NULL,
    imposto_total numeric(18,2) DEFAULT 0 NOT NULL,
    total numeric(18,2) DEFAULT 0 NOT NULL,
    valor_recebido numeric(18,2) DEFAULT 0 NOT NULL,
    troco numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    status character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    sold_at timestamp with time zone,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pos_sales_status_check CHECK (((status)::text = ANY ((ARRAY['rascunho'::character varying, 'concluida'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: pos_sales_id_seq; Type: SEQUENCE; Schema: pos; Owner: -
--

ALTER TABLE pos.pos_sales ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos.pos_sales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pos_sessions; Type: TABLE; Schema: pos; Owner: -
--

CREATE TABLE pos.pos_sessions (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    terminal_id bigint NOT NULL,
    user_id bigint NOT NULL,
    opened_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    closed_at timestamp with time zone,
    opening_amount numeric(18,2) DEFAULT 0 NOT NULL,
    closing_amount numeric(18,2),
    status character varying(20) DEFAULT 'aberta'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pos_sessions_status_check CHECK (((status)::text = ANY ((ARRAY['aberta'::character varying, 'fechada'::character varying])::text[])))
);


--
-- Name: pos_sessions_id_seq; Type: SEQUENCE; Schema: pos; Owner: -
--

ALTER TABLE pos.pos_sessions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos.pos_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pos_terminals; Type: TABLE; Schema: pos; Owner: -
--

CREATE TABLE pos.pos_terminals (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    warehouse_id bigint,
    caixa_id bigint,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: pos_terminals_id_seq; Type: SEQUENCE; Schema: pos; Owner: -
--

ALTER TABLE pos.pos_terminals ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pos.pos_terminals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_attribute_values; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_attribute_values (
    id bigint NOT NULL,
    product_attribute_id bigint NOT NULL,
    product_id bigint,
    product_variant_id bigint,
    valor character varying(150) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: product_attribute_values_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_attribute_values ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_attribute_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_attributes; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_attributes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(100) NOT NULL,
    tipo character varying(30) DEFAULT 'texto'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT product_attributes_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['texto'::character varying, 'numero'::character varying, 'lista'::character varying, 'booleano'::character varying, 'cor'::character varying])::text[])))
);


--
-- Name: product_attributes_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_attributes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_barcodes; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_barcodes (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_variant_id bigint,
    barcode character varying(100) NOT NULL,
    tipo character varying(30),
    principal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: product_barcodes_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_barcodes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_barcodes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_brands; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_brands (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(100) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: product_brands_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_brands ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_brands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_categories; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_categories (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    parent_id bigint,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: product_categories_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_categories ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_discounts; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_discounts (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_variant_id bigint,
    tipo character varying(20) NOT NULL,
    valor numeric(18,2) NOT NULL,
    motivo character varying(150),
    inicia_em timestamp with time zone,
    fim_em timestamp with time zone,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT product_discounts_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['percentual'::character varying, 'valor_fixo'::character varying])::text[]))),
    CONSTRAINT product_discounts_valor_check CHECK ((valor >= (0)::numeric))
);


--
-- Name: product_discounts_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_discounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_discounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_images; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_images (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    ficheiro_url text NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    ordem integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: product_images_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_images ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_kit_items; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_kit_items (
    id bigint NOT NULL,
    product_kit_id bigint NOT NULL,
    item_product_id bigint NOT NULL,
    item_variant_id bigint,
    quantidade numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT product_kit_items_quantidade_check CHECK ((quantidade > (0)::numeric))
);


--
-- Name: product_kit_items_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_kit_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_kit_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_kits; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_kits (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(150) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: product_kits_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_kits ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_kits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_prices; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_prices (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_variant_id bigint,
    tipo_preco character varying(30) DEFAULT 'venda'::character varying NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    valor numeric(18,2) NOT NULL,
    inicia_em timestamp with time zone,
    fim_em timestamp with time zone,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT product_prices_tipo_preco_check CHECK (((tipo_preco)::text = ANY ((ARRAY['custo'::character varying, 'venda'::character varying, 'atacado'::character varying, 'promocional'::character varying])::text[]))),
    CONSTRAINT product_prices_valor_check CHECK ((valor >= (0)::numeric))
);


--
-- Name: product_prices_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_prices ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_subcategories; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_subcategories (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    product_category_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: product_subcategories_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_subcategories ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_subcategories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_tag_links; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_tag_links (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_tag_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: product_tag_links_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_tag_links ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_tag_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_tags; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_tags (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(100) NOT NULL,
    cor character varying(20),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: product_tags_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_tags ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_units; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_units (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(80) NOT NULL,
    simbolo character varying(20),
    casas_decimais integer DEFAULT 2 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: product_units_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_units ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_units_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: product_variants; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.product_variants (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    codigo character varying(50),
    nome character varying(150) NOT NULL,
    sku character varying(80),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: product_variants_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.product_variants ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.product_variants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: products; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.products (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    product_category_id bigint,
    product_subcategory_id bigint,
    product_brand_id bigint,
    product_unit_id bigint,
    warehouse_default_id bigint,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    descricao text,
    tipo character varying(30) DEFAULT 'simples'::character varying NOT NULL,
    iva_percentual numeric(5,2) DEFAULT 17.00 NOT NULL,
    stock_minimo numeric(18,2) DEFAULT 0 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT products_iva_percentual_check CHECK ((iva_percentual >= (0)::numeric)),
    CONSTRAINT products_stock_minimo_check CHECK ((stock_minimo >= (0)::numeric)),
    CONSTRAINT products_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['simples'::character varying, 'variavel'::character varying, 'kit'::character varying, 'servico'::character varying])::text[])))
);


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.products ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: warehouses; Type: TABLE; Schema: produtos; Owner: -
--

CREATE TABLE produtos.warehouses (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    localizacao character varying(255),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: warehouses_id_seq; Type: SEQUENCE; Schema: produtos; Owner: -
--

ALTER TABLE produtos.warehouses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME produtos.warehouses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: chat_conversas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_conversas (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(200),
    tipo character varying(20) DEFAULT 'individual'::character varying NOT NULL,
    criado_por bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chat_conversas_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['individual'::character varying, 'grupo'::character varying])::text[])))
);


--
-- Name: chat_conversas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_conversas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_conversas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_conversas_id_seq OWNED BY public.chat_conversas.id;


--
-- Name: chat_mensagens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_mensagens (
    id bigint NOT NULL,
    conversa_id bigint NOT NULL,
    autor_id bigint,
    conteudo text NOT NULL,
    tipo character varying(20) DEFAULT 'texto'::character varying NOT NULL,
    ficheiro_url character varying(500),
    eliminada boolean DEFAULT false NOT NULL,
    editada_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chat_mensagens_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['texto'::character varying, 'imagem'::character varying, 'ficheiro'::character varying])::text[])))
);


--
-- Name: chat_mensagens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_mensagens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_mensagens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_mensagens_id_seq OWNED BY public.chat_mensagens.id;


--
-- Name: chat_participantes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_participantes (
    conversa_id bigint NOT NULL,
    user_id bigint NOT NULL,
    adicionado_em timestamp with time zone DEFAULT now() NOT NULL,
    ultima_leitura timestamp with time zone
);


--
-- Name: comunicados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comunicados (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    titulo character varying(300) NOT NULL,
    conteudo text NOT NULL,
    autor_id bigint,
    expira_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: comunicados_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comunicados_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comunicados_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comunicados_id_seq OWNED BY public.comunicados.id;


--
-- Name: comunicados_lidos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comunicados_lidos (
    comunicado_id bigint NOT NULL,
    user_id bigint NOT NULL,
    lido_em timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: notif_colaborador; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notif_colaborador (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    user_id bigint NOT NULL,
    tipo character varying(50) NOT NULL,
    titulo character varying(300) NOT NULL,
    corpo text,
    lida boolean DEFAULT false NOT NULL,
    link character varying(500),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: notif_colaborador_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notif_colaborador_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notif_colaborador_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notif_colaborador_id_seq OWNED BY public.notif_colaborador.id;


--
-- Name: candidatura_notas; Type: TABLE; Schema: recrutamento; Owner: -
--

CREATE TABLE recrutamento.candidatura_notas (
    id bigint NOT NULL,
    candidatura_id bigint NOT NULL,
    autor character varying(100) DEFAULT 'admin'::character varying NOT NULL,
    tipo character varying(20) DEFAULT 'nota'::character varying NOT NULL,
    conteudo text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT candidatura_notas_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['nota'::character varying, 'entrevista'::character varying, 'avaliacao'::character varying, 'sistema'::character varying])::text[])))
);


--
-- Name: candidatura_notas_id_seq; Type: SEQUENCE; Schema: recrutamento; Owner: -
--

ALTER TABLE recrutamento.candidatura_notas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recrutamento.candidatura_notas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: candidaturas; Type: TABLE; Schema: recrutamento; Owner: -
--

CREATE TABLE recrutamento.candidaturas (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    vaga_id bigint,
    nome character varying(150) NOT NULL,
    email character varying(255) NOT NULL,
    telefone character varying(30),
    vaga_titulo character varying(200) NOT NULL,
    carta text,
    cv_ficheiro character varying(255),
    carta_ficheiro character varying(255),
    ip character varying(45) NOT NULL,
    estado character varying(20) DEFAULT 'recebida'::character varying NOT NULL,
    score smallint,
    responsavel character varying(100),
    entrevista_data timestamp with time zone,
    entrevista_local character varying(200),
    entrevista_link character varying(300),
    entrevista_notas text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT candidaturas_estado_check CHECK (((estado)::text = ANY ((ARRAY['recebida'::character varying, 'em_analise'::character varying, 'entrevista'::character varying, 'aprovada'::character varying, 'rejeitada'::character varying])::text[]))),
    CONSTRAINT candidaturas_score_check CHECK (((score >= 1) AND (score <= 5)))
);


--
-- Name: candidaturas_id_seq; Type: SEQUENCE; Schema: recrutamento; Owner: -
--

ALTER TABLE recrutamento.candidaturas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recrutamento.candidaturas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: contactos; Type: TABLE; Schema: recrutamento; Owner: -
--

CREATE TABLE recrutamento.contactos (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    email character varying(255) NOT NULL,
    assunto character varying(255) NOT NULL,
    mensagem text NOT NULL,
    ip character varying(45) NOT NULL,
    lido boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: contactos_id_seq; Type: SEQUENCE; Schema: recrutamento; Owner: -
--

ALTER TABLE recrutamento.contactos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recrutamento.contactos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: vagas; Type: TABLE; Schema: recrutamento; Owner: -
--

CREATE TABLE recrutamento.vagas (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    titulo character varying(200) NOT NULL,
    area character varying(100) NOT NULL,
    local character varying(100) DEFAULT 'Maputo, Mocambique'::character varying NOT NULL,
    regime character varying(50) DEFAULT 'Presencial / Hibrido'::character varying NOT NULL,
    tipo character varying(50) DEFAULT 'Estagio'::character varying NOT NULL,
    descricao text NOT NULL,
    sobre_funcao text,
    responsabilidades jsonb DEFAULT '[]'::jsonb NOT NULL,
    req_obrigatorios jsonb DEFAULT '[]'::jsonb NOT NULL,
    req_preferenciais jsonb DEFAULT '[]'::jsonb NOT NULL,
    oferece jsonb DEFAULT '[]'::jsonb NOT NULL,
    ativa boolean DEFAULT true NOT NULL,
    num_vagas smallint DEFAULT 1 NOT NULL,
    prazo date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT vagas_num_vagas_check CHECK ((num_vagas > 0))
);


--
-- Name: vagas_id_seq; Type: SEQUENCE; Schema: recrutamento; Owner: -
--

ALTER TABLE recrutamento.vagas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recrutamento.vagas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: employee_bank_accounts; Type: TABLE; Schema: recursos_humanos; Owner: -
--

CREATE TABLE recursos_humanos.employee_bank_accounts (
    id bigint NOT NULL,
    employee_id bigint NOT NULL,
    banco character varying(120) NOT NULL,
    numero_conta character varying(60) NOT NULL,
    nib character varying(60),
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    principal boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: employee_bank_accounts_id_seq; Type: SEQUENCE; Schema: recursos_humanos; Owner: -
--

ALTER TABLE recursos_humanos.employee_bank_accounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recursos_humanos.employee_bank_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: employees; Type: TABLE; Schema: recursos_humanos; Owner: -
--

CREATE TABLE recursos_humanos.employees (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    department_id bigint,
    user_id bigint,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    email character varying(150),
    telefone character varying(30),
    nuit character varying(30),
    data_nascimento date,
    data_admissao date NOT NULL,
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    cargo character varying(120) NOT NULL,
    tipo_contrato character varying(20) DEFAULT 'efectivo'::character varying NOT NULL,
    salario_base numeric(18,2) DEFAULT 0 NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT employees_estado_check CHECK (((estado)::text = ANY ((ARRAY['ativo'::character varying, 'suspenso'::character varying, 'desligado'::character varying])::text[]))),
    CONSTRAINT employees_salario_base_check CHECK ((salario_base >= (0)::numeric)),
    CONSTRAINT employees_tipo_contrato_check CHECK (((tipo_contrato)::text = ANY ((ARRAY['efectivo'::character varying, 'prazo_certo'::character varying, 'prestador'::character varying, 'estagiario'::character varying])::text[])))
);


--
-- Name: employees_id_seq; Type: SEQUENCE; Schema: recursos_humanos; Owner: -
--

ALTER TABLE recursos_humanos.employees ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recursos_humanos.employees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: hr_departments; Type: TABLE; Schema: recursos_humanos; Owner: -
--

CREATE TABLE recursos_humanos.hr_departments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: hr_departments_id_seq; Type: SEQUENCE; Schema: recursos_humanos; Owner: -
--

ALTER TABLE recursos_humanos.hr_departments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recursos_humanos.hr_departments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: payroll_periods; Type: TABLE; Schema: recursos_humanos; Owner: -
--

CREATE TABLE recursos_humanos.payroll_periods (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    ano integer NOT NULL,
    mes integer NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    status character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    fechado_em timestamp with time zone,
    fechado_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT payroll_periods_mes_check CHECK (((mes >= 1) AND (mes <= 12))),
    CONSTRAINT payroll_periods_status_check CHECK (((status)::text = ANY ((ARRAY['aberto'::character varying, 'fechado'::character varying])::text[])))
);


--
-- Name: payroll_periods_id_seq; Type: SEQUENCE; Schema: recursos_humanos; Owner: -
--

ALTER TABLE recursos_humanos.payroll_periods ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recursos_humanos.payroll_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: payroll_run_lines; Type: TABLE; Schema: recursos_humanos; Owner: -
--

CREATE TABLE recursos_humanos.payroll_run_lines (
    id bigint NOT NULL,
    payroll_run_id bigint NOT NULL,
    employee_id bigint NOT NULL,
    salario_base numeric(18,2) DEFAULT 0 NOT NULL,
    adicionais numeric(18,2) DEFAULT 0 NOT NULL,
    descontos numeric(18,2) DEFAULT 0 NOT NULL,
    bruto numeric(18,2) DEFAULT 0 NOT NULL,
    liquido numeric(18,2) DEFAULT 0 NOT NULL,
    observacoes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: payroll_run_lines_id_seq; Type: SEQUENCE; Schema: recursos_humanos; Owner: -
--

ALTER TABLE recursos_humanos.payroll_run_lines ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recursos_humanos.payroll_run_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: payroll_runs; Type: TABLE; Schema: recursos_humanos; Owner: -
--

CREATE TABLE recursos_humanos.payroll_runs (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    payroll_period_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    processamento_em date DEFAULT CURRENT_DATE NOT NULL,
    status character varying(20) DEFAULT 'processado'::character varying NOT NULL,
    total_bruto numeric(18,2) DEFAULT 0 NOT NULL,
    total_descontos numeric(18,2) DEFAULT 0 NOT NULL,
    total_liquido numeric(18,2) DEFAULT 0 NOT NULL,
    criado_por bigint,
    aprovado_por bigint,
    aprovado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT payroll_runs_status_check CHECK (((status)::text = ANY ((ARRAY['processado'::character varying, 'aprovado'::character varying, 'cancelado'::character varying])::text[])))
);


--
-- Name: payroll_runs_id_seq; Type: SEQUENCE; Schema: recursos_humanos; Owner: -
--

ALTER TABLE recursos_humanos.payroll_runs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME recursos_humanos.payroll_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: ausencias; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.ausencias (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    tipo character varying(30),
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    dias integer,
    motivo text,
    estado character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    aprovado_por bigint,
    aprovado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tipo_id bigint,
    CONSTRAINT ausencias_estado_check CHECK (((estado)::text = ANY ((ARRAY['pendente'::character varying, 'aprovado'::character varying, 'rejeitado'::character varying, 'gozada'::character varying, 'cancelada'::character varying])::text[]))),
    CONSTRAINT ausencias_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['ferias'::character varying, 'doenca'::character varying, 'licenca_maternidade'::character varying, 'licenca_paternidade'::character varying, 'luto'::character varying, 'injustificada'::character varying, 'outro'::character varying])::text[])))
);


--
-- Name: ausencias_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.ausencias ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.ausencias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: avaliacao_criterios; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.avaliacao_criterios (
    id bigint NOT NULL,
    avaliacao_id bigint NOT NULL,
    criterio_id bigint NOT NULL,
    pontuacao numeric(4,2) NOT NULL
);


--
-- Name: avaliacao_criterios_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.avaliacao_criterios ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.avaliacao_criterios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: avaliacoes; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.avaliacoes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    periodo character varying(30),
    avaliador_id bigint,
    pontuacao numeric(4,2),
    comentarios text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    periodo_id bigint,
    estado character varying(20) DEFAULT 'rascunho'::character varying NOT NULL,
    aprovado_por bigint,
    aprovado_em timestamp with time zone,
    CONSTRAINT avaliacoes_estado_check CHECK (((estado)::text = ANY ((ARRAY['rascunho'::character varying, 'submetida'::character varying, 'aprovada'::character varying])::text[])))
);


--
-- Name: avaliacoes_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.avaliacoes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.avaliacoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: beneficios; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.beneficios (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    valor_padrao numeric(14,2),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: beneficios_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.beneficios ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.beneficios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cargos; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.cargos (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    salario_min numeric(14,2),
    salario_max numeric(14,2),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: cargos_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.cargos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.cargos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: componentes_salariais; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.componentes_salariais (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    tipo character varying(20) NOT NULL,
    forma_calculo character varying(20) DEFAULT 'fixo'::character varying NOT NULL,
    valor_padrao numeric(14,2),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT componentes_salariais_forma_calculo_check CHECK (((forma_calculo)::text = ANY ((ARRAY['fixo'::character varying, 'percentual'::character varying])::text[]))),
    CONSTRAINT componentes_salariais_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['provento'::character varying, 'desconto'::character varying])::text[])))
);


--
-- Name: componentes_salariais_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.componentes_salariais ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.componentes_salariais_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: contactos_emergencia; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.contactos_emergencia (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    nome character varying(150) NOT NULL,
    parentesco character varying(50),
    telefone character varying(30) NOT NULL,
    email character varying(150),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: contactos_emergencia_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.contactos_emergencia ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.contactos_emergencia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: contratos; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.contratos (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    funcao character varying(120),
    data_inicio date NOT NULL,
    data_fim date,
    salario numeric(14,2),
    ficheiro_url text,
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT contratos_estado_check CHECK (((estado)::text = ANY ((ARRAY['ativo'::character varying, 'encerrado'::character varying, 'rescindido'::character varying])::text[]))),
    CONSTRAINT contratos_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['efetivo'::character varying, 'termo_certo'::character varying, 'termo_incerto'::character varying, 'estagio'::character varying, 'prestacao_servico'::character varying])::text[])))
);


--
-- Name: contratos_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.contratos ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.contratos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: criterios_avaliacao; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.criterios_avaliacao (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    peso numeric(5,2) DEFAULT 1 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: criterios_avaliacao_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.criterios_avaliacao ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.criterios_avaliacao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: unidades_organizacionais; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.unidades_organizacionais (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(120) NOT NULL,
    descricao text,
    responsavel_id bigint,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tipo character varying(30) DEFAULT 'departamento'::character varying NOT NULL,
    parent_id bigint,
    CONSTRAINT unidades_organizacionais_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['departamento'::character varying, 'equipa'::character varying, 'divisao'::character varying, 'seccao'::character varying, 'direccao'::character varying, 'gabinete'::character varying, 'projeto'::character varying, 'outro'::character varying])::text[])))
);


--
-- Name: departamentos_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.unidades_organizacionais ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.departamentos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: documentos_funcionario; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.documentos_funcionario (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    numero character varying(60),
    data_emissao date,
    data_validade date,
    ficheiro_url text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: documentos_funcionario_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.documentos_funcionario ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.documentos_funcionario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: folhas_pagamento; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.folhas_pagamento (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    ano integer NOT NULL,
    mes integer NOT NULL,
    estado character varying(20) DEFAULT 'aberta'::character varying NOT NULL,
    num_funcionarios integer DEFAULT 0 NOT NULL,
    total_proventos numeric(14,2) DEFAULT 0 NOT NULL,
    total_descontos numeric(14,2) DEFAULT 0 NOT NULL,
    total_liquido numeric(14,2) DEFAULT 0 NOT NULL,
    processada_em timestamp with time zone,
    processada_por bigint,
    paga_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT folhas_pagamento_estado_check CHECK (((estado)::text = ANY ((ARRAY['aberta'::character varying, 'processada'::character varying, 'paga'::character varying, 'cancelada'::character varying])::text[]))),
    CONSTRAINT folhas_pagamento_mes_check CHECK (((mes >= 1) AND (mes <= 12)))
);


--
-- Name: folhas_pagamento_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.folhas_pagamento ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.folhas_pagamento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: formacoes; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.formacoes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(150) NOT NULL,
    descricao text,
    categoria character varying(20) DEFAULT 'tecnica'::character varying NOT NULL,
    duracao_horas numeric(6,2),
    entidade_formadora character varying(150),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT formacoes_categoria_check CHECK (((categoria)::text = ANY ((ARRAY['tecnica'::character varying, 'comportamental'::character varying, 'obrigatoria'::character varying, 'outra'::character varying])::text[])))
);


--
-- Name: formacoes_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.formacoes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.formacoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: funcionario_beneficios; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.funcionario_beneficios (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    beneficio_id bigint NOT NULL,
    valor numeric(14,2),
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    observacoes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: funcionario_beneficios_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.funcionario_beneficios ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.funcionario_beneficios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: funcionario_componentes_salariais; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.funcionario_componentes_salariais (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    componente_id bigint NOT NULL,
    valor numeric(14,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: funcionario_componentes_salariais_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.funcionario_componentes_salariais ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.funcionario_componentes_salariais_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: funcionario_formacoes; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.funcionario_formacoes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    formacao_id bigint NOT NULL,
    data_inicio date NOT NULL,
    data_fim date,
    estado character varying(20) DEFAULT 'planeada'::character varying NOT NULL,
    nota numeric(4,2),
    certificado_url text,
    observacoes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT funcionario_formacoes_estado_check CHECK (((estado)::text = ANY ((ARRAY['planeada'::character varying, 'em_curso'::character varying, 'concluida'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: funcionario_formacoes_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.funcionario_formacoes ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.funcionario_formacoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: funcionarios; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.funcionarios (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    unit_id bigint,
    numero_funcionario character varying(30),
    nome_completo character varying(150) NOT NULL,
    data_nascimento date,
    genero character varying(10),
    nuit character varying(30),
    telefone character varying(30),
    email character varying(150),
    endereco text,
    cargo character varying(120),
    data_admissao date DEFAULT CURRENT_DATE NOT NULL,
    data_saida date,
    tipo_contrato character varying(30) DEFAULT 'efetivo'::character varying NOT NULL,
    salario_base numeric(14,2),
    estado character varying(20) DEFAULT 'ativo'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    user_id bigint,
    cargo_id bigint,
    horario_id bigint,
    provincia character varying(60),
    cidade character varying(60),
    bairro character varying(100),
    CONSTRAINT funcionarios_estado_check CHECK (((estado)::text = ANY ((ARRAY['ativo'::character varying, 'suspenso'::character varying, 'licenca'::character varying, 'desligado'::character varying])::text[]))),
    CONSTRAINT funcionarios_genero_check CHECK (((genero)::text = ANY ((ARRAY['M'::character varying, 'F'::character varying, 'outro'::character varying])::text[]))),
    CONSTRAINT funcionarios_tipo_contrato_check CHECK (((tipo_contrato)::text = ANY ((ARRAY['efetivo'::character varying, 'termo_certo'::character varying, 'termo_incerto'::character varying, 'estagio'::character varying, 'prestacao_servico'::character varying])::text[])))
);


--
-- Name: funcionarios_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.funcionarios ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.funcionarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: historico_salarial; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.historico_salarial (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    salario_anterior numeric(14,2),
    salario_novo numeric(14,2) NOT NULL,
    data_efectiva date NOT NULL,
    motivo text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: historico_salarial_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.historico_salarial ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.historico_salarial_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: horarios_trabalho; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.horarios_trabalho (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    hora_entrada character varying(5) NOT NULL,
    hora_saida character varying(5) NOT NULL,
    intervalo_inicio character varying(5),
    intervalo_fim character varying(5),
    dias_semana character varying(20) DEFAULT '1,2,3,4,5'::character varying NOT NULL,
    carga_semanal_horas numeric(5,2),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: horarios_trabalho_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.horarios_trabalho ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.horarios_trabalho_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: justificacoes; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.justificacoes (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    tipo character varying(20) DEFAULT 'falta'::character varying NOT NULL,
    data date NOT NULL,
    motivo text NOT NULL,
    estado character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    ficheiro_url character varying(500),
    aprovado_por bigint,
    aprovado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT justificacoes_estado_check CHECK (((estado)::text = ANY ((ARRAY['pendente'::character varying, 'aprovado'::character varying, 'rejeitado'::character varying])::text[]))),
    CONSTRAINT justificacoes_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['falta'::character varying, 'atraso'::character varying])::text[])))
);


--
-- Name: justificacoes_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

CREATE SEQUENCE rh.justificacoes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: justificacoes_id_seq; Type: SEQUENCE OWNED BY; Schema: rh; Owner: -
--

ALTER SEQUENCE rh.justificacoes_id_seq OWNED BY rh.justificacoes.id;


--
-- Name: periodos_avaliacao; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.periodos_avaliacao (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(60) NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    estado character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT periodos_avaliacao_estado_check CHECK (((estado)::text = ANY ((ARRAY['aberto'::character varying, 'encerrado'::character varying])::text[])))
);


--
-- Name: periodos_avaliacao_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.periodos_avaliacao ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.periodos_avaliacao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: presencas; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.presencas (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    data date NOT NULL,
    hora_entrada character varying(5),
    hora_saida character varying(5),
    horas_extra numeric(5,2) DEFAULT 0 NOT NULL,
    observacoes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    latitude numeric(10,7),
    longitude numeric(10,7),
    observacao text,
    tipo character varying(20) DEFAULT 'presente'::character varying,
    CONSTRAINT presencas_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['presente'::character varying, 'atraso'::character varying, 'falta'::character varying, 'saida_antecipada'::character varying])::text[])))
);


--
-- Name: presencas_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.presencas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.presencas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: processos_disciplinares; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.processos_disciplinares (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    motivo text NOT NULL,
    descricao text,
    data_ocorrencia date NOT NULL,
    data_abertura date DEFAULT CURRENT_DATE NOT NULL,
    estado character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    decisao text,
    data_decisao date,
    aberto_por bigint,
    decidido_por bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT processos_disciplinares_estado_check CHECK (((estado)::text = ANY ((ARRAY['aberto'::character varying, 'em_analise'::character varying, 'decidido'::character varying, 'arquivado'::character varying])::text[]))),
    CONSTRAINT processos_disciplinares_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['advertencia_verbal'::character varying, 'advertencia_escrita'::character varying, 'suspensao'::character varying, 'despedimento'::character varying, 'outro'::character varying])::text[])))
);


--
-- Name: processos_disciplinares_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.processos_disciplinares ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.processos_disciplinares_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: recibo_vencimento_itens; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.recibo_vencimento_itens (
    id bigint NOT NULL,
    recibo_id bigint NOT NULL,
    componente_id bigint,
    nome character varying(100) NOT NULL,
    tipo character varying(20) NOT NULL,
    valor numeric(14,2) NOT NULL,
    CONSTRAINT recibo_vencimento_itens_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['provento'::character varying, 'desconto'::character varying])::text[])))
);


--
-- Name: recibo_vencimento_itens_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.recibo_vencimento_itens ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.recibo_vencimento_itens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: recibos_vencimento; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.recibos_vencimento (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    folha_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    salario_base numeric(14,2) DEFAULT 0 NOT NULL,
    total_proventos numeric(14,2) DEFAULT 0 NOT NULL,
    total_descontos numeric(14,2) DEFAULT 0 NOT NULL,
    salario_liquido numeric(14,2) DEFAULT 0 NOT NULL,
    estado character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT recibos_vencimento_estado_check CHECK (((estado)::text = ANY ((ARRAY['pendente'::character varying, 'pago'::character varying])::text[])))
);


--
-- Name: recibos_vencimento_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.recibos_vencimento ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.recibos_vencimento_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: saldos_ausencia; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.saldos_ausencia (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    funcionario_id bigint NOT NULL,
    tipo_ausencia_id bigint NOT NULL,
    ano integer NOT NULL,
    dias_atribuidos numeric(5,2) DEFAULT 0 NOT NULL,
    dias_usados numeric(5,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: saldos_ausencia_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.saldos_ausencia ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.saldos_ausencia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tipos_ausencia; Type: TABLE; Schema: rh; Owner: -
--

CREATE TABLE rh.tipos_ausencia (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(60) NOT NULL,
    dias_anuais numeric(5,2),
    remunerada boolean DEFAULT true NOT NULL,
    afeta_saldo boolean DEFAULT false NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tipos_ausencia_id_seq; Type: SEQUENCE; Schema: rh; Owner: -
--

ALTER TABLE rh.tipos_ausencia ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rh.tipos_ausencia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: security_ip_allowlist; Type: TABLE; Schema: seguranca; Owner: -
--

CREATE TABLE seguranca.security_ip_allowlist (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    descricao character varying(150),
    ip_or_cidr character varying(80) NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: security_ip_allowlist_id_seq; Type: SEQUENCE; Schema: seguranca; Owner: -
--

ALTER TABLE seguranca.security_ip_allowlist ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME seguranca.security_ip_allowlist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: security_mfa_enrollments; Type: TABLE; Schema: seguranca; Owner: -
--

CREATE TABLE seguranca.security_mfa_enrollments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    user_id bigint NOT NULL,
    metodo character varying(20) DEFAULT 'totp'::character varying NOT NULL,
    secret character varying(255) NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    last_verified_at timestamp with time zone,
    revoked_at timestamp with time zone,
    created_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT security_mfa_enrollments_metodo_check CHECK (((metodo)::text = ANY ((ARRAY['totp'::character varying, 'sms'::character varying, 'email'::character varying])::text[])))
);


--
-- Name: security_mfa_enrollments_id_seq; Type: SEQUENCE; Schema: seguranca; Owner: -
--

ALTER TABLE seguranca.security_mfa_enrollments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME seguranca.security_mfa_enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: security_policies; Type: TABLE; Schema: seguranca; Owner: -
--

CREATE TABLE seguranca.security_policies (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(120) NOT NULL,
    configuracao jsonb NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: security_policies_id_seq; Type: SEQUENCE; Schema: seguranca; Owner: -
--

ALTER TABLE seguranca.security_policies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME seguranca.security_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: api_logs; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.api_logs (
    id bigint NOT NULL,
    tenant_id bigint,
    metodo character varying(10) NOT NULL,
    rota character varying(255) NOT NULL,
    status_code integer,
    duracao_ms integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: api_logs_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.api_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.api_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cities; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.cities (
    id bigint NOT NULL,
    country_id bigint,
    nome character varying(100) NOT NULL
);


--
-- Name: cities_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.cities ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.cities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: countries; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.countries (
    id bigint NOT NULL,
    codigo character varying(10) NOT NULL,
    nome character varying(100) NOT NULL
);


--
-- Name: countries_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.countries ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.countries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: currencies; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.currencies (
    id bigint NOT NULL,
    codigo character varying(10) NOT NULL,
    nome character varying(80) NOT NULL,
    simbolo character varying(10),
    ativa boolean DEFAULT true NOT NULL
);


--
-- Name: currencies_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.currencies ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.currencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: email_templates; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.email_templates (
    id bigint NOT NULL,
    tenant_id bigint,
    codigo character varying(50) NOT NULL,
    assunto character varying(150) NOT NULL,
    corpo text NOT NULL
);


--
-- Name: email_templates_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.email_templates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.email_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: exchange_rates; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.exchange_rates (
    id bigint NOT NULL,
    from_currency_id bigint NOT NULL,
    to_currency_id bigint NOT NULL,
    rate numeric(18,6) NOT NULL,
    rate_date date NOT NULL
);


--
-- Name: exchange_rates_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.exchange_rates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.exchange_rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: integrations; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.integrations (
    id bigint NOT NULL,
    tenant_id bigint,
    codigo character varying(50) NOT NULL,
    nome character varying(120) NOT NULL,
    configuracao jsonb,
    ativa boolean DEFAULT true NOT NULL
);


--
-- Name: integrations_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.integrations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: languages; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.languages (
    id bigint NOT NULL,
    codigo character varying(10) NOT NULL,
    nome character varying(80) NOT NULL
);


--
-- Name: languages_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.languages ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.languages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: settings; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.settings (
    id bigint NOT NULL,
    tenant_id bigint,
    chave character varying(120) NOT NULL,
    valor text,
    escopo character varying(30) DEFAULT 'global'::character varying NOT NULL,
    CONSTRAINT settings_escopo_check CHECK (((escopo)::text = ANY ((ARRAY['global'::character varying, 'tenant'::character varying, 'user'::character varying])::text[])))
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.settings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sms_templates; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.sms_templates (
    id bigint NOT NULL,
    tenant_id bigint,
    codigo character varying(50) NOT NULL,
    corpo text NOT NULL
);


--
-- Name: sms_templates_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.sms_templates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.sms_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: system_logs; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.system_logs (
    id bigint NOT NULL,
    tenant_id bigint,
    nivel character varying(20) NOT NULL,
    modulo character varying(80),
    mensagem text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: system_logs_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.system_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.system_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tenant_branding; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.tenant_branding (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    logo_url text,
    cor_primaria character varying(20),
    cor_secundaria character varying(20),
    slogan character varying(150),
    website_url text,
    suporte_email character varying(150),
    suporte_telefone character varying(30),
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tenant_branding_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.tenant_branding ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.tenant_branding_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tenant_defaults; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.tenant_defaults (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    chave character varying(100) NOT NULL,
    valor text,
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tenant_defaults_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.tenant_defaults ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.tenant_defaults_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tenant_document_settings; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.tenant_document_settings (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    modulo character varying(50) NOT NULL,
    tipo_documento character varying(50) NOT NULL,
    prefixo character varying(20),
    reinicia_anualmente boolean DEFAULT true NOT NULL,
    serie_activa character varying(20),
    layout_template character varying(100),
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tenant_document_settings_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.tenant_document_settings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.tenant_document_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tenant_feature_flags; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.tenant_feature_flags (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(100) NOT NULL,
    activo boolean DEFAULT false NOT NULL,
    configuracao jsonb,
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tenant_feature_flags_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.tenant_feature_flags ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.tenant_feature_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tenant_integrations; Type: TABLE; Schema: sistema_configuracao; Owner: -
--

CREATE TABLE sistema_configuracao.tenant_integrations (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(100) NOT NULL,
    activo boolean DEFAULT false NOT NULL,
    endpoint_url text,
    credenciais jsonb,
    configuracao jsonb,
    updated_by bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tenant_integrations_id_seq; Type: SEQUENCE; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE sistema_configuracao.tenant_integrations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sistema_configuracao.tenant_integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_adjustments; Type: TABLE; Schema: stock; Owner: -
--

CREATE TABLE stock.stock_adjustments (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    adjustment_type character varying(20) NOT NULL,
    quantity numeric(18,2) NOT NULL,
    reason text,
    adjusted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT stock_adjustments_adjustment_type_check CHECK (((adjustment_type)::text = ANY ((ARRAY['positivo'::character varying, 'negativo'::character varying])::text[])))
);


--
-- Name: stock_adjustments_id_seq; Type: SEQUENCE; Schema: stock; Owner: -
--

ALTER TABLE stock.stock_adjustments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_adjustments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_alerts; Type: TABLE; Schema: stock; Owner: -
--

CREATE TABLE stock.stock_alerts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    alert_type character varying(30) NOT NULL,
    status character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    mensagem text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT stock_alerts_alert_type_check CHECK (((alert_type)::text = ANY ((ARRAY['stock_minimo'::character varying, 'stock_maximo'::character varying, 'lote_expirar'::character varying])::text[]))),
    CONSTRAINT stock_alerts_status_check CHECK (((status)::text = ANY ((ARRAY['aberto'::character varying, 'resolvido'::character varying, 'ignorado'::character varying])::text[])))
);


--
-- Name: stock_alerts_id_seq; Type: SEQUENCE; Schema: stock; Owner: -
--

ALTER TABLE stock.stock_alerts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_batches; Type: TABLE; Schema: stock; Owner: -
--

CREATE TABLE stock.stock_batches (
    id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    batch_number character varying(80) NOT NULL,
    manufacture_date date,
    expiry_date date,
    quantity numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: stock_batches_id_seq; Type: SEQUENCE; Schema: stock; Owner: -
--

ALTER TABLE stock.stock_batches ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_count_items; Type: TABLE; Schema: stock; Owner: -
--

CREATE TABLE stock.stock_count_items (
    id bigint NOT NULL,
    stock_count_id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    system_quantity numeric(18,2) NOT NULL,
    counted_quantity numeric(18,2) NOT NULL,
    difference_quantity numeric(18,2) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: stock_count_items_id_seq; Type: SEQUENCE; Schema: stock; Owner: -
--

ALTER TABLE stock.stock_count_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_count_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_counts; Type: TABLE; Schema: stock; Owner: -
--

CREATE TABLE stock.stock_counts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    warehouse_id bigint NOT NULL,
    status character varying(20) DEFAULT 'aberto'::character varying NOT NULL,
    count_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    closed_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    CONSTRAINT stock_counts_status_check CHECK (((status)::text = ANY ((ARRAY['aberto'::character varying, 'fechado'::character varying, 'cancelado'::character varying])::text[])))
);


--
-- Name: stock_counts_id_seq; Type: SEQUENCE; Schema: stock; Owner: -
--

ALTER TABLE stock.stock_counts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_items; Type: TABLE; Schema: stock; Owner: -
--

CREATE TABLE stock.stock_items (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_variant_id bigint,
    warehouse_id bigint NOT NULL,
    quantity numeric(18,2) DEFAULT 0 NOT NULL,
    reserved_quantity numeric(18,2) DEFAULT 0 NOT NULL,
    available_quantity numeric(18,2) GENERATED ALWAYS AS ((quantity - reserved_quantity)) STORED,
    minimum_quantity numeric(18,2) DEFAULT 0 NOT NULL,
    maximum_quantity numeric(18,2),
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: stock_items_id_seq; Type: SEQUENCE; Schema: stock; Owner: -
--

ALTER TABLE stock.stock_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_logs; Type: TABLE; Schema: stock; Owner: -
--

CREATE TABLE stock.stock_logs (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    stock_item_id bigint,
    acao character varying(100) NOT NULL,
    detalhe text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: stock_logs_id_seq; Type: SEQUENCE; Schema: stock; Owner: -
--

ALTER TABLE stock.stock_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_movements; Type: TABLE; Schema: stock; Owner: -
--

CREATE TABLE stock.stock_movements (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    quantity numeric(18,2) NOT NULL,
    reference_type character varying(50),
    reference_id bigint,
    movement_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT stock_movements_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['entrada'::character varying, 'saida'::character varying, 'transferencia_entrada'::character varying, 'transferencia_saida'::character varying, 'ajuste'::character varying, 'reserva'::character varying, 'liberacao'::character varying])::text[])))
);


--
-- Name: stock_movements_id_seq; Type: SEQUENCE; Schema: stock; Owner: -
--

ALTER TABLE stock.stock_movements ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_movements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_reservations; Type: TABLE; Schema: stock; Owner: -
--

CREATE TABLE stock.stock_reservations (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    quantity numeric(18,2) NOT NULL,
    reference_type character varying(50),
    reference_id bigint,
    status character varying(20) DEFAULT 'ativa'::character varying NOT NULL,
    reserved_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT stock_reservations_status_check CHECK (((status)::text = ANY ((ARRAY['ativa'::character varying, 'consumida'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: stock_reservations_id_seq; Type: SEQUENCE; Schema: stock; Owner: -
--

ALTER TABLE stock.stock_reservations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_reservations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_serial_numbers; Type: TABLE; Schema: stock; Owner: -
--

CREATE TABLE stock.stock_serial_numbers (
    id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    serial_number character varying(120) NOT NULL,
    status character varying(20) DEFAULT 'disponivel'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT stock_serial_numbers_status_check CHECK (((status)::text = ANY ((ARRAY['disponivel'::character varying, 'reservado'::character varying, 'vendido'::character varying, 'devolvido'::character varying])::text[])))
);


--
-- Name: stock_serial_numbers_id_seq; Type: SEQUENCE; Schema: stock; Owner: -
--

ALTER TABLE stock.stock_serial_numbers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_serial_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_transfer_items; Type: TABLE; Schema: stock; Owner: -
--

CREATE TABLE stock.stock_transfer_items (
    id bigint NOT NULL,
    stock_transfer_id bigint NOT NULL,
    stock_item_id bigint NOT NULL,
    quantity numeric(18,2) NOT NULL,
    CONSTRAINT stock_transfer_items_quantity_check CHECK ((quantity > (0)::numeric))
);


--
-- Name: stock_transfer_items_id_seq; Type: SEQUENCE; Schema: stock; Owner: -
--

ALTER TABLE stock.stock_transfer_items ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_transfer_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_transfers; Type: TABLE; Schema: stock; Owner: -
--

CREATE TABLE stock.stock_transfers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    numero character varying(50) NOT NULL,
    from_warehouse_id bigint NOT NULL,
    to_warehouse_id bigint NOT NULL,
    status character varying(20) DEFAULT 'pendente'::character varying NOT NULL,
    transfer_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    confirmed_at timestamp with time zone,
    received_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    CONSTRAINT stock_transfers_status_check CHECK (((status)::text = ANY ((ARRAY['pendente'::character varying, 'em_transito'::character varying, 'concluida'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Name: stock_transfers_id_seq; Type: SEQUENCE; Schema: stock; Owner: -
--

ALTER TABLE stock.stock_transfers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.stock_transfers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: warehouse_locations; Type: TABLE; Schema: stock; Owner: -
--

CREATE TABLE stock.warehouse_locations (
    id bigint NOT NULL,
    warehouse_id bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(120) NOT NULL,
    tipo character varying(30),
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: warehouse_locations_id_seq; Type: SEQUENCE; Schema: stock; Owner: -
--

ALTER TABLE stock.warehouse_locations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME stock.warehouse_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: bank_accounts; Type: TABLE; Schema: tesouraria; Owner: -
--

CREATE TABLE tesouraria.bank_accounts (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    banco character varying(120) NOT NULL,
    numero_conta character varying(80) NOT NULL,
    iban character varying(80),
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    saldo_inicial numeric(18,2) DEFAULT 0 NOT NULL,
    saldo_actual numeric(18,2) DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: bank_accounts_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: -
--

ALTER TABLE tesouraria.bank_accounts ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.bank_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: caixas; Type: TABLE; Schema: tesouraria; Owner: -
--

CREATE TABLE tesouraria.caixas (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    nome character varying(120) NOT NULL,
    saldo_atual numeric(18,2) DEFAULT 0 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: caixas_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: -
--

ALTER TABLE tesouraria.caixas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.caixas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cash_registers; Type: TABLE; Schema: tesouraria; Owner: -
--

CREATE TABLE tesouraria.cash_registers (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    codigo character varying(40) NOT NULL,
    nome character varying(120) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    saldo_inicial numeric(18,2) DEFAULT 0 NOT NULL,
    saldo_actual numeric(18,2) DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: cash_registers_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: -
--

ALTER TABLE tesouraria.cash_registers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.cash_registers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: contas_bancarias; Type: TABLE; Schema: tesouraria; Owner: -
--

CREATE TABLE tesouraria.contas_bancarias (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    banco character varying(120) NOT NULL,
    numero_conta character varying(60) NOT NULL,
    nib character varying(60),
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    saldo_atual numeric(18,2) DEFAULT 0 NOT NULL,
    ativa boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: contas_bancarias_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: -
--

ALTER TABLE tesouraria.contas_bancarias ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.contas_bancarias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: movements; Type: TABLE; Schema: tesouraria; Owner: -
--

CREATE TABLE tesouraria.movements (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    bank_account_id bigint,
    cash_register_id bigint,
    tipo character varying(20) NOT NULL,
    valor numeric(18,2) NOT NULL,
    moeda character varying(10) DEFAULT 'MZN'::character varying NOT NULL,
    data_movimento date DEFAULT CURRENT_DATE NOT NULL,
    metodo character varying(40),
    referencia character varying(100),
    descricao text,
    reference_type character varying(60),
    reference_id bigint,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT movements_check CHECK (((((bank_account_id IS NOT NULL))::integer + ((cash_register_id IS NOT NULL))::integer) = 1)),
    CONSTRAINT movements_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['recebimento'::character varying, 'pagamento'::character varying])::text[]))),
    CONSTRAINT movements_valor_check CHECK ((valor > (0)::numeric))
);


--
-- Name: movements_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: -
--

ALTER TABLE tesouraria.movements ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.movements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: movimentos_financeiros; Type: TABLE; Schema: tesouraria; Owner: -
--

CREATE TABLE tesouraria.movimentos_financeiros (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    origem_tipo character varying(30) NOT NULL,
    origem_id bigint,
    conta_bancaria_id bigint,
    caixa_id bigint,
    tipo character varying(20) NOT NULL,
    valor numeric(18,2) NOT NULL,
    referencia character varying(100),
    descricao text,
    data_movimento timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT movimentos_financeiros_origem_tipo_check CHECK (((origem_tipo)::text = ANY ((ARRAY['faturacao'::character varying, 'compras'::character varying, 'rh'::character varying, 'ajuste'::character varying])::text[]))),
    CONSTRAINT movimentos_financeiros_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['recebimento'::character varying, 'pagamento'::character varying, 'transferencia'::character varying, 'ajuste'::character varying])::text[]))),
    CONSTRAINT movimentos_financeiros_valor_check CHECK ((valor > (0)::numeric))
);


--
-- Name: movimentos_financeiros_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: -
--

ALTER TABLE tesouraria.movimentos_financeiros ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.movimentos_financeiros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reconciliacoes_bancarias; Type: TABLE; Schema: tesouraria; Owner: -
--

CREATE TABLE tesouraria.reconciliacoes_bancarias (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    conta_bancaria_id bigint NOT NULL,
    periodo_inicio date NOT NULL,
    periodo_fim date NOT NULL,
    saldo_extrato numeric(18,2) NOT NULL,
    saldo_sistema numeric(18,2) NOT NULL,
    diferenca numeric(18,2) NOT NULL,
    status character varying(20) DEFAULT 'aberta'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT reconciliacoes_bancarias_status_check CHECK (((status)::text = ANY ((ARRAY['aberta'::character varying, 'fechada'::character varying])::text[])))
);


--
-- Name: reconciliacoes_bancarias_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: -
--

ALTER TABLE tesouraria.reconciliacoes_bancarias ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.reconciliacoes_bancarias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reconciliations; Type: TABLE; Schema: tesouraria; Owner: -
--

CREATE TABLE tesouraria.reconciliations (
    id bigint NOT NULL,
    tenant_id bigint NOT NULL,
    bank_account_id bigint NOT NULL,
    periodo_inicio date NOT NULL,
    periodo_fim date NOT NULL,
    saldo_extracto numeric(18,2) NOT NULL,
    saldo_sistema numeric(18,2) DEFAULT 0 NOT NULL,
    diferenca numeric(18,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'aberta'::character varying NOT NULL,
    observacoes text,
    criada_por bigint,
    fechada_por bigint,
    fechada_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT reconciliations_check CHECK ((periodo_fim >= periodo_inicio)),
    CONSTRAINT reconciliations_status_check CHECK (((status)::text = ANY ((ARRAY['aberta'::character varying, 'fechada'::character varying])::text[])))
);


--
-- Name: reconciliations_id_seq; Type: SEQUENCE; Schema: tesouraria; Owner: -
--

ALTER TABLE tesouraria.reconciliations ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME tesouraria.reconciliations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: profiles; Type: TABLE; Schema: utilizadores; Owner: -
--

CREATE TABLE utilizadores.profiles (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    primeiro_nome character varying(100),
    ultimo_nome character varying(100),
    nome_exibicao character varying(150),
    data_nascimento date,
    genero character varying(20),
    idioma character varying(20) DEFAULT 'pt'::character varying,
    timezone character varying(60) DEFAULT 'Africa/Maputo'::character varying,
    bio text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: profiles_id_seq; Type: SEQUENCE; Schema: utilizadores; Owner: -
--

ALTER TABLE utilizadores.profiles ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_activity; Type: TABLE; Schema: utilizadores; Owner: -
--

CREATE TABLE utilizadores.user_activity (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    modulo character varying(100),
    acao character varying(120) NOT NULL,
    descricao text,
    ip_address character varying(64),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_activity_id_seq; Type: SEQUENCE; Schema: utilizadores; Owner: -
--

ALTER TABLE utilizadores.user_activity ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_activity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_avatar; Type: TABLE; Schema: utilizadores; Owner: -
--

CREATE TABLE utilizadores.user_avatar (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    ficheiro_url text NOT NULL,
    mime_type character varying(100),
    tamanho_bytes bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_avatar_id_seq; Type: SEQUENCE; Schema: utilizadores; Owner: -
--

ALTER TABLE utilizadores.user_avatar ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_avatar_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_devices; Type: TABLE; Schema: utilizadores; Owner: -
--

CREATE TABLE utilizadores.user_devices (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    device_id character varying(120) NOT NULL,
    nome character varying(120),
    plataforma character varying(50),
    user_agent text,
    ultimo_acesso_em timestamp with time zone,
    confiavel boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_devices_id_seq; Type: SEQUENCE; Schema: utilizadores; Owner: -
--

ALTER TABLE utilizadores.user_devices ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_devices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_notifications; Type: TABLE; Schema: utilizadores; Owner: -
--

CREATE TABLE utilizadores.user_notifications (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    tipo character varying(50) NOT NULL,
    titulo character varying(150) NOT NULL,
    mensagem text NOT NULL,
    lida boolean DEFAULT false NOT NULL,
    lida_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_notifications_id_seq; Type: SEQUENCE; Schema: utilizadores; Owner: -
--

ALTER TABLE utilizadores.user_notifications ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_preferences; Type: TABLE; Schema: utilizadores; Owner: -
--

CREATE TABLE utilizadores.user_preferences (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    chave character varying(100) NOT NULL,
    valor text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_preferences_id_seq; Type: SEQUENCE; Schema: utilizadores; Owner: -
--

ALTER TABLE utilizadores.user_preferences ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_security_logs; Type: TABLE; Schema: utilizadores; Owner: -
--

CREATE TABLE utilizadores.user_security_logs (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    evento character varying(100) NOT NULL,
    severidade character varying(20) DEFAULT 'info'::character varying NOT NULL,
    detalhe text,
    ip_address character varying(64),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT user_security_logs_severidade_check CHECK (((severidade)::text = ANY ((ARRAY['info'::character varying, 'warning'::character varying, 'critical'::character varying])::text[])))
);


--
-- Name: user_security_logs_id_seq; Type: SEQUENCE; Schema: utilizadores; Owner: -
--

ALTER TABLE utilizadores.user_security_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_security_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_settings; Type: TABLE; Schema: utilizadores; Owner: -
--

CREATE TABLE utilizadores.user_settings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    chave character varying(100) NOT NULL,
    valor text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_settings_id_seq; Type: SEQUENCE; Schema: utilizadores; Owner: -
--

ALTER TABLE utilizadores.user_settings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_tokens; Type: TABLE; Schema: utilizadores; Owner: -
--

CREATE TABLE utilizadores.user_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    tipo character varying(30) NOT NULL,
    token_hash text NOT NULL,
    expira_em timestamp with time zone,
    revogado_em timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT user_tokens_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['refresh'::character varying, 'email_verify'::character varying, 'mfa'::character varying, 'integration'::character varying])::text[])))
);


--
-- Name: user_tokens_id_seq; Type: SEQUENCE; Schema: utilizadores; Owner: -
--

ALTER TABLE utilizadores.user_tokens ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME utilizadores.user_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: permissoes_tipo id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.permissoes_tipo ALTER COLUMN id SET DEFAULT nextval('auth.permissoes_tipo_id_seq'::regclass);


--
-- Name: chat_conversas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_conversas ALTER COLUMN id SET DEFAULT nextval('public.chat_conversas_id_seq'::regclass);


--
-- Name: chat_mensagens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_mensagens ALTER COLUMN id SET DEFAULT nextval('public.chat_mensagens_id_seq'::regclass);


--
-- Name: comunicados id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunicados ALTER COLUMN id SET DEFAULT nextval('public.comunicados_id_seq'::regclass);


--
-- Name: notif_colaborador id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notif_colaborador ALTER COLUMN id SET DEFAULT nextval('public.notif_colaborador_id_seq'::regclass);


--
-- Name: justificacoes id; Type: DEFAULT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.justificacoes ALTER COLUMN id SET DEFAULT nextval('rh.justificacoes_id_seq'::regclass);


--
-- Data for Name: subscription_invoices; Type: TABLE DATA; Schema: assinaturas; Owner: -
--

COPY assinaturas.subscription_invoices (id, tenant_id, subscription_id, numero, billing_period_start, billing_period_end, due_date, valor_total, valor_pago, moeda, status, created_at) FROM stdin;
\.


--
-- Data for Name: subscription_plans; Type: TABLE DATA; Schema: assinaturas; Owner: -
--

COPY assinaturas.subscription_plans (id, tenant_id, codigo, nome, billing_period, preco, moeda, limites, activo, created_at, updated_at) FROM stdin;
1	1	BASIC	Plano Basic	mensal	3500.00	MZN	{"users": 5, "branches": 1}	t	2026-03-17 16:40:19.521799+00	2026-03-17 16:40:19.521799+00
2	1	PRO	Plano Pro	mensal	9500.00	MZN	{"users": 25, "branches": 5}	t	2026-03-17 16:40:19.521799+00	2026-03-17 16:40:19.521799+00
\.


--
-- Data for Name: subscription_usage; Type: TABLE DATA; Schema: assinaturas; Owner: -
--

COPY assinaturas.subscription_usage (id, tenant_id, subscription_id, recurso, quantidade, periodo, metadata, created_at) FROM stdin;
\.


--
-- Data for Name: subscriptions; Type: TABLE DATA; Schema: assinaturas; Owner: -
--

COPY assinaturas.subscriptions (id, tenant_id, company_id, plan_id, numero, starts_at, ends_at, next_billing_date, status, unit_price, moeda, auto_renew, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: audit_events; Type: TABLE DATA; Schema: auditoria; Owner: -
--

COPY auditoria.audit_events (id, tenant_id, actor_user_id, actor_email, actor_nome, service_name, module_name, action, entity_type, entity_id, status, ip_address, user_agent, metadata, payload_before, payload_after, previous_hash, event_hash, created_at) FROM stdin;
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: auditoria; Owner: -
--

COPY auditoria.audit_logs (id, tenant_id, user_id, modulo, entidade, entidade_id, acao, detalhes, ip_address, created_at) FROM stdin;
1	1	4	empresas	company	1	criar	{"codigo": "NXR-001"}	[::1]:50196	2026-05-08 20:58:32.152366+00
2	4	7	contabilidade	fiscal-years	\N	criar	{"ano": 2025, "data_fim": "2026-12-31", "data_inicio": "2026-07-15"}	127.0.0.1:49779	2026-06-15 13:08:49.115397+00
3	4	7	contabilidade	fiscal-periods	7	fechar	\N	127.0.0.1:59614	2026-06-15 13:11:20.357222+00
4	4	7	contabilidade	fiscal-periods	7	abrir	\N	127.0.0.1:62241	2026-06-15 13:13:32.631653+00
5	4	7	contabilidade	fiscal-periods	8	fechar	\N	127.0.0.1:63630	2026-06-15 16:38:36.35821+00
6	4	7	contabilidade	fiscal-periods	9	fechar	\N	127.0.0.1:64590	2026-06-15 16:38:42.834448+00
7	4	7	compras	purchase-requests	\N	criar	{"numero": "14", "department": "TIPO", "prioridade": "alta", "justificacao": "URGENTE", "required_date": "2026-06-30"}	127.0.0.1:62429	2026-06-16 12:31:10.415653+00
\.


--
-- Data for Name: api_keys; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.api_keys (id, tenant_id, user_id, nome, key_prefix, key_hash, ultimo_uso_em, expira_em, ativa, created_at) FROM stdin;
\.


--
-- Data for Name: cargos; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.cargos (id, tenant_id, nome, descricao, ativo, created_at) FROM stdin;
1	1	Gestor	Gest�o geral	t	2026-05-08 19:45:38.499078+00
\.


--
-- Data for Name: email_verifications; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.email_verifications (id, user_id, token_hash, expira_em, usado_em, created_at) FROM stdin;
\.


--
-- Data for Name: login_history; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.login_history (id, user_id, tenant_id, email_tentado, sucesso, ip_address, user_agent, motivo_falha, criado_em) FROM stdin;
20	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:52499	curl/8.17.0	\N	2026-06-10 13:38:17.572992+00
21	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:52516	curl/8.17.0	\N	2026-06-10 13:38:27.243959+00
22	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:52137	curl/8.17.0	\N	2026-06-10 13:38:41.451427+00
23	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:58853	curl/8.17.0	\N	2026-06-10 13:38:54.913017+00
24	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:59990		\N	2026-06-10 13:42:02.675461+00
25	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:56929	curl/8.17.0	\N	2026-06-10 14:07:38.952475+00
26	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:65318	curl/8.17.0	\N	2026-06-11 00:24:48.427593+00
27	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:65321		\N	2026-06-11 00:25:01.574348+00
28	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:57461		\N	2026-06-11 07:31:42.482627+00
29	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:51314	curl/8.17.0	\N	2026-06-11 12:24:30.832414+00
30	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:51411	curl/8.17.0	\N	2026-06-11 12:57:00.891125+00
31	\N	1	admin@nexora.co.mz	f	127.0.0.1:65020		password incorrecta	2026-06-11 17:21:46.210756+00
33	\N	1	admin@nexora.local	f	127.0.0.1:62853		password incorrecta	2026-06-11 17:28:46.798574+00
34	7	4	admin@nexora.co.mz	t	127.0.0.1:57479		\N	2026-06-11 17:31:31.820103+00
1	\N	1	admin@nexora.co.mz	t	[::1]:56655	curl/8.17.0	\N	2026-05-08 19:28:45.579473+00
2	\N	1	admin@nexora.co.mz	t	[::1]:52971	curl/8.17.0	\N	2026-05-08 19:35:03.857074+00
3	\N	1	admin@nexora.co.mz	t	127.0.0.1:61548		\N	2026-05-08 19:35:23.40006+00
4	\N	1	admin@nexora.co.mz	t	127.0.0.1:55404		\N	2026-05-08 19:41:25.165888+00
5	\N	1	admin@nexora.co.mz	t	[::1]:57678	curl/8.17.0	\N	2026-05-08 19:44:42.417927+00
6	\N	1	admin@nexora.co.mz	t	[::1]:63343	curl/8.17.0	\N	2026-05-08 19:44:45.408622+00
7	\N	1	admin@nexora.co.mz	t	[::1]:62929	curl/8.17.0	\N	2026-05-08 19:45:40.441566+00
8	\N	1	admin@nexora.co.mz	t	127.0.0.1:57741		\N	2026-05-08 19:46:00.374179+00
9	\N	1	admin@nexora.co.mz	t	[::1]:54795	curl/8.17.0	\N	2026-05-08 19:49:35.52855+00
10	\N	1	admin@nexora.co.mz	t	[::1]:54798	curl/8.17.0	\N	2026-05-08 19:49:36.092601+00
11	\N	1	admin@nexora.co.mz	t	127.0.0.1:59242		\N	2026-05-08 19:49:52.325053+00
12	\N	1	admin@nexora.co.mz	t	[::1]:62066	curl/8.17.0	\N	2026-05-08 20:00:20.199688+00
13	\N	1	admin@nexora.co.mz	t	[::1]:51008	curl/8.17.0	\N	2026-05-08 20:07:06.024898+00
14	\N	1	admin@nexora.co.mz	t	[::1]:63680	curl/8.17.0	\N	2026-05-08 20:12:30.212803+00
15	\N	1	admin@nexora.co.mz	t	127.0.0.1:52455		\N	2026-05-08 20:49:03.331227+00
16	\N	1	admin@nexora.co.mz	t	[::1]:58056	curl/8.17.0	\N	2026-05-08 20:57:14.853208+00
17	\N	1	admin@nexora.co.mz	t	[::1]:50177	curl/8.17.0	\N	2026-05-08 20:58:30.008631+00
18	\N	1	admin@nexora.co.mz	t	[::1]:64764	curl/8.17.0	\N	2026-05-08 21:15:31.87373+00
19	\N	1	admin@nexora.co.mz	t	[::1]:50822	curl/8.17.0	\N	2026-05-09 19:46:44.58155+00
32	\N	1	admin@nexora.co.mz	t	127.0.0.1:49780		\N	2026-06-11 17:27:41.920734+00
35	7	4	admin@nexora.co.mz	t	127.0.0.1:64796		\N	2026-06-11 17:44:01.295907+00
36	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:50747		\N	2026-06-11 17:45:05.811423+00
37	7	4	admin@nexora.co.mz	t	127.0.0.1:55061		\N	2026-06-11 17:46:47.786539+00
38	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:56106		\N	2026-06-11 17:49:19.375165+00
39	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:58637		\N	2026-06-12 01:41:59.183275+00
40	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:60860		\N	2026-06-12 04:13:08.562368+00
41	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:52351		\N	2026-06-12 04:14:33.382332+00
42	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:54378		\N	2026-06-12 05:15:18.51839+00
43	7	4	admin@nexora.co.mz	t	127.0.0.1:58475		\N	2026-06-12 08:18:08.731236+00
44	7	4	admin@nexora.co.mz	t	127.0.0.1:58482		\N	2026-06-12 08:18:18.249906+00
45	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:49977	curl/8.17.0	\N	2026-06-12 08:19:02.506484+00
46	\N	4	admin@nexora.co.mz	f	127.0.0.1:54341		password incorrecta	2026-06-12 08:21:08.263771+00
47	7	4	admin@nexora.co.mz	t	127.0.0.1:65481		\N	2026-06-12 08:22:13.459196+00
48	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:56453	curl/8.17.0	\N	2026-06-12 08:24:46.511137+00
49	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:54793	curl/8.17.0	\N	2026-06-12 08:24:58.121775+00
50	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:62234	curl/8.17.0	\N	2026-06-12 08:27:21.181141+00
51	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:59266	curl/8.17.0	\N	2026-06-12 08:27:43.502763+00
53	7	4	admin@nexora.co.mz	t	127.0.0.1:52669		\N	2026-06-12 08:44:29.509954+00
52	\N	4	admin@nexora.co.mz	f	127.0.0.1:55605		password incorrecta	2026-06-12 08:43:24.2063+00
54	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:59455	curl/8.17.0	\N	2026-06-12 08:46:13.719449+00
55	7	4	admin@nexora.co.mz	t	127.0.0.1:55082		\N	2026-06-12 13:03:40.767606+00
56	7	4	admin@nexora.co.mz	t	127.0.0.1:58918		\N	2026-06-15 12:58:29.624723+00
57	7	4	admin@nexora.co.mz	t	127.0.0.1:59950		\N	2026-06-16 12:19:35.931705+00
58	7	4	admin@nexora.co.mz	t	127.0.0.1:50361		\N	2026-06-16 14:01:41.841475+00
59	7	4	admin@nexora.co.mz	t	127.0.0.1:49196		\N	2026-06-18 13:54:10.037896+00
60	7	4	admin@nexora.co.mz	t	127.0.0.1:53412		\N	2026-06-18 18:50:18.644705+00
61	\N	1	recrutamento-bot@e258tech.local	f	127.0.0.1:57270		password incorrecta	2026-06-19 14:35:30.985656+00
62	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:53833		\N	2026-06-19 14:46:14.763511+00
63	7	4	admin@nexora.co.mz	t	127.0.0.1:51945		\N	2026-06-19 17:02:48.261965+00
64	8	1	recrutamento-bot@e258tech.local	t	[::1]:63253	curl/8.17.0	\N	2026-06-19 18:03:38.938149+00
65	8	1	recrutamento-bot@e258tech.local	t	[::1]:60846	curl/8.17.0	\N	2026-06-19 18:09:30.846319+00
66	8	1	recrutamento-bot@e258tech.local	t	127.0.0.1:64791		\N	2026-06-19 18:22:25.020965+00
67	7	4	admin@nexora.co.mz	t	127.0.0.1:55887		\N	2026-06-19 18:24:28.364013+00
68	\N	4	pos-teste@nexora.local	f	127.0.0.1:59494		password incorrecta	2026-06-19 18:25:23.047938+00
69	\N	4	pos-teste@nexora.local	f	127.0.0.1:64197		password incorrecta	2026-06-19 18:25:50.311207+00
70	9	4	pos-teste@nexora.local	t	[::1]:50762	curl/8.17.0	\N	2026-06-19 18:27:46.974736+00
71	9	4	pos-teste@nexora.local	t	127.0.0.1:59290		\N	2026-06-19 18:29:57.059156+00
72	10	4	eleuterio3d@gmail.com	t	127.0.0.1:52345		\N	2026-06-19 18:32:21.680206+00
73	10	4	eleuterio3d@gmail.com	t	127.0.0.1:54738		\N	2026-06-19 18:47:04.274204+00
74	10	4	eleuterio3d@gmail.com	t	127.0.0.1:55007		\N	2026-06-19 18:52:31.108707+00
75	7	4	admin@nexora.co.mz	t	127.0.0.1:60259		\N	2026-06-19 18:53:30.222068+00
76	7	4	admin@nexora.co.mz	t	[::1]:58425	curl/8.17.0	\N	2026-06-19 18:59:06.019807+00
77	7	4	admin@nexora.co.mz	t	[::1]:54809	curl/8.17.0	\N	2026-06-19 19:13:08.004153+00
78	7	4	admin@nexora.co.mz	t	[::1]:55045	curl/8.17.0	\N	2026-06-19 19:20:43.675004+00
79	7	4	admin@nexora.co.mz	t	127.0.0.1:62406		\N	2026-06-19 19:22:07.995665+00
80	7	4	admin@nexora.co.mz	t	[::1]:59252	curl/8.17.0	\N	2026-06-19 20:35:46.285034+00
81	10	4	eleuterio3d@gmail.com	t	[::1]:50791	curl/8.17.0	\N	2026-06-19 20:49:47.79469+00
82	7	4	admin@nexora.co.mz	t	[::1]:63615	curl/8.17.0	\N	2026-06-20 05:41:29.404814+00
83	7	4	admin@nexora.co.mz	t	[::1]:55981	curl/8.17.0	\N	2026-06-20 06:10:28.820195+00
84	7	4	admin@nexora.co.mz	t	[::1]:63538	curl/8.17.0	\N	2026-06-20 07:39:15.979328+00
85	7	4	admin@nexora.co.mz	t	[::1]:55732	curl/8.17.0	\N	2026-06-20 07:58:21.653376+00
86	7	4	admin@nexora.co.mz	t	[::1]:65007	curl/8.17.0	\N	2026-06-20 07:59:28.553002+00
87	10	4	eleuterio3d@gmail.com	t	127.0.0.1:60128		\N	2026-06-20 08:00:00.96331+00
88	10	4	eleuterio3d@gmail.com	t	[::1]:58897	curl/8.17.0	\N	2026-06-20 08:02:50.810837+00
89	10	4	eleuterio3d@gmail.com	t	[::1]:63024	curl/8.17.0	\N	2026-06-20 08:04:36.439115+00
90	10	4	eleuterio3d@gmail.com	t	[::1]:64768	curl/8.17.0	\N	2026-06-20 08:05:14.773691+00
91	10	4	eleuterio3d@gmail.com	t	[::1]:58715	curl/8.17.0	\N	2026-06-20 08:11:35.492835+00
92	7	4	admin@nexora.co.mz	t	[::1]:55177	curl/8.17.0	\N	2026-06-20 08:14:17.59332+00
93	7	4	admin@nexora.co.mz	t	[::1]:55186	curl/8.17.0	\N	2026-06-20 08:14:36.425666+00
94	7	4	admin@nexora.co.mz	t	127.0.0.1:54072		\N	2026-06-20 08:25:57.181767+00
95	10	4	eleuterio3d@gmail.com	t	127.0.0.1:64509		\N	2026-06-20 08:38:22.100529+00
96	10	4	eleuterio3d@gmail.com	t	127.0.0.1:52736		\N	2026-06-20 08:39:20.523755+00
97	10	4	eleuterio3d@gmail.com	t	127.0.0.1:50161		\N	2026-06-20 08:43:41.546527+00
98	11	4	admin1@nexora.co.mz	t	127.0.0.1:51263		\N	2026-06-20 08:59:49.980119+00
99	7	4	admin@nexora.co.mz	t	127.0.0.1:52950		\N	2026-06-20 09:01:12.722475+00
100	10	4	eleuterio3d@gmail.com	t	[::1]:60162	curl/8.17.0	\N	2026-06-20 09:21:25.164161+00
101	10	4	eleuterio3d@gmail.com	t	[::1]:63715	curl/8.17.0	\N	2026-06-20 09:24:40.169763+00
102	10	4	eleuterio3d@gmail.com	t	[::1]:51620	curl/8.17.0	\N	2026-06-20 09:26:00.681+00
103	10	4	eleuterio3d@gmail.com	t	[::1]:50896	curl/8.17.0	\N	2026-06-20 09:28:53.756646+00
104	10	4	eleuterio3d@gmail.com	t	[::1]:62413	curl/8.17.0	\N	2026-06-20 09:38:20.256604+00
105	10	4	eleuterio3d@gmail.com	t	[::1]:60868	curl/8.17.0	\N	2026-06-20 09:43:19.347455+00
106	10	4	eleuterio3d@gmail.com	t	[::1]:59987	curl/8.17.0	\N	2026-06-20 18:21:33.996645+00
107	10	4	eleuterio3d@gmail.com	t	[::1]:56989	curl/8.17.0	\N	2026-06-20 18:28:19.701942+00
108	10	4	eleuterio3d@gmail.com	t	[::1]:51506	curl/8.17.0	\N	2026-06-20 18:33:32.269086+00
109	10	4	eleuterio3d@gmail.com	t	[::1]:58012	curl/8.17.0	\N	2026-06-20 18:35:36.748036+00
110	7	4	admin@nexora.co.mz	t	127.0.0.1:57466		\N	2026-06-20 18:43:27.454794+00
111	11	4	admin1@nexora.co.mz	t	127.0.0.1:52080		\N	2026-06-20 18:51:26.819198+00
112	10	4	eleuterio3d@gmail.com	t	192.168.168.218:37018	okhttp/4.12.0	\N	2026-06-20 21:07:25.422713+00
113	10	4	eleuterio3d@gmail.com	t	192.168.168.218:38184	okhttp/4.12.0	\N	2026-06-20 22:01:44.874526+00
114	10	4	eleuterio3d@gmail.com	t	192.168.168.218:54164	okhttp/4.12.0	\N	2026-06-20 23:48:17.658955+00
115	10	4	eleuterio3d@gmail.com	t	192.168.168.218:35086	okhttp/4.12.0	\N	2026-06-21 02:34:32.514247+00
116	10	4	eleuterio3d@gmail.com	t	192.168.168.218:35908	okhttp/4.12.0	\N	2026-06-21 02:42:49.246038+00
117	10	4	eleuterio3d@gmail.com	t	192.168.168.218:56686	okhttp/4.12.0	\N	2026-06-21 02:57:41.543233+00
118	10	4	eleuterio3d@gmail.com	t	192.168.168.218:59022	okhttp/4.12.0	\N	2026-06-21 07:56:18.055049+00
119	10	4	eleuterio3d@gmail.com	t	192.168.168.218:52598	okhttp/4.12.0	\N	2026-06-21 08:19:16.430311+00
120	10	4	eleuterio3d@gmail.com	t	192.168.168.218:60166	okhttp/4.12.0	\N	2026-06-21 08:36:51.509474+00
121	10	4	eleuterio3d@gmail.com	t	192.168.168.218:52564	okhttp/4.12.0	\N	2026-06-21 08:55:57.196463+00
122	7	4	admin@nexora.co.mz	t	127.0.0.1:59838		\N	2026-06-21 10:15:48.969964+00
123	7	4	admin@nexora.co.mz	t	127.0.0.1:61836		\N	2026-06-21 10:20:36.377714+00
124	7	4	admin@nexora.co.mz	t	127.0.0.1:59387		\N	2026-06-21 10:27:38.514205+00
125	10	4	eleuterio3d@gmail.com	t	127.0.0.1:59019		\N	2026-06-21 11:03:07.565009+00
126	10	4	eleuterio3d@gmail.com	t	127.0.0.1:56572		\N	2026-06-21 11:07:31.148117+00
127	10	4	eleuterio3d@gmail.com	t	127.0.0.1:60369		\N	2026-06-21 11:15:06.901724+00
128	11	4	admin1@nexora.co.mz	t	127.0.0.1:62938		\N	2026-06-21 11:16:20.507481+00
129	7	4	admin@nexora.co.mz	t	127.0.0.1:65501		\N	2026-06-21 11:49:35.961431+00
130	11	4	admin1@nexora.co.mz	t	127.0.0.1:64389		\N	2026-06-21 11:50:18.372564+00
131	10	4	eleuterio3d@gmail.com	t	127.0.0.1:49674		\N	2026-06-21 11:56:45.891831+00
132	11	4	admin1@nexora.co.mz	t	127.0.0.1:61907		\N	2026-06-21 11:59:43.118658+00
133	11	4	admin1@nexora.co.mz	t	127.0.0.1:61873		\N	2026-06-21 12:01:12.156019+00
134	10	4	eleuterio3d@gmail.com	t	[::1]:56182	curl/8.17.0	\N	2026-06-21 12:35:01.104615+00
135	10	4	eleuterio3d@gmail.com	t	[::1]:49792	curl/8.17.0	\N	2026-06-21 12:36:48.749099+00
136	10	4	eleuterio3d@gmail.com	t	[::1]:55904	curl/8.17.0	\N	2026-06-21 12:41:52.573053+00
137	10	4	eleuterio3d@gmail.com	t	127.0.0.1:55911		\N	2026-06-21 12:41:53.771343+00
\.


--
-- Data for Name: password_resets; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.password_resets (id, user_id, token_hash, expira_em, usado_em, created_at) FROM stdin;
\.


--
-- Data for Name: permissoes_cargo; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.permissoes_cargo (id, cargo_id, modulo, acao) FROM stdin;
4	1	vendas	ver
5	1	vendas	criar
6	1	vendas	eliminar
\.


--
-- Data for Name: permissoes_diretas; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.permissoes_diretas (id, user_id, modulo, acao) FROM stdin;
726	11	clientes	ver_clientes
727	11	clientes	gerir_clientes
728	11	clientes	gerir_grupos
729	11	clientes	gerir_credito
730	11	clientes	eliminar_clientes
731	11	compras	ver_compras
732	11	compras	criar_pedidos
733	11	compras	aprovar_pedidos
734	11	compras	gerir_itens
735	11	contabilidade	ver_contabilidade
736	11	contabilidade	gerir_plano_contas
737	11	contabilidade	gerir_lancamentos
738	11	contabilidade	gerir_periodos
739	11	contabilidade	gerir_ativos_fixos
740	11	contabilidade	gerir_orcamentos
741	11	contabilidade	fechar_periodo
742	11	contabilidade	ver_relatorios
743	11	recursos-humanos	ver_funcionarios
744	11	recursos-humanos	gerir_funcionarios
745	11	recursos-humanos	gerir_contratos
746	11	recursos-humanos	gerir_horarios
747	11	recursos-humanos	aprovar_ausencias
748	11	recursos-humanos	processar_salarios
749	11	recursos-humanos	gerir_avaliacoes
750	11	recursos-humanos	gerir_formacoes
751	11	recursos-humanos	gerir_beneficios
752	11	recursos-humanos	ver_relatorios
753	11	assiduidade	ver_assiduidade
754	11	assiduidade	justificar
664	10	gestao-escolar	gerir_biblioteca
665	10	gestao-escolar	gerir_financeiro
666	10	gestao-escolar	gerir_comunicacao
667	10	gestao-escolar	ver_relatorios
668	10	notificacoes	ver_notificacoes
669	10	notificacoes	gerir_notificacoes
670	10	auditoria	ver_logs
671	10	seguranca	ver_seguranca
672	10	seguranca	gerir_politicas
673	10	seguranca	gerir_allowlist
674	10	sistema-configuracao	ver_configuracoes
675	10	sistema-configuracao	editar_configuracoes
676	10	sistema-configuracao	gerir_templates
677	10	sistema-configuracao	ver_logs_sistema
678	10	recrutamento	ver_vagas
679	10	recrutamento	gerir_vagas
680	10	recrutamento	ver_candidaturas
681	10	recrutamento	gerir_candidaturas
682	10	recrutamento	gerir_pipeline
683	10	recrutamento	avaliar_candidatos
130	1	empresa	ver_empresa
131	1	empresa	editar_empresa
132	1	empresa	gerir_filiais
133	1	empresa	gerir_licencas
134	1	clientes	ver_clientes
135	1	clientes	gerir_clientes
136	1	clientes	gerir_grupos
137	1	clientes	gerir_credito
138	1	clientes	eliminar_clientes
139	1	vendas	ver_vendas
140	1	vendas	criar_vendas
141	1	vendas	cancelar_vendas
142	1	faturacao	ver_documentos
143	1	faturacao	emitir_orcamentos
144	1	faturacao	emitir_encomendas
145	1	faturacao	emitir_faturas
146	1	faturacao	emitir_notas_credito
147	1	faturacao	configurar_series
148	1	pos	operar_pos
149	1	pos	ver_vendas
150	1	pos	gerir_terminais
151	1	pos	gerir_catalogo
152	1	stock	ver_stock
153	1	stock	gerir_produtos
154	1	stock	gerir_categorias
155	1	stock	gerir_movimentos
156	1	stock	eliminar_produtos
157	1	compras	ver_compras
158	1	compras	criar_pedidos
159	1	compras	aprovar_pedidos
160	1	compras	gerir_itens
161	1	logistica	ver_logistica
162	1	logistica	gerir_entregas
163	1	financeiro	ver_financeiro
164	1	financeiro	gerir_contas_receber
165	1	financeiro	gerir_contas_pagar
166	1	financeiro	gerir_categorias
167	1	tesouraria	ver_tesouraria
168	1	tesouraria	gerir_movimentos
169	1	tesouraria	gerir_reconciliacao
170	1	contabilidade	ver_contabilidade
171	1	contabilidade	gerir_plano_contas
172	1	contabilidade	gerir_lancamentos
173	1	contabilidade	gerir_periodos
174	1	contabilidade	gerir_ativos_fixos
175	1	contabilidade	gerir_orcamentos
176	1	contabilidade	fechar_periodo
177	1	contabilidade	ver_relatorios
178	1	impostos	ver_impostos
179	1	impostos	gerir_impostos
180	1	multi-moeda	ver_moedas
181	1	multi-moeda	gerir_moedas
182	1	centros-custo	ver_centros
183	1	centros-custo	gerir_centros
184	1	centros-custo	gerir_orcamentos
185	1	centros-custo	gerir_alocacoes
186	1	centros-custo	eliminar_centros
187	1	recursos-humanos	ver_funcionarios
188	1	recursos-humanos	gerir_funcionarios
189	1	recursos-humanos	gerir_contratos
190	1	recursos-humanos	gerir_horarios
191	1	recursos-humanos	aprovar_ausencias
192	1	recursos-humanos	processar_salarios
193	1	recursos-humanos	gerir_avaliacoes
194	1	recursos-humanos	gerir_formacoes
195	1	recursos-humanos	gerir_beneficios
196	1	recursos-humanos	ver_relatorios
197	1	pedido-ferias	ver_pedidos
198	1	pedido-ferias	submeter_pedido
199	1	crm	ver_leads
200	1	crm	gerir_leads
201	1	crm	mover_leads
202	1	crm	converter_leads
203	1	crm	eliminar_leads
204	1	crm	ver_oportunidades
205	1	crm	gerir_oportunidades
206	1	crm	gerir_atividades
207	1	assinaturas	ver_assinaturas
208	1	assinaturas	gerir_assinaturas
209	1	gestao-escolar	ver_escolar
210	1	gestao-escolar	gerir_academico
211	1	gestao-escolar	gerir_alunos
212	1	gestao-escolar	gerir_avaliacoes
213	1	gestao-escolar	gerir_frequencia
214	1	gestao-escolar	gerir_biblioteca
215	1	gestao-escolar	gerir_financeiro
216	1	gestao-escolar	gerir_comunicacao
217	1	gestao-escolar	ver_relatorios
218	1	notificacoes	ver_notificacoes
219	1	notificacoes	gerir_notificacoes
220	1	auditoria	ver_logs
221	1	seguranca	ver_seguranca
222	1	seguranca	gerir_politicas
223	1	seguranca	gerir_allowlist
224	1	sistema-configuracao	ver_configuracoes
225	1	sistema-configuracao	editar_configuracoes
226	1	sistema-configuracao	gerir_templates
227	1	sistema-configuracao	ver_logs_sistema
228	1	recrutamento	ver_vagas
229	1	recrutamento	gerir_vagas
230	1	recrutamento	ver_candidaturas
231	1	recrutamento	gerir_candidaturas
232	1	recrutamento	gerir_pipeline
233	1	recrutamento	avaliar_candidatos
234	1	recrutamento	ver_relatorios
235	8	empresa	ver_empresa
236	8	empresa	editar_empresa
237	8	empresa	gerir_filiais
238	8	empresa	gerir_licencas
239	8	clientes	ver_clientes
240	8	clientes	gerir_clientes
241	8	clientes	gerir_grupos
242	8	clientes	gerir_credito
243	8	clientes	eliminar_clientes
244	8	vendas	ver_vendas
245	8	vendas	criar_vendas
246	8	vendas	cancelar_vendas
247	8	faturacao	ver_documentos
248	8	faturacao	emitir_orcamentos
249	8	faturacao	emitir_encomendas
250	8	faturacao	emitir_faturas
251	8	faturacao	emitir_notas_credito
252	8	faturacao	configurar_series
253	8	pos	operar_pos
254	8	pos	ver_vendas
255	8	pos	gerir_terminais
256	8	pos	gerir_catalogo
257	8	stock	ver_stock
258	8	stock	gerir_produtos
259	8	stock	gerir_categorias
260	8	stock	gerir_movimentos
261	8	stock	eliminar_produtos
262	8	compras	ver_compras
263	8	compras	criar_pedidos
264	8	compras	aprovar_pedidos
265	8	compras	gerir_itens
266	8	logistica	ver_logistica
267	8	logistica	gerir_entregas
268	8	financeiro	ver_financeiro
269	8	financeiro	gerir_contas_receber
270	8	financeiro	gerir_contas_pagar
271	8	financeiro	gerir_categorias
272	8	tesouraria	ver_tesouraria
273	8	tesouraria	gerir_movimentos
274	8	tesouraria	gerir_reconciliacao
275	8	contabilidade	ver_contabilidade
276	8	contabilidade	gerir_plano_contas
277	8	contabilidade	gerir_lancamentos
278	8	contabilidade	gerir_periodos
279	8	contabilidade	gerir_ativos_fixos
280	8	contabilidade	gerir_orcamentos
281	8	contabilidade	fechar_periodo
282	8	contabilidade	ver_relatorios
283	8	impostos	ver_impostos
284	8	impostos	gerir_impostos
285	8	multi-moeda	ver_moedas
286	8	multi-moeda	gerir_moedas
287	8	centros-custo	ver_centros
288	8	centros-custo	gerir_centros
289	8	centros-custo	gerir_orcamentos
290	8	centros-custo	gerir_alocacoes
291	8	centros-custo	eliminar_centros
292	8	recursos-humanos	ver_funcionarios
293	8	recursos-humanos	gerir_funcionarios
294	8	recursos-humanos	gerir_contratos
295	8	recursos-humanos	gerir_horarios
296	8	recursos-humanos	aprovar_ausencias
297	8	recursos-humanos	processar_salarios
298	8	recursos-humanos	gerir_avaliacoes
299	8	recursos-humanos	gerir_formacoes
300	8	recursos-humanos	gerir_beneficios
301	8	recursos-humanos	ver_relatorios
302	8	pedido-ferias	ver_pedidos
303	8	pedido-ferias	submeter_pedido
304	8	crm	ver_leads
305	8	crm	gerir_leads
306	8	crm	mover_leads
307	8	crm	converter_leads
308	8	crm	eliminar_leads
309	8	crm	ver_oportunidades
310	8	crm	gerir_oportunidades
311	8	crm	gerir_atividades
312	8	assinaturas	ver_assinaturas
313	8	assinaturas	gerir_assinaturas
314	8	gestao-escolar	ver_escolar
315	8	gestao-escolar	gerir_academico
316	8	gestao-escolar	gerir_alunos
317	8	gestao-escolar	gerir_avaliacoes
318	8	gestao-escolar	gerir_frequencia
319	8	gestao-escolar	gerir_biblioteca
320	8	gestao-escolar	gerir_financeiro
321	8	gestao-escolar	gerir_comunicacao
322	8	gestao-escolar	ver_relatorios
323	8	notificacoes	ver_notificacoes
324	8	notificacoes	gerir_notificacoes
325	8	auditoria	ver_logs
326	8	seguranca	ver_seguranca
327	8	seguranca	gerir_politicas
328	8	seguranca	gerir_allowlist
329	8	sistema-configuracao	ver_configuracoes
330	8	sistema-configuracao	editar_configuracoes
331	8	sistema-configuracao	gerir_templates
332	8	sistema-configuracao	ver_logs_sistema
333	8	recrutamento	ver_vagas
334	8	recrutamento	gerir_vagas
335	8	recrutamento	ver_candidaturas
336	8	recrutamento	gerir_candidaturas
337	8	recrutamento	gerir_pipeline
338	8	recrutamento	avaliar_candidatos
339	8	recrutamento	ver_relatorios
445	1	home	ver_dashboard
446	1	chat	ver_conversas
447	1	chat	enviar_mensagem
448	1	assiduidade	ver_assiduidade
449	1	assiduidade	justificar
450	1	perfil	ver_perfil
451	1	perfil	editar_perfil
580	10	empresa	ver_empresa
581	10	empresa	editar_empresa
582	10	empresa	gerir_filiais
583	10	empresa	gerir_licencas
584	10	clientes	ver_clientes
585	10	clientes	gerir_clientes
586	10	clientes	gerir_grupos
459	8	home	ver_dashboard
460	8	chat	ver_conversas
461	8	chat	enviar_mensagem
462	8	assiduidade	ver_assiduidade
463	8	assiduidade	justificar
464	8	perfil	ver_perfil
465	8	perfil	editar_perfil
587	10	clientes	gerir_credito
588	10	clientes	eliminar_clientes
589	10	vendas	ver_vendas
590	10	vendas	criar_vendas
591	10	vendas	cancelar_vendas
592	10	faturacao	ver_documentos
593	10	faturacao	emitir_orcamentos
594	10	faturacao	emitir_encomendas
595	10	faturacao	emitir_faturas
596	10	faturacao	emitir_notas_credito
597	10	faturacao	configurar_series
598	10	pos	operar_pos
599	10	pos	ver_vendas
600	10	pos	gerir_terminais
601	10	pos	gerir_catalogo
602	10	stock	ver_stock
603	10	stock	gerir_produtos
604	10	stock	gerir_categorias
605	10	stock	gerir_movimentos
606	10	stock	eliminar_produtos
607	10	compras	ver_compras
608	10	compras	criar_pedidos
609	10	compras	aprovar_pedidos
610	10	compras	gerir_itens
611	10	logistica	ver_logistica
612	10	logistica	gerir_entregas
613	10	financeiro	ver_financeiro
614	10	financeiro	gerir_contas_receber
615	10	financeiro	gerir_contas_pagar
616	10	financeiro	gerir_categorias
617	10	tesouraria	ver_tesouraria
618	10	tesouraria	gerir_movimentos
619	10	tesouraria	gerir_reconciliacao
620	10	contabilidade	ver_contabilidade
621	10	contabilidade	gerir_plano_contas
622	10	contabilidade	gerir_lancamentos
623	10	contabilidade	gerir_periodos
624	10	contabilidade	gerir_ativos_fixos
625	10	contabilidade	gerir_orcamentos
626	10	contabilidade	fechar_periodo
627	10	contabilidade	ver_relatorios
628	10	impostos	ver_impostos
629	10	impostos	gerir_impostos
630	10	multi-moeda	ver_moedas
631	10	multi-moeda	gerir_moedas
632	10	centros-custo	ver_centros
633	10	centros-custo	gerir_centros
634	10	centros-custo	gerir_orcamentos
635	10	centros-custo	gerir_alocacoes
636	10	centros-custo	eliminar_centros
637	10	recursos-humanos	ver_funcionarios
638	10	recursos-humanos	gerir_funcionarios
639	10	recursos-humanos	gerir_contratos
640	10	recursos-humanos	gerir_horarios
641	10	recursos-humanos	aprovar_ausencias
642	10	recursos-humanos	processar_salarios
643	10	recursos-humanos	gerir_avaliacoes
644	10	recursos-humanos	gerir_formacoes
645	10	recursos-humanos	gerir_beneficios
646	10	recursos-humanos	ver_relatorios
647	10	pedido-ferias	ver_pedidos
648	10	pedido-ferias	submeter_pedido
649	10	crm	ver_leads
650	10	crm	gerir_leads
651	10	crm	mover_leads
652	10	crm	converter_leads
653	10	crm	eliminar_leads
654	10	crm	ver_oportunidades
655	10	crm	gerir_oportunidades
656	10	crm	gerir_atividades
657	10	assinaturas	ver_assinaturas
658	10	assinaturas	gerir_assinaturas
659	10	gestao-escolar	ver_escolar
660	10	gestao-escolar	gerir_academico
661	10	gestao-escolar	gerir_alunos
662	10	gestao-escolar	gerir_avaliacoes
663	10	gestao-escolar	gerir_frequencia
684	10	recrutamento	ver_relatorios
685	10	home	ver_dashboard
686	10	chat	ver_conversas
687	10	chat	enviar_mensagem
688	10	assiduidade	ver_assiduidade
689	10	assiduidade	justificar
690	10	perfil	ver_perfil
691	10	perfil	editar_perfil
702	10	autorizacao	gerir_utilizadores
703	10	autorizacao	gerir_perfis
704	10	autorizacao	gerir_permissoes
705	10	auth	ver_sessoes
\.


--
-- Data for Name: permissoes_tipo; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.permissoes_tipo (id, tipo, modulo, acao) FROM stdin;
1	funcionario	pedido-ferias	ver_pedidos
2	funcionario	pedido-ferias	submeter_pedido
3	funcionario	pedido-ferias	ver
4	funcionario	pedido-ferias	criar
5	funcionario	home	ver_dashboard
6	funcionario	chat	ver_conversas
7	funcionario	chat	enviar_mensagem
8	funcionario	assiduidade	ver_assiduidade
9	funcionario	assiduidade	justificar
10	funcionario	perfil	ver_perfil
11	funcionario	perfil	editar_perfil
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sessions (id, user_id, token_hash, ip_address, user_agent, iniciado_em, expira_em, encerrado_em, ativa) FROM stdin;
24	8	4b8b9b2a2c9878c1a627bf69a42f33a03e1445eb39bb069347ea1dd1129ad9d0	127.0.0.1:52499	curl/8.17.0	2026-06-10 13:38:17.522622+00	2026-06-10 13:53:17.519239+00	\N	t
25	8	79cd19ee7ea677d70e666c26c0970dab863e65c6b1ad5fc83fe200e72f8609b8	127.0.0.1:52516	curl/8.17.0	2026-06-10 13:38:27.267174+00	2026-06-10 13:53:27.240812+00	\N	t
26	8	e99f7d6c347d230040e1ca740ba1f77f74aa3f5fae39388c2387b2e165091edd	127.0.0.1:52137	curl/8.17.0	2026-06-10 13:38:41.450218+00	2026-06-10 13:53:41.450033+00	\N	t
27	8	3593f18cdf18b611b444bc1cfd887d57203136cce48bbbeaa1218f0fd047fa20	127.0.0.1:58853	curl/8.17.0	2026-06-10 13:38:54.912713+00	2026-06-10 13:53:54.910628+00	\N	t
28	8	0363e990e4be7d8e623b01a67b6646c8dd4d28338c868ffd15bca5805cd77849	127.0.0.1:59990		2026-06-10 13:42:02.676492+00	2026-06-10 13:57:02.675359+00	\N	t
30	8	25067c9925f690b4bb2ba034332500bad1a2350d03037f03b48bed2efc3eaf6c	127.0.0.1:56929	curl/8.17.0	2026-06-10 14:07:38.971439+00	2026-06-10 14:22:38.943779+00	\N	t
31	8	969a2aea4c0d7b0a0c26fdf68a957cee13a6cb2e80f8b2295cb1cb5abea1014a	127.0.0.1:65318	curl/8.17.0	2026-06-11 00:24:48.442284+00	2026-06-11 00:39:48.419202+00	\N	t
32	8	e6b9c24525fdb3913779284bae59ff11be9de1af4cdded00e715326557e0338a	127.0.0.1:65321		2026-06-11 00:25:01.574717+00	2026-06-11 00:40:01.572741+00	\N	t
33	8	fb25ed75dbf29513990a96c83c19c5b074a37eaa0bda23d8a6e149cea3db5f49	127.0.0.1:51613		2026-06-11 03:16:15.554464+00	2026-06-11 03:31:15.550857+00	\N	t
34	8	173839da72d917d303406242c2194021698c45438ba5704e4bb45836f3e07b22	127.0.0.1:57473		2026-06-11 03:52:10.603995+00	2026-06-11 04:07:10.602481+00	\N	t
35	8	47a7ef24b6b5cf9046b1cf0406016bde79a3c671d90d5c39c93ec8de75a97623	127.0.0.1:50909		2026-06-11 04:30:48.584381+00	2026-06-11 04:45:48.580403+00	\N	t
36	8	8008f1ddb1d49daf89d34a96533a0d70b93582a54bf8ce58ae5244278dfb8241	127.0.0.1:57461		2026-06-11 07:31:42.506087+00	2026-06-11 07:46:42.47733+00	\N	t
37	8	eac56f14ae43dc3577f94ef4c4916fc7b6e11063571d49fc0c5a70549b50c782	127.0.0.1:51079		2026-06-11 07:54:39.424735+00	2026-06-11 08:09:39.423596+00	\N	t
38	8	9863cbe43289d52aeca222d0d6b1f0ff851385d82e5c83e6e986c7983e87c9bb	127.0.0.1:49981		2026-06-11 08:12:12.039085+00	2026-06-11 08:27:12.036363+00	\N	t
39	8	8e8e91f510abad6e8eac93773e1b2b4f88a7f8244d65f984ac9c5458d4313996	127.0.0.1:51525		2026-06-11 08:36:58.632412+00	2026-06-11 08:51:58.623268+00	\N	t
40	8	d75f578a12bc5130ba797c787fefc431af6bbbed239a05146ad74fbbb495c354	127.0.0.1:64482		2026-06-11 09:51:35.760199+00	2026-06-11 10:06:35.747167+00	\N	t
41	8	57e02084cb386001eb513b25fa0a70e799a6616aae6204253ef7b06ccdcc0aa7	127.0.0.1:60807		2026-06-11 10:09:53.146648+00	2026-06-11 10:24:53.145969+00	\N	t
42	8	df476bdf3fac0458ffb3df22d15f28698ff8d0b1d2a5091493bf3b09fdabc655	127.0.0.1:51314	curl/8.17.0	2026-06-11 12:24:30.848201+00	2026-06-11 12:39:30.801591+00	\N	t
43	8	d8633fbae00573e00dd5d953ff238e575fa395925169ba54de1f856c927f33af	127.0.0.1:53490		2026-06-11 12:35:33.744558+00	2026-06-11 12:50:33.728581+00	\N	t
44	8	5e5b91a47576c16ab7bdac6272a0a6a156d77caaac68e119c4cc122702bb1e0d	127.0.0.1:51411	curl/8.17.0	2026-06-11 12:57:00.891516+00	2026-06-11 13:12:00.876837+00	\N	t
45	8	0daae2aa8dfcf31697b33f23827c3c8cac910d0d8933b5a3c1f6cdfca9da7464	127.0.0.1:53625		2026-06-11 13:11:31.635998+00	2026-06-11 13:26:31.635424+00	\N	t
46	8	b6929e825773d813a0113dc84e431a28810224d7224a6e487b5e957d98680cd1	127.0.0.1:63675		2026-06-11 13:30:40.741035+00	2026-06-11 13:45:40.728123+00	\N	t
47	8	0dab33c0e827e1a2a9df410ae48d907920ebdeda60654abf570893bf52ad114d	127.0.0.1:62342		2026-06-11 14:03:45.862916+00	2026-06-11 14:18:45.895188+00	\N	t
48	8	4b4161795065dc8d1b31a9f719723aaf5852fc75c02d69c8ad09a9442b31ab42	127.0.0.1:62574		2026-06-11 14:37:38.250308+00	2026-06-11 14:52:38.226061+00	\N	t
49	8	9a962be65ed4a50048fbb832f73ba5ebd9ded5a1e5affa54309639ec8727de06	127.0.0.1:52776		2026-06-11 16:41:56.175373+00	2026-06-11 16:56:56.150775+00	\N	t
51	8	18989740984aa632410dd15dd5e030e5e869dce3876a3d95f872292c1889adc0	127.0.0.1:51327		2026-06-11 17:27:49.070898+00	2026-06-11 17:42:49.068943+00	\N	t
52	7	27a045b9160d681fde840ebcba9acff84c8d754b70c7fd6fcca564dbda1f5333	127.0.0.1:57479		2026-06-11 17:31:31.845747+00	2026-06-11 17:46:31.818165+00	\N	t
54	8	98632ae5ca8c02a19a9ffcbc8c08866c5aea55184fbabe6201d32d7d646f3839	127.0.0.1:64798		2026-06-11 17:44:01.407352+00	2026-06-11 17:59:01.407508+00	\N	t
53	7	f7a72403081e9953e0da1c3ac6e8fd897b16afc824fa922db08b9c9917239719	127.0.0.1:64796		2026-06-11 17:44:01.340952+00	2026-06-11 17:59:01.284549+00	2026-06-11 17:44:08.181171+00	f
55	8	5425957b64cdf1b4b126c01f236de8ca3e85aa88f6cea01c683b65984b09520a	127.0.0.1:50747		2026-06-11 17:45:05.849198+00	2026-06-11 18:00:05.810174+00	\N	t
56	7	07c6608e0a86ef4f20016145ceadd948d65c83bb4ef57120e42abe381c0ac924	127.0.0.1:55061		2026-06-11 17:46:47.788451+00	2026-06-11 18:01:47.784515+00	2026-06-11 17:48:52.54166+00	f
57	8	1b23315566da98c05987fb89c8b3290767f23cd4bc35ad34f5f614b8141b1ece	127.0.0.1:56106		2026-06-11 17:49:19.375885+00	2026-06-11 18:04:19.37145+00	\N	t
58	8	986eef3772545c8aef036b2414381d7048fd39b9c046e04a90df6747da677f55	127.0.0.1:64972		2026-06-11 18:14:05.649563+00	2026-06-11 18:29:05.64793+00	\N	t
60	7	eb3100f90487a917a529a596b0a902138726ad939abc5e6367e4a8bc3ed7387c	127.0.0.1:51481		2026-06-11 18:14:24.444367+00	2026-06-11 18:29:24.443836+00	\N	t
61	7	53c9a642f84fb12e19edbbf366af08af389166cf0d3bd485744cfe3d53055654	127.0.0.1:63091		2026-06-11 18:37:31.638882+00	2026-06-11 18:52:31.615698+00	\N	t
62	8	58e8fab41aee40f15f80642a17b986cedb501eae569b3ee188f7fe69f223868b	127.0.0.1:63093		2026-06-11 18:37:31.689144+00	2026-06-11 18:52:31.688341+00	\N	t
63	7	9472e0fb520bfff1cd3ff62ccd8ab4b5213552459bdf2453ad90c51802a3e873	127.0.0.1:50620		2026-06-11 19:14:55.112511+00	2026-06-11 19:29:55.112604+00	\N	t
64	8	1e55bd0ece7f9414b5a30a48c362eedc22eecaf8c5f3dc8f849a11b1350c9b64	127.0.0.1:50621		2026-06-11 19:14:55.150319+00	2026-06-11 19:29:55.15015+00	\N	t
65	8	1946900a4df498597fe08a1808e384f7c3f47c9aa69ba38af6564140c3fe1798	127.0.0.1:50735		2026-06-11 19:36:54.254409+00	2026-06-11 19:51:54.252484+00	\N	t
67	7	b419e257f13f7fa0a984beeb6f59d630170cb94e421b5b64a4e57620f89d8c0b	127.0.0.1:53292		2026-06-12 01:40:40.990228+00	2026-06-12 01:55:40.981139+00	\N	t
68	8	2c49c48c8247f8f9eb8ecfb7d7022269649e55a762930a77d039658d2069ceda	127.0.0.1:53294		2026-06-12 01:40:41.030704+00	2026-06-12 01:55:41.02876+00	\N	t
69	8	1b7fe57d957ddcba52426a511f94c3e48d7760127bace02c344c9e9d1162bc92	127.0.0.1:49816		2026-06-12 01:41:43.265195+00	2026-06-12 01:56:43.262594+00	2026-06-12 01:41:48.42725+00	f
70	8	59507706f05cc47fd5b144c68d01aff87e5448469476411c856754411530ca5d	127.0.0.1:58637		2026-06-12 01:41:59.201469+00	2026-06-12 01:56:59.180924+00	\N	t
71	8	1c3882b3f272cc3fa91e218b34b16489fb75342f9034ca0a53ed9da1707aea3e	127.0.0.1:56431		2026-06-12 04:12:45.818235+00	2026-06-12 04:27:45.812299+00	2026-06-12 04:12:53.89742+00	f
75	7	b479e03042a607ffbce810f488d781f67c6ec574458080457439faf4990be556	127.0.0.1:54224		2026-06-12 04:13:33.365983+00	2026-06-12 04:28:33.364401+00	\N	t
73	8	e66c6a903e52128ff3dc2b71bab519f52d0b0134059ba2b507afc321d48b1f20	127.0.0.1:60860		2026-06-12 04:13:08.594492+00	2026-06-12 04:28:08.557664+00	2026-06-12 04:14:26.404445+00	f
76	8	154eed31659f2a75ee33f3aa022b350d2371add02032ae62040c3163c9893303	127.0.0.1:52351		2026-06-12 04:14:33.381991+00	2026-06-12 04:29:33.379212+00	\N	t
78	7	154b887b3035d20eb09e90194823ece1e2f6054e54d915ccd830e573da98ca2b	127.0.0.1:51766		2026-06-12 04:53:03.955111+00	2026-06-12 05:08:03.931752+00	\N	t
79	8	696a0b82e2aae0303e5a09948e3408738e778f9a47b0c0cedac9078435100702	127.0.0.1:51768		2026-06-12 04:53:03.990966+00	2026-06-12 05:08:03.989054+00	\N	t
80	7	7b8bdc5a64f2848018fdcfffcf33140e02f7be76de0af2102e8c2f4feaac2628	127.0.0.1:56925		2026-06-12 05:13:25.000034+00	2026-06-12 05:28:24.999059+00	\N	t
81	8	af4ee42e329a4fb6345a939e6796a42a182fa000c8c45079f7edcb5f6f7b36de	127.0.0.1:56926		2026-06-12 05:13:25.022576+00	2026-06-12 05:28:25.021062+00	\N	t
82	8	a4e7a1b1e41346a61648745de8f92061393cfffed921c36fac72b0933da67d31	127.0.0.1:51263		2026-06-12 05:14:56.716086+00	2026-06-12 05:29:56.713935+00	2026-06-12 05:15:10.646744+00	f
83	8	e709dffc13d8ef63b4b56faf62f65d20623304dac8e941941bf246c60ffc1c6d	127.0.0.1:54378		2026-06-12 05:15:18.5467+00	2026-06-12 05:30:18.513756+00	\N	t
84	8	f8560ccdbeec94860437dd011119b47777041ad183d29971e40b9f6221362086	127.0.0.1:60366		2026-06-12 06:32:01.423102+00	2026-06-12 06:47:01.414766+00	\N	t
86	7	e8c0d3a5f5d23f67a01ce9e1a44c2da0822ba7524f90b4dce8c058249c69c777	127.0.0.1:58475		2026-06-12 08:18:08.752038+00	2026-06-12 08:33:08.725676+00	\N	t
87	8	47a703a61a68fd9c80c53270d72392bdf7b18af549eaa2fd3e4faa530e5a2f62	127.0.0.1:58478		2026-06-12 08:18:08.8247+00	2026-06-12 08:33:08.822099+00	\N	t
88	7	64522b9507c384a2ab879250c7cfd0e2ac05e60f2394630b6a0c96a5b99c9f4c	127.0.0.1:58482		2026-06-12 08:18:18.250894+00	2026-06-12 08:33:18.246722+00	\N	t
89	8	fdb4bbdf6f93a3d6d79042d41ba418a0b67f10db90266d9ae99c5e1b668e6f08	127.0.0.1:49977	curl/8.17.0	2026-06-12 08:19:02.471899+00	2026-06-12 08:34:02.465734+00	\N	t
90	7	4349c2ceca5e83e6b9b8005ffc0d722e75ab6fb85fc223b22d5aed6fbdfb3719	127.0.0.1:65481		2026-06-12 08:22:13.48553+00	2026-06-12 08:37:13.456184+00	\N	t
91	8	6478e188613ba2c2cdd3add1d18a975a33d9f25066e5629f193a380852658aca	127.0.0.1:56453	curl/8.17.0	2026-06-12 08:24:46.510455+00	2026-06-12 08:39:46.507766+00	\N	t
92	8	892522100c11b04182602516898c2e74deca3a2857038995d02b0f86361e7834	127.0.0.1:54793	curl/8.17.0	2026-06-12 08:24:58.118041+00	2026-06-12 08:39:58.114992+00	\N	t
93	8	2348b845647d79ae6eb8f97b9d3994c89094c51ad958c8144272beed8132cf30	127.0.0.1:62234	curl/8.17.0	2026-06-12 08:27:21.1818+00	2026-06-12 08:42:21.180716+00	\N	t
94	8	db45fcb6cadaa5dba2c6776708875324841890e9306ba9f43c8721107686c73c	127.0.0.1:59266	curl/8.17.0	2026-06-12 08:27:43.502941+00	2026-06-12 08:42:43.499824+00	\N	t
95	7	2bcd47653e828b03a84390830a2bc3f7fa78624f018b1133c796ffc71ab92a4a	127.0.0.1:52661	curl/8.17.0	2026-06-12 08:44:16.264836+00	2026-06-12 08:59:16.262226+00	\N	t
96	7	a421754357cef3b03ce444ff06199e493ce4f780618606f244c9ce0bae39fe57	127.0.0.1:52669		2026-06-12 08:44:29.510357+00	2026-06-12 08:59:29.508962+00	\N	t
97	8	2826fba99dabfc4398e7985af68482efa406d2d4ac686371f18500ee3e686486	127.0.0.1:59455	curl/8.17.0	2026-06-12 08:46:13.718471+00	2026-06-12 09:01:13.715062+00	\N	t
98	7	99a73d6db6ddc723b22e106e1d0a01f73a383212b94cf17344497731e3bfc620	127.0.0.1:55082		2026-06-12 13:03:40.810524+00	2026-06-12 13:18:40.746041+00	\N	t
99	7	13a252f4b0a6d9955d7e97d01e0eebb01249c6d2c2492a01e3ddada985dff856	127.0.0.1:58733		2026-06-12 13:21:58.764365+00	2026-06-12 13:36:58.764458+00	\N	t
100	7	002d07165d85936c2bf29e4c8883b7ac6981afb7a5c75eba348f38d3733c1ba1	127.0.0.1:49310		2026-06-12 13:58:40.579783+00	2026-06-12 14:13:40.566805+00	\N	t
101	7	5827330f7aa70ac60adbdd0fe8d1c9317bb50ae1df4157b0df82cc367e4b83d7	127.0.0.1:50364		2026-06-12 15:09:49.647218+00	2026-06-12 15:24:49.635973+00	\N	t
102	7	834d0081016e6b84ffa02cd1c7c3803a3d17ee34edc22d704769d82f0796a8e4	127.0.0.1:59649		2026-06-12 15:31:42.981647+00	2026-06-12 15:46:42.981156+00	\N	t
103	7	71bf3b0d97247fc333abed12f7395fad491fd0725d721216a7d789e63ec36daa	127.0.0.1:55446		2026-06-12 17:08:05.083211+00	2026-06-12 17:23:04.980954+00	\N	t
104	7	10387961a9e6d73b0063168786e37deb29637946de28060dd0f99c05deea7a48	127.0.0.1:53189		2026-06-12 18:01:39.018572+00	2026-06-12 18:16:39.006889+00	\N	t
105	7	87661eb69e09f4c01cd2a228bdde589ec696bb819e773c665e94e20a83d30207	127.0.0.1:61705		2026-06-12 18:30:57.095597+00	2026-06-12 18:45:57.09606+00	\N	t
106	7	a9fc1d461c84f17c78446207fd3882827d66dd66ff3216e58f0fc315cb190d34	127.0.0.1:51175		2026-06-12 19:00:26.286842+00	2026-06-12 19:15:26.282581+00	\N	t
107	7	415f962687fd2fb7982541da2d200f542428f0dae4bd754d4b9769ec703ab97b	127.0.0.1:56657		2026-06-12 19:41:42.270613+00	2026-06-12 19:56:42.262959+00	\N	t
108	7	fd1a2e65958c1c82913c449377ec36d99478f542cac74a9b4e9b21708cca8998	127.0.0.1:55415		2026-06-12 20:24:10.461588+00	2026-06-12 20:39:10.453884+00	\N	t
109	7	b82c10fb8f86f5dd78ddcc16b6a3eca05a4363d7034e2dd1fab33d66f50fb7f8	127.0.0.1:64836		2026-06-12 20:45:43.72412+00	2026-06-12 21:00:43.720082+00	\N	t
110	7	ab192a3a723e1d0f11b1fe65a968f8f9cde0242eefbcc0efb3f7cb054b22cfda	127.0.0.1:49975		2026-06-12 21:56:30.625912+00	2026-06-12 22:11:30.623996+00	\N	t
111	7	477d555b6aba97cdac829185118b18ffe0124e97199c2d5390c2c5dc0ae6e047	127.0.0.1:50365		2026-06-13 03:11:15.339907+00	2026-06-13 03:26:15.33005+00	\N	t
112	7	86b24be23c3f4c2e528398a0a66c76699e0d46b57a252f836b13a54d74464e02	127.0.0.1:59834		2026-06-13 04:30:03.105247+00	2026-06-13 04:45:03.042475+00	\N	t
113	7	d9ceabae01a24dd4e07eb7be772192c94f30ec4a20f522bc8bc2db6d54103043	127.0.0.1:52920		2026-06-13 10:15:56.478227+00	2026-06-13 10:30:56.43077+00	\N	t
114	7	fd293f62db07b4ae45d2b14f1a24fe84bb9601aac8ef9f570c139e913e97637b	127.0.0.1:51390		2026-06-13 16:05:34.270574+00	2026-06-13 16:20:34.194861+00	\N	t
115	7	1d2f11b59e88678bfeaf438196bb35a8a4a77ae5ebd37a0031ffbb8076967061	127.0.0.1:57598		2026-06-13 16:38:45.514634+00	2026-06-13 16:53:45.510378+00	\N	t
116	9	2447c7af11fff557025b102a3ef893aa6f87e75852e67022a064a2d096d9cd43	127.0.0.1:57602	curl/8.17.0	2026-06-13 16:39:06.88837+00	2026-06-13 16:54:06.887044+00	\N	t
117	7	67c19b7f072e87229d7ed99e76665b50cc5f213a2ed6b1e1e80ba795e28b79b5	127.0.0.1:58175		2026-06-13 16:53:17.862916+00	2026-06-13 17:08:17.849144+00	\N	t
118	7	660f46ce03ae1829ab35b0db821d82c6086834e4762a787480fee3e0c6d32fe7	127.0.0.1:49397		2026-06-13 20:39:10.668221+00	2026-06-13 20:54:10.643417+00	\N	t
119	7	09b0b3a861fbe8a667e317f8a43a811ece29872b1fdba724f533192994b13f2f	127.0.0.1:64961		2026-06-13 23:38:04.45666+00	2026-06-13 23:53:04.436048+00	\N	t
120	7	5b715bb9b30dfdfd68a22a2a8d39808acb9a590f1f928e434e163cbf1b556a31	127.0.0.1:64804		2026-06-14 05:02:18.676+00	2026-06-14 05:17:18.637099+00	\N	t
121	7	e6445bc2406ff1a227cc56a5a8bcaa9ce6f6ccfa190b191d178447c526ef59d6	127.0.0.1:54166		2026-06-14 05:20:53.121946+00	2026-06-14 05:35:53.121791+00	\N	t
122	7	460a23bd3bd29dd78239afb6beb5da40b33b904c6f7272e59b45e96cad288aa2	127.0.0.1:59735		2026-06-14 06:35:14.87963+00	2026-06-14 06:50:14.840802+00	\N	t
123	7	58e7186aa4c20458551bf58432824b4b720b8b09393f3ce3c7ab2f994f30d25c	127.0.0.1:53443		2026-06-14 07:10:31.937597+00	2026-06-14 07:25:31.929819+00	\N	t
124	7	7173aa4afac76cc7fccef7313882846be76351967ab6538cbcd0c815ac2c90bd	127.0.0.1:62560		2026-06-14 08:59:43.095845+00	2026-06-14 09:14:43.077163+00	\N	t
125	7	3f618ebbe482ae73ce603274ff19ba2a496be7d7e5da4079a8ea2e182880d76d	127.0.0.1:63413		2026-06-14 10:03:38.19401+00	2026-06-14 10:18:38.186144+00	\N	t
126	1	883faf0562707bc4bb7062ab41e143c6d950e6076d5d47c0fd5ec1ecebab1f19	127.0.0.1:63048		2026-06-14 21:31:14.388952+00	2026-06-14 21:46:14.251074+00	\N	t
127	7	6b944ba91faaa0747606444e9ba15b5932eb07e241c0a2a4c63cab6ff78055e7	127.0.0.1:60217		2026-06-14 21:32:26.145229+00	2026-06-14 21:47:26.143101+00	\N	t
128	7	6f495007f08eedcd74ef79ed4e21446d4e0336437d6efab381a6ccfff5f033f3	127.0.0.1:54858		2026-06-15 02:39:36.592222+00	2026-06-15 02:54:36.567364+00	\N	t
129	7	871a05401aaa99c1f8a5757397fcd1fde497afad54770b898f65ab03b3a58d3e	127.0.0.1:64374		2026-06-15 03:13:39.515514+00	2026-06-15 03:28:39.504412+00	\N	t
130	7	8259795542ad8ff55c45c9c2174fb662b8c44a7ec552380819d07b76251bf16e	127.0.0.1:58918		2026-06-15 12:58:29.66158+00	2026-06-15 13:13:29.251615+00	\N	t
131	7	f49ac972fcea83fd96d0919d56e6c899818f26ece8be0d966473ac61e0df0e30	127.0.0.1:62240		2026-06-15 13:13:32.603415+00	2026-06-15 13:28:32.597471+00	\N	t
132	7	c10eccf021dbf6f433cd5a4677d3446bfdadbd220404cc862a45cc196cd56811	127.0.0.1:63398		2026-06-15 13:38:00.143901+00	2026-06-15 13:53:00.140389+00	\N	t
133	7	21c5c29127591802cbce177358cf8f8efa80f5603a7c09b5c4ba016f26f604f4	127.0.0.1:57801		2026-06-15 14:07:44.558286+00	2026-06-15 14:22:44.554805+00	\N	t
134	7	750ebea5a0a6de59126d5c89754501e48b87633a0acbd74de56d999477a9d801	127.0.0.1:54876		2026-06-15 14:44:30.301517+00	2026-06-15 14:59:30.298443+00	\N	t
135	7	6da3df45cc658715b4b38a63a9ef63bd08252884a5ccdffeab6068cb73f25606	127.0.0.1:62994		2026-06-15 16:24:18.217923+00	2026-06-15 16:39:18.206362+00	\N	t
136	7	4f837c45c3cab0281be701dddb0fed515420ab8a0b6f40638ba092b59df21596	127.0.0.1:51347		2026-06-15 16:38:51.19009+00	2026-06-15 16:53:51.187889+00	\N	t
137	7	e2d37116577382c56d03754a113a6e4b7cea3525b389a50505179795ae642038	127.0.0.1:52943		2026-06-15 16:57:06.376544+00	2026-06-15 17:12:06.379997+00	\N	t
138	7	b8738f053ea348de6ab2b82b900d526d1b950ffdc1cf19bd6426cf529a930021	127.0.0.1:61004		2026-06-15 17:22:31.758328+00	2026-06-15 17:37:31.751693+00	\N	t
139	7	ae1fa1799c2ea7354122c1201f9e8ada94c4fd76b65f33140d9675dd40090c5f	127.0.0.1:55948		2026-06-15 17:43:53.70957+00	2026-06-15 17:58:53.70527+00	\N	t
140	7	486c810f1aca1371c259324e27666bd3eb1fb1986f6235bb64bc2bfe062f4a57	127.0.0.1:61454		2026-06-16 04:53:36.205304+00	2026-06-16 05:08:36.208809+00	\N	t
141	7	e5398872c2e22b552b8fe7f0ad7371c62237002b1a1457ed7f65dc2de14043cd	127.0.0.1:59950		2026-06-16 12:19:35.943479+00	2026-06-16 12:34:35.919432+00	\N	t
142	7	56cc8e89f40a9d1543216cf106e9ab9389c436e06a06a88f2d92f7aa1f8c3cbd	127.0.0.1:51358		2026-06-16 13:19:01.128182+00	2026-06-16 13:34:01.115013+00	\N	t
143	7	5f330f799a0c92851ecfed9fe60343cf96f94cabf8d803dfa73e2aab630456f7	127.0.0.1:50361		2026-06-16 14:01:41.851744+00	2026-06-16 14:16:41.838086+00	\N	t
144	7	66d84fd07117bf3c1f247d2b3c867786a3ac4aa9a1efb25f94ee7d7f913110af	127.0.0.1:49196		2026-06-18 13:54:10.046839+00	2026-06-18 14:09:10.034669+00	\N	t
145	7	fa767c87ca15f5a8cc2e310694f13033018e95b47c6a35d89b876ec8ef466f7c	127.0.0.1:62264		2026-06-18 14:08:42.339428+00	2026-06-18 14:23:42.338652+00	\N	t
146	7	9d3c0a2da8ff4b966a0febe7708bdd4f4210e08123a858e9b400b4d6201f2cd2	127.0.0.1:64807		2026-06-18 14:27:55.19729+00	2026-06-18 14:42:55.195849+00	\N	t
147	7	401ac45d6c0caff761555b25805adc9fbccfe1dd7695987d5d93336bf957af33	127.0.0.1:57539		2026-06-18 14:42:25.479458+00	2026-06-18 14:57:25.478513+00	\N	t
148	7	9811225f6645fa628e75ab4df6cf5bd120f0cc570bfc428f9fb50f44bcc1dd17	127.0.0.1:53412		2026-06-18 18:50:18.610151+00	2026-06-18 19:05:18.581622+00	\N	t
149	7	f11f46a2450ffd988c15b37a73fc156d8128b99612977300ee2c64178bd138f4	127.0.0.1:59200		2026-06-18 19:21:11.014819+00	2026-06-18 19:36:11.013432+00	\N	t
150	7	0de04992be38bdb5329cf395f514f3544c38868d5367062ec73f00723091a1f9	127.0.0.1:58026		2026-06-18 19:35:42.613141+00	2026-06-18 19:50:42.612173+00	\N	t
151	7	aa8115da709c03fa5db7500c5ccbdbe72d32f6afe93fbcc60315d600f3094cf6	127.0.0.1:64668		2026-06-18 19:50:24.452418+00	2026-06-18 20:05:24.449216+00	\N	t
152	7	393c769085254d0433ee8375b723e0305c3f60cf43e26506f0ff40d6c572b696	127.0.0.1:59280		2026-06-18 20:05:00.51402+00	2026-06-18 20:20:00.514249+00	\N	t
153	7	e0fde08a4c64271384a07363f6cae0cb469d2c1aa196b106f59a49c483d9ccea	127.0.0.1:49818		2026-06-18 22:22:22.879611+00	2026-06-18 22:37:22.868593+00	\N	t
154	7	cfb885e73b3bdc462bac821e57953e38637cc4917f0f2ecea52c6d35ab5da5d6	127.0.0.1:52293		2026-06-19 14:18:00.13609+00	2026-06-19 14:33:00.126041+00	\N	t
155	7	dad6347fdbbe8d65393e3586cdc5d1c99d12cb583b4d898e44bae1c21f686120	127.0.0.1:54881		2026-06-19 14:34:59.252008+00	2026-06-19 14:49:59.251466+00	2026-06-19 14:35:03.143849+00	f
156	8	380008c148ccad87fa98ef64bdbdee472b7e6641329e1b098b7593376fa11722	127.0.0.1:53833		2026-06-19 14:46:14.639089+00	2026-06-19 15:01:14.630365+00	\N	t
157	8	840dcdcc88bc539a5dd0881cb7692f392270060a3b05cea88f893b64ae12a9c2	127.0.0.1:53696		2026-06-19 17:00:56.117136+00	2026-06-19 17:15:56.114214+00	2026-06-19 17:01:34.605017+00	f
158	7	af2484fc2f1d16c0b2bc9d7df417a98dfe37c0a99b461207bea8a8203a41a8ed	127.0.0.1:51945		2026-06-19 17:02:48.282489+00	2026-06-19 17:17:48.254741+00	\N	t
159	7	2f2931eb3ac9b9e38cd6f59d2bdb122f69f1284de0cb4c87b63dab38867f4d9b	127.0.0.1:57975		2026-06-19 17:19:17.448168+00	2026-06-19 17:34:17.441576+00	\N	t
160	8	89b53464e97a3feda5437d5a80761874bdbe6f12f28765a1041fbacb807a0109	127.0.0.1:52431		2026-06-19 17:45:15.140771+00	2026-06-19 18:00:15.138899+00	\N	t
161	8	74d09abe2695442a999c01083b8c641c774a928c3bd5e17366838c93d9e9abfc	127.0.0.1:63242		2026-06-19 18:03:09.629143+00	2026-06-19 18:18:09.62744+00	\N	t
162	8	eb6123e240726e9e199ba73be8e17bbcc000095a802b87967ae8709a4cb74ff7	[::1]:63253	curl/8.17.0	2026-06-19 18:03:38.958679+00	2026-06-19 18:18:38.937145+00	\N	t
163	8	d1104e134bfdceef3e6f96674500a1e00ee47ff894060dce0f89f4b6b1ca57d7	[::1]:60846	curl/8.17.0	2026-06-19 18:09:30.846319+00	2026-06-19 18:24:30.834548+00	\N	t
164	7	70e409b4cb087028e33e2e8ffbefce6b6733ffb92c4d64c9881dd78434c68f9f	127.0.0.1:64204		2026-06-19 18:20:05.447537+00	2026-06-19 18:35:05.445337+00	2026-06-19 18:20:55.669846+00	f
165	8	c181cd82785bfd48b573634fc0b29edbb2928fc4e6735e60b71a093b91bce8fc	127.0.0.1:64791		2026-06-19 18:22:25.060712+00	2026-06-19 18:37:25.018169+00	2026-06-19 18:23:21.19212+00	f
166	7	c5e86599108c2ac8401ac344cdb339ecbd9dc8fba38bf40bf1321e361048c258	127.0.0.1:55887		2026-06-19 18:24:28.363805+00	2026-06-19 18:39:28.362277+00	2026-06-19 18:25:01.032902+00	f
167	9	976eb62e38dc8d2e5b048ff1a007c82230ae370db37e3fc8382f1d20d3dd35d3	[::1]:50762	curl/8.17.0	2026-06-19 18:27:46.984841+00	2026-06-19 18:42:46.970664+00	\N	t
168	9	126283bdfdf42df976b2a1b0cc7d1b8ae141b268e61a049b207e6bee48965890	127.0.0.1:59290		2026-06-19 18:29:57.059773+00	2026-06-19 18:44:57.057118+00	2026-06-19 18:31:48.805209+00	f
170	8	b926995f91cf26f793b32bcc353ec6308c8fb132ee423bd137f18120c31eec70	127.0.0.1:63249		2026-06-19 18:35:31.295455+00	2026-06-19 18:50:31.295054+00	\N	t
173	8	79aa180cdfa731be0b5e87236b9a22f8cfaf9ced83f934a031340f6575d63dc5	127.0.0.1:55003		2026-06-19 18:52:29.446609+00	2026-06-19 19:07:29.446834+00	\N	t
175	7	1947e1ba79ca296b34739d015b63293c1af391fd6b038b7cfc7da311cc298ef4	127.0.0.1:60259		2026-06-19 18:53:30.22293+00	2026-06-19 19:08:30.22113+00	\N	t
176	7	b736d12c6ff7c26a2a901653cd3e5d559377a731cffa1e7cff5cf9c33a837b87	[::1]:58425	curl/8.17.0	2026-06-19 18:59:06.019035+00	2026-06-19 19:14:06.017318+00	\N	t
177	7	cfe3f3e1878cd822b84dd96f0c4e95e721e2050be121dc3d62d7fe63f2c7ca54	[::1]:54809	curl/8.17.0	2026-06-19 19:13:08.006353+00	2026-06-19 19:28:08.002886+00	\N	t
178	7	7fa8ab6e70b0515c3e9937d4aaa711275a8eb1b6064cbeb1e0b7bcb4f23a4b31	[::1]:55045	curl/8.17.0	2026-06-19 19:20:43.698996+00	2026-06-19 19:35:43.669321+00	\N	t
169	10	3c4a443e27cfe9148ce140aa7190a79c479c18370126dbfc92fee0a1b9d05665	127.0.0.1:52345		2026-06-19 18:32:21.6815+00	2026-06-19 18:47:21.679661+00	2026-06-19 19:20:43.996695+00	f
171	10	4751ae85ebde8094a9fa8eb8ff29834cd616b1f3b4589200982d86d94e26f6e3	127.0.0.1:54738		2026-06-19 18:47:04.252015+00	2026-06-19 19:02:04.250807+00	2026-06-19 19:20:43.996695+00	f
172	10	538063c321a87f2f9f18649a41426bbe8e8c277a44ee03d5cc4eee03a7e4e07c	127.0.0.1:49979		2026-06-19 18:47:27.967947+00	2026-06-19 19:02:27.967419+00	2026-06-19 19:20:43.996695+00	f
174	10	bf9c8199dd000976d9d3f35fc42d3966e45a08b952ace7b02b9b510071b28e3a	127.0.0.1:55007		2026-06-19 18:52:31.10872+00	2026-06-19 19:07:31.10767+00	2026-06-19 19:20:43.996695+00	f
179	8	8e587c6fc9de51aa60d9ee17be512244a24be35088ef3f023581d0975bb07d5f	127.0.0.1:62398		2026-06-19 19:21:18.838028+00	2026-06-19 19:36:18.834061+00	\N	t
180	7	464c967624feb05ce4d3ae4617677bf427ec10f03be28ebd38069a6be6313eac	127.0.0.1:62406		2026-06-19 19:22:07.994643+00	2026-06-19 19:37:07.992763+00	\N	t
181	10	7eb575f17cfaa0ca20ee855dc798db53488bca77be7bd015a5a34d039d68a64f	127.0.0.1:53749		2026-06-19 19:29:07.740226+00	2026-06-19 19:44:07.739982+00	\N	t
182	7	a9a29bcbd7d956f76c70c37e35d3fd85cc488aaa209270d4c8c9da61668f0eed	127.0.0.1:63307		2026-06-19 19:55:40.724387+00	2026-06-19 20:10:40.723033+00	\N	t
183	10	fb0eb7561528d92dec57a5e3b39fa425b4672da028643bb85ad358c46380a145	127.0.0.1:63614		2026-06-19 20:10:44.699634+00	2026-06-19 20:25:44.69789+00	\N	t
184	7	e311861b06b7901c6594353463b645073195a0de7958b1f0cdf6c3827c996dfa	127.0.0.1:62385		2026-06-19 20:20:01.45435+00	2026-06-19 20:35:01.452969+00	\N	t
185	7	a12180f389ffed88ef8eec883b4e28a4c04f608e69e457fd30627ae250d6f962	127.0.0.1:53836		2026-06-19 20:30:18.977633+00	2026-06-19 20:45:18.971249+00	\N	t
186	7	ddb8758818bc4555f74fa8457551ab58c550ecc48d8801df8b287e88f023f586	[::1]:59252	curl/8.17.0	2026-06-19 20:35:46.330616+00	2026-06-19 20:50:46.28193+00	\N	t
187	10	fddcd852b80dc79657de830b7cdf124aec13aad89dbdc664c1efb088a64423dc	127.0.0.1:51304		2026-06-19 20:36:19.395218+00	2026-06-19 20:51:19.391168+00	\N	t
188	10	163aa5190ff691bbf0d95554a9894c9f3405224385494bd3df1d948f3332ab9a	[::1]:50791	curl/8.17.0	2026-06-19 20:49:47.793817+00	2026-06-19 21:04:47.79089+00	\N	t
189	10	ede775c506daf8aba8e1b9a4b518a4dee231d7225a2375b3b2d8643b82d84dd3	127.0.0.1:65489		2026-06-20 05:33:42.318226+00	2026-06-20 05:48:42.303371+00	\N	t
190	7	5951cd6f2ca64c1d2f4fecd9f84d5ce97b69cef7f526347e77b20668c63cb1b8	[::1]:63615	curl/8.17.0	2026-06-20 05:41:29.316482+00	2026-06-20 05:56:29.315071+00	\N	t
191	10	82a6faee82f0736a40a05b15aaf97f03635e8aa3e0e7702874f493eb727358b6	127.0.0.1:62011		2026-06-20 05:57:41.928403+00	2026-06-20 06:12:41.992313+00	\N	t
192	7	d1de075519ddae137413488df844b49edeba48a6bfa23eaa8a392580dc748b24	[::1]:55981	curl/8.17.0	2026-06-20 06:10:28.801331+00	2026-06-20 06:25:28.797254+00	\N	t
193	7	7bbfbb8016da9c3477e850737d10526dcf996bcd09ec028ea1fdd510a2c28c3d	[::1]:63538	curl/8.17.0	2026-06-20 07:39:15.990542+00	2026-06-20 07:54:15.974362+00	\N	t
194	7	37626c47fd9c55889479171b3d2bb12fbb8abbfd771c970961adbc5808db4bfd	[::1]:51408	curl/8.17.0	2026-06-20 07:45:29.731016+00	2026-06-20 08:00:29.729336+00	\N	t
195	7	caefe14272cbee6024e10063b1a2a619928c496cf89ad988ae72a340f7801992	[::1]:52326	curl/8.17.0	2026-06-20 07:48:33.180504+00	2026-06-20 08:03:33.17992+00	\N	t
196	7	59e5a88d310d7a8763276f1ba7470e8c8a594fa497c0c4b378a087ea8bc06e03	[::1]:55732	curl/8.17.0	2026-06-20 07:58:21.672627+00	2026-06-20 08:13:21.650808+00	\N	t
197	10	c25c98ad2fda6fe532ada37499401e765b1fed71f577c1742037ffdf93c1a2c4	127.0.0.1:52184		2026-06-20 07:58:45.71669+00	2026-06-20 08:13:45.715325+00	2026-06-20 07:58:56.783955+00	f
198	7	eb5b51e4e7a0044dc5ca15319837cf37f59af83094c95fed31c84c111d53cc26	[::1]:65007	curl/8.17.0	2026-06-20 07:59:28.554155+00	2026-06-20 08:14:28.553498+00	\N	t
199	10	41d151249be27594348c5764832ba50d10d3bbce72943ce7e626cb180f1e7018	127.0.0.1:60128		2026-06-20 08:00:00.963895+00	2026-06-20 08:15:00.962507+00	\N	t
200	7	73d0729d842799cd06b0b79226fd56a99921fa27d3d70665f0be07d127551b77	127.0.0.1:65441		2026-06-20 08:00:12.083134+00	2026-06-20 08:15:12.082491+00	\N	t
201	10	9280b66cc3a7f996225b0904cd2dcf512b3ef0fd2df73b827fcb214fc58f41ed	[::1]:58897	curl/8.17.0	2026-06-20 08:02:50.811351+00	2026-06-20 08:17:50.810837+00	\N	t
202	10	ef29051fe2507b97d8719e34b6011866648a4918825de4e4aec3cc8cea1ab341	[::1]:63024	curl/8.17.0	2026-06-20 08:04:36.440364+00	2026-06-20 08:19:36.437345+00	\N	t
203	10	84dd2c2e26044b597dd43c1958ff1ccd871c5f848c4568ef4e83b6f52f2526c7	[::1]:64768	curl/8.17.0	2026-06-20 08:05:14.774703+00	2026-06-20 08:20:14.772589+00	\N	t
204	10	acdb7adcd3e2f7901ff1020935e22efff311fd0b165d021393b96927fa9537b1	[::1]:58715	curl/8.17.0	2026-06-20 08:11:35.509786+00	2026-06-20 08:26:35.491374+00	\N	t
205	7	adaa544b367eab9c105ff365655a542292814591eb4ac88bf0e93a2077356b08	[::1]:55177	curl/8.17.0	2026-06-20 08:14:17.59222+00	2026-06-20 08:29:17.589434+00	\N	t
206	7	07e5f57ab624b162d92c25e659abbb06aaed587a04ec7fb2f9b8c3f0b0f4b0f6	[::1]:55186	curl/8.17.0	2026-06-20 08:14:36.429633+00	2026-06-20 08:29:36.425319+00	\N	t
207	7	681e039dfa727b1afaf25a18e14a52fe09a1c613ff4be0afdfd07c72265bb034	127.0.0.1:55189		2026-06-20 08:14:37.302695+00	2026-06-20 08:29:37.302231+00	\N	t
208	7	9872110f2200cb1bb1d6bd3aa0abeedd92742a4ed678d85afb853271b913386e	127.0.0.1:54072		2026-06-20 08:25:57.180972+00	2026-06-20 08:40:57.181213+00	\N	t
209	7	27115e85908ffd100384f72e29f221177f4355c65105fa1347ae40fc1fb73519	127.0.0.1:57121		2026-06-20 08:33:11.636654+00	2026-06-20 08:48:11.635573+00	\N	t
210	10	6f1de0c1a7196ef9f2c05ef02d025f4429cd1cb9cb02567a5c15f7ecf56af1c4	127.0.0.1:63833		2026-06-20 08:35:01.085988+00	2026-06-20 08:50:01.085921+00	2026-06-20 08:35:11.908971+00	f
211	10	87d6a3a8c0a220fe7961b8d235118330eac90a595f76e7da9caae63b19510226	127.0.0.1:64509		2026-06-20 08:38:22.122755+00	2026-06-20 08:53:22.095442+00	2026-06-20 08:39:01.704904+00	f
212	10	a116e8068574fec24d9e14a9c038c25519ac69f865f9fd5ca8951c91341772a3	127.0.0.1:52736		2026-06-20 08:39:20.524512+00	2026-06-20 08:54:20.517901+00	2026-06-20 08:41:48.321509+00	f
213	10	88c64b31112f4d45237a6f13f351bdfab0a6c45b7803c4da8aae628413074543	127.0.0.1:50161		2026-06-20 08:43:41.576108+00	2026-06-20 08:58:41.545634+00	\N	t
214	7	3a457df04af36e3d24a25b047ce8afaf5c063d20b8572d0f060cb3a723574ef0	127.0.0.1:50766		2026-06-20 08:57:30.43486+00	2026-06-20 09:12:30.435935+00	\N	t
215	7	3498ccd9dd1d6a54cd794afc778738df2fef613d2ce8ba06eee8068b382206fa	127.0.0.1:57931		2026-06-20 08:57:38.827196+00	2026-06-20 09:12:38.827277+00	\N	t
216	10	b3a2a67d8ce30979962b49c3a1cf318b7ed2a64d9868d1ea4e92f44492e8b903	127.0.0.1:62245		2026-06-20 08:58:12.4465+00	2026-06-20 09:13:12.446214+00	\N	t
218	7	91fb2eac2aed0552498bd4b0aad884aeb53578ff85b8562837fea73ec9f7e9b9	127.0.0.1:52950		2026-06-20 09:01:12.722377+00	2026-06-20 09:16:12.720916+00	\N	t
219	10	58ba5acef38d9f4d23f185e22cacf20192c6e95a3ca1c5b0ae156ccafada601d	127.0.0.1:55156		2026-06-20 09:13:13.957481+00	2026-06-20 09:28:13.95907+00	\N	t
221	10	cdf7426a9ef4e0ef90db9a70afc15dffca5260db961aa6a3b49f2266f79cdac1	[::1]:60162	curl/8.17.0	2026-06-20 09:21:25.165185+00	2026-06-20 09:36:25.16203+00	\N	t
222	7	6103a1128e3d69f95d1f75062a2da353dbd88a525a21afdb2de4df608b31004e	127.0.0.1:50764		2026-06-20 09:21:25.810293+00	2026-06-20 09:36:25.808807+00	\N	t
223	10	927621934ac0bdd7390bab29fbb73db3926447d3a013f94c5f2d4365d0eea5fa	[::1]:63715	curl/8.17.0	2026-06-20 09:24:40.170451+00	2026-06-20 09:39:40.169176+00	\N	t
224	10	251d795034d9ec28b6e80d8831cdd8efe49b4b11c74716324445687e29ef1881	[::1]:51620	curl/8.17.0	2026-06-20 09:26:00.681833+00	2026-06-20 09:41:00.680586+00	\N	t
225	10	0c5a53369e6a9cf8480e4a847cfdea69e39ff26259c0fd5231527d6a87392ed3	[::1]:50896	curl/8.17.0	2026-06-20 09:28:53.75735+00	2026-06-20 09:43:53.751889+00	\N	t
227	10	9d9d8b644a598749dcbb73ebeca30b4dcf2a85139e4db716af035259097425fd	[::1]:62413	curl/8.17.0	2026-06-20 09:38:20.257551+00	2026-06-20 09:53:20.254442+00	\N	t
228	10	5b9774d6cd771ceb12f466562aebca399cc5f23688aee8bc6393bd2adb63d3d1	[::1]:60868	curl/8.17.0	2026-06-20 09:43:19.425644+00	2026-06-20 09:58:19.343031+00	\N	t
235	10	bfdef03d899c61dff905697d9426f616f448fd625e168fb00fc6d672fd009e70	127.0.0.1:56292		2026-06-20 18:17:52.765841+00	2026-06-20 18:32:52.765166+00	\N	t
236	10	a358d8ae76724e1cbdb5c8116a55ca4884eeb74da98cd83ff82f088dc08f719f	[::1]:59987	curl/8.17.0	2026-06-20 18:21:33.891943+00	2026-06-20 18:36:33.891911+00	\N	t
238	10	618f27b0c5f4977a742391f2aa332fef2e49624d3661f2ccd82f3e569861a645	[::1]:56989	curl/8.17.0	2026-06-20 18:28:19.723333+00	2026-06-20 18:43:19.695482+00	\N	t
239	10	bfca99793ddc0189a24ae45892e283d1fdabce3c58569e29e53f71e718f9972b	[::1]:51506	curl/8.17.0	2026-06-20 18:33:32.28955+00	2026-06-20 18:48:32.269158+00	\N	t
240	10	9c7d55f863052fdf712168b220a51ab987019fb91d3d4f8f6ff8df510f1dcda5	[::1]:58012	curl/8.17.0	2026-06-20 18:35:36.746741+00	2026-06-20 18:50:36.746449+00	\N	t
242	7	87f453164bd3b2bb6e40cf5ec6a6d657b926fc6153b4f7e37e6f59316b18ef3c	127.0.0.1:53711		2026-06-20 18:42:45.51018+00	2026-06-20 18:57:45.509644+00	\N	t
243	7	8d4bbcd31ea8e3167420594171a233eb7e017d3061cb52a63d7b24ada825369a	127.0.0.1:57466		2026-06-20 18:43:27.453404+00	2026-06-20 18:58:27.451662+00	\N	t
244	10	b4675a8ec397222c3516f76dfe416b059c0af55d95d8c7214bef5b8417a4b06c	127.0.0.1:64886		2026-06-20 18:50:34.16402+00	2026-06-20 19:05:34.164509+00	\N	t
246	7	5af1e2995c614483ccefc998c7861c92ea73b90766a7cd638a59978a0d6aa8ae	127.0.0.1:58535		2026-06-20 19:02:18.621803+00	2026-06-20 19:17:18.621042+00	\N	t
247	7	c067c8df319c06bdd9d09394bdd925db6e61a0292a53a863258b7616db2b1393	127.0.0.1:58975		2026-06-20 19:18:55.214044+00	2026-06-20 19:33:55.212108+00	\N	t
248	10	3123b56637c671a074c81931c520a7263e705f04ffa7a35a4754dfacaa92b4c2	127.0.0.1:60581		2026-06-20 19:21:13.796227+00	2026-06-20 19:36:13.794421+00	\N	t
250	7	42d885758064a1e4a86af5253ed8b2600fac28cd517e1126ff4271337bfd79f9	127.0.0.1:62138		2026-06-20 20:47:52.456023+00	2026-06-20 21:02:52.43543+00	\N	t
217	11	a377f355564e24df5bb962a067697c243617090f0063c761c13c38c3f6e1687d	127.0.0.1:51263		2026-06-20 08:59:50.019784+00	2026-06-20 09:14:49.9783+00	2026-06-21 11:51:59.749823+00	f
251	10	526753c873b3de460b177208f9dd3f1a26b5c13aaca9695b2766c73e94066a38	192.168.168.218:37018	okhttp/4.12.0	2026-06-20 21:07:25.452873+00	2026-06-20 21:22:25.409999+00	\N	t
253	10	8c6658701273c435f3f4583d1870d06a19447b5ca6c782cc95be6ba8086557b7	192.168.168.218:38184	okhttp/4.12.0	2026-06-20 22:01:44.872767+00	2026-06-20 22:16:44.746193+00	\N	t
255	10	bc4e9c23db3d31227a4d46421db5d29bf7f08099268ec2aafebd6ee4bf8a44d7	192.168.168.218:54164	okhttp/4.12.0	2026-06-20 23:48:17.673156+00	2026-06-21 00:03:17.443161+00	\N	t
256	10	75a6a4fd108b5746de404c55f5e423f0ab141b561728ef3af9835b3f087cd9eb	192.168.168.218:35086	okhttp/4.12.0	2026-06-21 02:34:32.528284+00	2026-06-21 02:49:32.507048+00	2026-06-21 02:42:47.058217+00	f
257	10	72e22bd497adf2b799b94eee328c0593648a14f47478452014cd95e8914741b5	192.168.168.218:35908	okhttp/4.12.0	2026-06-21 02:42:49.279904+00	2026-06-21 02:57:49.232927+00	2026-06-21 02:57:36.938425+00	f
258	10	bd4f09b8101fe1da5d3e4c03df0ee332a0e1cfa630b3565c007653e2374c8867	192.168.168.218:56686	okhttp/4.12.0	2026-06-21 02:57:41.540465+00	2026-06-21 03:12:41.392605+00	\N	t
259	10	6d3c9bd936a1029787530fa807e16d6f641ff07dc87f16323a4085c6ae6f4a02	192.168.168.218:59022	okhttp/4.12.0	2026-06-21 07:56:18.079972+00	2026-06-21 08:11:18.019951+00	\N	t
260	10	7c33436a6880d752099dd18a848ac1f516d6b7b8d3e10ac431918d43fd0a3854	192.168.168.218:52598	okhttp/4.12.0	2026-06-21 08:19:16.428151+00	2026-06-21 08:34:16.41034+00	\N	t
261	10	4a42a218fd7ce504868a3de95d958d563751cc208b9b6aedd6cba2220b797a73	192.168.168.218:60166	okhttp/4.12.0	2026-06-21 08:36:51.512775+00	2026-06-21 08:51:51.474283+00	\N	t
262	10	c89cccea1d7cef8c38861160fcf7f10808fd5f74b22daad142cb871ba78d465c	192.168.168.218:52564	okhttp/4.12.0	2026-06-21 08:55:57.200976+00	2026-06-21 09:10:57.193802+00	\N	t
263	10	e7996406d735f8378035b960a9c17fb0bd53f0fd9768d41010a4705e3ea83670	192.168.168.218:58760	okhttp/4.12.0	2026-06-21 09:28:58.309154+00	2026-06-21 09:43:58.301448+00	\N	t
264	10	93b4209435553eaa261d18f110f4a9658652d35db847aafdfc3c4ccd1317df02	192.168.168.218:49246	okhttp/4.12.0	2026-06-21 10:08:23.288999+00	2026-06-21 10:23:23.286913+00	\N	t
265	7	9a9347844326ee31fb09850142b6083e7c5820963210b405996856da5c09119f	127.0.0.1:59756		2026-06-21 10:14:36.464294+00	2026-06-21 10:29:36.463875+00	\N	t
266	7	0ab63a97eb64f79492f17ca65e9f467455170464990498681a88853f3b952de1	127.0.0.1:59838		2026-06-21 10:15:49.067563+00	2026-06-21 10:30:48.958255+00	\N	t
267	7	84659cf56fcbea8c9d4e6a6d65c0f608f452f85c499402d161203945064aacfc	127.0.0.1:61836		2026-06-21 10:20:36.379299+00	2026-06-21 10:35:36.377848+00	\N	t
268	7	10e87e2c650ea9945ed5360d38311721de13c05b7ec01bf3f1d30748b0cc8b97	127.0.0.1:59387		2026-06-21 10:27:38.515171+00	2026-06-21 10:42:38.514121+00	\N	t
270	10	a37a55a846d852fc527901efcbbc02587c63cf7466a7e27a025d5989a19daabc	127.0.0.1:55382		2026-06-21 10:36:04.330542+00	2026-06-21 10:51:04.325178+00	\N	t
271	7	8d1a50ab7d54e907c75330646f120b32b39e91396eaa517c7a2789ef84f4485a	127.0.0.1:55094		2026-06-21 11:00:06.909508+00	2026-06-21 11:15:06.900608+00	\N	t
272	10	8a0eef9f6aaec861568de293f8532f8f1a17ef21d2d4b877cc629b99b4c7c5d8	127.0.0.1:57524		2026-06-21 11:01:19.774166+00	2026-06-21 11:16:19.772956+00	2026-06-21 11:01:46.94098+00	f
273	10	cf9e6c88abd4e5ca3df34809cb77056efae3ed9e338fb6b7a2e3816847965db3	127.0.0.1:59019		2026-06-21 11:03:07.615086+00	2026-06-21 11:18:07.559342+00	\N	t
274	10	b2c234ccb76968315b8d73519870fb33fed5dffcc8dc5854c9bcfe81235948b5	127.0.0.1:56572		2026-06-21 11:07:31.148621+00	2026-06-21 11:22:31.1426+00	\N	t
275	10	b0776f3011e7497f6b04fcd471288b254872de390423366d8fb6acc08d8fcf6c	127.0.0.1:60369		2026-06-21 11:15:06.897239+00	2026-06-21 11:30:06.897008+00	\N	t
277	7	253ff1ec5d83c5bc3ce184d321001e281324ed4e4ffae494a1761d6c8eb072c1	127.0.0.1:56646		2026-06-21 11:20:57.981183+00	2026-06-21 11:35:57.978919+00	\N	t
278	10	69733cd61f3226135a70e2b2e9c1113bf9bfd8bdbe4a3d4a092447b9b2a2170b	127.0.0.1:54528		2026-06-21 11:22:14.124589+00	2026-06-21 11:37:14.123522+00	\N	t
279	10	9549bc8e974edd061f3c9b1bc01477e26b618a4981db3743f971fdd095061bb6	127.0.0.1:51865		2026-06-21 11:30:32.997358+00	2026-06-21 11:45:32.998203+00	\N	t
280	10	49635687b682a2029f1ba6f2bfae4d1097ba336db7e87efa98f031ffc04c87bb	127.0.0.1:49838		2026-06-21 11:38:58.958889+00	2026-06-21 11:53:58.957881+00	2026-06-21 11:48:39.816631+00	f
282	7	52b13b359cc1011e5af1ff2b37c00f99d528c7cd623b2961df5f506fd5ea7b41	127.0.0.1:65501		2026-06-21 11:49:36.014972+00	2026-06-21 12:04:35.96081+00	\N	t
220	11	4f7943f4c5a48489cd43806fb16efa6e877cba47faee56f4d63bd8ee9061dd75	127.0.0.1:55074		2026-06-20 09:14:20.446466+00	2026-06-20 09:29:20.444825+00	2026-06-21 11:51:59.749823+00	f
226	11	0400ac1dc5663f742078a74d5b803ab1ac908b6a230a4c0ab0530179740b7e36	127.0.0.1:49672		2026-06-20 09:29:10.437611+00	2026-06-20 09:44:10.437124+00	2026-06-21 11:51:59.749823+00	f
229	11	ad6de95ab644a3c26dadd435af2fa24c59c3d8785dfcc908d1a826b139bea2b9	127.0.0.1:49363		2026-06-20 09:44:10.642697+00	2026-06-20 09:59:10.642708+00	2026-06-21 11:51:59.749823+00	f
230	11	c4ba49f6914a8d8790938dbc61c3a2f5a6bd5139e9c75c68167e341f2a144d88	127.0.0.1:51248		2026-06-20 09:59:10.547027+00	2026-06-20 10:14:10.545919+00	2026-06-21 11:51:59.749823+00	f
231	11	bfe32980b8af2628ed5a9ed6e2f9911a1c34637a25a253642799e4cb431b7a07	127.0.0.1:60881		2026-06-20 10:14:10.483404+00	2026-06-20 10:29:10.482866+00	2026-06-21 11:51:59.749823+00	f
232	11	c5e8cbd1969b03ab6096620cb04e126fc9c752b64bee3a2dc2318cc80f34fc1e	127.0.0.1:60010		2026-06-20 10:29:10.458343+00	2026-06-20 10:44:10.457576+00	2026-06-21 11:51:59.749823+00	f
233	11	e75b7712d896e64a78c9022deb9bdded443893e0b3f95f6b232ca24a61ca721c	127.0.0.1:52041		2026-06-20 10:44:10.571374+00	2026-06-20 10:59:10.567995+00	2026-06-21 11:51:59.749823+00	f
234	11	cca65690da420dc4a7c5456eff0ac13954ae4923b84ecb8fbbd02d0f33a91658	127.0.0.1:53593		2026-06-20 18:11:04.42112+00	2026-06-20 18:26:04.457148+00	2026-06-21 11:51:59.749823+00	f
237	11	7a2e1cbd318500c1eacbc5fff8403822d9c24d6c9f918582ed82b091df14e7ac	127.0.0.1:63405		2026-06-20 18:25:57.721631+00	2026-06-20 18:40:57.720715+00	2026-06-21 11:51:59.749823+00	f
252	11	9acc297bae872e98510aec0dd1a1e0c3fa4481a3c4d20b32fb9adb3bc2ce8e4b	127.0.0.1:55395		2026-06-20 21:39:54.587917+00	2026-06-20 21:54:54.559815+00	2026-06-21 11:51:59.749823+00	f
254	11	4dd35e3eea9f6c17e868111d02960e3d2fa10be1e0169f7309654f7f22b35ee4	127.0.0.1:64898		2026-06-20 22:02:10.276052+00	2026-06-20 22:17:10.275433+00	2026-06-21 11:51:59.749823+00	f
269	11	f730474ac0ba977508195ea04baefc0e32b3cb1874805316277b968eaa9443d9	127.0.0.1:51796		2026-06-21 10:34:06.184894+00	2026-06-21 10:49:06.185479+00	2026-06-21 11:51:59.749823+00	f
276	11	47609c8db01b773956310b6003f97bb9a2bd6a3c1e9f8c7d21e82540716b86be	127.0.0.1:62938		2026-06-21 11:16:20.503928+00	2026-06-21 11:31:20.501341+00	2026-06-21 11:51:59.749823+00	f
281	11	7d556d189f9dcf79014ca0e3ddb69fa1dd4fcc952094d6dad46a001ea639999e	127.0.0.1:63049		2026-06-21 11:48:02.522291+00	2026-06-21 12:03:02.523083+00	2026-06-21 11:51:59.749823+00	f
283	11	8cfa35e8d9ea4fe42a6dd4c914be61894800052c07c0967ebbcf93fa5e478226	127.0.0.1:64389		2026-06-21 11:50:18.374794+00	2026-06-21 12:05:18.371162+00	2026-06-21 11:51:59.749823+00	f
286	11	6bfe93f41373ff952a9ab27ce3633d67f1fb9671a954b6e0a0cb1701bc4ff340	127.0.0.1:61873		2026-06-21 12:01:12.156822+00	2026-06-21 12:16:12.154427+00	\N	t
241	11	74a23abb5b31c3bf09321c46c3c6f67170e630c96473dfeb3f0c64f2c7127a12	127.0.0.1:59812		2026-06-20 18:40:57.769033+00	2026-06-20 18:55:57.766611+00	2026-06-21 11:51:59.749823+00	f
245	11	f8c9bf57df95dbe23a6d0216094059fdcbd9ea9f53c3257ecaf12d11bc9073e8	127.0.0.1:52080		2026-06-20 18:51:26.819936+00	2026-06-20 19:06:26.817807+00	2026-06-21 11:51:59.749823+00	f
249	11	f4d1fbad4cd9a74e7f895b095e93d4fcef3dc5e0ac51f2954fc08387449b306e	127.0.0.1:58652		2026-06-20 19:21:31.065712+00	2026-06-20 19:36:31.062838+00	2026-06-21 11:51:59.749823+00	f
284	10	c713527565426bcde94f3d5ea22686bd253ec32e05add2177bbc503f118bbe16	127.0.0.1:49674		2026-06-21 11:56:45.890216+00	2026-06-21 12:11:45.888074+00	\N	t
285	11	8c87df4c0bd037ac60895cae2fb665a15a27f2467a0efd3f57a8c2a2cc2bfb9a	127.0.0.1:61907		2026-06-21 11:59:43.119594+00	2026-06-21 12:14:43.115352+00	2026-06-21 12:01:03.356443+00	f
287	10	6dc5c0bab3e5572d996529f200b3965705863fa52d9bb67d36720a60eb50003b	[::1]:56182	curl/8.17.0	2026-06-21 12:35:01.124847+00	2026-06-21 12:50:01.098273+00	\N	t
289	10	a2293d24d057ca953ba1f42d1368a2c74ff854d35dec6ca43c71a9237ad91247	[::1]:49792	curl/8.17.0	2026-06-21 12:36:48.735085+00	2026-06-21 12:51:48.733163+00	\N	t
290	10	ecd4697d26dca61f6277b982e26673a0340e1e5f64280f90438e5254bc5b2779	[::1]:55904	curl/8.17.0	2026-06-21 12:41:52.61124+00	2026-06-21 12:56:52.571367+00	\N	t
291	10	3395fa2fa91a7bef8fd129a502aa04cb5d615aa2d754a033162947bfcc42cbb7	127.0.0.1:55911		2026-06-21 12:41:53.773493+00	2026-06-21 12:56:53.76803+00	\N	t
292	7	7295735fbb7841df20da0ebf23f6732a318336a3988454cd099c13e42b7babac	127.0.0.1:57035		2026-06-21 12:54:17.252976+00	2026-06-21 13:09:17.25079+00	\N	t
293	11	f805a119216d768edf4ec39b48acde3fd301681e2f9afb708cad5d53784ba49a	127.0.0.1:64438		2026-06-21 13:01:02.036298+00	2026-06-21 13:16:02.034215+00	\N	t
294	10	1c8c7b76ef6078d63d3d26fed00080a8a4e9e40a5e4860e34e19ee34efb43771	127.0.0.1:60526		2026-06-21 13:38:44.573999+00	2026-06-21 13:53:44.57049+00	\N	t
295	7	6c29fc61b5b574a90f266417cc882f6426d8886e9d443ac79f8a6c589e0e706e	127.0.0.1:50553		2026-06-21 14:54:49.277585+00	2026-06-21 15:09:49.272693+00	\N	t
296	10	8e5c85281cfd7d1c01696b265f94836c26ea8a9d2062c92b2c6877e1d60122b3	127.0.0.1:52944		2026-06-21 15:04:04.44468+00	2026-06-21 15:19:04.443892+00	\N	t
297	7	115c2b8424636b13d727422dc5ce02e99526d6f987f83bcb9ba37043d496d71c	127.0.0.1:54755		2026-06-21 15:14:56.281884+00	2026-06-21 15:29:56.280784+00	\N	t
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.users (id, tenant_id, nome, email, password_hash, telefone, estado, email_verificado, ultimo_login_em, created_at, updated_at, tipo, cargo_id, permissoes_atualizadas_em) FROM stdin;
7	4	Admin Test	admin@nexora.co.mz	$2a$12$QxeFR9g/5znaRmrBnGuaUOnuYaZFTEUp2.jlFzD5IPaWULYN.qLNS	+258840000001	ativo	t	2026-06-21 11:49:36.027556+00	2026-05-09 19:30:04.112696+00	2026-06-20 07:58:28.525395+00	superadmin	\N	2026-06-21 12:07:18.743406+00
1	1	Administrador Sistema	admin@nexora.local	$2a$12$rh.v9MY0rurE/J5F.2wMouDlolWjDhcWi2LAp2i1/tu9rqGzE56vW	+258840000001	ativo	t	2026-06-14 21:31:14.808101+00	2026-03-17 16:33:58.367371+00	2026-03-17 16:40:18.851684+00	funcionario	\N	2026-06-21 12:07:18.743406+00
10	4	Eleuterio Fulaho Notico	eleuterio3d@gmail.com	$2a$12$5flJiKbA1SNBCLyBGKaWbupNneTZT7jiRaqkV4xwBhpcW5JjJ4GEa	+258870000001	ativo	f	2026-06-21 12:41:53.783431+00	2026-06-19 18:31:21.03614+00	2026-06-20 08:03:00.568942+00	funcionario	\N	2026-06-21 12:07:18.743406+00
11	4	20032026	admin1@nexora.co.mz	$2a$12$G0xKkmby0GHSCC3Blm/bZuALGbgZdgHkMaa37q3A/tF41L1rl28dK	87667890	ativo	f	2026-06-21 12:01:12.168858+00	2026-06-20 08:58:47.045721+00	2026-06-21 11:51:59.730951+00	funcionario	\N	2026-06-21 13:00:37.714264+00
8	1	Recrutamento PHP Backend	recrutamento-bot@e258tech.local	$2a$12$MOpdLjzrErtLun8Ze74na.V1mGlzH0n/uzV8v6t.em5OfbQgyhtcW	\N	ativo	t	2026-06-19 18:22:25.068243+00	2026-06-10 13:36:04.318748+00	2026-06-10 13:36:04.318748+00	funcionario	\N	2026-06-21 12:07:18.743406+00
9	4	POS Teste	pos-teste@nexora.local	$2a$12$7lJQzn1KBEBqQwFcRoTZ7O6bVs3UNxCMyUCVIttKwuJss5ZIQwb8m	\N	ativo	t	2026-06-19 18:29:57.064207+00	2026-06-13 16:38:27.587203+00	2026-06-13 16:38:27.587203+00	superadmin	\N	2026-06-21 12:07:18.743406+00
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: autorizacao; Owner: -
--

COPY autorizacao.permissions (id, codigo, nome, descricao, recurso, acao, created_at) FROM stdin;
1	auth.users.manage	Gerir utilizadores	Criar e atualizar utilizadores	auth.users	manage	2026-03-17 16:33:58.781445+00
2	companies.manage	Gerir empresas	Gerir empresas e filiais	companies	manage	2026-03-17 16:33:58.781445+00
3	faturacao.manage	Gerir faturacao	Emitir e anular documentos	faturacao	manage	2026-03-17 16:33:58.781445+00
4	stock.manage	Gerir stock	Movimentar e consultar stock	stock	manage	2026-03-17 16:33:58.781445+00
5	reports.view	Ver relatorios	Consultar relatorios e dashboards	reports	view	2026-03-17 16:33:58.781445+00
6	settings.manage	Gerir configuracoes	Alterar configuracoes do tenant	settings	manage	2026-03-17 16:33:58.781445+00
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: autorizacao; Owner: -
--

COPY autorizacao.role_permissions (id, role_id, permission_id, created_at) FROM stdin;
1	1	1	2026-03-17 16:33:58.788285+00
2	1	2	2026-03-17 16:33:58.788285+00
3	1	3	2026-03-17 16:33:58.788285+00
4	1	4	2026-03-17 16:33:58.788285+00
5	1	5	2026-03-17 16:33:58.788285+00
6	1	6	2026-03-17 16:33:58.788285+00
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: autorizacao; Owner: -
--

COPY autorizacao.roles (id, tenant_id, codigo, nome, descricao, ativo, created_at) FROM stdin;
1	1	ADMIN	Administrador	Perfil administrativo completo	t	2026-03-17 16:33:58.785097+00
4	1	admin	Administrador	\N	t	2026-05-08 20:58:31.283557+00
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: autorizacao; Owner: -
--

COPY autorizacao.user_roles (id, user_id, role_id, created_at) FROM stdin;
1	1	1	2026-03-17 16:33:58.793436+00
\.


--
-- Data for Name: cost_center_allocations; Type: TABLE DATA; Schema: centros_custo; Owner: -
--

COPY centros_custo.cost_center_allocations (id, tenant_id, cost_center_id, source_service, source_type, source_id, source_line_id, descricao, valor, moeda, allocation_percent, referencia_tipo, referencia_id, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: cost_center_budgets; Type: TABLE DATA; Schema: centros_custo; Owner: -
--

COPY centros_custo.cost_center_budgets (id, tenant_id, cost_center_id, ano, mes, valor_orcamentado, moeda, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: cost_centers; Type: TABLE DATA; Schema: centros_custo; Owner: -
--

COPY centros_custo.cost_centers (id, tenant_id, parent_id, codigo, nome, tipo, gestor_user_id, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: customer_addresses; Type: TABLE DATA; Schema: clientes; Owner: -
--

COPY clientes.customer_addresses (id, customer_id, tipo, endereco, cidade, provincia, pais, codigo_postal, principal, created_at) FROM stdin;
1	2	principal	Maputo	Maputo	Maputo	Mozambique	1111	f	2026-06-12 14:01:46.475265+00
\.


--
-- Data for Name: customer_balances; Type: TABLE DATA; Schema: clientes; Owner: -
--

COPY clientes.customer_balances (id, customer_id, saldo_atual, saldo_vencido, credito_disponivel, updated_at) FROM stdin;
\.


--
-- Data for Name: customer_contacts; Type: TABLE DATA; Schema: clientes; Owner: -
--

COPY clientes.customer_contacts (id, customer_id, nome, cargo, telefone, email, principal, created_at) FROM stdin;
2	2	Gessica Gungulo	COMERCIAL	+258879908275	gessicagungulo1221@gmail.com	f	2026-06-12 15:44:23.414192+00
1	2	Eleuterio Fulaho Notico	gestor	+258852957672	eleuterio3d@gmail.com	t	2026-06-12 14:01:37.205464+00
\.


--
-- Data for Name: customer_credit_limits; Type: TABLE DATA; Schema: clientes; Owner: -
--

COPY clientes.customer_credit_limits (id, customer_id, limite_credito, moeda, inicio_em, fim_em, ativo, created_at, updated_at, motivo, updated_by) FROM stdin;
\.


--
-- Data for Name: customer_discounts; Type: TABLE DATA; Schema: clientes; Owner: -
--

COPY clientes.customer_discounts (id, customer_id, tipo, valor, motivo, ativo, inicio_em, fim_em, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: customer_documents; Type: TABLE DATA; Schema: clientes; Owner: -
--

COPY clientes.customer_documents (id, customer_id, tipo, numero, ficheiro_url, emitido_em, expira_em, created_at) FROM stdin;
\.


--
-- Data for Name: customer_groups; Type: TABLE DATA; Schema: clientes; Owner: -
--

COPY clientes.customer_groups (id, tenant_id, codigo, nome, descricao, ativo, created_at, updated_at) FROM stdin;
1	4	GRPC	VENDAS	VENDAS	t	2026-06-12 15:43:55.329407+00	2026-06-15 10:01:15.824182+00
\.


--
-- Data for Name: customer_history; Type: TABLE DATA; Schema: clientes; Owner: -
--

COPY clientes.customer_history (id, customer_id, evento, descricao, referencia_tipo, referencia_id, created_at, created_by) FROM stdin;
\.


--
-- Data for Name: customer_notes; Type: TABLE DATA; Schema: clientes; Owner: -
--

COPY clientes.customer_notes (id, customer_id, nota, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: customer_payments; Type: TABLE DATA; Schema: clientes; Owner: -
--

COPY clientes.customer_payments (id, tenant_id, customer_id, documento_id, metodo, referencia, valor, pago_em, observacao, created_by) FROM stdin;
1	4	2	\N	transferencia	\N	10000.00	2026-06-12 14:03:09.175122+00	\N	\N
\.


--
-- Data for Name: customer_tag_links; Type: TABLE DATA; Schema: clientes; Owner: -
--

COPY clientes.customer_tag_links (id, customer_id, customer_tag_id, created_at) FROM stdin;
\.


--
-- Data for Name: customer_tags; Type: TABLE DATA; Schema: clientes; Owner: -
--

COPY clientes.customer_tags (id, tenant_id, codigo, nome, cor, created_at) FROM stdin;
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: clientes; Owner: -
--

COPY clientes.customers (id, tenant_id, customer_group_id, codigo, nome, nuit, telefone, email, estado, observacao, created_at, updated_at, bloqueio_motivo, bloqueado_em) FROM stdin;
1	1	\N	\N	Empresa Teste Lda	\N	+258840000000	cliente.teste@example.com	ativo	Criado a partir do lead CRM #2	2026-06-12 08:26:53.632283+00	2026-06-12 08:26:53.632283+00	\N	\N
2	4	1	1111	Eleuterio Fulaho Notico	14578565577	+258852957672	eleuterio3d@gmail.com	ativo	Bayonetta	2026-06-12 14:00:01.504656+00	2026-06-12 15:44:03.612092+00	\N	\N
3	4	\N	\N	En4XD	\N	+258860675700	eleuterio@gmail.com	ativo	Criado a partir do lead CRM #4	2026-06-19 14:21:53.981166+00	2026-06-19 14:21:53.981166+00	\N	\N
\.


--
-- Data for Name: goods_receipt_items; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.goods_receipt_items (id, goods_receipt_id, purchase_order_item_id, product_id, quantity_received, returned_quantity, unit_cost, lote, validade, created_at) FROM stdin;
\.


--
-- Data for Name: goods_receipts; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.goods_receipts (id, tenant_id, purchase_order_id, supplier_id, numero, receipt_date, warehouse_id, status, observacoes, criado_por, created_at, supplier_document, updated_at) FROM stdin;
\.


--
-- Data for Name: purchase_invoice_items; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.purchase_invoice_items (id, purchase_invoice_id, purchase_order_item_id, product_id, descricao, unidade, quantity, unit_price, desconto, tax_rate, tax_amount, total, created_at) FROM stdin;
\.


--
-- Data for Name: purchase_invoices; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.purchase_invoices (id, tenant_id, supplier_id, purchase_order_id, goods_receipt_id, numero, supplier_invoice_number, invoice_date, due_date, moeda, subtotal, desconto_total, imposto_total, total, valor_pago, status, observacoes, criado_por, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: purchase_order_items; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.purchase_order_items (id, purchase_order_id, product_id, descricao, unidade, quantity, received_quantity, unit_price, desconto, tax_rate, tax_amount, total, created_at) FROM stdin;
\.


--
-- Data for Name: purchase_orders; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.purchase_orders (id, tenant_id, supplier_id, numero, order_date, expected_date, status, moeda, subtotal, desconto_total, imposto_total, total, observacoes, criado_por, aprovado_por, aprovado_em, created_at, updated_at, purchase_request_id, payment_terms) FROM stdin;
\.


--
-- Data for Name: purchase_payment_items; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.purchase_payment_items (id, purchase_payment_id, purchase_invoice_id, valor, created_at) FROM stdin;
\.


--
-- Data for Name: purchase_payments; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.purchase_payments (id, tenant_id, supplier_id, numero, payment_date, metodo, referencia, moeda, valor, valor_alocado, status, observacoes, criado_por, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: purchase_request_items; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.purchase_request_items (id, purchase_request_id, product_id, descricao, unidade, quantity, estimated_unit_price, observacoes, created_at) FROM stdin;
\.


--
-- Data for Name: purchase_requests; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.purchase_requests (id, tenant_id, numero, request_date, required_date, department, requested_by, status, prioridade, justificacao, observacoes, created_at, updated_at) FROM stdin;
3	4	14	2026-06-16	2026-06-30	TIPO	7	rascunho	alta	URGENTE	\N	2026-06-16 12:31:10.390672+00	2026-06-16 12:31:10.390672+00
\.


--
-- Data for Name: purchase_return_items; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.purchase_return_items (id, purchase_return_id, goods_receipt_item_id, product_id, quantity, unit_cost, total, created_at) FROM stdin;
\.


--
-- Data for Name: purchase_returns; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.purchase_returns (id, tenant_id, supplier_id, goods_receipt_id, numero, return_date, motivo, status, total, observacoes, criado_por, created_at, warehouse_id, updated_at) FROM stdin;
\.


--
-- Data for Name: supplier_addresses; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.supplier_addresses (id, supplier_id, tipo, endereco, cidade, provincia, pais, codigo_postal, principal, created_at) FROM stdin;
\.


--
-- Data for Name: supplier_contacts; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.supplier_contacts (id, supplier_id, nome, cargo, telefone, email, principal, created_at) FROM stdin;
\.


--
-- Data for Name: supplier_groups; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.supplier_groups (id, tenant_id, codigo, nome, descricao, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: compras; Owner: -
--

COPY compras.suppliers (id, tenant_id, supplier_group_id, codigo, nome, nuit, telefone, email, moeda_padrao, prazo_pagamento_dias, estado, observacao, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: account_types; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.account_types (id, tenant_id, codigo, nome, classe, natureza, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: accounting_budgets; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.accounting_budgets (id, tenant_id, chart_account_id, fiscal_year_id, mes, valor_orcamentado, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: accounting_journals; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.accounting_journals (id, tenant_id, codigo, nome, tipo, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: accounting_reports; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.accounting_reports (id, tenant_id, tipo, parametros, conteudo, gerado_por, gerado_em) FROM stdin;
\.


--
-- Data for Name: chart_of_accounts; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.chart_of_accounts (id, tenant_id, parent_id, codigo, nome, aceita_lancamento, ativo, created_at, updated_at, account_type_id) FROM stdin;
\.


--
-- Data for Name: depreciation_entries; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.depreciation_entries (id, tenant_id, fixed_asset_id, fiscal_period_id, numero_parcela, valor_amortizacao, status, journal_entry_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: fiscal_periods; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.fiscal_periods (id, tenant_id, ano, mes, data_inicio, data_fim, status, fechado_em, fechado_por, created_at, fiscal_year_id) FROM stdin;
1	4	2025	7	2026-07-15	2026-08-14	aberto	\N	\N	2026-06-15 13:08:48.98682+00	1
2	4	2025	8	2026-08-15	2026-09-14	aberto	\N	\N	2026-06-15 13:08:48.98682+00	1
3	4	2025	9	2026-09-15	2026-10-14	aberto	\N	\N	2026-06-15 13:08:48.98682+00	1
4	4	2025	10	2026-10-15	2026-11-14	aberto	\N	\N	2026-06-15 13:08:48.98682+00	1
5	4	2025	11	2026-11-15	2026-12-14	aberto	\N	\N	2026-06-15 13:08:48.98682+00	1
6	4	2025	12	2026-12-15	2027-01-14	aberto	\N	\N	2026-06-15 13:08:48.98682+00	1
10	4	2025	4	2027-04-15	2027-05-14	aberto	\N	\N	2026-06-15 13:08:48.98682+00	1
11	4	2025	5	2027-05-15	2027-06-14	aberto	\N	\N	2026-06-15 13:08:48.98682+00	1
12	4	2025	6	2027-06-15	2027-07-14	aberto	\N	\N	2026-06-15 13:08:48.98682+00	1
7	4	2025	1	2027-01-15	2027-02-14	aberto	\N	\N	2026-06-15 13:08:48.98682+00	1
8	4	2025	2	2027-02-15	2027-03-14	fechado	2026-06-15 16:38:36.337691+00	7	2026-06-15 13:08:48.98682+00	1
9	4	2025	3	2027-03-15	2027-04-14	fechado	2026-06-15 16:38:42.825808+00	7	2026-06-15 13:08:48.98682+00	1
\.


--
-- Data for Name: fiscal_years; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.fiscal_years (id, tenant_id, ano, data_inicio, data_fim, status, fechado_em, fechado_por, created_at) FROM stdin;
1	4	2025	2026-07-15	2026-12-31	aberto	\N	\N	2026-06-15 13:08:48.98682+00
\.


--
-- Data for Name: fixed_assets; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.fixed_assets (id, tenant_id, chart_account_id, depreciation_account_id, accumulated_depreciation_account_id, codigo, nome, data_aquisicao, valor_aquisicao, valor_residual, vida_util_meses, metodo, estado, data_alienacao, valor_alienacao, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: journal_entries; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.journal_entries (id, tenant_id, fiscal_period_id, accounting_journal_id, numero, entry_date, descricao, referencia_tipo, referencia_id, status, moeda, total_debito, total_credito, criado_por, publicado_por, publicado_em, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: journal_entry_lines; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.journal_entry_lines (id, journal_entry_id, account_id, descricao, debit, credit, reference_type, reference_id, created_at) FROM stdin;
\.


--
-- Data for Name: journal_entry_sequences; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.journal_entry_sequences (id, tenant_id, accounting_journal_id, ano, proxima_sequencia) FROM stdin;
\.


--
-- Data for Name: period_closing_checks; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.period_closing_checks (id, period_closing_id, verificacao, passou, detalhe, verificado_em) FROM stdin;
\.


--
-- Data for Name: period_closings; Type: TABLE DATA; Schema: contabilidade; Owner: -
--

COPY contabilidade.period_closings (id, tenant_id, fiscal_period_id, status, iniciado_por, iniciado_em, encerrado_por, encerrado_em, justificacao_reabertura, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: atividades; Type: TABLE DATA; Schema: crm; Owner: -
--

COPY crm.atividades (id, tenant_id, lead_id, oportunidade_id, tipo, titulo, descricao, data_atividade, concluida, responsavel, created_at, updated_at) FROM stdin;
1	1	\N	2	nota	Estágio alterado	Estágio alterado: Novo → Perdido\nMotivo: Cliente optou por concorrente (teste E2E)	\N	t	\N	2026-06-12 08:30:06.11919+00	2026-06-12 08:30:06.11919+00
2	4	\N	3	nota	Estágio alterado	Estágio alterado: Novo → Qualificado	\N	t	\N	2026-06-12 14:04:57.244942+00	2026-06-12 14:04:57.244942+00
\.


--
-- Data for Name: crm_activities; Type: TABLE DATA; Schema: crm; Owner: -
--

COPY crm.crm_activities (id, tenant_id, lead_id, opportunity_id, tipo, assunto, descricao, status, agendado_para, concluido_em, owner_user_id, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: crm_lead_sources; Type: TABLE DATA; Schema: crm; Owner: -
--

COPY crm.crm_lead_sources (id, tenant_id, codigo, nome, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: crm_leads; Type: TABLE DATA; Schema: crm; Owner: -
--

COPY crm.crm_leads (id, tenant_id, lead_source_id, codigo, nome, empresa, email, telefone, estado, interesse, observacoes, owner_user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: crm_opportunities; Type: TABLE DATA; Schema: crm; Owner: -
--

COPY crm.crm_opportunities (id, tenant_id, pipeline_id, stage_id, lead_id, customer_id, codigo, nome, valor_estimado, moeda, probabilidade, expected_close_date, estado, owner_user_id, observacoes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: crm_pipeline_stages; Type: TABLE DATA; Schema: crm; Owner: -
--

COPY crm.crm_pipeline_stages (id, pipeline_id, codigo, nome, ordem, probabilidade, ganho, perdido, created_at) FROM stdin;
\.


--
-- Data for Name: crm_pipelines; Type: TABLE DATA; Schema: crm; Owner: -
--

COPY crm.crm_pipelines (id, tenant_id, codigo, nome, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: leads; Type: TABLE DATA; Schema: crm; Owner: -
--

COPY crm.leads (id, tenant_id, nome, empresa, email, telefone, origem, estado, responsavel, notas, cliente_id, convertido_em, created_at, updated_at) FROM stdin;
1	1	Gessica Gungulo	Eduardo Mondlane University	gessicagungulo1221@gmail.com	+258879908275	redes_sociais	contactado	jose	rodar Erro ao guardar na base de dados.	\N	\N	2026-06-12 05:18:15.250177+00	2026-06-12 05:18:40.003549+00
2	1	Cliente Teste E2E Editado	Empresa Teste Lda	cliente.teste@example.com	+258840000000	site	convertido	jose	Lead editado via teste end-to-end CRM	1	2026-06-12 08:26:53.632283+00	2026-06-12 08:23:38.293846+00	2026-06-12 08:26:53.632283+00
3	4	Utech Mozambique	UtechMozambique	utechmozambique@gmail.com	+258860675700	redes_sociais	contactado	jose	admin@nexora.co.mz	\N	\N	2026-06-12 13:04:21.708449+00	2026-06-12 13:04:46.156475+00
4	4	Eleuterio Fulaho Notico	En4XD	eleuterio@gmail.com	+258860675700	chamada_fria	convertido	jose	admin@nexora.co.mz	3	2026-06-19 14:21:53.981166+00	2026-06-12 13:04:37.44258+00	2026-06-19 14:21:53.981166+00
\.


--
-- Data for Name: oportunidades; Type: TABLE DATA; Schema: crm; Owner: -
--

COPY crm.oportunidades (id, tenant_id, titulo, lead_id, cliente_id, estagio, valor_estimado, moeda, probabilidade, data_fecho_prevista, data_fecho_real, motivo_perda, responsavel, descricao, created_at, updated_at) FROM stdin;
2	1	Oportunidade E2E Standalone	\N	\N	perdido	8000.00	MZN	0	\N	2026-06-12	Cliente optou por concorrente (teste E2E)	jose	Oportunidade criada via teste end-to-end	2026-06-12 08:29:24.513218+00	2026-06-12 08:30:06.11919+00
1	1	Venda E2E - Cliente Teste	2	1	qualificado	15000.00	MZN	0	\N	\N	\N	jose	\N	2026-06-12 08:26:53.632283+00	2026-06-12 08:49:26.038678+00
3	4	Estágio Assistente Administrativo	4	2	qualificado	100000.00	MZN	10	2026-06-19	\N	\N	Domingos Vuma	Domingos Vuma	2026-06-12 14:04:22.428873+00	2026-06-12 14:04:57.244942+00
4	4	Oportunidade — Eleuterio Fulaho Notico	4	3	novo	0.00	MZN	0	\N	\N	\N	jose	\N	2026-06-19 14:21:53.981166+00	2026-06-19 14:21:53.981166+00
\.


--
-- Data for Name: companies; Type: TABLE DATA; Schema: empresa; Owner: -
--

COPY empresa.companies (id, codigo, nome, nome_comercial, tipo, status, moeda_base, timezone, created_at, updated_at) FROM stdin;
1	DEMO	Nexora Demo, Lda	Nexora Demo	empresa	ativa	MZN	Africa/Maputo	2026-03-17 16:33:58.713908+00	2026-03-17 16:40:19.441056+00
\.


--
-- Data for Name: company_addresses; Type: TABLE DATA; Schema: empresa; Owner: -
--

COPY empresa.company_addresses (id, company_id, branch_id, tipo, endereco, cidade, provincia, pais, codigo_postal, created_at) FROM stdin;
\.


--
-- Data for Name: company_banks; Type: TABLE DATA; Schema: empresa; Owner: -
--

COPY empresa.company_banks (id, company_id, banco, numero_conta, nib, iban, swift, moeda, principal, created_at) FROM stdin;
\.


--
-- Data for Name: company_branches; Type: TABLE DATA; Schema: empresa; Owner: -
--

COPY empresa.company_branches (id, company_id, codigo, nome, status, principal, created_at, updated_at) FROM stdin;
1	1	MATRIZ	Sede Maputo	ativa	t	2026-03-17 16:33:58.7282+00	2026-03-17 16:40:19.448791+00
\.


--
-- Data for Name: company_contacts; Type: TABLE DATA; Schema: empresa; Owner: -
--

COPY empresa.company_contacts (id, company_id, branch_id, tipo, nome, telefone, email, principal, created_at) FROM stdin;
\.


--
-- Data for Name: company_documents; Type: TABLE DATA; Schema: empresa; Owner: -
--

COPY empresa.company_documents (id, company_id, tipo, numero, ficheiro_url, emitido_em, expira_em, created_at) FROM stdin;
\.


--
-- Data for Name: company_licenses; Type: TABLE DATA; Schema: empresa; Owner: -
--

COPY empresa.company_licenses (id, company_id, plano, licenca_chave, limite_usuarios, limite_filiais, inicia_em, expira_em, status, created_at) FROM stdin;
\.


--
-- Data for Name: company_settings; Type: TABLE DATA; Schema: empresa; Owner: -
--

COPY empresa.company_settings (id, company_id, chave, valor, created_at, updated_at) FROM stdin;
1	1	default_currency	MZN	2026-03-17 16:33:58.760037+00	2026-03-17 16:40:19.453223+00
2	1	country	Mocambique	2026-03-17 16:33:58.760037+00	2026-03-17 16:40:19.453223+00
3	1	timezone	Africa/Maputo	2026-03-17 16:33:58.760037+00	2026-03-17 16:40:19.453223+00
4	1	language	pt-MZ	2026-03-17 16:33:58.760037+00	2026-03-17 16:40:19.453223+00
\.


--
-- Data for Name: company_tax_info; Type: TABLE DATA; Schema: empresa; Owner: -
--

COPY empresa.company_tax_info (id, company_id, nuit, regime_iva, taxa_iva_padrao, inicio_atividade, reparticao_fiscal, created_at, updated_at) FROM stdin;
1	1	400000001	regime_geral	16.00	2026-03-17	Maputo Cidade	2026-03-17 16:33:58.718891+00	2026-03-17 16:40:19.444924+00
\.


--
-- Data for Name: company_users; Type: TABLE DATA; Schema: empresa; Owner: -
--

COPY empresa.company_users (id, company_id, user_id, branch_id, perfil_empresa, ativo, created_at) FROM stdin;
1	1	1	1	admin	t	2026-03-17 16:33:58.773755+00
\.


--
-- Data for Name: companies; Type: TABLE DATA; Schema: empresas; Owner: -
--

COPY empresas.companies (id, codigo, nome, nome_comercial, tipo, status, moeda_base, timezone, created_at, updated_at) FROM stdin;
1	NXR-001	Nexora Demo Lda	\N	empresa	ativa	MZN	Africa/Maputo	2026-05-08 20:58:30.11641+00	2026-05-08 20:58:30.11641+00
4	NEXDEMO	Nexora Demo Lda	Nexora Demo	empresa	ativa	MZN	Africa/Maputo	2026-05-09 19:27:34.970616+00	2026-05-09 19:27:34.970616+00
\.


--
-- Data for Name: company_addresses; Type: TABLE DATA; Schema: empresas; Owner: -
--

COPY empresas.company_addresses (id, company_id, branch_id, tipo, endereco, cidade, provincia, pais, codigo_postal, created_at) FROM stdin;
\.


--
-- Data for Name: company_banks; Type: TABLE DATA; Schema: empresas; Owner: -
--

COPY empresas.company_banks (id, company_id, banco, numero_conta, nib, iban, swift, moeda, principal, created_at) FROM stdin;
\.


--
-- Data for Name: company_branches; Type: TABLE DATA; Schema: empresas; Owner: -
--

COPY empresas.company_branches (id, company_id, codigo, nome, status, principal, created_at, updated_at) FROM stdin;
1	1	BENFICA	CBE	ativa	f	2026-06-14 09:00:42.330161+00	2026-06-14 09:00:42.330161+00
\.


--
-- Data for Name: company_contacts; Type: TABLE DATA; Schema: empresas; Owner: -
--

COPY empresas.company_contacts (id, company_id, branch_id, tipo, nome, telefone, email, principal, created_at) FROM stdin;
\.


--
-- Data for Name: company_documents; Type: TABLE DATA; Schema: empresas; Owner: -
--

COPY empresas.company_documents (id, company_id, tipo, numero, ficheiro_url, emitido_em, expira_em, created_at) FROM stdin;
\.


--
-- Data for Name: company_licenses; Type: TABLE DATA; Schema: empresas; Owner: -
--

COPY empresas.company_licenses (id, company_id, plano, licenca_chave, limite_usuarios, limite_filiais, inicia_em, expira_em, status, created_at) FROM stdin;
1	1	professional	\N	10	5	2026-06-14	2026-07-01	ativa	2026-06-14 09:01:35.007556+00
\.


--
-- Data for Name: company_settings; Type: TABLE DATA; Schema: empresas; Owner: -
--

COPY empresas.company_settings (id, company_id, chave, valor, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: company_tax_info; Type: TABLE DATA; Schema: empresas; Owner: -
--

COPY empresas.company_tax_info (id, company_id, nuit, regime_iva, taxa_iva_padrao, inicio_atividade, reparticao_fiscal, created_at, updated_at) FROM stdin;
1	1	14578565577	\N	17.00	\N	\N	2026-06-14 09:01:49.798815+00	2026-06-14 09:01:49.798815+00
\.


--
-- Data for Name: company_users; Type: TABLE DATA; Schema: empresas; Owner: -
--

COPY empresas.company_users (id, company_id, user_id, branch_id, perfil_empresa, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: credit_note_items; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.credit_note_items (id, credit_note_id, product_id, descricao, quantidade, preco_unitario, tax_id, imposto_percent, imposto_valor, subtotal, total) FROM stdin;
\.


--
-- Data for Name: credit_notes; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.credit_notes (id, tenant_id, serie_id, customer_id, invoice_id, numero, credit_date, motivo, moeda, subtotal, imposto_total, total, observacoes, status, emitida_em, criado_por, created_at) FROM stdin;
1	4	5	2	1	NC0001	2026-06-15	IIII	MZN	0.00	0.00	0.00	NHBGGTB	rascunho	\N	\N	2026-06-15 17:00:57.815987+00
2	4	5	2	1	NC0002	2026-06-15	IIII	MZN	0.00	0.00	0.00	NHBGGTB	rascunho	\N	\N	2026-06-15 17:00:57.96068+00
3	4	5	2	2	NC0003	2026-06-15	YYY	EUR	0.00	0.00	0.00	YYY	rascunho	\N	\N	2026-06-15 17:01:30.881724+00
\.


--
-- Data for Name: invoice_discounts; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.invoice_discounts (id, invoice_id, tipo, valor, descricao) FROM stdin;
\.


--
-- Data for Name: invoice_items; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.invoice_items (id, invoice_id, product_id, descricao, quantidade, preco_unitario, desconto_percent, desconto_valor, tax_id, imposto_percent, imposto_valor, subtotal, total, tax_exemption_id) FROM stdin;
1	2	1	Arroz	1.0000	50.0000	0.0000	0.00	\N	17.0000	8.50	50.00	58.50	\N
2	2	1	Arroz	1.0000	50.0000	0.0000	0.00	\N	17.0000	8.50	50.00	58.50	\N
\.


--
-- Data for Name: invoice_receipts; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.invoice_receipts (id, tenant_id, serie_id, invoice_id, numero, payment_date, payment_method_id, valor, referencia, observacoes, status, criado_por, created_at) FROM stdin;
1	4	6	1	REB0001	2026-06-12	\N	10000.00	\N	\N	confirmado	\N	2026-06-12 20:26:54.214178+00
2	4	6	1	REB0002	2026-06-12	\N	10000.00	\N	\N	confirmado	\N	2026-06-12 20:26:54.280526+00
\.


--
-- Data for Name: invoice_series; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.invoice_series (id, tenant_id, tipo, prefixo, ano, sequencia, ativo, created_at) FROM stdin;
3	4	GR	GUI	2026	0	t	2026-06-12 15:10:26.485804+00
6	4	RB	REB	2026	2	t	2026-06-12 15:10:50.726221+00
1	4	ORC	FRP	2026	1	t	2026-06-12 15:10:05.543709+00
4	4	FT	FAT	2026	2	t	2026-06-12 15:10:35.469659+00
7	4	VD	VD	2026	3	t	2026-06-13 16:46:03.712032+00
5	4	NC	NC	2026	3	t	2026-06-12 15:10:42.529124+00
2	4	ENC	ECO	2026	2	t	2026-06-12 15:10:15.301227+00
\.


--
-- Data for Name: invoice_taxes; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.invoice_taxes (id, invoice_id, tax_id, nome_imposto, taxa, base_imponivel, valor_imposto) FROM stdin;
\.


--
-- Data for Name: invoices; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.invoices (id, tenant_id, serie_id, customer_id, sales_order_id, numero, invoice_date, due_date, moeda, taxa_cambio, subtotal, desconto_total, imposto_total, total, valor_pago, payment_terms, observacoes, status, emitida_em, criado_por, created_at, tipo) FROM stdin;
1	4	4	2	\N	FAT0001	2026-06-12	2026-06-26	MZN	1.000000	0.00	0.00	0.00	0.00	20000.00	\N	Faturação	emitida	2026-06-12 20:25:49.736499+00	\N	2026-06-12 20:25:25.476383+00	normal
2	4	4	2	\N	FAT0002	2026-06-12	\N	MZN	1.000000	0.00	0.00	17.00	117.00	0.00	\N	Adicionar Item	emitida	2026-06-13 03:18:33.514479+00	\N	2026-06-12 20:50:18.713899+00	normal
\.


--
-- Data for Name: sales_deliveries; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.sales_deliveries (id, tenant_id, serie_id, sales_order_id, numero, delivery_date, morada_entrega, observacoes, status, criado_por, created_at) FROM stdin;
\.


--
-- Data for Name: sales_delivery_items; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.sales_delivery_items (id, sales_delivery_id, sales_order_item_id, product_id, quantidade_entregue) FROM stdin;
\.


--
-- Data for Name: sales_order_items; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.sales_order_items (id, sales_order_id, product_id, descricao, quantidade, quantidade_entregue, preco_unitario, desconto_percent, desconto_valor, tax_id, imposto_percent, imposto_valor, subtotal, total) FROM stdin;
\.


--
-- Data for Name: sales_orders; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.sales_orders (id, tenant_id, serie_id, customer_id, sales_quote_id, numero, order_date, data_entrega_prevista, moeda, subtotal, desconto_total, imposto_total, total, observacoes, status, criado_por, created_at) FROM stdin;
1	4	2	2	\N	ECO0001	2026-06-18	\N	MZN	0.00	0.00	0.00	0.00	555555	rascunho	\N	2026-06-18 14:43:36.782578+00
2	4	2	2	\N	ECO0002	2026-06-18	\N	MZN	0.00	0.00	0.00	0.00	555555	rascunho	\N	2026-06-18 14:43:36.877381+00
\.


--
-- Data for Name: sales_quote_items; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.sales_quote_items (id, sales_quote_id, product_id, descricao, quantidade, preco_unitario, desconto_percent, desconto_valor, tax_id, imposto_percent, imposto_valor, subtotal, total) FROM stdin;
1	1	1	Arroz	1.0000	10000.0000	0.0000	0.00	\N	17.0000	1700.00	10000.00	11700.00
\.


--
-- Data for Name: sales_quotes; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.sales_quotes (id, tenant_id, serie_id, customer_id, numero, quote_date, validade, moeda, subtotal, desconto_total, imposto_total, total, observacoes, status, criado_por, created_at) FROM stdin;
1	4	\N	2	ORG	2026-06-12	2026-06-19	MZN	0.00	0.00	1700.00	11700.00	FFF	rascunho	\N	2026-06-12 15:13:10.914568+00
2	4	1	2	FRP0001	2026-06-12	2026-06-26	MZN	0.00	0.00	0.00	0.00	Faturação	rascunho	\N	2026-06-12 20:28:25.784909+00
\.


--
-- Data for Name: sales_return_items; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.sales_return_items (id, sales_return_id, product_id, quantidade, motivo, estado_produto) FROM stdin;
\.


--
-- Data for Name: sales_returns; Type: TABLE DATA; Schema: faturacao; Owner: -
--

COPY faturacao.sales_returns (id, tenant_id, customer_id, invoice_id, credit_note_id, numero, return_date, observacoes, status, criado_por, created_at) FROM stdin;
\.


--
-- Data for Name: accounts_payable; Type: TABLE DATA; Schema: financeiro; Owner: -
--

COPY financeiro.accounts_payable (id, tenant_id, numero, supplier_id, financial_category_id, origem_tipo, origem_id, descricao, valor_total, valor_pago, data_emissao, data_vencimento, status, created_at) FROM stdin;
\.


--
-- Data for Name: accounts_payable_payments; Type: TABLE DATA; Schema: financeiro; Owner: -
--

COPY financeiro.accounts_payable_payments (id, accounts_payable_id, payment_id, valor_imputado, data_imputacao) FROM stdin;
\.


--
-- Data for Name: accounts_receivable; Type: TABLE DATA; Schema: financeiro; Owner: -
--

COPY financeiro.accounts_receivable (id, tenant_id, numero, customer_id, financial_category_id, origem_tipo, origem_id, descricao, valor_total, valor_pago, data_emissao, data_vencimento, status, created_at) FROM stdin;
\.


--
-- Data for Name: accounts_receivable_payments; Type: TABLE DATA; Schema: financeiro; Owner: -
--

COPY financeiro.accounts_receivable_payments (id, accounts_receivable_id, payment_id, valor_imputado, data_imputacao) FROM stdin;
\.


--
-- Data for Name: cash_flow_entries; Type: TABLE DATA; Schema: financeiro; Owner: -
--

COPY financeiro.cash_flow_entries (id, tenant_id, financial_category_id, tipo, origem, data, valor, descricao, referencia_tipo, referencia_id, created_at) FROM stdin;
\.


--
-- Data for Name: financial_budgets; Type: TABLE DATA; Schema: financeiro; Owner: -
--

COPY financeiro.financial_budgets (id, tenant_id, financial_category_id, ano, mes, valor_orcamentado, created_at) FROM stdin;
\.


--
-- Data for Name: financial_categories; Type: TABLE DATA; Schema: financeiro; Owner: -
--

COPY financeiro.financial_categories (id, tenant_id, parent_id, codigo, nome, tipo, ativo) FROM stdin;
\.


--
-- Data for Name: payment_methods; Type: TABLE DATA; Schema: financeiro; Owner: -
--

COPY financeiro.payment_methods (id, tenant_id, codigo, nome, tipo, requer_referencia, ativo) FROM stdin;
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: financeiro; Owner: -
--

COPY financeiro.payments (id, tenant_id, numero, payment_method_id, financial_category_id, tipo, data_pagamento, valor, moeda, referencia_tipo, referencia_id, descricao, status, criado_por, created_at) FROM stdin;
\.


--
-- Data for Name: school_attendance; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_attendance (id, tenant_id, class_id, student_id, attendance_date, estado, observacoes, created_by, created_at, subject_id, enrollment_id, updated_at) FROM stdin;
\.


--
-- Data for Name: school_books; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_books (id, tenant_id, isbn, codigo, titulo, autor, editora, ano_publicacao, categoria, exemplares_total, exemplares_disponiveis, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: school_classes; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_classes (id, tenant_id, codigo, nome, nivel, ano_lectivo, turma, capacidade, activo, created_at, updated_at, school_year_id, director_teacher_id, sala, horario) FROM stdin;
\.


--
-- Data for Name: school_enrollments; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_enrollments (id, tenant_id, student_id, class_id, numero, data_matricula, status, created_by, created_at, school_year_id, observacoes, transferred_at, cancelled_at, updated_at) FROM stdin;
\.


--
-- Data for Name: school_fee_plans; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_fee_plans (id, tenant_id, school_year_id, codigo, nome, tipo, valor, moeda, periodicidade, dia_vencimento, classe_nivel, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: school_fees; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_fees (id, tenant_id, enrollment_id, numero, descricao, mes_referencia, data_vencimento, valor_total, valor_pago, moeda, status, created_at, fee_plan_id, student_id, desconto, desconto_motivo, entidade, referencia, emitida_em, updated_at) FROM stdin;
\.


--
-- Data for Name: school_grade_items; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_grade_items (id, tenant_id, class_id, subject_id, term_id, nome, tipo, data_avaliacao, nota_maxima, peso, publicado, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: school_grades; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_grades (id, tenant_id, grade_item_id, student_id, enrollment_id, nota, observacoes, lancado_por, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: school_guardians; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_guardians (id, tenant_id, student_id, nome, parentesco, telefone, email, nuit, endereco, principal, autorizado_recolher, created_at) FROM stdin;
\.


--
-- Data for Name: school_library_loans; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_library_loans (id, tenant_id, book_id, student_id, borrower_type, borrower_id, emprestado_em, devolucao_prevista, devolvido_em, status, observacoes, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: school_messages; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_messages (id, tenant_id, titulo, conteudo, tipo, audience_type, audience_id, status, publicado_em, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: school_payments; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_payments (id, tenant_id, school_fee_id, student_id, external_id, metodo, referencia, valor, moeda, status, conciliado, pago_em, created_by, payload_gateway, created_at) FROM stdin;
\.


--
-- Data for Name: school_student_roles; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_student_roles (id, tenant_id, student_id, class_id, cargo, data_inicio, data_fim, activo, observacoes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: school_students; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_students (id, tenant_id, codigo, nome, data_nascimento, genero, encarregado_nome, encarregado_telefone, encarregado_email, estado, created_at, updated_at, documento_tipo, documento_numero, nuit, telefone, email, endereco, fotografia_url) FROM stdin;
\.


--
-- Data for Name: school_subjects; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_subjects (id, tenant_id, codigo, nome, descricao, carga_horaria, nota_minima, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: school_teacher_assignments; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_teacher_assignments (id, tenant_id, school_year_id, class_id, subject_id, teacher_id, data_inicio, data_fim, activo, created_at) FROM stdin;
\.


--
-- Data for Name: school_teacher_roles; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_teacher_roles (id, tenant_id, teacher_id, cargo, school_year_id, data_inicio, data_fim, activo, observacoes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: school_terms; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_terms (id, tenant_id, school_year_id, codigo, nome, data_inicio, data_fim, peso, status, created_at) FROM stdin;
\.


--
-- Data for Name: school_years; Type: TABLE DATA; Schema: gestao_escolar; Owner: -
--

COPY gestao_escolar.school_years (id, tenant_id, codigo, nome, data_inicio, data_fim, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tax_certificates; Type: TABLE DATA; Schema: impostos; Owner: -
--

COPY impostos.tax_certificates (id, tenant_id, entity_type, entity_id, tipo, numero, data_emissao, validade, ficheiro_url, ativo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tax_exemptions; Type: TABLE DATA; Schema: impostos; Owner: -
--

COPY impostos.tax_exemptions (id, tenant_id, tax_id, entity_type, entity_id, motivo, numero_isencao, validade, ativo, created_at, data_inicio, updated_at) FROM stdin;
\.


--
-- Data for Name: tax_groups; Type: TABLE DATA; Schema: impostos; Owner: -
--

COPY impostos.tax_groups (id, tenant_id, codigo, nome, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: tax_regimes; Type: TABLE DATA; Schema: impostos; Owner: -
--

COPY impostos.tax_regimes (id, tenant_id, codigo, nome, descricao, ativo, tipo, principal, data_inicio, data_fim, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tax_return_lines; Type: TABLE DATA; Schema: impostos; Owner: -
--

COPY impostos.tax_return_lines (id, tax_return_id, codigo, descricao, natureza, base_imponivel, taxa, valor, referencia_tipo, referencia_id, documento_numero, created_at) FROM stdin;
\.


--
-- Data for Name: tax_returns; Type: TABLE DATA; Schema: impostos; Owner: -
--

COPY impostos.tax_returns (id, tenant_id, periodo, tipo, status, total_base, total_imposto, total_credito, total_a_pagar, data_submissao, created_at, periodo_inicio, periodo_fim, substitui_id, submetida_por, updated_at, total_a_recuperar) FROM stdin;
\.


--
-- Data for Name: tax_rules; Type: TABLE DATA; Schema: impostos; Owner: -
--

COPY impostos.tax_rules (id, tax_id, valor_minimo, valor_maximo, taxa, ordem, created_at) FROM stdin;
\.


--
-- Data for Name: tax_transactions; Type: TABLE DATA; Schema: impostos; Owner: -
--

COPY impostos.tax_transactions (id, tenant_id, tax_id, referencia_tipo, referencia_id, fiscal_period_id, base_tributavel, taxa_aplicada, valor_imposto, transaction_date, created_at) FROM stdin;
\.


--
-- Data for Name: taxes; Type: TABLE DATA; Schema: impostos; Owner: -
--

COPY impostos.taxes (id, tenant_id, codigo, nome, taxa, tipo, ativo, created_at, tax_group_id) FROM stdin;
\.


--
-- Data for Name: withholding_tax_transactions; Type: TABLE DATA; Schema: impostos; Owner: -
--

COPY impostos.withholding_tax_transactions (id, tenant_id, withholding_tax_id, referencia_tipo, referencia_id, base_imponivel, taxa_aplicada, valor_retido, transaction_date, entity_type, entity_id, documento_numero, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: withholding_taxes; Type: TABLE DATA; Schema: impostos; Owner: -
--

COPY impostos.withholding_taxes (id, tenant_id, codigo, nome, taxa, aplica_em, tipo_entidade, ativo, tipo, descricao, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: delivery_drivers; Type: TABLE DATA; Schema: logistica; Owner: -
--

COPY logistica.delivery_drivers (id, tenant_id, codigo, nome, telefone, documento, carta_conducao, estado, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: delivery_routes; Type: TABLE DATA; Schema: logistica; Owner: -
--

COPY logistica.delivery_routes (id, tenant_id, codigo, nome, origem, destino, distancia_km, duracao_estimada_min, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: delivery_statuses; Type: TABLE DATA; Schema: logistica; Owner: -
--

COPY logistica.delivery_statuses (id, tenant_id, codigo, nome, ordem, final, activo, created_at) FROM stdin;
\.


--
-- Data for Name: delivery_tracking; Type: TABLE DATA; Schema: logistica; Owner: -
--

COPY logistica.delivery_tracking (id, tenant_id, shipment_id, status_id, latitude, longitude, localizacao, observacoes, registado_por, registado_em) FROM stdin;
\.


--
-- Data for Name: delivery_vehicles; Type: TABLE DATA; Schema: logistica; Owner: -
--

COPY logistica.delivery_vehicles (id, tenant_id, codigo, matricula, marca, modelo, capacidade_kg, estado, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: logistics_drivers; Type: TABLE DATA; Schema: logistica; Owner: -
--

COPY logistica.logistics_drivers (id, tenant_id, codigo, nome, telefone, carta_numero, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: logistics_routes; Type: TABLE DATA; Schema: logistica; Owner: -
--

COPY logistica.logistics_routes (id, tenant_id, codigo, nome, origem, destino, distancia_km, activo, created_at) FROM stdin;
\.


--
-- Data for Name: logistics_shipments; Type: TABLE DATA; Schema: logistica; Owner: -
--

COPY logistica.logistics_shipments (id, tenant_id, numero, source_service, source_type, source_id, logistics_route_id, vehicle_id, driver_id, customer_id, delivery_address, scheduled_date, status, observacoes, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: logistics_tracking_events; Type: TABLE DATA; Schema: logistica; Owner: -
--

COPY logistica.logistics_tracking_events (id, tenant_id, shipment_id, evento, localizacao, latitude, longitude, observacoes, event_time, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: logistics_vehicles; Type: TABLE DATA; Schema: logistica; Owner: -
--

COPY logistica.logistics_vehicles (id, tenant_id, codigo, matricula, descricao, capacidade_kg, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: shipment_items; Type: TABLE DATA; Schema: logistica; Owner: -
--

COPY logistica.shipment_items (id, shipment_id, product_id, descricao, quantidade, peso_kg, created_at) FROM stdin;
\.


--
-- Data for Name: shipments; Type: TABLE DATA; Schema: logistica; Owner: -
--

COPY logistica.shipments (id, tenant_id, numero, reference_type, reference_id, customer_id, route_id, driver_id, vehicle_id, status_id, endereco_entrega, contacto_entrega, data_prevista, data_entrega, observacoes, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: currencies; Type: TABLE DATA; Schema: multi_moeda; Owner: -
--

COPY multi_moeda.currencies (id, code, name, symbol, decimals, active, created_at) FROM stdin;
1	MZN	Metical Mocambicano	MT	2	t	2026-03-17 16:28:39.044131+00
2	USD	US Dollar	$	2	t	2026-03-17 16:28:39.044131+00
3	ZAR	South African Rand	R	2	t	2026-03-17 16:28:39.044131+00
4	EUR	Euro	EUR	2	t	2026-03-17 16:28:39.044131+00
\.


--
-- Data for Name: exchange_rates; Type: TABLE DATA; Schema: multi_moeda; Owner: -
--

COPY multi_moeda.exchange_rates (id, tenant_id, base_currency_id, quote_currency_id, rate, source, effective_date, is_official, created_by, created_at) FROM stdin;
1	1	4	1	70.000000	seed	2026-03-17	f	1	2026-03-17 16:33:58.802781+00
2	1	3	1	3.450000	seed	2026-03-17	f	1	2026-03-17 16:33:58.802781+00
3	1	2	1	64.000000	seed	2026-03-17	f	1	2026-03-17 16:33:58.802781+00
4	1	1	2	0.015625	seed	2026-03-17	f	1	2026-03-17 16:33:58.802781+00
5	1	1	3	0.289855	seed	2026-03-17	f	1	2026-03-17 16:33:58.802781+00
6	1	1	4	0.014286	seed	2026-03-17	f	1	2026-03-17 16:33:58.802781+00
\.


--
-- Data for Name: tenant_currencies; Type: TABLE DATA; Schema: multi_moeda; Owner: -
--

COPY multi_moeda.tenant_currencies (id, tenant_id, currency_id, is_base, active, created_at) FROM stdin;
1	1	1	t	t	2026-03-17 16:33:58.798475+00
2	1	2	f	t	2026-03-17 16:33:58.798475+00
3	1	3	f	t	2026-03-17 16:33:58.798475+00
4	1	4	f	t	2026-03-17 16:33:58.798475+00
\.


--
-- Data for Name: notification_channels; Type: TABLE DATA; Schema: notifications; Owner: -
--

COPY notifications.notification_channels (id, tenant_id, codigo, nome, tipo, configuracao, activo, updated_by, created_at, updated_at) FROM stdin;
1	1	EMAIL_DEFAULT	Canal Email Principal	email	{"from": "no-reply@nexora.local", "provider": "smtp"}	t	1	2026-03-17 16:40:19.50574+00	2026-03-17 16:40:19.50574+00
2	1	SMS_DEFAULT	Canal SMS Principal	sms	{"provider": "mock"}	t	1	2026-03-17 16:40:19.50574+00	2026-03-17 16:40:19.50574+00
\.


--
-- Data for Name: notification_messages; Type: TABLE DATA; Schema: notifications; Owner: -
--

COPY notifications.notification_messages (id, tenant_id, channel_id, template_id, canal_tipo, destinatario, assunto, corpo, payload, referencia_tipo, referencia_id, status, tentativas, erro, enviado_em, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: notification_templates; Type: TABLE DATA; Schema: notifications; Owner: -
--

COPY notifications.notification_templates (id, tenant_id, codigo, canal_tipo, assunto, corpo, variaveis, activo, updated_by, created_at, updated_at) FROM stdin;
1	1	WELCOME_USER	email	Bem-vindo ao Nexora ERP	O utilizador {{nome}} foi criado com sucesso.	["nome"]	t	1	2026-03-17 16:40:19.513962+00	2026-03-17 16:40:19.513962+00
2	1	PASSWORD_RESET	email	Reposicao de password	Utilize o token {{token}} para redefinir a sua password.	["token"]	t	1	2026-03-17 16:40:19.513962+00	2026-03-17 16:40:19.513962+00
3	1	INVOICE_ISSUED	email	Documento emitido	O documento {{numero}} foi emitido no valor de {{total}}.	["numero", "total"]	t	1	2026-03-17 16:40:19.513962+00	2026-03-17 16:40:19.513962+00
\.


--
-- Data for Name: pos_catalog_items; Type: TABLE DATA; Schema: pos; Owner: -
--

COPY pos.pos_catalog_items (id, tenant_id, product_id, product_variant_id, codigo_barra, preco_venda, moeda, activo, created_at, updated_at) FROM stdin;
1	4	1	\N	\N	150.00	MZN	t	2026-06-13 16:46:03.89964+00	2026-06-13 16:46:03.89964+00
\.


--
-- Data for Name: pos_sale_items; Type: TABLE DATA; Schema: pos; Owner: -
--

COPY pos.pos_sale_items (id, pos_sale_id, product_id, product_variant_id, descricao, quantidade, preco_unitario, desconto_valor, imposto_valor, subtotal, total, created_at) FROM stdin;
2	2	1	\N	\N	2.00	150.00	0.00	48.00	300.00	348.00	2026-06-13 16:52:15.455311+00
3	3	1	\N	\N	10.00	150.00	0.00	255.00	1500.00	1755.00	2026-06-14 05:22:08.154817+00
4	4	1	\N	\N	8.00	150.00	0.00	204.00	1200.00	1404.00	2026-06-14 05:22:37.677842+00
\.


--
-- Data for Name: pos_sale_payments; Type: TABLE DATA; Schema: pos; Owner: -
--

COPY pos.pos_sale_payments (id, pos_sale_id, payment_method_id, tipo, valor, referencia, created_at) FROM stdin;
1	2	\N	numerario	400.00	\N	2026-06-13 16:52:15.455311+00
2	3	\N	numerario	2000.00	\N	2026-06-14 05:22:08.154817+00
3	4	\N	numerario	2000.00	\N	2026-06-14 05:22:37.677842+00
\.


--
-- Data for Name: pos_sales; Type: TABLE DATA; Schema: pos; Owner: -
--

COPY pos.pos_sales (id, tenant_id, pos_session_id, terminal_id, numero, customer_id, subtotal, desconto_total, imposto_total, total, valor_recebido, troco, moeda, status, sold_at, created_by, created_at) FROM stdin;
2	4	1	1	VD0001	\N	300.00	0.00	48.00	348.00	400.00	52.00	MZN	cancelada	2026-06-13 16:52:15.455311+00	9	2026-06-13 16:52:15.455311+00
3	4	2	1	VD0002	\N	1500.00	0.00	255.00	1755.00	2000.00	245.00	MZN	concluida	2026-06-14 05:22:08.154817+00	7	2026-06-14 05:22:08.154817+00
4	4	2	1	VD0003	\N	1200.00	0.00	204.00	1404.00	2000.00	596.00	MZN	concluida	2026-06-14 05:22:37.677842+00	7	2026-06-14 05:22:37.677842+00
\.


--
-- Data for Name: pos_sessions; Type: TABLE DATA; Schema: pos; Owner: -
--

COPY pos.pos_sessions (id, tenant_id, terminal_id, user_id, opened_at, closed_at, opening_amount, closing_amount, status, created_at) FROM stdin;
1	4	1	9	2026-06-13 16:46:20.327457+00	2026-06-13 16:53:08.14558+00	500.00	500.00	fechada	2026-06-13 16:46:20.327457+00
2	4	1	7	2026-06-13 20:39:32.018847+00	2026-06-15 13:38:09.764893+00	5.00	0.00	fechada	2026-06-13 20:39:32.018847+00
3	4	1	7	2026-06-18 14:43:55.902066+00	2026-06-18 14:44:50.963021+00	0.00	0.00	fechada	2026-06-18 14:43:55.902066+00
4	4	1	10	2026-06-21 11:42:34.418327+00	\N	0.00	\N	aberta	2026-06-21 11:42:34.418327+00
5	4	1	7	2026-06-21 14:59:02.069944+00	\N	0.00	\N	aberta	2026-06-21 14:59:02.069944+00
\.


--
-- Data for Name: pos_terminals; Type: TABLE DATA; Schema: pos; Owner: -
--

COPY pos.pos_terminals (id, tenant_id, codigo, nome, warehouse_id, caixa_id, activo, created_at, updated_at) FROM stdin;
1	4	T1	Caixa 1	1	\N	t	2026-06-13 16:41:01.11095+00	2026-06-13 16:41:01.11095+00
\.


--
-- Data for Name: product_attribute_values; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_attribute_values (id, product_attribute_id, product_id, product_variant_id, valor, created_at) FROM stdin;
\.


--
-- Data for Name: product_attributes; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_attributes (id, tenant_id, codigo, nome, tipo, created_at) FROM stdin;
\.


--
-- Data for Name: product_barcodes; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_barcodes (id, product_id, product_variant_id, barcode, tipo, principal, created_at) FROM stdin;
\.


--
-- Data for Name: product_brands; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_brands (id, tenant_id, codigo, nome, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: product_categories; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_categories (id, tenant_id, codigo, nome, descricao, ativo, created_at, parent_id, updated_at) FROM stdin;
1	4	CAT012	COMIDA	COMIDA	t	2026-06-12 17:08:56.188901+00	\N	2026-06-15 02:56:02.916454+00
\.


--
-- Data for Name: product_discounts; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_discounts (id, product_id, product_variant_id, tipo, valor, motivo, inicia_em, fim_em, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: product_images; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_images (id, product_id, ficheiro_url, principal, ordem, created_at) FROM stdin;
\.


--
-- Data for Name: product_kit_items; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_kit_items (id, product_kit_id, item_product_id, item_variant_id, quantidade, created_at) FROM stdin;
\.


--
-- Data for Name: product_kits; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_kits (id, product_id, codigo, nome, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: product_prices; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_prices (id, product_id, product_variant_id, tipo_preco, moeda, valor, inicia_em, fim_em, ativo, created_at) FROM stdin;
1	1	\N	venda	MZN	50.00	\N	\N	t	2026-06-12 21:02:48.388952+00
\.


--
-- Data for Name: product_subcategories; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_subcategories (id, tenant_id, product_category_id, codigo, nome, descricao, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: product_tag_links; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_tag_links (id, product_id, product_tag_id, created_at) FROM stdin;
\.


--
-- Data for Name: product_tags; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_tags (id, tenant_id, codigo, nome, cor, created_at) FROM stdin;
\.


--
-- Data for Name: product_units; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_units (id, tenant_id, codigo, nome, simbolo, casas_decimais, created_at) FROM stdin;
\.


--
-- Data for Name: product_variants; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.product_variants (id, product_id, codigo, nome, sku, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.products (id, tenant_id, product_category_id, product_subcategory_id, product_brand_id, product_unit_id, warehouse_default_id, codigo, nome, descricao, tipo, iva_percentual, stock_minimo, ativo, created_at, updated_at) FROM stdin;
1	4	1	\N	\N	\N	\N	PRODUTO	Arroz	Arroz	variavel	17.00	0.00	t	2026-06-12 17:10:09.669466+00	2026-06-12 17:10:09.669466+00
\.


--
-- Data for Name: warehouses; Type: TABLE DATA; Schema: produtos; Owner: -
--

COPY produtos.warehouses (id, tenant_id, codigo, nome, localizacao, ativo, created_at) FROM stdin;
1	4	WH1	Armazém Principal	\N	t	2026-06-13 16:41:00.863909+00
\.


--
-- Data for Name: chat_conversas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.chat_conversas (id, tenant_id, nome, tipo, criado_por, created_at) FROM stdin;
1	4	\N	individual	7	2026-06-20 07:45:30.747317+00
2	4	Equipa TI	grupo	7	2026-06-20 07:58:27.067746+00
3	4	Equipa TI	grupo	7	2026-06-20 07:58:27.475915+00
4	4	\N	individual	10	2026-06-20 08:02:58.582537+00
5	4	\N	individual	10	2026-06-20 08:02:58.679644+00
6	4	\N	individual	11	2026-06-20 09:00:06.544705+00
7	4	\N	individual	11	2026-06-20 09:00:53.998301+00
8	4	tvs	grupo	10	2026-06-20 09:13:34.256243+00
\.


--
-- Data for Name: chat_mensagens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.chat_mensagens (id, conversa_id, autor_id, conteudo, tipo, ficheiro_url, eliminada, editada_em, created_at) FROM stdin;
1	4	10	hhhhhh	texto	\N	f	\N	2026-06-20 08:57:21.5399+00
2	6	11	kkkkk	texto	\N	f	\N	2026-06-20 09:00:11.281953+00
3	7	11	ggtt	texto	\N	f	\N	2026-06-20 09:00:59.995405+00
4	8	10	bom dia	texto	\N	f	\N	2026-06-20 09:13:48.090618+00
5	8	11	bol	texto	\N	f	\N	2026-06-20 18:51:00.426192+00
6	8	10	vv	texto	\N	f	\N	2026-06-20 19:03:02.892186+00
7	8	11	kkg	texto	\N	f	\N	2026-06-20 19:03:38.338016+00
8	8	10	i	texto	\N	f	\N	2026-06-20 19:03:49.213497+00
9	7	11	by	texto	\N	f	\N	2026-06-20 19:04:32.634404+00
10	7	11	uuuuu	texto	\N	f	\N	2026-06-20 19:04:42.297526+00
11	7	10	ffffff	texto	\N	f	\N	2026-06-20 19:04:49.124829+00
12	7	10	hhhhh	texto	\N	f	\N	2026-06-20 19:04:54.240551+00
13	7	10	uuuu	texto	\N	f	\N	2026-06-20 19:21:25.059056+00
14	7	11	uu	texto	\N	f	\N	2026-06-20 19:21:37.354968+00
15	7	10	bingo	texto	\N	f	\N	2026-06-20 22:02:00.497618+00
16	7	11	yes	texto	\N	f	\N	2026-06-20 22:02:22.358481+00
17	7	10	bjjj	texto	\N	f	\N	2026-06-20 22:02:32.489065+00
18	7	11	hhhh	texto	\N	f	\N	2026-06-20 22:02:58.950582+00
19	7	11	hhh	texto	\N	f	\N	2026-06-20 22:03:12.677557+00
\.


--
-- Data for Name: chat_participantes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.chat_participantes (conversa_id, user_id, adicionado_em, ultima_leitura) FROM stdin;
1	7	2026-06-20 07:45:30.747317+00	\N
2	7	2026-06-20 07:58:27.067746+00	\N
2	9	2026-06-20 07:58:27.067746+00	\N
3	7	2026-06-20 07:58:27.475915+00	\N
3	9	2026-06-20 07:58:27.475915+00	\N
4	7	2026-06-20 08:02:58.582537+00	\N
5	10	2026-06-20 08:02:58.679644+00	\N
5	7	2026-06-20 08:02:58.679644+00	\N
8	7	2026-06-20 09:13:34.256243+00	\N
8	9	2026-06-20 09:13:34.256243+00	\N
6	11	2026-06-20 09:00:06.544705+00	2026-06-20 09:00:50.78801+00
8	11	2026-06-20 09:13:34.256243+00	2026-06-20 19:04:12.126+00
7	11	2026-06-20 09:00:53.998301+00	2026-06-20 22:02:15.412936+00
8	10	2026-06-20 09:13:34.256243+00	2026-06-21 02:58:14.148303+00
4	10	2026-06-20 08:02:58.582537+00	2026-06-21 02:58:17.242981+00
7	10	2026-06-20 09:00:53.998301+00	2026-06-21 07:56:30.902042+00
\.


--
-- Data for Name: comunicados; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.comunicados (id, tenant_id, titulo, conteudo, autor_id, expira_em, created_at) FROM stdin;
\.


--
-- Data for Name: comunicados_lidos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.comunicados_lidos (comunicado_id, user_id, lido_em) FROM stdin;
\.


--
-- Data for Name: notif_colaborador; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notif_colaborador (id, tenant_id, user_id, tipo, titulo, corpo, lida, link, created_at) FROM stdin;
\.


--
-- Data for Name: candidatura_notas; Type: TABLE DATA; Schema: recrutamento; Owner: -
--

COPY recrutamento.candidatura_notas (id, candidatura_id, autor, tipo, conteudo, created_at) FROM stdin;
9	6	sistema	sistema	Estado alterado: Recebida → Em Análise	2026-06-11 07:38:39.885135+00
10	6	sistema	sistema	Estado alterado: Em Análise → Recebida	2026-06-11 08:37:06.25462+00
11	6	sistema	sistema	Estado alterado: Recebida → Em Análise	2026-06-11 09:52:36.006381+00
12	6	sistema	sistema	Estado alterado: Em Análise → Entrevista	2026-06-11 09:52:47.05403+00
13	6	sistema	sistema	Estado alterado: Entrevista → Aprovada	2026-06-11 09:53:08.904029+00
\.


--
-- Data for Name: candidaturas; Type: TABLE DATA; Schema: recrutamento; Owner: -
--

COPY recrutamento.candidaturas (id, tenant_id, vaga_id, nome, email, telefone, vaga_titulo, carta, cv_ficheiro, carta_ficheiro, ip, estado, score, responsavel, entrevista_data, entrevista_local, entrevista_link, entrevista_notas, created_at, updated_at) FROM stdin;
6	1	5	Eleuterio Fulaho Notico	eleuterio3d@gmail.com	+258852957672	Desenvolvedor Frontend	\N	cv/cv_20260611_093812_2085f616.pdf	cv/carta_20260611_093812_76082967.pdf	127.0.0.1	aprovada	\N	\N	\N	\N	\N	\N	2026-06-11 07:38:12.582654+00	2026-06-11 09:53:08.904029+00
\.


--
-- Data for Name: contactos; Type: TABLE DATA; Schema: recrutamento; Owner: -
--

COPY recrutamento.contactos (id, tenant_id, nome, email, assunto, mensagem, ip, lido, created_at) FROM stdin;
\.


--
-- Data for Name: vagas; Type: TABLE DATA; Schema: recrutamento; Owner: -
--

COPY recrutamento.vagas (id, tenant_id, titulo, area, local, regime, tipo, descricao, sobre_funcao, responsabilidades, req_obrigatorios, req_preferenciais, oferece, ativa, num_vagas, prazo, created_at, updated_at) FROM stdin;
5	1	Desenvolvedor Frontend	Administrativo	Maputo, Moçambique	Presencial	Estágio	1c35b824843dab40bd	1c35b824843dab40bd	["1c35b824843dab40bd", "1c35b824843dab40bd"]	["1c35b824843dab40bd", "1c35b824843dab40bd"]	["1c35b824843dab40bd", "1c35b824843dab40bd"]	["1c35b824843dab40bd", "1c35b824843dab40bd"]	t	1	2026-06-18	2026-06-11 07:33:06.408853+00	2026-06-11 07:33:06.408853+00
6	1	Saude e vida	Saude e vida	Maputo, Moçambique	Presencial	Estágio	Saude e vida	Saude e vida	["Saude e vida", "Saude e vida"]	["Saude e vida", "Saude e vida"]	["Saude e vida", "Saude e vida"]	["Saude e vida", "Saude e vida", "Saude e vida"]	t	1	2026-06-18	2026-06-11 07:36:51.873925+00	2026-06-11 07:36:51.873925+00
\.


--
-- Data for Name: employee_bank_accounts; Type: TABLE DATA; Schema: recursos_humanos; Owner: -
--

COPY recursos_humanos.employee_bank_accounts (id, employee_id, banco, numero_conta, nib, moeda, principal, created_at) FROM stdin;
\.


--
-- Data for Name: employees; Type: TABLE DATA; Schema: recursos_humanos; Owner: -
--

COPY recursos_humanos.employees (id, tenant_id, department_id, user_id, codigo, nome, email, telefone, nuit, data_nascimento, data_admissao, estado, cargo, tipo_contrato, salario_base, moeda, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: hr_departments; Type: TABLE DATA; Schema: recursos_humanos; Owner: -
--

COPY recursos_humanos.hr_departments (id, tenant_id, codigo, nome, descricao, ativo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: payroll_periods; Type: TABLE DATA; Schema: recursos_humanos; Owner: -
--

COPY recursos_humanos.payroll_periods (id, tenant_id, ano, mes, data_inicio, data_fim, status, fechado_em, fechado_por, created_at) FROM stdin;
\.


--
-- Data for Name: payroll_run_lines; Type: TABLE DATA; Schema: recursos_humanos; Owner: -
--

COPY recursos_humanos.payroll_run_lines (id, payroll_run_id, employee_id, salario_base, adicionais, descontos, bruto, liquido, observacoes, created_at) FROM stdin;
\.


--
-- Data for Name: payroll_runs; Type: TABLE DATA; Schema: recursos_humanos; Owner: -
--

COPY recursos_humanos.payroll_runs (id, tenant_id, payroll_period_id, numero, processamento_em, status, total_bruto, total_descontos, total_liquido, criado_por, aprovado_por, aprovado_em, created_at) FROM stdin;
\.


--
-- Data for Name: ausencias; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.ausencias (id, tenant_id, funcionario_id, tipo, data_inicio, data_fim, dias, motivo, estado, aprovado_por, aprovado_em, created_at, tipo_id) FROM stdin;
3	4	1	\N	2026-06-20	2026-06-27	5	Nexora@2026	pendente	\N	\N	2026-06-20 08:49:53.23169+00	1
1	4	1	\N	2026-07-14	2026-07-25	9	Férias de verão	pendente	\N	\N	2026-06-20 08:03:01.358039+00	1
2	4	1	\N	2026-07-14	2026-07-25	9	Férias de verão	pendente	\N	\N	2026-06-20 08:03:01.532471+00	1
\.


--
-- Data for Name: avaliacao_criterios; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.avaliacao_criterios (id, avaliacao_id, criterio_id, pontuacao) FROM stdin;
\.


--
-- Data for Name: avaliacoes; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.avaliacoes (id, tenant_id, funcionario_id, periodo, avaliador_id, pontuacao, comentarios, created_at, periodo_id, estado, aprovado_por, aprovado_em) FROM stdin;
\.


--
-- Data for Name: beneficios; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.beneficios (id, tenant_id, codigo, nome, descricao, valor_padrao, ativo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: cargos; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.cargos (id, tenant_id, codigo, nome, descricao, salario_min, salario_max, ativo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: componentes_salariais; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.componentes_salariais (id, tenant_id, codigo, nome, tipo, forma_calculo, valor_padrao, ativo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: contactos_emergencia; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.contactos_emergencia (id, tenant_id, funcionario_id, nome, parentesco, telefone, email, created_at) FROM stdin;
\.


--
-- Data for Name: contratos; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.contratos (id, tenant_id, funcionario_id, tipo, funcao, data_inicio, data_fim, salario, ficheiro_url, estado, created_at) FROM stdin;
\.


--
-- Data for Name: criterios_avaliacao; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.criterios_avaliacao (id, tenant_id, codigo, nome, descricao, peso, ativo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: documentos_funcionario; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.documentos_funcionario (id, tenant_id, funcionario_id, tipo, numero, data_emissao, data_validade, ficheiro_url, created_at) FROM stdin;
\.


--
-- Data for Name: folhas_pagamento; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.folhas_pagamento (id, tenant_id, ano, mes, estado, num_funcionarios, total_proventos, total_descontos, total_liquido, processada_em, processada_por, paga_em, created_at) FROM stdin;
\.


--
-- Data for Name: formacoes; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.formacoes (id, tenant_id, codigo, nome, descricao, categoria, duracao_horas, entidade_formadora, ativo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: funcionario_beneficios; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.funcionario_beneficios (id, tenant_id, funcionario_id, beneficio_id, valor, data_inicio, data_fim, observacoes, created_at) FROM stdin;
\.


--
-- Data for Name: funcionario_componentes_salariais; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.funcionario_componentes_salariais (id, tenant_id, funcionario_id, componente_id, valor, created_at) FROM stdin;
\.


--
-- Data for Name: funcionario_formacoes; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.funcionario_formacoes (id, tenant_id, funcionario_id, formacao_id, data_inicio, data_fim, estado, nota, certificado_url, observacoes, created_at) FROM stdin;
\.


--
-- Data for Name: funcionarios; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.funcionarios (id, tenant_id, unit_id, numero_funcionario, nome_completo, data_nascimento, genero, nuit, telefone, email, endereco, cargo, data_admissao, data_saida, tipo_contrato, salario_base, estado, created_at, updated_at, user_id, cargo_id, horario_id, provincia, cidade, bairro) FROM stdin;
1	4	\N	\N	Eleuterio Fulaho Notico	\N	\N	\N	\N	eleuterio3d@gmail.com	\N	\N	2026-06-20	\N	efetivo	\N	ativo	2026-06-20 08:01:59.77768+00	2026-06-20 08:01:59.77768+00	10	\N	\N	\N	\N	\N
\.


--
-- Data for Name: historico_salarial; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.historico_salarial (id, tenant_id, funcionario_id, salario_anterior, salario_novo, data_efectiva, motivo, created_at) FROM stdin;
\.


--
-- Data for Name: horarios_trabalho; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.horarios_trabalho (id, tenant_id, codigo, nome, descricao, hora_entrada, hora_saida, intervalo_inicio, intervalo_fim, dias_semana, carga_semanal_horas, ativo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: justificacoes; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.justificacoes (id, tenant_id, funcionario_id, tipo, data, motivo, estado, ficheiro_url, aprovado_por, aprovado_em, created_at) FROM stdin;
1	4	1	falta	2026-06-19	Consulta medica de urgencia	pendente	\N	\N	\N	2026-06-20 08:02:59.710056+00
2	4	1	falta	2026-06-19	Consulta medica de urgencia	pendente	\N	\N	\N	2026-06-20 08:02:59.830288+00
\.


--
-- Data for Name: periodos_avaliacao; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.periodos_avaliacao (id, tenant_id, nome, data_inicio, data_fim, estado, created_at) FROM stdin;
\.


--
-- Data for Name: presencas; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.presencas (id, tenant_id, funcionario_id, data, hora_entrada, hora_saida, horas_extra, observacoes, created_at, latitude, longitude, observacao, tipo) FROM stdin;
\.


--
-- Data for Name: processos_disciplinares; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.processos_disciplinares (id, tenant_id, funcionario_id, tipo, motivo, descricao, data_ocorrencia, data_abertura, estado, decisao, data_decisao, aberto_por, decidido_por, created_at) FROM stdin;
\.


--
-- Data for Name: recibo_vencimento_itens; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.recibo_vencimento_itens (id, recibo_id, componente_id, nome, tipo, valor) FROM stdin;
\.


--
-- Data for Name: recibos_vencimento; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.recibos_vencimento (id, tenant_id, folha_id, funcionario_id, salario_base, total_proventos, total_descontos, salario_liquido, estado, created_at) FROM stdin;
\.


--
-- Data for Name: saldos_ausencia; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.saldos_ausencia (id, tenant_id, funcionario_id, tipo_ausencia_id, ano, dias_atribuidos, dias_usados, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tipos_ausencia; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.tipos_ausencia (id, tenant_id, codigo, nome, dias_anuais, remunerada, afeta_saldo, ativo, created_at, updated_at) FROM stdin;
1	4	FERIAS	Férias Anuais	22.00	t	t	t	2026-06-20 08:01:59.793043+00	2026-06-20 08:01:59.793043+00
\.


--
-- Data for Name: unidades_organizacionais; Type: TABLE DATA; Schema: rh; Owner: -
--

COPY rh.unidades_organizacionais (id, tenant_id, codigo, nome, descricao, responsavel_id, ativo, created_at, updated_at, tipo, parent_id) FROM stdin;
\.


--
-- Data for Name: security_ip_allowlist; Type: TABLE DATA; Schema: seguranca; Owner: -
--

COPY seguranca.security_ip_allowlist (id, tenant_id, descricao, ip_or_cidr, activo, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: security_mfa_enrollments; Type: TABLE DATA; Schema: seguranca; Owner: -
--

COPY seguranca.security_mfa_enrollments (id, tenant_id, user_id, metodo, secret, verified, last_verified_at, revoked_at, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: security_policies; Type: TABLE DATA; Schema: seguranca; Owner: -
--

COPY seguranca.security_policies (id, tenant_id, codigo, nome, configuracao, activo, updated_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: api_logs; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.api_logs (id, tenant_id, metodo, rota, status_code, duracao_ms, created_at) FROM stdin;
\.


--
-- Data for Name: cities; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.cities (id, country_id, nome) FROM stdin;
1	1	Maputo
\.


--
-- Data for Name: countries; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.countries (id, codigo, nome) FROM stdin;
1	MZ	mozambique
\.


--
-- Data for Name: currencies; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.currencies (id, codigo, nome, simbolo, ativa) FROM stdin;
1	MZN	Metical	MT	t
2	USD	Dolar	$	t
\.


--
-- Data for Name: email_templates; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.email_templates (id, tenant_id, codigo, assunto, corpo) FROM stdin;
\.


--
-- Data for Name: exchange_rates; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.exchange_rates (id, from_currency_id, to_currency_id, rate, rate_date) FROM stdin;
1	2	1	64.000000	2026-06-15
\.


--
-- Data for Name: integrations; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.integrations (id, tenant_id, codigo, nome, configuracao, ativa) FROM stdin;
\.


--
-- Data for Name: languages; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.languages (id, codigo, nome) FROM stdin;
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.settings (id, tenant_id, chave, valor, escopo) FROM stdin;
1	4	E258tech Mozambique	E258tech	tenant
\.


--
-- Data for Name: sms_templates; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.sms_templates (id, tenant_id, codigo, corpo) FROM stdin;
\.


--
-- Data for Name: system_logs; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.system_logs (id, tenant_id, nivel, modulo, mensagem, created_at) FROM stdin;
\.


--
-- Data for Name: tenant_branding; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.tenant_branding (id, tenant_id, logo_url, cor_primaria, cor_secundaria, slogan, website_url, suporte_email, suporte_telefone, updated_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tenant_defaults; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.tenant_defaults (id, tenant_id, chave, valor, updated_by, created_at, updated_at) FROM stdin;
1	1	default_currency	MZN	1	2026-03-17 16:40:19.493297+00	2026-03-17 16:40:19.493297+00
2	1	timezone	Africa/Maputo	1	2026-03-17 16:40:19.493297+00	2026-03-17 16:40:19.493297+00
3	1	locale	pt-MZ	1	2026-03-17 16:40:19.493297+00	2026-03-17 16:40:19.493297+00
4	1	fiscal_year_start_month	1	1	2026-03-17 16:40:19.493297+00	2026-03-17 16:40:19.493297+00
5	1	date_format	YYYY-MM-DD	1	2026-03-17 16:40:19.493297+00	2026-03-17 16:40:19.493297+00
6	1	number_format	pt-MZ	1	2026-03-17 16:40:19.493297+00	2026-03-17 16:40:19.493297+00
\.


--
-- Data for Name: tenant_document_settings; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.tenant_document_settings (id, tenant_id, modulo, tipo_documento, prefixo, reinicia_anualmente, serie_activa, layout_template, updated_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tenant_feature_flags; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.tenant_feature_flags (id, tenant_id, codigo, activo, configuracao, updated_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tenant_integrations; Type: TABLE DATA; Schema: sistema_configuracao; Owner: -
--

COPY sistema_configuracao.tenant_integrations (id, tenant_id, codigo, activo, endpoint_url, credenciais, configuracao, updated_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: stock_adjustments; Type: TABLE DATA; Schema: stock; Owner: -
--

COPY stock.stock_adjustments (id, tenant_id, stock_item_id, adjustment_type, quantity, reason, adjusted_at) FROM stdin;
\.


--
-- Data for Name: stock_alerts; Type: TABLE DATA; Schema: stock; Owner: -
--

COPY stock.stock_alerts (id, tenant_id, stock_item_id, alert_type, status, mensagem, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: stock_batches; Type: TABLE DATA; Schema: stock; Owner: -
--

COPY stock.stock_batches (id, stock_item_id, batch_number, manufacture_date, expiry_date, quantity, created_at) FROM stdin;
\.


--
-- Data for Name: stock_count_items; Type: TABLE DATA; Schema: stock; Owner: -
--

COPY stock.stock_count_items (id, stock_count_id, stock_item_id, system_quantity, counted_quantity, difference_quantity, created_at) FROM stdin;
\.


--
-- Data for Name: stock_counts; Type: TABLE DATA; Schema: stock; Owner: -
--

COPY stock.stock_counts (id, tenant_id, numero, warehouse_id, status, count_date, created_at, closed_at, cancelled_at) FROM stdin;
\.


--
-- Data for Name: stock_items; Type: TABLE DATA; Schema: stock; Owner: -
--

COPY stock.stock_items (id, tenant_id, product_id, product_variant_id, warehouse_id, quantity, reserved_quantity, minimum_quantity, maximum_quantity, updated_at) FROM stdin;
1	4	1	\N	1	82.00	0.00	0.00	\N	2026-06-14 05:22:37.677842+00
\.


--
-- Data for Name: stock_logs; Type: TABLE DATA; Schema: stock; Owner: -
--

COPY stock.stock_logs (id, tenant_id, stock_item_id, acao, detalhe, created_at) FROM stdin;
\.


--
-- Data for Name: stock_movements; Type: TABLE DATA; Schema: stock; Owner: -
--

COPY stock.stock_movements (id, tenant_id, stock_item_id, tipo, quantity, reference_type, reference_id, movement_date, created_at) FROM stdin;
1	4	1	saida	2.00	pos_sale	2	2026-06-13 16:52:15.455311+00	2026-06-13 16:52:15.455311+00
2	4	1	entrada	2.00	pos_sale_cancel	2	2026-06-13 16:52:45.675368+00	2026-06-13 16:52:45.675368+00
3	4	1	saida	10.00	pos_sale	3	2026-06-14 05:22:08.154817+00	2026-06-14 05:22:08.154817+00
4	4	1	saida	8.00	pos_sale	4	2026-06-14 05:22:37.677842+00	2026-06-14 05:22:37.677842+00
\.


--
-- Data for Name: stock_reservations; Type: TABLE DATA; Schema: stock; Owner: -
--

COPY stock.stock_reservations (id, tenant_id, stock_item_id, quantity, reference_type, reference_id, status, reserved_at, updated_at) FROM stdin;
\.


--
-- Data for Name: stock_serial_numbers; Type: TABLE DATA; Schema: stock; Owner: -
--

COPY stock.stock_serial_numbers (id, stock_item_id, serial_number, status, created_at) FROM stdin;
\.


--
-- Data for Name: stock_transfer_items; Type: TABLE DATA; Schema: stock; Owner: -
--

COPY stock.stock_transfer_items (id, stock_transfer_id, stock_item_id, quantity) FROM stdin;
\.


--
-- Data for Name: stock_transfers; Type: TABLE DATA; Schema: stock; Owner: -
--

COPY stock.stock_transfers (id, tenant_id, numero, from_warehouse_id, to_warehouse_id, status, transfer_date, created_at, confirmed_at, received_at, cancelled_at) FROM stdin;
\.


--
-- Data for Name: warehouse_locations; Type: TABLE DATA; Schema: stock; Owner: -
--

COPY stock.warehouse_locations (id, warehouse_id, codigo, nome, tipo, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: bank_accounts; Type: TABLE DATA; Schema: tesouraria; Owner: -
--

COPY tesouraria.bank_accounts (id, tenant_id, codigo, banco, numero_conta, iban, moeda, saldo_inicial, saldo_actual, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: caixas; Type: TABLE DATA; Schema: tesouraria; Owner: -
--

COPY tesouraria.caixas (id, tenant_id, nome, saldo_atual, ativo, created_at) FROM stdin;
\.


--
-- Data for Name: cash_registers; Type: TABLE DATA; Schema: tesouraria; Owner: -
--

COPY tesouraria.cash_registers (id, tenant_id, codigo, nome, moeda, saldo_inicial, saldo_actual, activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: contas_bancarias; Type: TABLE DATA; Schema: tesouraria; Owner: -
--

COPY tesouraria.contas_bancarias (id, tenant_id, banco, numero_conta, nib, moeda, saldo_atual, ativa, created_at) FROM stdin;
\.


--
-- Data for Name: movements; Type: TABLE DATA; Schema: tesouraria; Owner: -
--

COPY tesouraria.movements (id, tenant_id, bank_account_id, cash_register_id, tipo, valor, moeda, data_movimento, metodo, referencia, descricao, reference_type, reference_id, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: movimentos_financeiros; Type: TABLE DATA; Schema: tesouraria; Owner: -
--

COPY tesouraria.movimentos_financeiros (id, tenant_id, origem_tipo, origem_id, conta_bancaria_id, caixa_id, tipo, valor, referencia, descricao, data_movimento) FROM stdin;
\.


--
-- Data for Name: reconciliacoes_bancarias; Type: TABLE DATA; Schema: tesouraria; Owner: -
--

COPY tesouraria.reconciliacoes_bancarias (id, tenant_id, conta_bancaria_id, periodo_inicio, periodo_fim, saldo_extrato, saldo_sistema, diferenca, status, created_at) FROM stdin;
\.


--
-- Data for Name: reconciliations; Type: TABLE DATA; Schema: tesouraria; Owner: -
--

COPY tesouraria.reconciliations (id, tenant_id, bank_account_id, periodo_inicio, periodo_fim, saldo_extracto, saldo_sistema, diferenca, status, observacoes, criada_por, fechada_por, fechada_em, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: utilizadores; Owner: -
--

COPY utilizadores.profiles (id, user_id, primeiro_nome, ultimo_nome, nome_exibicao, data_nascimento, genero, idioma, timezone, bio, created_at, updated_at) FROM stdin;
1	4	Carlos	Admin	\N	\N	\N	pt	Africa/Maputo	\N	2026-05-08 20:00:20.430513+00	2026-05-08 20:00:20.430513+00
\.


--
-- Data for Name: user_activity; Type: TABLE DATA; Schema: utilizadores; Owner: -
--

COPY utilizadores.user_activity (id, user_id, modulo, acao, descricao, ip_address, created_at) FROM stdin;
\.


--
-- Data for Name: user_avatar; Type: TABLE DATA; Schema: utilizadores; Owner: -
--

COPY utilizadores.user_avatar (id, user_id, ficheiro_url, mime_type, tamanho_bytes, created_at) FROM stdin;
\.


--
-- Data for Name: user_devices; Type: TABLE DATA; Schema: utilizadores; Owner: -
--

COPY utilizadores.user_devices (id, user_id, device_id, nome, plataforma, user_agent, ultimo_acesso_em, confiavel, created_at) FROM stdin;
1	4	pc-001	Desktop	Windows	curl/8.17.0	2026-05-08 20:00:23.631601+00	t	2026-05-08 20:00:23.631601+00
\.


--
-- Data for Name: user_notifications; Type: TABLE DATA; Schema: utilizadores; Owner: -
--

COPY utilizadores.user_notifications (id, user_id, tipo, titulo, mensagem, lida, lida_em, created_at) FROM stdin;
1	4	info	Bem-vindo	O seu perfil foi criado.	f	\N	2026-05-08 20:00:21.654314+00
\.


--
-- Data for Name: user_preferences; Type: TABLE DATA; Schema: utilizadores; Owner: -
--

COPY utilizadores.user_preferences (id, user_id, chave, valor, created_at, updated_at) FROM stdin;
1	4	tema	dark	2026-05-08 20:00:21.158792+00	2026-05-08 20:00:21.158792+00
\.


--
-- Data for Name: user_security_logs; Type: TABLE DATA; Schema: utilizadores; Owner: -
--

COPY utilizadores.user_security_logs (id, user_id, evento, severidade, detalhe, ip_address, created_at) FROM stdin;
\.


--
-- Data for Name: user_settings; Type: TABLE DATA; Schema: utilizadores; Owner: -
--

COPY utilizadores.user_settings (id, user_id, chave, valor, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_tokens; Type: TABLE DATA; Schema: utilizadores; Owner: -
--

COPY utilizadores.user_tokens (id, user_id, tipo, token_hash, expira_em, revogado_em, created_at) FROM stdin;
\.


--
-- Name: subscription_invoices_id_seq; Type: SEQUENCE SET; Schema: assinaturas; Owner: -
--

SELECT pg_catalog.setval('assinaturas.subscription_invoices_id_seq', 1, false);


--
-- Name: subscription_plans_id_seq; Type: SEQUENCE SET; Schema: assinaturas; Owner: -
--

SELECT pg_catalog.setval('assinaturas.subscription_plans_id_seq', 2, true);


--
-- Name: subscription_usage_id_seq; Type: SEQUENCE SET; Schema: assinaturas; Owner: -
--

SELECT pg_catalog.setval('assinaturas.subscription_usage_id_seq', 1, false);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE SET; Schema: assinaturas; Owner: -
--

SELECT pg_catalog.setval('assinaturas.subscriptions_id_seq', 1, false);


--
-- Name: audit_events_id_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: -
--

SELECT pg_catalog.setval('auditoria.audit_events_id_seq', 1, false);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: -
--

SELECT pg_catalog.setval('auditoria.audit_logs_id_seq', 7, true);


--
-- Name: api_keys_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.api_keys_id_seq', 1, false);


--
-- Name: cargos_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.cargos_id_seq', 1, true);


--
-- Name: email_verifications_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.email_verifications_id_seq', 1, false);


--
-- Name: login_history_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.login_history_id_seq', 137, true);


--
-- Name: password_resets_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.password_resets_id_seq', 1, false);


--
-- Name: permissoes_cargo_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.permissoes_cargo_id_seq', 12, true);


--
-- Name: permissoes_diretas_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.permissoes_diretas_id_seq', 754, true);


--
-- Name: permissoes_tipo_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.permissoes_tipo_id_seq', 11, true);


--
-- Name: sessions_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.sessions_id_seq', 297, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.users_id_seq', 11, true);


--
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: autorizacao; Owner: -
--

SELECT pg_catalog.setval('autorizacao.permissions_id_seq', 18, true);


--
-- Name: role_permissions_id_seq; Type: SEQUENCE SET; Schema: autorizacao; Owner: -
--

SELECT pg_catalog.setval('autorizacao.role_permissions_id_seq', 18, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: autorizacao; Owner: -
--

SELECT pg_catalog.setval('autorizacao.roles_id_seq', 4, true);


--
-- Name: user_roles_id_seq; Type: SEQUENCE SET; Schema: autorizacao; Owner: -
--

SELECT pg_catalog.setval('autorizacao.user_roles_id_seq', 3, true);


--
-- Name: cost_center_allocations_id_seq; Type: SEQUENCE SET; Schema: centros_custo; Owner: -
--

SELECT pg_catalog.setval('centros_custo.cost_center_allocations_id_seq', 1, false);


--
-- Name: cost_center_budgets_id_seq; Type: SEQUENCE SET; Schema: centros_custo; Owner: -
--

SELECT pg_catalog.setval('centros_custo.cost_center_budgets_id_seq', 1, false);


--
-- Name: cost_centers_id_seq; Type: SEQUENCE SET; Schema: centros_custo; Owner: -
--

SELECT pg_catalog.setval('centros_custo.cost_centers_id_seq', 1, false);


--
-- Name: customer_addresses_id_seq; Type: SEQUENCE SET; Schema: clientes; Owner: -
--

SELECT pg_catalog.setval('clientes.customer_addresses_id_seq', 1, true);


--
-- Name: customer_balances_id_seq; Type: SEQUENCE SET; Schema: clientes; Owner: -
--

SELECT pg_catalog.setval('clientes.customer_balances_id_seq', 1, false);


--
-- Name: customer_contacts_id_seq; Type: SEQUENCE SET; Schema: clientes; Owner: -
--

SELECT pg_catalog.setval('clientes.customer_contacts_id_seq', 2, true);


--
-- Name: customer_credit_limits_id_seq; Type: SEQUENCE SET; Schema: clientes; Owner: -
--

SELECT pg_catalog.setval('clientes.customer_credit_limits_id_seq', 1, false);


--
-- Name: customer_discounts_id_seq; Type: SEQUENCE SET; Schema: clientes; Owner: -
--

SELECT pg_catalog.setval('clientes.customer_discounts_id_seq', 1, false);


--
-- Name: customer_documents_id_seq; Type: SEQUENCE SET; Schema: clientes; Owner: -
--

SELECT pg_catalog.setval('clientes.customer_documents_id_seq', 1, false);


--
-- Name: customer_groups_id_seq; Type: SEQUENCE SET; Schema: clientes; Owner: -
--

SELECT pg_catalog.setval('clientes.customer_groups_id_seq', 1, true);


--
-- Name: customer_history_id_seq; Type: SEQUENCE SET; Schema: clientes; Owner: -
--

SELECT pg_catalog.setval('clientes.customer_history_id_seq', 1, false);


--
-- Name: customer_notes_id_seq; Type: SEQUENCE SET; Schema: clientes; Owner: -
--

SELECT pg_catalog.setval('clientes.customer_notes_id_seq', 1, false);


--
-- Name: customer_payments_id_seq; Type: SEQUENCE SET; Schema: clientes; Owner: -
--

SELECT pg_catalog.setval('clientes.customer_payments_id_seq', 1, true);


--
-- Name: customer_tag_links_id_seq; Type: SEQUENCE SET; Schema: clientes; Owner: -
--

SELECT pg_catalog.setval('clientes.customer_tag_links_id_seq', 1, false);


--
-- Name: customer_tags_id_seq; Type: SEQUENCE SET; Schema: clientes; Owner: -
--

SELECT pg_catalog.setval('clientes.customer_tags_id_seq', 1, false);


--
-- Name: customers_id_seq; Type: SEQUENCE SET; Schema: clientes; Owner: -
--

SELECT pg_catalog.setval('clientes.customers_id_seq', 3, true);


--
-- Name: goods_receipt_items_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.goods_receipt_items_id_seq', 2, true);


--
-- Name: goods_receipts_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.goods_receipts_id_seq', 2, true);


--
-- Name: purchase_invoice_items_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.purchase_invoice_items_id_seq', 2, true);


--
-- Name: purchase_invoices_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.purchase_invoices_id_seq', 2, true);


--
-- Name: purchase_order_items_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.purchase_order_items_id_seq', 2, true);


--
-- Name: purchase_orders_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.purchase_orders_id_seq', 2, true);


--
-- Name: purchase_payment_items_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.purchase_payment_items_id_seq', 1, true);


--
-- Name: purchase_payments_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.purchase_payments_id_seq', 1, true);


--
-- Name: purchase_request_items_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.purchase_request_items_id_seq', 2, true);


--
-- Name: purchase_requests_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.purchase_requests_id_seq', 3, true);


--
-- Name: purchase_return_items_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.purchase_return_items_id_seq', 1, false);


--
-- Name: purchase_returns_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.purchase_returns_id_seq', 1, false);


--
-- Name: supplier_addresses_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.supplier_addresses_id_seq', 1, false);


--
-- Name: supplier_contacts_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.supplier_contacts_id_seq', 1, false);


--
-- Name: supplier_groups_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.supplier_groups_id_seq', 1, false);


--
-- Name: suppliers_id_seq; Type: SEQUENCE SET; Schema: compras; Owner: -
--

SELECT pg_catalog.setval('compras.suppliers_id_seq', 2, true);


--
-- Name: account_types_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.account_types_id_seq', 1, false);


--
-- Name: accounting_budgets_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.accounting_budgets_id_seq', 1, false);


--
-- Name: accounting_journals_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.accounting_journals_id_seq', 1, false);


--
-- Name: accounting_periods_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.accounting_periods_id_seq', 12, true);


--
-- Name: accounting_reports_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.accounting_reports_id_seq', 1, false);


--
-- Name: chart_of_accounts_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.chart_of_accounts_id_seq', 1, false);


--
-- Name: depreciation_entries_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.depreciation_entries_id_seq', 1, false);


--
-- Name: fiscal_years_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.fiscal_years_id_seq', 1, true);


--
-- Name: fixed_assets_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.fixed_assets_id_seq', 1, false);


--
-- Name: journal_entries_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.journal_entries_id_seq', 1, false);


--
-- Name: journal_entry_lines_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.journal_entry_lines_id_seq', 1, false);


--
-- Name: journal_entry_sequences_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.journal_entry_sequences_id_seq', 1, false);


--
-- Name: period_closing_checks_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.period_closing_checks_id_seq', 1, false);


--
-- Name: period_closings_id_seq; Type: SEQUENCE SET; Schema: contabilidade; Owner: -
--

SELECT pg_catalog.setval('contabilidade.period_closings_id_seq', 1, false);


--
-- Name: atividades_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: -
--

SELECT pg_catalog.setval('crm.atividades_id_seq', 2, true);


--
-- Name: crm_activities_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: -
--

SELECT pg_catalog.setval('crm.crm_activities_id_seq', 1, false);


--
-- Name: crm_lead_sources_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: -
--

SELECT pg_catalog.setval('crm.crm_lead_sources_id_seq', 1, false);


--
-- Name: crm_leads_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: -
--

SELECT pg_catalog.setval('crm.crm_leads_id_seq', 1, false);


--
-- Name: crm_opportunities_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: -
--

SELECT pg_catalog.setval('crm.crm_opportunities_id_seq', 1, false);


--
-- Name: crm_pipeline_stages_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: -
--

SELECT pg_catalog.setval('crm.crm_pipeline_stages_id_seq', 1, false);


--
-- Name: crm_pipelines_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: -
--

SELECT pg_catalog.setval('crm.crm_pipelines_id_seq', 1, false);


--
-- Name: leads_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: -
--

SELECT pg_catalog.setval('crm.leads_id_seq', 4, true);


--
-- Name: oportunidades_id_seq; Type: SEQUENCE SET; Schema: crm; Owner: -
--

SELECT pg_catalog.setval('crm.oportunidades_id_seq', 4, true);


--
-- Name: companies_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: -
--

SELECT pg_catalog.setval('empresa.companies_id_seq', 3, true);


--
-- Name: company_addresses_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: -
--

SELECT pg_catalog.setval('empresa.company_addresses_id_seq', 1, false);


--
-- Name: company_banks_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: -
--

SELECT pg_catalog.setval('empresa.company_banks_id_seq', 1, false);


--
-- Name: company_branches_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: -
--

SELECT pg_catalog.setval('empresa.company_branches_id_seq', 3, true);


--
-- Name: company_contacts_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: -
--

SELECT pg_catalog.setval('empresa.company_contacts_id_seq', 1, false);


--
-- Name: company_documents_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: -
--

SELECT pg_catalog.setval('empresa.company_documents_id_seq', 1, false);


--
-- Name: company_licenses_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: -
--

SELECT pg_catalog.setval('empresa.company_licenses_id_seq', 1, false);


--
-- Name: company_settings_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: -
--

SELECT pg_catalog.setval('empresa.company_settings_id_seq', 12, true);


--
-- Name: company_tax_info_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: -
--

SELECT pg_catalog.setval('empresa.company_tax_info_id_seq', 3, true);


--
-- Name: company_users_id_seq; Type: SEQUENCE SET; Schema: empresa; Owner: -
--

SELECT pg_catalog.setval('empresa.company_users_id_seq', 3, true);


--
-- Name: companies_id_seq; Type: SEQUENCE SET; Schema: empresas; Owner: -
--

SELECT pg_catalog.setval('empresas.companies_id_seq', 4, true);


--
-- Name: company_addresses_id_seq; Type: SEQUENCE SET; Schema: empresas; Owner: -
--

SELECT pg_catalog.setval('empresas.company_addresses_id_seq', 1, false);


--
-- Name: company_banks_id_seq; Type: SEQUENCE SET; Schema: empresas; Owner: -
--

SELECT pg_catalog.setval('empresas.company_banks_id_seq', 1, false);


--
-- Name: company_branches_id_seq; Type: SEQUENCE SET; Schema: empresas; Owner: -
--

SELECT pg_catalog.setval('empresas.company_branches_id_seq', 1, true);


--
-- Name: company_contacts_id_seq; Type: SEQUENCE SET; Schema: empresas; Owner: -
--

SELECT pg_catalog.setval('empresas.company_contacts_id_seq', 1, false);


--
-- Name: company_documents_id_seq; Type: SEQUENCE SET; Schema: empresas; Owner: -
--

SELECT pg_catalog.setval('empresas.company_documents_id_seq', 1, false);


--
-- Name: company_licenses_id_seq; Type: SEQUENCE SET; Schema: empresas; Owner: -
--

SELECT pg_catalog.setval('empresas.company_licenses_id_seq', 1, true);


--
-- Name: company_settings_id_seq; Type: SEQUENCE SET; Schema: empresas; Owner: -
--

SELECT pg_catalog.setval('empresas.company_settings_id_seq', 1, false);


--
-- Name: company_tax_info_id_seq; Type: SEQUENCE SET; Schema: empresas; Owner: -
--

SELECT pg_catalog.setval('empresas.company_tax_info_id_seq', 1, true);


--
-- Name: company_users_id_seq; Type: SEQUENCE SET; Schema: empresas; Owner: -
--

SELECT pg_catalog.setval('empresas.company_users_id_seq', 1, false);


--
-- Name: credit_note_items_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.credit_note_items_id_seq', 1, false);


--
-- Name: credit_notes_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.credit_notes_id_seq', 3, true);


--
-- Name: invoice_discounts_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.invoice_discounts_id_seq', 1, false);


--
-- Name: invoice_items_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.invoice_items_id_seq', 3, true);


--
-- Name: invoice_receipts_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.invoice_receipts_id_seq', 2, true);


--
-- Name: invoice_series_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.invoice_series_id_seq', 7, true);


--
-- Name: invoice_taxes_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.invoice_taxes_id_seq', 1, false);


--
-- Name: invoices_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.invoices_id_seq', 3, true);


--
-- Name: sales_deliveries_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.sales_deliveries_id_seq', 1, false);


--
-- Name: sales_delivery_items_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.sales_delivery_items_id_seq', 1, false);


--
-- Name: sales_order_items_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.sales_order_items_id_seq', 1, false);


--
-- Name: sales_orders_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.sales_orders_id_seq', 2, true);


--
-- Name: sales_quote_items_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.sales_quote_items_id_seq', 3, true);


--
-- Name: sales_quotes_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.sales_quotes_id_seq', 2, true);


--
-- Name: sales_return_items_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.sales_return_items_id_seq', 1, false);


--
-- Name: sales_returns_id_seq; Type: SEQUENCE SET; Schema: faturacao; Owner: -
--

SELECT pg_catalog.setval('faturacao.sales_returns_id_seq', 1, false);


--
-- Name: accounts_payable_id_seq; Type: SEQUENCE SET; Schema: financeiro; Owner: -
--

SELECT pg_catalog.setval('financeiro.accounts_payable_id_seq', 1, true);


--
-- Name: accounts_payable_payments_id_seq; Type: SEQUENCE SET; Schema: financeiro; Owner: -
--

SELECT pg_catalog.setval('financeiro.accounts_payable_payments_id_seq', 1, false);


--
-- Name: accounts_receivable_id_seq; Type: SEQUENCE SET; Schema: financeiro; Owner: -
--

SELECT pg_catalog.setval('financeiro.accounts_receivable_id_seq', 1, false);


--
-- Name: accounts_receivable_payments_id_seq; Type: SEQUENCE SET; Schema: financeiro; Owner: -
--

SELECT pg_catalog.setval('financeiro.accounts_receivable_payments_id_seq', 1, false);


--
-- Name: cash_flow_entries_id_seq; Type: SEQUENCE SET; Schema: financeiro; Owner: -
--

SELECT pg_catalog.setval('financeiro.cash_flow_entries_id_seq', 1, false);


--
-- Name: financial_budgets_id_seq; Type: SEQUENCE SET; Schema: financeiro; Owner: -
--

SELECT pg_catalog.setval('financeiro.financial_budgets_id_seq', 1, false);


--
-- Name: financial_categories_id_seq; Type: SEQUENCE SET; Schema: financeiro; Owner: -
--

SELECT pg_catalog.setval('financeiro.financial_categories_id_seq', 1, false);


--
-- Name: payment_methods_id_seq; Type: SEQUENCE SET; Schema: financeiro; Owner: -
--

SELECT pg_catalog.setval('financeiro.payment_methods_id_seq', 1, false);


--
-- Name: payments_id_seq; Type: SEQUENCE SET; Schema: financeiro; Owner: -
--

SELECT pg_catalog.setval('financeiro.payments_id_seq', 1, false);


--
-- Name: school_attendance_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_attendance_id_seq', 1, false);


--
-- Name: school_books_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_books_id_seq', 1, false);


--
-- Name: school_classes_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_classes_id_seq', 1, false);


--
-- Name: school_enrollments_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_enrollments_id_seq', 1, false);


--
-- Name: school_fee_plans_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_fee_plans_id_seq', 1, false);


--
-- Name: school_fees_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_fees_id_seq', 1, false);


--
-- Name: school_grade_items_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_grade_items_id_seq', 1, false);


--
-- Name: school_grades_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_grades_id_seq', 1, false);


--
-- Name: school_guardians_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_guardians_id_seq', 1, false);


--
-- Name: school_library_loans_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_library_loans_id_seq', 1, false);


--
-- Name: school_messages_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_messages_id_seq', 1, false);


--
-- Name: school_payments_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_payments_id_seq', 1, false);


--
-- Name: school_student_roles_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_student_roles_id_seq', 1, false);


--
-- Name: school_students_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_students_id_seq', 1, false);


--
-- Name: school_subjects_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_subjects_id_seq', 1, false);


--
-- Name: school_teacher_assignments_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_teacher_assignments_id_seq', 1, false);


--
-- Name: school_teacher_roles_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_teacher_roles_id_seq', 1, false);


--
-- Name: school_terms_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_terms_id_seq', 1, false);


--
-- Name: school_years_id_seq; Type: SEQUENCE SET; Schema: gestao_escolar; Owner: -
--

SELECT pg_catalog.setval('gestao_escolar.school_years_id_seq', 1, false);


--
-- Name: tax_certificates_id_seq; Type: SEQUENCE SET; Schema: impostos; Owner: -
--

SELECT pg_catalog.setval('impostos.tax_certificates_id_seq', 1, false);


--
-- Name: tax_exemptions_id_seq; Type: SEQUENCE SET; Schema: impostos; Owner: -
--

SELECT pg_catalog.setval('impostos.tax_exemptions_id_seq', 1, true);


--
-- Name: tax_groups_id_seq; Type: SEQUENCE SET; Schema: impostos; Owner: -
--

SELECT pg_catalog.setval('impostos.tax_groups_id_seq', 1, false);


--
-- Name: tax_regimes_id_seq; Type: SEQUENCE SET; Schema: impostos; Owner: -
--

SELECT pg_catalog.setval('impostos.tax_regimes_id_seq', 1, false);


--
-- Name: tax_return_lines_id_seq; Type: SEQUENCE SET; Schema: impostos; Owner: -
--

SELECT pg_catalog.setval('impostos.tax_return_lines_id_seq', 1, true);


--
-- Name: tax_returns_id_seq; Type: SEQUENCE SET; Schema: impostos; Owner: -
--

SELECT pg_catalog.setval('impostos.tax_returns_id_seq', 2, true);


--
-- Name: tax_rules_id_seq; Type: SEQUENCE SET; Schema: impostos; Owner: -
--

SELECT pg_catalog.setval('impostos.tax_rules_id_seq', 1, false);


--
-- Name: tax_transactions_id_seq; Type: SEQUENCE SET; Schema: impostos; Owner: -
--

SELECT pg_catalog.setval('impostos.tax_transactions_id_seq', 1, false);


--
-- Name: taxes_id_seq; Type: SEQUENCE SET; Schema: impostos; Owner: -
--

SELECT pg_catalog.setval('impostos.taxes_id_seq', 1, true);


--
-- Name: withholding_tax_transactions_id_seq; Type: SEQUENCE SET; Schema: impostos; Owner: -
--

SELECT pg_catalog.setval('impostos.withholding_tax_transactions_id_seq', 1, false);


--
-- Name: withholding_taxes_id_seq; Type: SEQUENCE SET; Schema: impostos; Owner: -
--

SELECT pg_catalog.setval('impostos.withholding_taxes_id_seq', 1, false);


--
-- Name: delivery_drivers_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: -
--

SELECT pg_catalog.setval('logistica.delivery_drivers_id_seq', 1, false);


--
-- Name: delivery_routes_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: -
--

SELECT pg_catalog.setval('logistica.delivery_routes_id_seq', 1, false);


--
-- Name: delivery_statuses_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: -
--

SELECT pg_catalog.setval('logistica.delivery_statuses_id_seq', 1, true);


--
-- Name: delivery_tracking_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: -
--

SELECT pg_catalog.setval('logistica.delivery_tracking_id_seq', 1, true);


--
-- Name: delivery_vehicles_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: -
--

SELECT pg_catalog.setval('logistica.delivery_vehicles_id_seq', 1, false);


--
-- Name: logistics_drivers_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: -
--

SELECT pg_catalog.setval('logistica.logistics_drivers_id_seq', 1, false);


--
-- Name: logistics_routes_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: -
--

SELECT pg_catalog.setval('logistica.logistics_routes_id_seq', 1, false);


--
-- Name: logistics_shipments_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: -
--

SELECT pg_catalog.setval('logistica.logistics_shipments_id_seq', 1, false);


--
-- Name: logistics_tracking_events_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: -
--

SELECT pg_catalog.setval('logistica.logistics_tracking_events_id_seq', 1, false);


--
-- Name: logistics_vehicles_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: -
--

SELECT pg_catalog.setval('logistica.logistics_vehicles_id_seq', 1, false);


--
-- Name: shipment_items_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: -
--

SELECT pg_catalog.setval('logistica.shipment_items_id_seq', 1, true);


--
-- Name: shipments_id_seq; Type: SEQUENCE SET; Schema: logistica; Owner: -
--

SELECT pg_catalog.setval('logistica.shipments_id_seq', 1, true);


--
-- Name: currencies_id_seq; Type: SEQUENCE SET; Schema: multi_moeda; Owner: -
--

SELECT pg_catalog.setval('multi_moeda.currencies_id_seq', 8, true);


--
-- Name: exchange_rates_id_seq; Type: SEQUENCE SET; Schema: multi_moeda; Owner: -
--

SELECT pg_catalog.setval('multi_moeda.exchange_rates_id_seq', 18, true);


--
-- Name: tenant_currencies_id_seq; Type: SEQUENCE SET; Schema: multi_moeda; Owner: -
--

SELECT pg_catalog.setval('multi_moeda.tenant_currencies_id_seq', 12, true);


--
-- Name: notification_channels_id_seq; Type: SEQUENCE SET; Schema: notifications; Owner: -
--

SELECT pg_catalog.setval('notifications.notification_channels_id_seq', 2, true);


--
-- Name: notification_messages_id_seq; Type: SEQUENCE SET; Schema: notifications; Owner: -
--

SELECT pg_catalog.setval('notifications.notification_messages_id_seq', 1, false);


--
-- Name: notification_templates_id_seq; Type: SEQUENCE SET; Schema: notifications; Owner: -
--

SELECT pg_catalog.setval('notifications.notification_templates_id_seq', 3, true);


--
-- Name: pos_catalog_items_id_seq; Type: SEQUENCE SET; Schema: pos; Owner: -
--

SELECT pg_catalog.setval('pos.pos_catalog_items_id_seq', 1, true);


--
-- Name: pos_sale_items_id_seq; Type: SEQUENCE SET; Schema: pos; Owner: -
--

SELECT pg_catalog.setval('pos.pos_sale_items_id_seq', 4, true);


--
-- Name: pos_sale_payments_id_seq; Type: SEQUENCE SET; Schema: pos; Owner: -
--

SELECT pg_catalog.setval('pos.pos_sale_payments_id_seq', 3, true);


--
-- Name: pos_sales_id_seq; Type: SEQUENCE SET; Schema: pos; Owner: -
--

SELECT pg_catalog.setval('pos.pos_sales_id_seq', 4, true);


--
-- Name: pos_sessions_id_seq; Type: SEQUENCE SET; Schema: pos; Owner: -
--

SELECT pg_catalog.setval('pos.pos_sessions_id_seq', 5, true);


--
-- Name: pos_terminals_id_seq; Type: SEQUENCE SET; Schema: pos; Owner: -
--

SELECT pg_catalog.setval('pos.pos_terminals_id_seq', 1, true);


--
-- Name: product_attribute_values_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_attribute_values_id_seq', 1, false);


--
-- Name: product_attributes_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_attributes_id_seq', 1, false);


--
-- Name: product_barcodes_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_barcodes_id_seq', 1, false);


--
-- Name: product_brands_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_brands_id_seq', 1, false);


--
-- Name: product_categories_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_categories_id_seq', 1, true);


--
-- Name: product_discounts_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_discounts_id_seq', 1, false);


--
-- Name: product_images_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_images_id_seq', 1, false);


--
-- Name: product_kit_items_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_kit_items_id_seq', 1, false);


--
-- Name: product_kits_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_kits_id_seq', 1, false);


--
-- Name: product_prices_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_prices_id_seq', 1, true);


--
-- Name: product_subcategories_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_subcategories_id_seq', 1, false);


--
-- Name: product_tag_links_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_tag_links_id_seq', 1, false);


--
-- Name: product_tags_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_tags_id_seq', 1, false);


--
-- Name: product_units_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_units_id_seq', 1, false);


--
-- Name: product_variants_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.product_variants_id_seq', 1, false);


--
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.products_id_seq', 1, true);


--
-- Name: warehouses_id_seq; Type: SEQUENCE SET; Schema: produtos; Owner: -
--

SELECT pg_catalog.setval('produtos.warehouses_id_seq', 1, true);


--
-- Name: chat_conversas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.chat_conversas_id_seq', 8, true);


--
-- Name: chat_mensagens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.chat_mensagens_id_seq', 19, true);


--
-- Name: comunicados_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.comunicados_id_seq', 1, false);


--
-- Name: notif_colaborador_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notif_colaborador_id_seq', 1, false);


--
-- Name: candidatura_notas_id_seq; Type: SEQUENCE SET; Schema: recrutamento; Owner: -
--

SELECT pg_catalog.setval('recrutamento.candidatura_notas_id_seq', 13, true);


--
-- Name: candidaturas_id_seq; Type: SEQUENCE SET; Schema: recrutamento; Owner: -
--

SELECT pg_catalog.setval('recrutamento.candidaturas_id_seq', 6, true);


--
-- Name: contactos_id_seq; Type: SEQUENCE SET; Schema: recrutamento; Owner: -
--

SELECT pg_catalog.setval('recrutamento.contactos_id_seq', 12, true);


--
-- Name: vagas_id_seq; Type: SEQUENCE SET; Schema: recrutamento; Owner: -
--

SELECT pg_catalog.setval('recrutamento.vagas_id_seq', 6, true);


--
-- Name: employee_bank_accounts_id_seq; Type: SEQUENCE SET; Schema: recursos_humanos; Owner: -
--

SELECT pg_catalog.setval('recursos_humanos.employee_bank_accounts_id_seq', 1, false);


--
-- Name: employees_id_seq; Type: SEQUENCE SET; Schema: recursos_humanos; Owner: -
--

SELECT pg_catalog.setval('recursos_humanos.employees_id_seq', 1, false);


--
-- Name: hr_departments_id_seq; Type: SEQUENCE SET; Schema: recursos_humanos; Owner: -
--

SELECT pg_catalog.setval('recursos_humanos.hr_departments_id_seq', 1, false);


--
-- Name: payroll_periods_id_seq; Type: SEQUENCE SET; Schema: recursos_humanos; Owner: -
--

SELECT pg_catalog.setval('recursos_humanos.payroll_periods_id_seq', 1, false);


--
-- Name: payroll_run_lines_id_seq; Type: SEQUENCE SET; Schema: recursos_humanos; Owner: -
--

SELECT pg_catalog.setval('recursos_humanos.payroll_run_lines_id_seq', 1, false);


--
-- Name: payroll_runs_id_seq; Type: SEQUENCE SET; Schema: recursos_humanos; Owner: -
--

SELECT pg_catalog.setval('recursos_humanos.payroll_runs_id_seq', 1, false);


--
-- Name: ausencias_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.ausencias_id_seq', 3, true);


--
-- Name: avaliacao_criterios_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.avaliacao_criterios_id_seq', 1, false);


--
-- Name: avaliacoes_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.avaliacoes_id_seq', 1, false);


--
-- Name: beneficios_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.beneficios_id_seq', 1, false);


--
-- Name: cargos_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.cargos_id_seq', 1, false);


--
-- Name: componentes_salariais_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.componentes_salariais_id_seq', 1, false);


--
-- Name: contactos_emergencia_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.contactos_emergencia_id_seq', 1, false);


--
-- Name: contratos_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.contratos_id_seq', 1, false);


--
-- Name: criterios_avaliacao_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.criterios_avaliacao_id_seq', 1, false);


--
-- Name: departamentos_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.departamentos_id_seq', 1, false);


--
-- Name: documentos_funcionario_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.documentos_funcionario_id_seq', 1, false);


--
-- Name: folhas_pagamento_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.folhas_pagamento_id_seq', 1, false);


--
-- Name: formacoes_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.formacoes_id_seq', 1, false);


--
-- Name: funcionario_beneficios_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.funcionario_beneficios_id_seq', 1, false);


--
-- Name: funcionario_componentes_salariais_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.funcionario_componentes_salariais_id_seq', 1, false);


--
-- Name: funcionario_formacoes_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.funcionario_formacoes_id_seq', 1, false);


--
-- Name: funcionarios_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.funcionarios_id_seq', 1, true);


--
-- Name: historico_salarial_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.historico_salarial_id_seq', 1, false);


--
-- Name: horarios_trabalho_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.horarios_trabalho_id_seq', 1, false);


--
-- Name: justificacoes_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.justificacoes_id_seq', 2, true);


--
-- Name: periodos_avaliacao_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.periodos_avaliacao_id_seq', 1, false);


--
-- Name: presencas_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.presencas_id_seq', 1, false);


--
-- Name: processos_disciplinares_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.processos_disciplinares_id_seq', 1, false);


--
-- Name: recibo_vencimento_itens_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.recibo_vencimento_itens_id_seq', 1, false);


--
-- Name: recibos_vencimento_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.recibos_vencimento_id_seq', 1, false);


--
-- Name: saldos_ausencia_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.saldos_ausencia_id_seq', 1, true);


--
-- Name: tipos_ausencia_id_seq; Type: SEQUENCE SET; Schema: rh; Owner: -
--

SELECT pg_catalog.setval('rh.tipos_ausencia_id_seq', 1, true);


--
-- Name: security_ip_allowlist_id_seq; Type: SEQUENCE SET; Schema: seguranca; Owner: -
--

SELECT pg_catalog.setval('seguranca.security_ip_allowlist_id_seq', 1, false);


--
-- Name: security_mfa_enrollments_id_seq; Type: SEQUENCE SET; Schema: seguranca; Owner: -
--

SELECT pg_catalog.setval('seguranca.security_mfa_enrollments_id_seq', 1, false);


--
-- Name: security_policies_id_seq; Type: SEQUENCE SET; Schema: seguranca; Owner: -
--

SELECT pg_catalog.setval('seguranca.security_policies_id_seq', 1, false);


--
-- Name: api_logs_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.api_logs_id_seq', 1, false);


--
-- Name: cities_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.cities_id_seq', 1, true);


--
-- Name: countries_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.countries_id_seq', 2, true);


--
-- Name: currencies_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.currencies_id_seq', 2, true);


--
-- Name: email_templates_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.email_templates_id_seq', 1, false);


--
-- Name: exchange_rates_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.exchange_rates_id_seq', 1, true);


--
-- Name: integrations_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.integrations_id_seq', 1, false);


--
-- Name: languages_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.languages_id_seq', 1, false);


--
-- Name: settings_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.settings_id_seq', 1, true);


--
-- Name: sms_templates_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.sms_templates_id_seq', 1, false);


--
-- Name: system_logs_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.system_logs_id_seq', 1, false);


--
-- Name: tenant_branding_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.tenant_branding_id_seq', 1, false);


--
-- Name: tenant_defaults_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.tenant_defaults_id_seq', 6, true);


--
-- Name: tenant_document_settings_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.tenant_document_settings_id_seq', 1, false);


--
-- Name: tenant_feature_flags_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.tenant_feature_flags_id_seq', 1, false);


--
-- Name: tenant_integrations_id_seq; Type: SEQUENCE SET; Schema: sistema_configuracao; Owner: -
--

SELECT pg_catalog.setval('sistema_configuracao.tenant_integrations_id_seq', 1, false);


--
-- Name: stock_adjustments_id_seq; Type: SEQUENCE SET; Schema: stock; Owner: -
--

SELECT pg_catalog.setval('stock.stock_adjustments_id_seq', 1, false);


--
-- Name: stock_alerts_id_seq; Type: SEQUENCE SET; Schema: stock; Owner: -
--

SELECT pg_catalog.setval('stock.stock_alerts_id_seq', 1, false);


--
-- Name: stock_batches_id_seq; Type: SEQUENCE SET; Schema: stock; Owner: -
--

SELECT pg_catalog.setval('stock.stock_batches_id_seq', 1, false);


--
-- Name: stock_count_items_id_seq; Type: SEQUENCE SET; Schema: stock; Owner: -
--

SELECT pg_catalog.setval('stock.stock_count_items_id_seq', 1, false);


--
-- Name: stock_counts_id_seq; Type: SEQUENCE SET; Schema: stock; Owner: -
--

SELECT pg_catalog.setval('stock.stock_counts_id_seq', 1, false);


--
-- Name: stock_items_id_seq; Type: SEQUENCE SET; Schema: stock; Owner: -
--

SELECT pg_catalog.setval('stock.stock_items_id_seq', 5, true);


--
-- Name: stock_logs_id_seq; Type: SEQUENCE SET; Schema: stock; Owner: -
--

SELECT pg_catalog.setval('stock.stock_logs_id_seq', 1, false);


--
-- Name: stock_movements_id_seq; Type: SEQUENCE SET; Schema: stock; Owner: -
--

SELECT pg_catalog.setval('stock.stock_movements_id_seq', 10, true);


--
-- Name: stock_reservations_id_seq; Type: SEQUENCE SET; Schema: stock; Owner: -
--

SELECT pg_catalog.setval('stock.stock_reservations_id_seq', 2, true);


--
-- Name: stock_serial_numbers_id_seq; Type: SEQUENCE SET; Schema: stock; Owner: -
--

SELECT pg_catalog.setval('stock.stock_serial_numbers_id_seq', 1, false);


--
-- Name: stock_transfer_items_id_seq; Type: SEQUENCE SET; Schema: stock; Owner: -
--

SELECT pg_catalog.setval('stock.stock_transfer_items_id_seq', 1, false);


--
-- Name: stock_transfers_id_seq; Type: SEQUENCE SET; Schema: stock; Owner: -
--

SELECT pg_catalog.setval('stock.stock_transfers_id_seq', 1, false);


--
-- Name: warehouse_locations_id_seq; Type: SEQUENCE SET; Schema: stock; Owner: -
--

SELECT pg_catalog.setval('stock.warehouse_locations_id_seq', 1, false);


--
-- Name: bank_accounts_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: -
--

SELECT pg_catalog.setval('tesouraria.bank_accounts_id_seq', 2, true);


--
-- Name: caixas_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: -
--

SELECT pg_catalog.setval('tesouraria.caixas_id_seq', 1, false);


--
-- Name: cash_registers_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: -
--

SELECT pg_catalog.setval('tesouraria.cash_registers_id_seq', 1, false);


--
-- Name: contas_bancarias_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: -
--

SELECT pg_catalog.setval('tesouraria.contas_bancarias_id_seq', 1, false);


--
-- Name: movements_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: -
--

SELECT pg_catalog.setval('tesouraria.movements_id_seq', 2, true);


--
-- Name: movimentos_financeiros_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: -
--

SELECT pg_catalog.setval('tesouraria.movimentos_financeiros_id_seq', 1, false);


--
-- Name: reconciliacoes_bancarias_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: -
--

SELECT pg_catalog.setval('tesouraria.reconciliacoes_bancarias_id_seq', 1, false);


--
-- Name: reconciliations_id_seq; Type: SEQUENCE SET; Schema: tesouraria; Owner: -
--

SELECT pg_catalog.setval('tesouraria.reconciliations_id_seq', 1, true);


--
-- Name: profiles_id_seq; Type: SEQUENCE SET; Schema: utilizadores; Owner: -
--

SELECT pg_catalog.setval('utilizadores.profiles_id_seq', 1, true);


--
-- Name: user_activity_id_seq; Type: SEQUENCE SET; Schema: utilizadores; Owner: -
--

SELECT pg_catalog.setval('utilizadores.user_activity_id_seq', 1, false);


--
-- Name: user_avatar_id_seq; Type: SEQUENCE SET; Schema: utilizadores; Owner: -
--

SELECT pg_catalog.setval('utilizadores.user_avatar_id_seq', 1, false);


--
-- Name: user_devices_id_seq; Type: SEQUENCE SET; Schema: utilizadores; Owner: -
--

SELECT pg_catalog.setval('utilizadores.user_devices_id_seq', 1, true);


--
-- Name: user_notifications_id_seq; Type: SEQUENCE SET; Schema: utilizadores; Owner: -
--

SELECT pg_catalog.setval('utilizadores.user_notifications_id_seq', 1, true);


--
-- Name: user_preferences_id_seq; Type: SEQUENCE SET; Schema: utilizadores; Owner: -
--

SELECT pg_catalog.setval('utilizadores.user_preferences_id_seq', 1, true);


--
-- Name: user_security_logs_id_seq; Type: SEQUENCE SET; Schema: utilizadores; Owner: -
--

SELECT pg_catalog.setval('utilizadores.user_security_logs_id_seq', 1, false);


--
-- Name: user_settings_id_seq; Type: SEQUENCE SET; Schema: utilizadores; Owner: -
--

SELECT pg_catalog.setval('utilizadores.user_settings_id_seq', 1, false);


--
-- Name: user_tokens_id_seq; Type: SEQUENCE SET; Schema: utilizadores; Owner: -
--

SELECT pg_catalog.setval('utilizadores.user_tokens_id_seq', 1, false);


--
-- Name: subscription_invoices subscription_invoices_pkey; Type: CONSTRAINT; Schema: assinaturas; Owner: -
--

ALTER TABLE ONLY assinaturas.subscription_invoices
    ADD CONSTRAINT subscription_invoices_pkey PRIMARY KEY (id);


--
-- Name: subscription_plans subscription_plans_pkey; Type: CONSTRAINT; Schema: assinaturas; Owner: -
--

ALTER TABLE ONLY assinaturas.subscription_plans
    ADD CONSTRAINT subscription_plans_pkey PRIMARY KEY (id);


--
-- Name: subscription_usage subscription_usage_pkey; Type: CONSTRAINT; Schema: assinaturas; Owner: -
--

ALTER TABLE ONLY assinaturas.subscription_usage
    ADD CONSTRAINT subscription_usage_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: assinaturas; Owner: -
--

ALTER TABLE ONLY assinaturas.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: subscription_invoices uq_subscription_invoices; Type: CONSTRAINT; Schema: assinaturas; Owner: -
--

ALTER TABLE ONLY assinaturas.subscription_invoices
    ADD CONSTRAINT uq_subscription_invoices UNIQUE (tenant_id, numero);


--
-- Name: subscription_plans uq_subscription_plans; Type: CONSTRAINT; Schema: assinaturas; Owner: -
--

ALTER TABLE ONLY assinaturas.subscription_plans
    ADD CONSTRAINT uq_subscription_plans UNIQUE (tenant_id, codigo);


--
-- Name: subscriptions uq_subscriptions; Type: CONSTRAINT; Schema: assinaturas; Owner: -
--

ALTER TABLE ONLY assinaturas.subscriptions
    ADD CONSTRAINT uq_subscriptions UNIQUE (tenant_id, numero);


--
-- Name: audit_events audit_events_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: -
--

ALTER TABLE ONLY auditoria.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: -
--

ALTER TABLE ONLY auditoria.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: api_keys api_keys_key_hash_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.api_keys
    ADD CONSTRAINT api_keys_key_hash_key UNIQUE (key_hash);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: cargos cargos_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.cargos
    ADD CONSTRAINT cargos_pkey PRIMARY KEY (id);


--
-- Name: cargos cargos_tenant_id_nome_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.cargos
    ADD CONSTRAINT cargos_tenant_id_nome_key UNIQUE (tenant_id, nome);


--
-- Name: email_verifications email_verifications_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.email_verifications
    ADD CONSTRAINT email_verifications_pkey PRIMARY KEY (id);


--
-- Name: email_verifications email_verifications_token_hash_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.email_verifications
    ADD CONSTRAINT email_verifications_token_hash_key UNIQUE (token_hash);


--
-- Name: login_history login_history_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.login_history
    ADD CONSTRAINT login_history_pkey PRIMARY KEY (id);


--
-- Name: password_resets password_resets_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.password_resets
    ADD CONSTRAINT password_resets_pkey PRIMARY KEY (id);


--
-- Name: password_resets password_resets_token_hash_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.password_resets
    ADD CONSTRAINT password_resets_token_hash_key UNIQUE (token_hash);


--
-- Name: permissoes_cargo permissoes_cargo_cargo_id_modulo_acao_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.permissoes_cargo
    ADD CONSTRAINT permissoes_cargo_cargo_id_modulo_acao_key UNIQUE (cargo_id, modulo, acao);


--
-- Name: permissoes_cargo permissoes_cargo_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.permissoes_cargo
    ADD CONSTRAINT permissoes_cargo_pkey PRIMARY KEY (id);


--
-- Name: permissoes_diretas permissoes_diretas_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.permissoes_diretas
    ADD CONSTRAINT permissoes_diretas_pkey PRIMARY KEY (id);


--
-- Name: permissoes_diretas permissoes_diretas_user_id_modulo_acao_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.permissoes_diretas
    ADD CONSTRAINT permissoes_diretas_user_id_modulo_acao_key UNIQUE (user_id, modulo, acao);


--
-- Name: permissoes_tipo permissoes_tipo_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.permissoes_tipo
    ADD CONSTRAINT permissoes_tipo_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_token_hash_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_token_hash_key UNIQUE (token_hash);


--
-- Name: permissoes_tipo uq_permissoes_tipo; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.permissoes_tipo
    ADD CONSTRAINT uq_permissoes_tipo UNIQUE (tipo, modulo, acao);


--
-- Name: users uq_users_email; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT uq_users_email UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: autorizacao; Owner: -
--

ALTER TABLE ONLY autorizacao.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: autorizacao; Owner: -
--

ALTER TABLE ONLY autorizacao.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: autorizacao; Owner: -
--

ALTER TABLE ONLY autorizacao.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: permissions uq_permissions_codigo; Type: CONSTRAINT; Schema: autorizacao; Owner: -
--

ALTER TABLE ONLY autorizacao.permissions
    ADD CONSTRAINT uq_permissions_codigo UNIQUE (codigo);


--
-- Name: role_permissions uq_role_permissions; Type: CONSTRAINT; Schema: autorizacao; Owner: -
--

ALTER TABLE ONLY autorizacao.role_permissions
    ADD CONSTRAINT uq_role_permissions UNIQUE (role_id, permission_id);


--
-- Name: roles uq_roles_tenant_codigo; Type: CONSTRAINT; Schema: autorizacao; Owner: -
--

ALTER TABLE ONLY autorizacao.roles
    ADD CONSTRAINT uq_roles_tenant_codigo UNIQUE (tenant_id, codigo);


--
-- Name: user_roles uq_user_roles; Type: CONSTRAINT; Schema: autorizacao; Owner: -
--

ALTER TABLE ONLY autorizacao.user_roles
    ADD CONSTRAINT uq_user_roles UNIQUE (user_id, role_id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: autorizacao; Owner: -
--

ALTER TABLE ONLY autorizacao.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: cost_center_allocations cost_center_allocations_pkey; Type: CONSTRAINT; Schema: centros_custo; Owner: -
--

ALTER TABLE ONLY centros_custo.cost_center_allocations
    ADD CONSTRAINT cost_center_allocations_pkey PRIMARY KEY (id);


--
-- Name: cost_center_budgets cost_center_budgets_pkey; Type: CONSTRAINT; Schema: centros_custo; Owner: -
--

ALTER TABLE ONLY centros_custo.cost_center_budgets
    ADD CONSTRAINT cost_center_budgets_pkey PRIMARY KEY (id);


--
-- Name: cost_centers cost_centers_pkey; Type: CONSTRAINT; Schema: centros_custo; Owner: -
--

ALTER TABLE ONLY centros_custo.cost_centers
    ADD CONSTRAINT cost_centers_pkey PRIMARY KEY (id);


--
-- Name: cost_center_budgets uq_cost_center_budgets; Type: CONSTRAINT; Schema: centros_custo; Owner: -
--

ALTER TABLE ONLY centros_custo.cost_center_budgets
    ADD CONSTRAINT uq_cost_center_budgets UNIQUE (tenant_id, cost_center_id, ano, mes);


--
-- Name: cost_centers uq_cost_centers; Type: CONSTRAINT; Schema: centros_custo; Owner: -
--

ALTER TABLE ONLY centros_custo.cost_centers
    ADD CONSTRAINT uq_cost_centers UNIQUE (tenant_id, codigo);


--
-- Name: customer_addresses customer_addresses_pkey; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_addresses
    ADD CONSTRAINT customer_addresses_pkey PRIMARY KEY (id);


--
-- Name: customer_balances customer_balances_pkey; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_balances
    ADD CONSTRAINT customer_balances_pkey PRIMARY KEY (id);


--
-- Name: customer_contacts customer_contacts_pkey; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_contacts
    ADD CONSTRAINT customer_contacts_pkey PRIMARY KEY (id);


--
-- Name: customer_credit_limits customer_credit_limits_pkey; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_credit_limits
    ADD CONSTRAINT customer_credit_limits_pkey PRIMARY KEY (id);


--
-- Name: customer_discounts customer_discounts_pkey; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_discounts
    ADD CONSTRAINT customer_discounts_pkey PRIMARY KEY (id);


--
-- Name: customer_documents customer_documents_pkey; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_documents
    ADD CONSTRAINT customer_documents_pkey PRIMARY KEY (id);


--
-- Name: customer_groups customer_groups_pkey; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_groups
    ADD CONSTRAINT customer_groups_pkey PRIMARY KEY (id);


--
-- Name: customer_history customer_history_pkey; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_history
    ADD CONSTRAINT customer_history_pkey PRIMARY KEY (id);


--
-- Name: customer_notes customer_notes_pkey; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_notes
    ADD CONSTRAINT customer_notes_pkey PRIMARY KEY (id);


--
-- Name: customer_payments customer_payments_pkey; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_payments
    ADD CONSTRAINT customer_payments_pkey PRIMARY KEY (id);


--
-- Name: customer_tag_links customer_tag_links_pkey; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_tag_links
    ADD CONSTRAINT customer_tag_links_pkey PRIMARY KEY (id);


--
-- Name: customer_tags customer_tags_pkey; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_tags
    ADD CONSTRAINT customer_tags_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: customer_balances uq_customer_balances_customer; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_balances
    ADD CONSTRAINT uq_customer_balances_customer UNIQUE (customer_id);


--
-- Name: customer_credit_limits uq_customer_credit_limits_customer; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_credit_limits
    ADD CONSTRAINT uq_customer_credit_limits_customer UNIQUE (customer_id);


--
-- Name: customer_groups uq_customer_groups; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_groups
    ADD CONSTRAINT uq_customer_groups UNIQUE (tenant_id, codigo);


--
-- Name: customer_tag_links uq_customer_tag_links; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_tag_links
    ADD CONSTRAINT uq_customer_tag_links UNIQUE (customer_id, customer_tag_id);


--
-- Name: customer_tags uq_customer_tags; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_tags
    ADD CONSTRAINT uq_customer_tags UNIQUE (tenant_id, codigo);


--
-- Name: customers uq_customers_tenant_codigo; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customers
    ADD CONSTRAINT uq_customers_tenant_codigo UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);


--
-- Name: customers uq_customers_tenant_nuit; Type: CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customers
    ADD CONSTRAINT uq_customers_tenant_nuit UNIQUE NULLS NOT DISTINCT (tenant_id, nuit);


--
-- Name: goods_receipt_items goods_receipt_items_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.goods_receipt_items
    ADD CONSTRAINT goods_receipt_items_pkey PRIMARY KEY (id);


--
-- Name: goods_receipts goods_receipts_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.goods_receipts
    ADD CONSTRAINT goods_receipts_pkey PRIMARY KEY (id);


--
-- Name: purchase_invoice_items purchase_invoice_items_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_invoice_items
    ADD CONSTRAINT purchase_invoice_items_pkey PRIMARY KEY (id);


--
-- Name: purchase_invoices purchase_invoices_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_invoices
    ADD CONSTRAINT purchase_invoices_pkey PRIMARY KEY (id);


--
-- Name: purchase_invoices purchase_invoices_tenant_id_numero_key; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_invoices
    ADD CONSTRAINT purchase_invoices_tenant_id_numero_key UNIQUE (tenant_id, numero);


--
-- Name: purchase_invoices purchase_invoices_tenant_id_supplier_id_supplier_invoice_nu_key; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_invoices
    ADD CONSTRAINT purchase_invoices_tenant_id_supplier_id_supplier_invoice_nu_key UNIQUE NULLS NOT DISTINCT (tenant_id, supplier_id, supplier_invoice_number);


--
-- Name: purchase_order_items purchase_order_items_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_order_items
    ADD CONSTRAINT purchase_order_items_pkey PRIMARY KEY (id);


--
-- Name: purchase_orders purchase_orders_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (id);


--
-- Name: purchase_payment_items purchase_payment_items_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_payment_items
    ADD CONSTRAINT purchase_payment_items_pkey PRIMARY KEY (id);


--
-- Name: purchase_payment_items purchase_payment_items_purchase_payment_id_purchase_invoice_key; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_payment_items
    ADD CONSTRAINT purchase_payment_items_purchase_payment_id_purchase_invoice_key UNIQUE (purchase_payment_id, purchase_invoice_id);


--
-- Name: purchase_payments purchase_payments_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_payments
    ADD CONSTRAINT purchase_payments_pkey PRIMARY KEY (id);


--
-- Name: purchase_payments purchase_payments_tenant_id_numero_key; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_payments
    ADD CONSTRAINT purchase_payments_tenant_id_numero_key UNIQUE (tenant_id, numero);


--
-- Name: purchase_request_items purchase_request_items_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_request_items
    ADD CONSTRAINT purchase_request_items_pkey PRIMARY KEY (id);


--
-- Name: purchase_requests purchase_requests_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_requests
    ADD CONSTRAINT purchase_requests_pkey PRIMARY KEY (id);


--
-- Name: purchase_requests purchase_requests_tenant_id_numero_key; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_requests
    ADD CONSTRAINT purchase_requests_tenant_id_numero_key UNIQUE (tenant_id, numero);


--
-- Name: purchase_return_items purchase_return_items_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_return_items
    ADD CONSTRAINT purchase_return_items_pkey PRIMARY KEY (id);


--
-- Name: purchase_returns purchase_returns_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_returns
    ADD CONSTRAINT purchase_returns_pkey PRIMARY KEY (id);


--
-- Name: supplier_addresses supplier_addresses_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.supplier_addresses
    ADD CONSTRAINT supplier_addresses_pkey PRIMARY KEY (id);


--
-- Name: supplier_contacts supplier_contacts_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.supplier_contacts
    ADD CONSTRAINT supplier_contacts_pkey PRIMARY KEY (id);


--
-- Name: supplier_groups supplier_groups_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.supplier_groups
    ADD CONSTRAINT supplier_groups_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: goods_receipts uq_goods_receipts; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.goods_receipts
    ADD CONSTRAINT uq_goods_receipts UNIQUE (tenant_id, numero);


--
-- Name: purchase_orders uq_purchase_orders; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_orders
    ADD CONSTRAINT uq_purchase_orders UNIQUE (tenant_id, numero);


--
-- Name: purchase_returns uq_purchase_returns; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_returns
    ADD CONSTRAINT uq_purchase_returns UNIQUE (tenant_id, numero);


--
-- Name: supplier_groups uq_supplier_groups; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.supplier_groups
    ADD CONSTRAINT uq_supplier_groups UNIQUE (tenant_id, codigo);


--
-- Name: suppliers uq_suppliers_tenant_codigo; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.suppliers
    ADD CONSTRAINT uq_suppliers_tenant_codigo UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);


--
-- Name: suppliers uq_suppliers_tenant_nuit; Type: CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.suppliers
    ADD CONSTRAINT uq_suppliers_tenant_nuit UNIQUE NULLS NOT DISTINCT (tenant_id, nuit);


--
-- Name: account_types account_types_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.account_types
    ADD CONSTRAINT account_types_pkey PRIMARY KEY (id);


--
-- Name: accounting_budgets accounting_budgets_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.accounting_budgets
    ADD CONSTRAINT accounting_budgets_pkey PRIMARY KEY (id);


--
-- Name: accounting_journals accounting_journals_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.accounting_journals
    ADD CONSTRAINT accounting_journals_pkey PRIMARY KEY (id);


--
-- Name: fiscal_periods accounting_periods_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.fiscal_periods
    ADD CONSTRAINT accounting_periods_pkey PRIMARY KEY (id);


--
-- Name: accounting_reports accounting_reports_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.accounting_reports
    ADD CONSTRAINT accounting_reports_pkey PRIMARY KEY (id);


--
-- Name: chart_of_accounts chart_of_accounts_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.chart_of_accounts
    ADD CONSTRAINT chart_of_accounts_pkey PRIMARY KEY (id);


--
-- Name: depreciation_entries depreciation_entries_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.depreciation_entries
    ADD CONSTRAINT depreciation_entries_pkey PRIMARY KEY (id);


--
-- Name: fiscal_years fiscal_years_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.fiscal_years
    ADD CONSTRAINT fiscal_years_pkey PRIMARY KEY (id);


--
-- Name: fixed_assets fixed_assets_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.fixed_assets
    ADD CONSTRAINT fixed_assets_pkey PRIMARY KEY (id);


--
-- Name: journal_entries journal_entries_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.journal_entries
    ADD CONSTRAINT journal_entries_pkey PRIMARY KEY (id);


--
-- Name: journal_entry_lines journal_entry_lines_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.journal_entry_lines
    ADD CONSTRAINT journal_entry_lines_pkey PRIMARY KEY (id);


--
-- Name: journal_entry_sequences journal_entry_sequences_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.journal_entry_sequences
    ADD CONSTRAINT journal_entry_sequences_pkey PRIMARY KEY (id);


--
-- Name: period_closing_checks period_closing_checks_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.period_closing_checks
    ADD CONSTRAINT period_closing_checks_pkey PRIMARY KEY (id);


--
-- Name: period_closings period_closings_pkey; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.period_closings
    ADD CONSTRAINT period_closings_pkey PRIMARY KEY (id);


--
-- Name: account_types uq_account_types; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.account_types
    ADD CONSTRAINT uq_account_types UNIQUE (tenant_id, codigo);


--
-- Name: accounting_budgets uq_accounting_budgets_conta_ano_mes; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.accounting_budgets
    ADD CONSTRAINT uq_accounting_budgets_conta_ano_mes UNIQUE (tenant_id, chart_account_id, fiscal_year_id, mes);


--
-- Name: accounting_journals uq_accounting_journals; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.accounting_journals
    ADD CONSTRAINT uq_accounting_journals UNIQUE (tenant_id, codigo);


--
-- Name: fiscal_periods uq_accounting_periods; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.fiscal_periods
    ADD CONSTRAINT uq_accounting_periods UNIQUE (tenant_id, ano, mes);


--
-- Name: chart_of_accounts uq_chart_of_accounts; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.chart_of_accounts
    ADD CONSTRAINT uq_chart_of_accounts UNIQUE (tenant_id, codigo);


--
-- Name: depreciation_entries uq_depreciation_entries_asset_period; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.depreciation_entries
    ADD CONSTRAINT uq_depreciation_entries_asset_period UNIQUE (fixed_asset_id, fiscal_period_id);


--
-- Name: fiscal_years uq_fiscal_years; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.fiscal_years
    ADD CONSTRAINT uq_fiscal_years UNIQUE (tenant_id, ano);


--
-- Name: fixed_assets uq_fixed_assets_codigo; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.fixed_assets
    ADD CONSTRAINT uq_fixed_assets_codigo UNIQUE (tenant_id, codigo);


--
-- Name: journal_entries uq_journal_entries; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.journal_entries
    ADD CONSTRAINT uq_journal_entries UNIQUE (tenant_id, numero);


--
-- Name: journal_entry_sequences uq_journal_entry_sequences; Type: CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.journal_entry_sequences
    ADD CONSTRAINT uq_journal_entry_sequences UNIQUE (tenant_id, accounting_journal_id, ano);


--
-- Name: atividades atividades_pkey; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.atividades
    ADD CONSTRAINT atividades_pkey PRIMARY KEY (id);


--
-- Name: crm_activities crm_activities_pkey; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_activities
    ADD CONSTRAINT crm_activities_pkey PRIMARY KEY (id);


--
-- Name: crm_lead_sources crm_lead_sources_pkey; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_lead_sources
    ADD CONSTRAINT crm_lead_sources_pkey PRIMARY KEY (id);


--
-- Name: crm_leads crm_leads_pkey; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_leads
    ADD CONSTRAINT crm_leads_pkey PRIMARY KEY (id);


--
-- Name: crm_opportunities crm_opportunities_pkey; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_opportunities
    ADD CONSTRAINT crm_opportunities_pkey PRIMARY KEY (id);


--
-- Name: crm_pipeline_stages crm_pipeline_stages_pkey; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_pipeline_stages
    ADD CONSTRAINT crm_pipeline_stages_pkey PRIMARY KEY (id);


--
-- Name: crm_pipelines crm_pipelines_pkey; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_pipelines
    ADD CONSTRAINT crm_pipelines_pkey PRIMARY KEY (id);


--
-- Name: leads leads_pkey; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (id);


--
-- Name: oportunidades oportunidades_pkey; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.oportunidades
    ADD CONSTRAINT oportunidades_pkey PRIMARY KEY (id);


--
-- Name: crm_lead_sources uq_crm_lead_sources; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_lead_sources
    ADD CONSTRAINT uq_crm_lead_sources UNIQUE (tenant_id, codigo);


--
-- Name: crm_leads uq_crm_leads; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_leads
    ADD CONSTRAINT uq_crm_leads UNIQUE (tenant_id, codigo);


--
-- Name: crm_opportunities uq_crm_opportunities; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_opportunities
    ADD CONSTRAINT uq_crm_opportunities UNIQUE (tenant_id, codigo);


--
-- Name: crm_pipeline_stages uq_crm_pipeline_stages; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_pipeline_stages
    ADD CONSTRAINT uq_crm_pipeline_stages UNIQUE (pipeline_id, codigo);


--
-- Name: crm_pipelines uq_crm_pipelines; Type: CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_pipelines
    ADD CONSTRAINT uq_crm_pipelines UNIQUE (tenant_id, codigo);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: company_addresses company_addresses_pkey; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_addresses
    ADD CONSTRAINT company_addresses_pkey PRIMARY KEY (id);


--
-- Name: company_banks company_banks_pkey; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_banks
    ADD CONSTRAINT company_banks_pkey PRIMARY KEY (id);


--
-- Name: company_branches company_branches_pkey; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_branches
    ADD CONSTRAINT company_branches_pkey PRIMARY KEY (id);


--
-- Name: company_contacts company_contacts_pkey; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_contacts
    ADD CONSTRAINT company_contacts_pkey PRIMARY KEY (id);


--
-- Name: company_documents company_documents_pkey; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_documents
    ADD CONSTRAINT company_documents_pkey PRIMARY KEY (id);


--
-- Name: company_licenses company_licenses_pkey; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_licenses
    ADD CONSTRAINT company_licenses_pkey PRIMARY KEY (id);


--
-- Name: company_settings company_settings_pkey; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_settings
    ADD CONSTRAINT company_settings_pkey PRIMARY KEY (id);


--
-- Name: company_tax_info company_tax_info_pkey; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_tax_info
    ADD CONSTRAINT company_tax_info_pkey PRIMARY KEY (id);


--
-- Name: company_users company_users_pkey; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_users
    ADD CONSTRAINT company_users_pkey PRIMARY KEY (id);


--
-- Name: companies uq_companies_codigo; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.companies
    ADD CONSTRAINT uq_companies_codigo UNIQUE (codigo);


--
-- Name: company_branches uq_company_branches; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_branches
    ADD CONSTRAINT uq_company_branches UNIQUE (company_id, codigo);


--
-- Name: company_settings uq_company_settings; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_settings
    ADD CONSTRAINT uq_company_settings UNIQUE (company_id, chave);


--
-- Name: company_tax_info uq_company_tax_info_company; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_tax_info
    ADD CONSTRAINT uq_company_tax_info_company UNIQUE (company_id);


--
-- Name: company_tax_info uq_company_tax_info_nuit; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_tax_info
    ADD CONSTRAINT uq_company_tax_info_nuit UNIQUE (nuit);


--
-- Name: company_users uq_company_users; Type: CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_users
    ADD CONSTRAINT uq_company_users UNIQUE (company_id, user_id);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: company_addresses company_addresses_pkey; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_addresses
    ADD CONSTRAINT company_addresses_pkey PRIMARY KEY (id);


--
-- Name: company_banks company_banks_pkey; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_banks
    ADD CONSTRAINT company_banks_pkey PRIMARY KEY (id);


--
-- Name: company_branches company_branches_pkey; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_branches
    ADD CONSTRAINT company_branches_pkey PRIMARY KEY (id);


--
-- Name: company_contacts company_contacts_pkey; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_contacts
    ADD CONSTRAINT company_contacts_pkey PRIMARY KEY (id);


--
-- Name: company_documents company_documents_pkey; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_documents
    ADD CONSTRAINT company_documents_pkey PRIMARY KEY (id);


--
-- Name: company_licenses company_licenses_pkey; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_licenses
    ADD CONSTRAINT company_licenses_pkey PRIMARY KEY (id);


--
-- Name: company_settings company_settings_pkey; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_settings
    ADD CONSTRAINT company_settings_pkey PRIMARY KEY (id);


--
-- Name: company_tax_info company_tax_info_pkey; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_tax_info
    ADD CONSTRAINT company_tax_info_pkey PRIMARY KEY (id);


--
-- Name: company_users company_users_pkey; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_users
    ADD CONSTRAINT company_users_pkey PRIMARY KEY (id);


--
-- Name: companies uq_companies_codigo; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.companies
    ADD CONSTRAINT uq_companies_codigo UNIQUE (codigo);


--
-- Name: company_branches uq_company_branches; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_branches
    ADD CONSTRAINT uq_company_branches UNIQUE (company_id, codigo);


--
-- Name: company_settings uq_company_settings; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_settings
    ADD CONSTRAINT uq_company_settings UNIQUE (company_id, chave);


--
-- Name: company_tax_info uq_company_tax_info_company; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_tax_info
    ADD CONSTRAINT uq_company_tax_info_company UNIQUE (company_id);


--
-- Name: company_tax_info uq_company_tax_info_nuit; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_tax_info
    ADD CONSTRAINT uq_company_tax_info_nuit UNIQUE (nuit);


--
-- Name: company_users uq_company_users; Type: CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_users
    ADD CONSTRAINT uq_company_users UNIQUE (company_id, user_id);


--
-- Name: credit_note_items credit_note_items_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.credit_note_items
    ADD CONSTRAINT credit_note_items_pkey PRIMARY KEY (id);


--
-- Name: credit_notes credit_notes_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.credit_notes
    ADD CONSTRAINT credit_notes_pkey PRIMARY KEY (id);


--
-- Name: invoice_discounts invoice_discounts_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoice_discounts
    ADD CONSTRAINT invoice_discounts_pkey PRIMARY KEY (id);


--
-- Name: invoice_items invoice_items_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoice_items
    ADD CONSTRAINT invoice_items_pkey PRIMARY KEY (id);


--
-- Name: invoice_receipts invoice_receipts_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoice_receipts
    ADD CONSTRAINT invoice_receipts_pkey PRIMARY KEY (id);


--
-- Name: invoice_series invoice_series_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoice_series
    ADD CONSTRAINT invoice_series_pkey PRIMARY KEY (id);


--
-- Name: invoice_taxes invoice_taxes_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoice_taxes
    ADD CONSTRAINT invoice_taxes_pkey PRIMARY KEY (id);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: sales_deliveries sales_deliveries_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_deliveries
    ADD CONSTRAINT sales_deliveries_pkey PRIMARY KEY (id);


--
-- Name: sales_delivery_items sales_delivery_items_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_delivery_items
    ADD CONSTRAINT sales_delivery_items_pkey PRIMARY KEY (id);


--
-- Name: sales_order_items sales_order_items_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_order_items
    ADD CONSTRAINT sales_order_items_pkey PRIMARY KEY (id);


--
-- Name: sales_orders sales_orders_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_orders
    ADD CONSTRAINT sales_orders_pkey PRIMARY KEY (id);


--
-- Name: sales_quote_items sales_quote_items_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_quote_items
    ADD CONSTRAINT sales_quote_items_pkey PRIMARY KEY (id);


--
-- Name: sales_quotes sales_quotes_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_quotes
    ADD CONSTRAINT sales_quotes_pkey PRIMARY KEY (id);


--
-- Name: sales_return_items sales_return_items_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_return_items
    ADD CONSTRAINT sales_return_items_pkey PRIMARY KEY (id);


--
-- Name: sales_returns sales_returns_pkey; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_returns
    ADD CONSTRAINT sales_returns_pkey PRIMARY KEY (id);


--
-- Name: credit_notes uq_credit_notes; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.credit_notes
    ADD CONSTRAINT uq_credit_notes UNIQUE (tenant_id, numero);


--
-- Name: invoice_receipts uq_invoice_receipts; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoice_receipts
    ADD CONSTRAINT uq_invoice_receipts UNIQUE (tenant_id, numero);


--
-- Name: invoice_series uq_invoice_series; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoice_series
    ADD CONSTRAINT uq_invoice_series UNIQUE (tenant_id, tipo, ano);


--
-- Name: invoices uq_invoices; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoices
    ADD CONSTRAINT uq_invoices UNIQUE (tenant_id, numero);


--
-- Name: sales_deliveries uq_sales_deliveries; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_deliveries
    ADD CONSTRAINT uq_sales_deliveries UNIQUE (tenant_id, numero);


--
-- Name: sales_orders uq_sales_orders; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_orders
    ADD CONSTRAINT uq_sales_orders UNIQUE (tenant_id, numero);


--
-- Name: sales_quotes uq_sales_quotes; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_quotes
    ADD CONSTRAINT uq_sales_quotes UNIQUE (tenant_id, numero);


--
-- Name: sales_returns uq_sales_returns; Type: CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_returns
    ADD CONSTRAINT uq_sales_returns UNIQUE (tenant_id, numero);


--
-- Name: accounts_payable_payments accounts_payable_payments_pkey; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_payable_payments
    ADD CONSTRAINT accounts_payable_payments_pkey PRIMARY KEY (id);


--
-- Name: accounts_payable accounts_payable_pkey; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_payable
    ADD CONSTRAINT accounts_payable_pkey PRIMARY KEY (id);


--
-- Name: accounts_receivable_payments accounts_receivable_payments_pkey; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_receivable_payments
    ADD CONSTRAINT accounts_receivable_payments_pkey PRIMARY KEY (id);


--
-- Name: accounts_receivable accounts_receivable_pkey; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_receivable
    ADD CONSTRAINT accounts_receivable_pkey PRIMARY KEY (id);


--
-- Name: cash_flow_entries cash_flow_entries_pkey; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.cash_flow_entries
    ADD CONSTRAINT cash_flow_entries_pkey PRIMARY KEY (id);


--
-- Name: financial_budgets financial_budgets_pkey; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.financial_budgets
    ADD CONSTRAINT financial_budgets_pkey PRIMARY KEY (id);


--
-- Name: financial_categories financial_categories_pkey; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.financial_categories
    ADD CONSTRAINT financial_categories_pkey PRIMARY KEY (id);


--
-- Name: payment_methods payment_methods_pkey; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.payment_methods
    ADD CONSTRAINT payment_methods_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: accounts_payable uq_accounts_payable; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_payable
    ADD CONSTRAINT uq_accounts_payable UNIQUE (tenant_id, numero);


--
-- Name: accounts_receivable uq_accounts_receivable; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_receivable
    ADD CONSTRAINT uq_accounts_receivable UNIQUE (tenant_id, numero);


--
-- Name: accounts_payable_payments uq_ap_payments; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_payable_payments
    ADD CONSTRAINT uq_ap_payments UNIQUE (accounts_payable_id, payment_id);


--
-- Name: accounts_receivable_payments uq_ar_payments; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_receivable_payments
    ADD CONSTRAINT uq_ar_payments UNIQUE (accounts_receivable_id, payment_id);


--
-- Name: financial_budgets uq_financial_budgets; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.financial_budgets
    ADD CONSTRAINT uq_financial_budgets UNIQUE (tenant_id, financial_category_id, ano, mes);


--
-- Name: payment_methods uq_payment_methods; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.payment_methods
    ADD CONSTRAINT uq_payment_methods UNIQUE (tenant_id, codigo);


--
-- Name: payments uq_payments; Type: CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.payments
    ADD CONSTRAINT uq_payments UNIQUE (tenant_id, numero);


--
-- Name: school_attendance school_attendance_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_attendance
    ADD CONSTRAINT school_attendance_pkey PRIMARY KEY (id);


--
-- Name: school_books school_books_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_books
    ADD CONSTRAINT school_books_pkey PRIMARY KEY (id);


--
-- Name: school_books school_books_tenant_id_codigo_key; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_books
    ADD CONSTRAINT school_books_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: school_classes school_classes_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_classes
    ADD CONSTRAINT school_classes_pkey PRIMARY KEY (id);


--
-- Name: school_enrollments school_enrollments_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_enrollments
    ADD CONSTRAINT school_enrollments_pkey PRIMARY KEY (id);


--
-- Name: school_fee_plans school_fee_plans_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_fee_plans
    ADD CONSTRAINT school_fee_plans_pkey PRIMARY KEY (id);


--
-- Name: school_fee_plans school_fee_plans_tenant_id_codigo_key; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_fee_plans
    ADD CONSTRAINT school_fee_plans_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: school_fees school_fees_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_fees
    ADD CONSTRAINT school_fees_pkey PRIMARY KEY (id);


--
-- Name: school_grade_items school_grade_items_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_grade_items
    ADD CONSTRAINT school_grade_items_pkey PRIMARY KEY (id);


--
-- Name: school_grades school_grades_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_grades
    ADD CONSTRAINT school_grades_pkey PRIMARY KEY (id);


--
-- Name: school_grades school_grades_tenant_id_grade_item_id_student_id_key; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_grades
    ADD CONSTRAINT school_grades_tenant_id_grade_item_id_student_id_key UNIQUE (tenant_id, grade_item_id, student_id);


--
-- Name: school_guardians school_guardians_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_guardians
    ADD CONSTRAINT school_guardians_pkey PRIMARY KEY (id);


--
-- Name: school_library_loans school_library_loans_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_library_loans
    ADD CONSTRAINT school_library_loans_pkey PRIMARY KEY (id);


--
-- Name: school_messages school_messages_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_messages
    ADD CONSTRAINT school_messages_pkey PRIMARY KEY (id);


--
-- Name: school_payments school_payments_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_payments
    ADD CONSTRAINT school_payments_pkey PRIMARY KEY (id);


--
-- Name: school_payments school_payments_tenant_id_external_id_key; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_payments
    ADD CONSTRAINT school_payments_tenant_id_external_id_key UNIQUE NULLS NOT DISTINCT (tenant_id, external_id);


--
-- Name: school_student_roles school_student_roles_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_student_roles
    ADD CONSTRAINT school_student_roles_pkey PRIMARY KEY (id);


--
-- Name: school_students school_students_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_students
    ADD CONSTRAINT school_students_pkey PRIMARY KEY (id);


--
-- Name: school_subjects school_subjects_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_subjects
    ADD CONSTRAINT school_subjects_pkey PRIMARY KEY (id);


--
-- Name: school_subjects school_subjects_tenant_id_codigo_key; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_subjects
    ADD CONSTRAINT school_subjects_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: school_teacher_assignments school_teacher_assignments_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_teacher_assignments
    ADD CONSTRAINT school_teacher_assignments_pkey PRIMARY KEY (id);


--
-- Name: school_teacher_assignments school_teacher_assignments_tenant_id_class_id_subject_id_te_key; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_teacher_assignments
    ADD CONSTRAINT school_teacher_assignments_tenant_id_class_id_subject_id_te_key UNIQUE (tenant_id, class_id, subject_id, teacher_id, data_inicio);


--
-- Name: school_teacher_roles school_teacher_roles_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_teacher_roles
    ADD CONSTRAINT school_teacher_roles_pkey PRIMARY KEY (id);


--
-- Name: school_terms school_terms_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_terms
    ADD CONSTRAINT school_terms_pkey PRIMARY KEY (id);


--
-- Name: school_terms school_terms_tenant_id_school_year_id_codigo_key; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_terms
    ADD CONSTRAINT school_terms_tenant_id_school_year_id_codigo_key UNIQUE (tenant_id, school_year_id, codigo);


--
-- Name: school_years school_years_pkey; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_years
    ADD CONSTRAINT school_years_pkey PRIMARY KEY (id);


--
-- Name: school_years school_years_tenant_id_codigo_key; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_years
    ADD CONSTRAINT school_years_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: school_classes uq_school_classes; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_classes
    ADD CONSTRAINT uq_school_classes UNIQUE (tenant_id, codigo, ano_lectivo);


--
-- Name: school_enrollments uq_school_enrollments; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_enrollments
    ADD CONSTRAINT uq_school_enrollments UNIQUE (tenant_id, numero);


--
-- Name: school_fees uq_school_fees; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_fees
    ADD CONSTRAINT uq_school_fees UNIQUE (tenant_id, numero);


--
-- Name: school_students uq_school_students; Type: CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_students
    ADD CONSTRAINT uq_school_students UNIQUE (tenant_id, codigo);


--
-- Name: tax_certificates tax_certificates_pkey; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_certificates
    ADD CONSTRAINT tax_certificates_pkey PRIMARY KEY (id);


--
-- Name: tax_exemptions tax_exemptions_pkey; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_exemptions
    ADD CONSTRAINT tax_exemptions_pkey PRIMARY KEY (id);


--
-- Name: tax_groups tax_groups_pkey; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_groups
    ADD CONSTRAINT tax_groups_pkey PRIMARY KEY (id);


--
-- Name: tax_regimes tax_regimes_pkey; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_regimes
    ADD CONSTRAINT tax_regimes_pkey PRIMARY KEY (id);


--
-- Name: tax_return_lines tax_return_lines_pkey; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_return_lines
    ADD CONSTRAINT tax_return_lines_pkey PRIMARY KEY (id);


--
-- Name: tax_returns tax_returns_pkey; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_returns
    ADD CONSTRAINT tax_returns_pkey PRIMARY KEY (id);


--
-- Name: tax_rules tax_rules_pkey; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_rules
    ADD CONSTRAINT tax_rules_pkey PRIMARY KEY (id);


--
-- Name: tax_transactions tax_transactions_pkey; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_transactions
    ADD CONSTRAINT tax_transactions_pkey PRIMARY KEY (id);


--
-- Name: taxes taxes_pkey; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.taxes
    ADD CONSTRAINT taxes_pkey PRIMARY KEY (id);


--
-- Name: tax_certificates uq_tax_certificates; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_certificates
    ADD CONSTRAINT uq_tax_certificates UNIQUE (tenant_id, numero);


--
-- Name: tax_groups uq_tax_groups; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_groups
    ADD CONSTRAINT uq_tax_groups UNIQUE (tenant_id, codigo);


--
-- Name: tax_regimes uq_tax_regimes; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_regimes
    ADD CONSTRAINT uq_tax_regimes UNIQUE (tenant_id, codigo);


--
-- Name: taxes uq_taxes; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.taxes
    ADD CONSTRAINT uq_taxes UNIQUE (tenant_id, codigo);


--
-- Name: withholding_taxes uq_withholding_taxes; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.withholding_taxes
    ADD CONSTRAINT uq_withholding_taxes UNIQUE (tenant_id, codigo);


--
-- Name: withholding_tax_transactions withholding_tax_transactions_pkey; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.withholding_tax_transactions
    ADD CONSTRAINT withholding_tax_transactions_pkey PRIMARY KEY (id);


--
-- Name: withholding_taxes withholding_taxes_pkey; Type: CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.withholding_taxes
    ADD CONSTRAINT withholding_taxes_pkey PRIMARY KEY (id);


--
-- Name: delivery_drivers delivery_drivers_pkey; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.delivery_drivers
    ADD CONSTRAINT delivery_drivers_pkey PRIMARY KEY (id);


--
-- Name: delivery_drivers delivery_drivers_tenant_id_codigo_key; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.delivery_drivers
    ADD CONSTRAINT delivery_drivers_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: delivery_routes delivery_routes_pkey; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.delivery_routes
    ADD CONSTRAINT delivery_routes_pkey PRIMARY KEY (id);


--
-- Name: delivery_routes delivery_routes_tenant_id_codigo_key; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.delivery_routes
    ADD CONSTRAINT delivery_routes_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: delivery_statuses delivery_statuses_pkey; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.delivery_statuses
    ADD CONSTRAINT delivery_statuses_pkey PRIMARY KEY (id);


--
-- Name: delivery_statuses delivery_statuses_tenant_id_codigo_key; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.delivery_statuses
    ADD CONSTRAINT delivery_statuses_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: delivery_tracking delivery_tracking_pkey; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.delivery_tracking
    ADD CONSTRAINT delivery_tracking_pkey PRIMARY KEY (id);


--
-- Name: delivery_vehicles delivery_vehicles_pkey; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.delivery_vehicles
    ADD CONSTRAINT delivery_vehicles_pkey PRIMARY KEY (id);


--
-- Name: delivery_vehicles delivery_vehicles_tenant_id_codigo_key; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.delivery_vehicles
    ADD CONSTRAINT delivery_vehicles_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: delivery_vehicles delivery_vehicles_tenant_id_matricula_key; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.delivery_vehicles
    ADD CONSTRAINT delivery_vehicles_tenant_id_matricula_key UNIQUE (tenant_id, matricula);


--
-- Name: logistics_drivers logistics_drivers_pkey; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_drivers
    ADD CONSTRAINT logistics_drivers_pkey PRIMARY KEY (id);


--
-- Name: logistics_routes logistics_routes_pkey; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_routes
    ADD CONSTRAINT logistics_routes_pkey PRIMARY KEY (id);


--
-- Name: logistics_shipments logistics_shipments_pkey; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT logistics_shipments_pkey PRIMARY KEY (id);


--
-- Name: logistics_tracking_events logistics_tracking_events_pkey; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_tracking_events
    ADD CONSTRAINT logistics_tracking_events_pkey PRIMARY KEY (id);


--
-- Name: logistics_vehicles logistics_vehicles_pkey; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_vehicles
    ADD CONSTRAINT logistics_vehicles_pkey PRIMARY KEY (id);


--
-- Name: shipment_items shipment_items_pkey; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.shipment_items
    ADD CONSTRAINT shipment_items_pkey PRIMARY KEY (id);


--
-- Name: shipments shipments_pkey; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.shipments
    ADD CONSTRAINT shipments_pkey PRIMARY KEY (id);


--
-- Name: shipments shipments_tenant_id_numero_key; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.shipments
    ADD CONSTRAINT shipments_tenant_id_numero_key UNIQUE (tenant_id, numero);


--
-- Name: logistics_drivers uq_logistics_drivers; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_drivers
    ADD CONSTRAINT uq_logistics_drivers UNIQUE (tenant_id, codigo);


--
-- Name: logistics_routes uq_logistics_routes; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_routes
    ADD CONSTRAINT uq_logistics_routes UNIQUE (tenant_id, codigo);


--
-- Name: logistics_shipments uq_logistics_shipments; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT uq_logistics_shipments UNIQUE (tenant_id, numero);


--
-- Name: logistics_vehicles uq_logistics_vehicles_codigo; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_vehicles
    ADD CONSTRAINT uq_logistics_vehicles_codigo UNIQUE (tenant_id, codigo);


--
-- Name: logistics_vehicles uq_logistics_vehicles_matricula; Type: CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_vehicles
    ADD CONSTRAINT uq_logistics_vehicles_matricula UNIQUE (tenant_id, matricula);


--
-- Name: currencies currencies_code_key; Type: CONSTRAINT; Schema: multi_moeda; Owner: -
--

ALTER TABLE ONLY multi_moeda.currencies
    ADD CONSTRAINT currencies_code_key UNIQUE (code);


--
-- Name: currencies currencies_pkey; Type: CONSTRAINT; Schema: multi_moeda; Owner: -
--

ALTER TABLE ONLY multi_moeda.currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);


--
-- Name: exchange_rates exchange_rates_pkey; Type: CONSTRAINT; Schema: multi_moeda; Owner: -
--

ALTER TABLE ONLY multi_moeda.exchange_rates
    ADD CONSTRAINT exchange_rates_pkey PRIMARY KEY (id);


--
-- Name: tenant_currencies tenant_currencies_pkey; Type: CONSTRAINT; Schema: multi_moeda; Owner: -
--

ALTER TABLE ONLY multi_moeda.tenant_currencies
    ADD CONSTRAINT tenant_currencies_pkey PRIMARY KEY (id);


--
-- Name: exchange_rates uq_exchange_rates; Type: CONSTRAINT; Schema: multi_moeda; Owner: -
--

ALTER TABLE ONLY multi_moeda.exchange_rates
    ADD CONSTRAINT uq_exchange_rates UNIQUE (tenant_id, base_currency_id, quote_currency_id, effective_date, source);


--
-- Name: tenant_currencies uq_tenant_currencies; Type: CONSTRAINT; Schema: multi_moeda; Owner: -
--

ALTER TABLE ONLY multi_moeda.tenant_currencies
    ADD CONSTRAINT uq_tenant_currencies UNIQUE (tenant_id, currency_id);


--
-- Name: notification_channels notification_channels_pkey; Type: CONSTRAINT; Schema: notifications; Owner: -
--

ALTER TABLE ONLY notifications.notification_channels
    ADD CONSTRAINT notification_channels_pkey PRIMARY KEY (id);


--
-- Name: notification_messages notification_messages_pkey; Type: CONSTRAINT; Schema: notifications; Owner: -
--

ALTER TABLE ONLY notifications.notification_messages
    ADD CONSTRAINT notification_messages_pkey PRIMARY KEY (id);


--
-- Name: notification_templates notification_templates_pkey; Type: CONSTRAINT; Schema: notifications; Owner: -
--

ALTER TABLE ONLY notifications.notification_templates
    ADD CONSTRAINT notification_templates_pkey PRIMARY KEY (id);


--
-- Name: notification_channels uq_notification_channels; Type: CONSTRAINT; Schema: notifications; Owner: -
--

ALTER TABLE ONLY notifications.notification_channels
    ADD CONSTRAINT uq_notification_channels UNIQUE (tenant_id, codigo);


--
-- Name: notification_templates uq_notification_templates; Type: CONSTRAINT; Schema: notifications; Owner: -
--

ALTER TABLE ONLY notifications.notification_templates
    ADD CONSTRAINT uq_notification_templates UNIQUE (tenant_id, codigo, canal_tipo);


--
-- Name: pos_catalog_items pos_catalog_items_pkey; Type: CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_catalog_items
    ADD CONSTRAINT pos_catalog_items_pkey PRIMARY KEY (id);


--
-- Name: pos_sale_items pos_sale_items_pkey; Type: CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_sale_items
    ADD CONSTRAINT pos_sale_items_pkey PRIMARY KEY (id);


--
-- Name: pos_sale_payments pos_sale_payments_pkey; Type: CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_sale_payments
    ADD CONSTRAINT pos_sale_payments_pkey PRIMARY KEY (id);


--
-- Name: pos_sales pos_sales_pkey; Type: CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_sales
    ADD CONSTRAINT pos_sales_pkey PRIMARY KEY (id);


--
-- Name: pos_sessions pos_sessions_pkey; Type: CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_sessions
    ADD CONSTRAINT pos_sessions_pkey PRIMARY KEY (id);


--
-- Name: pos_terminals pos_terminals_pkey; Type: CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_terminals
    ADD CONSTRAINT pos_terminals_pkey PRIMARY KEY (id);


--
-- Name: pos_catalog_items uq_pos_catalog_items; Type: CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_catalog_items
    ADD CONSTRAINT uq_pos_catalog_items UNIQUE NULLS NOT DISTINCT (tenant_id, product_id, product_variant_id);


--
-- Name: pos_sales uq_pos_sales; Type: CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_sales
    ADD CONSTRAINT uq_pos_sales UNIQUE (tenant_id, numero);


--
-- Name: pos_terminals uq_pos_terminals; Type: CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_terminals
    ADD CONSTRAINT uq_pos_terminals UNIQUE (tenant_id, codigo);


--
-- Name: product_attribute_values product_attribute_values_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_attribute_values
    ADD CONSTRAINT product_attribute_values_pkey PRIMARY KEY (id);


--
-- Name: product_attributes product_attributes_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_attributes
    ADD CONSTRAINT product_attributes_pkey PRIMARY KEY (id);


--
-- Name: product_barcodes product_barcodes_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_barcodes
    ADD CONSTRAINT product_barcodes_pkey PRIMARY KEY (id);


--
-- Name: product_brands product_brands_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_brands
    ADD CONSTRAINT product_brands_pkey PRIMARY KEY (id);


--
-- Name: product_categories product_categories_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_categories
    ADD CONSTRAINT product_categories_pkey PRIMARY KEY (id);


--
-- Name: product_discounts product_discounts_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_discounts
    ADD CONSTRAINT product_discounts_pkey PRIMARY KEY (id);


--
-- Name: product_images product_images_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_images
    ADD CONSTRAINT product_images_pkey PRIMARY KEY (id);


--
-- Name: product_kit_items product_kit_items_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_kit_items
    ADD CONSTRAINT product_kit_items_pkey PRIMARY KEY (id);


--
-- Name: product_kits product_kits_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_kits
    ADD CONSTRAINT product_kits_pkey PRIMARY KEY (id);


--
-- Name: product_prices product_prices_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_prices
    ADD CONSTRAINT product_prices_pkey PRIMARY KEY (id);


--
-- Name: product_subcategories product_subcategories_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_subcategories
    ADD CONSTRAINT product_subcategories_pkey PRIMARY KEY (id);


--
-- Name: product_tag_links product_tag_links_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_tag_links
    ADD CONSTRAINT product_tag_links_pkey PRIMARY KEY (id);


--
-- Name: product_tags product_tags_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_tags
    ADD CONSTRAINT product_tags_pkey PRIMARY KEY (id);


--
-- Name: product_units product_units_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_units
    ADD CONSTRAINT product_units_pkey PRIMARY KEY (id);


--
-- Name: product_variants product_variants_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_variants
    ADD CONSTRAINT product_variants_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: product_attributes uq_product_attributes; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_attributes
    ADD CONSTRAINT uq_product_attributes UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);


--
-- Name: product_barcodes uq_product_barcodes; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_barcodes
    ADD CONSTRAINT uq_product_barcodes UNIQUE (barcode);


--
-- Name: product_brands uq_product_brands; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_brands
    ADD CONSTRAINT uq_product_brands UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);


--
-- Name: product_categories uq_product_categories; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_categories
    ADD CONSTRAINT uq_product_categories UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);


--
-- Name: product_kits uq_product_kits; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_kits
    ADD CONSTRAINT uq_product_kits UNIQUE NULLS NOT DISTINCT (product_id, codigo);


--
-- Name: product_subcategories uq_product_subcategories; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_subcategories
    ADD CONSTRAINT uq_product_subcategories UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);


--
-- Name: product_tag_links uq_product_tag_links; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_tag_links
    ADD CONSTRAINT uq_product_tag_links UNIQUE (product_id, product_tag_id);


--
-- Name: product_tags uq_product_tags; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_tags
    ADD CONSTRAINT uq_product_tags UNIQUE NULLS NOT DISTINCT (tenant_id, codigo);


--
-- Name: product_units uq_product_units; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_units
    ADD CONSTRAINT uq_product_units UNIQUE (tenant_id, codigo);


--
-- Name: product_variants uq_product_variants; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_variants
    ADD CONSTRAINT uq_product_variants UNIQUE NULLS NOT DISTINCT (product_id, codigo);


--
-- Name: products uq_products; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT uq_products UNIQUE (tenant_id, codigo);


--
-- Name: warehouses uq_warehouses; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.warehouses
    ADD CONSTRAINT uq_warehouses UNIQUE (tenant_id, codigo);


--
-- Name: warehouses warehouses_pkey; Type: CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.warehouses
    ADD CONSTRAINT warehouses_pkey PRIMARY KEY (id);


--
-- Name: chat_conversas chat_conversas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_conversas
    ADD CONSTRAINT chat_conversas_pkey PRIMARY KEY (id);


--
-- Name: chat_mensagens chat_mensagens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_mensagens
    ADD CONSTRAINT chat_mensagens_pkey PRIMARY KEY (id);


--
-- Name: chat_participantes chat_participantes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_participantes
    ADD CONSTRAINT chat_participantes_pkey PRIMARY KEY (conversa_id, user_id);


--
-- Name: comunicados_lidos comunicados_lidos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunicados_lidos
    ADD CONSTRAINT comunicados_lidos_pkey PRIMARY KEY (comunicado_id, user_id);


--
-- Name: comunicados comunicados_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunicados
    ADD CONSTRAINT comunicados_pkey PRIMARY KEY (id);


--
-- Name: notif_colaborador notif_colaborador_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notif_colaborador
    ADD CONSTRAINT notif_colaborador_pkey PRIMARY KEY (id);


--
-- Name: candidatura_notas candidatura_notas_pkey; Type: CONSTRAINT; Schema: recrutamento; Owner: -
--

ALTER TABLE ONLY recrutamento.candidatura_notas
    ADD CONSTRAINT candidatura_notas_pkey PRIMARY KEY (id);


--
-- Name: candidaturas candidaturas_pkey; Type: CONSTRAINT; Schema: recrutamento; Owner: -
--

ALTER TABLE ONLY recrutamento.candidaturas
    ADD CONSTRAINT candidaturas_pkey PRIMARY KEY (id);


--
-- Name: contactos contactos_pkey; Type: CONSTRAINT; Schema: recrutamento; Owner: -
--

ALTER TABLE ONLY recrutamento.contactos
    ADD CONSTRAINT contactos_pkey PRIMARY KEY (id);


--
-- Name: vagas vagas_pkey; Type: CONSTRAINT; Schema: recrutamento; Owner: -
--

ALTER TABLE ONLY recrutamento.vagas
    ADD CONSTRAINT vagas_pkey PRIMARY KEY (id);


--
-- Name: employee_bank_accounts employee_bank_accounts_pkey; Type: CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.employee_bank_accounts
    ADD CONSTRAINT employee_bank_accounts_pkey PRIMARY KEY (id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: hr_departments hr_departments_pkey; Type: CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.hr_departments
    ADD CONSTRAINT hr_departments_pkey PRIMARY KEY (id);


--
-- Name: payroll_periods payroll_periods_pkey; Type: CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.payroll_periods
    ADD CONSTRAINT payroll_periods_pkey PRIMARY KEY (id);


--
-- Name: payroll_run_lines payroll_run_lines_pkey; Type: CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.payroll_run_lines
    ADD CONSTRAINT payroll_run_lines_pkey PRIMARY KEY (id);


--
-- Name: payroll_runs payroll_runs_pkey; Type: CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.payroll_runs
    ADD CONSTRAINT payroll_runs_pkey PRIMARY KEY (id);


--
-- Name: employees uq_employees_tenant_codigo; Type: CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.employees
    ADD CONSTRAINT uq_employees_tenant_codigo UNIQUE (tenant_id, codigo);


--
-- Name: employees uq_employees_tenant_nuit; Type: CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.employees
    ADD CONSTRAINT uq_employees_tenant_nuit UNIQUE NULLS NOT DISTINCT (tenant_id, nuit);


--
-- Name: hr_departments uq_hr_departments; Type: CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.hr_departments
    ADD CONSTRAINT uq_hr_departments UNIQUE (tenant_id, codigo);


--
-- Name: payroll_periods uq_payroll_periods; Type: CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.payroll_periods
    ADD CONSTRAINT uq_payroll_periods UNIQUE (tenant_id, ano, mes);


--
-- Name: payroll_run_lines uq_payroll_run_employee; Type: CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.payroll_run_lines
    ADD CONSTRAINT uq_payroll_run_employee UNIQUE (payroll_run_id, employee_id);


--
-- Name: payroll_runs uq_payroll_runs; Type: CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.payroll_runs
    ADD CONSTRAINT uq_payroll_runs UNIQUE (tenant_id, numero);


--
-- Name: ausencias ausencias_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.ausencias
    ADD CONSTRAINT ausencias_pkey PRIMARY KEY (id);


--
-- Name: avaliacao_criterios avaliacao_criterios_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.avaliacao_criterios
    ADD CONSTRAINT avaliacao_criterios_pkey PRIMARY KEY (id);


--
-- Name: avaliacoes avaliacoes_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.avaliacoes
    ADD CONSTRAINT avaliacoes_pkey PRIMARY KEY (id);


--
-- Name: beneficios beneficios_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.beneficios
    ADD CONSTRAINT beneficios_pkey PRIMARY KEY (id);


--
-- Name: cargos cargos_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.cargos
    ADD CONSTRAINT cargos_pkey PRIMARY KEY (id);


--
-- Name: componentes_salariais componentes_salariais_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.componentes_salariais
    ADD CONSTRAINT componentes_salariais_pkey PRIMARY KEY (id);


--
-- Name: contactos_emergencia contactos_emergencia_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.contactos_emergencia
    ADD CONSTRAINT contactos_emergencia_pkey PRIMARY KEY (id);


--
-- Name: contratos contratos_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.contratos
    ADD CONSTRAINT contratos_pkey PRIMARY KEY (id);


--
-- Name: criterios_avaliacao criterios_avaliacao_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.criterios_avaliacao
    ADD CONSTRAINT criterios_avaliacao_pkey PRIMARY KEY (id);


--
-- Name: unidades_organizacionais departamentos_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.unidades_organizacionais
    ADD CONSTRAINT departamentos_pkey PRIMARY KEY (id);


--
-- Name: documentos_funcionario documentos_funcionario_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.documentos_funcionario
    ADD CONSTRAINT documentos_funcionario_pkey PRIMARY KEY (id);


--
-- Name: folhas_pagamento folhas_pagamento_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.folhas_pagamento
    ADD CONSTRAINT folhas_pagamento_pkey PRIMARY KEY (id);


--
-- Name: formacoes formacoes_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.formacoes
    ADD CONSTRAINT formacoes_pkey PRIMARY KEY (id);


--
-- Name: funcionario_beneficios funcionario_beneficios_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionario_beneficios
    ADD CONSTRAINT funcionario_beneficios_pkey PRIMARY KEY (id);


--
-- Name: funcionario_componentes_salariais funcionario_componentes_salariais_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionario_componentes_salariais
    ADD CONSTRAINT funcionario_componentes_salariais_pkey PRIMARY KEY (id);


--
-- Name: funcionario_formacoes funcionario_formacoes_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionario_formacoes
    ADD CONSTRAINT funcionario_formacoes_pkey PRIMARY KEY (id);


--
-- Name: funcionarios funcionarios_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT funcionarios_pkey PRIMARY KEY (id);


--
-- Name: historico_salarial historico_salarial_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.historico_salarial
    ADD CONSTRAINT historico_salarial_pkey PRIMARY KEY (id);


--
-- Name: horarios_trabalho horarios_trabalho_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.horarios_trabalho
    ADD CONSTRAINT horarios_trabalho_pkey PRIMARY KEY (id);


--
-- Name: justificacoes justificacoes_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.justificacoes
    ADD CONSTRAINT justificacoes_pkey PRIMARY KEY (id);


--
-- Name: periodos_avaliacao periodos_avaliacao_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.periodos_avaliacao
    ADD CONSTRAINT periodos_avaliacao_pkey PRIMARY KEY (id);


--
-- Name: presencas presencas_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.presencas
    ADD CONSTRAINT presencas_pkey PRIMARY KEY (id);


--
-- Name: processos_disciplinares processos_disciplinares_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.processos_disciplinares
    ADD CONSTRAINT processos_disciplinares_pkey PRIMARY KEY (id);


--
-- Name: recibo_vencimento_itens recibo_vencimento_itens_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.recibo_vencimento_itens
    ADD CONSTRAINT recibo_vencimento_itens_pkey PRIMARY KEY (id);


--
-- Name: recibos_vencimento recibos_vencimento_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.recibos_vencimento
    ADD CONSTRAINT recibos_vencimento_pkey PRIMARY KEY (id);


--
-- Name: saldos_ausencia saldos_ausencia_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.saldos_ausencia
    ADD CONSTRAINT saldos_ausencia_pkey PRIMARY KEY (id);


--
-- Name: tipos_ausencia tipos_ausencia_pkey; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.tipos_ausencia
    ADD CONSTRAINT tipos_ausencia_pkey PRIMARY KEY (id);


--
-- Name: avaliacao_criterios uq_avaliacao_criterios; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.avaliacao_criterios
    ADD CONSTRAINT uq_avaliacao_criterios UNIQUE (avaliacao_id, criterio_id);


--
-- Name: beneficios uq_beneficios_tenant_codigo; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.beneficios
    ADD CONSTRAINT uq_beneficios_tenant_codigo UNIQUE (tenant_id, codigo);


--
-- Name: cargos uq_cargos_tenant_codigo; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.cargos
    ADD CONSTRAINT uq_cargos_tenant_codigo UNIQUE (tenant_id, codigo);


--
-- Name: componentes_salariais uq_componentes_salariais_tenant_codigo; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.componentes_salariais
    ADD CONSTRAINT uq_componentes_salariais_tenant_codigo UNIQUE (tenant_id, codigo);


--
-- Name: criterios_avaliacao uq_criterios_avaliacao_tenant_codigo; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.criterios_avaliacao
    ADD CONSTRAINT uq_criterios_avaliacao_tenant_codigo UNIQUE (tenant_id, codigo);


--
-- Name: folhas_pagamento uq_folhas_pagamento_tenant_ano_mes; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.folhas_pagamento
    ADD CONSTRAINT uq_folhas_pagamento_tenant_ano_mes UNIQUE (tenant_id, ano, mes);


--
-- Name: formacoes uq_formacoes_tenant_codigo; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.formacoes
    ADD CONSTRAINT uq_formacoes_tenant_codigo UNIQUE (tenant_id, codigo);


--
-- Name: funcionario_beneficios uq_funcionario_beneficio; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionario_beneficios
    ADD CONSTRAINT uq_funcionario_beneficio UNIQUE (funcionario_id, beneficio_id);


--
-- Name: funcionario_componentes_salariais uq_funcionario_componente; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionario_componentes_salariais
    ADD CONSTRAINT uq_funcionario_componente UNIQUE (funcionario_id, componente_id);


--
-- Name: funcionarios uq_funcionarios_user_id; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT uq_funcionarios_user_id UNIQUE (user_id);


--
-- Name: horarios_trabalho uq_horarios_trabalho_tenant_codigo; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.horarios_trabalho
    ADD CONSTRAINT uq_horarios_trabalho_tenant_codigo UNIQUE (tenant_id, codigo);


--
-- Name: periodos_avaliacao uq_periodos_avaliacao_tenant_nome; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.periodos_avaliacao
    ADD CONSTRAINT uq_periodos_avaliacao_tenant_nome UNIQUE (tenant_id, nome);


--
-- Name: presencas uq_presencas_funcionario_data; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.presencas
    ADD CONSTRAINT uq_presencas_funcionario_data UNIQUE (funcionario_id, data);


--
-- Name: recibos_vencimento uq_recibos_vencimento_folha_funcionario; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.recibos_vencimento
    ADD CONSTRAINT uq_recibos_vencimento_folha_funcionario UNIQUE (folha_id, funcionario_id);


--
-- Name: saldos_ausencia uq_saldos_ausencia; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.saldos_ausencia
    ADD CONSTRAINT uq_saldos_ausencia UNIQUE (funcionario_id, tipo_ausencia_id, ano);


--
-- Name: tipos_ausencia uq_tipos_ausencia_tenant_codigo; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.tipos_ausencia
    ADD CONSTRAINT uq_tipos_ausencia_tenant_codigo UNIQUE (tenant_id, codigo);


--
-- Name: unidades_organizacionais uq_unidades_organizacionais_tenant_codigo; Type: CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.unidades_organizacionais
    ADD CONSTRAINT uq_unidades_organizacionais_tenant_codigo UNIQUE (tenant_id, codigo);


--
-- Name: security_ip_allowlist security_ip_allowlist_pkey; Type: CONSTRAINT; Schema: seguranca; Owner: -
--

ALTER TABLE ONLY seguranca.security_ip_allowlist
    ADD CONSTRAINT security_ip_allowlist_pkey PRIMARY KEY (id);


--
-- Name: security_mfa_enrollments security_mfa_enrollments_pkey; Type: CONSTRAINT; Schema: seguranca; Owner: -
--

ALTER TABLE ONLY seguranca.security_mfa_enrollments
    ADD CONSTRAINT security_mfa_enrollments_pkey PRIMARY KEY (id);


--
-- Name: security_policies security_policies_pkey; Type: CONSTRAINT; Schema: seguranca; Owner: -
--

ALTER TABLE ONLY seguranca.security_policies
    ADD CONSTRAINT security_policies_pkey PRIMARY KEY (id);


--
-- Name: security_ip_allowlist uq_security_ip_allowlist; Type: CONSTRAINT; Schema: seguranca; Owner: -
--

ALTER TABLE ONLY seguranca.security_ip_allowlist
    ADD CONSTRAINT uq_security_ip_allowlist UNIQUE (tenant_id, ip_or_cidr);


--
-- Name: security_mfa_enrollments uq_security_mfa_user_method; Type: CONSTRAINT; Schema: seguranca; Owner: -
--

ALTER TABLE ONLY seguranca.security_mfa_enrollments
    ADD CONSTRAINT uq_security_mfa_user_method UNIQUE (tenant_id, user_id, metodo);


--
-- Name: security_policies uq_security_policies; Type: CONSTRAINT; Schema: seguranca; Owner: -
--

ALTER TABLE ONLY seguranca.security_policies
    ADD CONSTRAINT uq_security_policies UNIQUE (tenant_id, codigo);


--
-- Name: api_logs api_logs_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.api_logs
    ADD CONSTRAINT api_logs_pkey PRIMARY KEY (id);


--
-- Name: cities cities_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.cities
    ADD CONSTRAINT cities_pkey PRIMARY KEY (id);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: currencies currencies_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);


--
-- Name: email_templates email_templates_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (id);


--
-- Name: exchange_rates exchange_rates_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.exchange_rates
    ADD CONSTRAINT exchange_rates_pkey PRIMARY KEY (id);


--
-- Name: integrations integrations_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.integrations
    ADD CONSTRAINT integrations_pkey PRIMARY KEY (id);


--
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (id);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: sms_templates sms_templates_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.sms_templates
    ADD CONSTRAINT sms_templates_pkey PRIMARY KEY (id);


--
-- Name: system_logs system_logs_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.system_logs
    ADD CONSTRAINT system_logs_pkey PRIMARY KEY (id);


--
-- Name: tenant_branding tenant_branding_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.tenant_branding
    ADD CONSTRAINT tenant_branding_pkey PRIMARY KEY (id);


--
-- Name: tenant_branding tenant_branding_tenant_id_key; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.tenant_branding
    ADD CONSTRAINT tenant_branding_tenant_id_key UNIQUE (tenant_id);


--
-- Name: tenant_defaults tenant_defaults_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.tenant_defaults
    ADD CONSTRAINT tenant_defaults_pkey PRIMARY KEY (id);


--
-- Name: tenant_document_settings tenant_document_settings_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.tenant_document_settings
    ADD CONSTRAINT tenant_document_settings_pkey PRIMARY KEY (id);


--
-- Name: tenant_feature_flags tenant_feature_flags_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.tenant_feature_flags
    ADD CONSTRAINT tenant_feature_flags_pkey PRIMARY KEY (id);


--
-- Name: tenant_integrations tenant_integrations_pkey; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.tenant_integrations
    ADD CONSTRAINT tenant_integrations_pkey PRIMARY KEY (id);


--
-- Name: countries uq_countries; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.countries
    ADD CONSTRAINT uq_countries UNIQUE (codigo);


--
-- Name: currencies uq_currencies; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.currencies
    ADD CONSTRAINT uq_currencies UNIQUE (codigo);


--
-- Name: languages uq_languages; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.languages
    ADD CONSTRAINT uq_languages UNIQUE (codigo);


--
-- Name: tenant_defaults uq_tenant_defaults; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.tenant_defaults
    ADD CONSTRAINT uq_tenant_defaults UNIQUE (tenant_id, chave);


--
-- Name: tenant_document_settings uq_tenant_document_settings; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.tenant_document_settings
    ADD CONSTRAINT uq_tenant_document_settings UNIQUE (tenant_id, modulo, tipo_documento);


--
-- Name: tenant_feature_flags uq_tenant_feature_flags; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.tenant_feature_flags
    ADD CONSTRAINT uq_tenant_feature_flags UNIQUE (tenant_id, codigo);


--
-- Name: tenant_integrations uq_tenant_integrations; Type: CONSTRAINT; Schema: sistema_configuracao; Owner: -
--

ALTER TABLE ONLY sistema_configuracao.tenant_integrations
    ADD CONSTRAINT uq_tenant_integrations UNIQUE (tenant_id, codigo);


--
-- Name: stock_adjustments stock_adjustments_pkey; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_adjustments
    ADD CONSTRAINT stock_adjustments_pkey PRIMARY KEY (id);


--
-- Name: stock_alerts stock_alerts_pkey; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_alerts
    ADD CONSTRAINT stock_alerts_pkey PRIMARY KEY (id);


--
-- Name: stock_batches stock_batches_pkey; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_batches
    ADD CONSTRAINT stock_batches_pkey PRIMARY KEY (id);


--
-- Name: stock_count_items stock_count_items_pkey; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_count_items
    ADD CONSTRAINT stock_count_items_pkey PRIMARY KEY (id);


--
-- Name: stock_counts stock_counts_pkey; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_counts
    ADD CONSTRAINT stock_counts_pkey PRIMARY KEY (id);


--
-- Name: stock_items stock_items_pkey; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_items
    ADD CONSTRAINT stock_items_pkey PRIMARY KEY (id);


--
-- Name: stock_logs stock_logs_pkey; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_logs
    ADD CONSTRAINT stock_logs_pkey PRIMARY KEY (id);


--
-- Name: stock_movements stock_movements_pkey; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_movements
    ADD CONSTRAINT stock_movements_pkey PRIMARY KEY (id);


--
-- Name: stock_reservations stock_reservations_pkey; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_reservations
    ADD CONSTRAINT stock_reservations_pkey PRIMARY KEY (id);


--
-- Name: stock_serial_numbers stock_serial_numbers_pkey; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_serial_numbers
    ADD CONSTRAINT stock_serial_numbers_pkey PRIMARY KEY (id);


--
-- Name: stock_transfer_items stock_transfer_items_pkey; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_transfer_items
    ADD CONSTRAINT stock_transfer_items_pkey PRIMARY KEY (id);


--
-- Name: stock_transfers stock_transfers_pkey; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_transfers
    ADD CONSTRAINT stock_transfers_pkey PRIMARY KEY (id);


--
-- Name: stock_batches uq_stock_batches; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_batches
    ADD CONSTRAINT uq_stock_batches UNIQUE (stock_item_id, batch_number);


--
-- Name: stock_counts uq_stock_counts; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_counts
    ADD CONSTRAINT uq_stock_counts UNIQUE (tenant_id, numero);


--
-- Name: stock_items uq_stock_items; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_items
    ADD CONSTRAINT uq_stock_items UNIQUE NULLS NOT DISTINCT (tenant_id, product_id, product_variant_id, warehouse_id);


--
-- Name: stock_serial_numbers uq_stock_serial_numbers; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_serial_numbers
    ADD CONSTRAINT uq_stock_serial_numbers UNIQUE (serial_number);


--
-- Name: stock_transfers uq_stock_transfers; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_transfers
    ADD CONSTRAINT uq_stock_transfers UNIQUE (tenant_id, numero);


--
-- Name: warehouse_locations uq_warehouse_locations; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.warehouse_locations
    ADD CONSTRAINT uq_warehouse_locations UNIQUE (warehouse_id, codigo);


--
-- Name: warehouse_locations warehouse_locations_pkey; Type: CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.warehouse_locations
    ADD CONSTRAINT warehouse_locations_pkey PRIMARY KEY (id);


--
-- Name: bank_accounts bank_accounts_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.bank_accounts
    ADD CONSTRAINT bank_accounts_pkey PRIMARY KEY (id);


--
-- Name: bank_accounts bank_accounts_tenant_id_banco_numero_conta_key; Type: CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.bank_accounts
    ADD CONSTRAINT bank_accounts_tenant_id_banco_numero_conta_key UNIQUE (tenant_id, banco, numero_conta);


--
-- Name: bank_accounts bank_accounts_tenant_id_codigo_key; Type: CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.bank_accounts
    ADD CONSTRAINT bank_accounts_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: caixas caixas_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.caixas
    ADD CONSTRAINT caixas_pkey PRIMARY KEY (id);


--
-- Name: cash_registers cash_registers_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.cash_registers
    ADD CONSTRAINT cash_registers_pkey PRIMARY KEY (id);


--
-- Name: cash_registers cash_registers_tenant_id_codigo_key; Type: CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.cash_registers
    ADD CONSTRAINT cash_registers_tenant_id_codigo_key UNIQUE (tenant_id, codigo);


--
-- Name: contas_bancarias contas_bancarias_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.contas_bancarias
    ADD CONSTRAINT contas_bancarias_pkey PRIMARY KEY (id);


--
-- Name: movements movements_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.movements
    ADD CONSTRAINT movements_pkey PRIMARY KEY (id);


--
-- Name: movimentos_financeiros movimentos_financeiros_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.movimentos_financeiros
    ADD CONSTRAINT movimentos_financeiros_pkey PRIMARY KEY (id);


--
-- Name: reconciliacoes_bancarias reconciliacoes_bancarias_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.reconciliacoes_bancarias
    ADD CONSTRAINT reconciliacoes_bancarias_pkey PRIMARY KEY (id);


--
-- Name: reconciliations reconciliations_pkey; Type: CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.reconciliations
    ADD CONSTRAINT reconciliations_pkey PRIMARY KEY (id);


--
-- Name: reconciliations reconciliations_tenant_id_bank_account_id_periodo_inicio_pe_key; Type: CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.reconciliations
    ADD CONSTRAINT reconciliations_tenant_id_bank_account_id_periodo_inicio_pe_key UNIQUE (tenant_id, bank_account_id, periodo_inicio, periodo_fim);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: profiles uq_profiles_user; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.profiles
    ADD CONSTRAINT uq_profiles_user UNIQUE (user_id);


--
-- Name: user_avatar uq_user_avatar; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.user_avatar
    ADD CONSTRAINT uq_user_avatar UNIQUE (user_id);


--
-- Name: user_devices uq_user_devices; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.user_devices
    ADD CONSTRAINT uq_user_devices UNIQUE (user_id, device_id);


--
-- Name: user_preferences uq_user_preferences; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.user_preferences
    ADD CONSTRAINT uq_user_preferences UNIQUE (user_id, chave);


--
-- Name: user_settings uq_user_settings; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.user_settings
    ADD CONSTRAINT uq_user_settings UNIQUE (user_id, chave);


--
-- Name: user_activity user_activity_pkey; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.user_activity
    ADD CONSTRAINT user_activity_pkey PRIMARY KEY (id);


--
-- Name: user_avatar user_avatar_pkey; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.user_avatar
    ADD CONSTRAINT user_avatar_pkey PRIMARY KEY (id);


--
-- Name: user_devices user_devices_pkey; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.user_devices
    ADD CONSTRAINT user_devices_pkey PRIMARY KEY (id);


--
-- Name: user_notifications user_notifications_pkey; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.user_notifications
    ADD CONSTRAINT user_notifications_pkey PRIMARY KEY (id);


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (id);


--
-- Name: user_security_logs user_security_logs_pkey; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.user_security_logs
    ADD CONSTRAINT user_security_logs_pkey PRIMARY KEY (id);


--
-- Name: user_settings user_settings_pkey; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.user_settings
    ADD CONSTRAINT user_settings_pkey PRIMARY KEY (id);


--
-- Name: user_tokens user_tokens_pkey; Type: CONSTRAINT; Schema: utilizadores; Owner: -
--

ALTER TABLE ONLY utilizadores.user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- Name: idx_subscription_invoices_tenant_status; Type: INDEX; Schema: assinaturas; Owner: -
--

CREATE INDEX idx_subscription_invoices_tenant_status ON assinaturas.subscription_invoices USING btree (tenant_id, status);


--
-- Name: idx_subscription_plans_tenant; Type: INDEX; Schema: assinaturas; Owner: -
--

CREATE INDEX idx_subscription_plans_tenant ON assinaturas.subscription_plans USING btree (tenant_id, activo);


--
-- Name: idx_subscription_usage_tenant_periodo; Type: INDEX; Schema: assinaturas; Owner: -
--

CREATE INDEX idx_subscription_usage_tenant_periodo ON assinaturas.subscription_usage USING btree (tenant_id, periodo);


--
-- Name: idx_subscriptions_tenant_status; Type: INDEX; Schema: assinaturas; Owner: -
--

CREATE INDEX idx_subscriptions_tenant_status ON assinaturas.subscriptions USING btree (tenant_id, status);


--
-- Name: idx_audit_events_tenant_created; Type: INDEX; Schema: auditoria; Owner: -
--

CREATE INDEX idx_audit_events_tenant_created ON auditoria.audit_events USING btree (tenant_id, created_at DESC);


--
-- Name: idx_audit_events_tenant_entity; Type: INDEX; Schema: auditoria; Owner: -
--

CREATE INDEX idx_audit_events_tenant_entity ON auditoria.audit_events USING btree (tenant_id, entity_type, entity_id);


--
-- Name: idx_audit_events_tenant_service; Type: INDEX; Schema: auditoria; Owner: -
--

CREATE INDEX idx_audit_events_tenant_service ON auditoria.audit_events USING btree (tenant_id, service_name, module_name);


--
-- Name: idx_audit_logs_created_at; Type: INDEX; Schema: auditoria; Owner: -
--

CREATE INDEX idx_audit_logs_created_at ON auditoria.audit_logs USING btree (created_at);


--
-- Name: idx_audit_logs_modulo; Type: INDEX; Schema: auditoria; Owner: -
--

CREATE INDEX idx_audit_logs_modulo ON auditoria.audit_logs USING btree (modulo);


--
-- Name: idx_audit_logs_tenant_id; Type: INDEX; Schema: auditoria; Owner: -
--

CREATE INDEX idx_audit_logs_tenant_id ON auditoria.audit_logs USING btree (tenant_id);


--
-- Name: idx_audit_logs_user_id; Type: INDEX; Schema: auditoria; Owner: -
--

CREATE INDEX idx_audit_logs_user_id ON auditoria.audit_logs USING btree (user_id);


--
-- Name: uq_audit_events_hash; Type: INDEX; Schema: auditoria; Owner: -
--

CREATE UNIQUE INDEX uq_audit_events_hash ON auditoria.audit_events USING btree (event_hash);


--
-- Name: idx_api_keys_key_prefix; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_api_keys_key_prefix ON auth.api_keys USING btree (key_prefix);


--
-- Name: idx_api_keys_tenant_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_api_keys_tenant_id ON auth.api_keys USING btree (tenant_id);


--
-- Name: idx_cargos_tenant_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_cargos_tenant_id ON auth.cargos USING btree (tenant_id);


--
-- Name: idx_login_history_tenant_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_login_history_tenant_id ON auth.login_history USING btree (tenant_id);


--
-- Name: idx_password_resets_user_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_password_resets_user_id ON auth.password_resets USING btree (user_id);


--
-- Name: idx_permissoes_cargo_cargo_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_permissoes_cargo_cargo_id ON auth.permissoes_cargo USING btree (cargo_id);


--
-- Name: idx_permissoes_diretas_user_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_permissoes_diretas_user_id ON auth.permissoes_diretas USING btree (user_id);


--
-- Name: idx_permissoes_tipo_tipo; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_permissoes_tipo_tipo ON auth.permissoes_tipo USING btree (tipo);


--
-- Name: idx_sessions_ativa; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_sessions_ativa ON auth.sessions USING btree (ativa);


--
-- Name: idx_sessions_token_hash; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_sessions_token_hash ON auth.sessions USING btree (token_hash);


--
-- Name: idx_sessions_user_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_sessions_user_id ON auth.sessions USING btree (user_id);


--
-- Name: idx_users_tenant_id; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_users_tenant_id ON auth.users USING btree (tenant_id);


--
-- Name: idx_role_permissions_role_id; Type: INDEX; Schema: autorizacao; Owner: -
--

CREATE INDEX idx_role_permissions_role_id ON autorizacao.role_permissions USING btree (role_id);


--
-- Name: idx_roles_tenant_id; Type: INDEX; Schema: autorizacao; Owner: -
--

CREATE INDEX idx_roles_tenant_id ON autorizacao.roles USING btree (tenant_id);


--
-- Name: idx_user_roles_role_id; Type: INDEX; Schema: autorizacao; Owner: -
--

CREATE INDEX idx_user_roles_role_id ON autorizacao.user_roles USING btree (role_id);


--
-- Name: idx_user_roles_user_id; Type: INDEX; Schema: autorizacao; Owner: -
--

CREATE INDEX idx_user_roles_user_id ON autorizacao.user_roles USING btree (user_id);


--
-- Name: idx_cost_center_allocations_source; Type: INDEX; Schema: centros_custo; Owner: -
--

CREATE INDEX idx_cost_center_allocations_source ON centros_custo.cost_center_allocations USING btree (tenant_id, source_service, source_type, source_id);


--
-- Name: idx_cost_center_allocations_tenant; Type: INDEX; Schema: centros_custo; Owner: -
--

CREATE INDEX idx_cost_center_allocations_tenant ON centros_custo.cost_center_allocations USING btree (tenant_id, created_at DESC);


--
-- Name: idx_cost_center_budgets_tenant; Type: INDEX; Schema: centros_custo; Owner: -
--

CREATE INDEX idx_cost_center_budgets_tenant ON centros_custo.cost_center_budgets USING btree (tenant_id, ano, mes);


--
-- Name: idx_cost_centers_tenant; Type: INDEX; Schema: centros_custo; Owner: -
--

CREATE INDEX idx_cost_centers_tenant ON centros_custo.cost_centers USING btree (tenant_id, activo);


--
-- Name: idx_customer_addresses_customer_id; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customer_addresses_customer_id ON clientes.customer_addresses USING btree (customer_id);


--
-- Name: idx_customer_contacts_customer_id; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customer_contacts_customer_id ON clientes.customer_contacts USING btree (customer_id);


--
-- Name: idx_customer_discounts_customer_id; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customer_discounts_customer_id ON clientes.customer_discounts USING btree (customer_id);


--
-- Name: idx_customer_documents_customer_id; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customer_documents_customer_id ON clientes.customer_documents USING btree (customer_id);


--
-- Name: idx_customer_groups_tenant_id; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customer_groups_tenant_id ON clientes.customer_groups USING btree (tenant_id);


--
-- Name: idx_customer_history_customer_created; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customer_history_customer_created ON clientes.customer_history USING btree (customer_id, created_at DESC);


--
-- Name: idx_customer_history_customer_id; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customer_history_customer_id ON clientes.customer_history USING btree (customer_id);


--
-- Name: idx_customer_notes_customer_id; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customer_notes_customer_id ON clientes.customer_notes USING btree (customer_id);


--
-- Name: idx_customer_payments_customer_id; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customer_payments_customer_id ON clientes.customer_payments USING btree (customer_id);


--
-- Name: idx_customer_payments_tenant_pago_em; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customer_payments_tenant_pago_em ON clientes.customer_payments USING btree (tenant_id, pago_em DESC);


--
-- Name: idx_customer_tag_links_customer_id; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customer_tag_links_customer_id ON clientes.customer_tag_links USING btree (customer_id);


--
-- Name: idx_customers_group_id; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customers_group_id ON clientes.customers USING btree (customer_group_id);


--
-- Name: idx_customers_tenant_estado; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customers_tenant_estado ON clientes.customers USING btree (tenant_id, estado);


--
-- Name: idx_customers_tenant_id; Type: INDEX; Schema: clientes; Owner: -
--

CREATE INDEX idx_customers_tenant_id ON clientes.customers USING btree (tenant_id);


--
-- Name: idx_goods_receipt_items_receipt; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_goods_receipt_items_receipt ON compras.goods_receipt_items USING btree (goods_receipt_id);


--
-- Name: idx_goods_receipts_tenant_date; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_goods_receipts_tenant_date ON compras.goods_receipts USING btree (tenant_id, receipt_date);


--
-- Name: idx_purchase_invoice_items_invoice; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_purchase_invoice_items_invoice ON compras.purchase_invoice_items USING btree (purchase_invoice_id);


--
-- Name: idx_purchase_invoices_tenant_status; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_purchase_invoices_tenant_status ON compras.purchase_invoices USING btree (tenant_id, status, due_date);


--
-- Name: idx_purchase_order_items_order; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_purchase_order_items_order ON compras.purchase_order_items USING btree (purchase_order_id);


--
-- Name: idx_purchase_orders_supplier; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_purchase_orders_supplier ON compras.purchase_orders USING btree (supplier_id);


--
-- Name: idx_purchase_orders_tenant_status; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_purchase_orders_tenant_status ON compras.purchase_orders USING btree (tenant_id, status);


--
-- Name: idx_purchase_payment_items_payment; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_purchase_payment_items_payment ON compras.purchase_payment_items USING btree (purchase_payment_id);


--
-- Name: idx_purchase_payments_tenant_date; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_purchase_payments_tenant_date ON compras.purchase_payments USING btree (tenant_id, payment_date DESC);


--
-- Name: idx_purchase_request_items_request; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_purchase_request_items_request ON compras.purchase_request_items USING btree (purchase_request_id);


--
-- Name: idx_purchase_requests_tenant_status; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_purchase_requests_tenant_status ON compras.purchase_requests USING btree (tenant_id, status, request_date DESC);


--
-- Name: idx_purchase_return_items_return; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_purchase_return_items_return ON compras.purchase_return_items USING btree (purchase_return_id);


--
-- Name: idx_purchase_returns_tenant_date; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_purchase_returns_tenant_date ON compras.purchase_returns USING btree (tenant_id, return_date);


--
-- Name: idx_supplier_groups_tenant; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_supplier_groups_tenant ON compras.supplier_groups USING btree (tenant_id);


--
-- Name: idx_suppliers_tenant; Type: INDEX; Schema: compras; Owner: -
--

CREATE INDEX idx_suppliers_tenant ON compras.suppliers USING btree (tenant_id);


--
-- Name: idx_accounting_budgets_account; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_accounting_budgets_account ON contabilidade.accounting_budgets USING btree (chart_account_id);


--
-- Name: idx_accounting_budgets_tenant; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_accounting_budgets_tenant ON contabilidade.accounting_budgets USING btree (tenant_id, fiscal_year_id);


--
-- Name: idx_accounting_journals_tenant; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_accounting_journals_tenant ON contabilidade.accounting_journals USING btree (tenant_id, codigo);


--
-- Name: idx_accounting_periods_tenant; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_accounting_periods_tenant ON contabilidade.fiscal_periods USING btree (tenant_id, ano, mes);


--
-- Name: idx_accounting_reports_tenant; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_accounting_reports_tenant ON contabilidade.accounting_reports USING btree (tenant_id, tipo, gerado_em DESC);


--
-- Name: idx_chart_of_accounts_account_type; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_chart_of_accounts_account_type ON contabilidade.chart_of_accounts USING btree (tenant_id, account_type_id);


--
-- Name: idx_chart_of_accounts_tenant; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_chart_of_accounts_tenant ON contabilidade.chart_of_accounts USING btree (tenant_id, codigo);


--
-- Name: idx_depreciation_entries_asset; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_depreciation_entries_asset ON contabilidade.depreciation_entries USING btree (fixed_asset_id);


--
-- Name: idx_depreciation_entries_journal; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_depreciation_entries_journal ON contabilidade.depreciation_entries USING btree (journal_entry_id);


--
-- Name: idx_depreciation_entries_period; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_depreciation_entries_period ON contabilidade.depreciation_entries USING btree (fiscal_period_id);


--
-- Name: idx_depreciation_entries_tenant; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_depreciation_entries_tenant ON contabilidade.depreciation_entries USING btree (tenant_id, status);


--
-- Name: idx_fiscal_periods_fiscal_year; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_fiscal_periods_fiscal_year ON contabilidade.fiscal_periods USING btree (fiscal_year_id);


--
-- Name: idx_fixed_assets_account; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_fixed_assets_account ON contabilidade.fixed_assets USING btree (chart_account_id);


--
-- Name: idx_fixed_assets_tenant; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_fixed_assets_tenant ON contabilidade.fixed_assets USING btree (tenant_id, estado);


--
-- Name: idx_journal_entries_fiscal_period; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_journal_entries_fiscal_period ON contabilidade.journal_entries USING btree (tenant_id, fiscal_period_id);


--
-- Name: idx_journal_entries_status; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_journal_entries_status ON contabilidade.journal_entries USING btree (tenant_id, status);


--
-- Name: idx_journal_entries_tenant_date; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_journal_entries_tenant_date ON contabilidade.journal_entries USING btree (tenant_id, entry_date);


--
-- Name: idx_journal_entry_lines_account; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_journal_entry_lines_account ON contabilidade.journal_entry_lines USING btree (account_id);


--
-- Name: idx_journal_entry_lines_entry; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_journal_entry_lines_entry ON contabilidade.journal_entry_lines USING btree (journal_entry_id);


--
-- Name: idx_period_closing_checks_closing; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_period_closing_checks_closing ON contabilidade.period_closing_checks USING btree (period_closing_id);


--
-- Name: idx_period_closings_status; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_period_closings_status ON contabilidade.period_closings USING btree (tenant_id, status);


--
-- Name: idx_period_closings_tenant; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE INDEX idx_period_closings_tenant ON contabilidade.period_closings USING btree (tenant_id, fiscal_period_id);


--
-- Name: uq_accounting_budgets_anual; Type: INDEX; Schema: contabilidade; Owner: -
--

CREATE UNIQUE INDEX uq_accounting_budgets_anual ON contabilidade.accounting_budgets USING btree (tenant_id, chart_account_id, fiscal_year_id) WHERE (mes IS NULL);


--
-- Name: idx_atividades_concluida; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_atividades_concluida ON crm.atividades USING btree (concluida);


--
-- Name: idx_atividades_data; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_atividades_data ON crm.atividades USING btree (data_atividade);


--
-- Name: idx_atividades_lead_id; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_atividades_lead_id ON crm.atividades USING btree (lead_id);


--
-- Name: idx_atividades_oportunidade_id; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_atividades_oportunidade_id ON crm.atividades USING btree (oportunidade_id);


--
-- Name: idx_atividades_tenant_id; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_atividades_tenant_id ON crm.atividades USING btree (tenant_id);


--
-- Name: idx_atividades_tipo; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_atividades_tipo ON crm.atividades USING btree (tipo);


--
-- Name: idx_crm_activities_tenant; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_crm_activities_tenant ON crm.crm_activities USING btree (tenant_id, status);


--
-- Name: idx_crm_lead_sources_tenant; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_crm_lead_sources_tenant ON crm.crm_lead_sources USING btree (tenant_id);


--
-- Name: idx_crm_leads_tenant_estado; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_crm_leads_tenant_estado ON crm.crm_leads USING btree (tenant_id, estado);


--
-- Name: idx_crm_opportunities_stage; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_crm_opportunities_stage ON crm.crm_opportunities USING btree (stage_id);


--
-- Name: idx_crm_opportunities_tenant_estado; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_crm_opportunities_tenant_estado ON crm.crm_opportunities USING btree (tenant_id, estado);


--
-- Name: idx_crm_pipeline_stages_pipeline; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_crm_pipeline_stages_pipeline ON crm.crm_pipeline_stages USING btree (pipeline_id, ordem);


--
-- Name: idx_crm_pipelines_tenant; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_crm_pipelines_tenant ON crm.crm_pipelines USING btree (tenant_id);


--
-- Name: idx_leads_email; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_leads_email ON crm.leads USING btree (email);


--
-- Name: idx_leads_estado; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_leads_estado ON crm.leads USING btree (estado);


--
-- Name: idx_leads_responsavel; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_leads_responsavel ON crm.leads USING btree (responsavel);


--
-- Name: idx_leads_tenant_id; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_leads_tenant_id ON crm.leads USING btree (tenant_id);


--
-- Name: idx_oportunidades_cliente_id; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_oportunidades_cliente_id ON crm.oportunidades USING btree (cliente_id);


--
-- Name: idx_oportunidades_estagio; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_oportunidades_estagio ON crm.oportunidades USING btree (estagio);


--
-- Name: idx_oportunidades_lead_id; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_oportunidades_lead_id ON crm.oportunidades USING btree (lead_id);


--
-- Name: idx_oportunidades_responsavel; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_oportunidades_responsavel ON crm.oportunidades USING btree (responsavel);


--
-- Name: idx_oportunidades_tenant_id; Type: INDEX; Schema: crm; Owner: -
--

CREATE INDEX idx_oportunidades_tenant_id ON crm.oportunidades USING btree (tenant_id);


--
-- Name: idx_company_addresses_company_id; Type: INDEX; Schema: empresa; Owner: -
--

CREATE INDEX idx_company_addresses_company_id ON empresa.company_addresses USING btree (company_id);


--
-- Name: idx_company_banks_company_id; Type: INDEX; Schema: empresa; Owner: -
--

CREATE INDEX idx_company_banks_company_id ON empresa.company_banks USING btree (company_id);


--
-- Name: idx_company_branches_company_id; Type: INDEX; Schema: empresa; Owner: -
--

CREATE INDEX idx_company_branches_company_id ON empresa.company_branches USING btree (company_id);


--
-- Name: idx_company_contacts_company_id; Type: INDEX; Schema: empresa; Owner: -
--

CREATE INDEX idx_company_contacts_company_id ON empresa.company_contacts USING btree (company_id);


--
-- Name: idx_company_documents_company_id; Type: INDEX; Schema: empresa; Owner: -
--

CREATE INDEX idx_company_documents_company_id ON empresa.company_documents USING btree (company_id);


--
-- Name: idx_company_licenses_company_id; Type: INDEX; Schema: empresa; Owner: -
--

CREATE INDEX idx_company_licenses_company_id ON empresa.company_licenses USING btree (company_id);


--
-- Name: idx_company_settings_company_id; Type: INDEX; Schema: empresa; Owner: -
--

CREATE INDEX idx_company_settings_company_id ON empresa.company_settings USING btree (company_id);


--
-- Name: idx_company_users_company_id; Type: INDEX; Schema: empresa; Owner: -
--

CREATE INDEX idx_company_users_company_id ON empresa.company_users USING btree (company_id);


--
-- Name: idx_company_users_user_id; Type: INDEX; Schema: empresa; Owner: -
--

CREATE INDEX idx_company_users_user_id ON empresa.company_users USING btree (user_id);


--
-- Name: idx_company_addresses_company_id; Type: INDEX; Schema: empresas; Owner: -
--

CREATE INDEX idx_company_addresses_company_id ON empresas.company_addresses USING btree (company_id);


--
-- Name: idx_company_banks_company_id; Type: INDEX; Schema: empresas; Owner: -
--

CREATE INDEX idx_company_banks_company_id ON empresas.company_banks USING btree (company_id);


--
-- Name: idx_company_branches_company_id; Type: INDEX; Schema: empresas; Owner: -
--

CREATE INDEX idx_company_branches_company_id ON empresas.company_branches USING btree (company_id);


--
-- Name: idx_company_contacts_company_id; Type: INDEX; Schema: empresas; Owner: -
--

CREATE INDEX idx_company_contacts_company_id ON empresas.company_contacts USING btree (company_id);


--
-- Name: idx_company_documents_company_id; Type: INDEX; Schema: empresas; Owner: -
--

CREATE INDEX idx_company_documents_company_id ON empresas.company_documents USING btree (company_id);


--
-- Name: idx_company_licenses_company_id; Type: INDEX; Schema: empresas; Owner: -
--

CREATE INDEX idx_company_licenses_company_id ON empresas.company_licenses USING btree (company_id);


--
-- Name: idx_company_settings_company_id; Type: INDEX; Schema: empresas; Owner: -
--

CREATE INDEX idx_company_settings_company_id ON empresas.company_settings USING btree (company_id);


--
-- Name: idx_company_users_company_id; Type: INDEX; Schema: empresas; Owner: -
--

CREATE INDEX idx_company_users_company_id ON empresas.company_users USING btree (company_id);


--
-- Name: idx_credit_notes_invoice; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_credit_notes_invoice ON faturacao.credit_notes USING btree (invoice_id);


--
-- Name: idx_credit_notes_tenant; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_credit_notes_tenant ON faturacao.credit_notes USING btree (tenant_id, status);


--
-- Name: idx_invoice_receipts_invoice; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_invoice_receipts_invoice ON faturacao.invoice_receipts USING btree (invoice_id);


--
-- Name: idx_invoice_series_tenant; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_invoice_series_tenant ON faturacao.invoice_series USING btree (tenant_id, tipo, ano);


--
-- Name: idx_invoices_customer; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_invoices_customer ON faturacao.invoices USING btree (customer_id);


--
-- Name: idx_invoices_due_date; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_invoices_due_date ON faturacao.invoices USING btree (due_date) WHERE ((status)::text <> ALL ((ARRAY['paga'::character varying, 'cancelada'::character varying])::text[]));


--
-- Name: idx_invoices_order; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_invoices_order ON faturacao.invoices USING btree (sales_order_id);


--
-- Name: idx_invoices_tenant; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_invoices_tenant ON faturacao.invoices USING btree (tenant_id, status);


--
-- Name: idx_receipts_invoice; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_receipts_invoice ON faturacao.invoice_receipts USING btree (invoice_id);


--
-- Name: idx_sales_deliveries_order; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_sales_deliveries_order ON faturacao.sales_deliveries USING btree (sales_order_id);


--
-- Name: idx_sales_orders_customer; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_sales_orders_customer ON faturacao.sales_orders USING btree (customer_id);


--
-- Name: idx_sales_orders_quote; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_sales_orders_quote ON faturacao.sales_orders USING btree (sales_quote_id);


--
-- Name: idx_sales_orders_tenant; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_sales_orders_tenant ON faturacao.sales_orders USING btree (tenant_id, status);


--
-- Name: idx_sales_quotes_customer; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_sales_quotes_customer ON faturacao.sales_quotes USING btree (customer_id);


--
-- Name: idx_sales_quotes_tenant; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_sales_quotes_tenant ON faturacao.sales_quotes USING btree (tenant_id, status);


--
-- Name: idx_sales_returns_invoice; Type: INDEX; Schema: faturacao; Owner: -
--

CREATE INDEX idx_sales_returns_invoice ON faturacao.sales_returns USING btree (invoice_id);


--
-- Name: idx_ap_tenant_status; Type: INDEX; Schema: financeiro; Owner: -
--

CREATE INDEX idx_ap_tenant_status ON financeiro.accounts_payable USING btree (tenant_id, status);


--
-- Name: idx_ap_vencimento; Type: INDEX; Schema: financeiro; Owner: -
--

CREATE INDEX idx_ap_vencimento ON financeiro.accounts_payable USING btree (data_vencimento);


--
-- Name: idx_ar_customer; Type: INDEX; Schema: financeiro; Owner: -
--

CREATE INDEX idx_ar_customer ON financeiro.accounts_receivable USING btree (customer_id);


--
-- Name: idx_ar_tenant_status; Type: INDEX; Schema: financeiro; Owner: -
--

CREATE INDEX idx_ar_tenant_status ON financeiro.accounts_receivable USING btree (tenant_id, status);


--
-- Name: idx_ar_vencimento; Type: INDEX; Schema: financeiro; Owner: -
--

CREATE INDEX idx_ar_vencimento ON financeiro.accounts_receivable USING btree (data_vencimento);


--
-- Name: idx_budgets_tenant; Type: INDEX; Schema: financeiro; Owner: -
--

CREATE INDEX idx_budgets_tenant ON financeiro.financial_budgets USING btree (tenant_id, ano);


--
-- Name: idx_cashflow_tenant_data; Type: INDEX; Schema: financeiro; Owner: -
--

CREATE INDEX idx_cashflow_tenant_data ON financeiro.cash_flow_entries USING btree (tenant_id, data);


--
-- Name: idx_financial_categories_tenant; Type: INDEX; Schema: financeiro; Owner: -
--

CREATE INDEX idx_financial_categories_tenant ON financeiro.financial_categories USING btree (tenant_id);


--
-- Name: idx_payment_methods_tenant; Type: INDEX; Schema: financeiro; Owner: -
--

CREATE INDEX idx_payment_methods_tenant ON financeiro.payment_methods USING btree (tenant_id);


--
-- Name: idx_payments_data; Type: INDEX; Schema: financeiro; Owner: -
--

CREATE INDEX idx_payments_data ON financeiro.payments USING btree (tenant_id, data_pagamento);


--
-- Name: idx_payments_referencia; Type: INDEX; Schema: financeiro; Owner: -
--

CREATE INDEX idx_payments_referencia ON financeiro.payments USING btree (referencia_tipo, referencia_id);


--
-- Name: idx_payments_tenant; Type: INDEX; Schema: financeiro; Owner: -
--

CREATE INDEX idx_payments_tenant ON financeiro.payments USING btree (tenant_id);


--
-- Name: idx_school_assignments_class; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_assignments_class ON gestao_escolar.school_teacher_assignments USING btree (class_id, subject_id);


--
-- Name: idx_school_attendance_filters; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_attendance_filters ON gestao_escolar.school_attendance USING btree (tenant_id, class_id, attendance_date);


--
-- Name: idx_school_attendance_tenant; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_attendance_tenant ON gestao_escolar.school_attendance USING btree (tenant_id, attendance_date);


--
-- Name: idx_school_classes_tenant; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_classes_tenant ON gestao_escolar.school_classes USING btree (tenant_id, ano_lectivo);


--
-- Name: idx_school_classes_tenant_year; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_classes_tenant_year ON gestao_escolar.school_classes USING btree (tenant_id, school_year_id);


--
-- Name: idx_school_enrollments_tenant; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_enrollments_tenant ON gestao_escolar.school_enrollments USING btree (tenant_id, status);


--
-- Name: idx_school_enrollments_tenant_year; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_enrollments_tenant_year ON gestao_escolar.school_enrollments USING btree (tenant_id, school_year_id, status);


--
-- Name: idx_school_fees_filters; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_fees_filters ON gestao_escolar.school_fees USING btree (tenant_id, student_id, status, data_vencimento);


--
-- Name: idx_school_fees_tenant; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_fees_tenant ON gestao_escolar.school_fees USING btree (tenant_id, status);


--
-- Name: idx_school_grades_student; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_grades_student ON gestao_escolar.school_grades USING btree (student_id);


--
-- Name: idx_school_guardians_student; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_guardians_student ON gestao_escolar.school_guardians USING btree (student_id);


--
-- Name: idx_school_loans_status; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_loans_status ON gestao_escolar.school_library_loans USING btree (tenant_id, status, devolucao_prevista);


--
-- Name: idx_school_messages_tenant_status; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_messages_tenant_status ON gestao_escolar.school_messages USING btree (tenant_id, status);


--
-- Name: idx_school_payments_fee; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_payments_fee ON gestao_escolar.school_payments USING btree (school_fee_id, status);


--
-- Name: idx_school_students_tenant; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_students_tenant ON gestao_escolar.school_students USING btree (tenant_id, estado);


--
-- Name: idx_school_students_tenant_estado; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_students_tenant_estado ON gestao_escolar.school_students USING btree (tenant_id, estado);


--
-- Name: idx_school_terms_year; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_terms_year ON gestao_escolar.school_terms USING btree (school_year_id);


--
-- Name: idx_school_years_tenant; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE INDEX idx_school_years_tenant ON gestao_escolar.school_years USING btree (tenant_id, status);


--
-- Name: uq_school_attendance_entry; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE UNIQUE INDEX uq_school_attendance_entry ON gestao_escolar.school_attendance USING btree (tenant_id, class_id, student_id, attendance_date, COALESCE(subject_id, (0)::bigint));


--
-- Name: uq_school_student_class_year; Type: INDEX; Schema: gestao_escolar; Owner: -
--

CREATE UNIQUE INDEX uq_school_student_class_year ON gestao_escolar.school_enrollments USING btree (student_id, class_id, COALESCE(school_year_id, (0)::bigint));


--
-- Name: idx_tax_certificates_entity; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_certificates_entity ON impostos.tax_certificates USING btree (tenant_id, entity_type, entity_id);


--
-- Name: idx_tax_certificates_validade; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_certificates_validade ON impostos.tax_certificates USING btree (tenant_id, validade) WHERE ativo;


--
-- Name: idx_tax_exemptions_active; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_exemptions_active ON impostos.tax_exemptions USING btree (tenant_id, entity_type, entity_id, data_inicio, validade) WHERE ativo;


--
-- Name: idx_tax_exemptions_entity; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_exemptions_entity ON impostos.tax_exemptions USING btree (entity_type, entity_id);


--
-- Name: idx_tax_exemptions_tenant; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_exemptions_tenant ON impostos.tax_exemptions USING btree (tenant_id);


--
-- Name: idx_tax_regimes_tenant; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_regimes_tenant ON impostos.tax_regimes USING btree (tenant_id);


--
-- Name: idx_tax_return_lines_reference; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_return_lines_reference ON impostos.tax_return_lines USING btree (referencia_tipo, referencia_id);


--
-- Name: idx_tax_return_lines_return; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_return_lines_return ON impostos.tax_return_lines USING btree (tax_return_id);


--
-- Name: idx_tax_returns_tenant; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_returns_tenant ON impostos.tax_returns USING btree (tenant_id);


--
-- Name: idx_tax_rules_tax; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_rules_tax ON impostos.tax_rules USING btree (tax_id, valor_minimo);


--
-- Name: idx_tax_transactions_period; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_transactions_period ON impostos.tax_transactions USING btree (fiscal_period_id);


--
-- Name: idx_tax_transactions_ref; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_transactions_ref ON impostos.tax_transactions USING btree (referencia_tipo, referencia_id);


--
-- Name: idx_tax_transactions_tax; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_transactions_tax ON impostos.tax_transactions USING btree (tax_id);


--
-- Name: idx_tax_transactions_tenant; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_tax_transactions_tenant ON impostos.tax_transactions USING btree (tenant_id, transaction_date);


--
-- Name: idx_taxes_tax_group; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_taxes_tax_group ON impostos.taxes USING btree (tenant_id, tax_group_id);


--
-- Name: idx_taxes_tenant; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_taxes_tenant ON impostos.taxes USING btree (tenant_id);


--
-- Name: idx_wtt_tenant; Type: INDEX; Schema: impostos; Owner: -
--

CREATE INDEX idx_wtt_tenant ON impostos.withholding_tax_transactions USING btree (tenant_id);


--
-- Name: uq_tax_regime_principal; Type: INDEX; Schema: impostos; Owner: -
--

CREATE UNIQUE INDEX uq_tax_regime_principal ON impostos.tax_regimes USING btree (tenant_id) WHERE (principal AND ativo);


--
-- Name: uq_tax_returns_original; Type: INDEX; Schema: impostos; Owner: -
--

CREATE UNIQUE INDEX uq_tax_returns_original ON impostos.tax_returns USING btree (tenant_id, periodo, tipo) WHERE (substitui_id IS NULL);


--
-- Name: uq_tax_returns_substituicao; Type: INDEX; Schema: impostos; Owner: -
--

CREATE UNIQUE INDEX uq_tax_returns_substituicao ON impostos.tax_returns USING btree (substitui_id) WHERE (substitui_id IS NOT NULL);


--
-- Name: idx_logistics_drivers_tenant; Type: INDEX; Schema: logistica; Owner: -
--

CREATE INDEX idx_logistics_drivers_tenant ON logistica.logistics_drivers USING btree (tenant_id, activo);


--
-- Name: idx_logistics_routes_tenant; Type: INDEX; Schema: logistica; Owner: -
--

CREATE INDEX idx_logistics_routes_tenant ON logistica.logistics_routes USING btree (tenant_id, activo);


--
-- Name: idx_logistics_shipments_tenant_status; Type: INDEX; Schema: logistica; Owner: -
--

CREATE INDEX idx_logistics_shipments_tenant_status ON logistica.logistics_shipments USING btree (tenant_id, status);


--
-- Name: idx_logistics_tracking_events_tenant; Type: INDEX; Schema: logistica; Owner: -
--

CREATE INDEX idx_logistics_tracking_events_tenant ON logistica.logistics_tracking_events USING btree (tenant_id, event_time DESC);


--
-- Name: idx_logistics_tracking_shipment; Type: INDEX; Schema: logistica; Owner: -
--

CREATE INDEX idx_logistics_tracking_shipment ON logistica.delivery_tracking USING btree (shipment_id, registado_em DESC);


--
-- Name: idx_logistics_vehicles_tenant; Type: INDEX; Schema: logistica; Owner: -
--

CREATE INDEX idx_logistics_vehicles_tenant ON logistica.logistics_vehicles USING btree (tenant_id, activo);


--
-- Name: idx_exchange_rates_pair; Type: INDEX; Schema: multi_moeda; Owner: -
--

CREATE INDEX idx_exchange_rates_pair ON multi_moeda.exchange_rates USING btree (tenant_id, base_currency_id, quote_currency_id, effective_date DESC);


--
-- Name: idx_exchange_rates_tenant_date; Type: INDEX; Schema: multi_moeda; Owner: -
--

CREATE INDEX idx_exchange_rates_tenant_date ON multi_moeda.exchange_rates USING btree (tenant_id, effective_date DESC);


--
-- Name: idx_tenant_currencies_tenant; Type: INDEX; Schema: multi_moeda; Owner: -
--

CREATE INDEX idx_tenant_currencies_tenant ON multi_moeda.tenant_currencies USING btree (tenant_id, is_base);


--
-- Name: idx_notification_channels_tenant; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX idx_notification_channels_tenant ON notifications.notification_channels USING btree (tenant_id, activo);


--
-- Name: idx_notification_messages_tenant_status; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX idx_notification_messages_tenant_status ON notifications.notification_messages USING btree (tenant_id, status, created_at DESC);


--
-- Name: idx_notification_templates_tenant; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX idx_notification_templates_tenant ON notifications.notification_templates USING btree (tenant_id, activo);


--
-- Name: idx_pos_catalog_items_tenant; Type: INDEX; Schema: pos; Owner: -
--

CREATE INDEX idx_pos_catalog_items_tenant ON pos.pos_catalog_items USING btree (tenant_id, activo);


--
-- Name: idx_pos_sale_items_sale; Type: INDEX; Schema: pos; Owner: -
--

CREATE INDEX idx_pos_sale_items_sale ON pos.pos_sale_items USING btree (pos_sale_id);


--
-- Name: idx_pos_sale_payments_sale; Type: INDEX; Schema: pos; Owner: -
--

CREATE INDEX idx_pos_sale_payments_sale ON pos.pos_sale_payments USING btree (pos_sale_id);


--
-- Name: idx_pos_sales_session; Type: INDEX; Schema: pos; Owner: -
--

CREATE INDEX idx_pos_sales_session ON pos.pos_sales USING btree (pos_session_id);


--
-- Name: idx_pos_sales_tenant; Type: INDEX; Schema: pos; Owner: -
--

CREATE INDEX idx_pos_sales_tenant ON pos.pos_sales USING btree (tenant_id, status, created_at DESC);


--
-- Name: idx_pos_sessions_tenant; Type: INDEX; Schema: pos; Owner: -
--

CREATE INDEX idx_pos_sessions_tenant ON pos.pos_sessions USING btree (tenant_id, status);


--
-- Name: idx_pos_terminals_tenant; Type: INDEX; Schema: pos; Owner: -
--

CREATE INDEX idx_pos_terminals_tenant ON pos.pos_terminals USING btree (tenant_id);


--
-- Name: idx_product_attribute_values_product_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_attribute_values_product_id ON produtos.product_attribute_values USING btree (product_id);


--
-- Name: idx_product_barcodes_product; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_barcodes_product ON produtos.product_barcodes USING btree (product_id);


--
-- Name: idx_product_barcodes_product_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_barcodes_product_id ON produtos.product_barcodes USING btree (product_id);


--
-- Name: idx_product_brands_tenant; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_brands_tenant ON produtos.product_brands USING btree (tenant_id);


--
-- Name: idx_product_brands_tenant_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_brands_tenant_id ON produtos.product_brands USING btree (tenant_id);


--
-- Name: idx_product_categories_parent; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_categories_parent ON produtos.product_categories USING btree (tenant_id, parent_id);


--
-- Name: idx_product_categories_tenant; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_categories_tenant ON produtos.product_categories USING btree (tenant_id);


--
-- Name: idx_product_categories_tenant_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_categories_tenant_id ON produtos.product_categories USING btree (tenant_id);


--
-- Name: idx_product_discounts_product_active; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_discounts_product_active ON produtos.product_discounts USING btree (product_id, ativo);


--
-- Name: idx_product_discounts_product_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_discounts_product_id ON produtos.product_discounts USING btree (product_id);


--
-- Name: idx_product_images_product_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_images_product_id ON produtos.product_images USING btree (product_id);


--
-- Name: idx_product_kit_items_kit_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_kit_items_kit_id ON produtos.product_kit_items USING btree (product_kit_id);


--
-- Name: idx_product_kits_product_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_kits_product_id ON produtos.product_kits USING btree (product_id);


--
-- Name: idx_product_prices_product; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_prices_product ON produtos.product_prices USING btree (product_id);


--
-- Name: idx_product_prices_product_active; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_prices_product_active ON produtos.product_prices USING btree (product_id, ativo);


--
-- Name: idx_product_prices_product_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_prices_product_id ON produtos.product_prices USING btree (product_id);


--
-- Name: idx_product_subcategories_category_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_subcategories_category_id ON produtos.product_subcategories USING btree (product_category_id);


--
-- Name: idx_product_tag_links_product_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_tag_links_product_id ON produtos.product_tag_links USING btree (product_id);


--
-- Name: idx_product_units_tenant; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_units_tenant ON produtos.product_units USING btree (tenant_id);


--
-- Name: idx_product_units_tenant_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_units_tenant_id ON produtos.product_units USING btree (tenant_id);


--
-- Name: idx_product_variants_product; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_variants_product ON produtos.product_variants USING btree (product_id);


--
-- Name: idx_product_variants_product_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_variants_product_id ON produtos.product_variants USING btree (product_id);


--
-- Name: idx_product_variants_product_sku; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_product_variants_product_sku ON produtos.product_variants USING btree (product_id, sku);


--
-- Name: idx_products_tenant; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_products_tenant ON produtos.products USING btree (tenant_id);


--
-- Name: idx_products_tenant_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_products_tenant_id ON produtos.products USING btree (tenant_id);


--
-- Name: idx_warehouses_tenant; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_warehouses_tenant ON produtos.warehouses USING btree (tenant_id);


--
-- Name: idx_warehouses_tenant_id; Type: INDEX; Schema: produtos; Owner: -
--

CREATE INDEX idx_warehouses_tenant_id ON produtos.warehouses USING btree (tenant_id);


--
-- Name: idx_chat_conversas_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_chat_conversas_tenant ON public.chat_conversas USING btree (tenant_id);


--
-- Name: idx_chat_msg_autor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_chat_msg_autor ON public.chat_mensagens USING btree (autor_id);


--
-- Name: idx_chat_msg_conversa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_chat_msg_conversa ON public.chat_mensagens USING btree (conversa_id, created_at DESC);


--
-- Name: idx_chat_part_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_chat_part_user ON public.chat_participantes USING btree (user_id);


--
-- Name: idx_comunicados_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comunicados_tenant ON public.comunicados USING btree (tenant_id, created_at DESC);


--
-- Name: idx_notif_colab_nao_lida; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notif_colab_nao_lida ON public.notif_colaborador USING btree (user_id) WHERE (NOT lida);


--
-- Name: idx_notif_colab_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notif_colab_user ON public.notif_colaborador USING btree (user_id, created_at DESC);


--
-- Name: idx_candidatura_notas_candidatura_id; Type: INDEX; Schema: recrutamento; Owner: -
--

CREATE INDEX idx_candidatura_notas_candidatura_id ON recrutamento.candidatura_notas USING btree (candidatura_id);


--
-- Name: idx_candidaturas_email; Type: INDEX; Schema: recrutamento; Owner: -
--

CREATE INDEX idx_candidaturas_email ON recrutamento.candidaturas USING btree (email);


--
-- Name: idx_candidaturas_estado; Type: INDEX; Schema: recrutamento; Owner: -
--

CREATE INDEX idx_candidaturas_estado ON recrutamento.candidaturas USING btree (estado);


--
-- Name: idx_candidaturas_tenant_id; Type: INDEX; Schema: recrutamento; Owner: -
--

CREATE INDEX idx_candidaturas_tenant_id ON recrutamento.candidaturas USING btree (tenant_id);


--
-- Name: idx_candidaturas_vaga_id; Type: INDEX; Schema: recrutamento; Owner: -
--

CREATE INDEX idx_candidaturas_vaga_id ON recrutamento.candidaturas USING btree (vaga_id);


--
-- Name: idx_contactos_lido; Type: INDEX; Schema: recrutamento; Owner: -
--

CREATE INDEX idx_contactos_lido ON recrutamento.contactos USING btree (lido);


--
-- Name: idx_contactos_tenant_id; Type: INDEX; Schema: recrutamento; Owner: -
--

CREATE INDEX idx_contactos_tenant_id ON recrutamento.contactos USING btree (tenant_id);


--
-- Name: idx_vagas_ativa; Type: INDEX; Schema: recrutamento; Owner: -
--

CREATE INDEX idx_vagas_ativa ON recrutamento.vagas USING btree (ativa);


--
-- Name: idx_vagas_tenant_id; Type: INDEX; Schema: recrutamento; Owner: -
--

CREATE INDEX idx_vagas_tenant_id ON recrutamento.vagas USING btree (tenant_id);


--
-- Name: idx_employees_department; Type: INDEX; Schema: recursos_humanos; Owner: -
--

CREATE INDEX idx_employees_department ON recursos_humanos.employees USING btree (department_id);


--
-- Name: idx_employees_tenant; Type: INDEX; Schema: recursos_humanos; Owner: -
--

CREATE INDEX idx_employees_tenant ON recursos_humanos.employees USING btree (tenant_id, estado);


--
-- Name: idx_hr_departments_tenant; Type: INDEX; Schema: recursos_humanos; Owner: -
--

CREATE INDEX idx_hr_departments_tenant ON recursos_humanos.hr_departments USING btree (tenant_id);


--
-- Name: idx_payroll_periods_tenant; Type: INDEX; Schema: recursos_humanos; Owner: -
--

CREATE INDEX idx_payroll_periods_tenant ON recursos_humanos.payroll_periods USING btree (tenant_id, ano, mes);


--
-- Name: idx_payroll_run_lines_run; Type: INDEX; Schema: recursos_humanos; Owner: -
--

CREATE INDEX idx_payroll_run_lines_run ON recursos_humanos.payroll_run_lines USING btree (payroll_run_id);


--
-- Name: idx_payroll_runs_tenant; Type: INDEX; Schema: recursos_humanos; Owner: -
--

CREATE INDEX idx_payroll_runs_tenant ON recursos_humanos.payroll_runs USING btree (tenant_id, processamento_em);


--
-- Name: idx_ausencias_estado; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_ausencias_estado ON rh.ausencias USING btree (estado);


--
-- Name: idx_ausencias_funcionario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_ausencias_funcionario_id ON rh.ausencias USING btree (funcionario_id);


--
-- Name: idx_ausencias_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_ausencias_tenant_id ON rh.ausencias USING btree (tenant_id);


--
-- Name: idx_ausencias_tipo_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_ausencias_tipo_id ON rh.ausencias USING btree (tipo_id);


--
-- Name: idx_avaliacao_criterios_avaliacao_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_avaliacao_criterios_avaliacao_id ON rh.avaliacao_criterios USING btree (avaliacao_id);


--
-- Name: idx_avaliacoes_funcionario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_avaliacoes_funcionario_id ON rh.avaliacoes USING btree (funcionario_id);


--
-- Name: idx_avaliacoes_periodo_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_avaliacoes_periodo_id ON rh.avaliacoes USING btree (periodo_id);


--
-- Name: idx_avaliacoes_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_avaliacoes_tenant_id ON rh.avaliacoes USING btree (tenant_id);


--
-- Name: idx_beneficios_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_beneficios_tenant_id ON rh.beneficios USING btree (tenant_id);


--
-- Name: idx_cargos_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_cargos_tenant_id ON rh.cargos USING btree (tenant_id);


--
-- Name: idx_componentes_salariais_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_componentes_salariais_tenant_id ON rh.componentes_salariais USING btree (tenant_id);


--
-- Name: idx_contactos_emergencia_funcionario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_contactos_emergencia_funcionario_id ON rh.contactos_emergencia USING btree (funcionario_id);


--
-- Name: idx_contratos_funcionario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_contratos_funcionario_id ON rh.contratos USING btree (funcionario_id);


--
-- Name: idx_contratos_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_contratos_tenant_id ON rh.contratos USING btree (tenant_id);


--
-- Name: idx_criterios_avaliacao_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_criterios_avaliacao_tenant_id ON rh.criterios_avaliacao USING btree (tenant_id);


--
-- Name: idx_documentos_funcionario_funcionario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_documentos_funcionario_funcionario_id ON rh.documentos_funcionario USING btree (funcionario_id);


--
-- Name: idx_folhas_pagamento_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_folhas_pagamento_tenant_id ON rh.folhas_pagamento USING btree (tenant_id);


--
-- Name: idx_formacoes_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_formacoes_tenant_id ON rh.formacoes USING btree (tenant_id);


--
-- Name: idx_funcionario_beneficios_funcionario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_funcionario_beneficios_funcionario_id ON rh.funcionario_beneficios USING btree (funcionario_id);


--
-- Name: idx_funcionario_componentes_funcionario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_funcionario_componentes_funcionario_id ON rh.funcionario_componentes_salariais USING btree (funcionario_id);


--
-- Name: idx_funcionario_formacoes_formacao_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_funcionario_formacoes_formacao_id ON rh.funcionario_formacoes USING btree (formacao_id);


--
-- Name: idx_funcionario_formacoes_funcionario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_funcionario_formacoes_funcionario_id ON rh.funcionario_formacoes USING btree (funcionario_id);


--
-- Name: idx_funcionarios_cargo_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_funcionarios_cargo_id ON rh.funcionarios USING btree (cargo_id);


--
-- Name: idx_funcionarios_horario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_funcionarios_horario_id ON rh.funcionarios USING btree (horario_id);


--
-- Name: idx_funcionarios_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_funcionarios_tenant_id ON rh.funcionarios USING btree (tenant_id);


--
-- Name: idx_funcionarios_unit_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_funcionarios_unit_id ON rh.funcionarios USING btree (unit_id);


--
-- Name: idx_funcionarios_user_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_funcionarios_user_id ON rh.funcionarios USING btree (user_id);


--
-- Name: idx_historico_salarial_funcionario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_historico_salarial_funcionario_id ON rh.historico_salarial USING btree (funcionario_id);


--
-- Name: idx_horarios_trabalho_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_horarios_trabalho_tenant_id ON rh.horarios_trabalho USING btree (tenant_id);


--
-- Name: idx_justif_funcionario; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_justif_funcionario ON rh.justificacoes USING btree (funcionario_id);


--
-- Name: idx_justif_tenant_estado; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_justif_tenant_estado ON rh.justificacoes USING btree (tenant_id, estado);


--
-- Name: idx_periodos_avaliacao_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_periodos_avaliacao_tenant_id ON rh.periodos_avaliacao USING btree (tenant_id);


--
-- Name: idx_presencas_funcionario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_presencas_funcionario_id ON rh.presencas USING btree (funcionario_id);


--
-- Name: idx_presencas_tenant_data; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_presencas_tenant_data ON rh.presencas USING btree (tenant_id, data);


--
-- Name: idx_processos_disciplinares_estado; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_processos_disciplinares_estado ON rh.processos_disciplinares USING btree (estado);


--
-- Name: idx_processos_disciplinares_funcionario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_processos_disciplinares_funcionario_id ON rh.processos_disciplinares USING btree (funcionario_id);


--
-- Name: idx_processos_disciplinares_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_processos_disciplinares_tenant_id ON rh.processos_disciplinares USING btree (tenant_id);


--
-- Name: idx_recibo_vencimento_itens_recibo_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_recibo_vencimento_itens_recibo_id ON rh.recibo_vencimento_itens USING btree (recibo_id);


--
-- Name: idx_recibos_vencimento_folha_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_recibos_vencimento_folha_id ON rh.recibos_vencimento USING btree (folha_id);


--
-- Name: idx_recibos_vencimento_funcionario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_recibos_vencimento_funcionario_id ON rh.recibos_vencimento USING btree (funcionario_id);


--
-- Name: idx_recibos_vencimento_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_recibos_vencimento_tenant_id ON rh.recibos_vencimento USING btree (tenant_id);


--
-- Name: idx_saldos_ausencia_funcionario_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_saldos_ausencia_funcionario_id ON rh.saldos_ausencia USING btree (funcionario_id);


--
-- Name: idx_tipos_ausencia_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_tipos_ausencia_tenant_id ON rh.tipos_ausencia USING btree (tenant_id);


--
-- Name: idx_unidades_organizacionais_parent_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_unidades_organizacionais_parent_id ON rh.unidades_organizacionais USING btree (parent_id);


--
-- Name: idx_unidades_organizacionais_tenant_id; Type: INDEX; Schema: rh; Owner: -
--

CREATE INDEX idx_unidades_organizacionais_tenant_id ON rh.unidades_organizacionais USING btree (tenant_id);


--
-- Name: uq_funcionarios_tenant_numero; Type: INDEX; Schema: rh; Owner: -
--

CREATE UNIQUE INDEX uq_funcionarios_tenant_numero ON rh.funcionarios USING btree (tenant_id, numero_funcionario) WHERE ((numero_funcionario IS NOT NULL) AND ((numero_funcionario)::text <> ''::text));


--
-- Name: idx_security_ip_allowlist_tenant; Type: INDEX; Schema: seguranca; Owner: -
--

CREATE INDEX idx_security_ip_allowlist_tenant ON seguranca.security_ip_allowlist USING btree (tenant_id, activo);


--
-- Name: idx_security_mfa_enrollments_tenant; Type: INDEX; Schema: seguranca; Owner: -
--

CREATE INDEX idx_security_mfa_enrollments_tenant ON seguranca.security_mfa_enrollments USING btree (tenant_id, user_id);


--
-- Name: idx_security_policies_tenant; Type: INDEX; Schema: seguranca; Owner: -
--

CREATE INDEX idx_security_policies_tenant ON seguranca.security_policies USING btree (tenant_id);


--
-- Name: idx_tenant_defaults_tenant; Type: INDEX; Schema: sistema_configuracao; Owner: -
--

CREATE INDEX idx_tenant_defaults_tenant ON sistema_configuracao.tenant_defaults USING btree (tenant_id);


--
-- Name: idx_tenant_document_settings_tenant; Type: INDEX; Schema: sistema_configuracao; Owner: -
--

CREATE INDEX idx_tenant_document_settings_tenant ON sistema_configuracao.tenant_document_settings USING btree (tenant_id, modulo);


--
-- Name: idx_tenant_feature_flags_tenant; Type: INDEX; Schema: sistema_configuracao; Owner: -
--

CREATE INDEX idx_tenant_feature_flags_tenant ON sistema_configuracao.tenant_feature_flags USING btree (tenant_id);


--
-- Name: idx_tenant_integrations_tenant; Type: INDEX; Schema: sistema_configuracao; Owner: -
--

CREATE INDEX idx_tenant_integrations_tenant ON sistema_configuracao.tenant_integrations USING btree (tenant_id);


--
-- Name: idx_stock_alerts_tenant; Type: INDEX; Schema: stock; Owner: -
--

CREATE INDEX idx_stock_alerts_tenant ON stock.stock_alerts USING btree (tenant_id);


--
-- Name: idx_stock_alerts_tenant_status; Type: INDEX; Schema: stock; Owner: -
--

CREATE INDEX idx_stock_alerts_tenant_status ON stock.stock_alerts USING btree (tenant_id, status);


--
-- Name: idx_stock_batches_expiry; Type: INDEX; Schema: stock; Owner: -
--

CREATE INDEX idx_stock_batches_expiry ON stock.stock_batches USING btree (expiry_date);


--
-- Name: idx_stock_counts_tenant_status; Type: INDEX; Schema: stock; Owner: -
--

CREATE INDEX idx_stock_counts_tenant_status ON stock.stock_counts USING btree (tenant_id, status);


--
-- Name: idx_stock_items_product; Type: INDEX; Schema: stock; Owner: -
--

CREATE INDEX idx_stock_items_product ON stock.stock_items USING btree (product_id);


--
-- Name: idx_stock_items_product_warehouse; Type: INDEX; Schema: stock; Owner: -
--

CREATE INDEX idx_stock_items_product_warehouse ON stock.stock_items USING btree (tenant_id, product_id, warehouse_id);


--
-- Name: idx_stock_items_tenant; Type: INDEX; Schema: stock; Owner: -
--

CREATE INDEX idx_stock_items_tenant ON stock.stock_items USING btree (tenant_id);


--
-- Name: idx_stock_movements_date; Type: INDEX; Schema: stock; Owner: -
--

CREATE INDEX idx_stock_movements_date ON stock.stock_movements USING btree (tenant_id, movement_date);


--
-- Name: idx_stock_movements_item; Type: INDEX; Schema: stock; Owner: -
--

CREATE INDEX idx_stock_movements_item ON stock.stock_movements USING btree (stock_item_id);


--
-- Name: idx_stock_movements_tenant; Type: INDEX; Schema: stock; Owner: -
--

CREATE INDEX idx_stock_movements_tenant ON stock.stock_movements USING btree (tenant_id);


--
-- Name: idx_stock_reservations_tenant_status; Type: INDEX; Schema: stock; Owner: -
--

CREATE INDEX idx_stock_reservations_tenant_status ON stock.stock_reservations USING btree (tenant_id, status);


--
-- Name: idx_stock_transfers_tenant; Type: INDEX; Schema: stock; Owner: -
--

CREATE INDEX idx_stock_transfers_tenant ON stock.stock_transfers USING btree (tenant_id);


--
-- Name: uq_stock_count_items; Type: INDEX; Schema: stock; Owner: -
--

CREATE UNIQUE INDEX uq_stock_count_items ON stock.stock_count_items USING btree (stock_count_id, stock_item_id);


--
-- Name: idx_caixas_tenant_id; Type: INDEX; Schema: tesouraria; Owner: -
--

CREATE INDEX idx_caixas_tenant_id ON tesouraria.caixas USING btree (tenant_id);


--
-- Name: idx_contas_bancarias_tenant_id; Type: INDEX; Schema: tesouraria; Owner: -
--

CREATE INDEX idx_contas_bancarias_tenant_id ON tesouraria.contas_bancarias USING btree (tenant_id);


--
-- Name: idx_movimentos_tenant_id; Type: INDEX; Schema: tesouraria; Owner: -
--

CREATE INDEX idx_movimentos_tenant_id ON tesouraria.movimentos_financeiros USING btree (tenant_id);


--
-- Name: idx_reconciliacoes_conta_id; Type: INDEX; Schema: tesouraria; Owner: -
--

CREATE INDEX idx_reconciliacoes_conta_id ON tesouraria.reconciliacoes_bancarias USING btree (conta_bancaria_id);


--
-- Name: idx_treasury_movements_tenant_date; Type: INDEX; Schema: tesouraria; Owner: -
--

CREATE INDEX idx_treasury_movements_tenant_date ON tesouraria.movements USING btree (tenant_id, data_movimento DESC);


--
-- Name: idx_treasury_reconciliations_tenant_status; Type: INDEX; Schema: tesouraria; Owner: -
--

CREATE INDEX idx_treasury_reconciliations_tenant_status ON tesouraria.reconciliations USING btree (tenant_id, status, periodo_fim DESC);


--
-- Name: idx_profiles_user_id; Type: INDEX; Schema: utilizadores; Owner: -
--

CREATE INDEX idx_profiles_user_id ON utilizadores.profiles USING btree (user_id);


--
-- Name: idx_user_activity_user_id; Type: INDEX; Schema: utilizadores; Owner: -
--

CREATE INDEX idx_user_activity_user_id ON utilizadores.user_activity USING btree (user_id);


--
-- Name: idx_user_avatar_user_id; Type: INDEX; Schema: utilizadores; Owner: -
--

CREATE INDEX idx_user_avatar_user_id ON utilizadores.user_avatar USING btree (user_id);


--
-- Name: idx_user_devices_user_id; Type: INDEX; Schema: utilizadores; Owner: -
--

CREATE INDEX idx_user_devices_user_id ON utilizadores.user_devices USING btree (user_id);


--
-- Name: idx_user_notifications_lida; Type: INDEX; Schema: utilizadores; Owner: -
--

CREATE INDEX idx_user_notifications_lida ON utilizadores.user_notifications USING btree (lida);


--
-- Name: idx_user_notifications_user_id; Type: INDEX; Schema: utilizadores; Owner: -
--

CREATE INDEX idx_user_notifications_user_id ON utilizadores.user_notifications USING btree (user_id);


--
-- Name: idx_user_security_logs_user_id; Type: INDEX; Schema: utilizadores; Owner: -
--

CREATE INDEX idx_user_security_logs_user_id ON utilizadores.user_security_logs USING btree (user_id);


--
-- Name: idx_user_settings_user_id; Type: INDEX; Schema: utilizadores; Owner: -
--

CREATE INDEX idx_user_settings_user_id ON utilizadores.user_settings USING btree (user_id);


--
-- Name: idx_user_tokens_user_id; Type: INDEX; Schema: utilizadores; Owner: -
--

CREATE INDEX idx_user_tokens_user_id ON utilizadores.user_tokens USING btree (user_id);


--
-- Name: tax_return_lines tax_return_lines_immutable; Type: TRIGGER; Schema: impostos; Owner: -
--

CREATE TRIGGER tax_return_lines_immutable BEFORE INSERT OR DELETE OR UPDATE ON impostos.tax_return_lines FOR EACH ROW EXECUTE FUNCTION impostos.trg_tax_return_lines_immutable();


--
-- Name: tax_returns tax_returns_immutable; Type: TRIGGER; Schema: impostos; Owner: -
--

CREATE TRIGGER tax_returns_immutable BEFORE DELETE OR UPDATE ON impostos.tax_returns FOR EACH ROW EXECUTE FUNCTION impostos.trg_tax_return_immutable();


--
-- Name: subscription_invoices fk_subscription_invoices_subscription; Type: FK CONSTRAINT; Schema: assinaturas; Owner: -
--

ALTER TABLE ONLY assinaturas.subscription_invoices
    ADD CONSTRAINT fk_subscription_invoices_subscription FOREIGN KEY (subscription_id) REFERENCES assinaturas.subscriptions(id) ON DELETE CASCADE;


--
-- Name: subscription_usage fk_subscription_usage_subscription; Type: FK CONSTRAINT; Schema: assinaturas; Owner: -
--

ALTER TABLE ONLY assinaturas.subscription_usage
    ADD CONSTRAINT fk_subscription_usage_subscription FOREIGN KEY (subscription_id) REFERENCES assinaturas.subscriptions(id) ON DELETE CASCADE;


--
-- Name: subscriptions fk_subscriptions_plan; Type: FK CONSTRAINT; Schema: assinaturas; Owner: -
--

ALTER TABLE ONLY assinaturas.subscriptions
    ADD CONSTRAINT fk_subscriptions_plan FOREIGN KEY (plan_id) REFERENCES assinaturas.subscription_plans(id) ON DELETE RESTRICT;


--
-- Name: api_keys fk_api_keys_user; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.api_keys
    ADD CONSTRAINT fk_api_keys_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: email_verifications fk_email_verifications_user; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.email_verifications
    ADD CONSTRAINT fk_email_verifications_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: login_history fk_login_history_user; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.login_history
    ADD CONSTRAINT fk_login_history_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: password_resets fk_password_resets_user; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.password_resets
    ADD CONSTRAINT fk_password_resets_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sessions fk_sessions_user; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: users fk_users_cargo; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT fk_users_cargo FOREIGN KEY (cargo_id) REFERENCES auth.cargos(id) ON DELETE SET NULL;


--
-- Name: permissoes_cargo permissoes_cargo_cargo_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.permissoes_cargo
    ADD CONSTRAINT permissoes_cargo_cargo_id_fkey FOREIGN KEY (cargo_id) REFERENCES auth.cargos(id) ON DELETE CASCADE;


--
-- Name: permissoes_diretas permissoes_diretas_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.permissoes_diretas
    ADD CONSTRAINT permissoes_diretas_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: role_permissions fk_role_permissions_permission; Type: FK CONSTRAINT; Schema: autorizacao; Owner: -
--

ALTER TABLE ONLY autorizacao.role_permissions
    ADD CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES autorizacao.permissions(id) ON DELETE CASCADE;


--
-- Name: role_permissions fk_role_permissions_role; Type: FK CONSTRAINT; Schema: autorizacao; Owner: -
--

ALTER TABLE ONLY autorizacao.role_permissions
    ADD CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES autorizacao.roles(id) ON DELETE CASCADE;


--
-- Name: user_roles fk_user_roles_role; Type: FK CONSTRAINT; Schema: autorizacao; Owner: -
--

ALTER TABLE ONLY autorizacao.user_roles
    ADD CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES autorizacao.roles(id) ON DELETE CASCADE;


--
-- Name: cost_center_allocations fk_cost_center_allocations_center; Type: FK CONSTRAINT; Schema: centros_custo; Owner: -
--

ALTER TABLE ONLY centros_custo.cost_center_allocations
    ADD CONSTRAINT fk_cost_center_allocations_center FOREIGN KEY (cost_center_id) REFERENCES centros_custo.cost_centers(id) ON DELETE RESTRICT;


--
-- Name: cost_center_budgets fk_cost_center_budgets_center; Type: FK CONSTRAINT; Schema: centros_custo; Owner: -
--

ALTER TABLE ONLY centros_custo.cost_center_budgets
    ADD CONSTRAINT fk_cost_center_budgets_center FOREIGN KEY (cost_center_id) REFERENCES centros_custo.cost_centers(id) ON DELETE CASCADE;


--
-- Name: cost_centers fk_cost_centers_parent; Type: FK CONSTRAINT; Schema: centros_custo; Owner: -
--

ALTER TABLE ONLY centros_custo.cost_centers
    ADD CONSTRAINT fk_cost_centers_parent FOREIGN KEY (parent_id) REFERENCES centros_custo.cost_centers(id) ON DELETE SET NULL;


--
-- Name: customer_addresses fk_customer_addresses_customer; Type: FK CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_addresses
    ADD CONSTRAINT fk_customer_addresses_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;


--
-- Name: customer_balances fk_customer_balances_customer; Type: FK CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_balances
    ADD CONSTRAINT fk_customer_balances_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;


--
-- Name: customer_contacts fk_customer_contacts_customer; Type: FK CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_contacts
    ADD CONSTRAINT fk_customer_contacts_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;


--
-- Name: customer_credit_limits fk_customer_credit_limits_customer; Type: FK CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_credit_limits
    ADD CONSTRAINT fk_customer_credit_limits_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;


--
-- Name: customer_discounts fk_customer_discounts_customer; Type: FK CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_discounts
    ADD CONSTRAINT fk_customer_discounts_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;


--
-- Name: customer_documents fk_customer_documents_customer; Type: FK CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_documents
    ADD CONSTRAINT fk_customer_documents_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;


--
-- Name: customer_history fk_customer_history_customer; Type: FK CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_history
    ADD CONSTRAINT fk_customer_history_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;


--
-- Name: customer_notes fk_customer_notes_customer; Type: FK CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_notes
    ADD CONSTRAINT fk_customer_notes_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;


--
-- Name: customer_payments fk_customer_payments_customer; Type: FK CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_payments
    ADD CONSTRAINT fk_customer_payments_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;


--
-- Name: customer_tag_links fk_customer_tag_links_customer; Type: FK CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_tag_links
    ADD CONSTRAINT fk_customer_tag_links_customer FOREIGN KEY (customer_id) REFERENCES clientes.customers(id) ON DELETE CASCADE;


--
-- Name: customer_tag_links fk_customer_tag_links_tag; Type: FK CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customer_tag_links
    ADD CONSTRAINT fk_customer_tag_links_tag FOREIGN KEY (customer_tag_id) REFERENCES clientes.customer_tags(id) ON DELETE CASCADE;


--
-- Name: customers fk_customers_group; Type: FK CONSTRAINT; Schema: clientes; Owner: -
--

ALTER TABLE ONLY clientes.customers
    ADD CONSTRAINT fk_customers_group FOREIGN KEY (customer_group_id) REFERENCES clientes.customer_groups(id) ON DELETE SET NULL;


--
-- Name: goods_receipt_items fk_goods_receipt_items_order_item; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.goods_receipt_items
    ADD CONSTRAINT fk_goods_receipt_items_order_item FOREIGN KEY (purchase_order_item_id) REFERENCES compras.purchase_order_items(id) ON DELETE RESTRICT;


--
-- Name: goods_receipt_items fk_goods_receipt_items_receipt; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.goods_receipt_items
    ADD CONSTRAINT fk_goods_receipt_items_receipt FOREIGN KEY (goods_receipt_id) REFERENCES compras.goods_receipts(id) ON DELETE CASCADE;


--
-- Name: goods_receipts fk_goods_receipts_order; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.goods_receipts
    ADD CONSTRAINT fk_goods_receipts_order FOREIGN KEY (purchase_order_id) REFERENCES compras.purchase_orders(id) ON DELETE RESTRICT;


--
-- Name: goods_receipts fk_goods_receipts_supplier; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.goods_receipts
    ADD CONSTRAINT fk_goods_receipts_supplier FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE RESTRICT;


--
-- Name: purchase_order_items fk_purchase_order_items_order; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_order_items
    ADD CONSTRAINT fk_purchase_order_items_order FOREIGN KEY (purchase_order_id) REFERENCES compras.purchase_orders(id) ON DELETE CASCADE;


--
-- Name: purchase_orders fk_purchase_orders_supplier; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_orders
    ADD CONSTRAINT fk_purchase_orders_supplier FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE RESTRICT;


--
-- Name: purchase_return_items fk_purchase_return_items_receipt_item; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_return_items
    ADD CONSTRAINT fk_purchase_return_items_receipt_item FOREIGN KEY (goods_receipt_item_id) REFERENCES compras.goods_receipt_items(id) ON DELETE RESTRICT;


--
-- Name: purchase_return_items fk_purchase_return_items_return; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_return_items
    ADD CONSTRAINT fk_purchase_return_items_return FOREIGN KEY (purchase_return_id) REFERENCES compras.purchase_returns(id) ON DELETE CASCADE;


--
-- Name: purchase_returns fk_purchase_returns_receipt; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_returns
    ADD CONSTRAINT fk_purchase_returns_receipt FOREIGN KEY (goods_receipt_id) REFERENCES compras.goods_receipts(id) ON DELETE RESTRICT;


--
-- Name: purchase_returns fk_purchase_returns_supplier; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_returns
    ADD CONSTRAINT fk_purchase_returns_supplier FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE RESTRICT;


--
-- Name: supplier_addresses fk_supplier_addresses_supplier; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.supplier_addresses
    ADD CONSTRAINT fk_supplier_addresses_supplier FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE CASCADE;


--
-- Name: supplier_contacts fk_supplier_contacts_supplier; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.supplier_contacts
    ADD CONSTRAINT fk_supplier_contacts_supplier FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE CASCADE;


--
-- Name: suppliers fk_suppliers_group; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.suppliers
    ADD CONSTRAINT fk_suppliers_group FOREIGN KEY (supplier_group_id) REFERENCES compras.supplier_groups(id) ON DELETE SET NULL;


--
-- Name: purchase_invoice_items purchase_invoice_items_purchase_invoice_id_fkey; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_invoice_items
    ADD CONSTRAINT purchase_invoice_items_purchase_invoice_id_fkey FOREIGN KEY (purchase_invoice_id) REFERENCES compras.purchase_invoices(id) ON DELETE CASCADE;


--
-- Name: purchase_invoice_items purchase_invoice_items_purchase_order_item_id_fkey; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_invoice_items
    ADD CONSTRAINT purchase_invoice_items_purchase_order_item_id_fkey FOREIGN KEY (purchase_order_item_id) REFERENCES compras.purchase_order_items(id) ON DELETE RESTRICT;


--
-- Name: purchase_invoices purchase_invoices_goods_receipt_id_fkey; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_invoices
    ADD CONSTRAINT purchase_invoices_goods_receipt_id_fkey FOREIGN KEY (goods_receipt_id) REFERENCES compras.goods_receipts(id) ON DELETE RESTRICT;


--
-- Name: purchase_invoices purchase_invoices_purchase_order_id_fkey; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_invoices
    ADD CONSTRAINT purchase_invoices_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES compras.purchase_orders(id) ON DELETE RESTRICT;


--
-- Name: purchase_invoices purchase_invoices_supplier_id_fkey; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_invoices
    ADD CONSTRAINT purchase_invoices_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE RESTRICT;


--
-- Name: purchase_orders purchase_orders_purchase_request_id_fkey; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_orders
    ADD CONSTRAINT purchase_orders_purchase_request_id_fkey FOREIGN KEY (purchase_request_id) REFERENCES compras.purchase_requests(id);


--
-- Name: purchase_payment_items purchase_payment_items_purchase_invoice_id_fkey; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_payment_items
    ADD CONSTRAINT purchase_payment_items_purchase_invoice_id_fkey FOREIGN KEY (purchase_invoice_id) REFERENCES compras.purchase_invoices(id) ON DELETE RESTRICT;


--
-- Name: purchase_payment_items purchase_payment_items_purchase_payment_id_fkey; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_payment_items
    ADD CONSTRAINT purchase_payment_items_purchase_payment_id_fkey FOREIGN KEY (purchase_payment_id) REFERENCES compras.purchase_payments(id) ON DELETE CASCADE;


--
-- Name: purchase_payments purchase_payments_supplier_id_fkey; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_payments
    ADD CONSTRAINT purchase_payments_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES compras.suppliers(id) ON DELETE RESTRICT;


--
-- Name: purchase_request_items purchase_request_items_purchase_request_id_fkey; Type: FK CONSTRAINT; Schema: compras; Owner: -
--

ALTER TABLE ONLY compras.purchase_request_items
    ADD CONSTRAINT purchase_request_items_purchase_request_id_fkey FOREIGN KEY (purchase_request_id) REFERENCES compras.purchase_requests(id) ON DELETE CASCADE;


--
-- Name: chart_of_accounts chart_of_accounts_account_type_id_fkey; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.chart_of_accounts
    ADD CONSTRAINT chart_of_accounts_account_type_id_fkey FOREIGN KEY (account_type_id) REFERENCES contabilidade.account_types(id);


--
-- Name: fiscal_periods fiscal_periods_fiscal_year_id_fkey; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.fiscal_periods
    ADD CONSTRAINT fiscal_periods_fiscal_year_id_fkey FOREIGN KEY (fiscal_year_id) REFERENCES contabilidade.fiscal_years(id);


--
-- Name: accounting_budgets fk_accounting_budgets_account; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.accounting_budgets
    ADD CONSTRAINT fk_accounting_budgets_account FOREIGN KEY (chart_account_id) REFERENCES contabilidade.chart_of_accounts(id);


--
-- Name: accounting_budgets fk_accounting_budgets_year; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.accounting_budgets
    ADD CONSTRAINT fk_accounting_budgets_year FOREIGN KEY (fiscal_year_id) REFERENCES contabilidade.fiscal_years(id);


--
-- Name: chart_of_accounts fk_chart_parent; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.chart_of_accounts
    ADD CONSTRAINT fk_chart_parent FOREIGN KEY (parent_id) REFERENCES contabilidade.chart_of_accounts(id) ON DELETE SET NULL;


--
-- Name: depreciation_entries fk_depreciation_entries_asset; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.depreciation_entries
    ADD CONSTRAINT fk_depreciation_entries_asset FOREIGN KEY (fixed_asset_id) REFERENCES contabilidade.fixed_assets(id);


--
-- Name: depreciation_entries fk_depreciation_entries_journal; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.depreciation_entries
    ADD CONSTRAINT fk_depreciation_entries_journal FOREIGN KEY (journal_entry_id) REFERENCES contabilidade.journal_entries(id);


--
-- Name: depreciation_entries fk_depreciation_entries_period; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.depreciation_entries
    ADD CONSTRAINT fk_depreciation_entries_period FOREIGN KEY (fiscal_period_id) REFERENCES contabilidade.fiscal_periods(id);


--
-- Name: fixed_assets fk_fixed_assets_account; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.fixed_assets
    ADD CONSTRAINT fk_fixed_assets_account FOREIGN KEY (chart_account_id) REFERENCES contabilidade.chart_of_accounts(id);


--
-- Name: fixed_assets fk_fixed_assets_accum_account; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.fixed_assets
    ADD CONSTRAINT fk_fixed_assets_accum_account FOREIGN KEY (accumulated_depreciation_account_id) REFERENCES contabilidade.chart_of_accounts(id);


--
-- Name: fixed_assets fk_fixed_assets_depr_account; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.fixed_assets
    ADD CONSTRAINT fk_fixed_assets_depr_account FOREIGN KEY (depreciation_account_id) REFERENCES contabilidade.chart_of_accounts(id);


--
-- Name: journal_entries fk_journal_entries_journal; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.journal_entries
    ADD CONSTRAINT fk_journal_entries_journal FOREIGN KEY (accounting_journal_id) REFERENCES contabilidade.accounting_journals(id) ON DELETE RESTRICT;


--
-- Name: journal_entries fk_journal_entries_period; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.journal_entries
    ADD CONSTRAINT fk_journal_entries_period FOREIGN KEY (fiscal_period_id) REFERENCES contabilidade.fiscal_periods(id) ON DELETE RESTRICT;


--
-- Name: journal_entry_lines fk_journal_entry_lines_account; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.journal_entry_lines
    ADD CONSTRAINT fk_journal_entry_lines_account FOREIGN KEY (account_id) REFERENCES contabilidade.chart_of_accounts(id) ON DELETE RESTRICT;


--
-- Name: journal_entry_lines fk_journal_entry_lines_entry; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.journal_entry_lines
    ADD CONSTRAINT fk_journal_entry_lines_entry FOREIGN KEY (journal_entry_id) REFERENCES contabilidade.journal_entries(id) ON DELETE CASCADE;


--
-- Name: period_closing_checks fk_period_closing_checks_closing; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.period_closing_checks
    ADD CONSTRAINT fk_period_closing_checks_closing FOREIGN KEY (period_closing_id) REFERENCES contabilidade.period_closings(id) ON DELETE CASCADE;


--
-- Name: period_closings fk_period_closings_period; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.period_closings
    ADD CONSTRAINT fk_period_closings_period FOREIGN KEY (fiscal_period_id) REFERENCES contabilidade.fiscal_periods(id);


--
-- Name: journal_entry_sequences journal_entry_sequences_accounting_journal_id_fkey; Type: FK CONSTRAINT; Schema: contabilidade; Owner: -
--

ALTER TABLE ONLY contabilidade.journal_entry_sequences
    ADD CONSTRAINT journal_entry_sequences_accounting_journal_id_fkey FOREIGN KEY (accounting_journal_id) REFERENCES contabilidade.accounting_journals(id) ON DELETE CASCADE;


--
-- Name: atividades fk_atividades_lead; Type: FK CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.atividades
    ADD CONSTRAINT fk_atividades_lead FOREIGN KEY (lead_id) REFERENCES crm.leads(id) ON DELETE CASCADE;


--
-- Name: atividades fk_atividades_oportunidade; Type: FK CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.atividades
    ADD CONSTRAINT fk_atividades_oportunidade FOREIGN KEY (oportunidade_id) REFERENCES crm.oportunidades(id) ON DELETE CASCADE;


--
-- Name: crm_activities fk_crm_activities_lead; Type: FK CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_activities
    ADD CONSTRAINT fk_crm_activities_lead FOREIGN KEY (lead_id) REFERENCES crm.crm_leads(id) ON DELETE CASCADE;


--
-- Name: crm_activities fk_crm_activities_opportunity; Type: FK CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_activities
    ADD CONSTRAINT fk_crm_activities_opportunity FOREIGN KEY (opportunity_id) REFERENCES crm.crm_opportunities(id) ON DELETE CASCADE;


--
-- Name: crm_leads fk_crm_leads_source; Type: FK CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_leads
    ADD CONSTRAINT fk_crm_leads_source FOREIGN KEY (lead_source_id) REFERENCES crm.crm_lead_sources(id) ON DELETE SET NULL;


--
-- Name: crm_opportunities fk_crm_opportunities_lead; Type: FK CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_opportunities
    ADD CONSTRAINT fk_crm_opportunities_lead FOREIGN KEY (lead_id) REFERENCES crm.crm_leads(id) ON DELETE SET NULL;


--
-- Name: crm_opportunities fk_crm_opportunities_pipeline; Type: FK CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_opportunities
    ADD CONSTRAINT fk_crm_opportunities_pipeline FOREIGN KEY (pipeline_id) REFERENCES crm.crm_pipelines(id) ON DELETE RESTRICT;


--
-- Name: crm_opportunities fk_crm_opportunities_stage; Type: FK CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_opportunities
    ADD CONSTRAINT fk_crm_opportunities_stage FOREIGN KEY (stage_id) REFERENCES crm.crm_pipeline_stages(id) ON DELETE RESTRICT;


--
-- Name: crm_pipeline_stages fk_crm_pipeline_stages_pipeline; Type: FK CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.crm_pipeline_stages
    ADD CONSTRAINT fk_crm_pipeline_stages_pipeline FOREIGN KEY (pipeline_id) REFERENCES crm.crm_pipelines(id) ON DELETE CASCADE;


--
-- Name: oportunidades fk_oportunidades_lead; Type: FK CONSTRAINT; Schema: crm; Owner: -
--

ALTER TABLE ONLY crm.oportunidades
    ADD CONSTRAINT fk_oportunidades_lead FOREIGN KEY (lead_id) REFERENCES crm.leads(id) ON DELETE SET NULL;


--
-- Name: company_addresses fk_company_addresses_branch; Type: FK CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_addresses
    ADD CONSTRAINT fk_company_addresses_branch FOREIGN KEY (branch_id) REFERENCES empresa.company_branches(id) ON DELETE SET NULL;


--
-- Name: company_addresses fk_company_addresses_company; Type: FK CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_addresses
    ADD CONSTRAINT fk_company_addresses_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_banks fk_company_banks_company; Type: FK CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_banks
    ADD CONSTRAINT fk_company_banks_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_branches fk_company_branches_company; Type: FK CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_branches
    ADD CONSTRAINT fk_company_branches_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_contacts fk_company_contacts_branch; Type: FK CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_contacts
    ADD CONSTRAINT fk_company_contacts_branch FOREIGN KEY (branch_id) REFERENCES empresa.company_branches(id) ON DELETE SET NULL;


--
-- Name: company_contacts fk_company_contacts_company; Type: FK CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_contacts
    ADD CONSTRAINT fk_company_contacts_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_documents fk_company_documents_company; Type: FK CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_documents
    ADD CONSTRAINT fk_company_documents_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_licenses fk_company_licenses_company; Type: FK CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_licenses
    ADD CONSTRAINT fk_company_licenses_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_settings fk_company_settings_company; Type: FK CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_settings
    ADD CONSTRAINT fk_company_settings_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_tax_info fk_company_tax_info_company; Type: FK CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_tax_info
    ADD CONSTRAINT fk_company_tax_info_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_users fk_company_users_branch; Type: FK CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_users
    ADD CONSTRAINT fk_company_users_branch FOREIGN KEY (branch_id) REFERENCES empresa.company_branches(id) ON DELETE SET NULL;


--
-- Name: company_users fk_company_users_company; Type: FK CONSTRAINT; Schema: empresa; Owner: -
--

ALTER TABLE ONLY empresa.company_users
    ADD CONSTRAINT fk_company_users_company FOREIGN KEY (company_id) REFERENCES empresa.companies(id) ON DELETE CASCADE;


--
-- Name: company_addresses fk_company_addresses_branch; Type: FK CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_addresses
    ADD CONSTRAINT fk_company_addresses_branch FOREIGN KEY (branch_id) REFERENCES empresas.company_branches(id) ON DELETE SET NULL;


--
-- Name: company_addresses fk_company_addresses_company; Type: FK CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_addresses
    ADD CONSTRAINT fk_company_addresses_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;


--
-- Name: company_banks fk_company_banks_company; Type: FK CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_banks
    ADD CONSTRAINT fk_company_banks_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;


--
-- Name: company_branches fk_company_branches_company; Type: FK CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_branches
    ADD CONSTRAINT fk_company_branches_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;


--
-- Name: company_contacts fk_company_contacts_branch; Type: FK CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_contacts
    ADD CONSTRAINT fk_company_contacts_branch FOREIGN KEY (branch_id) REFERENCES empresas.company_branches(id) ON DELETE SET NULL;


--
-- Name: company_contacts fk_company_contacts_company; Type: FK CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_contacts
    ADD CONSTRAINT fk_company_contacts_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;


--
-- Name: company_documents fk_company_documents_company; Type: FK CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_documents
    ADD CONSTRAINT fk_company_documents_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;


--
-- Name: company_licenses fk_company_licenses_company; Type: FK CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_licenses
    ADD CONSTRAINT fk_company_licenses_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;


--
-- Name: company_settings fk_company_settings_company; Type: FK CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_settings
    ADD CONSTRAINT fk_company_settings_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;


--
-- Name: company_tax_info fk_company_tax_info_company; Type: FK CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_tax_info
    ADD CONSTRAINT fk_company_tax_info_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;


--
-- Name: company_users fk_company_users_branch; Type: FK CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_users
    ADD CONSTRAINT fk_company_users_branch FOREIGN KEY (branch_id) REFERENCES empresas.company_branches(id) ON DELETE SET NULL;


--
-- Name: company_users fk_company_users_company; Type: FK CONSTRAINT; Schema: empresas; Owner: -
--

ALTER TABLE ONLY empresas.company_users
    ADD CONSTRAINT fk_company_users_company FOREIGN KEY (company_id) REFERENCES empresas.companies(id) ON DELETE CASCADE;


--
-- Name: credit_note_items fk_credit_note_items_nc; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.credit_note_items
    ADD CONSTRAINT fk_credit_note_items_nc FOREIGN KEY (credit_note_id) REFERENCES faturacao.credit_notes(id) ON DELETE CASCADE;


--
-- Name: credit_notes fk_credit_notes_invoice; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.credit_notes
    ADD CONSTRAINT fk_credit_notes_invoice FOREIGN KEY (invoice_id) REFERENCES faturacao.invoices(id) ON DELETE SET NULL;


--
-- Name: credit_notes fk_credit_notes_serie; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.credit_notes
    ADD CONSTRAINT fk_credit_notes_serie FOREIGN KEY (serie_id) REFERENCES faturacao.invoice_series(id) ON DELETE SET NULL;


--
-- Name: sales_deliveries fk_deliveries_order; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_deliveries
    ADD CONSTRAINT fk_deliveries_order FOREIGN KEY (sales_order_id) REFERENCES faturacao.sales_orders(id);


--
-- Name: sales_deliveries fk_deliveries_serie; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_deliveries
    ADD CONSTRAINT fk_deliveries_serie FOREIGN KEY (serie_id) REFERENCES faturacao.invoice_series(id) ON DELETE SET NULL;


--
-- Name: sales_delivery_items fk_delivery_items_delivery; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_delivery_items
    ADD CONSTRAINT fk_delivery_items_delivery FOREIGN KEY (sales_delivery_id) REFERENCES faturacao.sales_deliveries(id) ON DELETE CASCADE;


--
-- Name: invoice_discounts fk_invoice_discounts_invoice; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoice_discounts
    ADD CONSTRAINT fk_invoice_discounts_invoice FOREIGN KEY (invoice_id) REFERENCES faturacao.invoices(id) ON DELETE CASCADE;


--
-- Name: invoice_items fk_invoice_items_invoice; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoice_items
    ADD CONSTRAINT fk_invoice_items_invoice FOREIGN KEY (invoice_id) REFERENCES faturacao.invoices(id) ON DELETE CASCADE;


--
-- Name: invoice_items fk_invoice_items_tax_exemption; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoice_items
    ADD CONSTRAINT fk_invoice_items_tax_exemption FOREIGN KEY (tax_exemption_id) REFERENCES impostos.tax_exemptions(id) ON DELETE SET NULL;


--
-- Name: invoice_taxes fk_invoice_taxes_invoice; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoice_taxes
    ADD CONSTRAINT fk_invoice_taxes_invoice FOREIGN KEY (invoice_id) REFERENCES faturacao.invoices(id) ON DELETE CASCADE;


--
-- Name: invoices fk_invoices_order; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoices
    ADD CONSTRAINT fk_invoices_order FOREIGN KEY (sales_order_id) REFERENCES faturacao.sales_orders(id) ON DELETE SET NULL;


--
-- Name: invoices fk_invoices_serie; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoices
    ADD CONSTRAINT fk_invoices_serie FOREIGN KEY (serie_id) REFERENCES faturacao.invoice_series(id) ON DELETE SET NULL;


--
-- Name: sales_order_items fk_order_items_order; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_order_items
    ADD CONSTRAINT fk_order_items_order FOREIGN KEY (sales_order_id) REFERENCES faturacao.sales_orders(id) ON DELETE CASCADE;


--
-- Name: sales_orders fk_orders_quote; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_orders
    ADD CONSTRAINT fk_orders_quote FOREIGN KEY (sales_quote_id) REFERENCES faturacao.sales_quotes(id) ON DELETE SET NULL;


--
-- Name: sales_orders fk_orders_serie; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_orders
    ADD CONSTRAINT fk_orders_serie FOREIGN KEY (serie_id) REFERENCES faturacao.invoice_series(id) ON DELETE SET NULL;


--
-- Name: sales_quote_items fk_quote_items_quote; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_quote_items
    ADD CONSTRAINT fk_quote_items_quote FOREIGN KEY (sales_quote_id) REFERENCES faturacao.sales_quotes(id) ON DELETE CASCADE;


--
-- Name: sales_quotes fk_quotes_serie; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_quotes
    ADD CONSTRAINT fk_quotes_serie FOREIGN KEY (serie_id) REFERENCES faturacao.invoice_series(id) ON DELETE SET NULL;


--
-- Name: invoice_receipts fk_receipts_invoice; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoice_receipts
    ADD CONSTRAINT fk_receipts_invoice FOREIGN KEY (invoice_id) REFERENCES faturacao.invoices(id);


--
-- Name: invoice_receipts fk_receipts_serie; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.invoice_receipts
    ADD CONSTRAINT fk_receipts_serie FOREIGN KEY (serie_id) REFERENCES faturacao.invoice_series(id) ON DELETE SET NULL;


--
-- Name: sales_return_items fk_return_items_return; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_return_items
    ADD CONSTRAINT fk_return_items_return FOREIGN KEY (sales_return_id) REFERENCES faturacao.sales_returns(id) ON DELETE CASCADE;


--
-- Name: sales_returns fk_returns_cn; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_returns
    ADD CONSTRAINT fk_returns_cn FOREIGN KEY (credit_note_id) REFERENCES faturacao.credit_notes(id) ON DELETE SET NULL;


--
-- Name: sales_returns fk_returns_invoice; Type: FK CONSTRAINT; Schema: faturacao; Owner: -
--

ALTER TABLE ONLY faturacao.sales_returns
    ADD CONSTRAINT fk_returns_invoice FOREIGN KEY (invoice_id) REFERENCES faturacao.invoices(id) ON DELETE SET NULL;


--
-- Name: accounts_payable fk_ap_category; Type: FK CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_payable
    ADD CONSTRAINT fk_ap_category FOREIGN KEY (financial_category_id) REFERENCES financeiro.financial_categories(id) ON DELETE SET NULL;


--
-- Name: accounts_payable_payments fk_ap_payments_ap; Type: FK CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_payable_payments
    ADD CONSTRAINT fk_ap_payments_ap FOREIGN KEY (accounts_payable_id) REFERENCES financeiro.accounts_payable(id) ON DELETE CASCADE;


--
-- Name: accounts_payable_payments fk_ap_payments_payment; Type: FK CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_payable_payments
    ADD CONSTRAINT fk_ap_payments_payment FOREIGN KEY (payment_id) REFERENCES financeiro.payments(id);


--
-- Name: accounts_receivable fk_ar_category; Type: FK CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_receivable
    ADD CONSTRAINT fk_ar_category FOREIGN KEY (financial_category_id) REFERENCES financeiro.financial_categories(id) ON DELETE SET NULL;


--
-- Name: accounts_receivable_payments fk_ar_payments_ar; Type: FK CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_receivable_payments
    ADD CONSTRAINT fk_ar_payments_ar FOREIGN KEY (accounts_receivable_id) REFERENCES financeiro.accounts_receivable(id) ON DELETE CASCADE;


--
-- Name: accounts_receivable_payments fk_ar_payments_payment; Type: FK CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.accounts_receivable_payments
    ADD CONSTRAINT fk_ar_payments_payment FOREIGN KEY (payment_id) REFERENCES financeiro.payments(id);


--
-- Name: financial_budgets fk_budgets_category; Type: FK CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.financial_budgets
    ADD CONSTRAINT fk_budgets_category FOREIGN KEY (financial_category_id) REFERENCES financeiro.financial_categories(id) ON DELETE CASCADE;


--
-- Name: cash_flow_entries fk_cashflow_category; Type: FK CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.cash_flow_entries
    ADD CONSTRAINT fk_cashflow_category FOREIGN KEY (financial_category_id) REFERENCES financeiro.financial_categories(id) ON DELETE SET NULL;


--
-- Name: financial_categories fk_financial_categories_parent; Type: FK CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.financial_categories
    ADD CONSTRAINT fk_financial_categories_parent FOREIGN KEY (parent_id) REFERENCES financeiro.financial_categories(id) ON DELETE SET NULL;


--
-- Name: payments fk_payments_category; Type: FK CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.payments
    ADD CONSTRAINT fk_payments_category FOREIGN KEY (financial_category_id) REFERENCES financeiro.financial_categories(id) ON DELETE SET NULL;


--
-- Name: payments fk_payments_method; Type: FK CONSTRAINT; Schema: financeiro; Owner: -
--

ALTER TABLE ONLY financeiro.payments
    ADD CONSTRAINT fk_payments_method FOREIGN KEY (payment_method_id) REFERENCES financeiro.payment_methods(id) ON DELETE SET NULL;


--
-- Name: school_attendance fk_school_attendance_class; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_attendance
    ADD CONSTRAINT fk_school_attendance_class FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE CASCADE;


--
-- Name: school_attendance fk_school_attendance_student; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_attendance
    ADD CONSTRAINT fk_school_attendance_student FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;


--
-- Name: school_enrollments fk_school_enrollments_class; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_enrollments
    ADD CONSTRAINT fk_school_enrollments_class FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE RESTRICT;


--
-- Name: school_enrollments fk_school_enrollments_student; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_enrollments
    ADD CONSTRAINT fk_school_enrollments_student FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;


--
-- Name: school_fees fk_school_fees_enrollment; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_fees
    ADD CONSTRAINT fk_school_fees_enrollment FOREIGN KEY (enrollment_id) REFERENCES gestao_escolar.school_enrollments(id) ON DELETE CASCADE;


--
-- Name: school_attendance school_attendance_enrollment_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_attendance
    ADD CONSTRAINT school_attendance_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES gestao_escolar.school_enrollments(id);


--
-- Name: school_attendance school_attendance_subject_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_attendance
    ADD CONSTRAINT school_attendance_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES gestao_escolar.school_subjects(id);


--
-- Name: school_classes school_classes_school_year_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_classes
    ADD CONSTRAINT school_classes_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id);


--
-- Name: school_enrollments school_enrollments_school_year_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_enrollments
    ADD CONSTRAINT school_enrollments_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id);


--
-- Name: school_fee_plans school_fee_plans_school_year_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_fee_plans
    ADD CONSTRAINT school_fee_plans_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id);


--
-- Name: school_fees school_fees_fee_plan_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_fees
    ADD CONSTRAINT school_fees_fee_plan_id_fkey FOREIGN KEY (fee_plan_id) REFERENCES gestao_escolar.school_fee_plans(id);


--
-- Name: school_fees school_fees_student_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_fees
    ADD CONSTRAINT school_fees_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id);


--
-- Name: school_grade_items school_grade_items_class_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_grade_items
    ADD CONSTRAINT school_grade_items_class_id_fkey FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE CASCADE;


--
-- Name: school_grade_items school_grade_items_subject_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_grade_items
    ADD CONSTRAINT school_grade_items_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES gestao_escolar.school_subjects(id);


--
-- Name: school_grade_items school_grade_items_term_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_grade_items
    ADD CONSTRAINT school_grade_items_term_id_fkey FOREIGN KEY (term_id) REFERENCES gestao_escolar.school_terms(id);


--
-- Name: school_grades school_grades_enrollment_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_grades
    ADD CONSTRAINT school_grades_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES gestao_escolar.school_enrollments(id);


--
-- Name: school_grades school_grades_grade_item_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_grades
    ADD CONSTRAINT school_grades_grade_item_id_fkey FOREIGN KEY (grade_item_id) REFERENCES gestao_escolar.school_grade_items(id) ON DELETE CASCADE;


--
-- Name: school_grades school_grades_student_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_grades
    ADD CONSTRAINT school_grades_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;


--
-- Name: school_guardians school_guardians_student_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_guardians
    ADD CONSTRAINT school_guardians_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;


--
-- Name: school_library_loans school_library_loans_book_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_library_loans
    ADD CONSTRAINT school_library_loans_book_id_fkey FOREIGN KEY (book_id) REFERENCES gestao_escolar.school_books(id);


--
-- Name: school_library_loans school_library_loans_student_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_library_loans
    ADD CONSTRAINT school_library_loans_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id);


--
-- Name: school_payments school_payments_school_fee_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_payments
    ADD CONSTRAINT school_payments_school_fee_id_fkey FOREIGN KEY (school_fee_id) REFERENCES gestao_escolar.school_fees(id);


--
-- Name: school_payments school_payments_student_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_payments
    ADD CONSTRAINT school_payments_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id);


--
-- Name: school_student_roles school_student_roles_class_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_student_roles
    ADD CONSTRAINT school_student_roles_class_id_fkey FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE CASCADE;


--
-- Name: school_student_roles school_student_roles_student_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_student_roles
    ADD CONSTRAINT school_student_roles_student_id_fkey FOREIGN KEY (student_id) REFERENCES gestao_escolar.school_students(id) ON DELETE CASCADE;


--
-- Name: school_teacher_assignments school_teacher_assignments_class_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_teacher_assignments
    ADD CONSTRAINT school_teacher_assignments_class_id_fkey FOREIGN KEY (class_id) REFERENCES gestao_escolar.school_classes(id) ON DELETE CASCADE;


--
-- Name: school_teacher_assignments school_teacher_assignments_school_year_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_teacher_assignments
    ADD CONSTRAINT school_teacher_assignments_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id);


--
-- Name: school_teacher_assignments school_teacher_assignments_subject_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_teacher_assignments
    ADD CONSTRAINT school_teacher_assignments_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES gestao_escolar.school_subjects(id);


--
-- Name: school_teacher_roles school_teacher_roles_school_year_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_teacher_roles
    ADD CONSTRAINT school_teacher_roles_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id);


--
-- Name: school_terms school_terms_school_year_id_fkey; Type: FK CONSTRAINT; Schema: gestao_escolar; Owner: -
--

ALTER TABLE ONLY gestao_escolar.school_terms
    ADD CONSTRAINT school_terms_school_year_id_fkey FOREIGN KEY (school_year_id) REFERENCES gestao_escolar.school_years(id) ON DELETE CASCADE;


--
-- Name: tax_exemptions fk_tax_exemptions_tax; Type: FK CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_exemptions
    ADD CONSTRAINT fk_tax_exemptions_tax FOREIGN KEY (tax_id) REFERENCES impostos.taxes(id) ON DELETE CASCADE;


--
-- Name: tax_return_lines fk_tax_return_lines_return; Type: FK CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_return_lines
    ADD CONSTRAINT fk_tax_return_lines_return FOREIGN KEY (tax_return_id) REFERENCES impostos.tax_returns(id) ON DELETE CASCADE;


--
-- Name: tax_returns fk_tax_returns_substitui; Type: FK CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_returns
    ADD CONSTRAINT fk_tax_returns_substitui FOREIGN KEY (substitui_id) REFERENCES impostos.tax_returns(id) ON DELETE RESTRICT;


--
-- Name: tax_rules fk_tax_rules_tax; Type: FK CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_rules
    ADD CONSTRAINT fk_tax_rules_tax FOREIGN KEY (tax_id) REFERENCES impostos.taxes(id) ON DELETE CASCADE;


--
-- Name: tax_transactions fk_tax_transactions_period; Type: FK CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_transactions
    ADD CONSTRAINT fk_tax_transactions_period FOREIGN KEY (fiscal_period_id) REFERENCES contabilidade.fiscal_periods(id);


--
-- Name: tax_transactions fk_tax_transactions_tax; Type: FK CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.tax_transactions
    ADD CONSTRAINT fk_tax_transactions_tax FOREIGN KEY (tax_id) REFERENCES impostos.taxes(id);


--
-- Name: withholding_tax_transactions fk_wtt_wt; Type: FK CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.withholding_tax_transactions
    ADD CONSTRAINT fk_wtt_wt FOREIGN KEY (withholding_tax_id) REFERENCES impostos.withholding_taxes(id);


--
-- Name: taxes taxes_tax_group_id_fkey; Type: FK CONSTRAINT; Schema: impostos; Owner: -
--

ALTER TABLE ONLY impostos.taxes
    ADD CONSTRAINT taxes_tax_group_id_fkey FOREIGN KEY (tax_group_id) REFERENCES impostos.tax_groups(id);


--
-- Name: delivery_tracking delivery_tracking_shipment_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.delivery_tracking
    ADD CONSTRAINT delivery_tracking_shipment_id_fkey FOREIGN KEY (shipment_id) REFERENCES logistica.shipments(id) ON DELETE CASCADE;


--
-- Name: delivery_tracking delivery_tracking_status_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.delivery_tracking
    ADD CONSTRAINT delivery_tracking_status_id_fkey FOREIGN KEY (status_id) REFERENCES logistica.delivery_statuses(id);


--
-- Name: logistics_shipments fk_logistics_shipments_driver; Type: FK CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT fk_logistics_shipments_driver FOREIGN KEY (driver_id) REFERENCES logistica.logistics_drivers(id) ON DELETE SET NULL;


--
-- Name: logistics_shipments fk_logistics_shipments_route; Type: FK CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT fk_logistics_shipments_route FOREIGN KEY (logistics_route_id) REFERENCES logistica.logistics_routes(id) ON DELETE SET NULL;


--
-- Name: logistics_shipments fk_logistics_shipments_vehicle; Type: FK CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_shipments
    ADD CONSTRAINT fk_logistics_shipments_vehicle FOREIGN KEY (vehicle_id) REFERENCES logistica.logistics_vehicles(id) ON DELETE SET NULL;


--
-- Name: logistics_tracking_events fk_logistics_tracking_events_shipment; Type: FK CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.logistics_tracking_events
    ADD CONSTRAINT fk_logistics_tracking_events_shipment FOREIGN KEY (shipment_id) REFERENCES logistica.logistics_shipments(id) ON DELETE CASCADE;


--
-- Name: shipment_items shipment_items_shipment_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.shipment_items
    ADD CONSTRAINT shipment_items_shipment_id_fkey FOREIGN KEY (shipment_id) REFERENCES logistica.shipments(id) ON DELETE CASCADE;


--
-- Name: shipments shipments_driver_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.shipments
    ADD CONSTRAINT shipments_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES logistica.delivery_drivers(id);


--
-- Name: shipments shipments_route_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.shipments
    ADD CONSTRAINT shipments_route_id_fkey FOREIGN KEY (route_id) REFERENCES logistica.delivery_routes(id);


--
-- Name: shipments shipments_status_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.shipments
    ADD CONSTRAINT shipments_status_id_fkey FOREIGN KEY (status_id) REFERENCES logistica.delivery_statuses(id);


--
-- Name: shipments shipments_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: logistica; Owner: -
--

ALTER TABLE ONLY logistica.shipments
    ADD CONSTRAINT shipments_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES logistica.delivery_vehicles(id);


--
-- Name: exchange_rates fk_exchange_rates_base; Type: FK CONSTRAINT; Schema: multi_moeda; Owner: -
--

ALTER TABLE ONLY multi_moeda.exchange_rates
    ADD CONSTRAINT fk_exchange_rates_base FOREIGN KEY (base_currency_id) REFERENCES multi_moeda.currencies(id) ON DELETE RESTRICT;


--
-- Name: exchange_rates fk_exchange_rates_quote; Type: FK CONSTRAINT; Schema: multi_moeda; Owner: -
--

ALTER TABLE ONLY multi_moeda.exchange_rates
    ADD CONSTRAINT fk_exchange_rates_quote FOREIGN KEY (quote_currency_id) REFERENCES multi_moeda.currencies(id) ON DELETE RESTRICT;


--
-- Name: tenant_currencies fk_tenant_currencies_currency; Type: FK CONSTRAINT; Schema: multi_moeda; Owner: -
--

ALTER TABLE ONLY multi_moeda.tenant_currencies
    ADD CONSTRAINT fk_tenant_currencies_currency FOREIGN KEY (currency_id) REFERENCES multi_moeda.currencies(id) ON DELETE RESTRICT;


--
-- Name: notification_messages fk_notification_messages_channel; Type: FK CONSTRAINT; Schema: notifications; Owner: -
--

ALTER TABLE ONLY notifications.notification_messages
    ADD CONSTRAINT fk_notification_messages_channel FOREIGN KEY (channel_id) REFERENCES notifications.notification_channels(id) ON DELETE SET NULL;


--
-- Name: notification_messages fk_notification_messages_template; Type: FK CONSTRAINT; Schema: notifications; Owner: -
--

ALTER TABLE ONLY notifications.notification_messages
    ADD CONSTRAINT fk_notification_messages_template FOREIGN KEY (template_id) REFERENCES notifications.notification_templates(id) ON DELETE SET NULL;


--
-- Name: pos_sale_items fk_pos_sale_items_sale; Type: FK CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_sale_items
    ADD CONSTRAINT fk_pos_sale_items_sale FOREIGN KEY (pos_sale_id) REFERENCES pos.pos_sales(id) ON DELETE CASCADE;


--
-- Name: pos_sale_payments fk_pos_sale_payments_sale; Type: FK CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_sale_payments
    ADD CONSTRAINT fk_pos_sale_payments_sale FOREIGN KEY (pos_sale_id) REFERENCES pos.pos_sales(id) ON DELETE CASCADE;


--
-- Name: pos_sales fk_pos_sales_session; Type: FK CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_sales
    ADD CONSTRAINT fk_pos_sales_session FOREIGN KEY (pos_session_id) REFERENCES pos.pos_sessions(id) ON DELETE RESTRICT;


--
-- Name: pos_sales fk_pos_sales_terminal; Type: FK CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_sales
    ADD CONSTRAINT fk_pos_sales_terminal FOREIGN KEY (terminal_id) REFERENCES pos.pos_terminals(id) ON DELETE RESTRICT;


--
-- Name: pos_sessions fk_pos_sessions_terminal; Type: FK CONSTRAINT; Schema: pos; Owner: -
--

ALTER TABLE ONLY pos.pos_sessions
    ADD CONSTRAINT fk_pos_sessions_terminal FOREIGN KEY (terminal_id) REFERENCES pos.pos_terminals(id) ON DELETE RESTRICT;


--
-- Name: product_attribute_values fk_product_attribute_values_attribute; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_attribute_values
    ADD CONSTRAINT fk_product_attribute_values_attribute FOREIGN KEY (product_attribute_id) REFERENCES produtos.product_attributes(id) ON DELETE CASCADE;


--
-- Name: product_attribute_values fk_product_attribute_values_product; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_attribute_values
    ADD CONSTRAINT fk_product_attribute_values_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;


--
-- Name: product_attribute_values fk_product_attribute_values_variant; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_attribute_values
    ADD CONSTRAINT fk_product_attribute_values_variant FOREIGN KEY (product_variant_id) REFERENCES produtos.product_variants(id) ON DELETE CASCADE;


--
-- Name: product_barcodes fk_product_barcodes_product; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_barcodes
    ADD CONSTRAINT fk_product_barcodes_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;


--
-- Name: product_categories fk_product_categories_parent; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_categories
    ADD CONSTRAINT fk_product_categories_parent FOREIGN KEY (parent_id) REFERENCES produtos.product_categories(id) ON DELETE SET NULL;


--
-- Name: product_discounts fk_product_discounts_product; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_discounts
    ADD CONSTRAINT fk_product_discounts_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;


--
-- Name: product_discounts fk_product_discounts_variant; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_discounts
    ADD CONSTRAINT fk_product_discounts_variant FOREIGN KEY (product_variant_id) REFERENCES produtos.product_variants(id) ON DELETE CASCADE;


--
-- Name: product_images fk_product_images_product; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_images
    ADD CONSTRAINT fk_product_images_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;


--
-- Name: product_kit_items fk_product_kit_items_kit; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_kit_items
    ADD CONSTRAINT fk_product_kit_items_kit FOREIGN KEY (product_kit_id) REFERENCES produtos.product_kits(id) ON DELETE CASCADE;


--
-- Name: product_kit_items fk_product_kit_items_product; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_kit_items
    ADD CONSTRAINT fk_product_kit_items_product FOREIGN KEY (item_product_id) REFERENCES produtos.products(id) ON DELETE RESTRICT;


--
-- Name: product_kit_items fk_product_kit_items_variant; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_kit_items
    ADD CONSTRAINT fk_product_kit_items_variant FOREIGN KEY (item_variant_id) REFERENCES produtos.product_variants(id) ON DELETE RESTRICT;


--
-- Name: product_kits fk_product_kits_product; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_kits
    ADD CONSTRAINT fk_product_kits_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;


--
-- Name: product_prices fk_product_prices_product; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_prices
    ADD CONSTRAINT fk_product_prices_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;


--
-- Name: product_prices fk_product_prices_variant; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_prices
    ADD CONSTRAINT fk_product_prices_variant FOREIGN KEY (product_variant_id) REFERENCES produtos.product_variants(id) ON DELETE CASCADE;


--
-- Name: product_subcategories fk_product_subcategories_category; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_subcategories
    ADD CONSTRAINT fk_product_subcategories_category FOREIGN KEY (product_category_id) REFERENCES produtos.product_categories(id) ON DELETE CASCADE;


--
-- Name: product_tag_links fk_product_tag_links_product; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_tag_links
    ADD CONSTRAINT fk_product_tag_links_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;


--
-- Name: product_tag_links fk_product_tag_links_tag; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_tag_links
    ADD CONSTRAINT fk_product_tag_links_tag FOREIGN KEY (product_tag_id) REFERENCES produtos.product_tags(id) ON DELETE CASCADE;


--
-- Name: product_variants fk_product_variants_product; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.product_variants
    ADD CONSTRAINT fk_product_variants_product FOREIGN KEY (product_id) REFERENCES produtos.products(id) ON DELETE CASCADE;


--
-- Name: products fk_products_brand; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT fk_products_brand FOREIGN KEY (product_brand_id) REFERENCES produtos.product_brands(id) ON DELETE SET NULL;


--
-- Name: products fk_products_category; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT fk_products_category FOREIGN KEY (product_category_id) REFERENCES produtos.product_categories(id) ON DELETE SET NULL;


--
-- Name: products fk_products_subcategory; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT fk_products_subcategory FOREIGN KEY (product_subcategory_id) REFERENCES produtos.product_subcategories(id) ON DELETE SET NULL;


--
-- Name: products fk_products_unit; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT fk_products_unit FOREIGN KEY (product_unit_id) REFERENCES produtos.product_units(id) ON DELETE SET NULL;


--
-- Name: products fk_products_warehouse; Type: FK CONSTRAINT; Schema: produtos; Owner: -
--

ALTER TABLE ONLY produtos.products
    ADD CONSTRAINT fk_products_warehouse FOREIGN KEY (warehouse_default_id) REFERENCES produtos.warehouses(id) ON DELETE SET NULL;


--
-- Name: chat_conversas chat_conversas_criado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_conversas
    ADD CONSTRAINT chat_conversas_criado_por_fkey FOREIGN KEY (criado_por) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: chat_mensagens chat_mensagens_autor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_mensagens
    ADD CONSTRAINT chat_mensagens_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: chat_mensagens chat_mensagens_conversa_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_mensagens
    ADD CONSTRAINT chat_mensagens_conversa_id_fkey FOREIGN KEY (conversa_id) REFERENCES public.chat_conversas(id) ON DELETE CASCADE;


--
-- Name: chat_participantes chat_participantes_conversa_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_participantes
    ADD CONSTRAINT chat_participantes_conversa_id_fkey FOREIGN KEY (conversa_id) REFERENCES public.chat_conversas(id) ON DELETE CASCADE;


--
-- Name: chat_participantes chat_participantes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_participantes
    ADD CONSTRAINT chat_participantes_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: comunicados comunicados_autor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunicados
    ADD CONSTRAINT comunicados_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: comunicados_lidos comunicados_lidos_comunicado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunicados_lidos
    ADD CONSTRAINT comunicados_lidos_comunicado_id_fkey FOREIGN KEY (comunicado_id) REFERENCES public.comunicados(id) ON DELETE CASCADE;


--
-- Name: comunicados_lidos comunicados_lidos_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunicados_lidos
    ADD CONSTRAINT comunicados_lidos_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: notif_colaborador notif_colaborador_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notif_colaborador
    ADD CONSTRAINT notif_colaborador_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: candidatura_notas fk_candidatura_notas_candidatura; Type: FK CONSTRAINT; Schema: recrutamento; Owner: -
--

ALTER TABLE ONLY recrutamento.candidatura_notas
    ADD CONSTRAINT fk_candidatura_notas_candidatura FOREIGN KEY (candidatura_id) REFERENCES recrutamento.candidaturas(id) ON DELETE CASCADE;


--
-- Name: candidaturas fk_candidaturas_vaga; Type: FK CONSTRAINT; Schema: recrutamento; Owner: -
--

ALTER TABLE ONLY recrutamento.candidaturas
    ADD CONSTRAINT fk_candidaturas_vaga FOREIGN KEY (vaga_id) REFERENCES recrutamento.vagas(id) ON DELETE SET NULL;


--
-- Name: employee_bank_accounts fk_employee_bank_accounts_employee; Type: FK CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.employee_bank_accounts
    ADD CONSTRAINT fk_employee_bank_accounts_employee FOREIGN KEY (employee_id) REFERENCES recursos_humanos.employees(id) ON DELETE CASCADE;


--
-- Name: employees fk_employees_department; Type: FK CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.employees
    ADD CONSTRAINT fk_employees_department FOREIGN KEY (department_id) REFERENCES recursos_humanos.hr_departments(id) ON DELETE SET NULL;


--
-- Name: payroll_run_lines fk_payroll_run_lines_employee; Type: FK CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.payroll_run_lines
    ADD CONSTRAINT fk_payroll_run_lines_employee FOREIGN KEY (employee_id) REFERENCES recursos_humanos.employees(id) ON DELETE RESTRICT;


--
-- Name: payroll_run_lines fk_payroll_run_lines_run; Type: FK CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.payroll_run_lines
    ADD CONSTRAINT fk_payroll_run_lines_run FOREIGN KEY (payroll_run_id) REFERENCES recursos_humanos.payroll_runs(id) ON DELETE CASCADE;


--
-- Name: payroll_runs fk_payroll_runs_period; Type: FK CONSTRAINT; Schema: recursos_humanos; Owner: -
--

ALTER TABLE ONLY recursos_humanos.payroll_runs
    ADD CONSTRAINT fk_payroll_runs_period FOREIGN KEY (payroll_period_id) REFERENCES recursos_humanos.payroll_periods(id) ON DELETE RESTRICT;


--
-- Name: ausencias ausencias_tipo_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.ausencias
    ADD CONSTRAINT ausencias_tipo_id_fkey FOREIGN KEY (tipo_id) REFERENCES rh.tipos_ausencia(id) ON DELETE RESTRICT;


--
-- Name: avaliacao_criterios avaliacao_criterios_avaliacao_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.avaliacao_criterios
    ADD CONSTRAINT avaliacao_criterios_avaliacao_id_fkey FOREIGN KEY (avaliacao_id) REFERENCES rh.avaliacoes(id) ON DELETE CASCADE;


--
-- Name: avaliacao_criterios avaliacao_criterios_criterio_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.avaliacao_criterios
    ADD CONSTRAINT avaliacao_criterios_criterio_id_fkey FOREIGN KEY (criterio_id) REFERENCES rh.criterios_avaliacao(id) ON DELETE RESTRICT;


--
-- Name: contactos_emergencia contactos_emergencia_funcionario_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.contactos_emergencia
    ADD CONSTRAINT contactos_emergencia_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: documentos_funcionario documentos_funcionario_funcionario_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.documentos_funcionario
    ADD CONSTRAINT documentos_funcionario_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: ausencias fk_ausencias_funcionario; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.ausencias
    ADD CONSTRAINT fk_ausencias_funcionario FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: avaliacoes fk_avaliacoes_funcionario; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.avaliacoes
    ADD CONSTRAINT fk_avaliacoes_funcionario FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: avaliacoes fk_avaliacoes_periodo; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.avaliacoes
    ADD CONSTRAINT fk_avaliacoes_periodo FOREIGN KEY (periodo_id) REFERENCES rh.periodos_avaliacao(id) ON DELETE SET NULL;


--
-- Name: contratos fk_contratos_funcionario; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.contratos
    ADD CONSTRAINT fk_contratos_funcionario FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: funcionarios fk_funcionarios_unidade; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT fk_funcionarios_unidade FOREIGN KEY (unit_id) REFERENCES rh.unidades_organizacionais(id) ON DELETE SET NULL;


--
-- Name: funcionarios fk_funcionarios_user; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT fk_funcionarios_user FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: processos_disciplinares fk_processos_disciplinares_funcionario; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.processos_disciplinares
    ADD CONSTRAINT fk_processos_disciplinares_funcionario FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: recibo_vencimento_itens fk_recibo_vencimento_itens_recibo; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.recibo_vencimento_itens
    ADD CONSTRAINT fk_recibo_vencimento_itens_recibo FOREIGN KEY (recibo_id) REFERENCES rh.recibos_vencimento(id) ON DELETE CASCADE;


--
-- Name: recibos_vencimento fk_recibos_vencimento_folha; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.recibos_vencimento
    ADD CONSTRAINT fk_recibos_vencimento_folha FOREIGN KEY (folha_id) REFERENCES rh.folhas_pagamento(id) ON DELETE CASCADE;


--
-- Name: recibos_vencimento fk_recibos_vencimento_funcionario; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.recibos_vencimento
    ADD CONSTRAINT fk_recibos_vencimento_funcionario FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: unidades_organizacionais fk_unidades_organizacionais_parent; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.unidades_organizacionais
    ADD CONSTRAINT fk_unidades_organizacionais_parent FOREIGN KEY (parent_id) REFERENCES rh.unidades_organizacionais(id) ON DELETE SET NULL;


--
-- Name: unidades_organizacionais fk_unidades_organizacionais_responsavel; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.unidades_organizacionais
    ADD CONSTRAINT fk_unidades_organizacionais_responsavel FOREIGN KEY (responsavel_id) REFERENCES rh.funcionarios(id) ON DELETE SET NULL;


--
-- Name: funcionario_beneficios funcionario_beneficios_beneficio_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionario_beneficios
    ADD CONSTRAINT funcionario_beneficios_beneficio_id_fkey FOREIGN KEY (beneficio_id) REFERENCES rh.beneficios(id) ON DELETE CASCADE;


--
-- Name: funcionario_beneficios funcionario_beneficios_funcionario_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionario_beneficios
    ADD CONSTRAINT funcionario_beneficios_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: funcionario_componentes_salariais funcionario_componentes_salariais_componente_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionario_componentes_salariais
    ADD CONSTRAINT funcionario_componentes_salariais_componente_id_fkey FOREIGN KEY (componente_id) REFERENCES rh.componentes_salariais(id) ON DELETE CASCADE;


--
-- Name: funcionario_componentes_salariais funcionario_componentes_salariais_funcionario_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionario_componentes_salariais
    ADD CONSTRAINT funcionario_componentes_salariais_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: funcionario_formacoes funcionario_formacoes_formacao_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionario_formacoes
    ADD CONSTRAINT funcionario_formacoes_formacao_id_fkey FOREIGN KEY (formacao_id) REFERENCES rh.formacoes(id) ON DELETE RESTRICT;


--
-- Name: funcionario_formacoes funcionario_formacoes_funcionario_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionario_formacoes
    ADD CONSTRAINT funcionario_formacoes_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: funcionarios funcionarios_cargo_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT funcionarios_cargo_id_fkey FOREIGN KEY (cargo_id) REFERENCES rh.cargos(id) ON DELETE SET NULL;


--
-- Name: funcionarios funcionarios_horario_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.funcionarios
    ADD CONSTRAINT funcionarios_horario_id_fkey FOREIGN KEY (horario_id) REFERENCES rh.horarios_trabalho(id) ON DELETE SET NULL;


--
-- Name: historico_salarial historico_salarial_funcionario_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.historico_salarial
    ADD CONSTRAINT historico_salarial_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: justificacoes justificacoes_aprovado_por_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.justificacoes
    ADD CONSTRAINT justificacoes_aprovado_por_fkey FOREIGN KEY (aprovado_por) REFERENCES auth.users(id);


--
-- Name: justificacoes justificacoes_funcionario_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.justificacoes
    ADD CONSTRAINT justificacoes_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: presencas presencas_funcionario_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.presencas
    ADD CONSTRAINT presencas_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: saldos_ausencia saldos_ausencia_funcionario_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.saldos_ausencia
    ADD CONSTRAINT saldos_ausencia_funcionario_id_fkey FOREIGN KEY (funcionario_id) REFERENCES rh.funcionarios(id) ON DELETE CASCADE;


--
-- Name: saldos_ausencia saldos_ausencia_tipo_ausencia_id_fkey; Type: FK CONSTRAINT; Schema: rh; Owner: -
--

ALTER TABLE ONLY rh.saldos_ausencia
    ADD CONSTRAINT saldos_ausencia_tipo_ausencia_id_fkey FOREIGN KEY (tipo_ausencia_id) REFERENCES rh.tipos_ausencia(id) ON DELETE CASCADE;


--
-- Name: stock_transfer_items fk_sti_item; Type: FK CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_transfer_items
    ADD CONSTRAINT fk_sti_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id);


--
-- Name: stock_transfer_items fk_sti_transfer; Type: FK CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_transfer_items
    ADD CONSTRAINT fk_sti_transfer FOREIGN KEY (stock_transfer_id) REFERENCES stock.stock_transfers(id) ON DELETE CASCADE;


--
-- Name: stock_adjustments fk_stock_adjustments_item; Type: FK CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_adjustments
    ADD CONSTRAINT fk_stock_adjustments_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id) ON DELETE CASCADE;


--
-- Name: stock_alerts fk_stock_alerts_item; Type: FK CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_alerts
    ADD CONSTRAINT fk_stock_alerts_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id) ON DELETE CASCADE;


--
-- Name: stock_batches fk_stock_batches_item; Type: FK CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_batches
    ADD CONSTRAINT fk_stock_batches_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id) ON DELETE CASCADE;


--
-- Name: stock_count_items fk_stock_count_items_count; Type: FK CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_count_items
    ADD CONSTRAINT fk_stock_count_items_count FOREIGN KEY (stock_count_id) REFERENCES stock.stock_counts(id) ON DELETE CASCADE;


--
-- Name: stock_movements fk_stock_movements_item; Type: FK CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_movements
    ADD CONSTRAINT fk_stock_movements_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id) ON DELETE CASCADE;


--
-- Name: stock_reservations fk_stock_reservations_item; Type: FK CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_reservations
    ADD CONSTRAINT fk_stock_reservations_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id) ON DELETE CASCADE;


--
-- Name: stock_serial_numbers fk_stock_serial_numbers_item; Type: FK CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.stock_serial_numbers
    ADD CONSTRAINT fk_stock_serial_numbers_item FOREIGN KEY (stock_item_id) REFERENCES stock.stock_items(id) ON DELETE CASCADE;


--
-- Name: warehouse_locations fk_warehouse_locations_warehouse; Type: FK CONSTRAINT; Schema: stock; Owner: -
--

ALTER TABLE ONLY stock.warehouse_locations
    ADD CONSTRAINT fk_warehouse_locations_warehouse FOREIGN KEY (warehouse_id) REFERENCES produtos.warehouses(id) ON DELETE CASCADE;


--
-- Name: movimentos_financeiros fk_mov_caixa; Type: FK CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.movimentos_financeiros
    ADD CONSTRAINT fk_mov_caixa FOREIGN KEY (caixa_id) REFERENCES tesouraria.caixas(id) ON DELETE SET NULL;


--
-- Name: movimentos_financeiros fk_mov_conta; Type: FK CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.movimentos_financeiros
    ADD CONSTRAINT fk_mov_conta FOREIGN KEY (conta_bancaria_id) REFERENCES tesouraria.contas_bancarias(id) ON DELETE SET NULL;


--
-- Name: reconciliacoes_bancarias fk_reconciliacoes_conta; Type: FK CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.reconciliacoes_bancarias
    ADD CONSTRAINT fk_reconciliacoes_conta FOREIGN KEY (conta_bancaria_id) REFERENCES tesouraria.contas_bancarias(id) ON DELETE RESTRICT;


--
-- Name: movements movements_bank_account_id_fkey; Type: FK CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.movements
    ADD CONSTRAINT movements_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES tesouraria.bank_accounts(id);


--
-- Name: movements movements_cash_register_id_fkey; Type: FK CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.movements
    ADD CONSTRAINT movements_cash_register_id_fkey FOREIGN KEY (cash_register_id) REFERENCES tesouraria.cash_registers(id);


--
-- Name: reconciliations reconciliations_bank_account_id_fkey; Type: FK CONSTRAINT; Schema: tesouraria; Owner: -
--

ALTER TABLE ONLY tesouraria.reconciliations
    ADD CONSTRAINT reconciliations_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES tesouraria.bank_accounts(id);


--
-- PostgreSQL database dump complete
--

\unrestrict iAhGjcg1cd8t3fAklZSYQOhZPUgxgUhb7nBGnjG0xtppwgHrh7e6TKkDYq5um2h

