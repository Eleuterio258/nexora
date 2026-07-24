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

func auditDocumentPDFKey(tenantID, documentID int64) string {
	return fmt.Sprintf("auditoria/documents/tenant-%d/%d.pdf", tenantID, documentID)
}

// EnviarDocumentoAuditoriaParaAssinatura cria um documento de assinatura para um documento de auditoria.
// Signatário: utilizador interno vinculado ao documento.
// POST /api/auditoria/documents/{id}/enviar-para-assinatura
func (h *Handler) EnviarDocumentoAuditoriaParaAssinatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var storageKey, ficheiroURL, nome, email string
	var signatarioUserID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(d.pdf_storage_key,''), COALESCE(d.ficheiro_url,''), COALESCE(u.nome,''), COALESCE(u.email,''), u.id
		FROM auditoria.audit_documents d
		JOIN auth.users u ON u.id = d.user_id
		WHERE d.id=$1 AND d.tenant_id=$2`, id, user.TenantID).Scan(&storageKey, &ficheiroURL, &nome, &email, &signatarioUserID); err != nil {
		jsonErr(w, "Documento de auditoria não encontrado", http.StatusNotFound)
		return
	}

	if storageKey == "" {
		storageKey = auditDocumentPDFKey(user.TenantID, id)
	}
	if ficheiroURL == "" {
		jsonErr(w, "Documento ainda não tem PDF gerado", http.StatusBadRequest)
		return
	}

	reader, _, err := h.storage.Get(r.Context(), storageKey)
	if err != nil {
		jsonErr(w, "PDF do documento de auditoria não disponível", http.StatusNotFound)
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
		Titulo:           fmt.Sprintf("Documento de auditoria — %s", nome),
		StorageKey:       storageKey,
		FicheiroURL:      ficheiroURL,
		HashSHA256:       hex.EncodeToString(hash[:]),
		CreatedBy:        user.ID,
		SignatarioNome:   nome,
		SignatarioEmail:  email,
		SignatarioUserID: &signatarioUserID,
		OrigemModulo:     "auditoria",
		OrigemID:         id,
	}

	docID, err := h.signature.CreateForSigning(r.Context(), req)
	if err != nil {
		jsonErr(w, "Erro ao criar documento de assinatura", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE auditoria.audit_documents SET assinatura_documento_id=$1 WHERE id=$2 AND tenant_id=$3`,
		docID, id, user.TenantID); err != nil {
		jsonErr(w, "Erro ao actualizar documento de auditoria", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "assinatura_documento_id": docID}, http.StatusCreated)
}
