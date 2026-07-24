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

func reconciliationPDFKey(tenantID, reconciliationID int64) string {
	return fmt.Sprintf("tesouraria/reconciliations/tenant-%d/%d.pdf", tenantID, reconciliationID)
}

// EnviarReconciliacaoParaAssinatura cria um documento de assinatura para uma reconciliação bancária.
// Signatário: utilizador interno que fechou a reconciliação.
// POST /api/tesouraria/reconciliacoes/{id}/enviar-para-assinatura
func (h *Handler) EnviarReconciliacaoParaAssinatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var storageKey, ficheiroURL, nome, email string
	var signatarioUserID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(re.pdf_storage_key,''), COALESCE(re.ficheiro_url,''), COALESCE(u.nome,''), COALESCE(u.email,''), u.id
		FROM tesouraria.reconciliations re
		JOIN auth.users u ON u.id = re.fechada_por
		WHERE re.id=$1 AND re.tenant_id=$2`, id, user.TenantID).Scan(&storageKey, &ficheiroURL, &nome, &email, &signatarioUserID); err != nil {
		jsonErr(w, "Reconciliação não encontrada", http.StatusNotFound)
		return
	}

	if storageKey == "" {
		storageKey = reconciliationPDFKey(user.TenantID, id)
	}
	if ficheiroURL == "" {
		jsonErr(w, "Reconciliação ainda não tem PDF gerado", http.StatusBadRequest)
		return
	}

	reader, _, err := h.storage.Get(r.Context(), storageKey)
	if err != nil {
		jsonErr(w, "PDF da reconciliação não disponível", http.StatusNotFound)
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
		Titulo:           fmt.Sprintf("Reconciliação bancária #%d", id),
		StorageKey:       storageKey,
		FicheiroURL:      ficheiroURL,
		HashSHA256:       hex.EncodeToString(hash[:]),
		CreatedBy:        user.ID,
		SignatarioNome:   nome,
		SignatarioEmail:  email,
		SignatarioUserID: &signatarioUserID,
		OrigemModulo:     "tesouraria",
		OrigemID:         id,
	}

	docID, err := h.signature.CreateForSigning(r.Context(), req)
	if err != nil {
		jsonErr(w, "Erro ao criar documento de assinatura", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE tesouraria.reconciliations SET assinatura_documento_id=$1 WHERE id=$2 AND tenant_id=$3`,
		docID, id, user.TenantID); err != nil {
		jsonErr(w, "Erro ao actualizar reconciliação", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "assinatura_documento_id": docID}, http.StatusCreated)
}
