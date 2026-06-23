package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"crypto/rand"
	"encoding/hex"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
	"nexora/internal/modules/auth/models"
)

// ── helpers ──────────────────────────────────────────────────────────────────

func (h *Handler) signAccess(userID, tenantID int64, tipo string) (string, error) {
	claims := jwt.MapClaims{
		"sub":  userID,
		"tid":  tenantID,
		"tipo": tipo,
		"exp":  time.Now().Add(h.cfg.JWTExpiresIn).Unix(),
		"iat":  time.Now().Unix(),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(h.cfg.JWTSecret))
}

func (h *Handler) signRefresh(userID int64) (string, error) {
	claims := jwt.MapClaims{
		"sub": userID,
		"exp": time.Now().Add(h.cfg.JWTRefreshExpiresIn).Unix(),
		"iat": time.Now().Unix(),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(h.cfg.JWTRefreshSecret))
}

func (h *Handler) insertSession(r *http.Request, userID int64, tokenHash string, expiresAt time.Time) error {
	_, err := h.db.Exec(r.Context(), `
		INSERT INTO sessions (user_id, token_hash, ip_address, user_agent, expira_em)
		VALUES ($1, $2, $3, $4, $5)`,
		userID,
		tokenHash,
		r.RemoteAddr,
		r.Header.Get("User-Agent"),
		expiresAt,
	)
	return err
}

// ── Login ─────────────────────────────────────────────────────────────────────

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Email == "" || body.Password == "" {
		jsonErr(w, "email e password são obrigatórios", http.StatusBadRequest)
		return
	}

	var (
		userID       int64
		tenantID     int64
		nome         string
		passwordHash string
		estado       string
		tipo         string
	)

	// tenant_id e tipo vêm sempre da base de dados — nunca do cliente
	err := h.db.QueryRow(r.Context(), `
		SELECT id, tenant_id, nome, password_hash, estado, tipo
		  FROM users WHERE email = LOWER($1)`,
		body.Email,
	).Scan(&userID, &tenantID, &nome, &passwordHash, &estado, &tipo)

	found := err == nil
	var pwOk bool
	if found {
		pwOk = bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(body.Password)) == nil
	}

	// fire-and-forget audit log
	go h.db.Exec(r.Context(), `
		INSERT INTO login_history (user_id, tenant_id, email_tentado, sucesso, ip_address, user_agent, motivo_falha)
		VALUES ($1, $2, LOWER($3), $4, $5, $6, $7)`,
		nullInt(userID, found && pwOk),
		tenantID,
		body.Email,
		found && pwOk,
		r.RemoteAddr,
		r.Header.Get("User-Agent"),
		loginFailReason(found, pwOk),
	)

	if !found || !pwOk {
		jsonErr(w, "Credenciais inválidas", http.StatusUnauthorized)
		return
	}
	if estado != "ativo" {
		jsonErr(w, "Conta "+estado, http.StatusForbidden)
		return
	}

	accessToken, err := h.signAccess(userID, tenantID, tipo)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	refreshToken, err := h.signRefresh(userID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	expiresAt := time.Now().Add(h.cfg.JWTExpiresIn)
	if err := h.insertSession(r, userID, mw.HashToken(accessToken), expiresAt); err != nil {
		jsonErr(w, "Erro ao criar sessão", http.StatusInternalServerError)
		return
	}

	h.db.Exec(r.Context(), `UPDATE users SET ultimo_login_em = NOW() WHERE id = $1`, userID)

	// Carregar permissões organizadas por módulo
	access, _ := models.LoadUserAccess(r.Context(), h.db, userID)
	modulos := []models.ModuloAcesso{}
	var cargoNome interface{} = nil
	if access != nil {
		modulos = access.Modulos
		cargoNome = access.CargoNome
	}

	jsonOK(w, map[string]interface{}{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"token_type":    "Bearer",
		"expires_in":    int(h.cfg.JWTExpiresIn.Seconds()),
		"tipo":          tipo,
		"user": map[string]interface{}{
			"id":    userID,
			"nome":  nome,
			"email": body.Email,
			"cargo": cargoNome,
		},
		"modulos": modulos,
	}, http.StatusOK)
}

// ── Logout ────────────────────────────────────────────────────────────────────

func (h *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	h.db.Exec(r.Context(), `
		UPDATE sessions SET ativa = FALSE, encerrado_em = NOW() WHERE id = $1`, user.SessionID)
	w.WriteHeader(http.StatusNoContent)
}

// ── Refresh ───────────────────────────────────────────────────────────────────

