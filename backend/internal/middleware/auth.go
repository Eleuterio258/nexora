package middleware

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type contextKey string

const UserKey contextKey = "authUser"

type AuthUser struct {
	ID        int64
	TenantID  int64
	SessionID int64
	Tipo      string // "superadmin" | "funcionario"
}

func HashToken(token string) string {
	return fmt.Sprintf("%x", sha256.Sum256([]byte(token)))
}

// RequireAuth valida o JWT e verifica a sessão na base de dados (auth-service).
// Aceita o token via header "Authorization: Bearer <token>" OU query param "?token=<token>"
// (usado por WebSocket que não pode enviar headers personalizados).
func RequireAuth(jwtSecret string, pool *pgxpool.Pool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			rawToken := ""
			header := r.Header.Get("Authorization")
			if strings.HasPrefix(header, "Bearer ") {
				rawToken = header[7:]
			} else if t := r.URL.Query().Get("token"); t != "" {
				rawToken = t
			}
			if rawToken == "" {
				JSONErr(w, "Token em falta", http.StatusUnauthorized)
				return
			}

			token, err := jwt.Parse(rawToken, func(t *jwt.Token) (interface{}, error) {
				if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, fmt.Errorf("unexpected signing method")
				}
				return []byte(jwtSecret), nil
			})
			if err != nil || !token.Valid {
				JSONErr(w, "Token inválido ou expirado", http.StatusUnauthorized)
				return
			}

			claims, _ := token.Claims.(jwt.MapClaims)
			userID := int64(claims["sub"].(float64))
			tipo, _ := claims["tipo"].(string)
			if tipo == "" {
				tipo = "funcionario"
			}

			var sessionID int64
			var ativa bool
			var estado string
			var tenantID int64

			err = pool.QueryRow(r.Context(), `
				SELECT s.id, s.ativa, u.estado, u.tenant_id
				  FROM auth.sessions s
				  JOIN auth.users u ON u.id = s.user_id
				 WHERE s.token_hash = $1 AND s.user_id = $2`,
				HashToken(rawToken), userID,
			).Scan(&sessionID, &ativa, &estado, &tenantID)

			if err != nil || !ativa {
				JSONErr(w, "Sessão revogada", http.StatusUnauthorized)
				return
			}
			if estado != "ativo" {
				JSONErr(w, "Utilizador inactivo ou bloqueado", http.StatusForbidden)
				return
			}

			ctx := context.WithValue(r.Context(), UserKey, &AuthUser{
				ID: userID, TenantID: tenantID, SessionID: sessionID, Tipo: tipo,
			})
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// RequireJWT valida apenas o JWT sem verificar sessão na DB (para serviços sem acesso à auth DB).
func RequireJWT(jwtSecret string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := r.Header.Get("Authorization")
			if !strings.HasPrefix(header, "Bearer ") {
				JSONErr(w, "Token em falta", http.StatusUnauthorized)
				return
			}
			token, err := jwt.Parse(header[7:], func(t *jwt.Token) (interface{}, error) {
				if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, fmt.Errorf("unexpected signing method")
				}
				return []byte(jwtSecret), nil
			})
			if err != nil || !token.Valid {
				JSONErr(w, "Token inválido ou expirado", http.StatusUnauthorized)
				return
			}
			claims, _ := token.Claims.(jwt.MapClaims)
			userID := int64(claims["sub"].(float64))
			tidRaw, _ := claims["tid"].(float64)
			tipo, _ := claims["tipo"].(string)
			if tipo == "" {
				tipo = "funcionario"
			}
			ctx := context.WithValue(r.Context(), UserKey, &AuthUser{
				ID: userID, TenantID: int64(tidRaw), Tipo: tipo,
			})
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func RequireSuperadmin() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if u := GetUser(r); u == nil || u.Tipo != "superadmin" {
				JSONErr(w, "Acesso reservado ao superadmin", http.StatusForbidden)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

func GetUser(r *http.Request) *AuthUser {
	u, _ := r.Context().Value(UserKey).(*AuthUser)
	return u
}

func JSONErr(w http.ResponseWriter, msg string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}
