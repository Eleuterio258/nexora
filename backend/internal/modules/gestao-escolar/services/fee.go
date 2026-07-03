package services

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/repositories"
	"nexora/internal/shared/contracts"
)

// FeeService lógica financeira escolar.
type FeeService struct {
	repo       *repositories.FeeRepository
	treasury   contracts.TreasuryPort
	financial  contracts.FinancialPort
	accounting contracts.AccountingPort
	invoicing  contracts.InvoicingPort
}

// NewFeeService cria serviço com os ports de integração injectados.
func NewFeeService(
	repo *repositories.FeeRepository,
	treasury contracts.TreasuryPort,
	financial contracts.FinancialPort,
	accounting contracts.AccountingPort,
	invoicing contracts.InvoicingPort,
) *FeeService {
	return &FeeService{
		repo:       repo,
		treasury:   treasury,
		financial:  financial,
		accounting: accounting,
		invoicing:  invoicing,
	}
}

var (
	ErrFeeNotFound         = errors.New("plano de propina nao encontrado")
	ErrFeeInvalidData      = errors.New("dados invalidos")
	ErrFeeAlreadyGenerated = errors.New("cobrancas ja geradas para este periodo")
)

// GenerateFromPlan gera cobranças recorrentes para um plano e período.
func (s *FeeService) GenerateFromPlan(ctx context.Context, feePlanID, tenantID int64, periodoReferencia string, createdBy *int64) (int, float64, error) {
	plan, err := s.repo.GetFeePlanByID(ctx, feePlanID, tenantID)
	if err == pgx.ErrNoRows {
		return 0, 0, ErrFeeNotFound
	}
	if err != nil {
		return 0, 0, err
	}
	if !plan.Activo {
		return 0, 0, ErrFeeInvalidData
	}
	if plan.SchoolYearID == nil || *plan.SchoolYearID == 0 {
		return 0, 0, ErrFeeInvalidData
	}

	alreadyGenerated, err := s.repo.CountGeneratedInPeriod(ctx, feePlanID, periodoReferencia)
	if err != nil {
		return 0, 0, err
	}
	if alreadyGenerated > 0 {
		return 0, 0, ErrFeeAlreadyGenerated
	}

	enrollments, err := s.repo.ListActiveEnrollmentsForYear(ctx, tenantID, *plan.SchoolYearID)
	if err != nil {
		return 0, 0, err
	}

	dataVencimento, descricao, err := s.periodDetails(plan, periodoReferencia)
	if err != nil {
		return 0, 0, err
	}

	var fees []models.SchoolFee
	for _, e := range enrollments {
		numero := fmt.Sprintf("ESC-%d-%d-%s", feePlanID, e.ID, periodoReferencia)
		fees = append(fees, models.SchoolFee{
			TenantID:       tenantID,
			EnrollmentID:   e.ID,
			FeePlanID:      &feePlanID,
			StudentID:      &e.StudentID,
			Numero:         numero,
			Descricao:      descricao,
			MesReferencia:  periodoReferencia,
			DataVencimento: dataVencimento,
			ValorTotal:     plan.Valor,
			Moeda:          plan.Moeda,
		})
	}

	if err := s.repo.CreateFeesBatch(ctx, fees); err != nil {
		return 0, 0, err
	}

	total := float64(len(fees)) * plan.Valor
	if err := s.repo.RecordGeneration(ctx, tenantID, feePlanID, *plan.SchoolYearID, periodoReferencia, len(fees), total, createdBy); err != nil {
		return 0, 0, err
	}

	return len(fees), total, nil
}

func (s *FeeService) periodDetails(plan *models.FeePlan, periodo string) (time.Time, string, error) {
	var dataVencimento time.Time
	var descricao string

	switch plan.Periodicidade {
	case "mensal":
		t, err := time.Parse("2006-01", periodo)
		if err != nil {
			return time.Time{}, "", ErrFeeInvalidData
		}
		day := 1
		if plan.DiaVencimento != nil && *plan.DiaVencimento > 0 {
			day = *plan.DiaVencimento
		}
		dataVencimento = time.Date(t.Year(), t.Month(), day, 0, 0, 0, 0, time.UTC)
		descricao = fmt.Sprintf("%s - %s/%d", plan.Nome, t.Month().String(), t.Year())
	case "trimestral":
		var year, term int
		_, err := fmt.Sscanf(periodo, "%d-T%d", &year, &term)
		if err != nil {
			return time.Time{}, "", ErrFeeInvalidData
		}
		month := time.Month((term-1)*3 + 1)
		dataVencimento = time.Date(year, month, 1, 0, 0, 0, 0, time.UTC)
		descricao = fmt.Sprintf("%s - Trimestre %d/%d", plan.Nome, term, year)
	case "anual":
		year, err := strconv.Atoi(periodo)
		if err != nil {
			return time.Time{}, "", ErrFeeInvalidData
		}
		dataVencimento = time.Date(year, 1, 1, 0, 0, 0, 0, time.UTC)
		descricao = fmt.Sprintf("%s - Ano %d", plan.Nome, year)
	case "unica":
		dataVencimento = time.Now().AddDate(0, 1, 0)
		descricao = plan.Nome
	default:
		return time.Time{}, "", ErrFeeInvalidData
	}
	return dataVencimento, descricao, nil
}

// ApplyDiscount aplica desconto.
func (s *FeeService) ApplyDiscount(ctx context.Context, id, tenantID int64, desconto float64, motivo string) error {
	if desconto <= 0 {
		return ErrFeeInvalidData
	}
	return s.repo.ApplyDiscount(ctx, id, tenantID, desconto, motivo)
}

