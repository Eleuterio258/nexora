package handlers

import (
	"net/http"
	"strconv"
	"strings"
	"time"

	mw "nexora/internal/middleware"
)

// syncPageSize é o tamanho de página por tipo (produtos/categorias). Um
// catálogo POS típico cabe numa página só; has_more/next_cursor existem para
// não bloquear tenants com catálogos grandes numa única resposta.
const syncPageSize = 300

type syncProdutoRow struct {
	ID                int64    `json:"id"`
	Codigo            string   `json:"codigo"`
	Nome              string   `json:"nome"`
	Descricao         *string  `json:"descricao,omitempty"`
	Tipo              string   `json:"tipo"`
	Ativo             bool     `json:"ativo"`
	ProductCategoryID *int64   `json:"product_category_id"`
	CategoriaNome     *string  `json:"categoria_nome,omitempty"`
	ProductBrandID    *int64   `json:"product_brand_id"`
	ProductUnitID     *int64   `json:"product_unit_id"`
	IvaPercentual     float64  `json:"iva_percentual"`
	PrecoVenda        *float64 `json:"preco_venda,omitempty"`
	Barcode           *string  `json:"barcode,omitempty"`
	ImagemURL         *string  `json:"imagem_url,omitempty"`
}

type syncCategoriaRow struct {
	ID        int64   `json:"id"`
	Codigo    *string `json:"codigo"`
	Nome      string  `json:"nome"`
	Descricao *string `json:"descricao"`
	Ativo     bool    `json:"ativo"`
}

