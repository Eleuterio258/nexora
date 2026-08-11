package handlers

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-pdf/fpdf"
	mw "nexora/internal/middleware"
)

type pdfEmitente struct {
	Nome   string
	Nuit   string
	Morada string
}

// dadosEmitente obtém os dados da empresa do tenant para o cabeçalho do PDF.
// Devolve campos vazios (nunca erro) se a empresa/endereço/NUIT ainda não
// estiverem configurados — o PDF é gerado na mesma, só sem esses dados.
func (h *Handler) dadosEmitente(ctx context.Context, tenantID int64) pdfEmitente {
	var e pdfEmitente
	var nomeComercial, nome, nuit *string
	h.db.QueryRow(ctx, `
		SELECT c.nome_comercial, c.nome, t.nuit
		  FROM empresas.companies c
		  LEFT JOIN empresas.company_tax_info t ON t.company_id = c.id
		 WHERE c.tenant_id=$1
		 ORDER BY c.id LIMIT 1`, tenantID).Scan(&nomeComercial, &nome, &nuit)
	if nomeComercial != nil && *nomeComercial != "" {
		e.Nome = *nomeComercial
	} else if nome != nil {
		e.Nome = *nome
	}
	if nuit != nil {
		e.Nuit = *nuit
	}

	var endereco, cidade *string
	h.db.QueryRow(ctx, `
		SELECT a.endereco, a.cidade
		  FROM empresas.company_addresses a
		  JOIN empresas.companies c ON c.id = a.company_id
		 WHERE c.tenant_id=$1
		 ORDER BY (a.tipo='principal') DESC, a.id LIMIT 1`, tenantID).Scan(&endereco, &cidade)
	if endereco != nil {
		e.Morada = *endereco
		if cidade != nil && *cidade != "" {
			e.Morada += ", " + *cidade
		}
	}
	return e
}

type pdfItem struct {
	Descricao string
	Qtd       float64
	Preco     float64
	Desconto  float64
	Imposto   float64
	Total     float64
}

type pdfCabecalho struct {
	Titulo       string // "FACTURA" / "NOTA DE CRÉDITO"
	Numero       string
	Data         time.Time
	ClienteNome  string
	ClienteNuit  string
	Moeda        string
	Subtotal     float64
	DescontoTot  float64
	ImpostoTotal float64
	Total        float64
	Observacoes  string // motivo (notas de crédito) ou observações (facturas)
}

