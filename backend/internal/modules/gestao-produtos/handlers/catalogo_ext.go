package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) jsonList(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	var raw []byte
	if err := h.db.QueryRow(r.Context(), query, args...).Scan(&raw); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(raw)
}

func (h *Handler) produtoValido(r *http.Request, productID string) bool {
	user := mw.GetUser(r)
	var ok bool
	_ = h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM produtos.products WHERE id=$1 AND tenant_id=$2)`,
		productID, user.TenantID).Scan(&ok)
	return ok
}

func (h *Handler) ListarCategoriasHierarquia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome), '[]'::jsonb)
		  FROM (
		    SELECT c.id,c.parent_id,c.codigo,c.nome,c.descricao,c.ativo,
		           COALESCE((SELECT COUNT(*) FROM produtos.product_categories f
		                     WHERE f.parent_id=c.id AND f.tenant_id=c.tenant_id),0) AS total_filhos
		      FROM produtos.product_categories c WHERE c.tenant_id=$1
		  ) x`, user.TenantID)
}

func (h *Handler) ObterCategoria(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var raw []byte
	err := h.db.QueryRow(r.Context(), `
		SELECT to_jsonb(x) FROM (
		  SELECT id,parent_id,codigo,nome,descricao,ativo,created_at,updated_at
		    FROM produtos.product_categories WHERE id=$1 AND tenant_id=$2
		) x`, chi.URLParam(r, "id"), user.TenantID).Scan(&raw)
	if err != nil {
		jsonErr(w, "Categoria nao encontrada", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(raw)
}

func (h *Handler) CriarCategoriaHierarquia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		ParentID  *int64  `json:"parent_id"`
		Codigo    *string `json:"codigo"`
		Nome      string  `json:"nome"`
		Descricao *string `json:"descricao"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Nome == "" {
		jsonErr(w, "nome e obrigatorio", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO produtos.product_categories(tenant_id,parent_id,codigo,nome,descricao)
		SELECT $1,$2,$3,$4,$5
		 WHERE $2::bigint IS NULL OR EXISTS(
		   SELECT 1 FROM produtos.product_categories WHERE id=$2 AND tenant_id=$1)
		RETURNING id`, user.TenantID, body.ParentID, body.Codigo, body.Nome, body.Descricao).Scan(&id)
	if err != nil {
		jsonErr(w, "Categoria pai invalida ou codigo duplicado", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarCategoriaHierarquia(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		ParentID  *int64  `json:"parent_id"`
		Codigo    *string `json:"codigo"`
		Nome      *string `json:"nome"`
		Descricao *string `json:"descricao"`
		Ativo     *bool   `json:"ativo"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	if body.ParentID != nil && strconv.FormatInt(*body.ParentID, 10) == id {
		jsonErr(w, "A categoria nao pode ser pai de si propria", http.StatusUnprocessableEntity)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE produtos.product_categories
		   SET parent_id=COALESCE($1,parent_id),codigo=COALESCE($2,codigo),
		       nome=COALESCE($3,nome),descricao=COALESCE($4,descricao),
		       ativo=COALESCE($5,ativo),updated_at=NOW()
		 WHERE id=$6 AND tenant_id=$7
		   AND ($1::bigint IS NULL OR EXISTS(
		     SELECT 1 FROM produtos.product_categories p WHERE p.id=$1 AND p.tenant_id=$7))`,
		body.ParentID, body.Codigo, body.Nome, body.Descricao, body.Ativo, id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Categoria nao encontrada, pai invalido ou codigo duplicado", http.StatusUnprocessableEntity)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ObterMarca(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var raw []byte
	err := h.db.QueryRow(r.Context(), `
		SELECT to_jsonb(x) FROM (
		  SELECT id,codigo,nome,descricao,ativo,created_at
		    FROM produtos.product_brands WHERE id=$1 AND tenant_id=$2
		) x`, chi.URLParam(r, "id"), user.TenantID).Scan(&raw)
	if err != nil {
		jsonErr(w, "Marca nao encontrada", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(raw)
}

func (h *Handler) ListarAtributos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome), '[]'::jsonb)
		  FROM (SELECT id,codigo,nome,tipo,created_at FROM produtos.product_attributes WHERE tenant_id=$1) x`,
		user.TenantID)
}

func (h *Handler) CriarAtributo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo *string `json:"codigo"`
		Nome   string  `json:"nome"`
		Tipo   string  `json:"tipo"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Nome == "" {
		jsonErr(w, "nome e obrigatorio", http.StatusBadRequest)
		return
	}
	if body.Tipo == "" {
		body.Tipo = "texto"
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO produtos.product_attributes(tenant_id,codigo,nome,tipo)
		VALUES($1,$2,$3,$4) RETURNING id`, user.TenantID, body.Codigo, body.Nome, body.Tipo).Scan(&id)
	if err != nil {
		jsonErr(w, "Nao foi possivel criar o atributo", http.StatusConflict)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarAtributo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo *string `json:"codigo"`
		Nome   *string `json:"nome"`
		Tipo   *string `json:"tipo"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE produtos.product_attributes
		   SET codigo=COALESCE($1,codigo),nome=COALESCE($2,nome),tipo=COALESCE($3,tipo)
		 WHERE id=$4 AND tenant_id=$5`,
		body.Codigo, body.Nome, body.Tipo, chi.URLParam(r, "id"), user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Atributo nao encontrado ou dados invalidos", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarTags(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome), '[]'::jsonb)
		  FROM (SELECT id,codigo,nome,cor,created_at FROM produtos.product_tags WHERE tenant_id=$1) x`,
		user.TenantID)
}

func (h *Handler) CriarTag(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo *string `json:"codigo"`
		Nome   string  `json:"nome"`
		Cor    *string `json:"cor"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Nome == "" {
		jsonErr(w, "nome e obrigatorio", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO produtos.product_tags(tenant_id,codigo,nome,cor)
		VALUES($1,$2,$3,$4) RETURNING id`, user.TenantID, body.Codigo, body.Nome, body.Cor).Scan(&id)
	if err != nil {
		jsonErr(w, "Nao foi possivel criar a tag", http.StatusConflict)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterProdutoCompleto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var raw []byte
	err := h.db.QueryRow(r.Context(), `
		SELECT jsonb_build_object(
		  'id',p.id,'codigo',p.codigo,'nome',p.nome,'tipo',p.tipo,'descricao',p.descricao,
		  'ativo',p.ativo,'product_category_id',p.product_category_id,
		  'product_brand_id',p.product_brand_id,'product_unit_id',p.product_unit_id,
		  'iva_percentual',p.iva_percentual,'stock_minimo',p.stock_minimo,
		  'created_at',p.created_at,'updated_at',p.updated_at,
		  'variantes',COALESCE((SELECT jsonb_agg(to_jsonb(v) ORDER BY v.id)
		    FROM produtos.product_variants v WHERE v.product_id=p.id),'[]'::jsonb),
		  'precos',COALESCE((SELECT jsonb_agg(to_jsonb(pr) ORDER BY pr.id)
		    FROM produtos.product_prices pr WHERE pr.product_id=p.id),'[]'::jsonb),
		  'stock',COALESCE((SELECT jsonb_agg(jsonb_build_object(
		    'id',s.id,'warehouse_id',s.warehouse_id,'warehouse',w.nome,
		    'product_variant_id',s.product_variant_id,'quantity',s.quantity,
		    'reserved_quantity',s.reserved_quantity,'available_quantity',s.available_quantity,
		    'minimum_quantity',s.minimum_quantity,'maximum_quantity',s.maximum_quantity))
		    FROM stock.stock_items s JOIN produtos.warehouses w ON w.id=s.warehouse_id
		    WHERE s.product_id=p.id AND s.tenant_id=p.tenant_id),'[]'::jsonb)
		)
		FROM produtos.products p WHERE p.id=$1 AND p.tenant_id=$2`,
		chi.URLParam(r, "id"), user.TenantID).Scan(&raw)
	if err != nil {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(raw)
}

func (h *Handler) ActualizarProdutoCompleto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo            *string  `json:"codigo"`
		Nome              *string  `json:"nome"`
		Tipo              *string  `json:"tipo"`
		Descricao         *string  `json:"descricao"`
		ProductCategoryID *int64   `json:"product_category_id"`
		ProductBrandID    *int64   `json:"product_brand_id"`
		ProductUnitID     *int64   `json:"product_unit_id"`
		IvaPercentual     *float64 `json:"iva_percentual"`
		StockMinimo       *float64 `json:"stock_minimo"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE produtos.products SET codigo=COALESCE($1,codigo),nome=COALESCE($2,nome),
		  tipo=COALESCE($3,tipo),descricao=COALESCE($4,descricao),
		  product_category_id=COALESCE($5,product_category_id),
		  product_brand_id=COALESCE($6,product_brand_id),
		  product_unit_id=COALESCE($7,product_unit_id),
		  iva_percentual=COALESCE($8,iva_percentual),
		  stock_minimo=COALESCE($9,stock_minimo),updated_at=NOW()
		 WHERE id=$10 AND tenant_id=$11`,
		body.Codigo, body.Nome, body.Tipo, body.Descricao, body.ProductCategoryID,
		body.ProductBrandID, body.ProductUnitID, body.IvaPercentual, body.StockMinimo,
		chi.URLParam(r, "id"), user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Produto nao encontrado ou dados invalidos", http.StatusUnprocessableEntity)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) mudarEstadoProduto(ativo bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		user := mw.GetUser(r)
		tag, err := h.db.Exec(r.Context(), `
			UPDATE produtos.products SET ativo=$1,updated_at=NOW()
			 WHERE id=$2 AND tenant_id=$3`, ativo, chi.URLParam(r, "id"), user.TenantID)
		if err != nil || tag.RowsAffected() == 0 {
			jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}
}

func (h *Handler) ActivarProduto(w http.ResponseWriter, r *http.Request) {
	h.mudarEstadoProduto(true)(w, r)
}
func (h *Handler) DesactivarProduto(w http.ResponseWriter, r *http.Request) {
	h.mudarEstadoProduto(false)(w, r)
}

func (h *Handler) ActualizarVariante(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo *string `json:"codigo"`
		SKU    *string `json:"sku"`
		Nome   *string `json:"nome"`
		Ativo  *bool   `json:"ativo"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE produtos.product_variants v
		   SET codigo=COALESCE($1,codigo),sku=COALESCE($2,sku),
		       nome=COALESCE($3,nome),ativo=COALESCE($4,ativo)
		  FROM produtos.products p
		 WHERE v.id=$5 AND v.product_id=$6 AND p.id=v.product_id AND p.tenant_id=$7`,
		body.Codigo, body.SKU, body.Nome, body.Ativo,
		chi.URLParam(r, "var_id"), chi.URLParam(r, "id"), user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Variante nao encontrada ou dados invalidos", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) CriarVarianteCompleta(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	productID := chi.URLParam(r, "id")
	if !h.produtoValido(r, productID) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		Codigo    *string `json:"codigo"`
		SKU       string  `json:"sku"`
		Nome      string  `json:"nome"`
		Atributos []struct {
			AtributoID int64  `json:"atributo_id"`
			Valor      string `json:"valor"`
		} `json:"atributos"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.SKU == "" || body.Nome == "" {
		jsonErr(w, "sku e nome sao obrigatorios", http.StatusBadRequest)
		return
	}
	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())
	var id int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO produtos.product_variants(product_id,codigo,sku,nome)
		VALUES($1,$2,$3,$4) RETURNING id`, productID, body.Codigo, body.SKU, body.Nome).Scan(&id)
	if err != nil {
		jsonErr(w, "Variante duplicada ou invalida", http.StatusConflict)
		return
	}
	for _, atributo := range body.Atributos {
		tag, insertErr := tx.Exec(r.Context(), `
			INSERT INTO produtos.product_attribute_values(product_attribute_id,product_id,product_variant_id,valor)
			SELECT id,$1,$2,$4 FROM produtos.product_attributes
			 WHERE id=$3 AND tenant_id=$5`,
			productID, id, atributo.AtributoID, atributo.Valor, user.TenantID)
		if insertErr != nil || tag.RowsAffected() == 0 {
			jsonErr(w, "Atributo de variante invalido", http.StatusUnprocessableEntity)
			return
		}
	}
	if tx.Commit(r.Context()) != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ListarVariantesCompleto(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(
		  jsonb_build_object(
		    'id',v.id,'codigo',v.codigo,'sku',v.sku,'nome',v.nome,'ativo',v.ativo,
		    'atributos',COALESCE((SELECT jsonb_agg(jsonb_build_object(
		      'atributo_id',a.id,'nome',a.nome,'valor',av.valor) ORDER BY a.nome)
		      FROM produtos.product_attribute_values av
		      JOIN produtos.product_attributes a ON a.id=av.product_attribute_id
		     WHERE av.product_variant_id=v.id),'[]'::jsonb)
		  ) ORDER BY v.nome
		),'[]'::jsonb)
		FROM produtos.product_variants v WHERE v.product_id=$1`, chi.URLParam(r, "id"))
}

func (h *Handler) RemoverVariante(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	tag, err := h.db.Exec(r.Context(), `
		DELETE FROM produtos.product_variants v USING produtos.products p
		 WHERE v.id=$1 AND v.product_id=$2 AND p.id=v.product_id AND p.tenant_id=$3`,
		chi.URLParam(r, "var_id"), chi.URLParam(r, "id"), user.TenantID)
	if err != nil {
		jsonErr(w, "Variante em uso", http.StatusConflict)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Variante nao encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarImagens(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.principal DESC,x.ordem,x.id),'[]'::jsonb)
		  FROM (SELECT id,ficheiro_url,principal,ordem,created_at
		          FROM produtos.product_images WHERE product_id=$1) x`, chi.URLParam(r, "id"))
}

