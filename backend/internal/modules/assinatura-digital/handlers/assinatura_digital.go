package handlers

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/shared/contracts"
	"nexora/internal/shared/pessoas"
	"nexora/internal/storage"
)

const conviteValidadeDias = 7

const maxDocumentoBytes = 20 << 20 // 20MB

// pdfMagicBytes é a assinatura de ficheiro (magic bytes) de um PDF válido.
var pdfMagicBytes = []byte("%PDF-")

// contentKey gera uma chave de storage a partir do hash do conteúdo (em vez
// do id do documento), para que o upload possa acontecer antes do INSERT na
// BD — se o storage falhar, nenhum registo órfão fica na base de dados.
func contentKey(tenantID int64, hashHex, suffix string) string {
	return storage.JoinPath("assinatura-digital", fmt.Sprintf("tenant-%d", tenantID), hashHex+suffix)
}

// CriarDocumento faz upload do PDF original. Valida a assinatura de ficheiro
// (%PDF-), grava no storage antes de inserir na BD (evita registo órfão em
// caso de falha do storage) e usa o hash do conteúdo como chave.
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
	if !bytes.HasPrefix(data, pdfMagicBytes) {
		jsonErr(w, "O ficheiro não é um PDF válido", http.StatusBadRequest)
		return
	}
	if suspeitos := detectarConteudoSuspeitoPDF(data); len(suspeitos) > 0 {
		jsonErr(w, "PDF rejeitado por conter conteúdo potencialmente activo: "+strings.Join(suspeitos, "; "), http.StatusBadRequest)
		return
	}

	if h.antivirus != nil {
		res, err := h.antivirus.Verificar(header.Filename, data)
		if err != nil {
			jsonErr(w, "Erro ao verificar ficheiro com antivírus", http.StatusInternalServerError)
			return
		}
		if res.Infectado {
			jsonErr(w, "Ficheiro rejeitado pelo antivírus: "+res.Motivo, http.StatusBadRequest)
			return
		}
	}

	titulo := r.FormValue("titulo")
	if titulo == "" {
		titulo = header.Filename
	}

	hash := sha256.Sum256(data)
	hashStr := hex.EncodeToString(hash[:])

	key := contentKey(user.TenantID, hashStr, ".pdf")
	url, err := h.storage.PutImmutable(r.Context(), key, data, "application/pdf")
	if err != nil {
		jsonErr(w, "Erro ao guardar documento", http.StatusInternalServerError)
		return
	}

	var id int64
	err = h.db.QueryRow(r.Context(), `
		INSERT INTO assinatura_digital.documentos (tenant_id, titulo, descricao, hash_sha256, storage_key, ficheiro_url, status, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,'rascunho',$7) RETURNING id`,
		user.TenantID, titulo, r.FormValue("descricao"), hashStr, key, url, user.ID).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro ao registar documento", http.StatusInternalServerError)
		return
	}

	h.log(r.Context(), id, nil, "upload", map[string]any{"titulo": titulo, "tamanho": len(data)}, user.TenantID, &user.ID, r)

	jsonOK(w, map[string]any{"id": id, "status": "rascunho", "url": url}, http.StatusCreated)
}

