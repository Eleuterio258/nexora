package adapters

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/internal/shared/contracts"
)

// TreasuryAdapter implementa contracts.TreasuryPort escrevendo directamente
// na tabela tesouraria.movements.
type TreasuryAdapter struct {
	db *pgxpool.Pool
}

// NewTreasuryAdapter cria um novo adaptador de Tesouraria.
func NewTreasuryAdapter(db *pgxpool.Pool) *TreasuryAdapter {
	return &TreasuryAdapter{db: db}
}

// RecordReceipt insere um movimento de recebimento em tesouraria.movements.
func (a *TreasuryAdapter) RecordReceipt(ctx context.Context, p contracts.TreasuryReceipt) error {
	moeda := p.Moeda
	if moeda == "" {
		moeda = "MZN"
	}
	origem := p.OrigemTipo
	if origem == "" {
		origem = "ajuste"
	}
	_, err := a.db.Exec(ctx, `
		INSERT INTO tesouraria.movements
		(tenant_id, reference_type, reference_id, bank_account_id,
		 tipo, valor, moeda, referencia, descricao, data_movimento)
		VALUES ($1, $2, $3, $4, 'recebimento', $5, $6, $7, $8, $9)`,
		p.TenantID, origem, p.OrigemID, p.ContaBancariaID,
		p.Valor, moeda, p.Referencia, p.Descricao, p.DataMovimento)
	return err
}
