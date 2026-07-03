package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

type cargoRow struct {
	ID              int64    `json:"id"`
	Codigo          string   `json:"codigo"`
	Nome            string   `json:"nome"`
	Descricao       *string  `json:"descricao"`
	SalarioMin      *float64 `json:"salario_min"`
	SalarioMax      *float64 `json:"salario_max"`
	Ativo           bool     `json:"ativo"`
	NumFuncionarios int      `json:"num_funcionarios"`
}

func (h *Handler) ListarCargos(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	rows, _ := h.db.Query(r.Context(), `
		SELECT c.id, c.codigo, c.nome, c.descricao, c.salario_min, c.salario_max, c.ativo,
		       (SELECT COUNT(*) FROM rh.funcionarios f WHERE f.cargo_id = c.id)
		  FROM rh.cargos c
		 WHERE c.tenant_id=$1
		 ORDER BY c.nome`, user.TenantID)
	defer rows.Close()
	data := []cargoRow{}
	for rows.Next() {
		var c cargoRow
		if rows.Scan(&c.ID, &c.Codigo, &c.Nome, &c.Descricao, &c.SalarioMin, &c.SalarioMax, &c.Ativo, &c.NumFuncionarios) == nil {
			data = append(data, c)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) CriarCargo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		Codigo     string   `json:"codigo"`
		Nome       string   `json:"nome"`
		Descricao  *string  `json:"descricao"`
		SalarioMin *float64 `json:"salario_min"`
		SalarioMax *float64 `json:"salario_max"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "código e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.SalarioMin != nil && body.SalarioMax != nil && *body.SalarioMax < *body.SalarioMin {
		jsonErr(w, "o salário máximo deve ser igual ou superior ao salário mínimo", http.StatusBadRequest)
		return
	}
	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO rh.cargos (tenant_id, codigo, nome, descricao, salario_min, salario_max)
		VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
		user.TenantID, body.Codigo, body.Nome, body.Descricao, body.SalarioMin, body.SalarioMax).Scan(&id)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um cargo com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) ActualizarCargo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var body struct {
		Codigo     *string  `json:"codigo"`
		Nome       *string  `json:"nome"`
		Descricao  *string  `json:"descricao"`
		SalarioMin *float64 `json:"salario_min"`
		SalarioMax *float64 `json:"salario_max"`
		Ativo      *bool    `json:"ativo"`
	}
	json.NewDecoder(r.Body).Decode(&body)
	if body.Codigo != nil && *body.Codigo == "" {
		jsonErr(w, "código não pode ser vazio", http.StatusBadRequest)
		return
	}
	if body.Nome != nil && *body.Nome == "" {
		jsonErr(w, "nome não pode ser vazio", http.StatusBadRequest)
		return
	}
	tag, err := h.db.Exec(r.Context(), `
		UPDATE rh.cargos SET
		  codigo=COALESCE($1,codigo), nome=COALESCE($2,nome), descricao=COALESCE($3,descricao),
		  salario_min=COALESCE($4,salario_min), salario_max=COALESCE($5,salario_max),
		  ativo=COALESCE($6,ativo), updated_at=NOW()
		WHERE id=$7 AND tenant_id=$8`,
		body.Codigo, body.Nome, body.Descricao, body.SalarioMin, body.SalarioMax, body.Ativo, id, user.TenantID)
	if err != nil {
		if isUniqueViolation(err) {
			jsonErr(w, "Já existe um cargo com este código", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Cargo não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoverCargo(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var temFuncionarios bool
	if err := h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM rh.funcionarios WHERE cargo_id=$1 AND tenant_id=$2)`, id, user.TenantID).Scan(&temFuncionarios); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if temFuncionarios {
		jsonErr(w, "Não é possível eliminar um cargo associado a funcionários", http.StatusConflict)
		return
	}

	tag, err := h.db.Exec(r.Context(), `DELETE FROM rh.cargos WHERE id=$1 AND tenant_id=$2`, id, user.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Cargo não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
