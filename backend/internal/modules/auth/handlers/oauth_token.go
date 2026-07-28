package handlers

import (
	"context"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/auth/models"
)

// oauthErr responde no vocabulário de erro standard da RFC 6749 (secção
// 5.2) — {"error":"invalid_grant", "error_description":"..."}. Os clientes
// (Android, PHP) esperam este formato, não o {"error":"mensagem"} livre
// usado pelo resto do ERP.
func oauthErr(w http.ResponseWriter, status int, code, description string) {
	jsonOK(w, map[string]string{"error": code, "error_description": description}, status)
}

// OAuthToken implementa POST /oauth/token — ponto de emissão único para os
// 4 grant_types suportados (password, client_credentials, authorization_code,
// refresh_token). Aceita form-urlencoded (padrão OAuth2, r.ParseForm cobre
// também query string) e cai em r.PostForm/r.Form de qualquer forma — não
// há necessidade de branch por Content-Type.
func (h *Handler) OAuthToken(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		oauthErr(w, http.StatusBadRequest, "invalid_request", "corpo do pedido inválido")
		return
	}
	grantType := r.PostFormValue("grant_type")
	switch grantType {
	case "password":
		h.oauthPasswordGrant(w, r)
	case "client_credentials":
		h.oauthClientCredentialsGrant(w, r)
	case "refresh_token":
		h.oauthRefreshTokenGrant(w, r)
	case "authorization_code":
		h.oauthAuthorizationCodeGrant(w, r)
	default:
		oauthErr(w, http.StatusBadRequest, "unsupported_grant_type", "grant_type não suportado")
	}
}

// authenticateOAuthClient carrega o cliente pelo client_id e, se for
// confidencial, exige e valida o client_secret. Devolve (nil, false) e já
// escreve a resposta de erro quando a autenticação falha — quem chama só
// precisa de checar o "ok".
func (h *Handler) authenticateOAuthClient(w http.ResponseWriter, r *http.Request) (*models.OAuthClient, bool) {
	clientID := r.PostFormValue("client_id")
	clientSecret := r.PostFormValue("client_secret")
	if clientID == "" {
		if u, p, ok := r.BasicAuth(); ok {
			clientID, clientSecret = u, p
		}
	}
	if clientID == "" {
		oauthErr(w, http.StatusBadRequest, "invalid_request", "client_id é obrigatório")
		return nil, false
	}
	client, err := models.LoadOAuthClient(r.Context(), h.db, clientID)
	if err != nil {
		oauthErr(w, http.StatusUnauthorized, "invalid_client", "cliente desconhecido ou inactivo")
		return nil, false
	}
	if client.ClientType == "confidential" {
		if clientSecret == "" || client.ClientSecretHash == nil || mw.HashToken(clientSecret) != *client.ClientSecretHash {
			oauthErr(w, http.StatusUnauthorized, "invalid_client", "client_secret inválido")
			return nil, false
		}
	}
	return client, true
}

// scopeStringFromAccess serializa as permissões RBAC finas já calculadas
// por models.LoadUserAccess no formato "modulo:acao modulo2:acao2 ..." —
// é isto que vai para a claim "scope" do access token. Usa só campos
// exportados de UserAccess (Modulos), sem tocar em rbac.go.
func scopeStringFromAccess(ua *models.UserAccess) string {
	if ua.Tipo == "superadmin" {
		return "*"
	}
	parts := make([]string, 0, len(ua.Modulos))
	for _, m := range ua.Modulos {
		for _, acao := range m.Acoes {
			parts = append(parts, m.Modulo+":"+acao)
		}
	}
	return strings.Join(parts, " ")
}

// oauthUserLookup replica a parte de identificação/validação de password de
// loginWithCredentials (auth.go) sem os efeitos secundários dessa função
// (sessions em BD, resposta JSON no formato antigo) — usada só pelo grant
// "password" de /oauth/token.
type oauthUserLookup struct {
	userID       int64
	tenantID     int64
	membershipID int64
	nome         string
	tipo         string
	escopo       string
}

