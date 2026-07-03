package adapters

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/internal/shared/contracts"
)

// InvoicingAdapter implementa contracts.InvoicingPort usando o módulo Faturação.
// Emite recibos (tipo RB) para pagamentos de propinas escolares.
type InvoicingAdapter struct {
	db *pgxpool.Pool
}

// NewInvoicingAdapter cria um novo adaptador de Faturação.
func NewInvoicingAdapter(db *pgxpool.Pool) *InvoicingAdapter {
	return &InvoicingAdapter{db: db}
}

// CreateReceipt emite um recibo (tipo RB) no módulo Faturação.
// Garante a série RB e o número único; idempotente via ON CONFLICT.
func (a *InvoicingAdapter) CreateReceipt(ctx context.Context, r contracts.SchoolReceipt) (int64, error) {
	tx, err := a.db.Begin(ctx)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback(ctx)

	// 1. Garantir que existe série RB para este tenant no ano corrente
	ano := r.DataEmissao.Year()
	var serieID int64
	err = tx.QueryRow(ctx, `
		INSERT INTO faturacao.invoice_series (tenant_id, tipo, prefixo, ano, sequencia)
		VALUES ($1, 'RB', 'RB', $2, 0)
		ON CONFLICT (tenant_id, tipo, ano) DO UPDATE SET tipo = EXCLUDED.tipo
		RETURNING id`,
		r.TenantID, ano,
	).Scan(&serieID)
	if err != nil {
		return 0, fmt.Errorf("erro ao garantir série RB: %w", err)
	}

	moeda := r.Moeda
	if moeda == "" {
		moeda = "MZN"
	}

	// 2. Criar recibo (invoice tipo RB) — idempotente via número único
	var invoiceID int64
	err = tx.QueryRow(ctx, `
		INSERT INTO faturacao.invoices
		(tenant_id, serie_id, customer_id, numero, invoice_date,
		 moeda, subtotal, desconto_total, imposto_total, total,
		 status, observacoes, criado_por)
		VALUES ($1, $2, $3, $4, $5, $6, $7, 0, 0, $7, 'emitida', $8, $9)
		ON CONFLICT (tenant_id, numero) DO NOTHING
		RETURNING id`,
		r.TenantID, serieID, r.CustomerID, r.Numero, r.DataEmissao,
		moeda, r.Valor, r.Descricao, r.CreatedBy,
	).Scan(&invoiceID)
	if err != nil {
		return 0, fmt.Errorf("erro ao criar recibo: %w", err)
	}
	if invoiceID == 0 {
		// já existia — obter o ID existente
		_ = tx.QueryRow(ctx, `
			SELECT id FROM faturacao.invoices WHERE tenant_id=$1 AND numero=$2`,
			r.TenantID, r.Numero).Scan(&invoiceID)
		return invoiceID, tx.Commit(ctx)
	}

	// 3. Linha do recibo
	_, err = tx.Exec(ctx, `
		INSERT INTO faturacao.invoice_items
		(invoice_id, descricao, quantidade, preco_unitario,
		 desconto_percent, desconto_valor, imposto_percent, imposto_valor,
		 subtotal, total)
		VALUES ($1, $2, 1, $3, 0, 0, 0, 0, $3, $3)`,
		invoiceID, r.Descricao, r.Valor)
	if err != nil {
		return 0, fmt.Errorf("erro ao criar linha do recibo: %w", err)
	}

	return invoiceID, tx.Commit(ctx)
}
