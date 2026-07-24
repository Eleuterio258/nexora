package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
	"nexora/internal/shared/contracts"
	"nexora/internal/storage"
)

type Handler struct {
	db        *pgxpool.Pool
	cfg       *config.Config
	storage   storage.Provider
	signature contracts.SignaturePort
}

func New(db *pgxpool.Pool, cfg *config.Config, st storage.Provider, signature contracts.SignaturePort) *Handler {
	return &Handler{db: db, cfg: cfg, storage: st, signature: signature}
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