func (h *Handler) findUserByCredentials(ctx context.Context, email, password string) (*oauthUserLookup, error) {
	var u oauthUserLookup
	var passwordHash, estado string
	err := h.db.QueryRow(ctx, `
		SELECT u.id, COALESCE(m.tenant_id, 0), COALESCE(m.id, 0), u.nome, u.password_hash, u.estado, u.tipo, COALESCE(NULLIF(m.escopo, ''), 'erp')
		  FROM users u
		  LEFT JOIN auth.memberships m ON m.user_id = u.id AND m.ativo = true
		 WHERE u.email = LOWER($1)`,
		email,
	).Scan(&u.userID, &u.tenantID, &u.membershipID, &u.nome, &passwordHash, &estado, &u.tipo, &u.escopo)
	if err != nil {
		return nil, models.ErrOAuthClientNotFound // reaproveita como "não encontrado" genérico
	}
	if bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(password)) != nil {
		return nil, models.ErrOAuthClientNotFound
	}
	if estado != "ativo" {
		return nil, models.ErrOAuthClientNotFound
	}
	return &u, nil
}

// oauthPasswordGrant — ROPC (RFC 6749 §4.3). Só aceite para clientes
// is_first_party=true (mitigação standard do risco de expor a password
// directamente ao "cliente", mesmo sendo first-party).
func (h *Handler) oauthPasswordGrant(w http.ResponseWriter, r *http.Request) {
	client, ok := h.authenticateOAuthClient(w, r)
	if !ok {
		return
	}
	if !client.SupportsGrant("password") || !client.IsFirstParty {
		oauthErr(w, http.StatusBadRequest, "unauthorized_client", "cliente não autorizado para grant_type=password")
		return
	}
	username := r.PostFormValue("username")
	password := r.PostFormValue("password")
	if username == "" || password == "" {
		oauthErr(w, http.StatusBadRequest, "invalid_request", "username e password são obrigatórios")
		return
	}
	u, err := h.findUserByCredentials(r.Context(), username, password)
	if err != nil {
		oauthErr(w, http.StatusBadRequest, "invalid_grant", "credenciais inválidas")
		return
	}
	// Contas aluno/encarregado/candidato (portal gestao-escolar) não migram
	// para /oauth/token nesta fase: usam IDs de sujeito fora do espaço
	// auth.users (studentID, candidatoID) ou nem sequer um "sub" numérico
	// (encarregado usa o email como claim, não um ID) — encaixar isso no
	// mesmo oauth_refresh_tokens.subject_id BIGINT produziria tokens
	// subtilmente incorrectos. Fora do âmbito real desta migração (que serve
	// web-erp + app Android de assiduidade, ambos só funcionario/superadmin)
	// — continuam em /api/auth/login até um plano dedicado para o portal.
	if u.tipo != "funcionario" && u.tipo != "superadmin" {
		oauthErr(w, http.StatusBadRequest, "unsupported_grant_type",
			"contas de portal (aluno/encarregado/candidato) ainda não migraram para /oauth/token — use /api/auth/login")
		return
	}

	scope := ""
	if access, err := models.LoadUserAccess(r.Context(), h.db, u.userID, u.membershipID); err == nil {
		scope = scopeStringFromAccess(access)
	}

	h.issueOAuthTokenResponse(w, r, client, u.tipo, u.userID, u.tenantID, u.membershipID, u.escopo, scope, h.cfg.JWTExpiresIn)
}