func (h *Handler) AdicionarImagem(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		FicheiroURL string `json:"ficheiro_url"`
		Principal   bool   `json:"principal"`
		Ordem       int    `json:"ordem"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.FicheiroURL == "" {
		jsonErr(w, "ficheiro_url e obrigatorio", http.StatusBadRequest)
		return
	}
	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())
	if body.Principal {
		_, _ = tx.Exec(r.Context(), `UPDATE produtos.product_images SET principal=false WHERE product_id=$1`, chi.URLParam(r, "id"))
	}
	var id int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO produtos.product_images(product_id,ficheiro_url,principal,ordem)
		VALUES($1,$2,$3,$4) RETURNING id`,
		chi.URLParam(r, "id"), body.FicheiroURL, body.Principal, body.Ordem).Scan(&id)
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Nao foi possivel adicionar a imagem", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) DefinirImagemPrincipal(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	_, _ = tx.Exec(r.Context(), `UPDATE produtos.product_images SET principal=false WHERE product_id=$1`, chi.URLParam(r, "id"))
	tag, err := tx.Exec(r.Context(), `
		UPDATE produtos.product_images SET principal=true WHERE id=$1 AND product_id=$2`,
		chi.URLParam(r, "img_id"), chi.URLParam(r, "id"))
	if err != nil || tag.RowsAffected() == 0 || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Imagem nao encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverImagem(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	tag, _ := h.db.Exec(r.Context(), `DELETE FROM produtos.product_images WHERE id=$1 AND product_id=$2`,
		chi.URLParam(r, "img_id"), chi.URLParam(r, "id"))
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Imagem nao encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ActualizarPreco(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		TipoPreco *string  `json:"tipo_preco"`
		Moeda     *string  `json:"moeda"`
		Valor     *float64 `json:"valor"`
		IniciaEm  *string  `json:"inicia_em"`
		FimEm     *string  `json:"fim_em"`
		Ativo     *bool    `json:"ativo"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE produtos.product_prices SET tipo_preco=COALESCE($1,tipo_preco),
		  moeda=COALESCE($2,moeda),valor=COALESCE($3,valor),
		  inicia_em=COALESCE($4::timestamptz,inicia_em),fim_em=COALESCE($5::timestamptz,fim_em),
		  ativo=COALESCE($6,ativo) WHERE id=$7 AND product_id=$8`,
		body.TipoPreco, body.Moeda, body.Valor, body.IniciaEm, body.FimEm,
		body.Ativo, chi.URLParam(r, "preco_id"), chi.URLParam(r, "id"))
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Preco nao encontrado ou dados invalidos", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarPrecosSeguro(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.tipo_preco,x.moeda,x.id),'[]'::jsonb)
		  FROM (SELECT id,product_variant_id,tipo_preco,moeda,valor,inicia_em,fim_em,ativo,created_at
		          FROM produtos.product_prices WHERE product_id=$1) x`, chi.URLParam(r, "id"))
}

func (h *Handler) DefinirPrecoSeguro(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		ProductVariantID *int64  `json:"product_variant_id"`
		TipoPreco        string  `json:"tipo_preco"`
		Moeda            string  `json:"moeda"`
		Valor            float64 `json:"valor"`
		IniciaEm         *string `json:"inicia_em"`
		FimEm            *string `json:"fim_em"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Valor < 0 {
		jsonErr(w, "valor deve ser valido", http.StatusBadRequest)
		return
	}
	if body.TipoPreco == "" {
		body.TipoPreco = "venda"
	}
	if body.Moeda == "" {
		body.Moeda = "MZN"
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO produtos.product_prices(
		  product_id,product_variant_id,tipo_preco,moeda,valor,inicia_em,fim_em)
		VALUES($1,$2,$3,$4,$5,$6::timestamptz,$7::timestamptz) RETURNING id`,
		chi.URLParam(r, "id"), body.ProductVariantID, body.TipoPreco, body.Moeda,
		body.Valor, body.IniciaEm, body.FimEm).Scan(&id)
	if err != nil {
		jsonErr(w, "Preco invalido", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ListarDescontos(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.id DESC),'[]'::jsonb)
		  FROM (SELECT * FROM produtos.product_discounts WHERE product_id=$1) x`, chi.URLParam(r, "id"))
}

