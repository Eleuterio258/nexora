package handlers

import (
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/storage"
)

// UploadCertificadoFicheiro faz upload do ficheiro PDF de um certificado fiscal.
// POST /api/impostos/certificados/{id}/upload
func (h *Handler) UploadCertificadoFicheiro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var exists bool
	if err := h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM impostos.tax_certificates WHERE id=$1 AND tenant_id=$2)`,
		id, user.TenantID,
	).Scan(&exists); err != nil || !exists {
		jsonErr(w, "certificado não encontrado", http.StatusNotFound)
		return
	}

	maxBytes := h.cfg.UploadMaxMB * 1024 * 1024
	if err := r.ParseMultipartForm(maxBytes); err != nil {
		jsonErr(w, fmt.Sprintf("ficheiro demasiado grande (máx %dMB)", h.cfg.UploadMaxMB), http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		jsonErr(w, "campo 'file' obrigatório", http.StatusBadRequest)
		return
	}
	defer file.Close()

	data, err := io.ReadAll(io.LimitReader(file, maxBytes+1))
	if err != nil || int64(len(data)) > maxBytes {
		jsonErr(w, fmt.Sprintf("ficheiro demasiado grande (máx %dMB)", h.cfg.UploadMaxMB), http.StatusBadRequest)
		return
	}

	ext := strings.ToLower(filepath.Ext(header.Filename))
	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	key := storage.JoinPath("impostos/certificados", fmt.Sprintf("tenant-%d", user.TenantID), id+ext)
	url, err := h.storage.Put(r.Context(), key, data, contentType)
	if err != nil {
		jsonErr(w, "erro ao guardar ficheiro", http.StatusInternalServerError)
		return
	}

	_, _ = h.db.Exec(r.Context(),
		`UPDATE impostos.tax_certificates SET ficheiro_url=$1, updated_at=NOW() WHERE id=$2 AND tenant_id=$3`,
		url, id, user.TenantID)

	jsonOK(w, map[string]string{"ficheiro_url": url}, http.StatusOK)
}

// DownloadCertificadoFicheiro serve o ficheiro PDF de um certificado fiscal.
// GET /api/impostos/certificados/{id}/download
func (h *Handler) DownloadCertificadoFicheiro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var fileURL string
	if err := h.db.QueryRow(r.Context(),
		`SELECT COALESCE(ficheiro_url,'') FROM impostos.tax_certificates WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID,
	).Scan(&fileURL); err != nil || fileURL == "" {
		jsonErr(w, "ficheiro não encontrado", http.StatusNotFound)
		return
	}

	key := storage.NormalizeKey(strings.TrimPrefix(fileURL, "/"))
	reader, _, err := h.storage.Get(r.Context(), key)
	if err != nil {
		jsonErr(w, "ficheiro não disponível", http.StatusNotFound)
		return
	}
	defer reader.Close()

	filename := filepath.Base(fileURL)
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, filename))
	w.Header().Set("Content-Type", "application/octet-stream")
	io.Copy(w, reader)
}