// ListarDocumentos lista os documentos do tenant.
// GET /api/assinatura-digital/documentos
func (h *Handler) ListarDocumentos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	rows, _ := h.db.Query(r.Context(), `
		SELECT d.id, d.titulo, d.descricao, d.status, d.created_at, d.data_envio, d.data_conclusao,
		       (SELECT COUNT(*) FROM assinatura_digital.signatarios s WHERE s.documento_id = d.id) as total_signatarios,
		       (SELECT COUNT(*) FROM assinatura_digital.signatarios s WHERE s.documento_id = d.id AND s.status IN ('assinado','aceite_eletronicamente')) as assinados
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
		Nome     string   `json:"nome"`
		Email    *string  `json:"email"`
		Nuit     *string  `json:"nuit"`
		BI       *string  `json:"bi"`
		Telefone *string  `json:"telefone"`
		Ordem    *int     `json:"ordem"`
		Tipo     *string  `json:"tipo"`
		Pagina   *int     `json:"pagina"`
		X        *float64 `json:"x"`
		Y        *float64 `json:"y"`
		Largura  *float64 `json:"largura"`
		Altura   *float64 `json:"altura"`
		UserID   *int64   `json:"user_id"`
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

	var userID *int64
	if body.UserID != nil && *body.UserID > 0 {
		var pertence bool
		h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM auth.memberships WHERE user_id=$1 AND tenant_id=$2)`, *body.UserID, user.TenantID).Scan(&pertence)
		if !pertence {
			jsonErr(w, "user_id não pertence a este tenant", http.StatusBadRequest)
			return
		}
		userID = body.UserID
	}

	var pessoaID *int64
	if userID != nil {
		if pid, err := pessoas.EnsureUserPessoa(r.Context(), h.db, *userID, body.Nome, nil); err == nil {
			pessoaID = &pid
		}
	} else if pid, err := pessoas.EnsurePessoa(r.Context(), h.db, body.Nome); err == nil {
		pessoaID = &pid
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO assinatura_digital.signatarios (documento_id, tenant_id, nome, email, nuit, bi, telefone, ordem, tipo, campo_pagina, campo_x, campo_y, campo_largura, campo_altura, pessoa_id, user_id)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16) RETURNING id`,
		docID, user.TenantID, body.Nome, body.Email, body.Nuit, body.BI, body.Telefone, ordem, tipo,
		body.Pagina, body.X, body.Y, body.Largura, body.Altura, pessoaID, userID).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro ao adicionar signatário", http.StatusInternalServerError)
		return
	}

	h.log(r.Context(), docID, &id, "adicionado", map[string]any{"nome": body.Nome}, user.TenantID, &user.ID, r)

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

	h.log(r.Context(), docID, &sigID, "removido", nil, user.TenantID, &user.ID, r)

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

	h.gerarConvites(r.Context(), docID, user.TenantID)

	h.log(r.Context(), docID, nil, "enviado", map[string]any{"signatarios": count}, user.TenantID, &user.ID, r)

	jsonOK(w, map[string]any{"ok": true, "msg": "Documento enviado para assinatura"}, http.StatusOK)
}

// gerarConvites cria um convite único por signatário e, quando há email,
// despacha-o via o sistema de notificações do ERP. Falhas de notificação não
// bloqueiam o envio do documento (mesma tolerância usada no resto do projecto).
func (h *Handler) gerarConvites(ctx context.Context, docID, tenantID int64) {
	rows, err := h.db.Query(ctx, `
		SELECT id, nome, email FROM assinatura_digital.signatarios
		WHERE documento_id=$1 AND status='convidado'`, docID)
	if err != nil {
		return
	}
	defer rows.Close()

	type sig struct {
		id    int64
		nome  string
		email *string
	}
	var signatarios []sig
	for rows.Next() {
		var s sig
		if rows.Scan(&s.id, &s.nome, &s.email) == nil {
			signatarios = append(signatarios, s)
		}
	}

	for _, s := range signatarios {
		b := make([]byte, 32)
		if _, err := rand.Read(b); err != nil {
			continue
		}
		token := hex.EncodeToString(b)
		tokenHash := mw.HashToken(token)

		if _, err := h.db.Exec(ctx, `
			INSERT INTO assinatura_digital.convites (documento_id, signatario_id, tenant_id, token_hash, expira_em)
			VALUES ($1,$2,$3,$4, NOW() + ($5 || ' days')::interval)`,
			docID, s.id, tenantID, tokenHash, conviteValidadeDias); err != nil {
			continue
		}

		if s.email == nil || *s.email == "" || h.notif == nil {
			continue
		}
		acesso := token
		if h.cfg.SignatureInviteBaseURL != "" {
			acesso = fmt.Sprintf("%s/%s", strings.TrimRight(h.cfg.SignatureInviteBaseURL, "/"), token)
		}
		corpo := fmt.Sprintf(
			"Olá %s, foi convidado(a) a assinar um documento. Aceda a %s para confirmar a sua identidade e assinar.\n\nEste convite expira em %d dias.",
			s.nome, acesso, conviteValidadeDias)
		h.notif.Send(ctx, contracts.Notification{
			TenantID:       tenantID,
			CanalTipo:      "email",
			Destinatario:   *s.email,
			Assunto:        "Convite para assinatura de documento",
			Corpo:          corpo,
			ReferenciaTipo: "assinatura-digital.convite",
			ReferenciaID:   &s.id,
		})
	}
}

// AssinarDocumento regista a assinatura de um utilizador ERP autenticado,
// vinculado ao signatário via signatarios.user_id. Signatários sem conta ERP
// (user_id nulo) têm de assinar pelo fluxo de convite (ver convites.go).
// POST /api/assinatura-digital/documentos/{id}/assinar
func (h *Handler) AssinarDocumento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var body struct {
		SignatarioID int64 `json:"signatario_id"`
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
	if docStatus != "pendente" && docStatus != "parcialmente_assinado" {
		jsonErr(w, "Documento não está disponível para assinatura", http.StatusConflict)
		return
	}

	var sigUserID *int64
	var ordem int
	if err := h.db.QueryRow(r.Context(), `
		SELECT user_id, ordem FROM assinatura_digital.signatarios
		WHERE id=$1 AND documento_id=$2 AND tenant_id=$3 AND status IN ('pendente','convidado')`,
		body.SignatarioID, docID, user.TenantID).Scan(&sigUserID, &ordem); err != nil {
		jsonErr(w, "Signatário não encontrado ou já assinou", http.StatusNotFound)
		return
	}
	if sigUserID == nil || *sigUserID != user.ID {
		jsonErr(w, "Este signatário deve confirmar pelo convite de assinatura enviado por email", http.StatusForbidden)
		return
	}

	ordemOK, err := h.verificarOrdem(r.Context(), docID, ordem)
	if err != nil {
		jsonErr(w, "Erro ao verificar ordem de assinatura", http.StatusInternalServerError)
		return
	}
	if !ordemOK {
		jsonErr(w, "Existem signatários anteriores que ainda não assinaram", http.StatusConflict)
		return
	}

	var nome, email string
	if err := h.db.QueryRow(r.Context(), `SELECT nome, email FROM auth.users WHERE id=$1`, user.ID).Scan(&nome, &email); err != nil {
		jsonErr(w, "Erro ao obter dados do utilizador", http.StatusInternalServerError)
		return
	}

	detalhes := map[string]any{"nome": nome, "email": email}
	hashStr, concluido, padesGerado, err := h.marcarAssinado(
		r.Context(), r, user.TenantID, docID, body.SignatarioID, nome, email,
		&user.ID, nil, &user.ID, detalhes,
	)
	if err != nil {
		if errors.Is(err, errGeracaoPAdES) {
			h.logPadesFalhou(r.Context(), r, user.TenantID, docID, body.SignatarioID, err.Error())
		}
		h.responderErroAssinatura(w, err)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "assinatura_hash": hashStr, "concluido": concluido, "pades_gerado": padesGerado}, http.StatusOK)
}

// RecusarSignatario regista a recusa de assinatura de um signatário vinculado
// ao utilizador autenticado.
// POST /api/assinatura-digital/documentos/{id}/signatarios/{sigId}/recusar
func (h *Handler) RecusarSignatario(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	sigID, _ := strconv.ParseInt(chi.URLParam(r, "sigId"), 10, 64)

	var body struct {
		Motivo string `json:"motivo"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	var sigUserID *int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT user_id FROM assinatura_digital.signatarios
		WHERE id=$1 AND documento_id=$2 AND tenant_id=$3 AND status IN ('pendente','convidado')`,
		sigID, docID, user.TenantID).Scan(&sigUserID); err != nil {
		jsonErr(w, "Signatário não encontrado ou já concluído", http.StatusNotFound)
		return
	}
	if sigUserID == nil || *sigUserID != user.ID {
		jsonErr(w, "Este signatário deve recusar pelo convite de assinatura enviado por email", http.StatusForbidden)
		return
	}

	// O status volta a ser verificado no próprio UPDATE (não só na SELECT
	// acima) para impedir que uma recusa concorrente sobreponha um "assinado"
	// já persistido por um pedido de assinatura em curso no mesmo instante.
	tag, err := h.db.Exec(r.Context(), `
		UPDATE assinatura_digital.signatarios
		SET status='recusado', recusado_em=NOW(), motivo_recusa=$1
		WHERE id=$2 AND documento_id=$3 AND status IN ('pendente','convidado')`,
		body.Motivo, sigID, docID)
	if err != nil {
		jsonErr(w, "Erro ao registar recusa", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Signatário não encontrado ou já concluído", http.StatusConflict)
		return
	}

	h.log(r.Context(), docID, &sigID, "recusado", map[string]any{"motivo": body.Motivo}, user.TenantID, &user.ID, r)

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// verificarOrdem devolve false se existir signatário do tipo "assinatura" com
// ordem inferior à indicada que ainda não tenha assinado — impõe a sequência
// declarada em signatarios.ordem.
func (h *Handler) verificarOrdem(ctx context.Context, docID int64, ordem int) (bool, error) {
	var pendentesAntes int
	err := h.db.QueryRow(ctx, `
		SELECT COUNT(*) FROM assinatura_digital.signatarios
		WHERE documento_id=$1 AND tipo='assinatura' AND ordem < $2 AND status NOT IN ('assinado','aceite_eletronicamente')`,
		docID, ordem).Scan(&pendentesAntes)
	if err != nil {
		return false, err
	}
	return pendentesAntes == 0, nil
}

func (h *Handler) logPadesFalhou(ctx context.Context, r *http.Request, tenantID, docID, sigID int64, motivo string) {
	h.log(ctx, docID, &sigID, "pades_falhou", map[string]any{"erro": motivo}, tenantID, nil, r)
}

// BaixarDocumento serve a última versão assinada (PAdES) do documento quando
// existir; caso contrário serve o original. Em ambos os casos verifica o
// hash antes de servir.
// GET /api/assinatura-digital/documentos/{id}/download
func (h *Handler) BaixarDocumento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var pertence bool
	h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM assinatura_digital.documentos WHERE id=$1 AND tenant_id=$2)`, docID, user.TenantID).Scan(&pertence)
	if !pertence {
		jsonErr(w, "Documento não encontrado", http.StatusNotFound)
		return
	}

	var key, hashEsperado string
	err := h.db.QueryRow(r.Context(), `
		SELECT storage_key, hash_sha256 FROM assinatura_digital.versoes_assinadas
		WHERE documento_id=$1 ORDER BY created_at DESC LIMIT 1`, docID).Scan(&key, &hashEsperado)
	if err != nil {
		if err := h.db.QueryRow(r.Context(), `SELECT storage_key, hash_sha256 FROM assinatura_digital.documentos WHERE id=$1`, docID).Scan(&key, &hashEsperado); err != nil {
			jsonErr(w, "Documento não encontrado", http.StatusNotFound)
			return
		}
	}

	h.servirPDFVerificado(w, r, docID, user.TenantID, &user.ID, key, hashEsperado, false)
}

