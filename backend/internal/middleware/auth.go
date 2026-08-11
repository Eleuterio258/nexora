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
	"github.com/jackc/pgx/v5"
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

// jwtKeyFunc devolve um keyfunc consciente de dois algoritmos: HS256
// (legado, jwtSecret) e RS256 (emitido por /oauth/token, verificado via
// "kid" contra oauthkeys.Provider, sem round-trip). Isto é permanente, não
// transitório: /api/auth/login e /api/auth/refresh continuam a servir
// contas de portal (aluno/encarregado/candidato/portal_professor) com
// tokens HS256 indefinidamente — o Authorization Server OAuth2
// (/oauth/token) só emite RS256 e só para funcionario/superadmin (decisão
// registada: migrar contas de portal para OAuth2 exigiria resolver primeiro
// o facto de não terem um "sub" numérico consistente no espaço auth.users,
// ver oauth_token.go). RequireAuth tem de continuar a aceitar os dois.
// JWTKeyFunc expõe jwtKeyFunc a quem valida tokens fora do middleware — hoje
// o WebSocket do chat (internal/ws.ServeWS), que autentica pelo query param
// ?token= e por isso não passa por RequireAuth. Enquanto tinha o seu próprio
// parse, só aceitava HMAC, e ficou a devolver 401 em ciclo assim que os
// access tokens do ERP passaram a ser RS256.
func JWTKeyFunc(jwtSecret string, oauthKeys *oauthkeys.Provider) jwt.Keyfunc {
	return jwtKeyFunc(jwtSecret, oauthKeys)
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

// RequireJWT valida apenas o JWT sem verificar sessão na DB (para serviços
// sem acesso à auth DB). Aceita HS256 (legado) e RS256 — ver jwtKeyFunc.
func RequireJWT(jwtSecret string, oauthKeys *oauthkeys.Provider) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := r.Header.Get("Authorization")
			if !strings.HasPrefix(header, "Bearer ") {
				JSONErr(w, "Token em falta", http.StatusUnauthorized)
				return
			}
			token, err := jwt.Parse(header[7:], jwtKeyFunc(jwtSecret, oauthKeys))
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
			midRaw, _ := claims["mid"].(float64)
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

			ctx := context.WithValue(r.Context(), UserKey, &AuthUser{
				ID: userID, TenantID: int64(tidRaw), MembershipID: int64(midRaw), Tipo: tipo, Escopo: escopo,
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

// DBPool é a interface mínima de base de dados usada pelos middlewares.
type DBPool interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

// RequireFeature verifica se uma funcionalidade está activa para o tenant.
// Superadmin tem acesso total. Deve ser usado após RequireAuth.
func RequireFeature(pool DBPool, feature string) func(http.Handler) http.Handler {
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

// RequireLicencaAtiva bloqueia o acesso quando o tenant tem uma licença de
// aplicação (empresas.company_licenses) explicitamente expirada ou suspensa.
// Um tenant sem NENHUMA licença registada passa livremente — licenciamento é
// opt-in por tenant (retrocompatível: a maioria dos tenants existentes nunca
// teve uma licença criada, bloqueá-los por omissão quebraria produção).
// Superadmin bypassa sempre. Deve ser usado depois de RequireAuth.
func RequireLicencaAtiva(pool DBPool) func(http.Handler) http.Handler {
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
			var total, validas int
			err := pool.QueryRow(r.Context(), `
				SELECT COUNT(*),
				       COUNT(*) FILTER (WHERE l.status = 'ativa' AND (l.expira_em IS NULL OR l.expira_em >= CURRENT_DATE))
				  FROM empresas.company_licenses l
				  JOIN saas.tenants t ON t.company_id = l.company_id
				 WHERE t.id = $1`, user.TenantID).Scan(&total, &validas)
			if err != nil {
				JSONErr(w, "Erro interno ao validar licença", http.StatusInternalServerError)
				return
			}
			if total > 0 && validas == 0 {
				JSONErr(w, "Licença da aplicação expirada ou suspensa — contacte o administrador", http.StatusPaymentRequired)
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

// IsTerminalToken indica se o token autenticado representa um terminal POS
// (identidade técnica) em vez de um utilizador/funcionário humano.
func IsTerminalToken(r *http.Request) bool {
	u := GetUser(r)
	return u != nil && u.Tipo == "terminal" && u.TerminalID != nil && *u.TerminalID > 0
}

// RequireHumanOperator é um middleware que rejeita pedidos feitos por tokens
// de terminal. Deve ser usado em rotas onde uma pessoa (operador de caixa)
// precisa estar autenticada, como abertura de sessão, venda e fecho de caixa.
func RequireHumanOperator() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if IsTerminalToken(r) {
				JSONErr(w, "Operação requer autenticação de operador humano", http.StatusForbidden)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

func JSONErr(w http.ResponseWriter, msg string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}
