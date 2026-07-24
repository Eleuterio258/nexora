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

// invoicePDFKey gera a chave de storage esperada para o PDF de uma fatura.
func invoicePDFKey(tenantID, invoiceID int64) string {
	return fmt.Sprintf("faturacao/invoices/tenant-%d/%d.pdf", tenantID, invoiceID)
}

// creditNotePDFKey gera a chave de storage esperada para o PDF de uma nota de crédito.
func creditNotePDFKey(tenantID, creditNoteID int64) string {
	return fmt.Sprintf("faturacao/credit-notes/tenant-%d/%d.pdf", tenantID, creditNoteID)
}

// EnviarFaturaParaAssinatura cria um documento no módulo assinatura-digital a
// partir do PDF já existente de uma fatura (invoice). Associa o cliente como
// signatário. O documento fica em 'rascunho' — o módulo assinatura-digital é
// usado depois para o enviar.
// POST /api/faturacao/invoices/{id}/enviar-para-assinatura
func (h *Handler) EnviarFaturaParaAssinatura(w http.ResponseWriter, r *http.Request) {
	h.enviarDocumentoFiscalParaAssinatura(w, r, "invoice")
}

// EnviarNotaCreditoParaAssinatura cria um documento no módulo assinatura-digital
// a partir do PDF já existente de uma nota de crédito.
// POST /api/faturacao/credit-notes/{id}/enviar-para-assinatura
func (h *Handler) EnviarNotaCreditoParaAssinatura(w http.ResponseWriter, r *http.Request) {
	h.enviarDocumentoFiscalParaAssinatura(w, r, "credit_note")
}

func (h *Handler) enviarDocumentoFiscalParaAssinatura(w http.ResponseWriter, r *http.Request, tipo string) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	idInt, _ := strconv.ParseInt(id, 10, 64)

	var tabela string
	var keyFn func(tenantID, docID int64) string
	var tituloPrefixo string
	if tipo == "invoice" {
		tabela = "invoices"
		keyFn = invoicePDFKey
		tituloPrefixo = "Fatura"
	} else {
		tabela = "credit_notes"
		keyFn = creditNotePDFKey
		tituloPrefixo = "Nota de crédito"
	}

	var storageKey, ficheiroURL, clienteNome, clienteEmail string
	if err := h.db.QueryRow(r.Context(), fmt.Sprintf(`
		SELECT COALESCE(f.pdf_storage_key,''), COALESCE(f.ficheiro_url,''), COALESCE(c.nome,''), COALESCE(c.email,'')
		FROM faturacao.%s f
		JOIN clientes.customers c ON c.id = f.customer_id
		WHERE f.id=$1 AND f.tenant_id=$2`, tabela),
		idInt, user.TenantID).Scan(&storageKey, &ficheiroURL, &clienteNome, &clienteEmail); err != nil {
		jsonErr(w, "Documento fiscal não encontrado", http.StatusNotFound)
		return
	}

	if storageKey == "" {
		storageKey = keyFn(user.TenantID, idInt)
	}
	if ficheiroURL == "" {
		jsonErr(w, "Documento fiscal ainda não tem PDF gerado", http.StatusBadRequest)
		return
	}

	reader, _, err := h.storage.Get(r.Context(), storageKey)
	if err != nil {
		jsonErr(w, "PDF do documento fiscal não disponível", http.StatusNotFound)
		return
	}
	data, err := io.ReadAll(reader)
	reader.Close()
	if err != nil {
		jsonErr(w, "Erro ao ler PDF do documento fiscal", http.StatusInternalServerError)
		return
	}

	hash := sha256.Sum256(data)

	req := contracts.SignatureDocumentRequest{
		TenantID:        user.TenantID,
		Titulo:          fmt.Sprintf("%s — %s", tituloPrefixo, clienteNome),
		StorageKey:      storageKey,
		FicheiroURL:     ficheiroURL,
		HashSHA256:      hex.EncodeToString(hash[:]),
		CreatedBy:       user.ID,
		SignatarioNome:  clienteNome,
		SignatarioEmail: clienteEmail,
		OrigemModulo:    "faturacao",
		OrigemID:        idInt,
	}

	docID, err := h.signature.CreateForSigning(r.Context(), req)
	if err != nil {
		jsonErr(w, "Erro ao criar documento de assinatura", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(), fmt.Sprintf(`
		UPDATE faturacao.%s SET assinatura_documento_id=$1 WHERE id=$2 AND tenant_id=$3`, tabela),
		docID, idInt, user.TenantID); err != nil {
		jsonErr(w, "Erro ao actualizar documento fiscal", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "assinatura_documento_id": docID}, http.StatusCreated)
}