// SyncDownload devolve produtos/categorias alterados desde "since" (unix
// millis), para o app PayCore Mobile actualizar o catálogo local sem
// reenviar tudo a cada sincronização. "since=0" (primeira sincronização de um
// terminal novo) devolve o catálogo completo, paginado.
//
// A alteração de um produto é a maior entre products.updated_at e o
// created_at do preço de venda activo mais recente — DefinirPrecoSeguro
// insere uma nova linha em product_prices em vez de fazer UPDATE, por isso
// só olhar para products.updated_at perderia alterações de preço.
func (h *Handler) SyncDownload(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()

	sinceMillis, _ := strconv.ParseInt(q.Get("since"), 10, 64)
	since := time.UnixMilli(sinceMillis)

	tipos := strings.Split(q.Get("types"), ",")
	if q.Get("types") == "" {
		tipos = []string{"produtos", "categorias"}
	}
	querProdutos, querCategorias := false, false
	for _, t := range tipos {
		switch strings.TrimSpace(t) {
		case "produtos":
			querProdutos = true
		case "categorias":
			querCategorias = true
		}
	}

	resp := struct {
		Produtos   []syncProdutoRow   `json:"produtos"`
		Categorias []syncCategoriaRow `json:"categorias"`
		HasMore    bool               `json:"has_more"`
		NextCursor *string            `json:"next_cursor"`
		// ServerTime é o relógio do servidor, não do cliente — usar isto (e
		// não o horário local do aparelho) como próximo "since" evita perder
		// alterações por desvio de relógio entre o terminal e o backend.
		ServerTime int64 `json:"server_time"`
	}{
		Produtos:   []syncProdutoRow{},
		Categorias: []syncCategoriaRow{},
		ServerTime: time.Now().UnixMilli(),
	}

	// next_cursor é o menor "since" de continuação entre os tipos que ainda
	// têm mais páginas — usar o maior deixaria a paginação saltar alterações
	// no tipo que ficou para trás.
	var proximoCursor *int64

	if querProdutos {
		rows, err := h.db.Query(r.Context(), `
			SELECT p.id, p.codigo, p.nome, p.descricao, p.tipo, p.ativo, p.product_category_id,
			       pc.nome AS categoria_nome, p.product_brand_id, p.product_unit_id,
			       p.iva_percentual, pv.valor, pb.barcode, pi.ficheiro_url,
			       GREATEST(
			         p.updated_at,
			         COALESCE(pv.created_at, p.updated_at),
			         COALESCE(pb.created_at, p.updated_at),
			         COALESCE(pi.created_at, p.updated_at)
			       ) AS alterado_em
			  FROM produtos.products p
			  LEFT JOIN produtos.product_categories pc ON pc.id = p.product_category_id
			  LEFT JOIN LATERAL (
			    SELECT valor, created_at FROM produtos.product_prices
			     WHERE product_id = p.id AND tipo_preco = 'venda' AND ativo = true
			     ORDER BY (moeda = 'MZN') DESC, created_at DESC LIMIT 1
			  ) pv ON true
			  LEFT JOIN LATERAL (
			    SELECT barcode, created_at FROM produtos.product_barcodes
			     WHERE product_id = p.id AND principal = true
			     ORDER BY created_at DESC LIMIT 1
			  ) pb ON true
			  LEFT JOIN LATERAL (
			    SELECT ficheiro_url, created_at FROM produtos.product_images
			     WHERE product_id = p.id AND principal = true
			     ORDER BY created_at DESC LIMIT 1
			  ) pi ON true
			 WHERE p.tenant_id = $1
			   AND GREATEST(
			         p.updated_at,
			         COALESCE(pv.created_at, p.updated_at),
			         COALESCE(pb.created_at, p.updated_at),
			         COALESCE(pi.created_at, p.updated_at)
			       ) >= $2
			 ORDER BY alterado_em ASC, p.id ASC
			 LIMIT $3`,
			user.TenantID, since, syncPageSize+1)
		if err == nil {
			defer rows.Close()
			var alteradoEm time.Time
			totalLidas := 0
			for rows.Next() {
				var p syncProdutoRow
				if rows.Scan(&p.ID, &p.Codigo, &p.Nome, &p.Descricao, &p.Tipo, &p.Ativo, &p.ProductCategoryID,
					&p.CategoriaNome, &p.ProductBrandID, &p.ProductUnitID, &p.IvaPercentual, &p.PrecoVenda,
					&p.Barcode, &p.ImagemURL, &alteradoEm) == nil {
					totalLidas++
					if totalLidas <= syncPageSize {
						resp.Produtos = append(resp.Produtos, p)
					}
				}
			}
			// A query pede syncPageSize+1: se voltou a linha extra, ficou mais
			// para trazer (totalLidas==syncPageSize teria sido falso positivo
			// se o total real fosse exactamente igual ao tamanho da página).
			if totalLidas > syncPageSize {
				resp.HasMore = true
				cursor := alteradoEm.UnixMilli()
				if proximoCursor == nil || cursor < *proximoCursor {
					proximoCursor = &cursor
				}
			}
		}
	}

	if querCategorias {
		rows, err := h.db.Query(r.Context(), `
			SELECT id, codigo, nome, descricao, ativo, updated_at
			  FROM produtos.product_categories
			 WHERE tenant_id = $1 AND updated_at >= $2
			 ORDER BY updated_at ASC, id ASC
			 LIMIT $3`,
			user.TenantID, since, syncPageSize+1)
		if err == nil {
			defer rows.Close()
			var alteradoEm time.Time
			for rows.Next() {
				var c syncCategoriaRow
				if rows.Scan(&c.ID, &c.Codigo, &c.Nome, &c.Descricao, &c.Ativo, &alteradoEm) == nil {
					if len(resp.Categorias) < syncPageSize {
						resp.Categorias = append(resp.Categorias, c)
					}
				}
			}
			if len(resp.Categorias) == syncPageSize {
				resp.HasMore = true
				cursor := alteradoEm.UnixMilli()
				if proximoCursor == nil || cursor < *proximoCursor {
					proximoCursor = &cursor
				}
			}
		}
	}

	if proximoCursor != nil {
		s := strconv.FormatInt(*proximoCursor, 10)
		resp.NextCursor = &s
	}

	jsonOK(w, resp, http.StatusOK)
}
