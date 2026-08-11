package handlers

import (
	"context"

	"nexora/internal/shared/adapters"
)

// gerarLancamentoContabilisticoFatura posta o lançamento de reconhecimento
// de receita da factura em Contabilidade. Ver adapters.PostInvoiceJournalEntry
// para o comportamento completo (não-bloqueante, idempotente, opcional por
// tenant) — partilhado com a factura fiscal automática do POS.
func (h *Handler) gerarLancamentoContabilisticoFatura(ctx context.Context, tenantID, userID, invoiceID int64) {
	adapters.PostInvoiceJournalEntry(ctx, h.db, h.accounting, tenantID, userID, invoiceID)
}

// gerarLancamentoEstornoNotaCredito posta o lançamento de estorno da nota de
// crédito em Contabilidade. Ver adapters.PostCreditNoteJournalEntry —
// partilhado com o estorno de vendas do POS.
func (h *Handler) gerarLancamentoEstornoNotaCredito(ctx context.Context, tenantID, userID, creditNoteID int64) {
	adapters.PostCreditNoteJournalEntry(ctx, h.db, h.accounting, tenantID, userID, creditNoteID)
}
