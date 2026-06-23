package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

var classesContaValidas = map[string]bool{
	"ativo": true, "passivo": true, "capital": true, "rendimento": true, "gasto": true,
}

var naturezasContaValidas = map[string]bool{
	"devedora": true, "credora": true,
}

type accountTypeRow struct {
	ID       int64  `json:"id"`
	Codigo   string `json:"codigo"`
	Nome     string `json:"nome"`
	Classe   string `json:"classe"`
	Natureza string `json:"natureza"`
	Ativo    bool   `json:"ativo"`
}

func (h *Handler) ListarTiposConta(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("classe"); v != "" {
		args = append(args, v)
		where += " AND classe=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("ativo"); v != "" {
		args = append(args, v == "true")
		where += " AND ativo=$" + strconv.Itoa(len(args))
	}
	rows, err := h.db.Query(r.Context(), `SELECT id, codigo, nome, classe, natureza, ativo FROM contabilidade.account_types WHERE `+where+` ORDER BY codigo`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	data := []accountTypeRow{}
	for rows.Next() {
		var t accountTypeRow
		if rows.Scan(&t.ID, &t.Codigo, &t.Nome, &t.Classe, &t.Natureza, &t.Ativo) == nil {
			data = append(data, t)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarTipoConta(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo   string `json:"codigo"`
		Nome     string `json:"nome"`
		Classe   string `json:"classe"`
		Natureza string `json:"natureza"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	if !classesContaValidas[body.Classe] {
		jsonErr(w, "classe inválida", http.StatusBadRequest)
		return
	}
	if !naturezasContaValidas[body.Natureza] {
		jsonErr(w, "natureza inválida", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO contabilidade.account_types (tenant_id,codigo,nome,classe,natureza)
		VALUES ($1,$2,$3,$4,$5) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Classe, body.Natureza).Scan(&id)
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

func (h *Handler) ObterTipoConta(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var t accountTypeRow
	err := h.db.QueryRow(r.Context(), `SELECT id, codigo, nome, classe, natureza, ativo FROM contabilidade.account_types WHERE id=$1 AND tenant_id=$2`, id, user.TenantID).
		Scan(&t.ID, &t.Codigo, &t.Nome, &t.Classe, &t.Natureza, &t.Ativo)
	if err != nil {
		jsonErr(w, "Tipo de conta não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, t, http.StatusOK)
}

func (h *Handler) ActualizarTipoConta(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Codigo   *string `json:"codigo"`
		Nome     *string `json:"nome"`
		Classe   *string `json:"classe"`
		Natureza *string `json:"natureza"`
		Ativo    *bool   `json:"ativo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	if body.Classe != nil && !classesContaValidas[*body.Classe] {
		jsonErr(w, "classe inválida", http.StatusBadRequest)
		return
	}
	if body.Natureza != nil && !naturezasContaValidas[*body.Natureza] {
		jsonErr(w, "natureza inválida", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE contabilidade.account_types SET
		  codigo=COALESCE($1,codigo), nome=COALESCE($2,nome), classe=COALESCE($3,classe),
		  natureza=COALESCE($4,natureza), ativo=COALESCE($5,ativo)
		WHERE id=$6 AND tenant_id=$7`,
		body.Codigo, body.Nome, body.Classe, body.Natureza, body.Ativo, id, user.TenantID)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Tipo de conta não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) EliminarTipoConta(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var emUso bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM contabilidade.chart_of_accounts WHERE account_type_id=$1 AND tenant_id=$2)`, id, user.TenantID).Scan(&emUso); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if emUso {
		jsonErr(w, "Tipo de conta está associado a contas do plano de contas", http.StatusConflict)
		return
	}
	tag, err := h.db.Exec(r.Context(), `DELETE FROM contabilidade.account_types WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Tipo de conta não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
