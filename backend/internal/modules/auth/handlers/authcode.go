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
func (h *Handler) issueFuncionarioTokens(w http.ResponseWriter, r *http.Request, u *userIdentity) {
	accessToken, err := h.signAccess(u.id, u.tenantID, u.membershipID, u.tipo, u.escopo)
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

	userAccess, _ := models.LoadUserAccess(r.Context(), h.db, u.id, u.membershipID)

	userObj := map[string]interface{}{
		"id":     u.id,
		"nome":   u.nome,
		"email":  u.email,
		"escopo": escoposPorTipoEscopo(u.tipo, u.escopo),
	}
	modulos := []models.ModuloAcesso{}
	features := []string{}
	if userAccess != nil {
		userObj["tenant_id"] = userAccess.TenantID
		userObj["cargo_id"] = userAccess.CargoID
		if userAccess.CargoNome != nil {
			userObj["cargo"] = *userAccess.CargoNome
		}
		modulos = userAccess.Modulos
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
		"modulos":       modulos,
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
	h.issueFuncionarioTokens(w, r, u)
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
	h.issueFuncionarioTokens(w, r, u)
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

	// Verificar que o utilizador alvo existe e é elegível (funcionário/superadmin).
	var targetEstado, targetTipo string
	if err := h.db.QueryRow(r.Context(), `
		SELECT estado, tipo FROM users WHERE id = $1`, body.UserID,
	).Scan(&targetEstado, &targetTipo); err != nil {
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

