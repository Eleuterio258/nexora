package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

type candidatoContextKey string

const CandidatoKey candidatoContextKey = "candidatoUser"

type CandidatoUser struct {
	ID       int64
	TenantID int64
	Email    string
	Nome     string
}

func GetCandidatoUser(r *http.Request) *CandidatoUser {
	u, _ := r.Context().Value(CandidatoKey).(*CandidatoUser)
	return u
}

// RequireCandidatoAuth valida o token de sessão do portal de candidatos.
// O token é um hex bruto (64 chars); o hash SHA-256 é guardado em candidato_sessions.
func RequireCandidatoAuth(pool *pgxpool.Pool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := r.Header.Get("Authorization")
			if !strings.HasPrefix(header, "Bearer ") {
				JSONErr(w, "Token em falta", http.StatusUnauthorized)
				return
			}
			rawToken := header[7:]

			var candidatoID, tenantID int64
			var email, nome string
			err := pool.QueryRow(r.Context(), `
				SELECT c.id, c.tenant_id, c.email, c.nome
				  FROM recrutamento.candidato_sessions s
				  JOIN recrutamento.candidatos c ON c.id = s.candidato_id
				 WHERE s.token_hash = $1
				   AND s.revogado_em IS NULL
				   AND s.expira_em > NOW()
				   AND c.ativo = true`,
				HashToken(rawToken),
			).Scan(&candidatoID, &tenantID, &email, &nome)

			if err != nil {
				JSONErr(w, "Sessão inválida ou expirada", http.StatusUnauthorized)
				return
			}

			ctx := context.WithValue(r.Context(), CandidatoKey, &CandidatoUser{
				ID: candidatoID, TenantID: tenantID, Email: email, Nome: nome,
			})
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
