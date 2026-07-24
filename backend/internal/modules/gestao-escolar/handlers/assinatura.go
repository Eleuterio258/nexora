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

func enrollmentPDFKey(tenantID, enrollmentID int64) string {
	return fmt.Sprintf("gestao-escolar/enrollments/tenant-%d/%d.pdf", tenantID, enrollmentID)
}

// EnviarMatriculaParaAssinatura cria um documento de assinatura para uma matrícula escolar.
// Signatário: encarregado de educação principal.
// POST /api/escolar/enrollments/{id}/enviar-para-assinatura
func (h *Handler) EnviarMatriculaParaAssinatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var storageKey, ficheiroURL, nome, email string
	if err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(e.pdf_storage_key,''), COALESCE(e.ficheiro_url,''), COALESCE(g.nome,''), COALESCE(g.email,'')
		FROM gestao_escolar.school_enrollments e
		JOIN gestao_escolar.school_students s ON s.id = e.student_id
		JOIN gestao_escolar.school_guardians g ON g.student_id = s.id AND g.principal = TRUE
		WHERE e.id=$1 AND e.tenant_id=$2`, id, user.TenantID).Scan(&storageKey, &ficheiroURL, &nome, &email); err != nil {
		jsonErr(w, "Matrícula não encontrada", http.StatusNotFound)
		return
	}

	if storageKey == "" {
		storageKey = enrollmentPDFKey(user.TenantID, id)
	}
	if ficheiroURL == "" {
		jsonErr(w, "Matrícula ainda não tem PDF gerado", http.StatusBadRequest)
		return
	}

	reader, _, err := h.storage.Get(r.Context(), storageKey)
	if err != nil {
		jsonErr(w, "PDF da matrícula não disponível", http.StatusNotFound)
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
		Titulo:          fmt.Sprintf("Matrícula escolar #%d", id),
		StorageKey:      storageKey,
		FicheiroURL:     ficheiroURL,
		HashSHA256:      hex.EncodeToString(hash[:]),
		CreatedBy:       user.ID,
		SignatarioNome:  nome,
		SignatarioEmail: email,
		OrigemModulo:    "gestao-escolar",
		OrigemID:        id,
	}

	docID, err := h.signature.CreateForSigning(r.Context(), req)
	if err != nil {
		jsonErr(w, "Erro ao criar documento de assinatura", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_enrollments SET assinatura_documento_id=$1 WHERE id=$2 AND tenant_id=$3`,
		docID, id, user.TenantID); err != nil {
		jsonErr(w, "Erro ao actualizar matrícula", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "assinatura_documento_id": docID}, http.StatusCreated)
}
