package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/pquerna/otp/totp"
	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/auth/models"
	"nexora/internal/modules/recursos-humanos/service/funcionario"
)

const (
	authCodeTypePIN  = "pin"
	authCodeTypeTOTP = "totp"
	pinMinLength     = 6
)

// ── helpers ──────────────────────────────────────────────────────────────────

type userIdentity struct {
	id           int64
	tenantID     int64
	membershipID int64
	nome         string
	email        string
	estado       string
	tipo         string
	escopo       string
}

// lookupUserByEmail procura um utilizador pelo email (case-insensitive) e
// devolve os dados necessários para emissão de tokens.
func (h *Handler) lookupUserByEmail(ctx context.Context, email string) (*userIdentity, error) {
	var u userIdentity
	err := h.db.QueryRow(ctx, `
		SELECT u.id, COALESCE(m.tenant_id, 0), COALESCE(m.id, 0), u.nome, u.email, u.estado, u.tipo, COALESCE(NULLIF(m.escopo, ''), 'erp')
		  FROM users u
		  LEFT JOIN auth.memberships m ON m.user_id = u.id AND m.ativo = true
		 WHERE u.email = LOWER($1)`,
		email,
	).Scan(&u.id, &u.tenantID, &u.membershipID, &u.nome, &u.email, &u.estado, &u.tipo, &u.escopo)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

// issueFuncionarioTokens cria access + refresh tokens, regista a sessão e
// devolve a resposta padrão de login do ERP. É usada por Login, PIN e TOTP.
//
// O access token é assinado RS256 (signOAuthAccessToken, mesmo helper de
// /oauth/token) — RequireAuth aceita HS256 e RS256 em simultâneo durante a
// transição (ver jwtKeyFunc), mas só RS256 vai sobreviver à Fase 6. O
// refresh token continua HS256 por agora (signRefresh) — RequireAuth nunca
// o valida directamente, só refreshWithToken, que fica para uma fase
// posterior.
func (h *Handler) issueFuncionarioTokens(w http.ResponseWriter, r *http.Request, u *userIdentity, funcionarioID *int64) {
	userAccess, _ := models.LoadUserAccess(r.Context(), h.db, u.id, u.membershipID)
	scope := ""
	if userAccess != nil {
		scope = scopeStringFromAccess(userAccess)
	}

	accessToken, _, err := h.signOAuthAccessToken(u.id, u.tenantID, u.membershipID, u.tipo, u.escopo, scope, h.cfg.JWTExpiresIn, time.Now())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	refreshToken, err := h.signRefresh(u.id)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	expiresAt := time.Now().Add(h.cfg.JWTExpiresIn)
	if err := h.insertSession(r, u.id, mw.HashToken(accessToken), expiresAt); err != nil {
		jsonErr(w, "Erro ao criar sessão", http.StatusInternalServerError)
		return
	}

	h.db.Exec(r.Context(), `UPDATE users SET ultimo_login_em = NOW() WHERE id = $1`, u.id)

	userObj := map[string]interface{}{
		"id":     u.id,
		"nome":   u.nome,
		"email":  u.email,
		"escopo": escoposPorTipoEscopo(u.tipo, u.escopo),
	}
	if funcionarioID != nil {
		userObj["funcionario_id"] = *funcionarioID
	}
	features := []string{}
	if userAccess != nil {
		userObj["tenant_id"] = userAccess.TenantID
		userObj["cargo_id"] = userAccess.CargoID
		if userAccess.CargoNome != nil {
			userObj["cargo"] = *userAccess.CargoNome
		}
		features = userAccess.Features
	} else {
		userObj["tenant_id"] = u.tenantID
	}

	jsonOK(w, map[string]interface{}{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"token_type":    "Bearer",
		"expires_in":    int(h.cfg.JWTExpiresIn.Seconds()),
		"tipo":          u.tipo,
		"escopo":        escoposPorTipoEscopo(u.tipo, u.escopo),
		"user":          userObj,
		"features":      features,
	}, http.StatusOK)
}

// logAuthAttempt regista uma tentativa de autenticação delegada.
func (h *Handler) logAuthAttempt(r *http.Request, u *userIdentity, email string, sucesso bool, motivo interface{}) {
	var uid, tid interface{}
	if u != nil {
		uid = u.id
		tid = nullInt(u.tenantID, u.tenantID > 0)
	}
	go h.db.Exec(r.Context(), `
		INSERT INTO login_history (user_id, tenant_id, email_tentado, sucesso, ip_address, user_agent, motivo_falha)
		VALUES ($1, $2, LOWER($3), $4, $5, $6, $7)`,
		uid, tid, email, sucesso, r.RemoteAddr, r.Header.Get("User-Agent"), motivo,
	)
}

// ── Login por PIN ────────────────────────────────────────────────────────────

func (h *Handler) LoginPorPIN(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Email string `json:"email"`
		PIN   string `json:"pin"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Email == "" || body.PIN == "" {
		jsonErr(w, "email e pin são obrigatórios", http.StatusBadRequest)
		return
	}

	u, err := h.lookupUserByEmail(r.Context(), body.Email)
	if err != nil {
		h.logAuthAttempt(r, nil, body.Email, false, "utilizador não encontrado")
		jsonErr(w, "Credenciais inválidas", http.StatusUnauthorized)
		return
	}

	if u.estado != "ativo" {
		h.logAuthAttempt(r, u, body.Email, false, "conta "+u.estado)
		jsonErr(w, "Conta "+u.estado, http.StatusForbidden)
		return
	}

	var pinHash string
	if err := h.db.QueryRow(r.Context(), `
		SELECT secret_hash FROM auth.user_auth_codes
		 WHERE user_id = $1 AND tipo = $2 AND ativo = true`,
		u.id, authCodeTypePIN,
	).Scan(&pinHash); err != nil {
		if err == pgx.ErrNoRows {
			h.logAuthAttempt(r, u, body.Email, false, "pin não configurado")
		} else {
			h.logAuthAttempt(r, u, body.Email, false, "erro interno")
		}
		jsonErr(w, "Credenciais inválidas", http.StatusUnauthorized)
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(pinHash), []byte(body.PIN)); err != nil {
		h.logAuthAttempt(r, u, body.Email, false, "pin incorrecto")
		jsonErr(w, "Credenciais inválidas", http.StatusUnauthorized)
		return
	}

	h.logAuthAttempt(r, u, body.Email, true, nil)

	// Resolve funcionario_id para uniformizar a identidade do utilizador no
	// contexto de assiduidade.
	var funcionarioID *int64
	if u.tenantID > 0 {
		svc := funcionario.NewService(h.db)
		if f, err := svc.PorUserID(r.Context(), u.tenantID, u.id); err == nil {
			funcionarioID = &f.ID
		}
	}

	h.issueFuncionarioTokens(w, r, u, funcionarioID)
}

// ── Verificação de PIN/TOTP para prova de presença (assiduidade) ───────────
//
// Distintos de LoginPorPIN/ValidarTOTP: aqueles autenticam um utilizador
// ainda SEM sessão e emitem tokens novos (fluxo de login). Estes dois
// verificam o código de um utilizador JÁ AUTENTICADO (RequireAuth) — não
// emitem tokens nem tocam na sessão existente. Existem porque marcar ponto
// por PIN/TOTP não é um login: o colaborador já está autenticado na app, só
// precisa de provar "sou mesmo eu, agora" antes de bater o ponto — a mesma
// distinção que /biometric/verify (FaceClock) já faz para a biometria facial
// (verifica identidade sem emitir sessão nova). Antes destes endpoints
// existirem, a app reaproveitava LoginPorPIN/ValidarTOTP para marcar ponto,
// o que substituía silenciosamente a sessão activa do utilizador a cada
// marcação — confuso e conceptualmente errado.

func (h *Handler) VerificarPIN(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	if user == nil {
		jsonErr(w, "Não autenticado", http.StatusUnauthorized)
		return
	}

	var body struct {
		PIN string `json:"pin"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.PIN == "" {
		jsonErr(w, "pin é obrigatório", http.StatusBadRequest)
		return
	}

	var pinHash string
	err := h.db.QueryRow(r.Context(), `
		SELECT secret_hash FROM auth.user_auth_codes
		 WHERE user_id = $1 AND tipo = $2 AND ativo = true`,
		user.ID, authCodeTypePIN,
	).Scan(&pinHash)
	if err != nil {
		jsonOK(w, map[string]any{"match": false, "reason": "pin_nao_configurado"}, http.StatusOK)
		return
	}

	if bcrypt.CompareHashAndPassword([]byte(pinHash), []byte(body.PIN)) != nil {
		jsonOK(w, map[string]any{"match": false, "reason": "pin_incorrecto"}, http.StatusOK)
		return
	}

	jsonOK(w, map[string]any{"match": true}, http.StatusOK)
}

func (h *Handler) VerificarTOTP(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	if user == nil {
		jsonErr(w, "Não autenticado", http.StatusUnauthorized)
		return
	}

	var body struct {
		Code string `json:"code"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Code == "" {
		jsonErr(w, "code é obrigatório", http.StatusBadRequest)
		return
	}

	var secret string
	err := h.db.QueryRow(r.Context(), `
		SELECT secret_hash FROM auth.user_auth_codes
		 WHERE user_id = $1 AND tipo = $2 AND ativo = true`,
		user.ID, authCodeTypeTOTP,
	).Scan(&secret)
	if err != nil {
		jsonOK(w, map[string]any{"match": false, "reason": "totp_nao_configurado"}, http.StatusOK)
		return
	}

	if !totp.Validate(body.Code, secret) {
		jsonOK(w, map[string]any{"match": false, "reason": "codigo_invalido"}, http.StatusOK)
		return
	}

	jsonOK(w, map[string]any{"match": true}, http.StatusOK)
}

// ── TOTP ─────────────────────────────────────────────────────────────────────

func (h *Handler) SetupTOTP(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	if user == nil {
		jsonErr(w, "Não autenticado", http.StatusUnauthorized)
		return
	}

	var body struct {
		Password string `json:"password"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	// Opcional: exigir password para reautenticação ao configurar TOTP.
	if body.Password != "" {
		var passwordHash string
		if err := h.db.QueryRow(r.Context(), `SELECT password_hash FROM users WHERE id = $1`, user.ID).Scan(&passwordHash); err != nil {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		if err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(body.Password)); err != nil {
			jsonErr(w, "Password incorrecta", http.StatusForbidden)
			return
		}
	}

	var email string
	if err := h.db.QueryRow(r.Context(), `SELECT email FROM users WHERE id = $1`, user.ID).Scan(&email); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	key, err := totp.Generate(totp.GenerateOpts{
		Issuer:      "Nexora",
		AccountName: email,
	})
	if err != nil {
		jsonErr(w, "Erro ao gerar TOTP", http.StatusInternalServerError)
		return
	}

	_, err = h.db.Exec(r.Context(), `
		INSERT INTO auth.user_auth_codes (user_id, tipo, secret_hash, created_by)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (user_id, tipo) DO UPDATE
		   SET secret_hash = EXCLUDED.secret_hash,
		       ativo = true,
		       updated_at = NOW(),
		       created_by = EXCLUDED.created_by,
		       revoked_at = NULL`,
		user.ID, authCodeTypeTOTP, key.Secret(), user.ID,
	)
	if err != nil {
		jsonErr(w, "Erro ao guardar TOTP", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]interface{}{
		"secret":           key.Secret(),
		"provisioning_uri": key.URL(),
	}, http.StatusOK)
}

func (h *Handler) ValidarTOTP(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Email string `json:"email"`
		Code  string `json:"code"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Email == "" || body.Code == "" {
		jsonErr(w, "email e code são obrigatórios", http.StatusBadRequest)
		return
	}

	u, err := h.lookupUserByEmail(r.Context(), body.Email)
	if err != nil {
		h.logAuthAttempt(r, nil, body.Email, false, "utilizador não encontrado")
		jsonErr(w, "Credenciais inválidas", http.StatusUnauthorized)
		return
	}

	if u.estado != "ativo" {
		h.logAuthAttempt(r, u, body.Email, false, "conta "+u.estado)
		jsonErr(w, "Conta "+u.estado, http.StatusForbidden)
		return
	}

	var secret string
	if err := h.db.QueryRow(r.Context(), `
		SELECT secret_hash FROM auth.user_auth_codes
		 WHERE user_id = $1 AND tipo = $2 AND ativo = true`,
		u.id, authCodeTypeTOTP,
	).Scan(&secret); err != nil {
		if err == pgx.ErrNoRows {
			h.logAuthAttempt(r, u, body.Email, false, "totp não configurado")
		} else {
			h.logAuthAttempt(r, u, body.Email, false, "erro interno")
		}
		jsonErr(w, "Credenciais inválidas", http.StatusUnauthorized)
		return
	}

	if !totp.Validate(body.Code, secret) {
		h.logAuthAttempt(r, u, body.Email, false, "código totp inválido")
		jsonErr(w, "Credenciais inválidas", http.StatusUnauthorized)
		return
	}

	h.logAuthAttempt(r, u, body.Email, true, nil)
	h.issueFuncionarioTokens(w, r, u, nil)
}

// ── Admin: definir PIN ───────────────────────────────────────────────────────

func (h *Handler) AdminDefinirPIN(w http.ResponseWriter, r *http.Request) {
	var body struct {
		UserID int64  `json:"user_id"`
		PIN    string `json:"pin"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.UserID <= 0 || body.PIN == "" {
		jsonErr(w, "user_id e pin são obrigatórios", http.StatusBadRequest)
		return
	}
	if len(body.PIN) < pinMinLength {
		jsonErr(w, fmt.Sprintf("pin deve ter no mínimo %d caracteres", pinMinLength), http.StatusBadRequest)
		return
	}

	admin := mw.GetUser(r)

	// Verificar que o utilizador alvo existe, é elegível e pertence ao mesmo tenant (ou superadmin).
	var targetEstado, targetTipo string
	var targetTenantID int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT u.estado, u.tipo, COALESCE(m.tenant_id, 0)
		  FROM users u
		  LEFT JOIN auth.memberships m ON m.user_id = u.id AND m.ativo = true
		 WHERE u.id = $1
		 ORDER BY m.principal DESC NULLS LAST, m.id ASC
		 LIMIT 1`, body.UserID,
	).Scan(&targetEstado, &targetTipo, &targetTenantID); err != nil {
		if err == pgx.ErrNoRows {
			jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		} else {
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
		}
		return
	}
	if targetEstado != "ativo" {
		jsonErr(w, "Utilizador inativo", http.StatusForbidden)
		return
	}
	if targetTipo != "funcionario" && targetTipo != "superadmin" {
		jsonErr(w, "Tipo de utilizador não suportado", http.StatusForbidden)
		return
	}
	if admin.Tipo != "superadmin" && targetTenantID != admin.TenantID {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}

	pinHash, err := bcrypt.GenerateFromPassword([]byte(body.PIN), 12)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	_, err = h.db.Exec(r.Context(), `
		INSERT INTO auth.user_auth_codes (user_id, tipo, secret_hash, created_by)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (user_id, tipo) DO UPDATE
		   SET secret_hash = EXCLUDED.secret_hash,
		       ativo = true,
		       updated_at = NOW(),
		       created_by = EXCLUDED.created_by,
		       revoked_at = NULL`,
		body.UserID, authCodeTypePIN, string(pinHash), admin.ID,
	)
	if err != nil {
		jsonErr(w, "Erro ao guardar PIN", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ── Reautenticação (step-up) ─────────────────────────────────────────────────

// Reauth emite um novo access token com reauth_at atualizado, exigindo
// password e/ou TOTP do utilizador já autenticado. Usado por superadmin para
// operações críticas.
func (h *Handler) Reauth(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	if user == nil {
		jsonErr(w, "Não autenticado", http.StatusUnauthorized)
		return
	}

	var body struct {
		Password string `json:"password"`
		TOTP     string `json:"totp"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	var passwordHash, email, estado string
	var tenantID, membershipID int64
	err := h.db.QueryRow(r.Context(), `
		SELECT u.password_hash, u.email, u.estado, COALESCE(m.tenant_id, 0), COALESCE(m.id, 0)
		  FROM users u
		  LEFT JOIN auth.memberships m ON m.user_id = u.id AND m.ativo = true
		 WHERE u.id = $1
		 ORDER BY m.principal DESC NULLS LAST, m.id ASC
		 LIMIT 1`, user.ID,
	).Scan(&passwordHash, &email, &estado, &tenantID, &membershipID)
	if err != nil {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
	if estado != "ativo" {
		jsonErr(w, "Conta "+estado, http.StatusForbidden)
		return
	}

	// Validar password se fornecida.
	if body.Password != "" {
		if bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(body.Password)) != nil {
			h.logAuthAttempt(r, &userIdentity{id: user.ID, tenantID: tenantID, email: email}, email, false, "password inválida na reauth")
			jsonErr(w, "Credenciais inválidas", http.StatusUnauthorized)
			return
		}
	}

	// Validar TOTP se configurado.
	var totpSecret string
	totpErr := h.db.QueryRow(r.Context(), `
		SELECT secret_hash FROM auth.user_auth_codes
		 WHERE user_id = $1 AND tipo = $2 AND ativo = true`,
		user.ID, authCodeTypeTOTP,
	).Scan(&totpSecret)
	if totpErr == nil {
		if body.TOTP == "" || !totp.Validate(body.TOTP, totpSecret) {
			h.logAuthAttempt(r, &userIdentity{id: user.ID, tenantID: tenantID, email: email}, email, false, "totp inválido na reauth")
			jsonErr(w, "Código TOTP inválido", http.StatusUnauthorized)
			return
		}
	}

	// Se não forneceu password nem TOTP e não tem TOTP configurado, exige password.
	if body.Password == "" && totpErr != nil {
		jsonErr(w, "Password é obrigatória", http.StatusBadRequest)
		return
	}

	h.logAuthAttempt(r, &userIdentity{id: user.ID, tenantID: tenantID, email: email}, email, true, "reauth")

	// Emitir novo access token com reauth_at atualizado.
	userAccess, _ := models.LoadUserAccess(r.Context(), h.db, user.ID, membershipID)
	scope := ""
	if userAccess != nil {
		scope = scopeStringFromAccess(userAccess)
	}
	escopo := user.Escopo
	if escopo == "" {
		escopo = "erp"
	}
	accessToken, _, err := h.signOAuthAccessToken(user.ID, tenantID, membershipID, user.Tipo, escopo, scope, h.cfg.JWTExpiresIn, time.Now())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	expiresAt := time.Now().Add(h.cfg.JWTExpiresIn)
	if err := h.insertSession(r, user.ID, mw.HashToken(accessToken), expiresAt); err != nil {
		jsonErr(w, "Erro ao criar sessão", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]interface{}{
		"access_token": accessToken,
		"token_type":   "Bearer",
		"expires_in":   int(h.cfg.JWTExpiresIn.Seconds()),
	}, http.StatusOK)
}

