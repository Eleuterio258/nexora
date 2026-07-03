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

	authModels "nexora/internal/modules/auth/models"
)

type contextKey string

const UserKey contextKey = "authUser"

type AuthUser struct {
	ID        int64
	TenantID  int64
	SessionID int64
	Tipo      string // "superadmin" | "funcionario"
	Escopo    string // "erp" | "escola"
}

func HashToken(token string) string {
	return fmt.Sprintf("%x", sha256.Sum256([]byte(token)))
}

// escopoPermitidoParaPath determina se um dado escopo pode aceder ao path.
// Superadmin é tratado separadamente pelos middlewares (bypass).
func escopoPermitidoParaPath(path, escopo string) bool {
	switch {
	case strings.HasPrefix(path, "/api/escolar"):
		return escopo == "escola"
	case strings.HasPrefix(path, "/api/auth"), strings.HasPrefix(path, "/api/portal"):
		// Auth e portais têm restrições próprias
		return true
	case strings.HasPrefix(path, "/api/"):
		return escopo == "erp"
	default:
		return true
	}
}

// RequireAuth valida o JWT e verifica a sessão na base de dados (auth-service).
// Aceita o token apenas via header "Authorization: Bearer <token>".
func RequireAuth(jwtSecret string, pool *pgxpool.Pool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := r.Header.Get("Authorization")
			if !strings.HasPrefix(header, "Bearer ") {
				JSONErr(w, "Token em falta", http.StatusUnauthorized)
				return
			}
			rawToken := header[7:]
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

			claims, claimsOk := token.Claims.(jwt.MapClaims)
			subRaw, subOk := claims["sub"].(float64)
			if !claimsOk || !subOk {
				JSONErr(w, "Token inválido", http.StatusUnauthorized)
				return
			}
			userID := int64(subRaw)
			tipo, _ := claims["tipo"].(string)
			if tipo == "" {
				tipo = "funcionario"
			}
			escopo, _ := claims["escopo"].(string)
			if escopo == "" {
				escopo = "erp"
			}

			// Rejeitar pedidos fora do escopo antes de consultar a base de dados.
			if tipo != "superadmin" && !escopoPermitidoParaPath(r.URL.Path, escopo) {
				JSONErr(w, "Acesso negado ao painel solicitado", http.StatusForbidden)
				return
			}

			var sessionID int64
			var ativa bool
			var estado string
			var tenantID int64

			err = pool.QueryRow(r.Context(), `
				SELECT s.id, s.ativa, u.estado, COALESCE(m.tenant_id, 0)
				  FROM auth.sessions s
				  JOIN auth.users u ON u.id = s.user_id
				  LEFT JOIN auth.memberships m ON m.user_id = u.id
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
				ID: userID, TenantID: tenantID, SessionID: sessionID, Tipo: tipo, Escopo: escopo,
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
			claims, claimsOk := token.Claims.(jwt.MapClaims)
			subRaw, subOk := claims["sub"].(float64)
			if !claimsOk || !subOk {
				JSONErr(w, "Token inválido", http.StatusUnauthorized)
				return
			}
			userID := int64(subRaw)
			tidRaw, _ := claims["tid"].(float64)
			tipo, _ := claims["tipo"].(string)
			if tipo == "" {
				tipo = "funcionario"
			}
			escopo, _ := claims["escopo"].(string)
			if escopo == "" {
				escopo = "erp"
			}
			if tipo != "superadmin" && !escopoPermitidoParaPath(r.URL.Path, escopo) {
				JSONErr(w, "Acesso negado ao painel solicitado", http.StatusForbidden)
				return
			}

			ctx := context.WithValue(r.Context(), UserKey, &AuthUser{
				ID: userID, TenantID: int64(tidRaw), Tipo: tipo, Escopo: escopo,
			})
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// RequirePermission verifica se o utilizador autenticado tem a permissão
// (modulo, acao) exigida. Superadmin tem acesso total.
// Deve ser usado depois de RequireAuth para que AuthUser exista no contexto.
func RequirePermission(pool *pgxpool.Pool, modulo, acao string) func(http.Handler) http.Handler {
	return RequirePermissionAny(pool, []authModels.Permission{{Modulo: modulo, Acao: acao}})
}

// RequirePermissionAny verifica se o utilizador tem pelo menos uma das permissões listadas.
// Superadmin tem acesso total. Todos os outros são verificados pelo RBAC.
func RequirePermissionAny(pool *pgxpool.Pool, perms []authModels.Permission) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			user := GetUser(r)
			if user == nil {
				JSONErr(w, "Utilizador não autenticado", http.StatusUnauthorized)
				return
			}
			if user.Tipo == "superadmin" {
				next.ServeHTTP(w, r)
				return
			}
			access, err := authModels.LoadUserAccess(r.Context(), pool, user.ID)
			if err != nil {
				JSONErr(w, "Sem permissão", http.StatusForbidden)
				return
			}
			for _, p := range perms {
				if access.Can(p.Modulo, p.Acao) {
					next.ServeHTTP(w, r)
					return
				}
			}
			JSONErr(w, "Sem permissão", http.StatusForbidden)
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

// RequireEscopo verifica se o utilizador autenticado tem um dos escopos permitidos.
// Superadmin bypassa todas as restrições de escopo.
// Deve ser usado depois de RequireAuth.
func RequireEscopo(escopos ...string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			u := GetUser(r)
			if u == nil {
				JSONErr(w, "Utilizador não autenticado", http.StatusUnauthorized)
				return
			}
			if u.Tipo == "superadmin" {
				next.ServeHTTP(w, r)
				return
			}
			for _, e := range escopos {
				if u.Escopo == e {
					next.ServeHTTP(w, r)
					return
				}
			}
			JSONErr(w, "Acesso negado ao painel solicitado", http.StatusForbidden)
		})
	}
}

// RestricaoEscopo aplica as regras de escopo automaticamente com base no path:
//   - /api/escolar/*  → escopo 'escola'
//   - /api/auth/*     → sem restrição (login, refresh, me, logout)
//   - /api/portal/*   → sem restrição (autenticação própria dos portais)
//   - /api/*          → escopo 'erp'
//
// Superadmin bypassa.
func RestricaoEscopo() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			u := GetUser(r)
			if u == nil {
				next.ServeHTTP(w, r)
				return
			}
			if u.Tipo == "superadmin" {
				next.ServeHTTP(w, r)
				return
			}

			path := r.URL.Path
			switch {
			case strings.HasPrefix(path, "/api/escolar"):
				if u.Escopo != "escola" {
					JSONErr(w, "Acesso reservado ao painel escolar", http.StatusForbidden)
					return
				}
			case strings.HasPrefix(path, "/api/auth"), strings.HasPrefix(path, "/api/portal"):
				// rotas de auth e portais mantêm-se livres de restrição de escopo
			default:
				if strings.HasPrefix(path, "/api/") && u.Escopo != "erp" {
					JSONErr(w, "Acesso reservado ao ERP", http.StatusForbidden)
					return
				}
			}
			next.ServeHTTP(w, r)
		})
	}
}

// RequireFeature verifica se uma funcionalidade está activa para o tenant.
// Superadmin tem acesso total. Deve ser usado após RequireAuth.
func RequireFeature(pool *pgxpool.Pool, feature string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			user := GetUser(r)
			if user == nil {
				JSONErr(w, "Utilizador não autenticado", http.StatusUnauthorized)
				return
			}
			if user.Tipo == "superadmin" {
				next.ServeHTTP(w, r)
				return
			}
			var activo bool
			err := pool.QueryRow(r.Context(), `
				SELECT COALESCE(
					(SELECT activo FROM sistema_configuracao.tenant_feature_flags
					  WHERE tenant_id = $1 AND codigo = $2),
					(SELECT ativo_por_defeito FROM saas.feature_catalog WHERE key = $2),
					FALSE
				)`, user.TenantID, feature).Scan(&activo)
			if err != nil {
				JSONErr(w, "Erro interno ao validar funcionalidade", http.StatusInternalServerError)
				return
			}
			if !activo {
				JSONErr(w, "Funcionalidade não disponível neste plano", http.StatusPaymentRequired)
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
