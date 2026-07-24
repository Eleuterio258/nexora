package handlers

import (
	"crypto/sha256"
	"encoding/hex"
	"io"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/shared/contracts"
)

// EnviarParaAssinatura cria um documento no módulo assinatura-digital a
// partir do PDF já gerado do contrato (reaproveita o ficheiro, não faz novo
// upload) e associa o funcionário como signatário. O documento fica em
// 'rascunho' — o próprio módulo assinatura-digital é usado depois para o
// enviar (POST /api/assinatura-digital/documentos/{id}/enviar).
// POST /api/rh/contratos/{id}/enviar-para-assinatura
func (h *Handler) EnviarParaAssinatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var ficheiroURL, funcNome, funcEmail string
	var funcUserID *int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(c.ficheiro_url,''), f.nome_completo, COALESCE(f.email,''), f.user_id
		FROM rh.contratos c
		JOIN rh.funcionarios f ON f.id = c.funcionario_id
		WHERE c.id=$1 AND c.tenant_id=$2`,
		id, user.TenantID).Scan(&ficheiroURL, &funcNome, &funcEmail, &funcUserID); err != nil {
		jsonErr(w, "Contrato não encontrado", http.StatusNotFound)
		return
	}
	if ficheiroURL == "" {
		jsonErr(w, "Contrato ainda não tem PDF gerado", http.StatusBadRequest)
		return
	}

	key := contratoPdfKey(user.TenantID, id)
	reader, _, err := h.storage.Get(r.Context(), key)
	if err != nil {
		jsonErr(w, "PDF do contrato não disponível", http.StatusNotFound)
		return
	}
	data, err := io.ReadAll(reader)
	reader.Close()
	if err != nil {
		jsonErr(w, "Erro ao ler PDF do contrato", http.StatusInternalServerError)
		return
	}

	hash := sha256.Sum256(data)
	origemID, _ := strconv.ParseInt(id, 10, 64)

	docID, err := h.signature.CreateForSigning(r.Context(), contracts.SignatureDocumentRequest{
		TenantID:         user.TenantID,
		Titulo:           "Contrato de trabalho — " + funcNome,
		StorageKey:       key,
		FicheiroURL:      ficheiroURL,
		HashSHA256:       hex.EncodeToString(hash[:]),
		CreatedBy:        user.ID,
		SignatarioNome:   funcNome,
		SignatarioEmail:  funcEmail,
		SignatarioUserID: funcUserID,
		OrigemModulo:     "recursos-humanos",
		OrigemID:         origemID,
	})
	if err != nil {
		jsonErr(w, "Erro ao criar documento de assinatura", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE rh.contratos SET assinatura_documento_id=$1 WHERE id=$2 AND tenant_id=$3`,
		docID, id, user.TenantID); err != nil {
		jsonErr(w, "Erro ao actualizar contrato", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "assinatura_documento_id": docID}, http.StatusCreated)
}
