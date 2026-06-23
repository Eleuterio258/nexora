package handlers

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"

	mw "nexora/internal/middleware"
)

func purchaseBody(r *http.Request) ([]byte, error) {
	raw, err := io.ReadAll(io.LimitReader(r.Body, 2<<20))
	if err != nil {
		return nil, err
	}
	if len(raw) == 0 || !json.Valid(raw) {
		return nil, errors.New("invalid JSON")
	}
	var object map[string]any
	if json.Unmarshal(raw, &object) != nil {
		return nil, errors.New("JSON object required")
	}
	return raw, nil
}

func (h *Handler) purchaseList(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	var raw []byte
	if err := h.db.QueryRow(r.Context(), query, args...).Scan(&raw); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func (h *Handler) purchaseCreate(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	var id int64
	if err := h.db.QueryRow(r.Context(), query, args...).Scan(&id); err != nil {
		jsonErr(w, "Dados invalidos ou registo duplicado", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func addPurchaseFilter(where *string, args *[]any, column, value string) {
	if value == "" {
		return
	}
	*args = append(*args, value)
	*where += " AND " + column + "=$" + strconv.Itoa(len(*args))
}

func purchaseSearch(r *http.Request, where *string, args *[]any, columns string) {
	if search := strings.TrimSpace(r.URL.Query().Get("search")); search != "" {
		*args = append(*args, "%"+search+"%")
		*where += " AND (" + strings.ReplaceAll(columns, "?", "$"+strconv.Itoa(len(*args))) + ")"
	}
}

func (h *Handler) CriarRequisicaoCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := purchaseBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.purchaseCreate(w, r, `INSERT INTO compras.purchase_requests
		(tenant_id,numero,request_date,required_date,department,requested_by,status,prioridade,justificacao,observacoes)
		SELECT $1,j.numero,COALESCE(j.request_date,CURRENT_DATE),j.required_date,j.department,$3,
		COALESCE(j.status,'rascunho'),COALESCE(j.prioridade,'normal'),j.justificacao,j.observacoes
		FROM jsonb_to_record($2::jsonb) AS j(numero text,request_date date,required_date date,department text,
		status text,prioridade text,justificacao text,observacoes text)
		WHERE j.numero<>'' RETURNING id`, u.TenantID, body, u.ID)
}

func (h *Handler) ListarRequisicoesCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "p.tenant_id=$1"
	args := []any{u.TenantID}
	addPurchaseFilter(&where, &args, "p.status", r.URL.Query().Get("status"))
	addPurchaseFilter(&where, &args, "p.department", r.URL.Query().Get("department"))
	purchaseSearch(r, &where, &args, "p.numero ILIKE ? OR p.justificacao ILIKE ?")
	h.purchaseList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.request_date DESC,x.id DESC),'[]') FROM (
		SELECT p.*,COALESCE((SELECT SUM(i.quantity*i.estimated_unit_price) FROM compras.purchase_request_items i
		WHERE i.purchase_request_id=p.id),0) estimated_total,
		COALESCE((SELECT jsonb_agg(to_jsonb(i) ORDER BY i.id) FROM compras.purchase_request_items i
		WHERE i.purchase_request_id=p.id),'[]') items FROM compras.purchase_requests p WHERE `+where+`) x`, args...)
}

func (h *Handler) AdicionarItemRequisicaoCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := purchaseBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.purchaseCreate(w, r, `INSERT INTO compras.purchase_request_items
		(purchase_request_id,product_id,descricao,unidade,quantity,estimated_unit_price,observacoes)
		SELECT p.id,j.product_id,COALESCE(NULLIF(j.descricao,''),pr.nome),COALESCE(j.unidade,'UN'),
		j.quantity,COALESCE(j.estimated_unit_price,0),j.observacoes
		FROM jsonb_to_record($2::jsonb) AS j(purchase_request_id bigint,product_id bigint,descricao text,
		unidade text,quantity numeric,estimated_unit_price numeric,observacoes text)
		JOIN compras.purchase_requests p ON p.id=j.purchase_request_id AND p.tenant_id=$1 AND p.status='rascunho'
		LEFT JOIN produtos.products pr ON pr.id=j.product_id AND pr.tenant_id=$1
		WHERE j.quantity>0 AND COALESCE(NULLIF(j.descricao,''),pr.nome) IS NOT NULL RETURNING purchase_request_items.id`,
		u.TenantID, body)
}

func (h *Handler) CriarOrdemCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := purchaseBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.purchaseCreate(w, r, `INSERT INTO compras.purchase_orders
		(tenant_id,supplier_id,purchase_request_id,numero,order_date,expected_date,status,moeda,payment_terms,observacoes,criado_por)
		SELECT $1,s.id,j.purchase_request_id,j.numero,COALESCE(j.order_date,CURRENT_DATE),j.expected_date,
		COALESCE(j.status,'rascunho'),COALESCE(j.moeda,s.moeda_padrao),j.payment_terms,j.observacoes,$3
		FROM jsonb_to_record($2::jsonb) AS j(supplier_id bigint,purchase_request_id bigint,numero text,
		order_date date,expected_date date,status text,moeda text,payment_terms text,observacoes text)
		JOIN compras.suppliers s ON s.id=j.supplier_id AND s.tenant_id=$1 AND s.estado='ativo'
		WHERE j.numero<>'' RETURNING purchase_orders.id`, u.TenantID, body, u.ID)
}

func (h *Handler) ListarOrdensCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "o.tenant_id=$1"
	args := []any{u.TenantID}
	addPurchaseFilter(&where, &args, "o.status", r.URL.Query().Get("status"))
	addPurchaseFilter(&where, &args, "o.supplier_id", r.URL.Query().Get("supplier_id"))
	purchaseSearch(r, &where, &args, "o.numero ILIKE ? OR s.nome ILIKE ?")
	h.purchaseList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.order_date DESC,x.id DESC),'[]') FROM (
		SELECT o.*,s.nome supplier_name,COALESCE((SELECT jsonb_agg(to_jsonb(i) ORDER BY i.id)
		FROM compras.purchase_order_items i WHERE i.purchase_order_id=o.id),'[]') items
		FROM compras.purchase_orders o JOIN compras.suppliers s ON s.id=o.supplier_id WHERE `+where+`) x`, args...)
}

