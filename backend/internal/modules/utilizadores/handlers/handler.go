package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
	"nexora/internal/storage"
)

// NotificationHub permite ao handler empurrar eventos WS aos utilizadores.
type NotificationHub interface {
	SendToUser(userID int64, payload []byte)
}

type Handler struct {
	db      *pgxpool.Pool
	cfg     *config.Config
	storage storage.Provider
	hub     NotificationHub
}

func New(db *pgxpool.Pool, cfg *config.Config, st storage.Provider, hub NotificationHub) *Handler {
	return &Handler{db: db, cfg: cfg, storage: st, hub: hub}
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

func itoa(n int64) string { return fmt.Sprintf("%d", n) }

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