func (h *Handler) CriarDesconto(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		ProductVariantID *int64  `json:"product_variant_id"`
		Tipo             string  `json:"tipo"`
		Valor            float64 `json:"valor"`
		Motivo           *string `json:"motivo"`
		IniciaEm         *string `json:"inicia_em"`
		FimEm            *string `json:"fim_em"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Valor < 0 ||
		(body.Tipo != "percentual" && body.Tipo != "valor_fixo") {
		jsonErr(w, "tipo e valor validos sao obrigatorios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO produtos.product_discounts(product_id,product_variant_id,tipo,valor,motivo,inicia_em,fim_em)
		VALUES($1,$2,$3,$4,$5,$6::timestamptz,$7::timestamptz) RETURNING id`,
		chi.URLParam(r, "id"), body.ProductVariantID, body.Tipo, body.Valor,
		body.Motivo, body.IniciaEm, body.FimEm).Scan(&id)
	if err != nil {
		jsonErr(w, "Nao foi possivel criar o desconto", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarDesconto(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		Tipo     *string  `json:"tipo"`
		Valor    *float64 `json:"valor"`
		Motivo   *string  `json:"motivo"`
		IniciaEm *string  `json:"inicia_em"`
		FimEm    *string  `json:"fim_em"`
		Ativo    *bool    `json:"ativo"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE produtos.product_discounts SET tipo=COALESCE($1,tipo),valor=COALESCE($2,valor),
		  motivo=COALESCE($3,motivo),inicia_em=COALESCE($4::timestamptz,inicia_em),
		  fim_em=COALESCE($5::timestamptz,fim_em),ativo=COALESCE($6,ativo)
		 WHERE id=$7 AND product_id=$8`,
		body.Tipo, body.Valor, body.Motivo, body.IniciaEm, body.FimEm,
		body.Ativo, chi.URLParam(r, "desc_id"), chi.URLParam(r, "id"))
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Desconto nao encontrado ou dados invalidos", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverDesconto(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	tag, _ := h.db.Exec(r.Context(), `DELETE FROM produtos.product_discounts WHERE id=$1 AND product_id=$2`,
		chi.URLParam(r, "desc_id"), chi.URLParam(r, "id"))
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Desconto nao encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarCodigosBarras(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.principal DESC,x.id),'[]'::jsonb)
		  FROM (SELECT * FROM produtos.product_barcodes WHERE product_id=$1) x`, chi.URLParam(r, "id"))
}

func (h *Handler) AdicionarCodigoBarras(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		ProductVariantID *int64  `json:"product_variant_id"`
		Barcode          string  `json:"barcode"`
		Tipo             *string `json:"tipo"`
		Principal        bool    `json:"principal"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Barcode == "" {
		jsonErr(w, "barcode e obrigatorio", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO produtos.product_barcodes(product_id,product_variant_id,barcode,tipo,principal)
		VALUES($1,$2,$3,$4,$5) RETURNING id`,
		chi.URLParam(r, "id"), body.ProductVariantID, body.Barcode, body.Tipo, body.Principal).Scan(&id)
	if err != nil {
		jsonErr(w, "Codigo de barras ja existe ou e invalido", http.StatusConflict)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RemoverCodigoBarras(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	tag, _ := h.db.Exec(r.Context(), `DELETE FROM produtos.product_barcodes WHERE id=$1 AND product_id=$2`,
		chi.URLParam(r, "cb_id"), chi.URLParam(r, "id"))
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Codigo de barras nao encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarComponentes(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome),'[]'::jsonb)
		  FROM (
		    SELECT i.id,i.item_product_id,p.codigo,p.nome,i.item_variant_id,v.sku,i.quantidade
		      FROM produtos.product_kits k
		      JOIN produtos.product_kit_items i ON i.product_kit_id=k.id
		      JOIN produtos.products p ON p.id=i.item_product_id
		      LEFT JOIN produtos.product_variants v ON v.id=i.item_variant_id
		     WHERE k.product_id=$1
		  ) x`, chi.URLParam(r, "id"))
}