// gerarPDFDocumentoFiscal desenha um PDF genérico de factura/nota de crédito
// — mesmo layout para os dois tipos de documento, só muda o título e se
// mostra "Motivo" (notas de crédito) em vez de "Observações".
func gerarPDFDocumentoFiscal(emitente pdfEmitente, c pdfCabecalho, itens []pdfItem) ([]byte, error) {
	pdf := fpdf.New("P", "mm", "A4", "")
	pdf.SetMargins(15, 15, 15)
	pdf.AddPage()

	pdf.SetFont("Arial", "B", 14)
	nomeEmitente := emitente.Nome
	if nomeEmitente == "" {
		nomeEmitente = "—"
	}
	pdf.Cell(0, 8, nomeEmitente)
	pdf.Ln(6)
	pdf.SetFont("Arial", "", 9)
	if emitente.Nuit != "" {
		pdf.Cell(0, 5, "NUIT: "+emitente.Nuit)
		pdf.Ln(5)
	}
	if emitente.Morada != "" {
		pdf.Cell(0, 5, emitente.Morada)
		pdf.Ln(5)
	}
	pdf.Ln(4)

	pdf.SetFont("Arial", "B", 16)
	pdf.Cell(0, 9, fmt.Sprintf("%s %s", c.Titulo, c.Numero))
	pdf.Ln(9)
	pdf.SetFont("Arial", "", 10)
	pdf.Cell(0, 6, "Data: "+c.Data.Format("2006-01-02"))
	pdf.Ln(6)
	pdf.Cell(0, 6, "Cliente: "+c.ClienteNome)
	pdf.Ln(6)
	if c.ClienteNuit != "" {
		pdf.Cell(0, 6, "NUIT do cliente: "+c.ClienteNuit)
		pdf.Ln(6)
	}
	pdf.Ln(4)

	// Tabela de itens
	pdf.SetFont("Arial", "B", 9)
	colunas := []float64{75, 20, 25, 20, 20, 20}
	titulos := []string{"Descrição", "Qtd.", "Preço unit.", "Desc. %", "Imp. %", "Total"}
	for i, t := range titulos {
		pdf.CellFormat(colunas[i], 7, t, "1", 0, "C", false, 0, "")
	}
	pdf.Ln(-1)
	pdf.SetFont("Arial", "", 9)
	for _, it := range itens {
		pdf.CellFormat(colunas[0], 6, it.Descricao, "1", 0, "L", false, 0, "")
		pdf.CellFormat(colunas[1], 6, fmt.Sprintf("%.2f", it.Qtd), "1", 0, "R", false, 0, "")
		pdf.CellFormat(colunas[2], 6, fmt.Sprintf("%.2f", it.Preco), "1", 0, "R", false, 0, "")
		pdf.CellFormat(colunas[3], 6, fmt.Sprintf("%.2f", it.Desconto), "1", 0, "R", false, 0, "")
		pdf.CellFormat(colunas[4], 6, fmt.Sprintf("%.2f", it.Imposto), "1", 0, "R", false, 0, "")
		pdf.CellFormat(colunas[5], 6, fmt.Sprintf("%.2f", it.Total), "1", 0, "R", false, 0, "")
		pdf.Ln(-1)
	}
	pdf.Ln(6)

	pdf.SetFont("Arial", "", 10)
	linhaTotal := func(rotulo string, valor float64) {
		pdf.Cell(140, 6, "")
		pdf.CellFormat(20, 6, rotulo, "", 0, "R", false, 0, "")
		pdf.CellFormat(20, 6, fmt.Sprintf("%.2f %s", valor, c.Moeda), "", 0, "R", false, 0, "")
		pdf.Ln(6)
	}
	linhaTotal("Subtotal:", c.Subtotal)
	if c.DescontoTot > 0 {
		linhaTotal("Desconto:", c.DescontoTot)
	}
	linhaTotal("Imposto:", c.ImpostoTotal)
	pdf.SetFont("Arial", "B", 11)
	linhaTotal("Total:", c.Total)

	if c.Observacoes != "" {
		pdf.Ln(4)
		pdf.SetFont("Arial", "B", 9)
		rotulo := "Observações: "
		if c.Titulo == "NOTA DE CRÉDITO" {
			rotulo = "Motivo: "
		}
		pdf.Cell(0, 5, rotulo)
		pdf.Ln(5)
		pdf.SetFont("Arial", "", 9)
		pdf.MultiCell(0, 5, c.Observacoes, "", "L", false)
	}

	pdf.Ln(8)
	pdf.SetFont("Arial", "I", 7)
	pdf.Cell(0, 4, "Documento emitido por sistema informático — Nexora ERP.")

	var buf bytes.Buffer
	if err := pdf.Output(&buf); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

// ── Facturas ─────────────────────────────────────────────────────────────

// GerarFaturaPDF gera o PDF da factura a partir dos dados já na BD e guarda-o
// no storage. POST /api/faturacao/invoices/{id}/gerar-pdf.
func (h *Handler) GerarFaturaPDF(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	idStr := chi.URLParam(r, "id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		jsonErr(w, "ID inválido", http.StatusBadRequest)
		return
	}

	var numero, status, moeda string
	var subtotal, descontoTotal, impostoTotal, total float64
	var invoiceDate time.Time
	var observacoes *string
	var clienteNome, clienteNuit string
	err = h.db.QueryRow(r.Context(), `
		SELECT f.numero, f.status, f.moeda, f.subtotal, f.desconto_total, f.imposto_total, f.total,
		       f.invoice_date, f.observacoes, c.nome, COALESCE(c.nuit,'')
		  FROM faturacao.invoices f
		  JOIN clientes.customers c ON c.id = f.customer_id
		 WHERE f.id=$1 AND f.tenant_id=$2`, id, user.TenantID).
		Scan(&numero, &status, &moeda, &subtotal, &descontoTotal, &impostoTotal, &total,
			&invoiceDate, &observacoes, &clienteNome, &clienteNuit)
	if err != nil {
		jsonErr(w, "Fatura não encontrada", http.StatusNotFound)
		return
	}
	if status == "rascunho" {
		jsonErr(w, "Só é possível gerar o PDF de uma factura emitida", http.StatusConflict)
		return
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT COALESCE(descricao,''), quantidade, preco_unitario, desconto_percent, imposto_percent, total
		  FROM faturacao.invoice_items WHERE invoice_id=$1 ORDER BY id`, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	var itens []pdfItem
	for rows.Next() {
		var it pdfItem
		if rows.Scan(&it.Descricao, &it.Qtd, &it.Preco, &it.Desconto, &it.Imposto, &it.Total) == nil {
			itens = append(itens, it)
		}
	}
	rows.Close()

	obs := ""
	if observacoes != nil {
		obs = *observacoes
	}
	bytesPDF, err := gerarPDFDocumentoFiscal(h.dadosEmitente(r.Context(), user.TenantID), pdfCabecalho{
		Titulo: "FACTURA", Numero: numero, Data: invoiceDate, ClienteNome: clienteNome, ClienteNuit: clienteNuit,
		Moeda: moeda, Subtotal: subtotal, DescontoTot: descontoTotal, ImpostoTotal: impostoTotal, Total: total,
		Observacoes: obs,
	}, itens)
	if err != nil {
		jsonErr(w, "Erro ao gerar PDF", http.StatusInternalServerError)
		return
	}

	url, err := h.storage.Put(r.Context(), invoicePDFKey(user.TenantID, id), bytesPDF, "application/pdf")
	if err != nil {
		jsonErr(w, "Erro ao guardar PDF", http.StatusInternalServerError)
		return
	}
	if _, err := h.db.Exec(r.Context(), `
		UPDATE faturacao.invoices SET pdf_storage_key=$1, ficheiro_url=$2 WHERE id=$3 AND tenant_id=$4`,
		invoicePDFKey(user.TenantID, id), url, id, user.TenantID); err != nil {
		jsonErr(w, "Erro ao actualizar fatura", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]string{"ficheiro_url": url}, http.StatusOK)
}

// ObterFaturaPDF serve o PDF já gerado da factura. GET /api/faturacao/invoices/{id}/pdf.
func (h *Handler) ObterFaturaPDF(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var ficheiroURL string
	if err := h.db.QueryRow(r.Context(),
		`SELECT COALESCE(ficheiro_url,'') FROM faturacao.invoices WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID).Scan(&ficheiroURL); err != nil || ficheiroURL == "" {
		jsonErr(w, "PDF ainda não gerado", http.StatusNotFound)
		return
	}

	idInt, _ := strconv.ParseInt(id, 10, 64)
	reader, _, err := h.storage.Get(r.Context(), invoicePDFKey(user.TenantID, idInt))
	if err != nil {
		jsonErr(w, "PDF não disponível", http.StatusNotFound)
		return
	}
	defer reader.Close()

	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="factura-%s.pdf"`, id))
	io.Copy(w, reader)
}

// ── Notas de crédito ─────────────────────────────────────────────────────

// GerarNotaCreditoPDF gera o PDF da nota de crédito. POST /api/faturacao/credit-notes/{id}/gerar-pdf.
func (h *Handler) GerarNotaCreditoPDF(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	idStr := chi.URLParam(r, "id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		jsonErr(w, "ID inválido", http.StatusBadRequest)
		return
	}

	var numero, status, moeda, motivo string
	var subtotal, impostoTotal, total float64
	var creditDate time.Time
	var clienteNome, clienteNuit string
	err = h.db.QueryRow(r.Context(), `
		SELECT n.numero, n.status, n.moeda, n.motivo, n.subtotal, n.imposto_total, n.total,
		       n.credit_date, c.nome, COALESCE(c.nuit,'')
		  FROM faturacao.credit_notes n
		  JOIN clientes.customers c ON c.id = n.customer_id
		 WHERE n.id=$1 AND n.tenant_id=$2`, id, user.TenantID).
		Scan(&numero, &status, &moeda, &motivo, &subtotal, &impostoTotal, &total,
			&creditDate, &clienteNome, &clienteNuit)
	if err != nil {
		jsonErr(w, "Nota de crédito não encontrada", http.StatusNotFound)
		return
	}
	if status == "rascunho" {
		jsonErr(w, "Só é possível gerar o PDF de uma nota de crédito emitida", http.StatusConflict)
		return
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT COALESCE(descricao,''), quantidade, preco_unitario, 0, imposto_percent, total
		  FROM faturacao.credit_note_items WHERE credit_note_id=$1 ORDER BY id`, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	var itens []pdfItem
	for rows.Next() {
		var it pdfItem
		if rows.Scan(&it.Descricao, &it.Qtd, &it.Preco, &it.Desconto, &it.Imposto, &it.Total) == nil {
			itens = append(itens, it)
		}
	}
	rows.Close()

	bytesPDF, err := gerarPDFDocumentoFiscal(h.dadosEmitente(r.Context(), user.TenantID), pdfCabecalho{
		Titulo: "NOTA DE CRÉDITO", Numero: numero, Data: creditDate, ClienteNome: clienteNome, ClienteNuit: clienteNuit,
		Moeda: moeda, Subtotal: subtotal, ImpostoTotal: impostoTotal, Total: total, Observacoes: motivo,
	}, itens)
	if err != nil {
		jsonErr(w, "Erro ao gerar PDF", http.StatusInternalServerError)
		return
	}

	url, err := h.storage.Put(r.Context(), creditNotePDFKey(user.TenantID, id), bytesPDF, "application/pdf")
	if err != nil {
		jsonErr(w, "Erro ao guardar PDF", http.StatusInternalServerError)
		return
	}
	if _, err := h.db.Exec(r.Context(), `
		UPDATE faturacao.credit_notes SET pdf_storage_key=$1, ficheiro_url=$2 WHERE id=$3 AND tenant_id=$4`,
		creditNotePDFKey(user.TenantID, id), url, id, user.TenantID); err != nil {
		jsonErr(w, "Erro ao actualizar nota de crédito", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]string{"ficheiro_url": url}, http.StatusOK)
}

// ObterNotaCreditoPDF serve o PDF já gerado da nota de crédito. GET /api/faturacao/credit-notes/{id}/pdf.
func (h *Handler) ObterNotaCreditoPDF(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var ficheiroURL string
	if err := h.db.QueryRow(r.Context(),
		`SELECT COALESCE(ficheiro_url,'') FROM faturacao.credit_notes WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID).Scan(&ficheiroURL); err != nil || ficheiroURL == "" {
		jsonErr(w, "PDF ainda não gerado", http.StatusNotFound)
		return
	}

	idInt, _ := strconv.ParseInt(id, 10, 64)
	reader, _, err := h.storage.Get(r.Context(), creditNotePDFKey(user.TenantID, idInt))
	if err != nil {
		jsonErr(w, "PDF não disponível", http.StatusNotFound)
		return
	}
	defer reader.Close()

	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="nota-credito-%s.pdf"`, id))
	io.Copy(w, reader)
}
