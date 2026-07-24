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

// purchaseOrderPDFKey gera a chave de storage esperada para o PDF de uma ordem de compra.
func purchaseOrderPDFKey(tenantID, orderID int64) string {
	return fmt.Sprintf("compras/purchase-orders/tenant-%d/%d.pdf", tenantID, orderID)
}

// EnviarOrdemCompraParaAssinatura cria um documento no módulo assinatura-digital
// a partir do PDF de uma ordem de compra. Associa o fornecedor como signatário.
// POST /api/compras/purchase-orders/{id}/enviar-para-assinatura
func (h *Handler) EnviarOrdemCompraParaAssinatura(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id, _ := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)

	var storageKey, ficheiroURL, fornecedorNome, fornecedorEmail string
	if err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(po.pdf_storage_key,''), COALESCE(po.ficheiro_url,''), COALESCE(s.nome,''), COALESCE(s.email,'')
		FROM compras.purchase_orders po
		JOIN compras.suppliers s ON s.id = po.supplier_id
		WHERE po.id=$1 AND po.tenant_id=$2`, id, user.TenantID).Scan(&storageKey, &ficheiroURL, &fornecedorNome, &fornecedorEmail); err != nil {
		jsonErr(w, "Ordem de compra não encontrada", http.StatusNotFound)
		return
	}

	if storageKey == "" {
		storageKey = purchaseOrderPDFKey(user.TenantID, id)
	}
	if ficheiroURL == "" {
		jsonErr(w, "Ordem de compra ainda não tem PDF gerado", http.StatusBadRequest)
		return
	}

	reader, _, err := h.storage.Get(r.Context(), storageKey)
	if err != nil {
		jsonErr(w, "PDF da ordem de compra não disponível", http.StatusNotFound)
		return
	}
	data, err := io.ReadAll(reader)
	reader.Close()
	if err != nil {
		jsonErr(w, "Erro ao ler PDF da ordem de compra", http.StatusInternalServerError)
		return
	}

	hash := sha256.Sum256(data)

	req := contracts.SignatureDocumentRequest{
		TenantID:        user.TenantID,
		Titulo:          fmt.Sprintf("Ordem de compra — %s", fornecedorNome),
		StorageKey:      storageKey,
		FicheiroURL:     ficheiroURL,
		HashSHA256:      hex.EncodeToString(hash[:]),
		CreatedBy:       user.ID,
		SignatarioNome:  fornecedorNome,
		SignatarioEmail: fornecedorEmail,
		OrigemModulo:    "compras",
		OrigemID:        id,
	}

	docID, err := h.signature.CreateForSigning(r.Context(), req)
	if err != nil {
		jsonErr(w, "Erro ao criar documento de assinatura", http.StatusInternalServerError)
		return
	}

	if _, err := h.db.Exec(r.Context(), `
		UPDATE compras.purchase_orders SET assinatura_documento_id=$1 WHERE id=$2 AND tenant_id=$3`,
		docID, id, user.TenantID); err != nil {
		jsonErr(w, "Erro ao actualizar ordem de compra", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true, "assinatura_documento_id": docID}, http.StatusCreated)
}
