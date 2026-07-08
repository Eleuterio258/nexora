package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"nexora/config"
	"nexora/internal/idhash"
	"nexora/internal/push"
	"nexora/internal/storage"
)

type Handler struct {
	db       *pgxpool.Pool
	cfg      *config.Config
	storage  storage.Provider
	push     *push.Service
	realtime *RealtimeServer
	idh      *idhash.Hasher
}

func New(db *pgxpool.Pool, cfg *config.Config, st storage.Provider, pushSvc *push.Service, realtime *RealtimeServer, idh *idhash.Hasher) *Handler {
	return &Handler{db: db, cfg: cfg, storage: st, push: pushSvc, realtime: realtime, idh: idh}
}

// decodeID resolve o parâmetro "{id}" de uma rota aninhada (ex.: /candidaturas/{id})
// para o inteiro real. O middleware global idh.Middleware() (router.go) não consegue
// decifrar estes parâmetros — o chi só os resolve dentro do handler final de um
// sub-router montado via r.Route(), depois de qualquer middleware (do próprio
// sub-router ou de fora) já ter corrido. Por isso a decodificação tem de acontecer
// aqui, explicitamente, em cada handler que lê "id" de uma rota aninhada.
func (h *Handler) decodeID(raw string) string {
	if _, err := strconv.ParseInt(raw, 10, 64); err == nil {
		return raw // já é um inteiro (ex.: chamada interna ou id não ofuscado)
	}
	if decoded, err := h.idh.Decode(raw); err == nil && decoded > 0 {
		return strconv.FormatInt(decoded, 10)
	}
	return raw
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

func isUniqueViolation(err error) bool {
	if pgErr, ok := err.(*pgconn.PgError); ok {
		return pgErr.Code == "23505"
	}
	return false
}

// filterList remove entradas vazias/em branco apos trim, replicando filterList() do vaga_save.php.
func filterList(items []string) []string {
	out := make([]string, 0, len(items))
	for _, it := range items {
		s := strings.TrimSpace(it)
		if s != "" {
			out = append(out, s)
		}
	}
	return out
}

func nullIfEmpty(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func parseOptionalInt(s string) *int {
	if s == "" {
		return nil
	}
	if v, err := strconv.Atoi(s); err == nil {
		return &v
	}
	return nil
}

func parseOptionalFloat(s string) *float64 {
	if s == "" {
		return nil
	}
	if v, err := strconv.ParseFloat(s, 64); err == nil {
		return &v
	}
	return nil
}