func (h *Handler) AdicionarComponente(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	productID := chi.URLParam(r, "id")
	if !h.produtoValido(r, productID) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		ItemProductID int64   `json:"item_product_id"`
		ItemVariantID *int64  `json:"item_variant_id"`
		Quantidade    float64 `json:"quantidade"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.ItemProductID == 0 || body.Quantidade <= 0 {
		jsonErr(w, "item_product_id e quantidade sao obrigatorios", http.StatusBadRequest)
		return
	}
	if strconv.FormatInt(body.ItemProductID, 10) == productID {
		jsonErr(w, "Um produto nao pode conter-se a si proprio", http.StatusUnprocessableEntity)
		return
	}
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	var kitID int64
	err := tx.QueryRow(r.Context(), `
		INSERT INTO produtos.product_kits(product_id,nome)
		SELECT id,nome FROM produtos.products WHERE id=$1 AND tenant_id=$2
		ON CONFLICT (product_id,codigo) DO NOTHING
		RETURNING id`, productID, user.TenantID).Scan(&kitID)
	if err != nil {
		err = tx.QueryRow(r.Context(), `SELECT id FROM produtos.product_kits WHERE product_id=$1 ORDER BY id LIMIT 1`, productID).Scan(&kitID)
	}
	if err != nil {
		jsonErr(w, "Nao foi possivel preparar o kit", http.StatusInternalServerError)
		return
	}
	var id int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO produtos.product_kit_items(product_kit_id,item_product_id,item_variant_id,quantidade)
		SELECT $1,p.id,$3,$4 FROM produtos.products p WHERE p.id=$2 AND p.tenant_id=$5
		RETURNING id`, kitID, body.ItemProductID, body.ItemVariantID, body.Quantidade, user.TenantID).Scan(&id)
	if err != nil || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Componente invalido", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarComponente(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		Quantidade float64 `json:"quantidade"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.Quantidade <= 0 {
		jsonErr(w, "quantidade deve ser positiva", http.StatusBadRequest)
		return
	}
	tag, _ := h.db.Exec(r.Context(), `
		UPDATE produtos.product_kit_items i SET quantidade=$1
		  FROM produtos.product_kits k
		 WHERE i.id=$2 AND i.product_kit_id=k.id AND k.product_id=$3`,
		body.Quantidade, chi.URLParam(r, "comp_id"), chi.URLParam(r, "id"))
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Componente nao encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverComponente(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	tag, _ := h.db.Exec(r.Context(), `
		DELETE FROM produtos.product_kit_items i USING produtos.product_kits k
		 WHERE i.id=$1 AND i.product_kit_id=k.id AND k.product_id=$2`,
		chi.URLParam(r, "comp_id"), chi.URLParam(r, "id"))
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Componente nao encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) AssociarTagProduto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	var body struct {
		TagID int64 `json:"tag_id"`
	}
	if json.NewDecoder(r.Body).Decode(&body) != nil || body.TagID == 0 {
		jsonErr(w, "tag_id e obrigatorio", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO produtos.product_tag_links(product_id,product_tag_id)
		SELECT $1,id FROM produtos.product_tags WHERE id=$2 AND tenant_id=$3
		ON CONFLICT(product_id,product_tag_id) DO UPDATE SET product_tag_id=EXCLUDED.product_tag_id
		RETURNING id`, chi.URLParam(r, "id"), body.TagID, user.TenantID).Scan(&id)
	if err != nil {
		jsonErr(w, "Tag nao encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) RemoverTagProduto(w http.ResponseWriter, r *http.Request) {
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	tag, _ := h.db.Exec(r.Context(), `
		DELETE FROM produtos.product_tag_links WHERE product_id=$1 AND product_tag_id=$2`,
		chi.URLParam(r, "id"), chi.URLParam(r, "tag_id"))
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Associacao nao encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) StockProduto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.warehouse_nome,x.product_variant_id),'[]'::jsonb)
		  FROM (
		    SELECT s.id,s.product_variant_id,s.warehouse_id,w.nome AS warehouse_nome,
		           s.quantity,s.reserved_quantity,s.available_quantity,
		           s.minimum_quantity,s.maximum_quantity,s.updated_at
		      FROM stock.stock_items s JOIN produtos.warehouses w ON w.id=s.warehouse_id
		     WHERE s.product_id=$1 AND s.tenant_id=$2
		  ) x`, chi.URLParam(r, "id"), user.TenantID)
}

