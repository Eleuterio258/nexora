package handlers

import (
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"nexora/internal/storage"
)

const meuReciboPdfMaxBytes = 10 << 20 // 10MB

// reciboPdfKey usa a mesma convenção de key do módulo recursos-humanos
// (recibos/tenant-{tenantID}/recibo-{id}.pdf), para que o cache seja partilhado
// independentemente de o PDF ter sido gerado primeiro pelo self-service ou pelo RH.
func reciboPdfKey(tenantID int64, id string) string {
	return storage.JoinPath("recibos", fmt.Sprintf("tenant-%d", tenantID), fmt.Sprintf("recibo-%s.pdf", id))
}

// MeuReciboPDF serve o PDF já gerado do recibo do funcionário autenticado, se existir em cache.
// GET /api/self-service/recibos/{id}/pdf
func (h *Handler) MeuReciboPDF(w http.ResponseWriter, r *http.Request) {
	funcID, ok := h.funcionarioID(r)
	if !ok {
		jsonErr(w, "Funcionário não encontrado para este utilizador", http.StatusNotFound)
		return
	}
	id := chi.URLParam(r, "id")

	var tenantID int64
	var pdfURL string
	if err := h.db.QueryRow(r.Context(),
		`SELECT tenant_id, COALESCE(pdf_url,'') FROM rh.recibos_vencimento WHERE id=$1 AND funcionario_id=$2`,
		id, funcID,
	).Scan(&tenantID, &pdfURL); err != nil || pdfURL == "" {
		jsonErr(w, "PDF ainda não gerado", http.StatusNotFound)
		return
	}

	reader, _, err := h.storage.Get(r.Context(), reciboPdfKey(tenantID, id))
	if err != nil {
		jsonErr(w, "PDF não disponível", http.StatusNotFound)
		return
	}
	defer reader.Close()

	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="recibo-%s.pdf"`, id))
	io.Copy(w, reader)
}

// GuardarMeuReciboPDF recebe os bytes do PDF (gerado no frontend) e guarda-os no storage.
// POST /api/self-service/recibos/{id}/pdf
func (h *Handler) GuardarMeuReciboPDF(w http.ResponseWriter, r *http.Request) {
	funcID, ok := h.funcionarioID(r)
	if !ok {
		jsonErr(w, "Funcionário não encontrado para este utilizador", http.StatusNotFound)
		return
	}
	id := chi.URLParam(r, "id")

	var tenantID int64
	if err := h.db.QueryRow(r.Context(),
		`SELECT tenant_id FROM rh.recibos_vencimento WHERE id=$1 AND funcionario_id=$2`,
		id, funcID,
	).Scan(&tenantID); err != nil {
		jsonErr(w, "Recibo não encontrado", http.StatusNotFound)
		return
	}

	data, err := io.ReadAll(io.LimitReader(r.Body, meuReciboPdfMaxBytes+1))
	if err != nil || len(data) == 0 || int64(len(data)) > meuReciboPdfMaxBytes {
		jsonErr(w, "Ficheiro inválido ou demasiado grande", http.StatusBadRequest)
		return
	}

	url, err := h.storage.Put(r.Context(), reciboPdfKey(tenantID, id), data, "application/pdf")
	if err != nil {
		jsonErr(w, "Erro ao guardar PDF", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(),
		`UPDATE rh.recibos_vencimento SET pdf_url=$1 WHERE id=$2 AND funcionario_id=$3`,
		url, id, funcID,
	); err != nil {
		jsonErr(w, "Erro ao actualizar recibo", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]string{"url": url}, http.StatusOK)
}

// MeusRecibos lista os recibos de vencimento do funcionário autenticado.
func (h *Handler) MeusRecibos(w http.ResponseWriter, r *http.Request) {
	funcID, ok := h.funcionarioID(r)
	if !ok {
		jsonErr(w, "Funcionário não encontrado para este utilizador", http.StatusNotFound)
		return
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT rv.id, rv.folha_id, fp.ano, fp.mes, fp.estado AS folha_estado,
		       rv.salario_base, rv.total_proventos, rv.total_descontos, rv.salario_liquido,
		       rv.estado, rv.created_at
		  FROM rh.recibos_vencimento rv
		  JOIN rh.folhas_pagamento fp ON fp.id = rv.folha_id
		 WHERE rv.funcionario_id = $1
		 ORDER BY fp.ano DESC, fp.mes DESC`, funcID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		ID             int64     `json:"id"`
		FolhaID        int64     `json:"folha_id"`
		Ano            int       `json:"ano"`
		Mes            int       `json:"mes"`
		FolhaEstado    string    `json:"folha_estado"`
		SalarioBase    float64   `json:"salario_base"`
		TotalProventos float64   `json:"total_proventos"`
		TotalDescontos float64   `json:"total_descontos"`
		SalarioLiquido float64   `json:"salario_liquido"`
		Estado         string    `json:"estado"`
		CreatedAt      time.Time `json:"created_at"`
	}
	data := []Row{}
	for rows.Next() {
		var rv Row
		if rows.Scan(&rv.ID, &rv.FolhaID, &rv.Ano, &rv.Mes, &rv.FolhaEstado,
			&rv.SalarioBase, &rv.TotalProventos, &rv.TotalDescontos, &rv.SalarioLiquido,
			&rv.Estado, &rv.CreatedAt) == nil {
			data = append(data, rv)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// MeuReciboDetalhe devolve o recibo e os itens do funcionário autenticado.
func (h *Handler) MeuReciboDetalhe(w http.ResponseWriter, r *http.Request) {
	funcID, ok := h.funcionarioID(r)
	if !ok {
		jsonErr(w, "Funcionário não encontrado para este utilizador", http.StatusNotFound)
		return
	}

	id := chi.URLParam(r, "id")

	var rv struct {
		ID             int64     `json:"id"`
		FolhaID        int64     `json:"folha_id"`
		Ano            int       `json:"ano"`
		Mes            int       `json:"mes"`
		SalarioBase    float64   `json:"salario_base"`
		TotalProventos float64   `json:"total_proventos"`
		TotalDescontos float64   `json:"total_descontos"`
		SalarioLiquido float64   `json:"salario_liquido"`
		Estado         string    `json:"estado"`
		CreatedAt      time.Time `json:"created_at"`
	}
	if err := h.db.QueryRow(r.Context(), `
		SELECT rv.id, rv.folha_id, fp.ano, fp.mes,
		       rv.salario_base, rv.total_proventos, rv.total_descontos, rv.salario_liquido,
		       rv.estado, rv.created_at
		  FROM rh.recibos_vencimento rv
		  JOIN rh.folhas_pagamento fp ON fp.id = rv.folha_id
		 WHERE rv.id = $1 AND rv.funcionario_id = $2`,
		id, funcID).Scan(&rv.ID, &rv.FolhaID, &rv.Ano, &rv.Mes,
		&rv.SalarioBase, &rv.TotalProventos, &rv.TotalDescontos, &rv.SalarioLiquido,
		&rv.Estado, &rv.CreatedAt); err != nil {
		jsonErr(w, "Recibo não encontrado", http.StatusNotFound)
		return
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT nome, tipo, valor FROM rh.recibo_vencimento_itens WHERE recibo_id = $1 ORDER BY tipo, nome`, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Item struct {
		Nome  string  `json:"nome"`
		Tipo  string  `json:"tipo"`
		Valor float64 `json:"valor"`
	}
	itens := []Item{}
	for rows.Next() {
		var it Item
		if rows.Scan(&it.Nome, &it.Tipo, &it.Valor) == nil {
			itens = append(itens, it)
		}
	}

	jsonOK(w, map[string]any{"recibo": rv, "itens": itens}, http.StatusOK)
}
