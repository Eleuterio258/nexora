package handlers

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/storage"
)

const maxDocumentoBytes = 20 << 20 // 20MB

func docKey(tenantID int64, docID int64, suffix string) string {
	return storage.JoinPath("assinatura-digital", fmt.Sprintf("tenant-%d", tenantID), fmt.Sprintf("doc-%d%s", docID, suffix))
}

// CriarDocumento faz upload do PDF original.
// POST /api/assinatura-digital/documentos
func (h *Handler) CriarDocumento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	if err := r.ParseMultipartForm(maxDocumentoBytes); err != nil {
		jsonErr(w, "Ficheiro inválido ou demasiado grande", http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("ficheiro")
	if err != nil {
		jsonErr(w, "Ficheiro obrigatório", http.StatusBadRequest)
		return
	}
	defer file.Close()

	data, err := io.ReadAll(io.LimitReader(file, maxDocumentoBytes+1))
	if err != nil || len(data) == 0 || int64(len(data)) > maxDocumentoBytes {
		jsonErr(w, "Ficheiro inválido ou demasiado grande", http.StatusBadRequest)
		return
	}

	titulo := r.FormValue("titulo")
	if titulo == "" {
		titulo = header.Filename
	}

	hash := sha256.Sum256(data)
	hashStr := hex.EncodeToString(hash[:])

	var id int64
	err = h.db.QueryRow(r.Context(), `
		INSERT INTO assinatura_digital.documentos (tenant_id, titulo, descricao, hash_sha256, status, created_by)
		VALUES ($1,$2,$3,$4,'rascunho',$5) RETURNING id`,
		user.TenantID, titulo, r.FormValue("descricao"), hashStr, user.ID).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro ao registar documento", http.StatusInternalServerError)
		return
	}

	key := docKey(user.TenantID, id, ".pdf")
	url, err := h.storage.Put(r.Context(), key, data, "application/pdf")
	if err != nil {
		jsonErr(w, "Erro ao guardar documento", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE assinatura_digital.documentos SET storage_key=$1, ficheiro_url=$2 WHERE id=$3`,
		key, url, id); err != nil {
		jsonErr(w, "Erro ao actualizar documento", http.StatusInternalServerError)
		return
	}

	h.log(r.Context(), id, nil, "upload", map[string]any{"titulo": titulo, "tamanho": len(data)}, user.ID, r)

	jsonOK(w, map[string]any{"id": id, "status": "rascunho", "url": url}, http.StatusCreated)
}

// ListarDocumentos lista os documentos do tenant.
// GET /api/assinatura-digital/documentos
func (h *Handler) ListarDocumentos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	rows, _ := h.db.Query(r.Context(), `
		SELECT d.id, d.titulo, d.descricao, d.status, d.created_at, d.data_envio, d.data_conclusao,
		       (SELECT COUNT(*) FROM assinatura_digital.signatarios s WHERE s.documento_id = d.id) as total_signatarios,
		       (SELECT COUNT(*) FROM assinatura_digital.signatarios s WHERE s.documento_id = d.id AND s.status='assinado') as assinados
		FROM assinatura_digital.documentos d
		WHERE d.tenant_id=$1
		ORDER BY d.created_at DESC`, user.TenantID)
	defer rows.Close()

	type Row struct {
		ID               int64      `json:"id"`
		Titulo           string     `json:"titulo"`
		Descricao        *string    `json:"descricao"`
		Status           string     `json:"status"`
		CreatedAt        time.Time  `json:"created_at"`
		DataEnvio        *time.Time `json:"data_envio"`
		DataConclusao    *time.Time `json:"data_conclusao"`
		TotalSignatarios int        `json:"total_signatarios"`
		Assinados        int        `json:"assinados"`
	}
	data := []Row{}
	for rows.Next() {
		var row Row
		if rows.Scan(&row.ID, &row.Titulo, &row.Descricao, &row.Status, &row.CreatedAt, &row.DataEnvio, &row.DataConclusao, &row.TotalSignatarios, &row.Assinados) == nil {
			data = append(data, row)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// ObterDocumento devolve detalhes do documento e signatários.
// GET /api/assinatura-digital/documentos/{id}
func (h *Handler) ObterDocumento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var doc struct {
		ID            int64      `json:"id"`
		Titulo        string     `json:"titulo"`
		Descricao     *string    `json:"descricao"`
		Status        string     `json:"status"`
		FicheiroURL   string     `json:"ficheiro_url"`
		HashSha256    string     `json:"hash_sha256"`
		CreatedAt     time.Time  `json:"created_at"`
		DataEnvio     *time.Time `json:"data_envio"`
		DataConclusao *time.Time `json:"data_conclusao"`
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, titulo, descricao, status, ficheiro_url, hash_sha256, created_at, data_envio, data_conclusao
		FROM assinatura_digital.documentos
		WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&doc.ID, &doc.Titulo, &doc.Descricao, &doc.Status, &doc.FicheiroURL, &doc.HashSha256, &doc.CreatedAt, &doc.DataEnvio, &doc.DataConclusao)
	if err != nil {
		jsonErr(w, "Documento não encontrado", http.StatusNotFound)
		return
	}

	rows, _ := h.db.Query(r.Context(), `
		SELECT id, nome, email, nuit, bi, telefone, ordem, tipo, status, assinado_em, campo_pagina, campo_x, campo_y, campo_largura, campo_altura
		FROM assinatura_digital.signatarios
		WHERE documento_id=$1 ORDER BY ordem, id`, id)
	defer rows.Close()

	type Sig struct {
		ID           int64      `json:"id"`
		Nome         string     `json:"nome"`
		Email        *string    `json:"email"`
		Nuit         *string    `json:"nuit"`
		BI           *string    `json:"bi"`
		Telefone     *string    `json:"telefone"`
		Ordem        int        `json:"ordem"`
		Tipo         string     `json:"tipo"`
		Status       string     `json:"status"`
		AssinadoEm   *time.Time `json:"assinado_em"`
		CampoPagina  *int       `json:"campo_pagina"`
		CampoX       *float64   `json:"campo_x"`
		CampoY       *float64   `json:"campo_y"`
		CampoLargura *float64   `json:"campo_largura"`
		CampoAltura  *float64   `json:"campo_altura"`
	}
	signatarios := []Sig{}
	for rows.Next() {
		var s Sig
		if rows.Scan(&s.ID, &s.Nome, &s.Email, &s.Nuit, &s.BI, &s.Telefone, &s.Ordem, &s.Tipo, &s.Status, &s.AssinadoEm, &s.CampoPagina, &s.CampoX, &s.CampoY, &s.CampoLargura, &s.CampoAltura) == nil {
			signatarios = append(signatarios, s)
		}
	}

	jsonOK(w, map[string]any{"documento": doc, "signatarios": signatarios}, http.StatusOK)
}

// AdicionarSignatario adiciona um signatário ao documento.
// POST /api/assinatura-digital/documentos/{id}/signatarios
func (h *Handler) AdicionarSignatario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var body struct {
		Nome    string  `json:"nome"`
		Email   *string `json:"email"`
		Nuit    *string `json:"nuit"`
		BI      *string `json:"bi"`
		Telefone *string `json:"telefone"`
		Ordem   *int    `json:"ordem"`
		Tipo    *string `json:"tipo"`
		Pagina  *int    `json:"pagina"`
		X       *float64 `json:"x"`
		Y       *float64 `json:"y"`
		Largura *float64 `json:"largura"`
		Altura  *float64 `json:"altura"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Nome == "" {
		jsonErr(w, "nome é obrigatório", http.StatusBadRequest)
		return
	}

	var status string
	if err := h.db.QueryRow(r.Context(), `SELECT status FROM assinatura_digital.documentos WHERE id=$1 AND tenant_id=$2`, docID, user.TenantID).Scan(&status); err != nil {
		jsonErr(w, "Documento não encontrado", http.StatusNotFound)
		return
	}
	if status != "rascunho" {
		jsonErr(w, "Só é possível adicionar signatários em documentos em rascunho", http.StatusConflict)
		return
	}

	ordem := 1
	if body.Ordem != nil && *body.Ordem > 0 {
		ordem = *body.Ordem
	}
	tipo := "assinatura"
	if body.Tipo != nil && *body.Tipo != "" {
		tipo = *body.Tipo
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO assinatura_digital.signatarios (documento_id, tenant_id, nome, email, nuit, bi, telefone, ordem, tipo, campo_pagina, campo_x, campo_y, campo_largura, campo_altura)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14) RETURNING id`,
		docID, user.TenantID, body.Nome, body.Email, body.Nuit, body.BI, body.Telefone, ordem, tipo,
		body.Pagina, body.X, body.Y, body.Largura, body.Altura).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro ao adicionar signatário", http.StatusInternalServerError)
		return
	}

	h.log(r.Context(), docID, &id, "adicionado", map[string]any{"nome": body.Nome}, user.ID, r)

	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

// RemoverSignatario remove um signatário.
// DELETE /api/assinatura-digital/documentos/{id}/signatarios/{sigId}
func (h *Handler) RemoverSignatario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	sigID, _ := strconv.ParseInt(chi.URLParam(r, "sigId"), 10, 64)

	var status string
	if err := h.db.QueryRow(r.Context(), `SELECT status FROM assinatura_digital.documentos WHERE id=$1 AND tenant_id=$2`, docID, user.TenantID).Scan(&status); err != nil {
		jsonErr(w, "Documento não encontrado", http.StatusNotFound)
		return
	}
	if status != "rascunho" {
		jsonErr(w, "Só é possível remover signatários em documentos em rascunho", http.StatusConflict)
		return
	}

	if _, err := h.db.Exec(r.Context(), `DELETE FROM assinatura_digital.signatarios WHERE id=$1 AND documento_id=$2 AND tenant_id=$3`, sigID, docID, user.TenantID); err != nil {
		jsonErr(w, "Erro ao remover signatário", http.StatusInternalServerError)
		return
	}

	h.log(r.Context(), docID, &sigID, "removido", nil, user.ID, r)

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// EnviarParaAssinatura altera o estado para pendente.
// POST /api/assinatura-digital/documentos/{id}/enviar
func (h *Handler) EnviarParaAssinatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var count int
	if err := h.db.QueryRow(r.Context(), `SELECT COUNT(*) FROM assinatura_digital.signatarios WHERE documento_id=$1`, docID).Scan(&count); err != nil || count == 0 {
		jsonErr(w, "Documento sem signatários", http.StatusBadRequest)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE assinatura_digital.documentos SET status='pendente', data_envio=NOW(), updated_at=NOW()
		WHERE id=$1 AND tenant_id=$2 AND status='rascunho'`, docID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao enviar documento", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Documento não encontrado ou já enviado", http.StatusConflict)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE assinatura_digital.signatarios SET status='convidado' WHERE documento_id=$1 AND status='pendente'`, docID); err != nil {
		jsonErr(w, "Erro ao actualizar signatários", http.StatusInternalServerError)
		return
	}

	h.log(r.Context(), docID, nil, "enviado", map[string]any{"signatarios": count}, user.ID, r)

	jsonOK(w, map[string]any{"ok": true, "msg": "Documento enviado para assinatura"}, http.StatusOK)
}

// AssinarDocumento regista a assinatura de um signatário.
// POST /api/assinatura-digital/documentos/{id}/assinar
func (h *Handler) AssinarDocumento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var body struct {
		SignatarioID int64   `json:"signatario_id"`
		Nome         string  `json:"nome"`
		Email        string  `json:"email"`
		PIN          *string `json:"pin"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.SignatarioID <= 0 {
		jsonErr(w, "signatario_id é obrigatório", http.StatusBadRequest)
		return
	}

	var docStatus string
	if err := h.db.QueryRow(r.Context(), `SELECT status FROM assinatura_digital.documentos WHERE id=$1 AND tenant_id=$2`, docID, user.TenantID).Scan(&docStatus); err != nil {
		jsonErr(w, "Documento não encontrado", http.StatusNotFound)
		return
	}
	if docStatus != "pendente" && docStatus != "assinado" {
		jsonErr(w, "Documento não está disponível para assinatura", http.StatusConflict)
		return
	}

	var sigNome string
	if err := h.db.QueryRow(r.Context(), `
		SELECT nome FROM assinatura_digital.signatarios
		WHERE id=$1 AND documento_id=$2 AND tenant_id=$3 AND status IN ('pendente','convidado')`,
		body.SignatarioID, docID, user.TenantID).Scan(&sigNome); err != nil {
		jsonErr(w, "Signatário não encontrado ou já assinou", http.StatusNotFound)
		return
	}

	if body.Nome == "" {
		body.Nome = sigNome
	}

	// Hash da assinatura (nome + email + timestamp + documento)
	hashInput := fmt.Sprintf("%s|%s|%d|%d|%d", body.Nome, body.Email, body.SignatarioID, docID, time.Now().Unix())
	hash := sha256.Sum256([]byte(hashInput))
	hashStr := hex.EncodeToString(hash[:])

	ip := r.RemoteAddr
	if host, _, err := net.SplitHostPort(ip); err == nil {
		ip = host
	}

	_, err := h.db.Exec(r.Context(), `
		UPDATE assinatura_digital.signatarios
		SET status='assinado', assinado_em=NOW(), assinatura_hash=$1, assinatura_ip=$2
		WHERE id=$3 AND documento_id=$4`,
		hashStr, ip, body.SignatarioID, docID)
	if err != nil {
		jsonErr(w, "Erro ao registar assinatura", http.StatusInternalServerError)
		return
	}

	h.log(r.Context(), docID, &body.SignatarioID, "assinado", map[string]any{"nome": body.Nome, "email": body.Email}, user.ID, r)

	// Verifica se todos assinaram
	var pendentes int
	h.db.QueryRow(r.Context(), `SELECT COUNT(*) FROM assinatura_digital.signatarios WHERE documento_id=$1 AND status!='assinado'`, docID).Scan(&pendentes)
	if pendentes == 0 {
		h.db.Exec(r.Context(), `UPDATE assinatura_digital.documentos SET status='assinado', data_conclusao=NOW(), updated_at=NOW() WHERE id=$1`, docID)
	}

	jsonOK(w, map[string]any{"ok": true, "assinatura_hash": hashStr, "concluido": pendentes == 0}, http.StatusOK)
}

// BaixarDocumento serve o PDF original ou assinado.
// GET /api/assinatura-digital/documentos/{id}/download
func (h *Handler) BaixarDocumento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var key string
	if err := h.db.QueryRow(r.Context(), `SELECT storage_key FROM assinatura_digital.documentos WHERE id=$1 AND tenant_id=$2`, docID, user.TenantID).Scan(&key); err != nil {
		jsonErr(w, "Documento não encontrado", http.StatusNotFound)
		return
	}

	reader, _, err := h.storage.Get(r.Context(), key)
	if err != nil {
		jsonErr(w, "Documento não disponível", http.StatusNotFound)
		return
	}
	defer reader.Close()

	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="documento-%d.pdf"`, docID))
	io.Copy(w, reader)
}

// CancelarDocumento cancela o processo de assinatura.
// POST /api/assinatura-digital/documentos/{id}/cancelar
func (h *Handler) CancelarDocumento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	tag, err := h.db.Exec(r.Context(), `
		UPDATE assinatura_digital.documentos SET status='cancelado', updated_at=NOW()
		WHERE id=$1 AND tenant_id=$2 AND status IN ('rascunho','pendente')`, docID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao cancelar", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Documento não encontrado ou já concluído", http.StatusConflict)
		return
	}

	h.log(r.Context(), docID, nil, "cancelado", nil, user.ID, r)

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

func (h *Handler) log(ctx context.Context, docID int64, sigID *int64, acao string, detalhes map[string]any, userID int64, r *http.Request) {
	detalhesJSON, _ := json.Marshal(detalhes)
	ip := r.RemoteAddr
	if host, _, err := net.SplitHostPort(ip); err == nil {
		ip = host
	}
	h.db.Exec(ctx, `
		INSERT INTO assinatura_digital.logs (documento_id, tenant_id, signatario_id, acao, detalhes, user_id, ip_address)
		VALUES ($1, $2, $3, $4, $5, $6, $7::inet)`,
		docID, mw.GetUser(r).TenantID, sigID, acao, detalhesJSON, userID, ip)
}