func (h *Handler) AlertasStockProduto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	if !h.produtoValido(r, chi.URLParam(r, "id")) {
		jsonErr(w, "Produto nao encontrado", http.StatusNotFound)
		return
	}
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.warehouse_nome),'[]'::jsonb)
		  FROM (
		    SELECT s.id AS stock_item_id,s.product_variant_id,s.warehouse_id,w.nome AS warehouse_nome,
		           s.available_quantity,s.minimum_quantity,
		           (s.minimum_quantity-s.available_quantity) AS quantidade_em_falta
		      FROM stock.stock_items s JOIN produtos.warehouses w ON w.id=s.warehouse_id
		     WHERE s.product_id=$1 AND s.tenant_id=$2
		       AND s.available_quantity<=s.minimum_quantity
		  ) x`, chi.URLParam(r, "id"), user.TenantID)
}

func (h *Handler) RelatorioMaisVendidos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit < 1 || limit > 100 {
		limit = 20
	}
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.quantidade_vendida DESC),'[]'::jsonb)
		  FROM (
		    SELECT p.id,p.codigo,p.nome,SUM(i.quantidade) AS quantidade_vendida,
		           SUM(i.total) AS valor_vendido
		      FROM faturacao.invoice_items i
		      JOIN faturacao.invoices f ON f.id=i.invoice_id
		      JOIN produtos.products p ON p.id=i.product_id
		     WHERE f.tenant_id=$1 AND f.status<>'cancelada' AND f.tipo='normal'
		     GROUP BY p.id,p.codigo,p.nome ORDER BY quantidade_vendida DESC LIMIT $2
		  ) x`, user.TenantID, limit)
}

