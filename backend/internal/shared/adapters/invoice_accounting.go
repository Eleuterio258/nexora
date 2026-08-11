package adapters

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"nexora/internal/shared/contracts"
)

// InvoiceAccountingDB é a interface mínima de BD usada pelas funções deste
// ficheiro. *pgxpool.Pool e as interfaces DB de cada módulo (que têm sempre
// pelo menos QueryRow/Exec) satisfazem-na sem qualquer adaptação.
type InvoiceAccountingDB interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

type faturacaoConfigContabil struct {
	AccountingJournalID int64
	ContaClientesID     int64
	ContaReceitaID      int64
	ContaIVAID          *int64
}

func configContabilidadeFaturacao(ctx context.Context, db InvoiceAccountingDB, tenantID int64) (*faturacaoConfigContabil, error) {
	var cfg faturacaoConfigContabil
	var contaIVA *int64
	err := db.QueryRow(ctx, `
		SELECT accounting_journal_id, conta_clientes_id, conta_receita_id, conta_iva_id
		  FROM faturacao.config_contabilidade
		 WHERE tenant_id=$1 AND ativo=TRUE`, tenantID).Scan(
		&cfg.AccountingJournalID, &cfg.ContaClientesID, &cfg.ContaReceitaID, &contaIVA)
	if err != nil {
		return nil, err
	}
	cfg.ContaIVAID = contaIVA
	return &cfg, nil
}

// PostInvoiceJournalEntry gera o lançamento de reconhecimento de receita
// (débito Clientes, crédito Receita + IVA) para uma factura já emitida/paga.
// Partilhado entre a emissão HTTP em modulo-faturacao (EmitirFaturaFiscal) e
// a factura fiscal automática que o POS gera em toda venda concluída
// (criarFaturaParaVenda) — ambas escrevem em faturacao.invoices.
//
// Não bloqueante por desenho: chamar sempre DEPOIS de a transacção que criou
// ou emitiu a factura já ter sido comitada. Se o tenant não tiver
// faturacao.config_contabilidade activa, ou se a postagem falhar por
// qualquer razão (ex.: período fiscal fechado), fica só registado em log —
// nunca reverte a venda/emissão que já aconteceu.
func PostInvoiceJournalEntry(ctx context.Context, db InvoiceAccountingDB, accounting contracts.AccountingPort, tenantID, userID, invoiceID int64) {
	if accounting == nil {
		return
	}
	cfg, err := configContabilidadeFaturacao(ctx, db, tenantID)
	if err != nil {
		return // tenant sem integração contabilística configurada — normal
	}

	var numero string
	var subtotal, descontoTotal, impostoTotal, total float64
	var dataEntrada time.Time
	var jaTemLancamento *int64
	err = db.QueryRow(ctx, `
		SELECT numero, subtotal, desconto_total, imposto_total, total, invoice_date, journal_entry_id
		  FROM faturacao.invoices WHERE id=$1 AND tenant_id=$2`, invoiceID, tenantID).
		Scan(&numero, &subtotal, &descontoTotal, &impostoTotal, &total, &dataEntrada, &jaTemLancamento)
	if err != nil {
		log.Printf("[WARN] PostInvoiceJournalEntry: fatura %d não encontrada: %v", invoiceID, err)
		return
	}
	if jaTemLancamento != nil || total <= 0 {
		return
	}

	receitaLiquida := subtotal - descontoTotal
	linhas := []contracts.JournalLine{
		{ContaID: cfg.ContaClientesID, Debito: total, Credito: 0, Memo: "Factura " + numero},
	}
	if cfg.ContaIVAID != nil && impostoTotal > 0 {
		linhas = append(linhas,
			contracts.JournalLine{ContaID: cfg.ContaReceitaID, Debito: 0, Credito: receitaLiquida, Memo: "Factura " + numero},
			contracts.JournalLine{ContaID: *cfg.ContaIVAID, Debito: 0, Credito: impostoTotal, Memo: "IVA factura " + numero},
		)
	} else {
		linhas = append(linhas,
			contracts.JournalLine{ContaID: cfg.ContaReceitaID, Debito: 0, Credito: receitaLiquida + impostoTotal, Memo: "Factura " + numero},
		)
	}

	entryID, err := recordAndFetchEntry(ctx, db, accounting, tenantID, userID, cfg.AccountingJournalID,
		fmt.Sprintf("FT-JE-%s", numero), fmt.Sprintf("Factura %s", numero), "fatura", invoiceID, dataEntrada, linhas)
	if err != nil {
		log.Printf("[WARN] PostInvoiceJournalEntry: falhou (fatura %d): %v", invoiceID, err)
		return
	}
	if _, err := db.Exec(ctx, `UPDATE faturacao.invoices SET journal_entry_id=$1 WHERE id=$2 AND tenant_id=$3`, entryID, invoiceID, tenantID); err != nil {
		log.Printf("[WARN] PostInvoiceJournalEntry: não foi possível gravar journal_entry_id (fatura %d): %v", invoiceID, err)
	}
}

