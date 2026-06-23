package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// â”€â”€ Categorias â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarCategorias(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `SELECT id, codigo, nome, descricao, ativo FROM produtos.product_categories WHERE tenant_id=$1 ORDER BY nome`, user.TenantID)
	defer rows.Close()
	type Row struct {
		ID        int64   `json:"id"`
		Codigo    *string `json:"codigo"`
		Nome      string  `json:"nome"`
		Descricao *string `json:"descricao"`
		Ativo     bool    `json:"ativo"`
	}
	data := []Row{}
	for rows.Next() {
		var c Row
		if rows.Scan(&c.ID, &c.Codigo, &c.Nome, &c.Descricao, &c.Ativo) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarCategoria(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo    *string `json:"codigo"`
		Nome      string  `json:"nome"`
		Descricao *string `json:"descricao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" {
		jsonErr(w, "nome Ã© obrigatÃ³rio", http.StatusBadRequest)
		return
	}
	var id int64
	if err := h.db.QueryRow(r.Context(), `INSERT INTO produtos.product_categories (tenant_id,codigo,nome,descricao) VALUES ($1,$2,$3,$4) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Descricao).Scan(&id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarCategoria(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Nome  *string `json:"nome"`
		Ativo *bool   `json:"ativo"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	h.db.Exec(r.Context(), `UPDATE produtos.product_categories SET nome=COALESCE($1,nome), ativo=COALESCE($2,ativo) WHERE id=$3 AND tenant_id=$4`, body.Nome, body.Ativo, id, user.TenantID)
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverCategoria(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var count int
	h.db.QueryRow(r.Context(), `SELECT COUNT(*) FROM produtos.products WHERE product_category_id=$1`, id).Scan(&count)
	if count > 0 {
		jsonErr(w, "Categoria tem produtos associados", http.StatusConflict)
		return
	}
	h.db.Exec(r.Context(), `DELETE FROM produtos.product_categories WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	w.WriteHeader(http.StatusNoContent)
}

// â”€â”€ Marcas â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarMarcas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `SELECT id, codigo, nome, descricao, ativo FROM produtos.product_brands WHERE tenant_id=$1 ORDER BY nome`, user.TenantID)
	defer rows.Close()
	type Row struct {
		ID        int64   `json:"id"`
		Codigo    *string `json:"codigo"`
		Nome      string  `json:"nome"`
		Descricao *string `json:"descricao"`
		Ativo     bool    `json:"ativo"`
	}
	data := []Row{}
	for rows.Next() {
		var b Row
		if rows.Scan(&b.ID, &b.Codigo, &b.Nome, &b.Descricao, &b.Ativo) == nil {
			data = append(data, b)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarMarca(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo    *string `json:"codigo"`
		Nome      string  `json:"nome"`
		Descricao *string `json:"descricao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" {
		jsonErr(w, "nome Ã© obrigatÃ³rio", http.StatusBadRequest)
		return
	}
	var id int64
	h.db.QueryRow(r.Context(), `INSERT INTO produtos.product_brands (tenant_id,codigo,nome,descricao) VALUES ($1,$2,$3,$4) RETURNING id`, user.TenantID, body.Codigo, body.Nome, body.Descricao).Scan(&id)
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarMarca(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Nome  *string `json:"nome"`
		Ativo *bool   `json:"ativo"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	h.db.Exec(r.Context(), `UPDATE produtos.product_brands SET nome=COALESCE($1,nome), ativo=COALESCE($2,ativo) WHERE id=$3 AND tenant_id=$4`, body.Nome, body.Ativo, id, user.TenantID)
	w.WriteHeader(http.StatusNoContent)
}

// â”€â”€ Unidades â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarUnidades(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `SELECT id, codigo, nome, simbolo FROM produtos.product_units WHERE tenant_id=$1 ORDER BY nome`, user.TenantID)
	defer rows.Close()
	type Row struct {
		ID      int64   `json:"id"`
		Codigo  string  `json:"codigo"`
		Nome    string  `json:"nome"`
		Simbolo *string `json:"simbolo"`
	}
	data := []Row{}
	for rows.Next() {
		var u Row
		if rows.Scan(&u.ID, &u.Codigo, &u.Nome, &u.Simbolo) == nil {
			data = append(data, u)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarUnidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo  string  `json:"codigo"`
		Nome    string  `json:"nome"`
		Simbolo *string `json:"simbolo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome sÃ£o obrigatÃ³rios", http.StatusBadRequest)
		return
	}
	var id int64
	h.db.QueryRow(r.Context(), `INSERT INTO produtos.product_units (tenant_id,codigo,nome,simbolo) VALUES ($1,$2,$3,$4) RETURNING id`, user.TenantID, body.Codigo, body.Nome, body.Simbolo).Scan(&id)
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarUnidade(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Nome    *string `json:"nome"`
		Simbolo *string `json:"simbolo"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	h.db.Exec(r.Context(), `UPDATE produtos.product_units SET nome=COALESCE($1,nome), simbolo=COALESCE($2,simbolo) WHERE id=$3 AND tenant_id=$4`, body.Nome, body.Simbolo, id, user.TenantID)
	w.WriteHeader(http.StatusNoContent)
}

// â”€â”€ Produtos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarProdutos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)
	where := "tenant_id=$1"
	args := []any{user.TenantID}

	if v := q.Get("categoria_id"); v != "" {
		args = append(args, v)
		where += " AND product_category_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("marca_id"); v != "" {
		args = append(args, v)
		where += " AND product_brand_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("tipo"); v != "" {
		args = append(args, v)
		where += " AND tipo=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("status"); v != "" {
		args = append(args, v == "ativo")
		where += " AND ativo=$" + strconv.Itoa(len(args))
	} else if v := q.Get("ativo"); v != "" {
		args = append(args, v == "true")
		where += " AND ativo=$" + strconv.Itoa(len(args))
	}
	if s := q.Get("search"); s != "" {
		args = append(args, "%"+s+"%")
		n := strconv.Itoa(len(args))
		where += " AND (nome ILIKE $" + n + " OR codigo ILIKE $" + n + ")"
	}
	countArgs := make([]any, len(args))
	copy(countArgs, args)
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(),
		"SELECT p.id, p.codigo, p.nome, p.tipo, p.ativo, p.product_category_id, p.product_brand_id, p.product_unit_id, p.iva_percentual, p.created_at, pv.valor "+
			"FROM produtos.products p LEFT JOIN LATERAL (SELECT valor FROM produtos.product_prices WHERE product_id = p.id AND tipo_preco = 'venda' AND ativo = true ORDER BY (moeda = 'MZN') DESC, created_at DESC LIMIT 1) pv ON true "+
			"WHERE "+where+" ORDER BY p.nome LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	type Row struct {
		ID                int64     `json:"id"`
		Codigo            string    `json:"codigo"`
		Nome              string    `json:"nome"`
		Tipo              string    `json:"tipo"`
		Ativo             bool      `json:"ativo"`
		ProductCategoryID *int64    `json:"product_category_id"`
		ProductBrandID    *int64    `json:"product_brand_id"`
		ProductUnitID     *int64    `json:"product_unit_id"`
		IvaPercentual     float64   `json:"iva_percentual"`
		CreatedAt         time.Time `json:"created_at"`
		PrecoVenda        *float64  `json:"preco_venda,omitempty"`
	}
	data := []Row{}
	for rows.Next() {
		var p Row
		if rows.Scan(&p.ID, &p.Codigo, &p.Nome, &p.Tipo, &p.Ativo, &p.ProductCategoryID, &p.ProductBrandID, &p.ProductUnitID, &p.IvaPercentual, &p.CreatedAt, &p.PrecoVenda) == nil {
			data = append(data, p)
		}
	}
	var total int
	h.db.QueryRow(r.Context(), "SELECT COUNT(*) FROM produtos.products WHERE "+where, countArgs...).Scan(&total)
	page, _ := strconv.Atoi(q.Get("page"))
	if page < 1 {
		page = 1
	}
	jsonOK(w, map[string]any{"data": data, "meta": map[string]int{"total": total, "page": page, "limit": limit}}, http.StatusOK)
}

func (h *Handler) CriarProduto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo            string   `json:"codigo"`
		Nome              string   `json:"nome"`
		Tipo              *string  `json:"tipo"`
		Descricao         *string  `json:"descricao"`
		ProductCategoryID *int64   `json:"product_category_id"`
		ProductBrandID    *int64   `json:"product_brand_id"`
		ProductUnitID     *int64   `json:"product_unit_id"`
		IvaPercentual     *float64 `json:"iva_percentual"`
		StockMinimo       *float64 `json:"stock_minimo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome sÃ£o obrigatÃ³rios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO produtos.products (tenant_id,codigo,nome,tipo,descricao,product_category_id,product_brand_id,product_unit_id,iva_percentual,stock_minimo)
		VALUES ($1,$2,$3,COALESCE($4,'simples'),$5,$6,$7,$8,COALESCE($9,17.00),COALESCE($10,0)) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Tipo, body.Descricao,
		body.ProductCategoryID, body.ProductBrandID, body.ProductUnitID, body.IvaPercentual, body.StockMinimo).Scan(&id)
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

func (h *Handler) ObterProduto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var p struct {
		ID                int64     `json:"id"`
		Codigo            string    `json:"codigo"`
		Nome              string    `json:"nome"`
		Tipo              string    `json:"tipo"`
		Descricao         *string   `json:"descricao"`
		Ativo             bool      `json:"ativo"`
		ProductCategoryID *int64    `json:"product_category_id"`
		ProductBrandID    *int64    `json:"product_brand_id"`
		ProductUnitID     *int64    `json:"product_unit_id"`
		IvaPercentual     float64   `json:"iva_percentual"`
		StockMinimo       float64   `json:"stock_minimo"`
		CreatedAt         time.Time `json:"created_at"`
		UpdatedAt         time.Time `json:"updated_at"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id,codigo,nome,tipo,descricao,ativo,product_category_id,product_brand_id,product_unit_id,iva_percentual,stock_minimo,created_at,updated_at
		  FROM produtos.products WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&p.ID, &p.Codigo, &p.Nome, &p.Tipo, &p.Descricao, &p.Ativo, &p.ProductCategoryID, &p.ProductBrandID, &p.ProductUnitID, &p.IvaPercentual, &p.StockMinimo, &p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		jsonErr(w, "Produto nÃ£o encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, p, http.StatusOK)
}

func (h *Handler) ActualizarProduto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Nome              *string  `json:"nome"`
		Descricao         *string  `json:"descricao"`
		Ativo             *bool    `json:"ativo"`
		ProductCategoryID *int64   `json:"product_category_id"`
		ProductBrandID    *int64   `json:"product_brand_id"`
		IvaPercentual     *float64 `json:"iva_percentual"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	tag, _ := h.db.Exec(r.Context(), `
		UPDATE produtos.products SET nome=COALESCE($1,nome), descricao=COALESCE($2,descricao), ativo=COALESCE($3,ativo),
		  product_category_id=COALESCE($4,product_category_id), product_brand_id=COALESCE($5,product_brand_id),
		  iva_percentual=COALESCE($6,iva_percentual), updated_at=NOW()
		WHERE id=$7 AND tenant_id=$8`,
		body.Nome, body.Descricao, body.Ativo, body.ProductCategoryID, body.ProductBrandID, body.IvaPercentual, id, user.TenantID)
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Produto nÃ£o encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// â”€â”€ PreÃ§os â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarPrecos(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	rows, _ := h.db.Query(r.Context(), `SELECT id, tipo_preco, moeda, valor, inicia_em, fim_em, ativo FROM produtos.product_prices WHERE product_id=$1 ORDER BY tipo_preco`, id)
	defer rows.Close()
	type Row struct {
		ID        int64      `json:"id"`
		TipoPreco string     `json:"tipo_preco"`
		Moeda     string     `json:"moeda"`
		Valor     float64    `json:"valor"`
		IniciaEm  *time.Time `json:"inicia_em"`
		FimEm     *time.Time `json:"fim_em"`
		Ativo     bool       `json:"ativo"`
	}
	data := []Row{}
	for rows.Next() {
		var p Row
		if rows.Scan(&p.ID, &p.TipoPreco, &p.Moeda, &p.Valor, &p.IniciaEm, &p.FimEm, &p.Ativo) == nil {
			data = append(data, p)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) DefinirPreco(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		TipoPreco string  `json:"tipo_preco"`
		Moeda     *string `json:"moeda"`
		Valor     float64 `json:"valor"`
		IniciaEm  *string `json:"inicia_em"`
		FimEm     *string `json:"fim_em"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Valor < 0 {
		jsonErr(w, "tipo_preco e valor sÃ£o obrigatÃ³rios", http.StatusBadRequest)
		return
	}
	var pid int64
	h.db.QueryRow(r.Context(), `
		INSERT INTO produtos.product_prices (product_id, tipo_preco, moeda, valor, inicia_em, fim_em)
		VALUES ($1,COALESCE($2,'venda'),COALESCE($3,'MZN'),$4,$5::timestamptz,$6::timestamptz)
		RETURNING id`, id, body.TipoPreco, body.Moeda, body.Valor, body.IniciaEm, body.FimEm).Scan(&pid)
	jsonOK(w, map[string]any{"id": pid}, http.StatusCreated)
}

// â”€â”€ Variantes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

func (h *Handler) ListarVariantes(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	rows, _ := h.db.Query(r.Context(), `SELECT id, sku, nome, ativo FROM produtos.product_variants WHERE product_id=$1 ORDER BY nome`, id)
	defer rows.Close()
	type Row struct {
		ID    int64   `json:"id"`
		SKU   string  `json:"sku"`
		Nome  *string `json:"nome"`
		Ativo bool    `json:"ativo"`
	}
	data := []Row{}
	for rows.Next() {
		var v Row
		if rows.Scan(&v.ID, &v.SKU, &v.Nome, &v.Ativo) == nil {
			data = append(data, v)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarVariante(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var body struct {
		SKU  string  `json:"sku"`
		Nome *string `json:"nome"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.SKU == "" {
		jsonErr(w, "sku Ã© obrigatÃ³rio", http.StatusBadRequest)
		return
	}
	var vid int64
	h.db.QueryRow(r.Context(), `INSERT INTO produtos.product_variants (product_id,sku,nome) VALUES ($1,$2,$3) RETURNING id`, id, body.SKU, body.Nome).Scan(&vid)
	jsonOK(w, map[string]any{"id": vid}, http.StatusCreated)
}
