package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
	"nexora/internal/modules/recursos-humanos/service/assiduidade"
	"nexora/internal/storage"
)

type Handler struct {
	db          *pgxpool.Pool
	cfg         *config.Config
	storage     storage.Provider
	assiduidade *assiduidade.Service
}

func New(db *pgxpool.Pool, cfg *config.Config, st storage.Provider) *Handler {
	return &Handler{db: db, cfg: cfg, storage: st, assiduidade: assiduidade.NewService(db)}
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

func isUniqueViolation(err error) bool {
	if pgErr, ok := err.(*pgconn.PgError); ok {
		return pgErr.Code == "23505"
	}
	return false
}

// uniqueViolationConstraint devolve o nome da constraint/índice violado quando
// err for um erro de violação de unicidade (23505), ou "" caso contrário.
func uniqueViolationConstraint(err error) string {
	if pgErr, ok := err.(*pgconn.PgError); ok && pgErr.Code == "23505" {
		return pgErr.ConstraintName
	}
	return ""
}