func (h *Handler) Refresh(w http.ResponseWriter, r *http.Request) {
	var body struct {
		RefreshToken string `json:"refresh_token"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.RefreshToken == "" {
		jsonErr(w, "refresh_token é obrigatório", http.StatusBadRequest)
		return
	}

	token, err := jwt.Parse(body.RefreshToken, func(t *jwt.Token) (interface{}, error) {
		return []byte(h.cfg.JWTRefreshSecret), nil
	})
	if err != nil || !token.Valid {
		jsonErr(w, "refresh_token inválido ou expirado", http.StatusUnauthorized)
		return
	}

	claims, _ := token.Claims.(jwt.MapClaims)
	userID := int64(claims["sub"].(float64))

	var tenantID int64
	var estado, tipo string
	err = h.db.QueryRow(r.Context(), `SELECT tenant_id, estado, tipo FROM users WHERE id = $1`, userID).
		Scan(&tenantID, &estado, &tipo)
	if err == pgx.ErrNoRows || estado != "ativo" {
		jsonErr(w, "Utilizador inactivo", http.StatusUnauthorized)
		return
	}

	accessToken, err := h.signAccess(userID, tenantID, tipo)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	expiresAt := time.Now().Add(h.cfg.JWTExpiresIn)
	h.insertSession(r, userID, mw.HashToken(accessToken), expiresAt)

	jsonOK(w, map[string]interface{}{
		"access_token": accessToken,
		"token_type":   "Bearer",
		"expires_in":   int(h.cfg.JWTExpiresIn.Seconds()),
	}, http.StatusOK)
}

// ── Me ────────────────────────────────────────────────────────────────────────

func (h *Handler) Me(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	row := h.db.QueryRow(r.Context(), `
		SELECT id, tenant_id, nome, email, telefone, estado, email_verificado, ultimo_login_em, created_at
		  FROM users WHERE id = $1`, user.ID)

	var u struct {
		ID              int64      `json:"id"`
		TenantID        int64      `json:"tenant_id"`
		Nome            string     `json:"nome"`
		Email           string     `json:"email"`
		Telefone        *string    `json:"telefone"`
		Estado          string     `json:"estado"`
		EmailVerificado bool       `json:"email_verificado"`
		UltimoLoginEm   *time.Time `json:"ultimo_login_em"`
		CreatedAt       time.Time  `json:"created_at"`
	}
	if err := row.Scan(&u.ID, &u.TenantID, &u.Nome, &u.Email, &u.Telefone,
		&u.Estado, &u.EmailVerificado, &u.UltimoLoginEm, &u.CreatedAt); err != nil {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, u, http.StatusOK)
}

// ── Perm Timestamp ───────────────────────────────────────────────────────────
// GET /api/auth/me/perm-ts — devolve o timestamp da última actualização de permissões.
// O PHP usa-o para detectar mudanças feitas pelo admin e fazer sync imediato, sem logout.
func (h *Handler) MePermTs(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var ts time.Time
	err := h.db.QueryRow(r.Context(), `
		SELECT permissoes_atualizadas_em FROM users WHERE id=$1`, user.ID).Scan(&ts)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]int64{"ts": ts.Unix()}, http.StatusOK)
}

// ── Change Password ───────────────────────────────────────────────────────────

func (h *Handler) ChangePassword(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var body struct {
		PasswordActual string `json:"password_actual"`
		NovaPassword   string `json:"nova_password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.PasswordActual == "" || body.NovaPassword == "" {
		jsonErr(w, "password_actual e nova_password são obrigatórios", http.StatusBadRequest)
		return
	}
	if len(body.NovaPassword) < 8 {
		jsonErr(w, "A nova password deve ter pelo menos 8 caracteres", http.StatusBadRequest)
		return
	}

	var hash string
	if err := h.db.QueryRow(r.Context(), `SELECT password_hash FROM users WHERE id = $1`, user.ID).Scan(&hash); err != nil {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
	if bcrypt.CompareHashAndPassword([]byte(hash), []byte(body.PasswordActual)) != nil {
		jsonErr(w, "Password actual incorrecta", http.StatusUnauthorized)
		return
	}

	newHash, _ := bcrypt.GenerateFromPassword([]byte(body.NovaPassword), 12)
	h.db.Exec(r.Context(), `UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2`, string(newHash), user.ID)
	h.db.Exec(r.Context(), `UPDATE sessions SET ativa = FALSE, encerrado_em = NOW() WHERE user_id = $1 AND id != $2`, user.ID, user.SessionID)

	w.WriteHeader(http.StatusNoContent)
}

// ── Forgot Password ───────────────────────────────────────────────────────────

func (h *Handler) ForgotPassword(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Email string `json:"email"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Email == "" {
		jsonErr(w, "email é obrigatório", http.StatusBadRequest)
		return
	}

	var uid int64
	err := h.db.QueryRow(r.Context(), `
		SELECT id FROM users WHERE email = LOWER($1) AND estado = 'ativo'`,
		body.Email).Scan(&uid)

	if err == nil {
		b := make([]byte, 32)
		rand.Read(b)
		token := hex.EncodeToString(b)
		tokenHash := mw.HashToken(token)
		h.db.Exec(r.Context(), `
			INSERT INTO password_resets (user_id, token_hash, expira_em)
			VALUES ($1, $2, NOW() + INTERVAL '1 hour')`, uid, tokenHash)
		// TODO: enqueue email via message broker
	}
	w.WriteHeader(http.StatusNoContent)
}

// ── Reset Password ────────────────────────────────────────────────────────────

func (h *Handler) ResetPassword(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Token        string `json:"token"`
		NovaPassword string `json:"nova_password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Token == "" || body.NovaPassword == "" {
		jsonErr(w, "token e nova_password são obrigatórios", http.StatusBadRequest)
		return
	}
	if len(body.NovaPassword) < 8 {
		jsonErr(w, "A nova password deve ter pelo menos 8 caracteres", http.StatusBadRequest)
		return
	}

	tokenHash := mw.HashToken(body.Token)
	var resetID, userID int64
	err := h.db.QueryRow(r.Context(), `
		SELECT id, user_id FROM password_resets
		 WHERE token_hash = $1 AND usado_em IS NULL AND expira_em > NOW()`, tokenHash).
		Scan(&resetID, &userID)
	if err != nil {
		jsonErr(w, "Token inválido ou expirado", http.StatusBadRequest)
		return
	}

	newHash, _ := bcrypt.GenerateFromPassword([]byte(body.NovaPassword), 12)
	h.db.Exec(r.Context(), `UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2`, string(newHash), userID)
	h.db.Exec(r.Context(), `UPDATE password_resets SET usado_em = NOW() WHERE id = $1`, resetID)
	h.db.Exec(r.Context(), `UPDATE sessions SET ativa = FALSE, encerrado_em = NOW() WHERE user_id = $1`, userID)

	w.WriteHeader(http.StatusNoContent)
}

