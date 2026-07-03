package handlers

import (
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgconn"
	mw "nexora/internal/middleware"
)

type flowResponse struct {
	ID        int64          `json:"id"`
	TenantID  int64          `json:"tenant_id"`
	Feature   string         `json:"feature"`
	Nome      string         `json:"nome"`
	Condicao  map[string]any `json:"condicao"`
	Niveis    []any          `json:"niveis"`
	Ativo     bool           `json:"ativo"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
}

// GET /api/aprovacoes/flows?feature=compras.requisicoes
func (h *Handler) ListarFlows(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	feature := r.URL.Query().Get("feature")

	query := `
		SELECT id, tenant_id, feature, nome, condicao, niveis, ativo, created_at, updated_at
		  FROM saas.approval_flows
		 WHERE tenant_id = $1`
	args := []any{user.TenantID}

	if feature != "" {
		args = append(args, feature)
		query += " AND feature = $2"
	}
	query += " ORDER BY feature, nome"

	rows, err := h.db.Query(r.Context(), query, args...)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	data := []flowResponse{}
	for rows.Next() {
		var f flowResponse
		if rows.Scan(&f.ID, &f.TenantID, &f.Feature, &f.Nome, &f.Condicao,
			&f.Niveis, &f.Ativo, &f.CreatedAt, &f.UpdatedAt) == nil {
			data = append(data, f)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// POST /api/aprovacoes/flows
// Corpo: { "feature": "compras.requisicoes", "nome": "Compras > 50k", "condicao": {...}, "niveis": [...] }
func (h *Handler) CriarFlow(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)

	var body struct {
		Feature  string         `json:"feature"`
		Nome     string         `json:"nome"`
		Condicao map[string]any `json:"condicao"`
		Niveis   []any          `json:"niveis"`
		Ativo    *bool          `json:"ativo"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Feature == "" || body.Nome == "" {
		jsonErr(w, "feature e nome são obrigatórios", http.StatusBadRequest)
		return
	}
	if len(body.Niveis) == 0 {
		jsonErr(w, "O fluxo deve ter pelo menos um nível de aprovação", http.StatusBadRequest)
		return
	}
	if body.Condicao == nil {
		body.Condicao = map[string]any{}
	}
	ativo := true
	if body.Ativo != nil {
		ativo = *body.Ativo
	}

	var f flowResponse
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO saas.approval_flows (tenant_id, feature, nome, condicao, niveis, ativo)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, tenant_id, feature, nome, condicao, niveis, ativo, created_at, updated_at`,
		user.TenantID, body.Feature, body.Nome, body.Condicao, body.Niveis, ativo).
		Scan(&f.ID, &f.TenantID, &f.Feature, &f.Nome, &f.Condicao, &f.Niveis, &f.Ativo, &f.CreatedAt, &f.UpdatedAt)
	if err != nil {
		if isPgUniqueViolation(err) {
			jsonErr(w, "Já existe um fluxo com este nome para esta feature", http.StatusConflict)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, f, http.StatusCreated)
}

// GET /api/aprovacoes/flows/{id}
func (h *Handler) ObterFlow(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var f flowResponse
	err := h.db.QueryRow(r.Context(), `
		SELECT id, tenant_id, feature, nome, condicao, niveis, ativo, created_at, updated_at
		  FROM saas.approval_flows
		 WHERE id = $1 AND tenant_id = $2`, id, user.TenantID).
		Scan(&f.ID, &f.TenantID, &f.Feature, &f.Nome, &f.Condicao, &f.Niveis, &f.Ativo, &f.CreatedAt, &f.UpdatedAt)
	if err != nil {
		jsonErr(w, "Fluxo não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, f, http.StatusOK)
}

// PUT /api/aprovacoes/flows/{id}
func (h *Handler) ActualizarFlow(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var body struct {
		Nome     *string        `json:"nome"`
		Condicao map[string]any `json:"condicao"`
		Niveis   []any          `json:"niveis"`
		Ativo    *bool          `json:"ativo"`
	}
	json.NewDecoder(r.Body).Decode(&body)

	var f flowResponse
	err := h.db.QueryRow(r.Context(), `
		UPDATE saas.approval_flows SET
		  nome      = COALESCE($1, nome),
		  condicao  = COALESCE($2, condicao),
		  niveis    = COALESCE($3, niveis),
		  ativo     = COALESCE($4, ativo),
		  updated_at = NOW()
		WHERE id = $5 AND tenant_id = $6
		RETURNING id, tenant_id, feature, nome, condicao, niveis, ativo, created_at, updated_at`,
		body.Nome, body.Condicao, body.Niveis, body.Ativo, id, user.TenantID).
		Scan(&f.ID, &f.TenantID, &f.Feature, &f.Nome, &f.Condicao, &f.Niveis, &f.Ativo, &f.CreatedAt, &f.UpdatedAt)
	if err != nil {
		jsonErr(w, "Fluxo não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, f, http.StatusOK)
}

// DELETE /api/aprovacoes/flows/{id}
func (h *Handler) EliminarFlow(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	// Bloquear se existem pedidos pendentes
	var pendentes int
	h.db.QueryRow(r.Context(),
		`SELECT COUNT(*) FROM saas.approval_requests WHERE flow_id = $1 AND estado = 'pendente'`, id).
		Scan(&pendentes)
	if pendentes > 0 {
		jsonErr(w, "Não é possível eliminar: existem pedidos de aprovação pendentes", http.StatusConflict)
		return
	}

	tag, err := h.db.Exec(r.Context(),
		`DELETE FROM saas.approval_flows WHERE id = $1 AND tenant_id = $2`, id, user.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Fluxo não encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func isPgUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
