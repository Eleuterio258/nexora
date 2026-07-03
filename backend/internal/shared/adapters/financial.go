package adapters

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/internal/shared/contracts"
)

// FinancialAdapter implementa contracts.FinancialPort escrevendo nas tabelas
// financeiro.accounts_receivable e financeiro.payments.
type FinancialAdapter struct {
	db *pgxpool.Pool
}

// NewFinancialAdapter cria um novo adaptador do módulo Financeiro.
func NewFinancialAdapter(db *pgxpool.Pool) *FinancialAdapter {
	return &FinancialAdapter{db: db}
}

// RecordReceivable cria conta a receber + pagamento numa transacção atómica.
// Idempotente via ON CONFLICT DO NOTHING em ambas as inserções.
func (a *FinancialAdapter) RecordReceivable(ctx context.Context, p contracts.FinancialReceivable) error {
	tx, err := a.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// 1. Conta a receber
	var arID int64
	err = tx.QueryRow(ctx, `
		INSERT INTO financeiro.accounts_receivable
		(tenant_id, numero, origem_tipo, origem_id, descricao,
		 valor_total, data_emissao, data_vencimento, status)
		VALUES ($1, $2, $3, $4, $5, $6, CURRENT_DATE, $7, 'pendente')
		ON CONFLICT (tenant_id, numero) DO UPDATE
		  SET descricao = EXCLUDED.descricao
		RETURNING id`,
		p.TenantID, p.Numero, p.OrigemTipo, p.OrigemID,
		p.Descricao, p.Valor, p.DataVencimento,
	).Scan(&arID)
	if err != nil {
		return err
	}

	// 2. Pagamento — número gerado localmente para não depender da sequência interna
	//    do módulo Financeiro (financeiro.payments_id_seq).
	pagoNumero := fmt.Sprintf("PAG-%s-%05d-%08d", p.OrigemTipo, p.TenantID, arID)
	_, err = tx.Exec(ctx, `
		INSERT INTO financeiro.payments
		(tenant_id, numero, tipo, data_pagamento, valor,
		 referencia_tipo, referencia_id, criado_por)
		VALUES ($1, $2, 'recebimento', CURRENT_DATE, $3, $4, $5, $6)
		ON CONFLICT (tenant_id, numero) DO NOTHING`,
		p.TenantID, pagoNumero, p.Valor,
		p.OrigemTipo, arID, p.CreatedBy,
	)
	if err != nil {
		return err
	}

	// 3. Actualizar saldo da conta a receber
	_, err = tx.Exec(ctx, `
		UPDATE financeiro.accounts_receivable
		SET valor_pago     = valor_total,
		    valor_pendente = 0,
		    status         = 'pago'
		WHERE id = $1 AND tenant_id = $2`, arID, p.TenantID)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}
