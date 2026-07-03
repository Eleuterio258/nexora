DO $$
DECLARE
  v_ativo_id bigint;
  v_receita_id bigint;
  v_year_id bigint;
  v_period_id bigint;
  v_journal_id bigint;
  v_serie_id bigint;
  v_pm_id bigint;
  v_fc_id bigint;
  v_account_client bigint;
  v_account_bank bigint;
  v_account_revenue bigint;
  v_prod_cat_id bigint;
  v_prod_id bigint;
  fee record;
  v_invoice_id bigint;
  v_inv_num text;
  v_ar_id bigint;
  v_pay_id bigint;
  v_je_id bigint;
BEGIN
  INSERT INTO contabilidade.account_types (tenant_id, codigo, nome, classe, natureza)
  VALUES (5, 'ATIVO', 'Ativo', 'ativo', 'devedora')
  ON CONFLICT DO NOTHING RETURNING id INTO v_ativo_id;
  IF v_ativo_id IS NULL THEN SELECT id INTO v_ativo_id FROM contabilidade.account_types WHERE tenant_id = 5 AND codigo = 'ATIVO'; END IF;

  INSERT INTO contabilidade.account_types (tenant_id, codigo, nome, classe, natureza)
  VALUES (5, 'RENDIMENTO', 'Rendimento', 'rendimento', 'credora')
  ON CONFLICT DO NOTHING RETURNING id INTO v_receita_id;
  IF v_receita_id IS NULL THEN SELECT id INTO v_receita_id FROM contabilidade.account_types WHERE tenant_id = 5 AND codigo = 'RENDIMENTO'; END IF;

  INSERT INTO contabilidade.fiscal_years (tenant_id, ano, data_inicio, data_fim, status)
  VALUES (5, 2026, '2026-01-01', '2026-12-31', 'aberto')
  ON CONFLICT DO NOTHING RETURNING id INTO v_year_id;
  IF v_year_id IS NULL THEN SELECT id INTO v_year_id FROM contabilidade.fiscal_years WHERE tenant_id = 5 AND ano = 2026; END IF;

  INSERT INTO contabilidade.fiscal_periods (tenant_id, fiscal_year_id, ano, mes, data_inicio, data_fim, status)
  VALUES (5, v_year_id, 2026, 2, '2026-02-01', '2026-02-28', 'aberto')
  ON CONFLICT DO NOTHING RETURNING id INTO v_period_id;
  IF v_period_id IS NULL THEN SELECT id INTO v_period_id FROM contabilidade.fiscal_periods WHERE tenant_id = 5 AND ano = 2026 AND mes = 2; END IF;

  INSERT INTO contabilidade.accounting_journals (tenant_id, codigo, nome, tipo, ativo)
  VALUES (5, 'GERAL', 'Diario Geral', 'geral', true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_journal_id;
  IF v_journal_id IS NULL THEN SELECT id INTO v_journal_id FROM contabilidade.accounting_journals WHERE tenant_id = 5 AND codigo = 'GERAL'; END IF;

  INSERT INTO faturacao.invoice_series (tenant_id, tipo, prefixo, ano, sequencia, ativo)
  VALUES (5, 'FT', 'FT', 2026, 1, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_serie_id;
  IF v_serie_id IS NULL THEN SELECT id INTO v_serie_id FROM faturacao.invoice_series WHERE tenant_id = 5 AND tipo = 'FT' AND ano = 2026; END IF;

  INSERT INTO financeiro.payment_methods (tenant_id, codigo, nome, tipo, requer_referencia, ativo)
  VALUES (5, 'MPESA', 'M-Pesa', 'mpesa', false, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_pm_id;
  IF v_pm_id IS NULL THEN SELECT id INTO v_pm_id FROM financeiro.payment_methods WHERE tenant_id = 5 AND codigo = 'MPESA'; END IF;

  INSERT INTO financeiro.financial_categories (tenant_id, codigo, nome, tipo, ativo)
  VALUES (5, 'PROPINA', 'Propinas', 'receita', true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_fc_id;
  IF v_fc_id IS NULL THEN SELECT id INTO v_fc_id FROM financeiro.financial_categories WHERE tenant_id = 5 AND codigo = 'PROPINA'; END IF;

  INSERT INTO contabilidade.chart_of_accounts (tenant_id, codigo, nome, account_type_id, aceita_lancamento, ativo)
  VALUES (5, '411100', 'Clientes - Alunos', v_ativo_id, true, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_account_client;
  IF v_account_client IS NULL THEN SELECT id INTO v_account_client FROM contabilidade.chart_of_accounts WHERE tenant_id = 5 AND codigo = '411100'; END IF;

  INSERT INTO contabilidade.chart_of_accounts (tenant_id, codigo, nome, account_type_id, aceita_lancamento, ativo)
  VALUES (5, '121100', 'Caixa / Banco', v_ativo_id, true, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_account_bank;
  IF v_account_bank IS NULL THEN SELECT id INTO v_account_bank FROM contabilidade.chart_of_accounts WHERE tenant_id = 5 AND codigo = '121100'; END IF;

  INSERT INTO contabilidade.chart_of_accounts (tenant_id, codigo, nome, account_type_id, aceita_lancamento, ativo)
  VALUES (5, '711100', 'Receita de Propinas', v_receita_id, true, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_account_revenue;
  IF v_account_revenue IS NULL THEN SELECT id INTO v_account_revenue FROM contabilidade.chart_of_accounts WHERE tenant_id = 5 AND codigo = '711100'; END IF;

  INSERT INTO produtos.product_categories (tenant_id, codigo, nome, ativo)
  VALUES (5, 'SERVICOS', 'Servicos', true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_prod_cat_id;
  IF v_prod_cat_id IS NULL THEN SELECT id INTO v_prod_cat_id FROM produtos.product_categories WHERE tenant_id = 5 AND codigo = 'SERVICOS'; END IF;

  INSERT INTO produtos.products (tenant_id, product_category_id, codigo, nome, descricao, tipo, iva_percentual, stock_minimo, ativo)
  VALUES (5, v_prod_cat_id, 'PROPINA', 'Propina', 'Mensalidade escolar', 'servico', 0, 0, true)
  ON CONFLICT DO NOTHING RETURNING id INTO v_prod_id;
  IF v_prod_id IS NULL THEN SELECT id INTO v_prod_id FROM produtos.products WHERE tenant_id = 5 AND codigo = 'PROPINA'; END IF;

  FOR fee IN
    SELECT f.id, f.student_id, f.enrollment_id, f.numero, f.descricao, f.valor_total, f.valor_pago, f.status, f.data_vencimento, s.client_id, c.id AS customer_id
    FROM gestao_escolar.school_fees f
    JOIN gestao_escolar.school_students s ON s.id = f.student_id
    JOIN clientes.customers c ON c.id = s.client_id
    WHERE f.tenant_id = 5 AND s.codigo LIKE 'ALU-PFA-2026-%'
  LOOP
    v_inv_num := fee.numero;

    INSERT INTO faturacao.invoices (tenant_id, serie_id, customer_id, numero, invoice_date, due_date, moeda, taxa_cambio, subtotal, desconto_total, imposto_total, total, valor_pago, status, tipo, observacoes, criado_por)
    VALUES (5, v_serie_id, fee.customer_id, v_inv_num, CURRENT_DATE, fee.data_vencimento, 'MZN', 1, fee.valor_total, 0, 0, fee.valor_total, fee.valor_pago,
      CASE
        WHEN fee.status = 'paga' THEN 'paga'
        WHEN fee.valor_pago > 0 THEN 'parcialmente_paga'
        ELSE 'emitida'
      END,
      'normal', fee.descricao, 13)
    ON CONFLICT DO NOTHING RETURNING id INTO v_invoice_id;

    IF v_invoice_id IS NULL THEN
      SELECT id INTO v_invoice_id FROM faturacao.invoices WHERE tenant_id = 5 AND numero = v_inv_num;
    END IF;

    INSERT INTO faturacao.invoice_items (invoice_id, product_id, descricao, quantidade, preco_unitario, desconto_percent, desconto_valor, imposto_percent, imposto_valor, subtotal, total)
    VALUES (v_invoice_id, v_prod_id, fee.descricao, 1, fee.valor_total, 0, 0, 0, 0, fee.valor_total, fee.valor_total)
    ON CONFLICT DO NOTHING;

    INSERT INTO financeiro.accounts_receivable (tenant_id, numero, customer_id, financial_category_id, origem_tipo, origem_id, descricao, valor_total, valor_pago, data_emissao, data_vencimento, status)
    VALUES (5, 'AR-' || v_inv_num, fee.customer_id, v_fc_id, 'invoice', v_invoice_id, fee.descricao, fee.valor_total, fee.valor_pago, CURRENT_DATE, fee.data_vencimento,
      CASE
        WHEN fee.status = 'paga' THEN 'liquidada'
        WHEN fee.valor_pago > 0 THEN 'parcial'
        ELSE 'pendente'
      END)
    ON CONFLICT DO NOTHING RETURNING id INTO v_ar_id;

    IF v_ar_id IS NULL THEN
      SELECT id INTO v_ar_id FROM financeiro.accounts_receivable WHERE tenant_id = 5 AND numero = 'AR-' || v_inv_num;
    END IF;

    IF fee.status = 'paga' THEN
      INSERT INTO financeiro.payments (tenant_id, numero, payment_method_id, financial_category_id, tipo, data_pagamento, valor, moeda, referencia_tipo, referencia_id, descricao, status, criado_por)
      VALUES (5, 'PAY-' || v_inv_num, v_pm_id, v_fc_id, 'recebimento', CURRENT_DATE, fee.valor_pago, 'MZN', 'accounts_receivable', v_ar_id, 'Pagamento ' || fee.descricao, 'confirmado', 13)
      ON CONFLICT DO NOTHING RETURNING id INTO v_pay_id;

      INSERT INTO contabilidade.journal_entries (tenant_id, fiscal_period_id, accounting_journal_id, numero, entry_date, descricao, referencia_tipo, referencia_id, status, moeda, total_debito, total_credito, criado_por)
      VALUES (5, v_period_id, v_journal_id, 'LC-' || v_inv_num, CURRENT_DATE, 'Recebimento ' || fee.descricao, 'payment', v_pay_id, 'publicado', 'MZN', fee.valor_pago, fee.valor_pago, 13)
      ON CONFLICT DO NOTHING RETURNING id INTO v_je_id;

      INSERT INTO contabilidade.journal_entry_lines (journal_entry_id, account_id, descricao, debit, credit)
      VALUES
        (v_je_id, v_account_bank, 'Caixa/Banco', fee.valor_pago, 0),
        (v_je_id, v_account_client, 'Cliente', 0, fee.valor_pago),
        (v_je_id, v_account_client, 'Cliente', fee.valor_pago, 0),
        (v_je_id, v_account_revenue, 'Receita', 0, fee.valor_pago);
    END IF;
  END LOOP;
END $$;
