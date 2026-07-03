package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type encarregadoContextKey string

const EncarregadoKey encarregadoContextKey = "encarregadoUser"

type EncarregadoUser struct {
	Email    string
	TenantID int64
}

func GetEncarregadoUser(r *http.Request) *EncarregadoUser {
	u, _ := r.Context().Value(EncarregadoKey).(*EncarregadoUser)
	return u
}

// RequireEncarregadoAuth valida o JWT do portal do encarregado e verifica a sessão.
func RequireEncarregadoAuth(jwtSecret string, pool *pgxpool.Pool) func(http.Handler) http.Handler {
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

			if tipo, _ := claims["tipo"].(string); tipo != "encarregado" {
				JSONErr(w, "Token inválido para este portal", http.StatusForbidden)
				return
			}

			email, emailOk := claims["email"].(string)
			tidRaw, tidOk := claims["tid"].(float64)
			if !emailOk || !tidOk || email == "" {
				JSONErr(w, "Token inválido", http.StatusUnauthorized)
				return
			}
			tenantID := int64(tidRaw)

			// Verificar sessão activa
			var ativa bool
			err = pool.QueryRow(r.Context(), `
				SELECT ativa FROM gestao_escolar.guardian_portal_sessions
				 WHERE token_hash = $1
				   AND guardian_email = $2
				   AND tenant_id = $3
				   AND expira_em > NOW()`,
				HashToken(rawToken), email, tenantID,
			).Scan(&ativa)

			if err != nil || !ativa {
				JSONErr(w, "Sessão revogada ou expirada", http.StatusUnauthorized)
				return
			}

			ctx := context.WithValue(r.Context(), EncarregadoKey, &EncarregadoUser{
				Email: email, TenantID: tenantID,
			})
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}
