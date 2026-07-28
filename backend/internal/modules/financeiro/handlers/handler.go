package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
)

func (h *Handler) existeNoTenant(ctx context.Context, tabela, colunaID string, id any, tenantID int64) bool {
	var um int
	query := fmt.Sprintf("SELECT 1 FROM %s WHERE %s=$1 AND tenant_id=$2", tabela, colunaID)
	err := h.db.QueryRow(ctx, query, id, tenantID).Scan(&um)
	return err == nil
}

type Handler struct {
	db  *pgxpool.Pool
	cfg *config.Config
}

func New(db *pgxpool.Pool, cfg *config.Config) *Handler {
	return &Handler{db: db, cfg: cfg}
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
