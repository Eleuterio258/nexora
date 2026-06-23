package handlers

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

var (
	errLancamentoNaoEncontrado = errors.New("lançamento não encontrado")
	errLancamentoNaoPublicado  = errors.New("apenas lançamentos publicados podem ser estornados")
	errPeriodoNaoAberto        = errors.New("o período fiscal não está aberto")
)

const journalEntrySelect = `
	SELECT id, fiscal_period_id, accounting_journal_id, numero, entry_date, descricao,
	       referencia_tipo, referencia_id, status, moeda, total_debito, total_credito,
	       criado_por, publicado_por, publicado_em, created_at
	  FROM contabilidade.journal_entries`

type journalEntryRow struct {
	ID                  int64      `json:"id"`
	FiscalPeriodID      int64      `json:"fiscal_period_id"`
	AccountingJournalID int64      `json:"accounting_journal_id"`
	Numero              string     `json:"numero"`
	EntryDate           time.Time  `json:"entry_date"`
	Descricao           string     `json:"descricao"`
	ReferenciaTipo      *string    `json:"referencia_tipo"`
	ReferenciaID        *int64     `json:"referencia_id"`
	Status              string     `json:"status"`
	Moeda               string     `json:"moeda"`
	TotalDebito         float64    `json:"total_debito"`
	TotalCredito        float64    `json:"total_credito"`
	CriadoPor           *int64     `json:"criado_por"`
	PublicadoPor        *int64     `json:"publicado_por"`
	PublicadoEm         *time.Time `json:"publicado_em"`
	CreatedAt           time.Time  `json:"created_at"`
}

type journalEntryLineRow struct {
	ID            int64   `json:"id"`
	AccountID     int64   `json:"account_id"`
	AccountCodigo string  `json:"account_codigo"`
	AccountNome   string  `json:"account_nome"`
	Descricao     *string `json:"descricao"`
	Debit         float64 `json:"debit"`
	Credit        float64 `json:"credit"`
}

type lancamentoLinhaInput struct {
	AccountID int64   `json:"account_id"`
	Descricao *string `json:"descricao"`
	Debit     float64 `json:"debit"`
	Credit    float64 `json:"credit"`
}

func scanJournalEntry(row pgx.Row) (journalEntryRow, error) {
	var e journalEntryRow
	err := row.Scan(&e.ID, &e.FiscalPeriodID, &e.AccountingJournalID, &e.Numero, &e.EntryDate, &e.Descricao,
		&e.ReferenciaTipo, &e.ReferenciaID, &e.Status, &e.Moeda, &e.TotalDebito, &e.TotalCredito,
		&e.CriadoPor, &e.PublicadoPor, &e.PublicadoEm, &e.CreatedAt)
	return e, err
}

// proximoNumeroLancamento obtém e incrementa a sequência do diário/ano com lock,
// devolvendo o número no formato "<codigo>/<ano>/<sequencia%04d>".
func proximoNumeroLancamento(ctx context.Context, tx pgx.Tx, tenantID, journalID int64, ano int, codigoDiario string) (string, error) {
	_, err := tx.Exec(ctx, `
		INSERT INTO contabilidade.journal_entry_sequences (tenant_id, accounting_journal_id, ano, proxima_sequencia)
		VALUES ($1,$2,$3,1)
		ON CONFLICT (tenant_id, accounting_journal_id, ano) DO NOTHING`,
		tenantID, journalID, ano)
	if err != nil {
		return "", err
	}

	var seq int
	err = tx.QueryRow(ctx, `
		SELECT proxima_sequencia FROM contabilidade.journal_entry_sequences
		 WHERE tenant_id=$1 AND accounting_journal_id=$2 AND ano=$3
		 FOR UPDATE`,
		tenantID, journalID, ano).Scan(&seq)
	if err != nil {
		return "", err
	}

	_, err = tx.Exec(ctx, `
		UPDATE contabilidade.journal_entry_sequences SET proxima_sequencia=proxima_sequencia+1
		 WHERE tenant_id=$1 AND accounting_journal_id=$2 AND ano=$3`,
		tenantID, journalID, ano)
	if err != nil {
		return "", err
	}

	return fmt.Sprintf("%s/%d/%04d", codigoDiario, ano, seq), nil
}

