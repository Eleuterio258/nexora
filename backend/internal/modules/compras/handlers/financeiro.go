package handlers

import (
	"net/http"

	mw "nexora/internal/middleware"
)

func (h *Handler) CriarFacturaCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := purchaseBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.purchaseCreate(w, r, `INSERT INTO compras.purchase_invoices
		(tenant_id,supplier_id,purchase_order_id,goods_receipt_id,numero,supplier_invoice_number,
		invoice_date,due_date,moeda,status,observacoes,criado_por)
		SELECT $1,s.id,j.purchase_order_id,j.goods_receipt_id,j.numero,j.supplier_invoice_number,
		COALESCE(j.invoice_date,CURRENT_DATE),j.due_date,COALESCE(j.moeda,s.moeda_padrao),
		COALESCE(j.status,'rascunho'),j.observacoes,$3
		FROM jsonb_to_record($2::jsonb) AS j(supplier_id bigint,purchase_order_id bigint,goods_receipt_id bigint,
		numero text,supplier_invoice_number text,invoice_date date,due_date date,moeda text,status text,observacoes text)
		JOIN compras.suppliers s ON s.id=j.supplier_id AND s.tenant_id=$1
		WHERE j.numero<>'' AND j.due_date IS NOT NULL RETURNING purchase_invoices.id`, u.TenantID, body, u.ID)
}

func (h *Handler) ListarFacturasCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "i.tenant_id=$1"
	args := []any{u.TenantID}
	addPurchaseFilter(&where, &args, "i.supplier_id", r.URL.Query().Get("supplier_id"))
	addPurchaseFilter(&where, &args, "i.status", r.URL.Query().Get("status"))
	h.purchaseList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.invoice_date DESC,x.id DESC),'[]') FROM (
		SELECT i.*,s.nome supplier_name,GREATEST(i.total-i.valor_pago,0) valor_pendente,
		COALESCE((SELECT jsonb_agg(to_jsonb(ii) ORDER BY ii.id) FROM compras.purchase_invoice_items ii
		WHERE ii.purchase_invoice_id=i.id),'[]') items FROM compras.purchase_invoices i
		JOIN compras.suppliers s ON s.id=i.supplier_id WHERE `+where+`) x`, args...)
}

func (h *Handler) AdicionarItemFacturaCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := purchaseBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var id, invoiceID int64
	err = tx.QueryRow(r.Context(), `INSERT INTO compras.purchase_invoice_items
		(purchase_invoice_id,purchase_order_item_id,product_id,descricao,unidade,quantity,
		unit_price,desconto,tax_rate,tax_amount,total)
		SELECT i.id,j.purchase_order_item_id,j.product_id,COALESCE(NULLIF(j.descricao,''),p.nome),
		COALESCE(j.unidade,'UN'),j.quantity,j.unit_price,COALESCE(j.desconto,0),COALESCE(j.tax_rate,0),
		ROUND(GREATEST(j.quantity*j.unit_price-COALESCE(j.desconto,0),0)*COALESCE(j.tax_rate,0)/100,2),
		ROUND(GREATEST(j.quantity*j.unit_price-COALESCE(j.desconto,0),0)*(1+COALESCE(j.tax_rate,0)/100),2)
		FROM jsonb_to_record($2::jsonb) AS j(purchase_invoice_id bigint,purchase_order_item_id bigint,
		product_id bigint,descricao text,unidade text,quantity numeric,unit_price numeric,desconto numeric,tax_rate numeric)
		JOIN compras.purchase_invoices i ON i.id=j.purchase_invoice_id AND i.tenant_id=$1 AND i.status='rascunho'
		LEFT JOIN produtos.products p ON p.id=j.product_id AND p.tenant_id=$1
		WHERE j.quantity>0 AND j.unit_price>=0 AND COALESCE(NULLIF(j.descricao,''),p.nome) IS NOT NULL
		RETURNING purchase_invoice_items.id,purchase_invoice_id`, u.TenantID, body).Scan(&id, &invoiceID)
	if err != nil {
		jsonErr(w, "Factura ou item invalido", http.StatusUnprocessableEntity)
		return
	}
	_, err = tx.Exec(r.Context(), `UPDATE compras.purchase_invoices i SET
		subtotal=x.subtotal,desconto_total=x.desconto,imposto_total=x.imposto,total=x.total,
		status='emitida',updated_at=NOW() FROM (
		SELECT purchase_invoice_id,SUM(quantity*unit_price) subtotal,SUM(desconto) desconto,
		SUM(tax_amount) imposto,SUM(total) total FROM compras.purchase_invoice_items
		WHERE purchase_invoice_id=$1 GROUP BY purchase_invoice_id) x WHERE i.id=x.purchase_invoice_id`, invoiceID)
	if err == nil {
		_, err = tx.Exec(r.Context(), `INSERT INTO financeiro.accounts_payable
			(tenant_id,numero,supplier_id,origem_tipo,origem_id,descricao,valor_total,valor_pago,
			data_emissao,data_vencimento,status)
			SELECT tenant_id,numero,supplier_id,'purchase_invoice',id,'Factura de fornecedor '||numero,
			total,valor_pago,invoice_date,due_date,
			CASE WHEN valor_pago=0 THEN 'pendente' ELSE 'parcial' END
			FROM compras.purchase_invoices WHERE id=$1
			ON CONFLICT(tenant_id,numero) DO UPDATE SET valor_total=EXCLUDED.valor_total,
			data_vencimento=EXCLUDED.data_vencimento`, invoiceID)
	}
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao recalcular factura", 500)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) CriarPagamentoCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := purchaseBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.purchaseCreate(w, r, `INSERT INTO compras.purchase_payments
		(tenant_id,supplier_id,numero,payment_date,metodo,referencia,moeda,valor,status,observacoes,criado_por)
		SELECT $1,s.id,j.numero,COALESCE(j.payment_date,CURRENT_DATE),j.metodo,j.referencia,
		COALESCE(j.moeda,s.moeda_padrao),j.valor,COALESCE(j.status,'confirmado'),j.observacoes,$3
		FROM jsonb_to_record($2::jsonb) AS j(supplier_id bigint,numero text,payment_date date,
		metodo text,referencia text,moeda text,valor numeric,status text,observacoes text)
		JOIN compras.suppliers s ON s.id=j.supplier_id AND s.tenant_id=$1
		WHERE j.numero<>'' AND j.metodo<>'' AND j.valor>0 RETURNING purchase_payments.id`, u.TenantID, body, u.ID)
}

func (h *Handler) ListarPagamentosCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "p.tenant_id=$1"
	args := []any{u.TenantID}
	addPurchaseFilter(&where, &args, "p.supplier_id", r.URL.Query().Get("supplier_id"))
	addPurchaseFilter(&where, &args, "p.status", r.URL.Query().Get("status"))
	h.purchaseList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.payment_date DESC,x.id DESC),'[]') FROM (
		SELECT p.*,s.nome supplier_name,p.valor-p.valor_alocado valor_disponivel,
		COALESCE((SELECT jsonb_agg(to_jsonb(pi) ORDER BY pi.id) FROM compras.purchase_payment_items pi
		WHERE pi.purchase_payment_id=p.id),'[]') items FROM compras.purchase_payments p
		JOIN compras.suppliers s ON s.id=p.supplier_id WHERE `+where+`) x`, args...)
}

func (h *Handler) AdicionarItemPagamentoCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := purchaseBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var id, paymentID, invoiceID int64
	var amount float64
	err = tx.QueryRow(r.Context(), `INSERT INTO compras.purchase_payment_items
		(purchase_payment_id,purchase_invoice_id,valor)
		SELECT p.id,i.id,j.valor FROM jsonb_to_record($2::jsonb)
		AS j(purchase_payment_id bigint,purchase_invoice_id bigint,valor numeric)
		JOIN compras.purchase_payments p ON p.id=j.purchase_payment_id AND p.tenant_id=$1 AND p.status='confirmado'
		JOIN compras.purchase_invoices i ON i.id=j.purchase_invoice_id AND i.tenant_id=$1
		AND i.supplier_id=p.supplier_id AND i.status IN ('emitida','parcial')
		WHERE j.valor>0 AND p.valor_alocado+j.valor<=p.valor AND i.valor_pago+j.valor<=i.total
		RETURNING purchase_payment_items.id,purchase_payment_id,purchase_invoice_id,valor`,
		u.TenantID, body).Scan(&id, &paymentID, &invoiceID, &amount)
	if err != nil {
		jsonErr(w, "Pagamento, factura ou valor invalido", http.StatusUnprocessableEntity)
		return
	}
	_, err = tx.Exec(r.Context(), `UPDATE compras.purchase_payments SET
		valor_alocado=valor_alocado+$1,updated_at=NOW() WHERE id=$2`, amount, paymentID)
	if err == nil {
		_, err = tx.Exec(r.Context(), `UPDATE compras.purchase_invoices SET valor_pago=valor_pago+$1,
			status=CASE WHEN valor_pago+$1>=total THEN 'paga' ELSE 'parcial' END,updated_at=NOW()
			WHERE id=$2`, amount, invoiceID)
	}
	if err == nil {
		_, err = tx.Exec(r.Context(), `UPDATE financeiro.accounts_payable SET valor_pago=valor_pago+$1,
			status=CASE WHEN valor_pago+$1>=valor_total THEN 'liquidada' ELSE 'parcial' END
			WHERE tenant_id=$2 AND origem_tipo='purchase_invoice' AND origem_id=$3`,
			amount, u.TenantID, invoiceID)
	}
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao alocar pagamento", 500)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}
