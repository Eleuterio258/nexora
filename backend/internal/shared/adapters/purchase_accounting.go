package adapters

import (
	"context"
	"fmt"
	"log"
	"time"

	"nexora/internal/shared/contracts"
)

type comprasConfigContabil struct {
	AccountingJournalID int64
	ContaFornecedoresID int64
	ContaDespesaID      int64
	ContaIVAID          *int64
}

func configContabilidadeCompras(ctx context.Context, db InvoiceAccountingDB, tenantID int64) (*comprasConfigContabil, error) {
	var cfg comprasConfigContabil
	var contaIVA *int64
	err := db.QueryRow(ctx, `
		SELECT accounting_journal_id, conta_fornecedores_id, conta_despesa_id, conta_iva_id
		  FROM compras.config_contabilidade
		 WHERE tenant_id=$1 AND ativo=TRUE`, tenantID).Scan(
		&cfg.AccountingJournalID, &cfg.ContaFornecedoresID, &cfg.ContaDespesaID, &contaIVA)
	if err != nil {
		return nil, err
	}
	cfg.ContaIVAID = contaIVA
	return &cfg, nil
}

// PostPurchaseInvoiceJournalEntry gera o lançamento de reconhecimento de
// despesa (débito Despesa + IVA a recuperar, crédito Fornecedores) para uma
// factura de fornecedor. Chamado depois de AdicionarItemFacturaCompra ter
// comitado — é essa chamada que transiciona compras.purchase_invoices de
// 'rascunho' para 'emitida' pela primeira vez.
//
// Idempotente por invoiceID (via purchase_invoices.journal_entry_id): só
// posta uma vez, reflectindo o total no momento em que a factura saiu de
// rascunho. Se itens forem adicionados numa factura já emitida, o total é
// recalculado na tabela mas o lançamento já postado NÃO é actualizado —
// limitação conhecida, documentada em lacunasde10082026.md item 5, aceitável
// porque facturas de fornecedor tipicamente chegam com a lista de itens já
// fechada. Não-bloqueante: falhas ficam só em log.
func PostPurchaseInvoiceJournalEntry(ctx context.Context, db InvoiceAccountingDB, accounting contracts.AccountingPort, tenantID, userID, purchaseInvoiceID int64) {
	if accounting == nil {
		return
	}
	cfg, err := configContabilidadeCompras(ctx, db, tenantID)
	if err != nil {
		return // tenant sem integração contabilística configurada — normal
	}

	var numero string
	var subtotal, descontoTotal, impostoTotal, total float64
	var dataEntrada time.Time
	var jaTemLancamento *int64
	err = db.QueryRow(ctx, `
		SELECT numero, subtotal, desconto_total, imposto_total, total, invoice_date, journal_entry_id
		  FROM compras.purchase_invoices WHERE id=$1 AND tenant_id=$2`, purchaseInvoiceID, tenantID).
		Scan(&numero, &subtotal, &descontoTotal, &impostoTotal, &total, &dataEntrada, &jaTemLancamento)
	if err != nil {
		log.Printf("[WARN] PostPurchaseInvoiceJournalEntry: factura de compra %d não encontrada: %v", purchaseInvoiceID, err)
		return
	}
	if jaTemLancamento != nil || total <= 0 {
		return
	}

	despesaLiquida := subtotal - descontoTotal
	linhas := []contracts.JournalLine{
		{ContaID: cfg.ContaFornecedoresID, Debito: 0, Credito: total, Memo: "Factura de compra " + numero},
	}
	if cfg.ContaIVAID != nil && impostoTotal > 0 {
		linhas = append(linhas,
			contracts.JournalLine{ContaID: cfg.ContaDespesaID, Debito: despesaLiquida, Credito: 0, Memo: "Factura de compra " + numero},
			contracts.JournalLine{ContaID: *cfg.ContaIVAID, Debito: impostoTotal, Credito: 0, Memo: "IVA a recuperar factura " + numero},
		)
	} else {
		linhas = append(linhas,
			contracts.JournalLine{ContaID: cfg.ContaDespesaID, Debito: despesaLiquida + impostoTotal, Credito: 0, Memo: "Factura de compra " + numero},
		)
	}

	entryID, err := recordAndFetchEntry(ctx, db, accounting, tenantID, userID, cfg.AccountingJournalID,
		fmt.Sprintf("CC-JE-%s", numero), fmt.Sprintf("Factura de compra %s", numero), "purchase_invoice", purchaseInvoiceID, dataEntrada, linhas)
	if err != nil {
		log.Printf("[WARN] PostPurchaseInvoiceJournalEntry: falhou (factura %d): %v", purchaseInvoiceID, err)
		return
	}
	if _, err := db.Exec(ctx, `UPDATE compras.purchase_invoices SET journal_entry_id=$1 WHERE id=$2 AND tenant_id=$3`, entryID, purchaseInvoiceID, tenantID); err != nil {
		log.Printf("[WARN] PostPurchaseInvoiceJournalEntry: não foi possível gravar journal_entry_id (factura %d): %v", purchaseInvoiceID, err)
	}
}
