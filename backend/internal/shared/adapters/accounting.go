package adapters

import (
	"context"
	"fmt"
	"math"

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
// Idempotente via ON CONFLICT (tenant_id, numero) DO NOTHING. Resolve o
// período fiscal aberto do tenant a partir de e.DataEntrada.
func (a *AccountingAdapter) RecordJournalEntry(ctx context.Context, e contracts.JournalEntry) error {
	if len(e.Linhas) < 2 {
		return fmt.Errorf("lançamento contabilístico requer mínimo 2 linhas (débito e crédito)")
	}
	if e.AccountingJournalID == 0 {
		return fmt.Errorf("accounting_journal_id é obrigatório")
	}

	var totalDebito, totalCredito float64
	for _, l := range e.Linhas {
		totalDebito += l.Debito
		totalCredito += l.Credito
	}
	if math.Abs(totalDebito-totalCredito) > 0.005 {
		return fmt.Errorf("lançamento não balanceado (débito %.2f, crédito %.2f)", totalDebito, totalCredito)
	}

	moeda := e.Moeda
	if moeda == "" {
		moeda = "MZN"
	}

	tx, err := a.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	var periodoID int64
	var periodoStatus string
	err = tx.QueryRow(ctx, `
		SELECT id, status FROM contabilidade.fiscal_periods
		 WHERE tenant_id=$1 AND ano=$2 AND mes=$3`,
		e.TenantID, e.DataEntrada.Year(), int(e.DataEntrada.Month())).Scan(&periodoID, &periodoStatus)
	if err != nil {
		return fmt.Errorf("período fiscal não encontrado para %04d-%02d", e.DataEntrada.Year(), e.DataEntrada.Month())
	}
	if periodoStatus != "aberto" {
		return fmt.Errorf("período fiscal %04d-%02d não está aberto", e.DataEntrada.Year(), e.DataEntrada.Month())
	}

	var entryID int64
	err = tx.QueryRow(ctx, `
		INSERT INTO contabilidade.journal_entries
		(tenant_id, fiscal_period_id, accounting_journal_id, numero, entry_date, descricao,
		 referencia_tipo, referencia_id, status, moeda, total_debito, total_credito,
		 criado_por, publicado_por, publicado_em)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'publicado',$9,$10,$11,$12,$12,NOW())
		ON CONFLICT (tenant_id, numero) DO NOTHING
		RETURNING id`,
		e.TenantID, periodoID, e.AccountingJournalID, e.Numero, e.DataEntrada, e.Descricao,
		e.ReferenciaTipo, e.ReferenciaID, moeda, totalDebito, totalCredito, e.CreatedBy,
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
			(journal_entry_id, account_id, descricao, debit, credit)
			VALUES ($1, $2, $3, $4, $5)`,
			entryID, l.ContaID, l.Memo, l.Debito, l.Credito)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}
