package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"slices"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ── Helpers internos ───────────────────────────────────────────────────────────

// moduloDependencias devolve as chaves que modulo requer directamente.
func moduloDependencias(ctx context.Context, db *pgxpool.Pool, modulo string) ([]string, error) {
	rows, err := db.Query(ctx,
		`SELECT requires FROM saas.module_dependencies WHERE modulo = $1`, modulo)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []string
	for rows.Next() {
		var r string
		if rows.Scan(&r) == nil {
			out = append(out, r)
		}
	}
	return out, rows.Err()
}

// modulosDependentes devolve os módulos activos do tenant que dependem de modulo.
func modulosDependentes(ctx context.Context, db *pgxpool.Pool, tenantID int64, modulo string) ([]string, error) {
	rows, err := db.Query(ctx, `
		SELECT d.modulo
		  FROM saas.module_dependencies d
		  JOIN saas.tenant_modules tm
		    ON tm.tenant_id = $1 AND tm.modulo = d.modulo AND tm.ativo = TRUE
		 WHERE d.requires = $2`, tenantID, modulo)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []string
	for rows.Next() {
		var m string
		if rows.Scan(&m) == nil {
			out = append(out, m)
		}
	}
	return out, rows.Err()
}

// resolverCascata calcula recursivamente todos os módulos que precisam de ser
// activados para que modulo possa funcionar (BFS sobre module_dependencies).
func resolverCascata(ctx context.Context, db *pgxpool.Pool, modulo string) ([]string, error) {
	visited := map[string]bool{modulo: true}
	queue := []string{modulo}
	var cascata []string

	for len(queue) > 0 {
		cur := queue[0]
		queue = queue[1:]

		deps, err := moduloDependencias(ctx, db, cur)
		if err != nil {
			return nil, err
		}
		for _, d := range deps {
			if !visited[d] {
				visited[d] = true
				cascata = append(cascata, d)
				queue = append(queue, d)
			}
		}
	}
	return cascata, nil
}

// ── Handlers HTTP ──────────────────────────────────────────────────────────────

// GET /api/superadmin/modules/dependencies
// Devolve o grafo completo de dependências do catálogo.
func (h *Handler) ListarDependencias(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(r.Context(),
		`SELECT modulo, requires FROM saas.module_dependencies ORDER BY modulo, requires`)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Edge struct {
		Modulo   string `json:"modulo"`
		Requires string `json:"requires"`
	}
	data := []Edge{}
	for rows.Next() {
		var e Edge
		if rows.Scan(&e.Modulo, &e.Requires) == nil {
			data = append(data, e)
		}
	}
	jsonOK(w, data, http.StatusOK)
}

// POST /api/superadmin/modules/dependencies
// Corpo: { "modulo": "x", "requires": "y" }
func (h *Handler) AdicionarDependencia(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Modulo   string `json:"modulo"`
		Requires string `json:"requires"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Modulo == "" || body.Requires == "" {
		jsonErr(w, "modulo e requires são obrigatórios", http.StatusBadRequest)
		return
	}
	if body.Modulo == body.Requires {
		jsonErr(w, "Um módulo não pode depender de si próprio", http.StatusBadRequest)
		return
	}

	// Detectar ciclo: se requires já depende de modulo transitivamente, há ciclo.
	cascata, err := resolverCascata(r.Context(), h.db, body.Requires)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if slices.Contains(cascata, body.Modulo) {
		jsonErr(w, "Esta dependência criaria um ciclo no grafo", http.StatusConflict)
		return
	}

	_, err = h.db.Exec(r.Context(),
		`INSERT INTO saas.module_dependencies (modulo, requires) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
		body.Modulo, body.Requires)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// DELETE /api/superadmin/modules/dependencies/{modulo}/{requires}
func (h *Handler) RemoverDependencia(w http.ResponseWriter, r *http.Request) {
	modulo := chi.URLParam(r, "modulo")
	requires := chi.URLParam(r, "requires")

	tag, err := h.db.Exec(r.Context(),
		`DELETE FROM saas.module_dependencies WHERE modulo = $1 AND requires = $2`, modulo, requires)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Dependência não encontrada", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
