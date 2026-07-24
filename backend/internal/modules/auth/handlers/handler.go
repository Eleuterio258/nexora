package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
	"nexora/internal/push"
)

type Handler struct {
	db   *pgxpool.Pool
	cfg  *config.Config
	push *push.Service
}

func New(db *pgxpool.Pool, cfg *config.Config, pushSvc *push.Service) *Handler {
	return &Handler{db: db, cfg: cfg, push: pushSvc}
}

func jsonOK(w http.ResponseWriter, v interface{}, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func jsonErr(w http.ResponseWriter, msg string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}

func itoa(n int64) string {
	return fmt.Sprintf("%d", n)
}

// tenantFromHeader lê X-Tenant-ID do header — tenant_id nunca deve vir do body.
func tenantFromHeader(w http.ResponseWriter, r *http.Request) (int64, bool) {
	raw := r.Header.Get("X-Tenant-ID")
	if raw == "" {
		jsonErr(w, "header X-Tenant-ID é obrigatório", http.StatusBadRequest)
		return 0, false
	}
	var id int64
	if _, err := fmt.Sscanf(raw, "%d", &id); err != nil || id <= 0 {
		jsonErr(w, "X-Tenant-ID inválido", http.StatusBadRequest)
		return 0, false
	}
	return id, true
}

func isPgUniqueViolation(err error) bool {
	if pgErr, ok := err.(*pgconn.PgError); ok {
		return pgErr.Code == "23505"
	}
	return false
}

func isPgForeignKeyViolation(err error) bool {
	if pgErr, ok := err.(*pgconn.PgError); ok {
		return pgErr.Code == "23503"
	}
	return false
}
