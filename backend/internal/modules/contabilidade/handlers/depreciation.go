package handlers

import (
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/http"
	"sort"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

const depreciationEntrySelect = `
	SELECT d.id, d.fixed_asset_id, d.fiscal_period_id, d.numero_parcela, d.valor_amortizacao, d.status, d.journal_entry_id, d.created_at
	  FROM contabilidade.depreciation_entries d
	  JOIN contabilidade.fixed_assets fa ON fa.id = d.fixed_asset_id`

type depreciationEntryRow struct {
	ID               int64     `json:"id"`
	FixedAssetID     int64     `json:"fixed_asset_id"`
	FiscalPeriodID   int64     `json:"fiscal_period_id"`
	NumeroParcela    int       `json:"numero_parcela"`
	ValorAmortizacao float64   `json:"valor_amortizacao"`
	Status           string    `json:"status"`
	JournalEntryID   *int64    `json:"journal_entry_id"`
	CreatedAt        time.Time `json:"created_at"`
}

func scanDepreciationEntry(row pgx.Row) (depreciationEntryRow, error) {
	var e depreciationEntryRow
	err := row.Scan(&e.ID, &e.FixedAssetID, &e.FiscalPeriodID, &e.NumeroParcela, &e.ValorAmortizacao, &e.Status, &e.JournalEntryID, &e.CreatedAt)
	return e, err
}

func (h *Handler) ListarAmortizacoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "fa.tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("fixed_asset_id"); v != "" {
		args = append(args, v)
		where += " AND d.fixed_asset_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("fiscal_period_id"); v != "" {
		args = append(args, v)
		where += " AND d.fiscal_period_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("status"); v != "" {
		args = append(args, v)
		where += " AND d.status=$" + strconv.Itoa(len(args))
	}
	rows, err := h.db.Query(r.Context(), depreciationEntrySelect+" WHERE "+where+" ORDER BY d.fiscal_period_id DESC, d.id", args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data := []depreciationEntryRow{}
	for rows.Next() {
		e, err := scanDepreciationEntry(rows)
		if err == nil {
			data = append(data, e)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) ObterAmortizacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	e, err := scanDepreciationEntry(h.db.QueryRow(r.Context(), depreciationEntrySelect+` WHERE d.id=$1 AND fa.tenant_id=$2`, id, user.TenantID))
	if err != nil {
		jsonErr(w, "Amortização não encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, e, http.StatusOK)
}

// ProcessarAmortizacoes calcula a parcela de amortização (linha recta) de cada
// ativo fixo activo ainda sem entrada para o período indicado, e regista-as
// num único lançamento consolidado (um par débito/crédito por conta).
func (h *Handler) ProcessarAmortizacoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		FiscalPeriodID      int64 `json:"fiscal_period_id"`
		AccountingJournalID int64 `json:"accounting_journal_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.FiscalPeriodID == 0 || body.AccountingJournalID == 0 {
		jsonErr(w, "fiscal_period_id e accounting_journal_id são obrigatórios", http.StatusBadRequest)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var periodoStatus string
	var ano, mes int
	err = tx.QueryRow(r.Context(), `SELECT status, ano, mes FROM contabilidade.fiscal_periods WHERE id=$1 AND tenant_id=$2`,
		body.FiscalPeriodID, user.TenantID).Scan(&periodoStatus, &ano, &mes)
	if err != nil {
		jsonErr(w, "Período fiscal não encontrado", http.StatusNotFound)
		return
	}
	if periodoStatus != "aberto" {
		jsonErr(w, "o período fiscal não está aberto", http.StatusConflict)
		return
	}

	var codigoDiario string
	err = tx.QueryRow(r.Context(), `SELECT codigo FROM contabilidade.accounting_journals WHERE id=$1 AND tenant_id=$2`,
		body.AccountingJournalID, user.TenantID).Scan(&codigoDiario)
	if err != nil {
		jsonErr(w, "Diário não encontrado", http.StatusNotFound)
		return
	}

	rows, err := tx.Query(r.Context(), `
		SELECT fa.id, fa.depreciation_account_id, fa.accumulated_depreciation_account_id,
		       fa.valor_aquisicao, fa.valor_residual, fa.vida_util_meses,
		       (SELECT COUNT(*) FROM contabilidade.depreciation_entries WHERE fixed_asset_id=fa.id)
		  FROM contabilidade.fixed_assets fa
		 WHERE fa.tenant_id=$1 AND fa.estado='ativo'
		   AND NOT EXISTS (
		       SELECT 1 FROM contabilidade.depreciation_entries
		        WHERE fixed_asset_id=fa.id AND fiscal_period_id=$2)`,
		user.TenantID, body.FiscalPeriodID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	type ativoPendente struct {
		id, contaAmortizacao, contaAcumulada int64
		valorAquisicao, valorResidual        float64
		vidaUtil, parcelasExistentes         int
	}
	var ativos []ativoPendente
	for rows.Next() {
		var a ativoPendente
		if rows.Scan(&a.id, &a.contaAmortizacao, &a.contaAcumulada, &a.valorAquisicao, &a.valorResidual, &a.vidaUtil, &a.parcelasExistentes) == nil {
			if a.parcelasExistentes < a.vidaUtil {
				ativos = append(ativos, a)
			}
		}
	}
	rows.Close()

	if len(ativos) == 0 {
		jsonErr(w, "não existem ativos fixos pendentes de amortização neste período", http.StatusConflict)
		return
	}

	type valoresPorConta struct {
		debito, credito float64
	}
	totaisPorConta := map[int64]*valoresPorConta{}
	type parcelaAtivo struct {
		fixedAssetID  int64
		numeroParcela int
		valor         float64
	}
	var parcelas []parcelaAtivo
	for _, a := range ativos {
		base := a.valorAquisicao - a.valorResidual
		valorParcela := math.Round(base/float64(a.vidaUtil)*100) / 100
		numeroParcela := a.parcelasExistentes + 1
		valor := valorParcela
		if numeroParcela == a.vidaUtil {
			valor = math.Round((base-valorParcela*float64(a.vidaUtil-1))*100) / 100
		}
		if valor <= 0 {
			continue
		}

		if totaisPorConta[a.contaAmortizacao] == nil {
			totaisPorConta[a.contaAmortizacao] = &valoresPorConta{}
		}
		totaisPorConta[a.contaAmortizacao].debito += valor

		if totaisPorConta[a.contaAcumulada] == nil {
			totaisPorConta[a.contaAcumulada] = &valoresPorConta{}
		}
		totaisPorConta[a.contaAcumulada].credito += valor

		parcelas = append(parcelas, parcelaAtivo{fixedAssetID: a.id, numeroParcela: numeroParcela, valor: valor})
	}

	if len(parcelas) == 0 {
		jsonErr(w, "não existem ativos fixos pendentes de amortização neste período", http.StatusConflict)
		return
	}

	contaIDs := make([]int64, 0, len(totaisPorConta))
	for contaID := range totaisPorConta {
		contaIDs = append(contaIDs, contaID)
	}
	sort.Slice(contaIDs, func(i, j int) bool { return contaIDs[i] < contaIDs[j] })

	descricao := fmt.Sprintf("Amortização do período %02d/%d", mes, ano)
	var linhas []lancamentoLinhaInput
	for _, contaID := range contaIDs {
		t := totaisPorConta[contaID]
		if t.debito > 0 {
			d := descricao
			linhas = append(linhas, lancamentoLinhaInput{AccountID: contaID, Descricao: &d, Debit: t.debito})
		}
		if t.credito > 0 {
			d := descricao
			linhas = append(linhas, lancamentoLinhaInput{AccountID: contaID, Descricao: &d, Credit: t.credito})
		}
	}

	totalDebito, totalCredito, err := validarLinhasLancamento(linhas)
	if err != nil {
		jsonErr(w, err.Error(), http.StatusConflict)
		return
	}
	if err := validarContasLancamento(r.Context(), tx, user.TenantID, linhas); err != nil {
		jsonErr(w, err.Error(), http.StatusConflict)
		return
	}

	numero, err := proximoNumeroLancamento(r.Context(), tx, user.TenantID, body.AccountingJournalID, ano, codigoDiario)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	var entryID int64
	err = tx.QueryRow(r.Context(), `
		INSERT INTO contabilidade.journal_entries
		  (tenant_id, fiscal_period_id, accounting_journal_id, numero, entry_date, descricao,
		   referencia_tipo, referencia_id, status, moeda, total_debito, total_credito,
		   criado_por, publicado_por, publicado_em)
		VALUES ($1,$2,$3,$4,CURRENT_DATE,$5,'amortizacao',$6,'publicado',$7,$8,$9,$10,$10,NOW())
		RETURNING id`,
		user.TenantID, body.FiscalPeriodID, body.AccountingJournalID, numero,
		descricao, body.FiscalPeriodID, "MZN", totalDebito, totalCredito, user.ID).Scan(&entryID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := inserirLinhasLancamento(r.Context(), tx, entryID, linhas); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	for _, p := range parcelas {
		if _, err := tx.Exec(r.Context(), `
			INSERT INTO contabilidade.depreciation_entries
			  (tenant_id, fixed_asset_id, fiscal_period_id, numero_parcela, valor_amortizacao, status, journal_entry_id)
			VALUES ($1,$2,$3,$4,$5,'processado',$6)`,
			user.TenantID, p.fixedAssetID, body.FiscalPeriodID, p.numeroParcela, p.valor, entryID); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"id": entryID, "numero": numero, "ativos_processados": len(parcelas), "total": totalDebito,
	}, http.StatusCreated)
}

// CancelarAmortizacao estorna o lançamento de amortização associado e marca
// como 'cancelado' todas as depreciation_entries desse lançamento consolidado.
func (h *Handler) CancelarAmortizacao(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	var status string
	var journalEntryID *int64
	err = tx.QueryRow(r.Context(), `
		SELECT d.status, d.journal_entry_id
		  FROM contabilidade.depreciation_entries d
		  JOIN contabilidade.fixed_assets fa ON fa.id = d.fixed_asset_id
		 WHERE d.id=$1 AND fa.tenant_id=$2`, id, user.TenantID).Scan(&status, &journalEntryID)
	if err != nil {
		jsonErr(w, "Amortização não encontrada", http.StatusNotFound)
		return
	}
	if status != "processado" || journalEntryID == nil {
		jsonErr(w, "apenas amortizações processadas podem ser canceladas", http.StatusConflict)
		return
	}

	if _, _, err := estornarLancamentoTx(r.Context(), tx, user.TenantID, user.ID, *journalEntryID); err != nil {
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

	if _, err := tx.Exec(r.Context(), `
		UPDATE contabilidade.depreciation_entries SET status='cancelado', updated_at=NOW()
		WHERE journal_entry_id=$1 AND tenant_id=$2`, *journalEntryID, user.TenantID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
