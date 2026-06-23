-- Funcoes do modulo de Gestao de Clientes

CREATE OR REPLACE FUNCTION fn_customer_credit_available(p_customer_id BIGINT)
RETURNS NUMERIC(18,2) AS $$
DECLARE
    v_limite NUMERIC(18,2);
    v_saldo NUMERIC(18,2);
BEGIN
    SELECT COALESCE(ccl.limite_credito, 0), COALESCE(cb.saldo_atual, 0)
      INTO v_limite, v_saldo
      FROM customers c
 LEFT JOIN customer_credit_limits ccl ON ccl.customer_id = c.id AND ccl.ativo = TRUE
 LEFT JOIN customer_balances cb ON cb.customer_id = c.id
     WHERE c.id = p_customer_id;

    RETURN v_limite - v_saldo;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_customer_can_buy_on_credit(p_customer_id BIGINT, p_valor NUMERIC)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN fn_customer_credit_available(p_customer_id) >= COALESCE(p_valor, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_update_customer_balance(
    p_customer_id BIGINT,
    p_novo_saldo NUMERIC,
    p_saldo_vencido NUMERIC DEFAULT 0
)
RETURNS VOID AS $$
DECLARE
    v_credito_disponivel NUMERIC(18,2);
BEGIN
    v_credito_disponivel := fn_customer_credit_available(p_customer_id) - COALESCE(p_novo_saldo, 0) + COALESCE((SELECT saldo_atual FROM customer_balances WHERE customer_id = p_customer_id), 0);

    INSERT INTO customer_balances (customer_id, saldo_atual, saldo_vencido, credito_disponivel, updated_at)
    VALUES (p_customer_id, COALESCE(p_novo_saldo, 0), COALESCE(p_saldo_vencido, 0), v_credito_disponivel, CURRENT_TIMESTAMP)
    ON CONFLICT (customer_id)
    DO UPDATE SET
        saldo_atual = EXCLUDED.saldo_atual,
        saldo_vencido = EXCLUDED.saldo_vencido,
        credito_disponivel = EXCLUDED.credito_disponivel,
        updated_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;