// validarLinhasLancamento garante que cada linha tem débito XOR crédito > 0
// e que o lançamento está balanceado, devolvendo os totais.
func validarLinhasLancamento(linhas []lancamentoLinhaInput) (totalDebito, totalCredito float64, err error) {
	for _, l := range linhas {
		if l.AccountID == 0 {
			return 0, 0, fmt.Errorf("cada linha deve indicar account_id")
		}
		if l.Debit < 0 || l.Credit < 0 {
			return 0, 0, fmt.Errorf("debit e credit não podem ser negativos")
		}
		if (l.Debit > 0) == (l.Credit > 0) {
			return 0, 0, fmt.Errorf("cada linha deve ter débito ou crédito, mas não ambos")
		}
		totalDebito += l.Debit
		totalCredito += l.Credit
	}
	if math.Abs(totalDebito-totalCredito) > 0.005 {
		return 0, 0, fmt.Errorf("o lançamento não está balanceado: débito %.2f, crédito %.2f", totalDebito, totalCredito)
	}
	return totalDebito, totalCredito, nil
}

func validarContasLancamento(ctx context.Context, tx pgx.Tx, tenantID int64, linhas []lancamentoLinhaInput) error {
	for _, l := range linhas {
		var aceitaLancamento bool
		err := tx.QueryRow(ctx, `
			SELECT aceita_lancamento FROM contabilidade.chart_of_accounts
			 WHERE id=$1 AND tenant_id=$2`, l.AccountID, tenantID).Scan(&aceitaLancamento)
		if err != nil {
			return fmt.Errorf("conta %d não encontrada", l.AccountID)
		}
		if !aceitaLancamento {
			return fmt.Errorf("a conta %d não aceita lançamentos", l.AccountID)
		}
	}
	return nil
}

func inserirLinhasLancamento(ctx context.Context, tx pgx.Tx, entryID int64, linhas []lancamentoLinhaInput) error {
	for _, l := range linhas {
		if _, err := tx.Exec(ctx, `
			INSERT INTO contabilidade.journal_entry_lines (journal_entry_id, account_id, descricao, debit, credit)
			VALUES ($1,$2,$3,$4,$5)`,
			entryID, l.AccountID, l.Descricao, l.Debit, l.Credit); err != nil {
			return err
		}
	}
	return nil
}

