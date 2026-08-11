package handlers

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/shared/contracts"
)

// EnviarFaturaEmail envia a factura (PDF já gerado) por e-mail ao cliente.
// POST /api/faturacao/invoices/{id}/enviar-email.
func (h *Handler) EnviarFaturaEmail(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	idStr := chi.URLParam(r, "id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		jsonErr(w, "ID inválido", http.StatusBadRequest)
		return
	}
	if h.notification == nil {
		jsonErr(w, "Envio de e-mail não está configurado", http.StatusServiceUnavailable)
		return
	}

	var numero, ficheiroURL, clienteNome, clienteEmail string
	err = h.db.QueryRow(r.Context(), `
		SELECT f.numero, COALESCE(f.ficheiro_url,''), c.nome, COALESCE(c.email,'')
		  FROM faturacao.invoices f
		  JOIN clientes.customers c ON c.id = f.customer_id
		 WHERE f.id=$1 AND f.tenant_id=$2`, id, user.TenantID).
		Scan(&numero, &ficheiroURL, &clienteNome, &clienteEmail)
	if err != nil {
		jsonErr(w, "Fatura não encontrada", http.StatusNotFound)
		return
	}
	if ficheiroURL == "" {
		jsonErr(w, "Gere o PDF da factura antes de a enviar por e-mail", http.StatusConflict)
		return
	}
	if clienteEmail == "" {
		jsonErr(w, "Cliente não tem e-mail configurado", http.StatusConflict)
		return
	}

	refID := id
	h.notification.Send(r.Context(), contracts.Notification{
		TenantID:        user.TenantID,
		CanalTipo:       "email",
		Destinatario:    clienteEmail,
		Assunto:         fmt.Sprintf("Factura %s", numero),
		Corpo:           fmt.Sprintf("Caro(a) %s,\n\nSegue em anexo a factura %s.\n\nCumprimentos.", clienteNome, numero),
		ReferenciaTipo:  "fatura",
		ReferenciaID:    &refID,
		AnexoStorageKey: invoicePDFKey(user.TenantID, id),
		AnexoNome:       fmt.Sprintf("factura-%s.pdf", numero),
	})

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// EnviarNotaCreditoEmail envia a nota de crédito (PDF já gerado) por e-mail
// ao cliente. POST /api/faturacao/credit-notes/{id}/enviar-email.
func (h *Handler) EnviarNotaCreditoEmail(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	idStr := chi.URLParam(r, "id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		jsonErr(w, "ID inválido", http.StatusBadRequest)
		return
	}
	if h.notification == nil {
		jsonErr(w, "Envio de e-mail não está configurado", http.StatusServiceUnavailable)
		return
	}

	var numero, ficheiroURL, clienteNome, clienteEmail string
	err = h.db.QueryRow(r.Context(), `
		SELECT n.numero, COALESCE(n.ficheiro_url,''), c.nome, COALESCE(c.email,'')
		  FROM faturacao.credit_notes n
		  JOIN clientes.customers c ON c.id = n.customer_id
		 WHERE n.id=$1 AND n.tenant_id=$2`, id, user.TenantID).
		Scan(&numero, &ficheiroURL, &clienteNome, &clienteEmail)
	if err != nil {
		jsonErr(w, "Nota de crédito não encontrada", http.StatusNotFound)
		return
	}
	if ficheiroURL == "" {
		jsonErr(w, "Gere o PDF da nota de crédito antes de a enviar por e-mail", http.StatusConflict)
		return
	}
	if clienteEmail == "" {
		jsonErr(w, "Cliente não tem e-mail configurado", http.StatusConflict)
		return
	}

	refID := id
	h.notification.Send(r.Context(), contracts.Notification{
		TenantID:        user.TenantID,
		CanalTipo:       "email",
		Destinatario:    clienteEmail,
		Assunto:         fmt.Sprintf("Nota de crédito %s", numero),
		Corpo:           fmt.Sprintf("Caro(a) %s,\n\nSegue em anexo a nota de crédito %s.\n\nCumprimentos.", clienteNome, numero),
		ReferenciaTipo:  "nota_credito",
		ReferenciaID:    &refID,
		AnexoStorageKey: creditNotePDFKey(user.TenantID, id),
		AnexoNome:       fmt.Sprintf("nota-credito-%s.pdf", numero),
	})

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}