func (h *Handler) AdicionarItemOrdemCompra(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := purchaseBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var id, orderID int64
	err = tx.QueryRow(r.Context(), `INSERT INTO compras.purchase_order_items
		(purchase_order_id,product_id,descricao,unidade,quantity,unit_price,desconto,tax_rate,tax_amount,total)
		SELECT o.id,j.product_id,COALESCE(NULLIF(j.descricao,''),p.nome),COALESCE(j.unidade,'UN'),
		j.quantity,j.unit_price,COALESCE(j.desconto,0),COALESCE(j.tax_rate,0),
		ROUND(GREATEST(j.quantity*j.unit_price-COALESCE(j.desconto,0),0)*COALESCE(j.tax_rate,0)/100,2),
		ROUND(GREATEST(j.quantity*j.unit_price-COALESCE(j.desconto,0),0)*
		(1+COALESCE(j.tax_rate,0)/100),2)
		FROM jsonb_to_record($2::jsonb) AS j(purchase_order_id bigint,product_id bigint,descricao text,
		unidade text,quantity numeric,unit_price numeric,desconto numeric,tax_rate numeric)
		JOIN compras.purchase_orders o ON o.id=j.purchase_order_id AND o.tenant_id=$1 AND o.status='rascunho'
		LEFT JOIN produtos.products p ON p.id=j.product_id AND p.tenant_id=$1
		WHERE j.quantity>0 AND j.unit_price>=0 AND COALESCE(NULLIF(j.descricao,''),p.nome) IS NOT NULL
		RETURNING purchase_order_items.id,purchase_order_id`, u.TenantID, body).Scan(&id, &orderID)
	if err != nil {
		jsonErr(w, "Ordem ou item invalido", http.StatusUnprocessableEntity)
		return
	}
	_, err = tx.Exec(r.Context(), `UPDATE compras.purchase_orders o SET
		subtotal=x.subtotal,desconto_total=x.desconto,imposto_total=x.imposto,total=x.total,updated_at=NOW()
		FROM (SELECT purchase_order_id,SUM(quantity*unit_price) subtotal,SUM(desconto) desconto,
		SUM(tax_amount) imposto,SUM(total) total FROM compras.purchase_order_items
		WHERE purchase_order_id=$1 GROUP BY purchase_order_id) x WHERE o.id=x.purchase_order_id`, orderID)
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao recalcular ordem", 500)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}
