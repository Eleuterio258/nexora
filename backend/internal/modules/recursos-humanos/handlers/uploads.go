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

// UploadContratoFicheiro faz upload do ficheiro PDF/doc associado a um contrato.
// POST /api/rh/contratos/{id}/upload
func (h *Handler) UploadContratoFicheiro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var exists bool
	if err := h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM rh.contratos WHERE id=$1 AND tenant_id=$2)`, id, user.TenantID,
	).Scan(&exists); err != nil || !exists {
		jsonErr(w, "contrato não encontrado", http.StatusNotFound)
		return
	}

	url, err := uploadFicheiro(h, r, user.TenantID, "rh/contratos", id)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, _ = h.db.Exec(r.Context(),
		`UPDATE rh.contratos SET ficheiro_url=$1 WHERE id=$2 AND tenant_id=$3`,
		url, id, user.TenantID)

	jsonOK(w, map[string]string{"ficheiro_url": url}, http.StatusOK)
}

// DownloadContratoFicheiro serve o ficheiro associado a um contrato.
// GET /api/rh/contratos/{id}/download
func (h *Handler) DownloadContratoFicheiro(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var url string
	if err := h.db.QueryRow(r.Context(),
		`SELECT COALESCE(ficheiro_url,'') FROM rh.contratos WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID,
	).Scan(&url); err != nil || url == "" {
		jsonErr(w, "ficheiro não encontrado", http.StatusNotFound)
		return
	}

	serveFile(h, w, r, url)
}

// UploadDocumentoFuncionario faz upload do ficheiro de um documento de funcionário.
// POST /api/rh/documentos/{id}/upload
func (h *Handler) UploadDocumentoFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var exists bool
	if err := h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM rh.documentos_funcionario WHERE id=$1 AND tenant_id=$2)`,
		id, user.TenantID,
	).Scan(&exists); err != nil || !exists {
		jsonErr(w, "documento não encontrado", http.StatusNotFound)
		return
	}

	url, err := uploadFicheiro(h, r, user.TenantID, "rh/documentos", id)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, _ = h.db.Exec(r.Context(),
		`UPDATE rh.documentos_funcionario SET ficheiro_url=$1 WHERE id=$2 AND tenant_id=$3`,
		url, id, user.TenantID)

	jsonOK(w, map[string]string{"ficheiro_url": url}, http.StatusOK)
}

// DownloadDocumentoFuncionario serve o ficheiro de um documento de funcionário.
// GET /api/rh/documentos/{id}/download
func (h *Handler) DownloadDocumentoFuncionario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var url string
	if err := h.db.QueryRow(r.Context(),
		`SELECT COALESCE(ficheiro_url,'') FROM rh.documentos_funcionario WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID,
	).Scan(&url); err != nil || url == "" {
		jsonErr(w, "ficheiro não encontrado", http.StatusNotFound)
		return
	}

	serveFile(h, w, r, url)
}

// UploadCertificadoFormacao faz upload do certificado de uma formação de funcionário.
// POST /api/rh/funcionarios/{id}/formacoes/{registoId}/upload
func (h *Handler) UploadCertificadoFormacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID := chi.URLParam(r, "id")
	registoID := chi.URLParam(r, "registoId")

	var exists bool
	if err := h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM rh.funcionario_formacoes WHERE id=$1 AND funcionario_id=$2 AND tenant_id=$3)`,
		registoID, funcID, user.TenantID,
	).Scan(&exists); err != nil || !exists {
		jsonErr(w, "registo de formação não encontrado", http.StatusNotFound)
		return
	}

	url, err := uploadFicheiro(h, r, user.TenantID, "rh/formacoes", registoID)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, _ = h.db.Exec(r.Context(),
		`UPDATE rh.funcionario_formacoes SET certificado_url=$1 WHERE id=$2 AND tenant_id=$3`,
		url, registoID, user.TenantID)

	jsonOK(w, map[string]string{"certificado_url": url}, http.StatusOK)
}

// DownloadCertificadoFormacao serve o certificado de uma formação de funcionário.
// GET /api/rh/funcionarios/{id}/formacoes/{registoId}/download
func (h *Handler) DownloadCertificadoFormacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	funcID := chi.URLParam(r, "id")
	registoID := chi.URLParam(r, "registoId")

	var url string
	if err := h.db.QueryRow(r.Context(),
		`SELECT COALESCE(certificado_url,'') FROM rh.funcionario_formacoes WHERE id=$1 AND funcionario_id=$2 AND tenant_id=$3`,
		registoID, funcID, user.TenantID,
	).Scan(&url); err != nil || url == "" {
		jsonErr(w, "certificado não encontrado", http.StatusNotFound)
		return
	}

	serveFile(h, w, r, url)
}

// ── helpers internos ──────────────────────────────────────────────────────────

// uploadFicheiro lê o multipart "file", valida o tamanho e guarda no storage.
// Devolve a URL pública ou um erro descritivo.
func uploadFicheiro(h *Handler, r *http.Request, tenantID int64, prefix, recordID string) (string, error) {
	maxBytes := h.cfg.UploadMaxMB * 1024 * 1024
	if err := r.ParseMultipartForm(maxBytes); err != nil {
		return "", fmt.Errorf("ficheiro demasiado grande (máx %dMB)", h.cfg.UploadMaxMB)
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		return "", fmt.Errorf("campo 'file' obrigatório")
	}
	defer file.Close()

	data, err := io.ReadAll(io.LimitReader(file, maxBytes+1))
	if err != nil {
		return "", fmt.Errorf("erro ao ler ficheiro")
	}
	if int64(len(data)) > maxBytes {
		return "", fmt.Errorf("ficheiro demasiado grande (máx %dMB)", h.cfg.UploadMaxMB)
	}

	ext := strings.ToLower(filepath.Ext(header.Filename))
	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	key := storage.JoinPath(prefix, fmt.Sprintf("tenant-%d", tenantID), recordID+ext)
	url, err := h.storage.Put(r.Context(), key, data, contentType)
	if err != nil {
		return "", fmt.Errorf("erro ao guardar ficheiro")
	}
	return url, nil
}

// serveFile serve o conteúdo de um objecto do storage diretamente na resposta HTTP.
func serveFile(h *Handler, w http.ResponseWriter, r *http.Request, fileURL string) {
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
