package handlers

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/shared/contracts"
)

func approvalRequestPDFKey(tenantID, requestID int64) string {
	return fmt.Sprintf("aprovacoes/requests/tenant-%d/%d.pdf", tenantID, requestID)
}

// EnviarRequestParaAssinatura cria um documento de assinatura para uma decisão de aprovação.
// Signatário: aprovador do nível actual (utilizador interno).
// POST /api/aprovacoes/requests/{id}/enviar-para-assinatura
func (h *Handler) EnviarRequestParaAssinatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var storageKey, ficheiroURL, signatarioNome, signatarioEmail string
	var signatarioUserID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(ar.pdf_storage_key,''), COALESCE(ar.ficheiro_url,''), COALESCE(u.nome,''), COALESCE(u.email,''), u.id
		FROM saas.approval_requests ar
		JOIN auth.users u ON u.id = (
			SELECT a.decisao_por FROM saas.approval_decisions a
			WHERE a.request_id = ar.id AND a.nivel = ar.nivel_atual
			ORDER BY a.created_at DESC LIMIT 1
		)
		WHERE ar.id=$1 AND ar.tenant_id=$2`, id, user.TenantID).Scan(&storageKey, &ficheiroURL, &signatarioNome, &signatarioEmail, &signatarioUserID); err != nil {
		jsonErr(w, "Pedido de aprovação não encontrado", http.StatusNotFound)
		return
	}

	if storageKey == "" {
		storageKey = approvalRequestPDFKey(user.TenantID, id)
	}
	if ficheiroURL == "" {
		jsonErr(w, "Pedido de aprovação ainda não tem PDF gerado", http.StatusBadRequest)
		return
	}

	reader, _, err := h.storage.Get(r.Context(), storageKey)
	if err != nil {
		jsonErr(w, "PDF do pedido de aprovação não disponível", http.StatusNotFound)
		return
	}
	data, err := io.ReadAll(reader)
	reader.Close()
	if err != nil {
		jsonErr(w, "Erro ao ler PDF", http.StatusInternalServerError)
		return
	}

	hash := sha256.Sum256(data)
	req := contracts.SignatureDocumentRequest{
		TenantID:         user.TenantID,
		Titulo:           fmt.Sprintf("Decisão de aprovação #%d", id),
		StorageKey:       storageKey,
		FicheiroURL:      ficheiroURL,
		HashSHA256:       hex.EncodeToString(hash[:]),
		CreatedBy:        user.ID,
		SignatarioNome:   signatarioNome,
		SignatarioEmail:  signatarioEmail,
		SignatarioUserID: &signatarioUserID,
		OrigemModulo:     "aprovacoes",
		OrigemID:         id,
	}

	docID, err := h.signature.CreateForSigning(r.Context(), req)
	if err != nil {
		jsonErr(w, "Erro ao criar documento de assinatura", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE saas.approval_requests SET assinatura_documento_id=$1 WHERE id=$2 AND tenant_id=$3`,
		docID, id, user.TenantID); err != nil {
		jsonErr(w, "Erro ao actualizar pedido de aprovação", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "assinatura_documento_id": docID}, http.StatusCreated)
}
