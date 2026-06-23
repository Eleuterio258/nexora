package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) stockJSONList(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	var raw []byte
	if err := h.db.QueryRow(r.Context(), query, args...).Scan(&raw); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func stockID(r *http.Request, name string) (int64, error) {
	return strconv.ParseInt(chi.URLParam(r, name), 10, 64)
}

func stockFilters(base string, args []any, values ...[2]string) (string, []any) {
	for _, value := range values {
		if value[1] != "" {
			args = append(args, value[1])
			base += " AND " + value[0] + "=$" + strconv.Itoa(len(args))
		}
	}
	return base, args
}

func (h *Handler) ActualizarLocalizacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo *string `json:"codigo"`
		Nome   *string `json:"nome"`
		Tipo   *string `json:"tipo"`
		Ativo  *bool   `json:"ativo"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE stock.warehouse_locations l
		   SET codigo=COALESCE($1,codigo),nome=COALESCE($2,nome),
		       tipo=COALESCE($3,tipo),ativo=COALESCE($4,ativo)
		  FROM produtos.warehouses a
		 WHERE l.id=$5 AND l.warehouse_id=$6 AND a.id=l.warehouse_id AND a.tenant_id=$7`,
		body.Codigo, body.Nome, body.Tipo, body.Ativo,
		chi.URLParam(r, "loc_id"), chi.URLParam(r, "id"), user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Localizacao nao encontrada ou codigo duplicado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverLocalizacaoSeguro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tag, err := h.db.Exec(r.Context(), `
		DELETE FROM stock.warehouse_locations l USING produtos.warehouses a
		 WHERE l.id=$1 AND l.warehouse_id=$2 AND a.id=l.warehouse_id AND a.tenant_id=$3`,
		chi.URLParam(r, "loc_id"), chi.URLParam(r, "id"), user.TenantID)
	if err != nil {
		jsonErr(w, "Localizacao esta em uso", http.StatusConflict)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Localizacao nao encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ObterStockItem(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var raw []byte
	err := h.db.QueryRow(r.Context(), `
		SELECT jsonb_build_object(
		  'id',s.id,'product_id',s.product_id,'produto',p.nome,
		  'product_variant_id',s.product_variant_id,'warehouse_id',s.warehouse_id,
		  'armazem',a.nome,'quantity',s.quantity,'reserved_quantity',s.reserved_quantity,
		  'available_quantity',s.available_quantity,'minimum_quantity',s.minimum_quantity,
		  'maximum_quantity',s.maximum_quantity,'updated_at',s.updated_at,
		  'reservas',COALESCE((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.reserved_at DESC)
		    FROM stock.stock_reservations r WHERE r.stock_item_id=s.id),'[]'::jsonb),
		  'lotes',COALESCE((SELECT jsonb_agg(to_jsonb(b) ORDER BY b.expiry_date)
		    FROM stock.stock_batches b WHERE b.stock_item_id=s.id),'[]'::jsonb)
		)
		FROM stock.stock_items s
		JOIN produtos.products p ON p.id=s.product_id
		JOIN produtos.warehouses a ON a.id=s.warehouse_id
		WHERE s.id=$1 AND s.tenant_id=$2`,
		chi.URLParam(r, "id"), user.TenantID).Scan(&raw)
	if err != nil {
		jsonErr(w, "Posicao de stock nao encontrada", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func (h *Handler) InicializarStockItemSeguro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		ProductID        int64    `json:"product_id"`
		ProductVariantID *int64   `json:"product_variant_id"`
		WarehouseID      int64    `json:"warehouse_id"`
		Quantity         float64  `json:"quantity"`
		MinimumQuantity  *float64 `json:"minimum_quantity"`
		MaximumQuantity  *float64 `json:"maximum_quantity"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.ProductID < 1 ||
		body.WarehouseID < 1 || body.Quantity < 0 {
		jsonErr(w, "Produto, armazem e quantidade validos sao obrigatorios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO stock.stock_items(
		  tenant_id,product_id,product_variant_id,warehouse_id,quantity,
		  reserved_quantity,minimum_quantity,maximum_quantity)
		SELECT $1,p.id,$3,a.id,$4,0,COALESCE($5,p.stock_minimo),$6
		  FROM produtos.products p,produtos.warehouses a
		 WHERE p.id=$2 AND p.tenant_id=$1 AND a.id=$7 AND a.tenant_id=$1
		   AND ($3::bigint IS NULL OR EXISTS(
		     SELECT 1 FROM produtos.product_variants v WHERE v.id=$3 AND v.product_id=p.id))
		ON CONFLICT (tenant_id,product_id,product_variant_id,warehouse_id)
		DO UPDATE SET minimum_quantity=EXCLUDED.minimum_quantity,
		              maximum_quantity=EXCLUDED.maximum_quantity
		RETURNING id`,
		user.TenantID, body.ProductID, body.ProductVariantID, body.Quantity,
		body.MinimumQuantity, body.MaximumQuantity, body.WarehouseID).Scan(&id)
	if err != nil {
		jsonErr(w, "Produto, variante ou armazem invalido", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) DefinirMinimoMaximoSeguro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		MinimumQuantity *float64 `json:"minimum_quantity"`
		MaximumQuantity *float64 `json:"maximum_quantity"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil ||
		(body.MinimumQuantity != nil && *body.MinimumQuantity < 0) ||
		(body.MaximumQuantity != nil && *body.MaximumQuantity < 0) {
		jsonErr(w, "Limites invalidos", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE stock.stock_items SET minimum_quantity=COALESCE($1,minimum_quantity),
		  maximum_quantity=COALESCE($2,maximum_quantity),updated_at=NOW()
		 WHERE id=$3 AND tenant_id=$4`,
		body.MinimumQuantity, body.MaximumQuantity, chi.URLParam(r, "id"), user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Posicao de stock nao encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarMovimentosCompleto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "m.tenant_id=$1"
	args := []any{user.TenantID}
	where, args = stockFilters(where, args,
		[2]string{"s.product_id", q.Get("product_id")},
		[2]string{"s.warehouse_id", q.Get("warehouse_id")},
		[2]string{"m.tipo", q.Get("tipo")})
	if v := q.Get("data_inicio"); v != "" {
		args = append(args, v)
		where += " AND m.movement_date >= $" + strconv.Itoa(len(args)) + "::date"
	}
	if v := q.Get("data_fim"); v != "" {
		args = append(args, v)
		where += " AND m.movement_date < ($" + strconv.Itoa(len(args)) + "::date + interval '1 day')"
	}
	limit, offset := pageParams(r)
	args = append(args, limit, offset)
	h.stockJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.movement_date DESC),'[]'::jsonb)
		FROM (
		  SELECT m.id,m.stock_item_id,s.product_id,p.nome AS produto,s.warehouse_id,a.nome AS armazem,
		         m.tipo,m.quantity,m.reference_type,m.reference_id,m.movement_date,m.created_at
		    FROM stock.stock_movements m
		    JOIN stock.stock_items s ON s.id=m.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE `+where+`
		   ORDER BY m.movement_date DESC LIMIT $`+strconv.Itoa(len(args)-1)+` OFFSET $`+strconv.Itoa(len(args))+`
		) x`, args...)
}

func (h *Handler) RegistarMovimentoSeguro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		StockItemID   int64   `json:"stock_item_id"`
		Tipo          string  `json:"tipo"`
		Quantity      float64 `json:"quantity"`
		ReferenceType *string `json:"reference_type"`
		ReferenceID   *int64  `json:"reference_id"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.StockItemID < 1 ||
		body.Quantity <= 0 || (body.Tipo != "entrada" && body.Tipo != "saida") {
		jsonErr(w, "stock_item_id, tipo entrada/saida e quantity positiva sao obrigatorios", http.StatusBadRequest)
		return
	}
	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())
	var current, reserved float64
	err = tx.QueryRow(r.Context(), `
		SELECT quantity,reserved_quantity FROM stock.stock_items
		 WHERE id=$1 AND tenant_id=$2 FOR UPDATE`, body.StockItemID, user.TenantID).
		Scan(&current, &reserved)
	if err != nil {
		jsonErr(w, "Posicao de stock nao encontrada", http.StatusNotFound)
		return
	}
	delta := body.Quantity
	if body.Tipo == "saida" {
		delta = -body.Quantity
		if current-body.Quantity < reserved {
			jsonErr(w, "Stock disponivel insuficiente", http.StatusConflict)
			return
		}
	}
	_, err = tx.Exec(r.Context(), `
		UPDATE stock.stock_items SET quantity=quantity+$1,updated_at=NOW() WHERE id=$2`,
		delta, body.StockItemID)
	var id int64
	if err == nil {
		err = tx.QueryRow(r.Context(), `
			INSERT INTO stock.stock_movements(
			  tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id)
			VALUES($1,$2,$3,$4,$5,$6) RETURNING id`,
			user.TenantID, body.StockItemID, body.Tipo, body.Quantity,
			body.ReferenceType, body.ReferenceID).Scan(&id)
	}
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Nao foi possivel registar o movimento", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterMovimento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var raw []byte
	err := h.db.QueryRow(r.Context(), `
		SELECT to_jsonb(x) FROM (
		  SELECT m.id,m.stock_item_id,s.product_id,p.nome AS produto,s.warehouse_id,a.nome AS armazem,
		         m.tipo,m.quantity,m.reference_type,m.reference_id,m.movement_date,m.created_at
		    FROM stock.stock_movements m
		    JOIN stock.stock_items s ON s.id=m.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE m.id=$1 AND m.tenant_id=$2
		) x`, chi.URLParam(r, "id"), user.TenantID).Scan(&raw)
	if err != nil {
		jsonErr(w, "Movimento nao encontrado", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func (h *Handler) ListarAjustesCompleto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "j.tenant_id=$1"
	args := []any{user.TenantID}
	where, args = stockFilters(where, args,
		[2]string{"s.warehouse_id", q.Get("warehouse_id")},
		[2]string{"j.adjustment_type", q.Get("tipo")})
	if v := q.Get("data_inicio"); v != "" {
		args = append(args, v)
		where += " AND j.adjusted_at >= $" + strconv.Itoa(len(args)) + "::date"
	}
	if v := q.Get("data_fim"); v != "" {
		args = append(args, v)
		where += " AND j.adjusted_at < ($" + strconv.Itoa(len(args)) + "::date + interval '1 day')"
	}
	h.stockJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.adjusted_at DESC),'[]'::jsonb)
		FROM (
		  SELECT j.id,j.stock_item_id,s.product_id,p.nome AS produto,s.warehouse_id,a.nome AS armazem,
		         j.adjustment_type,j.quantity,j.reason,j.adjusted_at,j.created_at
		    FROM stock.stock_adjustments j
		    JOIN stock.stock_items s ON s.id=j.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE `+where+`
		) x`, args...)
}

func (h *Handler) CriarAjusteSeguro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		StockItemID    int64   `json:"stock_item_id"`
		AdjustmentType string  `json:"adjustment_type"`
		Quantity       float64 `json:"quantity"`
		Reason         string  `json:"reason"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.StockItemID < 1 ||
		body.Quantity <= 0 || body.Reason == "" ||
		(body.AdjustmentType != "positivo" && body.AdjustmentType != "negativo") {
		jsonErr(w, "Posicao, tipo, quantidade positiva e motivo sao obrigatorios", http.StatusBadRequest)
		return
	}
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var current, reserved float64
	err := tx.QueryRow(r.Context(), `
		SELECT quantity,reserved_quantity FROM stock.stock_items
		 WHERE id=$1 AND tenant_id=$2 FOR UPDATE`, body.StockItemID, user.TenantID).
		Scan(&current, &reserved)
	if err != nil {
		jsonErr(w, "Posicao de stock nao encontrada", http.StatusNotFound)
		return
	}
	delta := body.Quantity
	if body.AdjustmentType == "negativo" {
		delta = -body.Quantity
		if current-body.Quantity < reserved {
			jsonErr(w, "O ajuste deixaria stock abaixo da quantidade reservada", http.StatusConflict)
			return
		}
	}
	var id int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO stock.stock_adjustments(
		  tenant_id,stock_item_id,adjustment_type,quantity,reason)
		VALUES($1,$2,$3,$4,$5) RETURNING id`,
		user.TenantID, body.StockItemID, body.AdjustmentType, body.Quantity, body.Reason).Scan(&id)
	if err == nil {
		_, err = tx.Exec(r.Context(), `
			UPDATE stock.stock_items SET quantity=quantity+$1,updated_at=NOW() WHERE id=$2`,
			delta, body.StockItemID)
	}
	if err == nil {
		_, err = tx.Exec(r.Context(), `
			INSERT INTO stock.stock_movements(
			  tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id)
			VALUES($1,$2,'ajuste',$3,'stock_adjustment',$4)`,
			user.TenantID, body.StockItemID, delta, id)
	}
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Nao foi possivel criar o ajuste", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterAjuste(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var raw []byte
	err := h.db.QueryRow(r.Context(), `
		SELECT to_jsonb(x) FROM (
		  SELECT j.*,s.product_id,s.warehouse_id,p.nome AS produto,a.nome AS armazem
		    FROM stock.stock_adjustments j
		    JOIN stock.stock_items s ON s.id=j.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE j.id=$1 AND j.tenant_id=$2
		) x`, chi.URLParam(r, "id"), user.TenantID).Scan(&raw)
	if err != nil {
		jsonErr(w, "Ajuste nao encontrado", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

type transferItemInput struct {
	StockItemID int64   `json:"stock_item_id"`
	Quantity    float64 `json:"quantity"`
}

func (h *Handler) ListarTransferenciasCompleto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "t.tenant_id=$1"
	args := []any{user.TenantID}
	where, args = stockFilters(where, args, [2]string{"t.status", q.Get("status")})
	if warehouse := q.Get("warehouse"); warehouse != "" {
		args = append(args, warehouse)
		n := strconv.Itoa(len(args))
		where += " AND (t.from_warehouse_id=$" + n + " OR t.to_warehouse_id=$" + n + ")"
	}
	h.stockJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.transfer_date DESC),'[]'::jsonb)
		FROM (
		  SELECT t.id,t.numero,t.from_warehouse_id,origem.nome AS armazem_origem,
		         t.to_warehouse_id,destino.nome AS armazem_destino,t.status,
		         t.transfer_date,t.confirmed_at,t.received_at,t.cancelled_at,t.created_at,
		         (SELECT COUNT(*) FROM stock.stock_transfer_items i
		           WHERE i.stock_transfer_id=t.id) AS total_itens
		    FROM stock.stock_transfers t
		    JOIN produtos.warehouses origem ON origem.id=t.from_warehouse_id
		    JOIN produtos.warehouses destino ON destino.id=t.to_warehouse_id
		   WHERE `+where+`
		) x`, args...)
}

