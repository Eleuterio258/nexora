package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

type taxTransactionRow struct {
	ID              int64     `json:"id"`
	TaxID           int64     `json:"tax_id"`
	ReferenciaTipo  string    `json:"referencia_tipo"`
	ReferenciaID    *int64    `json:"referencia_id"`
	FiscalPeriodID  *int64    `json:"fiscal_period_id"`
	BaseTributavel  float64   `json:"base_tributavel"`
	TaxaAplicada    float64   `json:"taxa_aplicada"`
	ValorImposto    float64   `json:"valor_imposto"`
	TransactionDate time.Time `json:"transaction_date"`
	CreatedAt       time.Time `json:"created_at"`
}

const taxTransactionSelect = `
	SELECT tt.id, tt.tax_id, tt.referencia_tipo, tt.referencia_id, tt.fiscal_period_id,
	       tt.base_tributavel, tt.taxa_aplicada, tt.valor_imposto, tt.transaction_date, tt.created_at
	  FROM impostos.tax_transactions tt`

func scanTaxTransaction(row pgx.Row) (taxTransactionRow, error) {
	var t taxTransactionRow
	err := row.Scan(&t.ID, &t.TaxID, &t.ReferenciaTipo, &t.ReferenciaID, &t.FiscalPeriodID,
		&t.BaseTributavel, &t.TaxaAplicada, &t.ValorImposto, &t.TransactionDate, &t.CreatedAt)
	return t, err
}

func (h *Handler) ListarTransacoesImposto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	limit, offset := pageParams(r)
	where := "tt.tenant_id=$1"
	args := []any{user.TenantID}
	for _, f := range []string{"tax_id", "referencia_tipo", "fiscal_period_id"} {
		if v := q.Get(f); v != "" {
			args = append(args, v)
			where += " AND tt." + f + "=$" + strconv.Itoa(len(args))
		}
	}
	args = append(args, limit, offset)
	n := len(args)

	rows, err := h.db.Query(r.Context(), taxTransactionSelect+
		` WHERE `+where+
		` ORDER BY tt.transaction_date DESC, tt.id DESC LIMIT $`+strconv.Itoa(n-1)+` OFFSET $`+strconv.Itoa(n), args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data := []taxTransactionRow{}
	for rows.Next() {
		t, err := scanTaxTransaction(rows)
		if err == nil {
			data = append(data, t)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) ObterTransacaoImposto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	t, err := scanTaxTransaction(h.db.QueryRow(r.Context(), taxTransactionSelect+
		` tt JOIN impostos.taxes tx ON tx.id=tt.tax_id WHERE tt.id=$1 AND tx.tenant_id=$2`, id, user.TenantID))
	if err != nil {
		jsonErr(w, "Transação de imposto não encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, t, http.StatusOK)
}

func (h *Handler) RegistarTransacaoImposto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		TaxID           int64    `json:"tax_id"`
		ReferenciaTipo  string   `json:"referencia_tipo"`
		ReferenciaID    *int64   `json:"referencia_id"`
		FiscalPeriodID  *int64   `json:"fiscal_period_id"`
		BaseTributavel  float64  `json:"base_tributavel"`
		TaxaAplicada    *float64 `json:"taxa_aplicada"`
		TransactionDate string   `json:"transaction_date"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil ||
		body.TaxID == 0 || body.ReferenciaTipo == "" || body.TransactionDate == "" {
		jsonErr(w, "tax_id, referencia_tipo e transaction_date são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.BaseTributavel < 0 {
		jsonErr(w, "base_tributavel não pode ser negativa", http.StatusBadRequest)
		return
	}

	var taxaPadrao float64
	if err := h.db.QueryRow(r.Context(), `SELECT taxa FROM impostos.taxes WHERE id=$1 AND tenant_id=$2`,
		body.TaxID, user.TenantID).Scan(&taxaPadrao); err != nil {
		jsonErr(w, "Taxa não encontrada", http.StatusNotFound)
		return
	}

	taxaAplicada := taxaPadrao
	if body.TaxaAplicada != nil {
		taxaAplicada = *body.TaxaAplicada
	} else {
		rows, err := h.db.Query(r.Context(), `
			SELECT valor_minimo, valor_maximo, taxa FROM impostos.tax_rules
			 WHERE tax_id=$1 ORDER BY valor_minimo`, body.TaxID)
		if err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		for rows.Next() {
			var min, taxa float64
			var max *float64
			if rows.Scan(&min, &max, &taxa) != nil {
				continue
			}
			if body.BaseTributavel >= min && (max == nil || body.BaseTributavel < *max) {
				taxaAplicada = taxa
			}
		}
		rows.Close()
	}
	if taxaAplicada < 0 {
		jsonErr(w, "a taxa aplicada não pode ser negativa", http.StatusBadRequest)
		return
	}

	valorImposto := body.BaseTributavel * taxaAplicada / 100

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO impostos.tax_transactions
		    (tenant_id, tax_id, referencia_tipo, referencia_id, fiscal_period_id,
		     base_tributavel, taxa_aplicada, valor_imposto, transaction_date)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING id`,
		user.TenantID, body.TaxID, body.ReferenciaTipo, body.ReferenciaID, body.FiscalPeriodID,
		body.BaseTributavel, taxaAplicada, valorImposto, body.TransactionDate).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id, "taxa_aplicada": taxaAplicada, "valor_imposto": valorImposto}, http.StatusCreated)
}