func (h *Handler) ListarLancamentos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	for _, f := range []string{"fiscal_period_id", "accounting_journal_id", "referencia_tipo", "status"} {
		if v := q.Get(f); v != "" {
			args = append(args, v)
			where += " AND " + f + "=$" + strconv.Itoa(len(args))
		}
	}
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(), journalEntrySelect+" WHERE "+where+
		" ORDER BY entry_date DESC, id DESC LIMIT $"+strconv.Itoa(n-1)+" OFFSET $"+strconv.Itoa(n), args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data := []journalEntryRow{}
	for rows.Next() {
		e, err := scanJournalEntry(rows)
		if err == nil {
			data = append(data, e)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarLancamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		AccountingJournalID int64                  `json:"accounting_journal_id"`
		FiscalPeriodID      int64                  `json:"fiscal_period_id"`
		EntryDate           string                 `json:"entry_date"`
		Descricao           string                 `json:"descricao"`
		ReferenciaTipo      *string                `json:"referencia_tipo"`
		ReferenciaID        *int64                 `json:"referencia_id"`
		Moeda               *string                `json:"moeda"`
		Linhas              []lancamentoLinhaInput `json:"linhas"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil ||
		body.AccountingJournalID == 0 || body.FiscalPeriodID == 0 || body.EntryDate == "" || body.Descricao == "" {
		jsonErr(w, "accounting_journal_id, fiscal_period_id, entry_date e descricao são obrigatórios", http.StatusBadRequest)
		return
	}
	if len(body.Linhas) < 2 {
		jsonErr(w, "o lançamento deve ter pelo menos duas linhas", http.StatusBadRequest)
		return
	}
	totalDebito, totalCredito, err := validarLinhasLancamento(body.Linhas)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusBadRequest)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var periodoStatus string
	var ano int
	err = tx.QueryRow(r.Context(), `
		SELECT status, ano FROM contabilidade.fiscal_periods WHERE id=$1 AND tenant_id=$2`,
		body.FiscalPeriodID, user.TenantID).Scan(&periodoStatus, &ano)
	if err != nil {
		jsonErr(w, "Período fiscal não encontrado", http.StatusNotFound)
		return
	}
	if periodoStatus != "aberto" {
		jsonErr(w, "o período fiscal não está aberto", http.StatusConflict)
		return
	}

	var codigoDiario string
	err = tx.QueryRow(r.Context(), `
		SELECT codigo FROM contabilidade.accounting_journals WHERE id=$1 AND tenant_id=$2`,
		body.AccountingJournalID, user.TenantID).Scan(&codigoDiario)
	if err != nil {
		jsonErr(w, "Diário não encontrado", http.StatusNotFound)
		return
	}

	if err := validarContasLancamento(r.Context(), tx, user.TenantID, body.Linhas); err != nil {
		jsonErr(w, err.Error(), http.StatusBadRequest)
		return
	}

	numero, err := proximoNumeroLancamento(r.Context(), tx, user.TenantID, body.AccountingJournalID, ano, codigoDiario)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	moeda := "MZN"
	if body.Moeda != nil && *body.Moeda != "" {
		moeda = *body.Moeda
	}

	var id int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO contabilidade.journal_entries
		  (tenant_id, fiscal_period_id, accounting_journal_id, numero, entry_date, descricao,
		   referencia_tipo, referencia_id, status, moeda, total_debito, total_credito,
		   criado_por, publicado_por, publicado_em)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'publicado',$9,$10,$11,$12,$12,NOW())
		RETURNING id`,
		user.TenantID, body.FiscalPeriodID, body.AccountingJournalID, numero, body.EntryDate, body.Descricao,
		body.ReferenciaTipo, body.ReferenciaID, moeda, totalDebito, totalCredito, user.ID).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Número de lançamento já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := inserirLinhasLancamento(r.Context(), tx, id, body.Linhas); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"id": id, "numero": numero}, http.StatusCreated)
}