// oauthClientCredentialsGrant — RFC 6749 §4.4, sem utilizador envolvido.
// scope vem de oauth_clients.allowed_scopes (curado manualmente por
// cliente), não de RBAC. Sem refresh token — o cliente volta a
// autenticar-se com o próprio segredo quando o access token expirar.
func (h *Handler) oauthClientCredentialsGrant(w http.ResponseWriter, r *http.Request) {
	client, ok := h.authenticateOAuthClient(w, r)
	if !ok {
		return
	}
	if client.ClientType != "confidential" || !client.SupportsGrant("client_credentials") {
		oauthErr(w, http.StatusBadRequest, "unauthorized_client", "cliente não autorizado para grant_type=client_credentials")
		return
	}
	scope := strings.Join(client.AllowedScopes, " ")
	accessToken, _, err := h.signOAuthAccessToken(0, 0, 0, "client", "erp", scope, h.cfg.JWTExpiresIn, time.Now())
	if err != nil {
		oauthErr(w, http.StatusInternalServerError, "server_error", "erro ao emitir token")
		return
	}
	jsonOK(w, map[string]interface{}{
		"access_token": accessToken,
		"token_type":   "Bearer",
		"expires_in":   int(h.cfg.JWTExpiresIn.Seconds()),
		"scope":        scope,
	}, http.StatusOK)
}

// issueOAuthTokenResponse assina o access token, gera e persiste um refresh
// token novo (família nova — usado pelos grants iniciais; oauthRefreshTokenGrant
// usa a variante de rotation) e escreve a resposta JSON standard.
//
// Para sujeitos humanos (funcionario/superadmin) também cria uma entrada em
// auth.sessions, porque o middleware RequireAuth ainda valida o access token
// contra essa tabela (compatibilidade com sessões HS256 legadas e rotas
// protegidas do ERP). client_credentials não cria sessão — é um token de
// máquina, sem utilizador.
func (h *Handler) issueOAuthTokenResponse(w http.ResponseWriter, r *http.Request, client *models.OAuthClient, subjectType string, subjectID, tenantID, membershipID int64, escopo, scope string, expiry time.Duration) {
	accessToken, _, err := h.signOAuthAccessToken(subjectID, tenantID, membershipID, subjectType, escopo, scope, expiry, time.Now())
	if err != nil {
		oauthErr(w, http.StatusInternalServerError, "server_error", "erro ao emitir access token")
		return
	}
	refreshToken, err := h.issueRefreshToken(r, client, subjectType, subjectID, membershipID, scope, uuid.NewString())
	if err != nil {
		oauthErr(w, http.StatusInternalServerError, "server_error", "erro ao emitir refresh token")
		return
	}

	if subjectType == "funcionario" || subjectType == "superadmin" {
		if err := h.insertSession(r, subjectID, mw.HashToken(accessToken), time.Now().Add(expiry)); err != nil {
			oauthErr(w, http.StatusInternalServerError, "server_error", "erro ao criar sessão")
			return
		}
	}

	h.db.Exec(r.Context(), `UPDATE users SET ultimo_login_em = NOW() WHERE id = $1`, subjectID)
	jsonOK(w, map[string]interface{}{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"token_type":    "Bearer",
		"expires_in":    int(expiry.Seconds()),
		"scope":         scope,
	}, http.StatusOK)
}