func (h *Handler) CriarTransferenciaCompleta(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Numero          string              `json:"numero"`
		FromWarehouseID int64               `json:"from_warehouse_id"`
		ToWarehouseID   int64               `json:"to_warehouse_id"`
		Items           []transferItemInput `json:"items"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Numero == "" ||
		body.FromWarehouseID < 1 || body.ToWarehouseID < 1 ||
		body.FromWarehouseID == body.ToWarehouseID || len(body.Items) == 0 {
		jsonErr(w, "Numero, armazens distintos e itens sao obrigatorios", http.StatusBadRequest)
		return
	}
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var id int64
	err := tx.QueryRow(r.Context(), `
		INSERT INTO stock.stock_transfers(
		  tenant_id,numero,from_warehouse_id,to_warehouse_id)
		SELECT $1,$2,origem.id,destino.id
		  FROM produtos.warehouses origem,produtos.warehouses destino
		 WHERE origem.id=$3 AND origem.tenant_id=$1 AND origem.ativo
		   AND destino.id=$4 AND destino.tenant_id=$1 AND destino.ativo
		RETURNING id`,
		user.TenantID, body.Numero, body.FromWarehouseID, body.ToWarehouseID).Scan(&id)
	if err != nil {
		jsonErr(w, "Armazem invalido ou numero duplicado", http.StatusUnprocessableEntity)
		return
	}
	for _, item := range body.Items {
		if item.StockItemID < 1 || item.Quantity <= 0 {
			jsonErr(w, "Item de transferencia invalido", http.StatusBadRequest)
			return
		}
		tag, itemErr := tx.Exec(r.Context(), `
			INSERT INTO stock.stock_transfer_items(stock_transfer_id,stock_item_id,quantity)
			SELECT $1,id,$3 FROM stock.stock_items
			 WHERE id=$2 AND tenant_id=$4 AND warehouse_id=$5`,
			id, item.StockItemID, item.Quantity, user.TenantID, body.FromWarehouseID)
		if itemErr != nil || tag.RowsAffected() == 0 {
			jsonErr(w, "Item nao pertence ao armazem de origem", http.StatusUnprocessableEntity)
			return
		}
	}
	if tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterTransferencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var raw []byte
	err := h.db.QueryRow(r.Context(), `
		SELECT jsonb_build_object(
		  'id',t.id,'numero',t.numero,'from_warehouse_id',t.from_warehouse_id,
		  'armazem_origem',origem.nome,'to_warehouse_id',t.to_warehouse_id,
		  'armazem_destino',destino.nome,'status',t.status,'transfer_date',t.transfer_date,
		  'confirmed_at',t.confirmed_at,'received_at',t.received_at,
		  'cancelled_at',t.cancelled_at,'created_at',t.created_at,
		  'items',COALESCE((SELECT jsonb_agg(jsonb_build_object(
		    'id',i.id,'stock_item_id',i.stock_item_id,'product_id',s.product_id,
		    'produto',p.nome,'product_variant_id',s.product_variant_id,'quantity',i.quantity)
		    ORDER BY p.nome)
		    FROM stock.stock_transfer_items i
		    JOIN stock.stock_items s ON s.id=i.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		   WHERE i.stock_transfer_id=t.id),'[]'::jsonb)
		)
		FROM stock.stock_transfers t
		JOIN produtos.warehouses origem ON origem.id=t.from_warehouse_id
		JOIN produtos.warehouses destino ON destino.id=t.to_warehouse_id
		WHERE t.id=$1 AND t.tenant_id=$2`,
		chi.URLParam(r, "id"), user.TenantID).Scan(&raw)
	if err != nil {
		jsonErr(w, "Transferencia nao encontrada", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func (h *Handler) ConfirmarTransferencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var status string
	err := tx.QueryRow(r.Context(), `
		SELECT status FROM stock.stock_transfers
		 WHERE id=$1 AND tenant_id=$2 FOR UPDATE`,
		chi.URLParam(r, "id"), user.TenantID).Scan(&status)
	if err != nil {
		jsonErr(w, "Transferencia nao encontrada", http.StatusNotFound)
		return
	}
	if status != "pendente" {
		jsonErr(w, "Apenas transferencias pendentes podem ser confirmadas", http.StatusConflict)
		return
	}
	rows, err := tx.Query(r.Context(), `
		SELECT i.stock_item_id,i.quantity,s.quantity,s.reserved_quantity
		  FROM stock.stock_transfer_items i
		  JOIN stock.stock_items s ON s.id=i.stock_item_id
		 WHERE i.stock_transfer_id=$1 FOR UPDATE OF s`, chi.URLParam(r, "id"))
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	type row struct {
		item                   int64
		qty, current, reserved float64
	}
	items := []row{}
	for rows.Next() {
		var item row
		if rows.Scan(&item.item, &item.qty, &item.current, &item.reserved) == nil {
			if item.current-item.qty < item.reserved {
				rows.Close()
				jsonErr(w, "Stock insuficiente para expedir todos os itens", http.StatusConflict)
				return
			}
			items = append(items, item)
		}
	}
	rows.Close()
	for _, item := range items {
		_, err = tx.Exec(r.Context(), `
			UPDATE stock.stock_items SET quantity=quantity-$1,updated_at=NOW() WHERE id=$2`,
			item.qty, item.item)
		if err == nil {
			_, err = tx.Exec(r.Context(), `
				INSERT INTO stock.stock_movements(
				  tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id)
				VALUES($1,$2,'transferencia_saida',$3,'stock_transfer',$4)`,
				user.TenantID, item.item, item.qty, chi.URLParam(r, "id"))
		}
		if err != nil {
			jsonErr(w, "Erro ao expedir transferencia", http.StatusInternalServerError)
			return
		}
	}
	_, err = tx.Exec(r.Context(), `
		UPDATE stock.stock_transfers SET status='em_transito',confirmed_at=NOW()
		 WHERE id=$1`, chi.URLParam(r, "id"))
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao confirmar transferencia", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ReceberTransferencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var status string
	var destination int64
	err := tx.QueryRow(r.Context(), `
		SELECT status,to_warehouse_id FROM stock.stock_transfers
		 WHERE id=$1 AND tenant_id=$2 FOR UPDATE`,
		chi.URLParam(r, "id"), user.TenantID).Scan(&status, &destination)
	if err != nil {
		jsonErr(w, "Transferencia nao encontrada", http.StatusNotFound)
		return
	}
	if status != "em_transito" {
		jsonErr(w, "Apenas transferencias em transito podem ser recebidas", http.StatusConflict)
		return
	}
	rows, err := tx.Query(r.Context(), `
		SELECT s.product_id,s.product_variant_id,i.quantity
		  FROM stock.stock_transfer_items i
		  JOIN stock.stock_items s ON s.id=i.stock_item_id
		 WHERE i.stock_transfer_id=$1`, chi.URLParam(r, "id"))
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	type item struct {
		product int64
		variant *int64
		qty     float64
	}
	items := []item{}
	for rows.Next() {
		var value item
		if rows.Scan(&value.product, &value.variant, &value.qty) == nil {
			items = append(items, value)
		}
	}
	rows.Close()
	for _, value := range items {
		var stockItemID int64
		err = tx.QueryRow(r.Context(), `
			INSERT INTO stock.stock_items(
			  tenant_id,product_id,product_variant_id,warehouse_id,quantity,reserved_quantity,minimum_quantity)
			VALUES($1,$2,$3,$4,$5,0,0)
			ON CONFLICT(tenant_id,product_id,product_variant_id,warehouse_id)
			DO UPDATE SET quantity=stock.stock_items.quantity+EXCLUDED.quantity,updated_at=NOW()
			RETURNING id`,
			user.TenantID, value.product, value.variant, destination, value.qty).Scan(&stockItemID)
		if err == nil {
			_, err = tx.Exec(r.Context(), `
				INSERT INTO stock.stock_movements(
				  tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id)
				VALUES($1,$2,'transferencia_entrada',$3,'stock_transfer',$4)`,
				user.TenantID, stockItemID, value.qty, chi.URLParam(r, "id"))
		}
		if err != nil {
			jsonErr(w, "Erro ao receber transferencia", http.StatusInternalServerError)
			return
		}
	}
	_, err = tx.Exec(r.Context(), `
		UPDATE stock.stock_transfers SET status='concluida',received_at=NOW() WHERE id=$1`,
		chi.URLParam(r, "id"))
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao concluir transferencia", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) CancelarTransferencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tag, err := h.db.Exec(r.Context(), `
		UPDATE stock.stock_transfers SET status='cancelada',cancelled_at=NOW()
		 WHERE id=$1 AND tenant_id=$2 AND status='pendente'`,
		chi.URLParam(r, "id"), user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Apenas transferencias pendentes podem ser canceladas", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarReservas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "r.tenant_id=$1 AND r.status='ativa'"
	args := []any{user.TenantID}
	where, args = stockFilters(where, args,
		[2]string{"s.product_id", q.Get("product_id")},
		[2]string{"r.reference_type", q.Get("reference_type")})
	h.stockJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.reserved_at DESC),'[]'::jsonb)
		FROM (
		  SELECT r.*,s.product_id,p.nome AS produto,s.warehouse_id,a.nome AS armazem
		    FROM stock.stock_reservations r
		    JOIN stock.stock_items s ON s.id=r.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE `+where+`
		) x`, args...)
}

