package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"nexora/internal/middleware"
)

// ListarIPAllowlist devolve os CIDRs autorizados para acesso de superadmin.
func (h *Handler) ListarIPAllowlist(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(r.Context(), `
		SELECT id, ip_cidr::text, descricao, ativo, created_at
		  FROM auth.superadmin_ip_allowlist
		 ORDER BY created_at DESC`)
	if err != nil {
		middleware.JSONErr(w, "Erro ao obter allowlist", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var result []map[string]any
	for rows.Next() {
		var id int64
		var cidr, descricao string
		var ativo bool
		var createdAt time.Time
		if err := rows.Scan(&id, &cidr, &descricao, &ativo, &createdAt); err != nil {
			continue
		}
		result = append(result, map[string]any{
			"id":         id,
			"ip_cidr":    cidr,
			"descricao":  descricao,
			"ativo":      ativo,
			"created_at": createdAt,
		})
	}
	if result == nil {
		result = []map[string]any{}
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(result)
}

// CriarIPAllowlist adiciona um novo CIDR à allowlist de superadmin.
func (h *Handler) CriarIPAllowlist(w http.ResponseWriter, r *http.Request) {
	user := middleware.GetUser(r)
	var body struct {
		IPCIDR    string `json:"ip_cidr"`
		Descricao string `json:"descricao"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.IPCIDR == "" {
		middleware.JSONErr(w, "ip_cidr é obrigatório", http.StatusBadRequest)
		return
	}

	var id int64
	err := h.db.QueryRow(r.Context(), `
		INSERT INTO auth.superadmin_ip_allowlist (ip_cidr, descricao, created_by)
		VALUES ($1::inet, $2, $3)
		RETURNING id`,
		body.IPCIDR, body.Descricao, user.ID,
	).Scan(&id)
	if err != nil {
		middleware.JSONErr(w, "Erro ao criar entrada", http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]any{"id": id})
}

// RemoverIPAllowlist inativa (remove logicamente) uma entrada da allowlist.
func (h *Handler) RemoverIPAllowlist(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		middleware.JSONErr(w, "ID inválido", http.StatusBadRequest)
		return
	}

	_, err = h.db.Exec(r.Context(), `
		UPDATE auth.superadmin_ip_allowlist SET ativo = false WHERE id = $1`, id)
	if err != nil {
		middleware.JSONErr(w, "Erro ao remover entrada", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