// issueRefreshToken gera um token opaco novo e grava-o em
// auth.oauth_refresh_tokens. familyID é constante ao longo de toda a cadeia
// de rotation de um login — permite revogar a família inteira de uma vez em
// caso de reuse detection.
func (h *Handler) issueRefreshToken(r *http.Request, client *models.OAuthClient, subjectType string, subjectID, membershipID int64, scope, familyID string) (string, error) {
	raw, err := randomOpaqueToken()
	if err != nil {
		return "", err
	}
	expiresAt := time.Now().Add(h.cfg.JWTRefreshExpiresIn)
	_, err = h.db.Exec(r.Context(), `
		INSERT INTO auth.oauth_refresh_tokens
			(token_hash, client_id, subject_type, subject_id, membership_id, scope, family_id, expira_em, ip_address, user_agent)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
		mw.HashToken(raw), client.ID, subjectType, subjectID, membershipID, scope, familyID, expiresAt,
		clientIP(r), r.Header.Get("User-Agent"),
	)
	if err != nil {
		return "", err
	}
	return raw, nil
}

// oauthRefreshTokenGrant — RFC 6749 §6, com rotation obrigatória: o token
// apresentado é sempre revogado (usado ou não), e um novo é emitido na
// mesma família. Se o token apresentado já estiver revogado, é reuse de um
// token roubado/duplicado — revoga a família inteira e nega.
func (h *Handler) oauthRefreshTokenGrant(w http.ResponseWriter, r *http.Request) {
	client, ok := h.authenticateOAuthClient(w, r)
	if !ok {
		return
	}
	raw := r.PostFormValue("refresh_token")
	if raw == "" {
		oauthErr(w, http.StatusBadRequest, "invalid_request", "refresh_token é obrigatório")
		return
	}

	var (
		id                                       int64
		clientRowID, subjectID, membershipID     int64
		subjectType, scope, familyID             string
		revokedAt                                *time.Time
		expiraEm                                 time.Time
	)
	err := h.db.QueryRow(r.Context(), `
		SELECT id, client_id, subject_type, subject_id, membership_id, scope, family_id, revoked_at, expira_em
		  FROM auth.oauth_refresh_tokens
		 WHERE token_hash = $1`, mw.HashToken(raw),
	).Scan(&id, &clientRowID, &subjectType, &subjectID, &membershipID, &scope, &familyID, &revokedAt, &expiraEm)
	if err != nil {
		oauthErr(w, http.StatusBadRequest, "invalid_grant", "refresh_token inválido")
		return
	}
	if clientRowID != client.ID {
		oauthErr(w, http.StatusBadRequest, "invalid_grant", "refresh_token não pertence a este cliente")
		return
	}
	if revokedAt != nil {
		// Reuse de um token já rodado/revogado — trata-se como comprometido:
		// revoga toda a família para forçar novo login.
		h.db.Exec(r.Context(), `
			UPDATE auth.oauth_refresh_tokens SET revoked_at = NOW()
			 WHERE family_id = $1 AND revoked_at IS NULL`, familyID)
		oauthErr(w, http.StatusBadRequest, "invalid_grant", "refresh_token já utilizado — sessão revogada")
		return
	}
	if time.Now().After(expiraEm) {
		oauthErr(w, http.StatusBadRequest, "invalid_grant", "refresh_token expirado")
		return
	}

	// Rotation: revoga o actual, emite um novo na mesma família.
	h.db.Exec(r.Context(), `UPDATE auth.oauth_refresh_tokens SET revoked_at = NOW() WHERE id = $1`, id)
	newRaw, err := randomOpaqueToken()
	if err != nil {
		oauthErr(w, http.StatusInternalServerError, "server_error", "erro ao rodar refresh_token")
		return
	}
	expiresAt := time.Now().Add(h.cfg.JWTRefreshExpiresIn)
	_, err = h.db.Exec(r.Context(), `
		INSERT INTO auth.oauth_refresh_tokens
			(token_hash, client_id, subject_type, subject_id, membership_id, scope, family_id, parent_id, expira_em, ip_address, user_agent)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
		mw.HashToken(newRaw), client.ID, subjectType, subjectID, membershipID, scope, familyID, id, expiresAt,
		clientIP(r), r.Header.Get("User-Agent"),
	)
	if err != nil {
		oauthErr(w, http.StatusInternalServerError, "server_error", "erro ao gravar refresh_token")
		return
	}

	// Re-calcular o access token com o mesmo tenant/membership do refresh
	// (não confiar em nada vindo do cliente); tid vem sempre de BD quando o
	// subject é humano — para subject_type="client" fica 0/0. subjectType só
	// pode ser "funcionario"/"superadmin" (password, authorization_code) —
	// client_credentials nunca emite refresh token (RFC 6749 §4.4).
	var tenantID int64
	if subjectType != "client" {
		h.db.QueryRow(r.Context(), `SELECT COALESCE(tenant_id,0) FROM auth.memberships WHERE id = $1`, membershipID).Scan(&tenantID)
	}
	expiry := h.cfg.JWTExpiresIn
	accessToken, _, err := h.signOAuthAccessToken(subjectID, tenantID, membershipID, subjectType, "erp", scope, expiry, time.Now())
	if err != nil {
		oauthErr(w, http.StatusInternalServerError, "server_error", "erro ao emitir access token")
		return
	}

	jsonOK(w, map[string]interface{}{
		"access_token":  accessToken,
		"refresh_token": newRaw,
		"token_type":    "Bearer",
		"expires_in":    int(expiry.Seconds()),
		"scope":         scope,
	}, http.StatusOK)
}

