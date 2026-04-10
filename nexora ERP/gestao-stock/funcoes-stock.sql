-- Funcoes do modulo de Gestao de Stock

-- Quantidade disponivel de um produto num armazem (quantity - reserved_quantity)
CREATE OR REPLACE FUNCTION fn_stock_disponivel(
    p_product_id   BIGINT,
    p_warehouse_id BIGINT
)
RETURNS NUMERIC(18,2) LANGUAGE plpgsql STABLE AS $$
DECLARE
    v_disponivel NUMERIC(18,2);
BEGIN
    SELECT available_quantity
      INTO v_disponivel
      FROM stock_items
     WHERE product_id  = p_product_id
       AND warehouse_id = p_warehouse_id
     LIMIT 1;

    RETURN COALESCE(v_disponivel, 0);
END;
$$;

-- Verifica se existe quantidade suficiente para transferencia
CREATE OR REPLACE FUNCTION fn_pode_transferir_stock(
    p_product_id   BIGINT,
    p_warehouse_id BIGINT,
    p_quantidade   NUMERIC
)
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN fn_stock_disponivel(p_product_id, p_warehouse_id) >= COALESCE(p_quantidade, 0);
END;
$$;

-- Reservar stock: cria reserva e actualiza reserved_quantity e available_quantity
CREATE OR REPLACE FUNCTION fn_reservar_stock(
    p_product_id     BIGINT,
    p_warehouse_id   BIGINT,
    p_quantidade     NUMERIC,
    p_reference_type VARCHAR,
    p_reference_id   BIGINT
)
RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE
    v_stock_item_id   BIGINT;
    v_reserva_id      BIGINT;
    v_disponivel      NUMERIC(18,2);
BEGIN
    -- Obter stock_item
    SELECT id, available_quantity
      INTO v_stock_item_id, v_disponivel
      FROM stock_items
     WHERE product_id   = p_product_id
       AND warehouse_id  = p_warehouse_id
     FOR UPDATE;

    IF v_stock_item_id IS NULL THEN
        RAISE EXCEPTION 'Stock nao encontrado para produto % no armazem %',
            p_product_id, p_warehouse_id;
    END IF;

    IF v_disponivel < p_quantidade THEN
        RAISE EXCEPTION 'Stock insuficiente: disponivel=%, solicitado=%',
            v_disponivel, p_quantidade;
    END IF;

    -- Criar reserva
    INSERT INTO stock_reservations (
        tenant_id, stock_item_id, quantity, reference_type, reference_id, status
    )
    SELECT si.tenant_id, v_stock_item_id, p_quantidade, p_reference_type, p_reference_id, 'ativa'
      FROM stock_items si WHERE si.id = v_stock_item_id
    RETURNING id INTO v_reserva_id;

    -- Actualizar quantidades
    UPDATE stock_items
       SET reserved_quantity  = reserved_quantity + p_quantidade,
           available_quantity = available_quantity - p_quantidade,
           updated_at         = CURRENT_TIMESTAMP
     WHERE id = v_stock_item_id;

    RETURN v_reserva_id;
END;
$$;

-- Liberar reserva: cancela reserva e devolve a available_quantity
CREATE OR REPLACE FUNCTION fn_liberar_reserva(p_reserva_id BIGINT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    v_stock_item_id BIGINT;
    v_quantidade    NUMERIC(18,2);
BEGIN
    SELECT stock_item_id, quantity
      INTO v_stock_item_id, v_quantidade
      FROM stock_reservations
     WHERE id = p_reserva_id AND status = 'ativa'
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reserva % nao encontrada ou ja nao esta activa', p_reserva_id;
    END IF;

    UPDATE stock_reservations SET status = 'cancelada' WHERE id = p_reserva_id;

    UPDATE stock_items
       SET reserved_quantity  = GREATEST(reserved_quantity - v_quantidade, 0),
           available_quantity = available_quantity + v_quantidade,
           updated_at         = CURRENT_TIMESTAMP
     WHERE id = v_stock_item_id;
END;
$$;

-- Consumir reserva: marca como consumida e regista movimento de saida
CREATE OR REPLACE FUNCTION fn_consumir_reserva(
    p_reserva_id     BIGINT,
    p_reference_type VARCHAR,
    p_reference_id   BIGINT
)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    v_stock_item_id BIGINT;
    v_tenant_id     BIGINT;
    v_quantidade    NUMERIC(18,2);
BEGIN
    SELECT sr.stock_item_id, si.tenant_id, sr.quantity
      INTO v_stock_item_id, v_tenant_id, v_quantidade
      FROM stock_reservations sr
      JOIN stock_items si ON si.id = sr.stock_item_id
     WHERE sr.id = p_reserva_id AND sr.status = 'ativa'
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reserva % nao encontrada ou ja nao esta activa', p_reserva_id;
    END IF;

    -- Marcar reserva como consumida
    UPDATE stock_reservations SET status = 'consumida' WHERE id = p_reserva_id;

    -- Reduzir quantity e reserved_quantity
    UPDATE stock_items
       SET quantity           = quantity - v_quantidade,
           reserved_quantity  = GREATEST(reserved_quantity - v_quantidade, 0),
           updated_at         = CURRENT_TIMESTAMP
     WHERE id = v_stock_item_id;

    -- Registar movimento de saida
    INSERT INTO stock_movements (tenant_id, stock_item_id, tipo, quantity, reference_type, reference_id)
    VALUES (v_tenant_id, v_stock_item_id, 'saida', v_quantidade, p_reference_type, p_reference_id);
END;
$$;
