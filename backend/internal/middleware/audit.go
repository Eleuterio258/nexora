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

// acoesEspeciais mapeia o último segmento de rotas de acção (ex: /ausencias/{id}/aprovar)
// para o nome da acção registada em auditoria.
var acoesEspeciais = map[string]string{
	"aprovar":   "aprovar",
	"rejeitar":  "rejeitar",
	"gozar":     "gozar",
	"cancelar":  "cancelar",
	"renovar":   "renovar",
	"rescindir": "rescindir",
	"desligar":  "desligar",
	"mover":     "mover",
	"processar": "processar",
	"pagar":     "pagar",
	"submeter":  "submeter",
}

var acoesPorMetodo = map[string]string{
	http.MethodPost:   "criar",
	http.MethodPut:    "atualizar",
	http.MethodPatch:  "atualizar",
	http.MethodDelete: "eliminar",
}

// parseRotaRH extrai a entidade, o id da entidade e a acção a partir do caminho
// e método de um pedido a /api/rh/..., para efeitos de auditoria (RNF05).
func parseRotaRH(method, path string) (entidade string, entidadeID *int64, acao string) {
	rota := strings.Trim(strings.TrimPrefix(path, "/api/rh"), "/")
	partes := strings.Split(rota, "/")

	acao = acoesPorMetodo[method]

	if len(partes) > 0 {
		if v, ok := acoesEspeciais[partes[len(partes)-1]]; ok {
			acao = v
			partes = partes[:len(partes)-1]
		}
	}

	var nomes []string
	for _, p := range partes {
		if p == "" {
			continue
		}
		if id, err := strconv.ParseInt(p, 10, 64); err == nil {
			entidadeID = &id
			continue
		}
		nomes = append(nomes, p)
	}

	entidade = strings.Join(nomes, ".")
	if entidade == "" {
		entidade = "rh"
	}
	return
}

// AuditRH regista em audit_logs as operações de escrita (POST/PUT/PATCH/DELETE)
// efectuadas com sucesso nos endpoints /api/rh, cumprindo o requisito de
// auditoria das operações de Recursos Humanos (RNF05).
func AuditRH(db *pgxpool.Pool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.Method == http.MethodGet || r.Method == http.MethodHead || r.Method == http.MethodOptions {
				next.ServeHTTP(w, r)
				return
			}

			var corpo []byte
			if r.Body != nil {
				corpo, _ = io.ReadAll(r.Body)
				r.Body = io.NopCloser(bytes.NewReader(corpo))
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

			entidade, entidadeID, acao := parseRotaRH(r.Method, r.URL.Path)

			var detalhes json.RawMessage
			if len(corpo) > 0 && json.Valid(corpo) {
				detalhes = json.RawMessage(corpo)
			}

			db.Exec(context.Background(), `
				INSERT INTO audit_logs (tenant_id, user_id, modulo, entidade, entidade_id, acao, detalhes, ip_address)
				VALUES ($1,$2,'recursos-humanos',$3,$4,$5,$6,$7)`,
				user.TenantID, user.ID, entidade, entidadeID, acao, detalhes, r.RemoteAddr)
		})
	}
}
