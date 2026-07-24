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

func candidaturaPDFKey(tenantID, candidaturaID int64) string {
	return fmt.Sprintf("recrutamento/candidaturas/tenant-%d/%d.pdf", tenantID, candidaturaID)
}

// EnviarCandidaturaParaAssinatura cria um documento de assinatura para uma proposta/aceitação de candidatura.
// Signatário: candidato externo.
// POST /api/recrutamento/candidaturas/{id}/enviar-para-assinatura
func (h *Handler) EnviarCandidaturaParaAssinatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rawID := chi.URLParam(r, "id")
	id, _ := strconv.ParseInt(h.decodeID(rawID), 10, 64)

	var storageKey, ficheiroURL, nome, email string
	if err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(c.pdf_storage_key,''), COALESCE(c.ficheiro_url,''), COALESCE(c.nome,''), COALESCE(c.email,'')
		FROM recrutamento.candidaturas c
		WHERE c.id=$1 AND c.tenant_id=$2`, id, user.TenantID).Scan(&storageKey, &ficheiroURL, &nome, &email); err != nil {
		jsonErr(w, "Candidatura não encontrada", http.StatusNotFound)
		return
	}

	if storageKey == "" {
		storageKey = candidaturaPDFKey(user.TenantID, id)
	}
	if ficheiroURL == "" {
		jsonErr(w, "Candidatura ainda não tem PDF gerado", http.StatusBadRequest)
		return
	}

	reader, _, err := h.storage.Get(r.Context(), storageKey)
	if err != nil {
		jsonErr(w, "PDF da candidatura não disponível", http.StatusNotFound)
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
		TenantID:        user.TenantID,
		Titulo:          fmt.Sprintf("Proposta de contratação — %s", nome),
		StorageKey:      storageKey,
		FicheiroURL:     ficheiroURL,
		HashSHA256:      hex.EncodeToString(hash[:]),
		CreatedBy:       user.ID,
		SignatarioNome:  nome,
		SignatarioEmail: email,
		OrigemModulo:    "recrutamento",
		OrigemID:        id,
	}

	docID, err := h.signature.CreateForSigning(r.Context(), req)
	if err != nil {
		jsonErr(w, "Erro ao criar documento de assinatura", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE recrutamento.candidaturas SET assinatura_documento_id=$1 WHERE id=$2 AND tenant_id=$3`,
		docID, id, user.TenantID); err != nil {
		jsonErr(w, "Erro ao actualizar candidatura", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "assinatura_documento_id": docID}, http.StatusCreated)
}
