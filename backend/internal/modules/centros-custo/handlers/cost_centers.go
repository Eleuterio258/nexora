package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
)

type costCenterRow struct {
	ID           int64  `json:"id"`
	ParentID     *int64 `json:"parent_id"`
	Codigo       string `json:"codigo"`
	Nome         string `json:"nome"`
	Tipo         string `json:"tipo"`
	GestorUserID *int64 `json:"gestor_user_id"`
	Activo       bool   `json:"activo"`
}

const costCenterSelect = `
	SELECT id, parent_id, codigo, nome, tipo, gestor_user_id, activo
	  FROM centros_custo.cost_centers
`

func scanCostCenters(rows pgx.Rows) []costCenterRow {
	data := []costCenterRow{}
	for rows.Next() {
		var c costCenterRow
		if rows.Scan(&c.ID, &c.ParentID, &c.Codigo, &c.Nome, &c.Tipo, &c.GestorUserID, &c.Activo) == nil {
			data = append(data, c)
		}
	}
	return data
}

func (h *Handler) ListarCentrosCusto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	q := r.URL.Query()
	where := "tenant_id=$1"
	args := []any{user.TenantID}
	if v := q.Get("tipo"); v != "" {
		args = append(args, v)
		where += " AND tipo=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("activo"); v != "" {
		args = append(args, v == "true")
		where += " AND activo=$" + strconv.Itoa(len(args))
	}
	if v := q.Get("parent_id"); v != "" {
		args = append(args, v)
		where += " AND parent_id=$" + strconv.Itoa(len(args))
	}
	rows, err := h.db.Query(r.Context(), costCenterSelect+` WHERE `+where+` ORDER BY codigo`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	jsonOK(w, scanCostCenters(rows), http.StatusOK)
}

func (h *Handler) CriarCentroCusto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		ParentID     *int64  `json:"parent_id"`
		Codigo       string  `json:"codigo"`
		Nome         string  `json:"nome"`
		Tipo         *string `json:"tipo"`
		GestorUserID *int64  `json:"gestor_user_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO centros_custo.cost_centers (tenant_id, parent_id, codigo, nome, tipo, gestor_user_id)
		VALUES ($1,$2,$3,$4,COALESCE($5,'centro'),$6) RETURNING id`,
		user.TenantID, body.ParentID, body.Codigo, body.Nome, body.Tipo, body.GestorUserID).Scan(&id)
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

func (h *Handler) ObterCentroCusto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	rows, err := h.db.Query(r.Context(), costCenterSelect+` WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	centros := scanCostCenters(rows)
	rows.Close()
	if len(centros) == 0 {
		jsonErr(w, "Centro de custo não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, centros[0], http.StatusOK)
}

func (h *Handler) ActualizarCentroCusto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		ParentID     *int64  `json:"parent_id"`
		Codigo       *string `json:"codigo"`
		Nome         *string `json:"nome"`
		Tipo         *string `json:"tipo"`
		GestorUserID *int64  `json:"gestor_user_id"`
		Activo       *bool   `json:"activo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE centros_custo.cost_centers SET
		  parent_id=COALESCE($1,parent_id), codigo=COALESCE($2,codigo), nome=COALESCE($3,nome),
		  tipo=COALESCE($4,tipo), gestor_user_id=COALESCE($5,gestor_user_id),
		  activo=COALESCE($6,activo), updated_at=NOW()
		WHERE id=$7 AND tenant_id=$8`,
		body.ParentID, body.Codigo, body.Nome, body.Tipo, body.GestorUserID, body.Activo, id, user.TenantID)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Código já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Centro de custo não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) EliminarCentroCusto(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var temFilhos, temOrcamentos, temAlocacoes bool
	err := h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM centros_custo.cost_centers WHERE parent_id=$1 AND tenant_id=$2),
		       EXISTS(SELECT 1 FROM centros_custo.cost_center_budgets WHERE cost_center_id=$1),
		       EXISTS(SELECT 1 FROM centros_custo.cost_center_allocations WHERE cost_center_id=$1)`,
		id, user.TenantID).Scan(&temFilhos, &temOrcamentos, &temAlocacoes)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if temFilhos || temOrcamentos || temAlocacoes {
		jsonErr(w, "Não é possível eliminar um centro de custo com sub-centros, orçamentos ou alocações associadas", http.StatusConflict)
		return
	}
	tag, err := h.db.Exec(r.Context(), `DELETE FROM centros_custo.cost_centers WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Centro de custo não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
