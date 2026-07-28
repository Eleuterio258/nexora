package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
	"nexora/internal/shared/contracts"
	"nexora/internal/storage"
)

// DB define a interface minima de pool de BD usada pelo modulo.
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

func itoa(n int64) string { return fmt.Sprintf("%d", n) }

func isUniqueViolation(err error) bool {
	if pgErr, ok := err.(*pgconn.PgError); ok {
		return pgErr.Code == "23505"
	}
	return false
}

// empresaDoTenant verifica se a empresa com o ID fornecido pertence ao tenant.
// Devolve o ID da empresa e true se existir e pertencer ao tenant.
func (h *Handler) empresaDoTenant(ctx context.Context, companyID string, tenantID int64) (int64, bool) {
	var id int64
	err := h.db.QueryRow(ctx, `SELECT id FROM empresas.companies WHERE id = $1 AND tenant_id = $2`, companyID, tenantID).Scan(&id)
	return id, err == nil
}
