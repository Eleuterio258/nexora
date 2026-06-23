package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
)

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

func nullIfEmpty(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func strDefault(s *string, def string) string {
	if s == nil {
		return def
	}
	v := strings.TrimSpace(*s)
	if v == "" {
		return def
	}
	return v
}

var dateFormatRe = regexp.MustCompile(`^\d{4}-\d{2}-\d{2}$`)

// parseDateOrNil valida e converte "YYYY-MM-DD" em *time.Time. Devolve ok=false se o formato for invalido.
func parseDateOrNil(s *string) (*time.Time, bool) {
	if s == nil || strings.TrimSpace(*s) == "" {
		return nil, true
	}
	if !dateFormatRe.MatchString(*s) {
		return nil, false
	}
	t, err := time.Parse("2006-01-02", *s)
	if err != nil {
		return nil, false
	}
	return &t, true
}

// parseDataAtividade aceita RFC3339 ou "YYYY-MM-DDTHH:MM" (formato de <input type="datetime-local">).
func parseDataAtividade(s string) (time.Time, error) {
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		return t, nil
	}
	if t, err := time.Parse("2006-01-02T15:04", s); err == nil {
		return t, nil
	}
	return time.Time{}, fmt.Errorf("formato de data inválido")
}
