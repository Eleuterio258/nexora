SET search_path TO stock, produtos, public;

ALTER TABLE stock_transfers
    ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS received_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

ALTER TABLE stock_reservations
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE stock_counts
    ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

ALTER TABLE stock_alerts
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE UNIQUE INDEX IF NOT EXISTS uq_stock_count_items
    ON stock_count_items (stock_count_id, stock_item_id);
CREATE INDEX IF NOT EXISTS idx_stock_reservations_tenant_status
    ON stock_reservations (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_stock_batches_expiry
    ON stock_batches (expiry_date);
CREATE INDEX IF NOT EXISTS idx_stock_counts_tenant_status
    ON stock_counts (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_stock_alerts_tenant_status
    ON stock_alerts (tenant_id, status);

CREATE OR REPLACE FUNCTION fn_reservar_stock(
    p_tenant_id BIGINT,
    p_stock_item_id BIGINT,
    p_quantity NUMERIC,
    p_reference_type VARCHAR DEFAULT NULL,
    p_reference_id BIGINT DEFAULT NULL
) RETURNS BIGINT
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

CREATE OR REPLACE FUNCTION fn_liberar_reserva(
    p_tenant_id BIGINT,
    p_reservation_id BIGINT
) RETURNS VOID
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

CREATE OR REPLACE FUNCTION fn_consumir_reserva(
    p_tenant_id BIGINT,
    p_reservation_id BIGINT
) RETURNS VOID
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
