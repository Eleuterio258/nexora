package handlers

import (
	"net/http"

	mw "nexora/internal/middleware"
)

func (h *Handler) CriarRecepcaoCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := purchaseBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.purchaseCreate(w, r, `INSERT INTO compras.goods_receipts
		(tenant_id,purchase_order_id,supplier_id,numero,receipt_date,warehouse_id,status,
		supplier_document,observacoes,criado_por)
		SELECT $1,o.id,o.supplier_id,j.numero,COALESCE(j.receipt_date,CURRENT_DATE),j.warehouse_id,
		'confirmado',j.supplier_document,j.observacoes,$3
		FROM jsonb_to_record($2::jsonb) AS j(purchase_order_id bigint,numero text,receipt_date date,
		warehouse_id bigint,supplier_document text,observacoes text)
		JOIN compras.purchase_orders o ON o.id=j.purchase_order_id AND o.tenant_id=$1
		JOIN produtos.warehouses w ON w.id=j.warehouse_id AND w.tenant_id=$1
		WHERE j.numero<>'' AND o.status IN ('aprovada','parcial') RETURNING goods_receipts.id`,
		u.TenantID, body, u.ID)
}

func (h *Handler) ListarRecepcoesCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "r.tenant_id=$1"
	args := []any{u.TenantID}
	addPurchaseFilter(&where, &args, "r.supplier_id", r.URL.Query().Get("supplier_id"))
	addPurchaseFilter(&where, &args, "r.purchase_order_id", r.URL.Query().Get("purchase_order_id"))
	addPurchaseFilter(&where, &args, "r.status", r.URL.Query().Get("status"))
	h.purchaseList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.receipt_date DESC,x.id DESC),'[]') FROM (
		SELECT r.*,s.nome supplier_name,o.numero purchase_order_number,
		COALESCE((SELECT jsonb_agg(to_jsonb(i) ORDER BY i.id) FROM compras.goods_receipt_items i
		WHERE i.goods_receipt_id=r.id),'[]') items FROM compras.goods_receipts r
		JOIN compras.suppliers s ON s.id=r.supplier_id JOIN compras.purchase_orders o ON o.id=r.purchase_order_id
		WHERE `+where+`) x`, args...)
}

func (h *Handler) AdicionarItemRecepcaoCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := purchaseBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var itemID, orderItemID, orderID, productID, warehouseID int64
	var quantity float64
	err = tx.QueryRow(r.Context(), `INSERT INTO compras.goods_receipt_items
		(goods_receipt_id,purchase_order_item_id,product_id,quantity_received,unit_cost,lote,validade)
		SELECT r.id,i.id,i.product_id,j.quantity_received,COALESCE(j.unit_cost,i.unit_price),j.lote,j.validade
		FROM jsonb_to_record($2::jsonb) AS j(goods_receipt_id bigint,purchase_order_item_id bigint,
		quantity_received numeric,unit_cost numeric,lote text,validade date)
		JOIN compras.goods_receipts r ON r.id=j.goods_receipt_id AND r.tenant_id=$1 AND r.status='confirmado'
		JOIN compras.purchase_order_items i ON i.id=j.purchase_order_item_id AND i.purchase_order_id=r.purchase_order_id
		WHERE i.product_id IS NOT NULL AND j.quantity_received>0
		AND i.received_quantity+j.quantity_received<=i.quantity
		RETURNING goods_receipt_items.id,purchase_order_item_id,
		(SELECT purchase_order_id FROM compras.purchase_order_items WHERE id=purchase_order_item_id),
		product_id,quantity_received,
		(SELECT warehouse_id FROM compras.goods_receipts WHERE id=goods_receipt_id)`,
		u.TenantID, body).Scan(&itemID, &orderItemID, &orderID, &productID, &quantity, &warehouseID)
	if err != nil {
		jsonErr(w, "Recepcao, produto ou quantidade invalida", http.StatusUnprocessableEntity)
		return
	}
	_, err = tx.Exec(r.Context(), `UPDATE compras.purchase_order_items SET
		received_quantity=received_quantity+$1 WHERE id=$2`, quantity, orderItemID)
	if err == nil {
		_, err = tx.Exec(r.Context(), `INSERT INTO stock.stock_items
			(tenant_id,product_id,warehouse_id,quantity,reserved_quantity,minimum_quantity)
			VALUES($1,$2,$3,$4,0,0)
			ON CONFLICT(tenant_id,product_id,product_variant_id,warehouse_id)
			DO UPDATE SET quantity=stock.stock_items.quantity+EXCLUDED.quantity,updated_at=NOW()`,
			u.TenantID, productID, warehouseID, quantity)
	}
	var stockItemID int64
	if err == nil {
		err = tx.QueryRow(r.Context(), `SELECT id FROM stock.stock_items WHERE tenant_id=$1
			AND product_id=$2 AND warehouse_id=$3 AND product_variant_id IS NULL`,
			u.TenantID, productID, warehouseID).Scan(&stockItemID)
	}
	if err == nil {
		_, err = tx.Exec(r.Context(), `INSERT INTO stock.stock_movements
			(tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id)
			VALUES($1,$2,'entrada',$3,'purchase_receipt',$4)`,
			u.TenantID, stockItemID, quantity, itemID)
	}
	if err == nil {
		_, err = tx.Exec(r.Context(), `UPDATE compras.purchase_orders o SET status=CASE
			WHEN NOT EXISTS(SELECT 1 FROM compras.purchase_order_items i
				WHERE i.purchase_order_id=o.id AND i.received_quantity<i.quantity)
			THEN 'recebida' ELSE 'parcial' END,updated_at=NOW() WHERE o.id=$1`, orderID)
	}
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao actualizar stock da recepcao", 500)
		return
	}
	jsonOK(w, map[string]any{"id": itemID}, http.StatusCreated)
}

func (h *Handler) CriarDevolucaoCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := purchaseBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.purchaseCreate(w, r, `INSERT INTO compras.purchase_returns
		(tenant_id,supplier_id,goods_receipt_id,warehouse_id,numero,return_date,motivo,status,observacoes,criado_por)
		SELECT $1,r.supplier_id,r.id,r.warehouse_id,j.numero,COALESCE(j.return_date,CURRENT_DATE),j.motivo,
		'confirmada',j.observacoes,$3 FROM jsonb_to_record($2::jsonb)
		AS j(goods_receipt_id bigint,numero text,return_date date,motivo text,observacoes text)
		JOIN compras.goods_receipts r ON r.id=j.goods_receipt_id AND r.tenant_id=$1 AND r.status='confirmado'
		WHERE j.numero<>'' AND j.motivo<>'' RETURNING purchase_returns.id`, u.TenantID, body, u.ID)
}

func (h *Handler) ListarDevolucoesCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "r.tenant_id=$1"
	args := []any{u.TenantID}
	addPurchaseFilter(&where, &args, "r.supplier_id", r.URL.Query().Get("supplier_id"))
	addPurchaseFilter(&where, &args, "r.status", r.URL.Query().Get("status"))
	h.purchaseList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.return_date DESC,x.id DESC),'[]') FROM (
		SELECT r.*,s.nome supplier_name,COALESCE((SELECT jsonb_agg(to_jsonb(i) ORDER BY i.id)
		FROM compras.purchase_return_items i WHERE i.purchase_return_id=r.id),'[]') items
		FROM compras.purchase_returns r JOIN compras.suppliers s ON s.id=r.supplier_id WHERE `+where+`) x`, args...)
}

func (h *Handler) AdicionarItemDevolucaoCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := purchaseBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var id, receiptItemID, returnID, productID, warehouseID int64
	var quantity, total float64
	err = tx.QueryRow(r.Context(), `INSERT INTO compras.purchase_return_items
		(purchase_return_id,goods_receipt_item_id,product_id,quantity,unit_cost,total)
		SELECT r.id,i.id,i.product_id,j.quantity,COALESCE(j.unit_cost,i.unit_cost),
		ROUND(j.quantity*COALESCE(j.unit_cost,i.unit_cost),2)
		FROM jsonb_to_record($2::jsonb) AS j(purchase_return_id bigint,goods_receipt_item_id bigint,
		quantity numeric,unit_cost numeric)
		JOIN compras.purchase_returns r ON r.id=j.purchase_return_id AND r.tenant_id=$1 AND r.status='confirmada'
		JOIN compras.goods_receipt_items i ON i.id=j.goods_receipt_item_id AND i.goods_receipt_id=r.goods_receipt_id
		WHERE i.product_id IS NOT NULL AND j.quantity>0 AND i.returned_quantity+j.quantity<=i.quantity_received
		RETURNING purchase_return_items.id,goods_receipt_item_id,purchase_return_id,product_id,quantity,total,
		(SELECT warehouse_id FROM compras.purchase_returns WHERE id=purchase_return_id)`,
		u.TenantID, body).Scan(&id, &receiptItemID, &returnID, &productID, &quantity, &total, &warehouseID)
	if err != nil {
		jsonErr(w, "Devolucao ou quantidade invalida", http.StatusUnprocessableEntity)
		return
	}
	var stockItemID int64
	err = tx.QueryRow(r.Context(), `UPDATE stock.stock_items SET quantity=quantity-$1,updated_at=NOW()
		WHERE tenant_id=$2 AND product_id=$3 AND warehouse_id=$4 AND product_variant_id IS NULL
		AND quantity-reserved_quantity>=$1 RETURNING id`, quantity, u.TenantID, productID, warehouseID).Scan(&stockItemID)
	if err == nil {
		_, err = tx.Exec(r.Context(), `UPDATE compras.goods_receipt_items SET
			returned_quantity=returned_quantity+$1 WHERE id=$2`, quantity, receiptItemID)
	}
	if err == nil {
		_, err = tx.Exec(r.Context(), `UPDATE compras.purchase_returns SET total=total+$1,updated_at=NOW() WHERE id=$2`,
			total, returnID)
	}
	if err == nil {
		_, err = tx.Exec(r.Context(), `INSERT INTO stock.stock_movements
			(tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id)
			VALUES($1,$2,'saida',$3,'purchase_return',$4)`, u.TenantID, stockItemID, quantity, id)
	}
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Stock insuficiente para devolucao", http.StatusConflict)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}
