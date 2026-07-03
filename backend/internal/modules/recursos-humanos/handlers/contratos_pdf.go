package handlers

import (
	"fmt"
	"io"
	"net/http"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/storage"
)

const contratoPdfMaxBytes = 10 << 20 // 10MB

func contratoPdfKey(tenantID int64, id string) string {
	return storage.JoinPath("contratos", fmt.Sprintf("tenant-%d", tenantID), fmt.Sprintf("contrato-%s.pdf", id))
}

// ObterContratoPDF serve o PDF do contrato, se existir em storage.
// GET /api/rh/contratos/{id}/pdf
func (h *Handler) ObterContratoPDF(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var pdfURL string
	if err := h.db.QueryRow(r.Context(),
		`SELECT COALESCE(ficheiro_url,'') FROM rh.contratos WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID,
	).Scan(&pdfURL); err != nil || pdfURL == "" {
		jsonErr(w, "PDF ainda não gerado", http.StatusNotFound)
		return
	}

	reader, _, err := h.storage.Get(r.Context(), contratoPdfKey(user.TenantID, id))
	if err != nil {
		jsonErr(w, "PDF não disponível", http.StatusNotFound)
		return
	}
	defer reader.Close()

	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="contrato-%s.pdf"`, id))
	io.Copy(w, reader)
}

// GuardarContratoPDF recebe os bytes do PDF (gerado no frontend) e guarda-os no storage.
// POST /api/rh/contratos/{id}/pdf
func (h *Handler) GuardarContratoPDF(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var exists bool
	if err := h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM rh.contratos WHERE id=$1 AND tenant_id=$2)`,
		id, user.TenantID,
	).Scan(&exists); err != nil || !exists {
		jsonErr(w, "Contrato não encontrado", http.StatusNotFound)
		return
	}

	data, err := io.ReadAll(io.LimitReader(r.Body, contratoPdfMaxBytes+1))
	if err != nil || len(data) == 0 || int64(len(data)) > contratoPdfMaxBytes {
		jsonErr(w, "Ficheiro inválido ou demasiado grande", http.StatusBadRequest)
		return
	}

	url, err := h.storage.Put(r.Context(), contratoPdfKey(user.TenantID, id), data, "application/pdf")
	if err != nil {
		jsonErr(w, "Erro ao guardar PDF", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(),
		`UPDATE rh.contratos SET ficheiro_url=$1 WHERE id=$2 AND tenant_id=$3`,
		url, id, user.TenantID,
	); err != nil {
		jsonErr(w, "Erro ao actualizar contrato", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]string{"url": url}, http.StatusOK)
}
