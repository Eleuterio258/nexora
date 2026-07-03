package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"

	"nexora/config"
	mw "nexora/internal/middleware"
	"nexora/internal/storage"
)

func decodeJSON(r *http.Request, v any) error {
	return json.NewDecoder(r.Body).Decode(v)
}

type Handler struct {
	db      *pgxpool.Pool
	cfg     *config.Config
	storage storage.Provider
}

func New(db *pgxpool.Pool, cfg *config.Config, st storage.Provider) *Handler {
	return &Handler{db: db, cfg: cfg, storage: st}
}

func jsonOK(w http.ResponseWriter, v any, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func jsonErr(w http.ResponseWriter, msg string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}

// funcionarioID devolve o id do funcionário associado ao utilizador autenticado.
func (h *Handler) funcionarioID(r *http.Request) (int64, bool) {
	user := mw.GetUser(r)
	var id int64
	err := h.db.QueryRow(r.Context(),
		`SELECT id FROM rh.funcionarios WHERE user_id=$1 AND tenant_id=$2`,
		user.ID, user.TenantID).Scan(&id)
	return id, err == nil
}
