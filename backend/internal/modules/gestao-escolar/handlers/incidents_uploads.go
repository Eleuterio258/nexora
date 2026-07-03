package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

const incidentMaxFileSize = 10 << 20 // 10 MB

type incidentAnexo struct {
	Nome      string `json:"nome"`
	URL       string `json:"url"`
	Tamanho   int64  `json:"tamanho"`
	CriadoEm string `json:"criado_em"`
}

// loadAnexos lê o jsonb de anexos de um incidente.
func (h *Handler) loadAnexos(r *http.Request, incidentID, tenantID int64) ([]incidentAnexo, error) {
	var raw []byte
	err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(anexos, '[]'::jsonb)
		  FROM gestao_escolar.school_student_incidents
		 WHERE id=$1 AND tenant_id=$2`, incidentID, tenantID).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var list []incidentAnexo
	if err := json.Unmarshal(raw, &list); err != nil {
		return nil, err
	}
	return list, nil
}

// saveAnexos persiste o jsonb de anexos de um incidente.
func (h *Handler) saveAnexos(r *http.Request, incidentID, tenantID int64, list []incidentAnexo) error {
	b, err := json.Marshal(list)
	if err != nil {
		return err
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_student_incidents
		   SET anexos=$1, updated_at=NOW()
		 WHERE id=$2 AND tenant_id=$3`, b, incidentID, tenantID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return fmt.Errorf("not found")
	}
	return nil
}

// POST /api/escolar/incidents/{id}/anexos
func (h *Handler) UploadAnexoIncidente(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID inválido", http.StatusBadRequest)
		return
	}

	if h.storage == nil {
		jsonErr(w, "Armazenamento não configurado", http.StatusServiceUnavailable)
		return
	}

	if err := r.ParseMultipartForm(incidentMaxFileSize); err != nil {
		jsonErr(w, "Ficheiro demasiado grande (máx 10 MB)", http.StatusRequestEntityTooLarge)
		return
	}
	file, header, err := r.FormFile("file")
	if err != nil {
		jsonErr(w, "Campo 'file' em falta", http.StatusBadRequest)
		return
	}
	defer file.Close()

	data, err := io.ReadAll(io.LimitReader(file, incidentMaxFileSize+1))
	if err != nil {
		jsonErr(w, "Erro ao ler ficheiro", http.StatusInternalServerError)
		return
	}
	if int64(len(data)) > incidentMaxFileSize {
		jsonErr(w, "Ficheiro demasiado grande (máx 10 MB)", http.StatusRequestEntityTooLarge)
		return
	}

	ct := header.Header.Get("Content-Type")
	if ct == "" {
		ct = "application/octet-stream"
	}
	key := fmt.Sprintf("tenants/%d/incidents/%d/%d_%s",
		u.TenantID, id, time.Now().UnixMilli(), header.Filename)

	fileURL, err := h.storage.Put(r.Context(), key, data, ct)
	if err != nil {
		jsonErr(w, "Erro ao guardar ficheiro", http.StatusInternalServerError)
		return
	}

	anexos, err := h.loadAnexos(r, id, u.TenantID)
	if err != nil {
		jsonErr(w, "Incidente não encontrado", http.StatusNotFound)
		return
	}

	novo := incidentAnexo{
		Nome:      header.Filename,
		URL:       fileURL,
		Tamanho:   int64(len(data)),
		CriadoEm: time.Now().UTC().Format(time.RFC3339),
	}
	anexos = append(anexos, novo)

	if err := h.saveAnexos(r, id, u.TenantID, anexos); err != nil {
		jsonErr(w, "Erro ao actualizar incidente", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"indice": len(anexos) - 1,
		"anexo":  novo,
	}, http.StatusCreated)
}

// GET /api/escolar/incidents/{id}/anexos/{idx}/download
func (h *Handler) DownloadAnexoIncidente(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID inválido", http.StatusBadRequest)
		return
	}
	idx, err := strconv.Atoi(chi.URLParam(r, "idx"))
	if err != nil {
		jsonErr(w, "Índice inválido", http.StatusBadRequest)
		return
	}

	anexos, err := h.loadAnexos(r, id, u.TenantID)
	if err != nil || idx < 0 || idx >= len(anexos) {
		jsonErr(w, "Anexo não encontrado", http.StatusNotFound)
		return
	}

	fileURL := anexos[idx].URL
	if fileURL == "" {
		jsonErr(w, "Anexo sem URL", http.StatusNotFound)
		return
	}

	if h.storage != nil {
		rc, _, err := h.storage.Get(r.Context(), fileURL)
		if err == nil {
			defer rc.Close()
			w.Header().Set("Content-Disposition", "attachment; filename=\""+anexos[idx].Nome+"\"")
			w.Header().Set("Content-Type", "application/octet-stream")
			w.WriteHeader(http.StatusOK)
			io.Copy(w, rc)
			return
		}
	}
	// Fallback: redirecionar para a URL pública
	http.Redirect(w, r, fileURL, http.StatusFound)
}

// DELETE /api/escolar/incidents/{id}/anexos/{idx}
func (h *Handler) EliminarAnexoIncidente(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID inválido", http.StatusBadRequest)
		return
	}
	idx, err := strconv.Atoi(chi.URLParam(r, "idx"))
	if err != nil {
		jsonErr(w, "Índice inválido", http.StatusBadRequest)
		return
	}

	anexos, err := h.loadAnexos(r, id, u.TenantID)
	if err != nil || idx < 0 || idx >= len(anexos) {
		jsonErr(w, "Anexo não encontrado", http.StatusNotFound)
		return
	}

	removed := anexos[idx]
	anexos = append(anexos[:idx], anexos[idx+1:]...)

	if err := h.saveAnexos(r, id, u.TenantID, anexos); err != nil {
		jsonErr(w, "Erro ao actualizar incidente", http.StatusInternalServerError)
		return
	}

	// Apagar do storage em background
	if h.storage != nil && removed.URL != "" {
		go h.storage.Delete(r.Context(), removed.URL)
	}

	w.WriteHeader(http.StatusNoContent)
}
