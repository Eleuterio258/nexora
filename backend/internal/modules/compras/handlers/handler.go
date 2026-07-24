package handlers

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"nexora/config"
	"nexora/internal/shared/contracts"
	"nexora/internal/storage"
)

// DB define a interface mínima de pool de BD usada pelo módulo.
type DB interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
	Begin(ctx context.Context) (pgx.Tx, error)
}

type Handler struct {
	db        DB
	cfg       *config.Config
	storage   storage.Provider
	signature contracts.SignaturePort
}

func New(db DB, cfg *config.Config, st storage.Provider, signature contracts.SignaturePort) *Handler {
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
