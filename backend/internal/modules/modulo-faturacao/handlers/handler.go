package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

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
	db           DB
	cfg          *config.Config
	storage      storage.Provider
	signature    contracts.SignaturePort
	accounting   contracts.AccountingPort
	legalAudit   contracts.LegalAuditPort
	notification contracts.NotificationPort
}

func New(db DB, cfg *config.Config, st storage.Provider, signature contracts.SignaturePort, accounting contracts.AccountingPort, legalAudit contracts.LegalAuditPort, notification contracts.NotificationPort) *Handler {
	return &Handler{db: db, cfg: cfg, storage: st, signature: signature, accounting: accounting, legalAudit: legalAudit, notification: notification}
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

// existeNoTenant verifica se um registro existe numa tabela filtrada por tenant_id.
// Nomes de tabela são controlados internamente (nunca vindos do cliente).
func (h *Handler) existeNoTenant(ctx context.Context, tabela, colunaID string, id any, tenantID int64) bool {
	var um int
	query := fmt.Sprintf("SELECT 1 FROM %s WHERE %s=$1 AND tenant_id=$2", tabela, colunaID)
	err := h.db.QueryRow(ctx, query, id, tenantID).Scan(&um)
	return err == nil
}
