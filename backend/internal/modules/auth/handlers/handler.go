package handlers

import (
	"encoding/json"
	"net/http"

	"nexora/config"
	"nexora/internal/modules/auth/oauthkeys"
	"nexora/internal/push"
	"nexora/internal/shared/contracts"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Handler struct {
	db         *pgxpool.Pool
	cfg        *config.Config
	push       *push.Service
	oauthKeys  *oauthkeys.Provider
	notif      contracts.NotificationPort
	legalAudit contracts.LegalAuditPort
}

func New(db *pgxpool.Pool, cfg *config.Config, pushSvc *push.Service, oauthKeys *oauthkeys.Provider, notif contracts.NotificationPort, legalAudit contracts.LegalAuditPort) *Handler {
	return &Handler{db: db, cfg: cfg, push: pushSvc, oauthKeys: oauthKeys, notif: notif, legalAudit: legalAudit}
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