// BaixarOriginal serve sempre o PDF original enviado, mesmo que já existam
// versões assinadas.
// GET /api/assinatura-digital/documentos/{id}/original/download
func (h *Handler) BaixarOriginal(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var key, hashEsperado string
	if err := h.db.QueryRow(r.Context(), `SELECT storage_key, hash_sha256 FROM assinatura_digital.documentos WHERE id=$1 AND tenant_id=$2`, docID, user.TenantID).Scan(&key, &hashEsperado); err != nil {
		jsonErr(w, "Documento não encontrado", http.StatusNotFound)
		return
	}

	h.servirPDFVerificado(w, r, docID, user.TenantID, &user.ID, key, hashEsperado, false)
}

// ListarVersoes lista as versões assinadas (evidência PAdES) de um documento.
// GET /api/assinatura-digital/documentos/{id}/versoes
func (h *Handler) ListarVersoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var pertence bool
	h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM assinatura_digital.documentos WHERE id=$1 AND tenant_id=$2)`, docID, user.TenantID).Scan(&pertence)
	if !pertence {
		jsonErr(w, "Documento não encontrado", http.StatusNotFound)
		return
	}

	rows, _ := h.db.Query(r.Context(), `
		SELECT id, signatario_id, provider, legal_valido, certificado_subject, algoritmo_assinatura, timestamp_autoridade, created_at
		FROM assinatura_digital.versoes_assinadas
		WHERE documento_id=$1 ORDER BY created_at`, docID)
	defer rows.Close()

	type Versao struct {
		ID                  int64     `json:"id"`
		SignatarioID        *int64    `json:"signatario_id"`
		Provider            *string   `json:"provider"`
		LegalValido         bool      `json:"legal_valido"`
		CertificadoSubject  *string   `json:"certificado_subject"`
		AlgoritmoAssinatura *string   `json:"algoritmo_assinatura"`
		TimestampAutoridade *string   `json:"timestamp_autoridade"`
		CreatedAt           time.Time `json:"created_at"`
	}
	data := []Versao{}
	for rows.Next() {
		var v Versao
		if rows.Scan(&v.ID, &v.SignatarioID, &v.Provider, &v.LegalValido, &v.CertificadoSubject, &v.AlgoritmoAssinatura, &v.TimestampAutoridade, &v.CreatedAt) == nil {
			data = append(data, v)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// BaixarVersao serve uma versão assinada específica.
// GET /api/assinatura-digital/documentos/{id}/versoes/{versaoId}/download
func (h *Handler) BaixarVersao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	docID, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	versaoID, _ := strconv.ParseInt(chi.URLParam(r, "versaoId"), 10, 64)

	var key, hashEsperado string
	if err := h.db.QueryRow(r.Context(), `
		SELECT v.storage_key, v.hash_sha256
		FROM assinatura_digital.versoes_assinadas v
		JOIN assinatura_digital.documentos d ON d.id = v.documento_id
		WHERE v.id=$1 AND v.documento_id=$2 AND d.tenant_id=$3`,
		versaoID, docID, user.TenantID).Scan(&key, &hashEsperado); err != nil {
		jsonErr(w, "Versão não encontrada", http.StatusNotFound)
		return
	}

	h.servirPDFVerificado(w, r, docID, user.TenantID, &user.ID, key, hashEsperado, false)
}

// servirPDFVerificado lê o objecto do storage, confirma que o hash
// corresponde ao gravado e só então o serve — recusa servir um ficheiro cujo
// conteúdo não bate certo com o hash registado.
// O parâmetro inline controla o Content-Disposition: true para visualização no
// browser, false para download. tenantID e userID são usados apenas para log;
// userID pode ser nil em fluxos sem sessão ERP.
func (h *Handler) servirPDFVerificado(w http.ResponseWriter, r *http.Request, docID, tenantID int64, userID *int64, key, hashEsperado string, inline bool) {
	reader, _, err := h.storage.Get(r.Context(), key)
	if err != nil {
		jsonErr(w, "Documento não disponível", http.StatusNotFound)
		return
	}
	defer reader.Close()

	data, err := io.ReadAll(reader)
	if err != nil {
		jsonErr(w, "Erro ao ler documento", http.StatusInternalServerError)
		return
	}

	hash := sha256.Sum256(data)
	if hex.EncodeToString(hash[:]) != hashEsperado {
		h.log(r.Context(), docID, nil, "integridade_falhou", nil, tenantID, userID, r)
		jsonErr(w, "Falha na verificação de integridade do documento", http.StatusConflict)
		return
	}

	w.Header().Set("Content-Type", "application/pdf")
	if inline {
		w.Header().Set("Content-Disposition", fmt.Sprintf(`inline; filename="documento-%d.pdf"`, docID))
	} else {
		w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="documento-%d.pdf"`, docID))
	}
	w.Write(data)
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

	h.log(r.Context(), docID, nil, "cancelado", nil, user.TenantID, &user.ID, r)

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// log regista uma entrada de auditoria imutável. userID é nil nas acções do
// fluxo de convite (sem sessão ERP).
func (h *Handler) log(ctx context.Context, docID int64, sigID *int64, acao string, detalhes map[string]any, tenantID int64, userID *int64, r *http.Request) {
	detalhesJSON, _ := json.Marshal(detalhes)
	ip := ""
	if r != nil {
		ip = r.RemoteAddr
		if host, _, err := net.SplitHostPort(ip); err == nil {
			ip = host
		}
	}
	h.db.Exec(ctx, `
		INSERT INTO assinatura_digital.logs (documento_id, tenant_id, signatario_id, acao, detalhes, user_id, ip_address)
		VALUES ($1, $2, $3, $4, $5, $6, NULLIF($7,'')::inet)`,
		docID, tenantID, sigID, acao, detalhesJSON, userID, ip)
}
