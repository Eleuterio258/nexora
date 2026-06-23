package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

type contaRow struct {
	ID               int64   `json:"id"`
	ParentID         *int64  `json:"parent_id"`
	Codigo           string  `json:"codigo"`
	Nome             string  `json:"nome"`
	AccountTypeID    *int64  `json:"account_type_id"`
	AccountTypeNome  *string `json:"account_type_nome"`
	Classe           *string `json:"classe"`
	Natureza         *string `json:"natureza"`
	AceitaLancamento bool    `json:"aceita_lancamento"`
	Ativo            bool    `json:"ativo"`
}

const contaSelect = `
	SELECT c.id, c.parent_id, c.codigo, c.nome, c.account_type_id, t.nome, t.classe, t.natureza, c.aceita_lancamento, c.ativo
	  FROM contabilidade.chart_of_accounts c
	  LEFT JOIN contabilidade.account_types t ON t.id = c.account_type_id
`

func scanContas(rows pgx.Rows) []contaRow {
	data := []contaRow{}
	for rows.Next() {
		var c contaRow
		if rows.Scan(&c.ID, &c.ParentID, &c.Codigo, &c.Nome, &c.AccountTypeID, &c.AccountTypeNome, &c.Classe, &c.Natureza, &c.AceitaLancamento, &c.Ativo) == nil {
			data = append(data, c)
		}
	}
	return data
}

func (h *Handler) ListarContas(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "c.tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("account_type_id"); v != "" {
		args = append(args, v)
		where += " AND c.account_type_id=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("aceita_lancamento"); v != "" {
		args = append(args, v == "true")
		where += " AND c.aceita_lancamento=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("ativo"); v != "" {
		args = append(args, v == "true")
		where += " AND c.ativo=$" + strconv.Itoa(len(args))
	}
	rows, err := h.db.Query(r.Context(), contaSelect+` WHERE `+where+` ORDER BY c.codigo`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	jsonOK(w, scanContas(rows), http.StatusOK)
}

func (h *Handler) CriarConta(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		ParentID         *int64 `json:"parent_id"`
		Codigo           string `json:"codigo"`
		Nome             string `json:"nome"`
		AccountTypeID    *int64 `json:"account_type_id"`
		AceitaLancamento *bool  `json:"aceita_lancamento"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO contabilidade.chart_of_accounts (tenant_id,parent_id,codigo,nome,account_type_id,aceita_lancamento)
		VALUES ($1,$2,$3,$4,$5,COALESCE($6,true)) RETURNING id`,
		user.TenantID, body.ParentID, body.Codigo, body.Nome, body.AccountTypeID, body.AceitaLancamento).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ObterConta(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	rows, err := h.db.Query(r.Context(), contaSelect+` WHERE c.id=$1 AND c.tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	contas := scanContas(rows)
	rows.Close()
	if len(contas) == 0 {
		jsonErr(w, "Conta não encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, contas[0], http.StatusOK)
}

func (h *Handler) ActualizarConta(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		ParentID         *int64  `json:"parent_id"`
		Codigo           *string `json:"codigo"`
		Nome             *string `json:"nome"`
		AccountTypeID    *int64  `json:"account_type_id"`
		AceitaLancamento *bool   `json:"aceita_lancamento"`
		Ativo            *bool   `json:"ativo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE contabilidade.chart_of_accounts SET
		  parent_id=COALESCE($1,parent_id), codigo=COALESCE($2,codigo), nome=COALESCE($3,nome),
		  account_type_id=COALESCE($4,account_type_id), aceita_lancamento=COALESCE($5,aceita_lancamento),
		  ativo=COALESCE($6,ativo), updated_at=NOW()
		WHERE id=$7 AND tenant_id=$8`,
		body.ParentID, body.Codigo, body.Nome, body.AccountTypeID, body.AceitaLancamento, body.Ativo, id, user.TenantID)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Conta não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) EliminarConta(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var temFilhos, temLancamentos bool
	err := h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM contabilidade.chart_of_accounts WHERE parent_id=$1 AND tenant_id=$2),
		       EXISTS(SELECT 1 FROM contabilidade.journal_entry_lines WHERE account_id=$1)`,
		id, user.TenantID).Scan(&temFilhos, &temLancamentos)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if temFilhos || temLancamentos {
		jsonErr(w, "Não é possível eliminar uma conta com sub-contas ou lançamentos associados", http.StatusConflict)
		return
	}
	tag, err := h.db.Exec(r.Context(), `DELETE FROM contabilidade.chart_of_accounts WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Conta não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