// ── Verify Email ──────────────────────────────────────────────────────────────

func (h *Handler) VerifyEmail(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Token string `json:"token"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Token == "" {
		jsonErr(w, "token é obrigatório", http.StatusBadRequest)
		return
	}

	tokenHash := mw.HashToken(body.Token)
	var verID, userID int64
	err := h.db.QueryRow(r.Context(), `
		SELECT id, user_id FROM email_verifications
		 WHERE token_hash = $1 AND usado_em IS NULL AND expira_em > NOW()`, tokenHash).
		Scan(&verID, &userID)
	if err != nil {
		jsonErr(w, "Token inválido ou expirado", http.StatusBadRequest)
		return
	}

	h.db.Exec(r.Context(), `UPDATE users SET email_verificado = TRUE, updated_at = NOW() WHERE id = $1`, userID)
	h.db.Exec(r.Context(), `UPDATE email_verifications SET usado_em = NOW() WHERE id = $1`, verID)

	w.WriteHeader(http.StatusNoContent)
}

// ── Gateway Validate ──────────────────────────────────────────────────────────

func (h *Handler) GatewayValidate(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var id, tenantID int64
	var nome, email string
	err := h.db.QueryRow(r.Context(), `SELECT id, tenant_id, nome, email FROM users WHERE id = $1`, user.ID).
		Scan(&id, &tenantID, &nome, &email)
	if err != nil {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
	w.Header().Set("X-Auth-User-Id", itoa(id))
	w.Header().Set("X-Auth-Tenant-Id", itoa(tenantID))
	w.Header().Set("X-Auth-Session-Id", itoa(user.SessionID))
	w.Header().Set("X-Auth-User-Email", email)
	w.Header().Set("X-Auth-User-Name", nome)
	w.WriteHeader(http.StatusNoContent)
}

// ── internal helpers ──────────────────────────────────────────────────────────

func nullInt(v int64, ok bool) interface{} {
	if !ok {
		return nil
	}
	return v
}

func loginFailReason(found, pwOk bool) interface{} {
	if found && pwOk {
		return nil
	}
	if !found {
		return "utilizador não encontrado"
	}
	return "password incorrecta"
}