// PostCreditNoteJournalEntry gera o lançamento de estorno — o inverso do
// reconhecimento de receita (débito Receita + IVA, crédito Clientes) — para
// uma nota de crédito já emitida. Mesmo padrão não-bloqueante de
// PostInvoiceJournalEntry; chamar depois da transacção que emitiu a nota
// (hoje só o estorno de vendas POS — EstornoParcialVenda — emite notas de
// crédito reais com total>0; CriarNotaCredito em modulo-faturacao ainda cria
// só rascunhos vazios, ver lacunasde10082026.md item 1).
func PostCreditNoteJournalEntry(ctx context.Context, db InvoiceAccountingDB, accounting contracts.AccountingPort, tenantID, userID, creditNoteID int64) {
	if accounting == nil {
		return
	}
	cfg, err := configContabilidadeFaturacao(ctx, db, tenantID)
	if err != nil {
		return
	}

	var numero string
	var subtotal, impostoTotal, total float64
	var dataEntrada time.Time
	var jaTemLancamento *int64
	err = db.QueryRow(ctx, `
		SELECT numero, subtotal, imposto_total, total, credit_date, journal_entry_id
		  FROM faturacao.credit_notes WHERE id=$1 AND tenant_id=$2`, creditNoteID, tenantID).
		Scan(&numero, &subtotal, &impostoTotal, &total, &dataEntrada, &jaTemLancamento)
	if err != nil {
		log.Printf("[WARN] PostCreditNoteJournalEntry: nota de crédito %d não encontrada: %v", creditNoteID, err)
		return
	}
	if jaTemLancamento != nil || total <= 0 {
		return
	}

	// Notas de crédito emitidas pelo POS (o único emissor real hoje) não
	// discriminam subtotal/imposto_total por linha — só o total devolvido.
	receitaLiquida := subtotal - impostoTotal
	if receitaLiquida <= 0 {
		receitaLiquida = total - impostoTotal
	}
	linhas := []contracts.JournalLine{
		{ContaID: cfg.ContaClientesID, Debito: 0, Credito: total, Memo: "Nota de crédito " + numero},
	}
	if cfg.ContaIVAID != nil && impostoTotal > 0 {
		linhas = append(linhas,
			contracts.JournalLine{ContaID: cfg.ContaReceitaID, Debito: receitaLiquida, Credito: 0, Memo: "Nota de crédito " + numero},
			contracts.JournalLine{ContaID: *cfg.ContaIVAID, Debito: impostoTotal, Credito: 0, Memo: "IVA nota de crédito " + numero},
		)
	} else {
		linhas = append(linhas,
			contracts.JournalLine{ContaID: cfg.ContaReceitaID, Debito: receitaLiquida + impostoTotal, Credito: 0, Memo: "Nota de crédito " + numero},
		)
	}

	entryID, err := recordAndFetchEntry(ctx, db, accounting, tenantID, userID, cfg.AccountingJournalID,
		fmt.Sprintf("NC-JE-%s", numero), fmt.Sprintf("Nota de crédito %s", numero), "nota_credito", creditNoteID, dataEntrada, linhas)
	if err != nil {
		log.Printf("[WARN] PostCreditNoteJournalEntry: falhou (nota %d): %v", creditNoteID, err)
		return
	}
	if _, err := db.Exec(ctx, `UPDATE faturacao.credit_notes SET journal_entry_id=$1 WHERE id=$2 AND tenant_id=$3`, entryID, creditNoteID, tenantID); err != nil {
		log.Printf("[WARN] PostCreditNoteJournalEntry: não foi possível gravar journal_entry_id (nota %d): %v", creditNoteID, err)
	}
}

// recordAndFetchEntry chama o AccountingPort e devolve o id do lançamento
// criado (RecordJournalEntry não o devolve directamente, só erro).
func recordAndFetchEntry(ctx context.Context, db InvoiceAccountingDB, accounting contracts.AccountingPort,
	tenantID, userID, accountingJournalID int64, entryNumero, descricao, referenciaTipo string, referenciaID int64,
	dataEntrada time.Time, linhas []contracts.JournalLine) (int64, error) {
	var createdBy *int64
	if userID > 0 {
		createdBy = &userID
	}
	refID := referenciaID
	if err := accounting.RecordJournalEntry(ctx, contracts.JournalEntry{
		TenantID:            tenantID,
		AccountingJournalID: accountingJournalID,
		Numero:              entryNumero,
		Descricao:           descricao,
		ReferenciaTipo:      referenciaTipo,
		ReferenciaID:        &refID,
		DataEntrada:         dataEntrada,
		CreatedBy:           createdBy,
		Linhas:              linhas,
	}); err != nil {
		return 0, err
	}

	var entryID int64
	if err := db.QueryRow(ctx, `SELECT id FROM contabilidade.journal_entries WHERE tenant_id=$1 AND numero=$2`, tenantID, entryNumero).Scan(&entryID); err != nil {
		return 0, fmt.Errorf("lançamento criado mas não encontrado ao reler: %w", err)
	}
	return entryID, nil
}
