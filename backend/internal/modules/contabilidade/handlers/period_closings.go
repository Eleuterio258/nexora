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

type periodClosingRow struct {
	ID                     int64      `json:"id"`
	FiscalPeriodID         int64      `json:"fiscal_period_id"`
	Ano                    int        `json:"ano"`
	Mes                    int        `json:"mes"`
	Status                 string     `json:"status"`
	IniciadoPor            *int64     `json:"iniciado_por"`
	IniciadoEm             time.Time  `json:"iniciado_em"`
	EncerradoPor           *int64     `json:"encerrado_por"`
	EncerradoEm            *time.Time `json:"encerrado_em"`
	JustificacaoReabertura *string    `json:"justificacao_reabertura"`
}

const periodClosingSelect = `
	SELECT pc.id, pc.fiscal_period_id, p.ano, p.mes, pc.status, pc.iniciado_por, pc.iniciado_em,
	       pc.encerrado_por, pc.encerrado_em, pc.justificacao_reabertura
	  FROM contabilidade.period_closings pc
	  JOIN contabilidade.fiscal_periods p ON p.id = pc.fiscal_period_id
`

func scanPeriodClosings(rows pgx.Rows) []periodClosingRow {
	data := []periodClosingRow{}
	for rows.Next() {
		var pc periodClosingRow
		if rows.Scan(&pc.ID, &pc.FiscalPeriodID, &pc.Ano, &pc.Mes, &pc.Status, &pc.IniciadoPor, &pc.IniciadoEm,
			&pc.EncerradoPor, &pc.EncerradoEm, &pc.JustificacaoReabertura) == nil {
			data = append(data, pc)
		}
	}
	return data
}

type periodClosingCheckRow struct {
	ID           int64     `json:"id"`
	Verificacao  string    `json:"verificacao"`
	Passou       bool      `json:"passou"`
	Detalhe      *string   `json:"detalhe"`
	VerificadoEm time.Time `json:"verificado_em"`
}

func (h *Handler) ListarEncerramentos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "pc.tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("fiscal_period_id"); v != "" {
		args = append(args, v)
		where += " AND pc.fiscal_period_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("status"); v != "" {
		args = append(args, v)
		where += " AND pc.status=$" + strconv.Itoa(len(args))
	}
	rows, err := h.db.Query(r.Context(), periodClosingSelect+` WHERE `+where+` ORDER BY p.ano DESC, p.mes DESC`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	jsonOK(w, scanPeriodClosings(rows), http.StatusOK)
}

