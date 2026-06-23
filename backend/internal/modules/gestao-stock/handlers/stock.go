package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// â”€â”€ ArmazÃ©ns (warehouses estÃ£o no schema produtos) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarArmazens(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `SELECT id, codigo, nome, localizacao, ativo FROM warehouses WHERE tenant_id=$1 ORDER BY nome`, user.TenantID)
	defer rows.Close()
	type Row struct {
		ID          int64   `json:"id"`
		Codigo      string  `json:"codigo"`
		Nome        string  `json:"nome"`
		Localizacao *string `json:"localizacao"`
		Ativo       bool    `json:"ativo"`
	}
	data := []Row{}
	for rows.Next() {
		var a Row
		if rows.Scan(&a.ID, &a.Codigo, &a.Nome, &a.Localizacao, &a.Ativo) == nil {
			data = append(data, a)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarArmazem(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo      string  `json:"codigo"`
		Nome        string  `json:"nome"`
		Localizacao *string `json:"localizacao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome sÃ£o obrigatÃ³rios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO warehouses (tenant_id,codigo,nome,localizacao) VALUES ($1,$2,$3,$4) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Localizacao).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "CÃ³digo jÃ¡ existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterArmazem(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var a struct {
		ID          int64     `json:"id"`
		Codigo      string    `json:"codigo"`
		Nome        string    `json:"nome"`
		Localizacao *string   `json:"localizacao"`
		Ativo       bool      `json:"ativo"`
		CreatedAt   time.Time `json:"created_at"`
	}
	err := h.db.QueryRow(r.Context(), `SELECT id,codigo,nome,localizacao,ativo,created_at FROM warehouses WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&a.ID, &a.Codigo, &a.Nome, &a.Localizacao, &a.Ativo, &a.CreatedAt)
	if err != nil {
		jsonErr(w, "ArmazÃ©m nÃ£o encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, a, http.StatusOK)
}

func (h *Handler) ActualizarArmazem(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Nome        *string `json:"nome"`
		Localizacao *string `json:"localizacao"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	h.db.Exec(r.Context(), `UPDATE warehouses SET nome=COALESCE($1,nome), localizacao=COALESCE($2,localizacao), updated_at=NOW() WHERE id=$3 AND tenant_id=$4`,
		body.Nome, body.Localizacao, id, user.TenantID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) mudarAtivoArmazem(ativo bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user := mw.GetUser(r)
		id := chi.URLParam(r, "id")
		h.db.Exec(r.Context(), `UPDATE warehouses SET ativo=$1, updated_at=NOW() WHERE id=$2 AND tenant_id=$3`, ativo, id, user.TenantID)
		w.WriteHeader(http.StatusNoContent)
	}
}
func (h *Handler) ActivarArmazem(w http.ResponseWriter, r *http.Request) {
	h.mudarAtivoArmazem(true)(w, r)
}
func (h *Handler) DesactivarArmazem(w http.ResponseWriter, r *http.Request) {
	h.mudarAtivoArmazem(false)(w, r)
}

// â”€â”€ LocalizaÃ§Ãµes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarLocalizacoes(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	rows, _ := h.db.Query(r.Context(), `SELECT id, codigo, nome, ativo FROM warehouse_locations WHERE warehouse_id=$1 ORDER BY codigo`, id)
	defer rows.Close()
	type Row struct {
		ID     int64  `json:"id"`
		Codigo string `json:"codigo"`
		Nome   string `json:"nome"`
		Ativo  bool   `json:"ativo"`
	}
	data := []Row{}
	for rows.Next() {
		var l Row
		if rows.Scan(&l.ID, &l.Codigo, &l.Nome, &l.Ativo) == nil {
			data = append(data, l)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarLocalizacao(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		Codigo string `json:"codigo"`
		Nome   string `json:"nome"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" {
		jsonErr(w, "codigo Ã© obrigatÃ³rio", http.StatusBadRequest)
		return
	}
	var lid int64
	h.db.QueryRow(r.Context(), `INSERT INTO warehouse_locations (warehouse_id,codigo,nome) VALUES ($1,$2,$3) RETURNING id`, id, body.Codigo, body.Nome).Scan(&lid)
	jsonOK(w, map[string]any{"id": lid}, http.StatusCreated)
}

func (h *Handler) RemoverLocalizacao(w http.ResponseWriter, r *http.Request) {
	h.db.Exec(r.Context(), `DELETE FROM warehouse_locations WHERE id=$1 AND warehouse_id=$2`, chi.URLParam(r, "locId"), chi.URLParam(r, "id"))
	w.WriteHeader(http.StatusNoContent)
}

// â”€â”€ PosiÃ§Ãµes de Stock â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarStockItems(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("warehouse_id"); v != "" {
		args = append(args, v)
		where += " AND warehouse_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("product_id"); v != "" {
		args = append(args, v)
		where += " AND product_id=$" + strconv.Itoa(len(args))
	}
	if q.Get("abaixo_minimo") == "true" {
		where += " AND available_quantity <= minimum_quantity"
	}

	rows, _ := h.db.Query(r.Context(),
		"SELECT id, product_id, warehouse_id, quantity, reserved_quantity, available_quantity, minimum_quantity, maximum_quantity FROM stock_items WHERE "+where+" ORDER BY id", args...)
	defer rows.Close()
	type Row struct {
		ID                int64    `json:"id"`
		ProductID         int64    `json:"product_id"`
		WarehouseID       int64    `json:"warehouse_id"`
		Quantity          float64  `json:"quantity"`
		ReservedQuantity  float64  `json:"reserved_quantity"`
		AvailableQuantity float64  `json:"available_quantity"`
		MinimumQuantity   float64  `json:"minimum_quantity"`
		MaximumQuantity   *float64 `json:"maximum_quantity"`
	}
	data := []Row{}
	for rows.Next() {
		var s Row
		if rows.Scan(&s.ID, &s.ProductID, &s.WarehouseID, &s.Quantity, &s.ReservedQuantity, &s.AvailableQuantity, &s.MinimumQuantity, &s.MaximumQuantity) == nil {
			data = append(data, s)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) InicializarStockItem(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		ProductID       int64    `json:"product_id"`
		WarehouseID     int64    `json:"warehouse_id"`
		Quantity        float64  `json:"quantity"`
		MinimumQuantity *float64 `json:"minimum_quantity"`
		MaximumQuantity *float64 `json:"maximum_quantity"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ProductID == 0 || body.WarehouseID == 0 {
		jsonErr(w, "product_id e warehouse_id sÃ£o obrigatÃ³rios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO stock_items (tenant_id, product_id, warehouse_id, quantity, available_quantity, minimum_quantity, maximum_quantity)
		VALUES ($1,$2,$3,$4,$4,COALESCE($5,0),$6)
		ON CONFLICT (product_id, warehouse_id) DO UPDATE SET quantity=$4, available_quantity=$4 RETURNING id`,
		user.TenantID, body.ProductID, body.WarehouseID, body.Quantity, body.MinimumQuantity, body.MaximumQuantity).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) DefinirMinimoMaximo(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		MinimumQuantity *float64 `json:"minimum_quantity"`
		MaximumQuantity *float64 `json:"maximum_quantity"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	h.db.Exec(r.Context(), `UPDATE stock_items SET minimum_quantity=COALESCE($1,minimum_quantity), maximum_quantity=COALESCE($2,maximum_quantity), updated_at=NOW() WHERE id=$3`,
		body.MinimumQuantity, body.MaximumQuantity, id)
	w.WriteHeader(http.StatusNoContent)
}

// â”€â”€ Movimentos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarMovimentos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("tipo"); v != "" {
		args = append(args, v)
		where += " AND tipo=$" + strconv.Itoa(len(args))
	}
	args = append(args, limit, offset)
	n := len(args)
	rows, _ := h.db.Query(r.Context(),
		"SELECT id, stock_item_id, tipo, quantity, reference_type, reference_id, created_at FROM stock_movements WHERE "+
			where+" ORDER BY created_at DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	defer rows.Close()
	type Row struct {
		ID            int64     `json:"id"`
		StockItemID   int64     `json:"stock_item_id"`
		Tipo          string    `json:"tipo"`
		Quantity      float64   `json:"quantity"`
		ReferenceType *string   `json:"reference_type"`
		ReferenceID   *int64    `json:"reference_id"`
		CreatedAt     time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var m Row
		if rows.Scan(&m.ID, &m.StockItemID, &m.Tipo, &m.Quantity, &m.ReferenceType, &m.ReferenceID, &m.CreatedAt) == nil {
			data = append(data, m)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) RegistarMovimento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		StockItemID   int64   `json:"stock_item_id"`
		Tipo          string  `json:"tipo"`
		Quantity      float64 `json:"quantity"`
		ReferenceType *string `json:"reference_type"`
		ReferenceID   *int64  `json:"reference_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.StockItemID == 0 || body.Quantity == 0 {
		jsonErr(w, "stock_item_id, tipo e quantity sÃ£o obrigatÃ³rios", http.StatusBadRequest)
		return
	}
	var id int64
	h.db.QueryRow(r.Context(), `INSERT INTO stock_movements (tenant_id,stock_item_id,tipo,quantity,reference_type,reference_id) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		user.TenantID, body.StockItemID, body.Tipo, body.Quantity, body.ReferenceType, body.ReferenceID).Scan(&id)
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// â”€â”€ Ajustes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarAjustes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	limit, offset := pageParams(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, stock_item_id, adjustment_type, quantity, reason, created_at FROM stock_adjustments
		 WHERE tenant_id=$1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`, user.TenantID, limit, offset)
	defer rows.Close()
	type Row struct {
		ID             int64     `json:"id"`
		StockItemID    int64     `json:"stock_item_id"`
		AdjustmentType string    `json:"adjustment_type"`
		Quantity       float64   `json:"quantity"`
		Reason         *string   `json:"reason"`
		CreatedAt      time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var a Row
		if rows.Scan(&a.ID, &a.StockItemID, &a.AdjustmentType, &a.Quantity, &a.Reason, &a.CreatedAt) == nil {
			data = append(data, a)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarAjuste(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		StockItemID    int64   `json:"stock_item_id"`
		AdjustmentType string  `json:"adjustment_type"`
		Quantity       float64 `json:"quantity"`
		Reason         *string `json:"reason"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.StockItemID == 0 || body.Quantity == 0 {
		jsonErr(w, "stock_item_id, adjustment_type e quantity sÃ£o obrigatÃ³rios", http.StatusBadRequest)
		return
	}
	var id int64
	h.db.QueryRow(r.Context(), `INSERT INTO stock_adjustments (tenant_id,stock_item_id,adjustment_type,quantity,reason) VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		user.TenantID, body.StockItemID, body.AdjustmentType, body.Quantity, body.Reason).Scan(&id)
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// â”€â”€ TransferÃªncias â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarTransferencias(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	limit, offset := pageParams(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT id, numero, from_warehouse_id, to_warehouse_id, status, transfer_date
		  FROM stock_transfers WHERE tenant_id=$1 ORDER BY transfer_date DESC LIMIT $2 OFFSET $3`,
		user.TenantID, limit, offset)
	defer rows.Close()
	type Row struct {
		ID              int64     `json:"id"`
		Numero          string    `json:"numero"`
		FromWarehouseID int64     `json:"from_warehouse_id"`
		ToWarehouseID   int64     `json:"to_warehouse_id"`
		Status          string    `json:"status"`
		TransferDate    time.Time `json:"transfer_date"`
	}
	data := []Row{}
	for rows.Next() {
		var t Row
		if rows.Scan(&t.ID, &t.Numero, &t.FromWarehouseID, &t.ToWarehouseID, &t.Status, &t.TransferDate) == nil {
			data = append(data, t)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarTransferencia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Numero          string `json:"numero"`
		FromWarehouseID int64  `json:"from_warehouse_id"`
		ToWarehouseID   int64  `json:"to_warehouse_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Numero == "" || body.FromWarehouseID == 0 || body.ToWarehouseID == 0 {
		jsonErr(w, "numero, from_warehouse_id e to_warehouse_id sÃ£o obrigatÃ³rios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `INSERT INTO stock_transfers (tenant_id,numero,from_warehouse_id,to_warehouse_id) VALUES ($1,$2,$3,$4) RETURNING id`,
		user.TenantID, body.Numero, body.FromWarehouseID, body.ToWarehouseID).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "NÃºmero de transferÃªncia jÃ¡ existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}