// oauthAuthorizationCodeGrant — RFC 6749 §4.1.3 + PKCE (RFC 7636). A
// emissão do "code" acontece em GET/POST /oauth/authorize (Fase 3); aqui só
// se troca o code por tokens. Implementado já para não deixar a tabela
// oauth_authorization_codes sem consumidor quando a Fase 3 ligar o
// /oauth/authorize.
func (h *Handler) oauthAuthorizationCodeGrant(w http.ResponseWriter, r *http.Request) {
	client, ok := h.authenticateOAuthClient(w, r)
	if !ok {
		return
	}
	if !client.SupportsGrant("authorization_code") {
		oauthErr(w, http.StatusBadRequest, "unauthorized_client", "cliente não autorizado para grant_type=authorization_code")
		return
	}
	code := r.PostFormValue("code")
	redirectURI := r.PostFormValue("redirect_uri")
	verifier := r.PostFormValue("code_verifier")
	if code == "" || redirectURI == "" || verifier == "" {
		oauthErr(w, http.StatusBadRequest, "invalid_request", "code, redirect_uri e code_verifier são obrigatórios")
		return
	}

	var (
		id                                    int64
		clientRowID, userID, membershipID     int64
		storedRedirect, scope, challenge      string
		usedAt                                *time.Time
		expiraEm                              time.Time
	)
	err := h.db.QueryRow(r.Context(), `
		SELECT id, client_id, user_id, membership_id, redirect_uri, scope, code_challenge, used_at, expira_em
		  FROM auth.oauth_authorization_codes
		 WHERE code_hash = $1`, mw.HashToken(code),
	).Scan(&id, &clientRowID, &userID, &membershipID, &storedRedirect, &scope, &challenge, &usedAt, &expiraEm)
	if err != nil {
		oauthErr(w, http.StatusBadRequest, "invalid_grant", "code inválido")
		return
	}
	if clientRowID != client.ID || storedRedirect != redirectURI {
		oauthErr(w, http.StatusBadRequest, "invalid_grant", "code não corresponde ao cliente/redirect_uri")
		return
	}
	if usedAt != nil {
		oauthErr(w, http.StatusBadRequest, "invalid_grant", "code já utilizado")
		return
	}
	if time.Now().After(expiraEm) {
		oauthErr(w, http.StatusBadRequest, "invalid_grant", "code expirado")
		return
	}
	if !pkceChallengeMatches(challenge, verifier) {
		oauthErr(w, http.StatusBadRequest, "invalid_grant", "code_verifier inválido")
		return
	}

	// Single-use: marcar como usado antes de emitir tokens.
	if _, err := h.db.Exec(r.Context(), `UPDATE auth.oauth_authorization_codes SET used_at = NOW() WHERE id = $1`, id); err != nil {
		oauthErr(w, http.StatusInternalServerError, "server_error", "erro ao consumir code")
		return
	}

	var tenantID int64
	h.db.QueryRow(r.Context(), `SELECT COALESCE(tenant_id,0) FROM auth.memberships WHERE id = $1`, membershipID).Scan(&tenantID)

	h.issueOAuthTokenResponse(w, r, client, "funcionario", userID, tenantID, membershipID, "erp", scope, h.cfg.JWTExpiresIn)
}
