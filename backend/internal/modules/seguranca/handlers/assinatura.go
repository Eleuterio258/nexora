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

func securityPolicyPDFKey(tenantID, policyID int64) string {
	return fmt.Sprintf("seguranca/policies/tenant-%d/%d.pdf", tenantID, policyID)
}

// EnviarPoliticaParaAssinatura cria um documento de assinatura para uma política de segurança.
// Signatário: utilizador interno responsável pela política (updated_by).
// POST /api/seguranca/politicas/{id}/enviar-para-assinatura
func (h *Handler) EnviarPoliticaParaAssinatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var storageKey, ficheiroURL, nome, email string
	var signatarioUserID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(p.pdf_storage_key,''), COALESCE(p.ficheiro_url,''), COALESCE(u.nome,''), COALESCE(u.email,''), u.id
		FROM seguranca.security_policies p
		JOIN auth.users u ON u.id = p.updated_by
		WHERE p.id=$1 AND p.tenant_id=$2`, id, user.TenantID).Scan(&storageKey, &ficheiroURL, &nome, &email, &signatarioUserID); err != nil {
		jsonErr(w, "Política não encontrada", http.StatusNotFound)
		return
	}

	if storageKey == "" {
		storageKey = securityPolicyPDFKey(user.TenantID, id)
	}
	if ficheiroURL == "" {
		jsonErr(w, "Política ainda não tem PDF gerado", http.StatusBadRequest)
		return
	}

	reader, _, err := h.storage.Get(r.Context(), storageKey)
	if err != nil {
		jsonErr(w, "PDF da política não disponível", http.StatusNotFound)
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
		Titulo:           fmt.Sprintf("Política de segurança #%d", id),
		StorageKey:       storageKey,
		FicheiroURL:      ficheiroURL,
		HashSHA256:       hex.EncodeToString(hash[:]),
		CreatedBy:        user.ID,
		SignatarioNome:   nome,
		SignatarioEmail:  email,
		SignatarioUserID: &signatarioUserID,
		OrigemModulo:     "seguranca",
		OrigemID:         id,
	}

	docID, err := h.signature.CreateForSigning(r.Context(), req)
	if err != nil {
		jsonErr(w, "Erro ao criar documento de assinatura", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE seguranca.security_policies SET assinatura_documento_id=$1 WHERE id=$2 AND tenant_id=$3`,
		docID, id, user.TenantID); err != nil {
		jsonErr(w, "Erro ao actualizar política", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "assinatura_documento_id": docID}, http.StatusCreated)
}
