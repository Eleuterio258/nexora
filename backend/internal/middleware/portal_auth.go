package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type alunoContextKey string

const AlunoKey alunoContextKey = "alunoUser"

type AlunoUser struct {
	ID       int64
	TenantID int64
}

func GetAlunoUser(r *http.Request) *AlunoUser {
	u, _ := r.Context().Value(AlunoKey).(*AlunoUser)
	return u
}

// RequireAlunoAuth valida o JWT do portal do aluno e verifica a sessão em portal_sessions.
func RequireAlunoAuth(jwtSecret string, pool *pgxpool.Pool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := r.Header.Get("Authorization")
			if !strings.HasPrefix(header, "Bearer ") {
				JSONErr(w, "Token em falta", http.StatusUnauthorized)
				return
			}
			rawToken := header[7:]

			token, err := jwt.Parse(rawToken, func(t *jwt.Token) (interface{}, error) {
				if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, fmt.Errorf("método de assinatura inesperado")
				}
				return []byte(jwtSecret), nil
			})
			if err != nil || !token.Valid {
				JSONErr(w, "Token inválido ou expirado", http.StatusUnauthorized)
				return
			}

			claims, ok := token.Claims.(jwt.MapClaims)
			if !ok {
				JSONErr(w, "Token inválido", http.StatusUnauthorized)
				return
			}

			// Verificar tipo "aluno"
			if tipo, _ := claims["tipo"].(string); tipo != "aluno" {
				JSONErr(w, "Token inválido para este portal", http.StatusForbidden)
				return
			}

			subRaw, subOk := claims["sub"].(float64)
			tidRaw, tidOk := claims["tid"].(float64)
			if !subOk || !tidOk {
				JSONErr(w, "Token inválido", http.StatusUnauthorized)
				return
			}

			studentID := int64(subRaw)
			tenantID := int64(tidRaw)

			// Verificar sessão activa na base de dados
			var ativa bool
			var portalAtivo bool
			err = pool.QueryRow(r.Context(), `
				SELECT ps.ativa, s.portal_ativo
				  FROM gestao_escolar.portal_sessions ps
				  JOIN gestao_escolar.school_students s ON s.id = ps.student_id
				 WHERE ps.token_hash = $1
				   AND ps.student_id = $2
				   AND ps.expira_em > NOW()`,
				HashToken(rawToken), studentID,
			).Scan(&ativa, &portalAtivo)

			if err != nil || !ativa {
				JSONErr(w, "Sessão revogada ou expirada", http.StatusUnauthorized)
				return
			}
			if !portalAtivo {
				JSONErr(w, "Acesso ao portal desactivado", http.StatusForbidden)
				return
			}

			ctx := context.WithValue(r.Context(), AlunoKey, &AlunoUser{
				ID: studentID, TenantID: tenantID,
			})
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
