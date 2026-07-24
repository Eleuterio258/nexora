package handlers

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"nexora/config"
	"nexora/internal/modules/assinatura-digital/pki"
	"nexora/internal/pkg/antivirus"
	"nexora/internal/shared/contracts"
	"nexora/internal/storage"
)

// DB define a interface mínima de pool de BD usada pelo módulo. Permite usar
// tanto *pgxpool.Pool (produção) como pgxmock (testes).
type DB interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

type Handler struct {
	db          DB
	cfg         *config.Config
	storage     storage.Provider
	notif       contracts.NotificationPort
	pdfSigner   *pki.PDFSigner
	sigProvider pki.SignatureProvider
	antivirus   antivirus.Verificador
}

func New(db DB, cfg *config.Config, st storage.Provider, notif contracts.NotificationPort, pdfSigner *pki.PDFSigner, sigProvider pki.SignatureProvider, av antivirus.Verificador) *Handler {
	return &Handler{db: db, cfg: cfg, storage: st, notif: notif, pdfSigner: pdfSigner, sigProvider: sigProvider, antivirus: av}
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
