package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
	"nexora/internal/push"
	"nexora/internal/shared/contracts"
	"nexora/internal/ws"
)

type Handler struct {
	db         *pgxpool.Pool
	cfg        *config.Config
	wsHub      *ws.Hub
	push       *push.Service
	accounting contracts.AccountingPort
}

func New(db *pgxpool.Pool, cfg *config.Config, wsHub *ws.Hub, pushSvc *push.Service, accounting contracts.AccountingPort) *Handler {
	return &Handler{db: db, cfg: cfg, wsHub: wsHub, push: pushSvc, accounting: accounting}
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

func pageParams(r *http.Request) (limit, offset int) {
	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	limit, _ = strconv.Atoi(r.URL.Query().Get("limit"))
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset = (page - 1) * limit
	return
}

func isUniqueViolation(err error) bool {
	if pgErr, ok := err.(*pgconn.PgError); ok {
		return pgErr.Code == "23505"
	}
	return false
}
