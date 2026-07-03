package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
)

type planResponse struct {
	ID            int64          `json:"id"`
	Codigo        string         `json:"codigo"`
	Nome          string         `json:"nome"`
	Descricao     *string        `json:"descricao"`
	PrecoMensal   float64        `json:"preco_mensal"`
	PrecoAnual    float64        `json:"preco_anual"`
	Moeda         string         `json:"moeda"`
	Limites       map[string]any `json:"limites"`
	Ativo         bool           `json:"ativo"`
	CreatedAt     time.Time      `json:"created_at"`
	UpdatedAt     time.Time      `json:"updated_at"`
}

func (h *Handler) ListarPlanos(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	ativo := q.Get("ativo")

	where := "1=1"
	args := []interface{}{}
	if ativo != "" {
		args = append(args, ativo == "true")
		where += " AND ativo = $" + strconv.Itoa(len(args))
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT id, codigo, nome, descricao, preco_mensal, preco_anual, moeda, limites, ativo, created_at, updated_at
		  FROM saas.plans
		 WHERE `+where+`
		 ORDER BY nome ASC`, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []planResponse{}
	for rows.Next() {
		var p planResponse
		if err := rows.Scan(&p.ID, &p.Codigo, &p.Nome, &p.Descricao, &p.PrecoMensal, &p.PrecoAnual,
			&p.Moeda, &p.Limites, &p.Ativo, &p.CreatedAt, &p.UpdatedAt); err == nil {
			data = append(data, p)
		}
	}

	jsonOK(w, data, http.StatusOK)
}

func (h *Handler) ObterPlano(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var p planResponse
	err := h.db.QueryRow(r.Context(), `
		SELECT id, codigo, nome, descricao, preco_mensal, preco_anual, moeda, limites, ativo, created_at, updated_at
		  FROM saas.plans
		 WHERE id = $1`, id).
		Scan(&p.ID, &p.Codigo, &p.Nome, &p.Descricao, &p.PrecoMensal, &p.PrecoAnual,
			&p.Moeda, &p.Limites, &p.Ativo, &p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		jsonErr(w, "Plano não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, p, http.StatusOK)
}

func (h *Handler) CriarPlano(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Codigo        string         `json:"codigo"`
		Nome          string         `json:"nome"`
		Descricao     *string        `json:"descricao"`
		PrecoMensal   float64        `json:"preco_mensal"`
		PrecoAnual    float64        `json:"preco_anual"`
		Moeda         string         `json:"moeda"`
		Limites       map[string]any `json:"limites"`
		Ativo         *bool          `json:"ativo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Codigo == "" || body.Nome == "" {
		jsonErr(w, "codigo e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.Moeda == "" { body.Moeda = "MZN" }
	if body.Ativo == nil { b := true; body.Ativo = &b }

	var p planResponse
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO saas.plans (codigo, nome, descricao, preco_mensal, preco_anual, moeda, limites, ativo)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, codigo, nome, descricao, preco_mensal, preco_anual, moeda, limites, ativo, created_at, updated_at`,
		body.Codigo, body.Nome, body.Descricao, body.PrecoMensal, body.PrecoAnual,
		body.Moeda, body.Limites, *body.Ativo).
		Scan(&p.ID, &p.Codigo, &p.Nome, &p.Descricao, &p.PrecoMensal, &p.PrecoAnual,
			&p.Moeda, &p.Limites, &p.Ativo, &p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		if isPgUniqueViolation(err) {
			jsonErr(w, "Código de plano já existe", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, p, http.StatusCreated)
}

func (h *Handler) ActualizarPlano(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	var body struct {
		Nome          *string        `json:"nome"`
		Descricao     *string        `json:"descricao"`
		PrecoMensal   *float64       `json:"preco_mensal"`
		PrecoAnual    *float64       `json:"preco_anual"`
		Moeda         *string        `json:"moeda"`
		Limites       map[string]any `json:"limites"`
		Ativo         *bool          `json:"ativo"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	var p planResponse
	err := h.db.QueryRow(r.Context(), `
		UPDATE saas.plans SET
			nome = COALESCE($1, nome),
			descricao = COALESCE($2, descricao),
			preco_mensal = COALESCE($3, preco_mensal),
			preco_anual = COALESCE($4, preco_anual),
			moeda = COALESCE($5, moeda),
			limites = COALESCE($6, limites),
			ativo = COALESCE($7, ativo),
			updated_at = NOW()
		WHERE id = $8
		RETURNING id, codigo, nome, descricao, preco_mensal, preco_anual, moeda, limites, ativo, created_at, updated_at`,
		body.Nome, body.Descricao, body.PrecoMensal, body.PrecoAnual, body.Moeda,
		body.Limites, body.Ativo, id).
		Scan(&p.ID, &p.Codigo, &p.Nome, &p.Descricao, &p.PrecoMensal, &p.PrecoAnual,
			&p.Moeda, &p.Limites, &p.Ativo, &p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		jsonErr(w, "Plano não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, p, http.StatusOK)
}

func (h *Handler) EliminarPlano(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	tag, err := h.db.Exec(r.Context(), `DELETE FROM saas.plans WHERE id = $1`, id)
	if err != nil {
		jsonErr(w, "Erro ao eliminar plano", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Plano não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]string{"message": "Plano eliminado"}, http.StatusOK)
}

// GET /api/superadmin/plans/{id}/modules
// Lista os módulos incluídos no plano (com info do catálogo).
func (h *Handler) ListarModulosPlano(w http.ResponseWriter, r *http.Request) {
	planID := chi.URLParam(r, "id")

	// Verificar que o plano existe
	var exists bool
	h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM saas.plans WHERE id = $1)`, planID).Scan(&exists)
	if !exists {
		jsonErr(w, "Plano não encontrado", http.StatusNotFound)
		return
	}

	rows, err := h.db.Query(r.Context(), `
		SELECT mc.key, mc.nome, mc.categoria,
		       (pm.plan_id IS NOT NULL) AS incluido
		  FROM saas.module_catalog mc
		  LEFT JOIN saas.plan_modules pm ON pm.plan_id = $1 AND pm.modulo = mc.key
		 WHERE mc.ativo = TRUE
		 ORDER BY mc.categoria, mc.nome`, planID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Row struct {
		Key       string `json:"key"`
		Nome      string `json:"nome"`
		Categoria string `json:"categoria"`
		Incluido  bool   `json:"incluido"`
	}
	data := []Row{}
	for rows.Next() {
		var r Row
		if rows.Scan(&r.Key, &r.Nome, &r.Categoria, &r.Incluido) == nil {
			data = append(data, r)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// PUT /api/superadmin/plans/{id}/modules
// Substitui completamente a lista de módulos do plano.
// Corpo: { "modulos": ["clientes", "faturacao", ...] }
func (h *Handler) DefinirModulosPlano(w http.ResponseWriter, r *http.Request) {
	planID, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "id inválido", http.StatusBadRequest)
		return
	}

	var body struct {
		Modulos []string `json:"modulos"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Payload inválido", http.StatusBadRequest)
		return
	}

	var exists bool
	h.db.QueryRow(r.Context(), `SELECT EXISTS(SELECT 1 FROM saas.plans WHERE id = $1)`, planID).Scan(&exists)
	if !exists {
		jsonErr(w, "Plano não encontrado", http.StatusNotFound)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	tx.Exec(r.Context(), `DELETE FROM saas.plan_modules WHERE plan_id = $1`, planID)

	for _, mod := range body.Modulos {
		if mod == "" {
			continue
		}
		tx.Exec(r.Context(),
			`INSERT INTO saas.plan_modules (plan_id, modulo) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
			planID, mod)
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro ao guardar", http.StatusInternalServerError)
		return
	}

	h.ListarModulosPlano(w, r)
}