func (h *Handler) CriarReserva(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		StockItemID   int64   `json:"stock_item_id"`
		Quantity      float64 `json:"quantity"`
		ReferenceType *string `json:"reference_type"`
		ReferenceID   *int64  `json:"reference_id"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.StockItemID < 1 || body.Quantity <= 0 {
		jsonErr(w, "stock_item_id e quantity positiva sao obrigatorios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		SELECT stock.fn_reservar_stock($1,$2,$3,$4,$5)`,
		user.TenantID, body.StockItemID, body.Quantity, body.ReferenceType, body.ReferenceID).Scan(&id)
	if err != nil {
		jsonErr(w, strings.TrimPrefix(err.Error(), "ERROR: "), http.StatusConflict)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterReserva(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var raw []byte
	err := h.db.QueryRow(r.Context(), `
		SELECT to_jsonb(x) FROM (
		  SELECT r.*,s.product_id,p.nome AS produto,s.warehouse_id,a.nome AS armazem
		    FROM stock.stock_reservations r
		    JOIN stock.stock_items s ON s.id=r.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE r.id=$1 AND r.tenant_id=$2
		) x`, chi.URLParam(r, "id"), user.TenantID).Scan(&raw)
	if err != nil {
		jsonErr(w, "Reserva nao encontrada", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func (h *Handler) LiberarReserva(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	if _, err := h.db.Exec(r.Context(), `SELECT stock.fn_liberar_reserva($1,$2)`,
		user.TenantID, chi.URLParam(r, "id")); err != nil {
		jsonErr(w, "Reserva activa nao encontrada", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ConsumirReserva(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	if _, err := h.db.Exec(r.Context(), `SELECT stock.fn_consumir_reserva($1,$2)`,
		user.TenantID, chi.URLParam(r, "id")); err != nil {
		jsonErr(w, "Reserva activa nao encontrada ou stock insuficiente", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarLotes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "s.tenant_id=$1"
	args := []any{user.TenantID}
	where, args = stockFilters(where, args, [2]string{"s.product_id", q.Get("product_id")})
	if days := q.Get("a_expirar"); days != "" {
		if days == "true" {
			days = "30"
		}
		args = append(args, days)
		where += " AND b.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE+($" +
			strconv.Itoa(len(args)) + "::int)"
	}
	h.stockJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.expiry_date NULLS LAST),'[]'::jsonb)
		FROM (
		  SELECT b.id,b.stock_item_id,b.batch_number,b.manufacture_date,b.expiry_date,b.quantity,
		         b.created_at,s.product_id,p.nome AS produto,s.warehouse_id,a.nome AS armazem
		    FROM stock.stock_batches b
		    JOIN stock.stock_items s ON s.id=b.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE `+where+`
		) x`, args...)
}

func (h *Handler) CriarLote(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		StockItemID     int64   `json:"stock_item_id"`
		BatchNumber     string  `json:"batch_number"`
		ManufactureDate *string `json:"manufacture_date"`
		ExpiryDate      *string `json:"expiry_date"`
		Quantity        float64 `json:"quantity"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.StockItemID < 1 ||
		body.BatchNumber == "" || body.Quantity <= 0 {
		jsonErr(w, "Posicao, numero e quantidade positiva sao obrigatorios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO stock.stock_batches(
		  stock_item_id,batch_number,manufacture_date,expiry_date,quantity)
		SELECT id,$2,$3::date,$4::date,$5 FROM stock.stock_items
		 WHERE id=$1 AND tenant_id=$6 RETURNING id`,
		body.StockItemID, body.BatchNumber, body.ManufactureDate,
		body.ExpiryDate, body.Quantity, user.TenantID).Scan(&id)
	if err != nil {
		jsonErr(w, "Lote duplicado ou posicao invalida", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterLote(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var raw []byte
	err := h.db.QueryRow(r.Context(), `
		SELECT to_jsonb(x) FROM (
		  SELECT b.*,s.product_id,p.nome AS produto,s.warehouse_id,a.nome AS armazem
		    FROM stock.stock_batches b
		    JOIN stock.stock_items s ON s.id=b.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE b.id=$1 AND s.tenant_id=$2
		) x`, chi.URLParam(r, "id"), user.TenantID).Scan(&raw)
	if err != nil {
		jsonErr(w, "Lote nao encontrado", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func (h *Handler) ActualizarLote(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		BatchNumber     *string  `json:"batch_number"`
		ManufactureDate *string  `json:"manufacture_date"`
		ExpiryDate      *string  `json:"expiry_date"`
		Quantity        *float64 `json:"quantity"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil ||
		(body.Quantity != nil && *body.Quantity < 0) {
		jsonErr(w, "Dados invalidos", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE stock.stock_batches b SET batch_number=COALESCE($1,batch_number),
		  manufacture_date=COALESCE($2::date,manufacture_date),
		  expiry_date=COALESCE($3::date,expiry_date),quantity=COALESCE($4,quantity)
		  FROM stock.stock_items s
		 WHERE b.id=$5 AND s.id=b.stock_item_id AND s.tenant_id=$6`,
		body.BatchNumber, body.ManufactureDate, body.ExpiryDate, body.Quantity,
		chi.URLParam(r, "id"), user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Lote nao encontrado ou dados invalidos", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) LotesAExpirar(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	days, _ := strconv.Atoi(r.URL.Query().Get("dias"))
	if days < 1 {
		days = 30
	}
	h.stockJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.expiry_date),'[]'::jsonb)
		FROM (
		  SELECT b.id,b.batch_number,b.expiry_date,b.quantity,s.product_id,p.nome AS produto,
		         s.warehouse_id,a.nome AS armazem,b.expiry_date-CURRENT_DATE AS dias_restantes
		    FROM stock.stock_batches b
		    JOIN stock.stock_items s ON s.id=b.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE s.tenant_id=$1 AND b.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE+$2
		) x`, user.TenantID, days)
}

func (h *Handler) ListarSeriais(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "s.tenant_id=$1"
	args := []any{user.TenantID}
	where, args = stockFilters(where, args,
		[2]string{"s.product_id", q.Get("product_id")},
		[2]string{"n.status", q.Get("status")})
	h.stockJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.serial_number),'[]'::jsonb)
		FROM (
		  SELECT n.id,n.stock_item_id,n.serial_number,n.status,n.created_at,
		         s.product_id,p.nome AS produto,s.warehouse_id,a.nome AS armazem
		    FROM stock.stock_serial_numbers n
		    JOIN stock.stock_items s ON s.id=n.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE `+where+`
		) x`, args...)
}

func (h *Handler) CriarSerial(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		StockItemID  int64  `json:"stock_item_id"`
		SerialNumber string `json:"serial_number"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.StockItemID < 1 || body.SerialNumber == "" {
		jsonErr(w, "stock_item_id e serial_number sao obrigatorios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO stock.stock_serial_numbers(stock_item_id,serial_number)
		SELECT id,$2 FROM stock.stock_items WHERE id=$1 AND tenant_id=$3 RETURNING id`,
		body.StockItemID, body.SerialNumber, user.TenantID).Scan(&id)
	if err != nil {
		jsonErr(w, "Numero de serie duplicado ou posicao invalida", http.StatusConflict)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterSerial(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var raw []byte
	err := h.db.QueryRow(r.Context(), `
		SELECT to_jsonb(x) FROM (
		  SELECT n.id,n.stock_item_id,n.serial_number,n.status,n.created_at,
		         s.product_id,p.nome AS produto,s.warehouse_id,a.nome AS armazem
		    FROM stock.stock_serial_numbers n
		    JOIN stock.stock_items s ON s.id=n.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE n.serial_number=$1 AND s.tenant_id=$2
		) x`, chi.URLParam(r, "serial"), user.TenantID).Scan(&raw)
	if err != nil {
		jsonErr(w, "Numero de serie nao encontrado", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func (h *Handler) ActualizarStatusSerial(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Status string `json:"status"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil ||
		!map[string]bool{"disponivel": true, "reservado": true, "vendido": true, "devolvido": true}[body.Status] {
		jsonErr(w, "Status invalido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE stock.stock_serial_numbers n SET status=$1
		  FROM stock.stock_items s
		 WHERE n.id=$2 AND s.id=n.stock_item_id AND s.tenant_id=$3`,
		body.Status, chi.URLParam(r, "id"), user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Numero de serie nao encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarContagens(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "c.tenant_id=$1"
	args := []any{user.TenantID}
	where, args = stockFilters(where, args,
		[2]string{"c.warehouse_id", q.Get("warehouse_id")},
		[2]string{"c.status", q.Get("status")})
	h.stockJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.count_date DESC),'[]'::jsonb)
		FROM (
		  SELECT c.*,a.nome AS armazem,
		    (SELECT COUNT(*) FROM stock.stock_count_items i WHERE i.stock_count_id=c.id) total_itens,
		    (SELECT COUNT(*) FROM stock.stock_count_items i
		      WHERE i.stock_count_id=c.id AND i.difference_quantity<>0) total_divergencias
		    FROM stock.stock_counts c JOIN produtos.warehouses a ON a.id=c.warehouse_id
		   WHERE `+where+`
		) x`, args...)
}

func (h *Handler) CriarContagem(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Numero      string `json:"numero"`
		WarehouseID int64  `json:"warehouse_id"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Numero == "" || body.WarehouseID < 1 {
		jsonErr(w, "numero e warehouse_id sao obrigatorios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO stock.stock_counts(tenant_id,numero,warehouse_id)
		SELECT $1,$2,id FROM produtos.warehouses WHERE id=$3 AND tenant_id=$1
		RETURNING id`, user.TenantID, body.Numero, body.WarehouseID).Scan(&id)
	if err != nil {
		jsonErr(w, "Armazem invalido ou numero duplicado", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterContagem(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var raw []byte
	err := h.db.QueryRow(r.Context(), `
		SELECT jsonb_build_object(
		  'id',c.id,'numero',c.numero,'warehouse_id',c.warehouse_id,'armazem',a.nome,
		  'status',c.status,'count_date',c.count_date,'closed_at',c.closed_at,
		  'cancelled_at',c.cancelled_at,'created_at',c.created_at,
		  'items',COALESCE((SELECT jsonb_agg(jsonb_build_object(
		    'id',i.id,'stock_item_id',i.stock_item_id,'product_id',s.product_id,
		    'produto',p.nome,'system_quantity',i.system_quantity,
		    'counted_quantity',i.counted_quantity,'difference_quantity',i.difference_quantity)
		    ORDER BY p.nome)
		    FROM stock.stock_count_items i
		    JOIN stock.stock_items s ON s.id=i.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		   WHERE i.stock_count_id=c.id),'[]'::jsonb)
		)
		FROM stock.stock_counts c JOIN produtos.warehouses a ON a.id=c.warehouse_id
		WHERE c.id=$1 AND c.tenant_id=$2`,
		chi.URLParam(r, "id"), user.TenantID).Scan(&raw)
	if err != nil {
		jsonErr(w, "Contagem nao encontrada", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func (h *Handler) AdicionarItemContagem(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		StockItemID     int64   `json:"stock_item_id"`
		CountedQuantity float64 `json:"counted_quantity"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.StockItemID < 1 || body.CountedQuantity < 0 {
		jsonErr(w, "Posicao e quantidade contada valida sao obrigatorias", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO stock.stock_count_items(
		  stock_count_id,stock_item_id,system_quantity,counted_quantity,difference_quantity)
		SELECT c.id,s.id,s.quantity,$3,$3-s.quantity
		  FROM stock.stock_counts c
		  JOIN stock.stock_items s ON s.warehouse_id=c.warehouse_id AND s.tenant_id=c.tenant_id
		 WHERE c.id=$1 AND c.tenant_id=$4 AND c.status='aberto' AND s.id=$2
		ON CONFLICT(stock_count_id,stock_item_id)
		DO UPDATE SET counted_quantity=EXCLUDED.counted_quantity,
		              difference_quantity=EXCLUDED.counted_quantity-stock_count_items.system_quantity
		RETURNING id`, chi.URLParam(r, "id"), body.StockItemID, body.CountedQuantity, user.TenantID).Scan(&id)
	if err != nil {
		jsonErr(w, "Contagem fechada ou posicao invalida", http.StatusConflict)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarItemContagem(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		CountedQuantity float64 `json:"counted_quantity"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.CountedQuantity < 0 {
		jsonErr(w, "Quantidade invalida", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE stock.stock_count_items i
		   SET counted_quantity=$1,difference_quantity=$1-i.system_quantity
		  FROM stock.stock_counts c
		 WHERE i.id=$2 AND i.stock_count_id=$3 AND c.id=i.stock_count_id
		   AND c.tenant_id=$4 AND c.status='aberto'`,
		body.CountedQuantity, chi.URLParam(r, "item_id"), chi.URLParam(r, "id"), user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Item ou contagem aberta nao encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) FecharContagem(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var status string
	err := tx.QueryRow(r.Context(), `
		SELECT status FROM stock.stock_counts
		 WHERE id=$1 AND tenant_id=$2 FOR UPDATE`,
		chi.URLParam(r, "id"), user.TenantID).Scan(&status)
	if err != nil {
		jsonErr(w, "Contagem nao encontrada", http.StatusNotFound)
		return
	}
	if status != "aberto" {
		jsonErr(w, "Apenas contagens abertas podem ser fechadas", http.StatusConflict)
		return
	}
	rows, err := tx.Query(r.Context(), `
		SELECT i.stock_item_id,i.difference_quantity
		  FROM stock.stock_count_items i WHERE i.stock_count_id=$1 AND i.difference_quantity<>0`,
		chi.URLParam(r, "id"))
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	type divergence struct {
		item       int64
		difference float64
	}
	divergences := []divergence{}
	for rows.Next() {
		var d divergence
		if rows.Scan(&d.item, &d.difference) == nil {
			divergences = append(divergences, d)
		}
	}
	rows.Close()
	for _, d := range divergences {
		kind := "positivo"
		quantity := d.difference
		if quantity < 0 {
			kind = "negativo"
			quantity = -quantity
		}
		var adjustmentID int64
		err = tx.QueryRow(r.Context(), `
			INSERT INTO stock.stock_adjustments(
			  tenant_id,stock_item_id,adjustment_type,quantity,reason)
			VALUES($1,$2,$3,$4,$5) RETURNING id`,
			user.TenantID, d.item, kind, quantity,
			fmt.Sprintf("Contagem fisica %s", chi.URLParam(r, "id"))).Scan(&adjustmentID)
		if err == nil {
			var updatedID int64
			err = tx.QueryRow(r.Context(), `
			UPDATE stock.stock_items SET quantity=quantity+$1,updated_at=NOW()
			 WHERE id=$2 AND tenant_id=$3
			   AND quantity+$1>=reserved_quantity
			RETURNING id`, d.difference, d.item, user.TenantID).Scan(&updatedID)
			if err == pgx.ErrNoRows {
				jsonErr(w, "A contagem deixaria stock abaixo da quantidade reservada", http.StatusConflict)
				return
			}
		}
		if err == nil {
			_, err = tx.Exec(r.Context(), `
				INSERT INTO stock.stock_movements(
				  tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id)
				VALUES($1,$2,'ajuste',$3,'stock_count',$4)`,
				user.TenantID, d.item, d.difference, chi.URLParam(r, "id"))
		}
		if err != nil {
			jsonErr(w, "Erro ao gerar ajustes da contagem", http.StatusInternalServerError)
			return
		}
	}
	_, err = tx.Exec(r.Context(), `
		UPDATE stock.stock_counts SET status='fechado',closed_at=NOW() WHERE id=$1`,
		chi.URLParam(r, "id"))
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro ao fechar contagem", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) CancelarContagem(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tag, err := h.db.Exec(r.Context(), `
		UPDATE stock.stock_counts SET status='cancelado',cancelled_at=NOW()
		 WHERE id=$1 AND tenant_id=$2 AND status='aberto'`,
		chi.URLParam(r, "id"), user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Apenas contagens abertas podem ser canceladas", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarAlertas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "al.tenant_id=$1 AND al.status='aberto'"
	args := []any{user.TenantID}
	where, args = stockFilters(where, args,
		[2]string{"al.alert_type", q.Get("alert_type")},
		[2]string{"s.warehouse_id", q.Get("warehouse_id")})
	h.stockJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.created_at DESC),'[]'::jsonb)
		FROM (
		  SELECT al.*,s.product_id,p.nome AS produto,s.warehouse_id,a.nome AS armazem,
		         s.available_quantity,s.minimum_quantity,s.maximum_quantity
		    FROM stock.stock_alerts al
		    JOIN stock.stock_items s ON s.id=al.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE `+where+`
		) x`, args...)
}

func (h *Handler) mudarEstadoAlerta(status string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user := mw.GetUser(r)
		tag, err := h.db.Exec(r.Context(), `
			UPDATE stock.stock_alerts SET status=$1,updated_at=NOW()
			 WHERE id=$2 AND tenant_id=$3 AND status='aberto'`,
			status, chi.URLParam(r, "id"), user.TenantID)
		if err != nil || tag.RowsAffected() == 0 {
			jsonErr(w, "Alerta aberto nao encontrado", http.StatusNotFound)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func (h *Handler) ResolverAlerta(w http.ResponseWriter, r *http.Request) {
	h.mudarEstadoAlerta("resolvido")(w, r)
}

func (h *Handler) IgnorarAlerta(w http.ResponseWriter, r *http.Request) {
	h.mudarEstadoAlerta("ignorado")(w, r)
}

func reportDates(r *http.Request) (string, string) {
	start := r.URL.Query().Get("data_inicio")
	end := r.URL.Query().Get("data_fim")
	if start == "" {
		start = "1900-01-01"
	}
	if end == "" {
		end = "2999-12-31"
	}
	return start, end
}

func (h *Handler) RelatorioPosicao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.stockJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.armazem,x.produto),'[]'::jsonb)
		FROM (
		  SELECT s.id,s.product_id,p.codigo,p.nome AS produto,s.product_variant_id,
		         s.warehouse_id,a.nome AS armazem,s.quantity,s.reserved_quantity,
		         s.available_quantity,s.minimum_quantity,s.maximum_quantity,s.updated_at
		    FROM stock.stock_items s
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE s.tenant_id=$1
		) x`, user.TenantID)
}

func (h *Handler) RelatorioResumoMovimentos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	start, end := reportDates(r)
	h.stockJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.produto,x.armazem),'[]'::jsonb)
		FROM (
		  SELECT s.product_id,p.codigo,p.nome AS produto,s.warehouse_id,a.nome AS armazem,
		    SUM(CASE WHEN m.tipo IN ('entrada','transferencia_entrada') THEN ABS(m.quantity) ELSE 0 END) entradas,
		    SUM(CASE WHEN m.tipo IN ('saida','transferencia_saida') THEN ABS(m.quantity) ELSE 0 END) saidas,
		    SUM(CASE WHEN m.tipo='ajuste' THEN m.quantity ELSE 0 END) ajustes
		    FROM stock.stock_movements m
		    JOIN stock.stock_items s ON s.id=m.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE m.tenant_id=$1 AND m.movement_date >= $2::date
		     AND m.movement_date < ($3::date+interval '1 day')
		   GROUP BY s.product_id,p.codigo,p.nome,s.warehouse_id,a.nome
		) x`, user.TenantID, start, end)
}

func (h *Handler) RelatorioStockBaixo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.stockJSONList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.quantidade_em_falta DESC),'[]'::jsonb)
		FROM (
		  SELECT s.id,s.product_id,p.codigo,p.nome AS produto,s.warehouse_id,a.nome AS armazem,
		         s.available_quantity,s.minimum_quantity,
		         s.minimum_quantity-s.available_quantity AS quantidade_em_falta
		    FROM stock.stock_items s
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		   WHERE s.tenant_id=$1 AND s.available_quantity<=s.minimum_quantity
		) x`, user.TenantID)
}

func (h *Handler) RelatorioLotesExpirar(w http.ResponseWriter, r *http.Request) {
	h.LotesAExpirar(w, r)
}

func (h *Handler) RelatorioDivergencias(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.stockJSONList(w, r, `
		WITH ultima AS (
		  SELECT DISTINCT ON (warehouse_id) id,warehouse_id,numero,count_date
		    FROM stock.stock_counts
		   WHERE tenant_id=$1 AND status='fechado'
		   ORDER BY warehouse_id,count_date DESC
		)
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.armazem,x.produto),'[]'::jsonb)
		FROM (
		  SELECT u.id AS count_id,u.numero,u.count_date,u.warehouse_id,a.nome AS armazem,
		         s.product_id,p.nome AS produto,i.system_quantity,i.counted_quantity,
		         i.difference_quantity
		    FROM ultima u
		    JOIN produtos.warehouses a ON a.id=u.warehouse_id
		    JOIN stock.stock_count_items i ON i.stock_count_id=u.id
		    JOIN stock.stock_items s ON s.id=i.stock_item_id
		    JOIN produtos.products p ON p.id=s.product_id
		   WHERE i.difference_quantity<>0
		) x`, user.TenantID)
}

func (h *Handler) RelatorioValorizacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.stockJSONList(w, r, `
		SELECT jsonb_build_object(
		  'itens',COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.armazem,x.produto),'[]'::jsonb),
		  'valor_total',COALESCE(SUM(x.valor_stock),0)
		)
		FROM (
		  SELECT s.id,s.product_id,p.codigo,p.nome AS produto,s.warehouse_id,a.nome AS armazem,
		         s.quantity,custo.valor AS custo_medio,
		         s.quantity*COALESCE(custo.valor,0) AS valor_stock
		    FROM stock.stock_items s
		    JOIN produtos.products p ON p.id=s.product_id
		    JOIN produtos.warehouses a ON a.id=s.warehouse_id
		    LEFT JOIN LATERAL (
		      SELECT valor FROM produtos.product_prices
		       WHERE product_id=p.id AND tipo_preco='custo' AND ativo
		       ORDER BY created_at DESC LIMIT 1
		    ) custo ON true
		   WHERE s.tenant_id=$1
		) x`, user.TenantID)
}
