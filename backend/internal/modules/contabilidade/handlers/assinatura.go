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

func accountingReportPDFKey(tenantID, reportID int64) string {
	return fmt.Sprintf("contabilidade/reports/tenant-%d/%d.pdf", tenantID, reportID)
}

// EnviarRelatorioParaAssinatura cria um documento de assinatura para um relatório contabilístico.
// Signatário: utilizador interno que gerou o relatório.
// POST /api/contabilidade/reports/{id}/enviar-para-assinatura
func (h *Handler) EnviarRelatorioParaAssinatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var storageKey, ficheiroURL, nome, email string
	var signatarioUserID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(ar.pdf_storage_key,''), COALESCE(ar.ficheiro_url,''), COALESCE(u.nome,''), COALESCE(u.email,''), u.id
		FROM contabilidade.accounting_reports ar
		JOIN auth.users u ON u.id = ar.gerado_por
		WHERE ar.id=$1 AND ar.tenant_id=$2`, id, user.TenantID).Scan(&storageKey, &ficheiroURL, &nome, &email, &signatarioUserID); err != nil {
		jsonErr(w, "Relatório não encontrado", http.StatusNotFound)
		return
	}

	if storageKey == "" {
		storageKey = accountingReportPDFKey(user.TenantID, id)
	}
	if ficheiroURL == "" {
		jsonErr(w, "Relatório ainda não tem PDF gerado", http.StatusBadRequest)
		return
	}

	reader, _, err := h.storage.Get(r.Context(), storageKey)
	if err != nil {
		jsonErr(w, "PDF do relatório não disponível", http.StatusNotFound)
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
		Titulo:           fmt.Sprintf("Relatório contabilístico #%d", id),
		StorageKey:       storageKey,
		FicheiroURL:      ficheiroURL,
		HashSHA256:       hex.EncodeToString(hash[:]),
		CreatedBy:        user.ID,
		SignatarioNome:   nome,
		SignatarioEmail:  email,
		SignatarioUserID: &signatarioUserID,
		OrigemModulo:     "contabilidade",
		OrigemID:         id,
	}

	docID, err := h.signature.CreateForSigning(r.Context(), req)
	if err != nil {
		jsonErr(w, "Erro ao criar documento de assinatura", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE contabilidade.accounting_reports SET assinatura_documento_id=$1 WHERE id=$2 AND tenant_id=$3`,
		docID, id, user.TenantID); err != nil {
		jsonErr(w, "Erro ao actualizar relatório", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "assinatura_documento_id": docID}, http.StatusCreated)
}
