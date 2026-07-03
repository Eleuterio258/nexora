package adapters

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/internal/shared/contracts"
)

// AccountingAdapter implementa contracts.AccountingPort escrevendo em
// contabilidade.journal_entries e contabilidade.journal_entry_lines.
type AccountingAdapter struct {
	db *pgxpool.Pool
}

// NewAccountingAdapter cria um novo adaptador de Contabilidade.
func NewAccountingAdapter(db *pgxpool.Pool) *AccountingAdapter {
	return &AccountingAdapter{db: db}
}

// RecordJournalEntry cria um lançamento contabilístico completo numa transacção.
// Idempotente via ON CONFLICT (tenant_id, numero) DO NOTHING.
func (a *AccountingAdapter) RecordJournalEntry(ctx context.Context, e contracts.JournalEntry) error {
	if len(e.Linhas) < 2 {
		return fmt.Errorf("lançamento contabilístico requer mínimo 2 linhas (débito e crédito)")
	}

	tx, err := a.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	var entryID int64
	err = tx.QueryRow(ctx, `
		INSERT INTO contabilidade.journal_entries
		(tenant_id, numero, descricao, referencia, entry_date, criado_por)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (tenant_id, numero) DO NOTHING
		RETURNING id`,
		e.TenantID, e.Numero, e.Descricao, e.Referencia, e.DataEntrada, e.CreatedBy,
	).Scan(&entryID)
	if err != nil {
		return err
	}
	if entryID == 0 {
		return nil // já existia — idempotente
	}

	for _, l := range e.Linhas {
		_, err = tx.Exec(ctx, `
			INSERT INTO contabilidade.journal_entry_lines
			(journal_entry_id, chart_account_id, debito, credito, memo)
			VALUES ($1, $2, $3, $4, $5)`,
			entryID, l.ContaID, l.Debito, l.Credito, l.Memo)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}
