package repositories

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
)

// FeeRepository acesso a dados de propinas/cobranças.
type FeeRepository struct {
	db DB
}

// NewFeeRepository cria repositório.
func NewFeeRepository(db DB) *FeeRepository {
	return &FeeRepository{db: db}
}

// GetFeePlanByID obtém plano.
func (r *FeeRepository) GetFeePlanByID(ctx context.Context, id, tenantID int64) (*models.FeePlan, error) {
	var fp models.FeePlan
	err := r.db.QueryRow(ctx, `
		SELECT id, tenant_id, school_year_id, codigo, nome, tipo, valor, moeda, periodicidade, dia_vencimento, classe_nivel, activo, created_at, updated_at
		FROM gestao_escolar.school_fee_plans
		WHERE id=$1 AND tenant_id=$2`, id, tenantID).Scan(
		&fp.ID, &fp.TenantID, &fp.SchoolYearID, &fp.Codigo, &fp.Nome, &fp.Tipo, &fp.Valor, &fp.Moeda,
		&fp.Periodicidade, &fp.DiaVencimento, &fp.ClasseNivel, &fp.Activo, &fp.CreatedAt, &fp.UpdatedAt)
	return &fp, err
}

// CountGeneratedInPeriod conta cobranças já geradas para o plano/período.
func (r *FeeRepository) CountGeneratedInPeriod(ctx context.Context, feePlanID int64, periodo string) (int, error) {
	var count int
	err := r.db.QueryRow(ctx, `
		SELECT COUNT(*) FROM gestao_escolar.school_fee_generations
		WHERE fee_plan_id=$1 AND periodo_referencia=$2`, feePlanID, periodo).Scan(&count)
	return count, err
}

// RecordGeneration regista geração de cobranças.
func (r *FeeRepository) RecordGeneration(ctx context.Context, tenantID, feePlanID, schoolYearID int64, periodo string, totalCobrancas int, valorTotal float64, createdBy *int64) error {
	_, err := r.db.Exec(ctx, `
		INSERT INTO gestao_escolar.school_fee_generations
		(tenant_id, fee_plan_id, school_year_id, periodo_referencia, total_cobrancas, valor_total, gerado_por)
		VALUES ($1,$2,$3,$4,$5,$6,$7)
		ON CONFLICT(tenant_id, fee_plan_id, periodo_referencia) DO UPDATE SET
		 total_cobrancas=EXCLUDED.total_cobrancas, valor_total=EXCLUDED.valor_total, data_geracao=NOW()`,
		tenantID, feePlanID, schoolYearID, periodo, totalCobrancas, valorTotal, createdBy)
	return err
}

// CreateFeesBatch cria múltiplas cobranças em batch.
func (r *FeeRepository) CreateFeesBatch(ctx context.Context, fees []models.SchoolFee) error {
	if len(fees) == 0 {
		return nil
	}
	batch := &pgx.Batch{}
	for _, f := range fees {
		batch.Queue(`
			INSERT INTO gestao_escolar.school_fees
			(tenant_id, enrollment_id, fee_plan_id, student_id, numero, descricao, mes_referencia, data_vencimento, valor_total, moeda, status)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'pendente')
			ON CONFLICT(tenant_id, numero) DO NOTHING`,
			f.TenantID, f.EnrollmentID, f.FeePlanID, f.StudentID, f.Numero, f.Descricao, f.MesReferencia, f.DataVencimento, f.ValorTotal, f.Moeda)
	}
	br := r.db.SendBatch(ctx, batch)
	return br.Close()
}

