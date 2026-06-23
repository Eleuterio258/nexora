package middleware

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strconv"
	"strings"

	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"
)

// AuditModule regista operacoes de escrita bem-sucedidas de um modulo.
func AuditModule(db *pgxpool.Pool, prefix, modulo string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.Method == http.MethodGet || r.Method == http.MethodHead || r.Method == http.MethodOptions {
				next.ServeHTTP(w, r)
				return
			}

			var body []byte
			if r.Body != nil {
				body, _ = io.ReadAll(r.Body)
				r.Body = io.NopCloser(bytes.NewReader(body))
			}

			ww := chimw.NewWrapResponseWriter(w, r.ProtoMajor)
			next.ServeHTTP(ww, r)
			if ww.Status() >= 400 {
				return
			}
			user := GetUser(r)
			if user == nil {
				return
			}

			path := strings.Trim(strings.TrimPrefix(r.URL.Path, prefix), "/")
			parts := strings.Split(path, "/")
			entity := "modulo"
			var entityID *int64
			action := acoesPorMetodo[r.Method]
			if len(parts) > 0 && parts[0] != "" {
				entity = parts[0]
			}
			for _, part := range parts[1:] {
				if id, err := strconv.ParseInt(part, 10, 64); err == nil {
					entityID = &id
				} else if part != "" {
					action = part
				}
			}
			var details json.RawMessage
			if len(body) > 0 && json.Valid(body) {
				details = json.RawMessage(body)
			}
			_, _ = db.Exec(context.Background(), `
				INSERT INTO auditoria.audit_logs(
				  tenant_id,user_id,modulo,entidade,entidade_id,acao,detalhes,ip_address)
				VALUES($1,$2,$3,$4,$5,$6,$7,$8)`,
				user.TenantID, user.ID, modulo, entity, entityID, action, details, r.RemoteAddr)
		})
	}
}