func (h *Handler) RelatorioSemMovimentos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	dias, _ := strconv.Atoi(r.URL.Query().Get("dias"))
	if dias < 1 {
		dias = 90
	}
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome),'[]'::jsonb)
		  FROM (
		    SELECT p.id,p.codigo,p.nome,MAX(m.movement_date) AS ultimo_movimento
		      FROM produtos.products p
		      LEFT JOIN stock.stock_items s ON s.product_id=p.id AND s.tenant_id=p.tenant_id
		      LEFT JOIN stock.stock_movements m ON m.stock_item_id=s.id AND m.tenant_id=p.tenant_id
		     WHERE p.tenant_id=$1
		     GROUP BY p.id,p.codigo,p.nome
		    HAVING MAX(m.movement_date) IS NULL
		        OR MAX(m.movement_date)<NOW()-($2::text||' days')::interval
		  ) x`, user.TenantID, dias)
}

func (h *Handler) RelatorioStockCritico(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.quantidade_em_falta DESC),'[]'::jsonb)
		  FROM (
		    SELECT p.id,p.codigo,p.nome,s.product_variant_id,w.id AS warehouse_id,w.nome AS warehouse,
		           s.available_quantity,s.minimum_quantity,
		           s.minimum_quantity-s.available_quantity AS quantidade_em_falta
		      FROM stock.stock_items s
		      JOIN produtos.products p ON p.id=s.product_id
		      JOIN produtos.warehouses w ON w.id=s.warehouse_id
		     WHERE s.tenant_id=$1 AND s.available_quantity<=s.minimum_quantity
		  ) x`, user.TenantID)
}

func (h *Handler) RelatorioMargem(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.jsonList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome),'[]'::jsonb)
		  FROM (
		    SELECT p.id,p.codigo,p.nome,
		      venda.valor AS preco_venda,custo.valor AS custo_medio,
		      CASE WHEN venda.valor IS NULL OR custo.valor IS NULL THEN NULL
		           ELSE venda.valor-custo.valor END AS margem_valor,
		      CASE WHEN venda.valor>0 AND custo.valor IS NOT NULL
		           THEN ROUND(((venda.valor-custo.valor)/venda.valor)*100,2) END AS margem_percentual
		    FROM produtos.products p
		    LEFT JOIN LATERAL (
		      SELECT valor FROM produtos.product_prices
		       WHERE product_id=p.id AND tipo_preco='venda' AND ativo
		       ORDER BY created_at DESC LIMIT 1
		    ) venda ON true
		    LEFT JOIN LATERAL (
		      SELECT valor FROM produtos.product_prices
		       WHERE product_id=p.id AND tipo_preco='custo' AND ativo
		       ORDER BY created_at DESC LIMIT 1
		    ) custo ON true
		    WHERE p.tenant_id=$1
		  ) x`, user.TenantID)
}