// ListActiveEnrollmentsForYear lista matrículas activas de um ano.
func (r *FeeRepository) ListActiveEnrollmentsForYear(ctx context.Context, tenantID, schoolYearID int64) ([]struct {
	ID        int64
	StudentID int64
	ClassID   int64
}, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, student_id, class_id FROM gestao_escolar.school_enrollments
		WHERE tenant_id=$1 AND school_year_id=$2 AND status='activa'`, tenantID, schoolYearID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var enrollments []struct {
		ID        int64
		StudentID int64
		ClassID   int64
	}
	for rows.Next() {
		var e struct {
			ID        int64
			StudentID int64
			ClassID   int64
		}
		if err := rows.Scan(&e.ID, &e.StudentID, &e.ClassID); err != nil {
			return nil, err
		}
		enrollments = append(enrollments, e)
	}
	return enrollments, rows.Err()
}

// GetFeeByID obtém cobrança.
func (r *FeeRepository) GetFeeByID(ctx context.Context, id, tenantID int64) (*models.SchoolFee, error) {
	var f models.SchoolFee
	err := r.db.QueryRow(ctx, `
		SELECT id, tenant_id, enrollment_id, fee_plan_id, student_id, numero, descricao, mes_referencia, data_vencimento,
		 valor_total, valor_pago, desconto, desconto_motivo, moeda, status, entidade, referencia, emitida_em, created_at, updated_at
		FROM gestao_escolar.school_fees
		WHERE id=$1 AND tenant_id=$2`, id, tenantID).Scan(
		&f.ID, &f.TenantID, &f.EnrollmentID, &f.FeePlanID, &f.StudentID, &f.Numero, &f.Descricao, &f.MesReferencia,
		&f.DataVencimento, &f.ValorTotal, &f.ValorPago, &f.Desconto, &f.DescontoMotivo, &f.Moeda, &f.Status,
		&f.Entidade, &f.Referencia, &f.EmitidaEm, &f.CreatedAt, &f.UpdatedAt)
	return &f, err
}

// ApplyDiscount aplica desconto e actualiza status se necessário.
func (r *FeeRepository) ApplyDiscount(ctx context.Context, id, tenantID int64, desconto float64, motivo string) error {
	_, err := r.db.Exec(ctx, `
		UPDATE gestao_escolar.school_fees
		SET desconto=$1, desconto_motivo=$2, valor_pago=LEAST(valor_pago + $1, valor_total),
		 status=CASE WHEN (valor_total - (valor_pago + $1)) <= 0 THEN 'paga' ELSE status END,
		 updated_at=NOW()
		WHERE id=$3 AND tenant_id=$4`, desconto, motivo, id, tenantID)
	return err
}

// CreatePayment regista pagamento e actualiza cobrança.
func (r *FeeRepository) CreatePayment(ctx context.Context, p *models.SchoolPayment) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// Inserir pagamento
	err = tx.QueryRow(ctx, `
		INSERT INTO gestao_escolar.school_payments
		(tenant_id, school_fee_id, student_id, external_id, metodo, referencia, valor, moeda, status, pago_em, payload_gateway, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
		RETURNING id, created_at`,
		p.TenantID, p.SchoolFeeID, p.StudentID, p.ExternalID, p.Metodo, p.Referencia, p.Valor, p.Moeda, p.Status, p.PagoEm, p.PayloadGateway, p.CreatedBy,
	).Scan(&p.ID, &p.CreatedAt)
	if err != nil {
		return err
	}

	// Actualizar cobrança
	_, err = tx.Exec(ctx, `
		UPDATE gestao_escolar.school_fees
		SET valor_pago=valor_pago+$1,
		 status=CASE
		  WHEN (valor_total - desconto) <= (valor_pago+$1) THEN 'paga'
		  WHEN (valor_pago+$1) > 0 THEN 'parcial'
		  ELSE status
		 END,
		 updated_at=NOW()
		WHERE id=$2 AND tenant_id=$3`, p.Valor, p.SchoolFeeID, p.TenantID)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

// CreateTreasuryMovement mantido por compatibilidade — prefer usar TreasuryPort.
// Delega ao adaptador via fee service; este método pode ser removido quando
// todos os callers migrarem para o port.
func (r *FeeRepository) CreateTreasuryMovement(ctx context.Context, tenantID int64, contaBancariaID *int64, valor float64, descricao, referencia string, dataMovimento time.Time) error {
	_, err := r.db.Exec(ctx, `
		INSERT INTO tesouraria.movements
		(tenant_id, reference_type, reference_id, bank_account_id, tipo, valor, moeda, referencia, descricao, data_movimento)
		VALUES ($1,'escolar',NULL,$2,'recebimento',$3,'MZN',$4,$5,$6)`,
		tenantID, contaBancariaID, valor, referencia, descricao, dataMovimento)
	return err
}

// FinancialConfig configuração financeira do módulo escolar por tenant.
type FinancialConfig struct {
	ContaBancariaID             *int64
	CentroCustoID               *int64
	CriarMovimentoTesouraria    bool
	CriarMovimentoFinanceiro    bool
	CriarLancamentoContabilidade bool
	ContaDebitoID               *int64 // conta bancária/caixa para débito no journal
	ContaCreditoID              *int64 // conta de receita para crédito no journal
	CriarReciboFaturacao        bool
	CustomerGroupID             *int64 // grupo de clientes para encarregados
}

// GetFinancialConfig obtém configuração financeira escolar.
func (r *FeeRepository) GetFinancialConfig(ctx context.Context, tenantID int64) (*FinancialConfig, error) {
	var cfg FinancialConfig
	err := r.db.QueryRow(ctx, `
		SELECT conta_bancaria_id, centro_custo_id,
		       criar_movimento_tesouraria, criar_movimento_financeiro,
		       COALESCE(criar_lancamento_contabilidade, FALSE),
		       conta_debito_id, conta_credito_id,
		       COALESCE(criar_recibo_faturacao, FALSE),
		       customer_group_id
		FROM gestao_escolar.school_financial_config
		WHERE tenant_id=$1`, tenantID).Scan(
		&cfg.ContaBancariaID, &cfg.CentroCustoID,
		&cfg.CriarMovimentoTesouraria, &cfg.CriarMovimentoFinanceiro,
		&cfg.CriarLancamentoContabilidade,
		&cfg.ContaDebitoID, &cfg.ContaCreditoID,
		&cfg.CriarReciboFaturacao,
		&cfg.CustomerGroupID)
	if err == pgx.ErrNoRows {
		return nil, nil
	}
	return &cfg, err
}

// CreateFinancialReceivable cria conta a receber e regista o pagamento no módulo Financeiro.
// Chamado apenas quando school_financial_config.criar_movimento_financeiro=true.
func (r *FeeRepository) CreateFinancialReceivable(ctx context.Context, tenantID, schoolFeeID int64, descricao string, valor float64, dataVencimento time.Time, createdBy *int64) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// 1. Criar conta a receber com origem_tipo='escolar'
	var arID int64
	err = tx.QueryRow(ctx, `
		INSERT INTO financeiro.accounts_receivable
		(tenant_id, numero, origem_tipo, origem_id, descricao, valor_total,
		 data_emissao, data_vencimento, status)
		VALUES ($1, 'ESC-'||$2, 'escolar', $2, $3, $4, CURRENT_DATE, $5, 'pendente')
		ON CONFLICT DO NOTHING
		RETURNING id`,
		tenantID, schoolFeeID, descricao, valor, dataVencimento,
	).Scan(&arID)
	if err != nil {
		return err
	}

	// 2. Registar pagamento imediato (a propina foi paga no módulo escolar).
	// O número é gerado localmente (PAG-ESC-<tenant>-<ar_id>) para não depender
	// da sequência interna do módulo Financeiro (financeiro.payments_id_seq).
	_, err = tx.Exec(ctx, `
		INSERT INTO financeiro.payments
		(tenant_id, numero, tipo, data_pagamento, valor,
		 referencia_tipo, referencia_id, criado_por)
		VALUES ($1, 'PAG-ESC-'||LPAD($1::text,5,'0')||'-'||LPAD($3::text,8,'0'),
		'recebimento', CURRENT_DATE, $2, 'escolar', $3, $4)
		ON CONFLICT (tenant_id, numero) DO NOTHING`,
		tenantID, valor, arID, createdBy,
	)
	if err != nil {
		return err
	}

	// 3. Actualizar saldo da conta a receber
	_, err = tx.Exec(ctx, `
		UPDATE financeiro.accounts_receivable
		SET valor_pago    = valor_total,
		    valor_pendente = 0,
		    status        = 'pago'
		WHERE id = $1 AND tenant_id = $2`, arID, tenantID)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

// GetStudentClientID devolve o client_id (gestao_clientes) do aluno, ou 0 se não estiver ligado.
func (r *FeeRepository) GetStudentClientID(ctx context.Context, studentID, tenantID int64) (int64, error) {
	var id int64
	err := r.db.QueryRow(ctx, `
		SELECT COALESCE(client_id, 0) FROM gestao_escolar.school_students
		WHERE id=$1 AND tenant_id=$2`, studentID, tenantID).Scan(&id)
	return id, err
}

// GenerateReference gera referência única.
func GenerateReference(prefix string, id int64) string {
	return fmt.Sprintf("%s-%d-%d", prefix, id, time.Now().Unix())
}
