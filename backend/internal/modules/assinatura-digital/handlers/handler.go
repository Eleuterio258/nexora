package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
	"nexora/internal/storage"
)

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
