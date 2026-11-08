package middleware

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	authModels "nexora/internal/modules/auth/models"
	"nexora/internal/modules/auth/oauthkeys"
)

type contextKey string

const UserKey contextKey = "authUser"

type AuthUser struct {
	ID            int64
	TenantID      int64
	SessionID     int64
	MembershipID  int64     // auth.memberships.id usado neste login; 0 se não houver (ex.: superadmin)
	Tipo          string    // "superadmin" | "funcionario" | "terminal"
	Escopo        string    // "erp" | "escola"
	ReauthAt      time.Time // momento da última reautenticação (step-up)
	TerminalID    *int64    // preenchido quando o token representa um terminal POS
	FuncionarioID *int64    // preenchido quando o token representa um funcionário operador
}

func HashToken(token string) string {
	return fmt.Sprintf("%x", sha256.Sum256([]byte(token)))
}

func jwtKeyFunc(jwtSecret string, oauthKeys *oauthkeys.Provider) jwt.Keyfunc {
	return func(t *jwt.Token) (interface{}, error) {
		switch t.Method.(type) {
		case *jwt.SigningMethodHMAC:
			return []byte(jwtSecret), nil
		case *jwt.SigningMethodRSA:
			kid, _ := t.Header["kid"].(string)
			pub, ok := oauthKeys.PublicKey(kid)
			if !ok {
				return nil, fmt.Errorf("kid desconhecido: %q", kid)
			}
			return pub, nil
		default:
			return nil, fmt.Errorf("unexpected signing method")
		}
	}
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
// Aceita o token apenas via header "Authorization: Bearer <token>". Aceita
// tanto HS256 (legado, jwtSecret) como RS256 (emitido por /oauth/token,
// verificado via oauthKeys) — ver jwtKeyFunc.
func RequireAuth(jwtSecret string, pool *pgxpool.Pool, oauthKeys *oauthkeys.Provider) func(http.Handler) http.Handler {
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

			token, err := jwt.Parse(rawToken, jwtKeyFunc(jwtSecret, oauthKeys))
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
			midRaw, _ := claims["mid"].(float64)
			membershipID := int64(midRaw)

			var terminalID, funcionarioID *int64
			if raw, ok := claims["terminal_id"].(float64); ok && raw > 0 {
				tid := int64(raw)
				terminalID = &tid
			}
			if raw, ok := claims["funcionario_id"].(float64); ok && raw > 0 {
				fid := int64(raw)
				funcionarioID = &fid
			}

			var reauthAt time.Time
			if raw, ok := claims["reauth_at"].(float64); ok && raw > 0 {
				reauthAt = time.Unix(int64(raw), 0)
			} else if raw, ok := claims["iat"].(float64); ok && raw > 0 {
				reauthAt = time.Unix(int64(raw), 0)
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

			// Filtrar a membership por id (não só por user_id) é o que torna
			// esta resolução de tenant determinística agora que um user pode
			// ter mais de uma membership (ver migration 20260713000002) — o
			// mid vem de um JWT assinado, por isso confiável, mas o AND
			// m.user_id = u.id fica como defesa adicional contra um token
			// mal formado apontar para a membership de outra pessoa.
			err = pool.QueryRow(r.Context(), `
				SELECT s.id, s.ativa, u.estado, COALESCE(m.tenant_id, 0)
				  FROM auth.sessions s
				  JOIN auth.users u ON u.id = s.user_id
				  LEFT JOIN auth.memberships m ON m.id = $3 AND m.user_id = u.id
				 WHERE s.token_hash = $1 AND s.user_id = $2`,
				HashToken(rawToken), userID, membershipID,
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
				ID: userID, TenantID: tenantID, SessionID: sessionID,
				MembershipID: membershipID, Tipo: tipo, Escopo: escopo,
				ReauthAt: reauthAt, TerminalID: terminalID, FuncionarioID: funcionarioID,
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
			access, err := authModels.LoadUserAccess(r.Context(), pool, user.ID, user.MembershipID)
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

func GetUser(r *http.Request) *AuthUser {
	u, _ := r.Context().Value(UserKey).(*AuthUser)
	return u
}

func JSONErr(w http.ResponseWriter, msg string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}