func (h *Handler) IniciarEncerramento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		FiscalPeriodID int64 `json:"fiscal_period_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.FiscalPeriodID == 0 {
		jsonErr(w, "fiscal_period_id é obrigatório", http.StatusBadRequest)
		return
	}

	var status string
	err := h.db.QueryRow(r.Context(), `SELECT status FROM contabilidade.fiscal_periods WHERE id=$1 AND tenant_id=$2`,
		body.FiscalPeriodID, user.TenantID).Scan(&status)
	if err == pgx.ErrNoRows {
		jsonErr(w, "Período fiscal não encontrado", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if status != "aberto" {
		jsonErr(w, "O período fiscal já está fechado", http.StatusConflict)
		return
	}

	var existe bool
	err = h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM contabilidade.period_closings
		               WHERE fiscal_period_id=$1 AND tenant_id=$2 AND status IN ('em_curso','verificado','encerrado'))`,
		body.FiscalPeriodID, user.TenantID).Scan(&existe)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if existe {
		jsonErr(w, "Já existe um processo de encerramento em curso para este período", http.StatusConflict)
		return
	}

	var id int64
	err = h.db.QueryRow(r.Context(), `
		INSERT INTO contabilidade.period_closings (tenant_id, fiscal_period_id, status, iniciado_por)
		VALUES ($1,$2,'em_curso',$3) RETURNING id`,
		user.TenantID, body.FiscalPeriodID, user.ID).Scan(&id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterEncerramento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	rows, err := h.db.Query(r.Context(), periodClosingSelect+` WHERE pc.id=$1 AND pc.tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	closings := scanPeriodClosings(rows)
	if len(closings) == 0 {
		jsonErr(w, "Encerramento não encontrado", http.StatusNotFound)
		return
	}

	checkRows, err := h.db.Query(r.Context(), `
		SELECT id, verificacao, passou, detalhe, verificado_em
		  FROM contabilidade.period_closing_checks
		 WHERE period_closing_id=$1
		 ORDER BY id`, id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer checkRows.Close()
	checks := []periodClosingCheckRow{}
	for checkRows.Next() {
		var c periodClosingCheckRow
		if checkRows.Scan(&c.ID, &c.Verificacao, &c.Passou, &c.Detalhe, &c.VerificadoEm) == nil {
			checks = append(checks, c)
		}
	}

	result := map[string]any{
		"id":                      closings[0].ID,
		"fiscal_period_id":        closings[0].FiscalPeriodID,
		"ano":                     closings[0].Ano,
		"mes":                     closings[0].Mes,
		"status":                  closings[0].Status,
		"iniciado_por":            closings[0].IniciadoPor,
		"iniciado_em":             closings[0].IniciadoEm,
		"encerrado_por":           closings[0].EncerradoPor,
		"encerrado_em":            closings[0].EncerradoEm,
		"justificacao_reabertura": closings[0].JustificacaoReabertura,
		"checks":                  checks,
	}
	jsonOK(w, result, http.StatusOK)
}

func (h *Handler) ExecutarVerificacoes(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var fiscalPeriodID int64
	var status string
	err := h.db.QueryRow(r.Context(), `
		SELECT fiscal_period_id, status FROM contabilidade.period_closings WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID).Scan(&fiscalPeriodID, &status)
	if err == pgx.ErrNoRows {
		jsonErr(w, "Encerramento não encontrado", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if status == "encerrado" {
		jsonErr(w, "Este encerramento já foi confirmado", http.StatusConflict)
		return
	}

	if _, err := h.db.Exec(r.Context(), `DELETE FROM contabilidade.period_closing_checks WHERE period_closing_id=$1`, id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	type checkDef struct {
		nome      string
		query     string
		ok, falha string
	}
	checks := []checkDef{
		{
			nome:  "lancamentos_balanceados",
			query: `SELECT COUNT(*) FROM contabilidade.journal_entries WHERE tenant_id=$1 AND fiscal_period_id=$2 AND status='publicado' AND total_debito <> total_credito`,
			ok:    "Todos os lançamentos publicados estão balanceados.",
			falha: "Existem lançamentos publicados com totais de débito e crédito diferentes.",
		},
		{
			nome:  "sem_rascunhos_pendentes",
			query: `SELECT COUNT(*) FROM contabilidade.journal_entries WHERE tenant_id=$1 AND fiscal_period_id=$2 AND status='rascunho'`,
			ok:    "Não existem lançamentos em rascunho.",
			falha: "Existem lançamentos em rascunho neste período.",
		},
		{
			nome:  "amortizacoes_processadas",
			query: `SELECT COUNT(*) FROM contabilidade.depreciation_entries WHERE tenant_id=$1 AND fiscal_period_id=$2 AND status='pendente'`,
			ok:    "Todas as amortizações deste período foram processadas.",
			falha: "Existem amortizações pendentes de processamento neste período.",
		},
	}

	allPassed := true
	results := []periodClosingCheckRow{}
	for _, c := range checks {
		var count int
		if err := h.db.QueryRow(r.Context(), c.query, user.TenantID, fiscalPeriodID).Scan(&count); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		passou := count == 0
		detalhe := c.ok
		if !passou {
			detalhe = c.falha
			allPassed = false
		}

		var check periodClosingCheckRow
		if err := h.db.QueryRow(r.Context(), `
			INSERT INTO contabilidade.period_closing_checks (period_closing_id, verificacao, passou, detalhe)
			VALUES ($1,$2,$3,$4) RETURNING id, verificacao, passou, detalhe, verificado_em`,
			id, c.nome, passou, detalhe).Scan(&check.ID, &check.Verificacao, &check.Passou, &check.Detalhe, &check.VerificadoEm); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		results = append(results, check)
	}

	novoStatus := "em_curso"
	if allPassed {
		novoStatus = "verificado"
	}
	if _, err := h.db.Exec(r.Context(), `UPDATE contabilidade.period_closings SET status=$1, updated_at=NOW() WHERE id=$2`, novoStatus, id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"id": id, "status": novoStatus, "checks": results}, http.StatusOK)
}

func (h *Handler) ConfirmarEncerramento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var fiscalPeriodID int64
	var status string
	err := h.db.QueryRow(r.Context(), `
		SELECT fiscal_period_id, status FROM contabilidade.period_closings WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID).Scan(&fiscalPeriodID, &status)
	if err == pgx.ErrNoRows {
		jsonErr(w, "Encerramento não encontrado", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if status != "verificado" {
		jsonErr(w, "É necessário executar as verificações com sucesso antes de encerrar", http.StatusConflict)
		return
	}

	var falhas int
	if err := h.db.QueryRow(r.Context(), `SELECT COUNT(*) FROM contabilidade.period_closing_checks WHERE period_closing_id=$1 AND NOT passou`, id).Scan(&falhas); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if falhas > 0 {
		jsonErr(w, "Existem verificações que não passaram", http.StatusConflict)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	if _, err := tx.Exec(r.Context(), `
		UPDATE contabilidade.period_closings SET status='encerrado', encerrado_por=$1, encerrado_em=NOW(), updated_at=NOW()
		WHERE id=$2`, user.ID, id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	tag, err := tx.Exec(r.Context(), `
		UPDATE contabilidade.fiscal_periods SET status='fechado', fechado_em=NOW(), fechado_por=$1
		WHERE id=$2 AND tenant_id=$3 AND status='aberto'`, user.ID, fiscalPeriodID, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "O período fiscal já está fechado", http.StatusConflict)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ReabrirEncerramento(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Justificacao string `json:"justificacao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Justificacao == "" {
		jsonErr(w, "A justificação é obrigatória", http.StatusBadRequest)
		return
	}

	var fiscalPeriodID int64
	var status string
	err := h.db.QueryRow(r.Context(), `
		SELECT fiscal_period_id, status FROM contabilidade.period_closings WHERE id=$1 AND tenant_id=$2`,
		id, user.TenantID).Scan(&fiscalPeriodID, &status)
	if err == pgx.ErrNoRows {
		jsonErr(w, "Encerramento não encontrado", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if status != "encerrado" {
		jsonErr(w, "Apenas encerramentos confirmados podem ser reabertos", http.StatusConflict)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	if _, err := tx.Exec(r.Context(), `
		UPDATE contabilidade.period_closings SET status='reaberto', justificacao_reabertura=$1, updated_at=NOW()
		WHERE id=$2`, body.Justificacao, id); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if _, err := tx.Exec(r.Context(), `
		UPDATE contabilidade.fiscal_periods SET status='aberto', fechado_em=NULL, fechado_por=NULL
		WHERE id=$1 AND tenant_id=$2`, fiscalPeriodID, user.TenantID); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