func (h *Handler) ObterLancamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	e, err := scanJournalEntry(h.db.QueryRow(r.Context(), journalEntrySelect+` WHERE id=$1 AND tenant_id=$2`, id, user.TenantID))
	if err != nil {
		jsonErr(w, "Lançamento não encontrado", http.StatusNotFound)
		return
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT l.id, l.account_id, a.codigo, a.nome, l.descricao, l.debit, l.credit
		  FROM contabilidade.journal_entry_lines l
		  JOIN contabilidade.chart_of_accounts a ON a.id = l.account_id
		 WHERE l.journal_entry_id=$1
		 ORDER BY l.id`, e.ID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	linhas := []journalEntryLineRow{}
	for rows.Next() {
		var l journalEntryLineRow
		if rows.Scan(&l.ID, &l.AccountID, &l.AccountCodigo, &l.AccountNome, &l.Descricao, &l.Debit, &l.Credit) == nil {
			linhas = append(linhas, l)
		}
	}
	rows.Close()

	jsonOK(w, map[string]any{
		"id": e.ID, "fiscal_period_id": e.FiscalPeriodID, "accounting_journal_id": e.AccountingJournalID,
		"numero": e.Numero, "entry_date": e.EntryDate, "descricao": e.Descricao,
		"referencia_tipo": e.ReferenciaTipo, "referencia_id": e.ReferenciaID,
		"status": e.Status, "moeda": e.Moeda, "total_debito": e.TotalDebito, "total_credito": e.TotalCredito,
		"criado_por": e.CriadoPor, "publicado_por": e.PublicadoPor, "publicado_em": e.PublicadoEm,
		"created_at": e.CreatedAt, "linhas": linhas,
	}, http.StatusOK)
}

func (h *Handler) ActualizarLancamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		EntryDate *string                `json:"entry_date"`
		Descricao *string                `json:"descricao"`
		Linhas    []lancamentoLinhaInput `json:"linhas"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	if len(body.Linhas) < 2 {
		jsonErr(w, "o lançamento deve ter pelo menos duas linhas", http.StatusBadRequest)
		return
	}
	totalDebito, totalCredito, err := validarLinhasLancamento(body.Linhas)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusBadRequest)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var entryID int64
	var status, periodoStatus string
	err = tx.QueryRow(r.Context(), `
		SELECT e.id, e.status, p.status
		  FROM contabilidade.journal_entries e
		  JOIN contabilidade.fiscal_periods p ON p.id = e.fiscal_period_id
		 WHERE e.id=$1 AND e.tenant_id=$2`, id, user.TenantID).Scan(&entryID, &status, &periodoStatus)
	if err != nil {
		jsonErr(w, "Lançamento não encontrado", http.StatusNotFound)
		return
	}
	if status != "publicado" {
		jsonErr(w, "apenas lançamentos publicados podem ser alterados", http.StatusConflict)
		return
	}
	if periodoStatus != "aberto" {
		jsonErr(w, "o período fiscal não está aberto", http.StatusConflict)
		return
	}

	if err := validarContasLancamento(r.Context(), tx, user.TenantID, body.Linhas); err != nil {
		jsonErr(w, err.Error(), http.StatusBadRequest)
		return
	}

	if _, err := tx.Exec(r.Context(), `DELETE FROM contabilidade.journal_entry_lines WHERE journal_entry_id=$1`, entryID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if err := inserirLinhasLancamento(r.Context(), tx, entryID, body.Linhas); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	_, err = tx.Exec(r.Context(), `
		UPDATE contabilidade.journal_entries SET
		  entry_date=COALESCE($1,entry_date), descricao=COALESCE($2,descricao),
		  total_debito=$3, total_credito=$4, updated_at=NOW()
		WHERE id=$5`,
		body.EntryDate, body.Descricao, totalDebito, totalCredito, entryID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// estornarLancamentoTx marca o lançamento entryID como anulado e cria um
// lançamento espelho (publicado, débitos/créditos invertidos,
// referencia_tipo='estorno'), devolvendo o seu id e número.
func estornarLancamentoTx(ctx context.Context, tx pgx.Tx, tenantID, userID int64, entryID any) (novoID int64, numero string, err error) {
	original, err := scanJournalEntry(tx.QueryRow(ctx, journalEntrySelect+` WHERE id=$1 AND tenant_id=$2`, entryID, tenantID))
	if err != nil {
		return 0, "", errLancamentoNaoEncontrado
	}
	if original.Status != "publicado" {
		return 0, "", errLancamentoNaoPublicado
	}

	var periodoStatus string
	var ano int
	err = tx.QueryRow(ctx, `SELECT status, ano FROM contabilidade.fiscal_periods WHERE id=$1`, original.FiscalPeriodID).
		Scan(&periodoStatus, &ano)
	if err != nil {
		return 0, "", err
	}
	if periodoStatus != "aberto" {
		return 0, "", errPeriodoNaoAberto
	}

	var codigoDiario string
	err = tx.QueryRow(ctx, `SELECT codigo FROM contabilidade.accounting_journals WHERE id=$1`, original.AccountingJournalID).
		Scan(&codigoDiario)
	if err != nil {
		return 0, "", err
	}

	rows, err := tx.Query(ctx, `
		SELECT account_id, descricao, debit, credit
		  FROM contabilidade.journal_entry_lines WHERE journal_entry_id=$1`, original.ID)
	if err != nil {
		return 0, "", err
	}
	var linhas []lancamentoLinhaInput
	for rows.Next() {
		var l lancamentoLinhaInput
		if rows.Scan(&l.AccountID, &l.Descricao, &l.Debit, &l.Credit) == nil {
			l.Debit, l.Credit = l.Credit, l.Debit
			linhas = append(linhas, l)
		}
	}
	rows.Close()

	numero, err = proximoNumeroLancamento(ctx, tx, tenantID, original.AccountingJournalID, ano, codigoDiario)
	if err != nil {
		return 0, "", err
	}

	err = tx.QueryRow(ctx, `
		INSERT INTO contabilidade.journal_entries
		  (tenant_id, fiscal_period_id, accounting_journal_id, numero, entry_date, descricao,
		   referencia_tipo, referencia_id, status, moeda, total_debito, total_credito,
		   criado_por, publicado_por, publicado_em)
		VALUES ($1,$2,$3,$4,CURRENT_DATE,$5,$6,$7,'publicado',$8,$9,$10,$11,$11,NOW())
		RETURNING id`,
		tenantID, original.FiscalPeriodID, original.AccountingJournalID, numero,
		"Estorno de "+original.Numero+" - "+original.Descricao, "estorno", original.ID,
		original.Moeda, original.TotalCredito, original.TotalDebito, userID).Scan(&novoID)
	if err != nil {
		return 0, "", err
	}

	if err := inserirLinhasLancamento(ctx, tx, novoID, linhas); err != nil {
		return 0, "", err
	}

	_, err = tx.Exec(ctx, `UPDATE contabilidade.journal_entries SET status='anulado', updated_at=NOW() WHERE id=$1`, original.ID)
	if err != nil {
		return 0, "", err
	}

	return novoID, numero, nil
}

func (h *Handler) EstornarLancamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	novoID, numero, err := estornarLancamentoTx(r.Context(), tx, user.TenantID, user.ID, id)
	if err != nil {
		switch {
		case errors.Is(err, errLancamentoNaoEncontrado):
			jsonErr(w, err.Error(), http.StatusNotFound)
		case errors.Is(err, errLancamentoNaoPublicado), errors.Is(err, errPeriodoNaoAberto):
			jsonErr(w, err.Error(), http.StatusConflict)
		default:
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"id": novoID, "numero": numero}, http.StatusCreated)
}

func (h *Handler) AdicionarLinhaLancamento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body lancamentoLinhaInput
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.AccountID == 0 {
		jsonErr(w, "account_id é obrigatório", http.StatusBadRequest)
		return
	}
	if body.Debit < 0 || body.Credit < 0 || (body.Debit > 0) == (body.Credit > 0) {
		jsonErr(w, "a linha deve ter débito ou crédito, mas não ambos", http.StatusBadRequest)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var entryID int64
	var status, periodoStatus string
	err = tx.QueryRow(r.Context(), `
		SELECT e.id, e.status, p.status
		  FROM contabilidade.journal_entries e
		  JOIN contabilidade.fiscal_periods p ON p.id = e.fiscal_period_id
		 WHERE e.id=$1 AND e.tenant_id=$2`, id, user.TenantID).Scan(&entryID, &status, &periodoStatus)
	if err != nil {
		jsonErr(w, "Lançamento não encontrado", http.StatusNotFound)
		return
	}
	if status != "publicado" {
		jsonErr(w, "apenas lançamentos publicados podem ser alterados", http.StatusConflict)
		return
	}
	if periodoStatus != "aberto" {
		jsonErr(w, "o período fiscal não está aberto", http.StatusConflict)
		return
	}

	if err := validarContasLancamento(r.Context(), tx, user.TenantID, []lancamentoLinhaInput{body}); err != nil {
		jsonErr(w, err.Error(), http.StatusBadRequest)
		return
	}

	var lineID int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO contabilidade.journal_entry_lines (journal_entry_id, account_id, descricao, debit, credit)
		VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		entryID, body.AccountID, body.Descricao, body.Debit, body.Credit).Scan(&lineID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	_, err = tx.Exec(r.Context(), `
		UPDATE contabilidade.journal_entries SET
		  total_debito=total_debito+$1, total_credito=total_credito+$2, updated_at=NOW()
		WHERE id=$3`, body.Debit, body.Credit, entryID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"id": lineID}, http.StatusCreated)
}