// RegisterPayment regista pagamento e aciona integrações configuradas.
// A ordem é: (1) gravar pagamento escolar, (2) Tesouraria, (3) Financeiro.
// As integrações são condicionadas pelas flags em school_financial_config.
func (s *FeeService) RegisterPayment(ctx context.Context, p *models.SchoolPayment) error {
	if p.TenantID == 0 || p.SchoolFeeID == 0 || p.StudentID == 0 || p.Valor <= 0 {
		return ErrFeeInvalidData
	}
	p.Status = strings.ToLower(strings.TrimSpace(p.Status))
	if p.Status == "" {
		p.Status = "confirmado"
	}
	if p.PagoEm.IsZero() {
		p.PagoEm = time.Now()
	}

	fee, err := s.repo.GetFeeByID(ctx, p.SchoolFeeID, p.TenantID)
	if err == pgx.ErrNoRows {
		return ErrFeeNotFound
	}
	if err != nil {
		return err
	}

	// CreatePayment é a operação principal — fatal se falhar (pagamento não registado)
	if err := s.repo.CreatePayment(ctx, p); err != nil {
		return err
	}

	// A partir daqui o pagamento está gravado na DB.
	// Falhas nas integrações externas são logadas mas não revertem o pagamento,
	// evitando que o cliente receba 500 e tente de novo criando duplicados.

	cfg, err := s.repo.GetFinancialConfig(ctx, p.TenantID)
	if err != nil {
		log.Printf("[WARN] RegisterPayment: GetFinancialConfig falhou para tenant %d (payment %d): %v", p.TenantID, p.ID, err)
		return nil
	}
	if cfg == nil {
		return nil // sem configuração → integrações desactivadas
	}

	descricao := fmt.Sprintf("Pagamento escolar - %s", fee.Descricao)
	referencia := fee.Referencia
	if referencia == "" {
		referencia = repositories.GenerateReference("ESC", p.ID)
	}

	// Integração com Tesouraria (via TreasuryPort — baixo acoplamento)
	if cfg.CriarMovimentoTesouraria && s.treasury != nil {
		if err := s.treasury.RecordReceipt(ctx, contracts.TreasuryReceipt{
			TenantID:        p.TenantID,
			ContaBancariaID: cfg.ContaBancariaID,
			Valor:           p.Valor,
			Moeda:           fee.Moeda,
			Referencia:      referencia,
			Descricao:       descricao,
			OrigemTipo:      "escolar",
			OrigemID:        &p.SchoolFeeID,
			DataMovimento:   p.PagoEm,
		}); err != nil {
			log.Printf("[WARN] RegisterPayment: treasury.RecordReceipt falhou (payment %d): %v", p.ID, err)
		}
	}

	// Integração com Financeiro (conta a receber + pagamento)
	if cfg.CriarMovimentoFinanceiro && s.financial != nil {
		if err := s.financial.RecordReceivable(ctx, contracts.FinancialReceivable{
			TenantID:       p.TenantID,
			Numero:         fmt.Sprintf("ESC-%d", p.SchoolFeeID),
			OrigemTipo:     "escolar",
			OrigemID:       p.SchoolFeeID,
			Descricao:      descricao,
			Valor:          p.Valor,
			Moeda:          fee.Moeda,
			DataVencimento: fee.DataVencimento,
			CreatedBy:      p.CreatedBy,
		}); err != nil {
			log.Printf("[WARN] RegisterPayment: financial.RecordReceivable falhou (payment %d): %v", p.ID, err)
		}
	}

	// Integração com Contabilidade (débito bancário / crédito receita propinas)
	if cfg.CriarLancamentoContabilidade && s.accounting != nil &&
		cfg.ContaDebitoID != nil && cfg.ContaCreditoID != nil {
		numEntry := fmt.Sprintf("ESC-JE-%d-%d", p.TenantID, p.ID)
		if err := s.accounting.RecordJournalEntry(ctx, contracts.JournalEntry{
			TenantID:    p.TenantID,
			Numero:      numEntry,
			Descricao:   descricao,
			Referencia:  referencia,
			DataEntrada: p.PagoEm,
			CreatedBy:   p.CreatedBy,
			Linhas: []contracts.JournalLine{
				{ContaID: *cfg.ContaDebitoID, Debito: p.Valor, Credito: 0, Memo: descricao},
				{ContaID: *cfg.ContaCreditoID, Debito: 0, Credito: p.Valor, Memo: descricao},
			},
		}); err != nil {
			log.Printf("[WARN] RegisterPayment: accounting.RecordJournalEntry falhou (payment %d): %v", p.ID, err)
		}
	}

	// Integração com Faturação (recibo tipo RB) — requer client_id do encarregado
	if cfg.CriarReciboFaturacao && s.invoicing != nil && fee.StudentID != nil {
		clientID, _ := s.repo.GetStudentClientID(ctx, *fee.StudentID, p.TenantID)
		if clientID > 0 {
			numRecibo := fmt.Sprintf("RB-ESC-%05d-%08d", p.TenantID, p.ID)
			if _, err := s.invoicing.CreateReceipt(ctx, contracts.SchoolReceipt{
				TenantID:    p.TenantID,
				CustomerID:  clientID,
				Numero:      numRecibo,
				Descricao:   descricao,
				Valor:       p.Valor,
				Moeda:       fee.Moeda,
				DataEmissao: p.PagoEm,
				CreatedBy:   p.CreatedBy,
			}); err != nil {
				log.Printf("[WARN] RegisterPayment: invoicing.CreateReceipt falhou (payment %d): %v", p.ID, err)
			}
		}
	}

	return nil
}
