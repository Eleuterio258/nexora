package handlers

import (
	"encoding/json"
	"net"
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

const (
	portalJWTExpiry      = 8 * time.Hour
	encarregadoJWTExpiry = 8 * time.Hour
	candidatoJWTExpiry   = 30 * 24 * time.Hour
)

func (h *Handler) signAccess(userID, tenantID int64, tipo, escopo string) (string, error) {
	if escopo == "" {
		escopo = "erp"
	}
	jti, err := randomJTI()
	if err != nil {
		return "", err
	}
	claims := jwt.MapClaims{
		"sub":    userID,
		"tid":    tenantID,
		"tipo":   tipo,
		"escopo": escopo,
		"jti":    jti,
		"exp":    time.Now().Add(h.cfg.JWTExpiresIn).Unix(),
		"iat":    time.Now().Unix(),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(h.cfg.JWTSecret))
}

func (h *Handler) signRefresh(userID int64) (string, error) {
	jti, err := randomJTI()
	if err != nil {
		return "", err
	}
	claims := jwt.MapClaims{
		"sub": userID,
		"jti": jti,
		"exp": time.Now().Add(h.cfg.JWTRefreshExpiresIn).Unix(),
		"iat": time.Now().Unix(),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(h.cfg.JWTRefreshSecret))
}

func (h *Handler) signAlunoToken(studentID, tenantID int64) (string, error) {
	jti, err := randomJTI()
	if err != nil {
		return "", err
	}
	claims := jwt.MapClaims{
		"sub":  studentID,
		"tid":  tenantID,
		"tipo": "aluno",
		"jti":  jti,
		"exp":  time.Now().Add(portalJWTExpiry).Unix(),
		"iat":  time.Now().Unix(),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(h.cfg.JWTSecret))
}

func (h *Handler) signEncarregadoToken(email string, tenantID int64) (string, error) {
	jti, err := randomJTI()
	if err != nil {
		return "", err
	}
	claims := jwt.MapClaims{
		"email": email,
		"tid":   tenantID,
		"tipo":  "encarregado",
		"jti":   jti,
		"exp":   time.Now().Add(encarregadoJWTExpiry).Unix(),
		"iat":   time.Now().Unix(),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(h.cfg.JWTSecret))
}

func (h *Handler) signCandidatoToken(candidatoID, tenantID int64) (string, error) {
	jti, err := randomJTI()
	if err != nil {
		return "", err
	}
	claims := jwt.MapClaims{
		"sub":  candidatoID,
		"tid":  tenantID,
		"tipo": "candidato",
		"jti":  jti,
		"exp":  time.Now().Add(candidatoJWTExpiry).Unix(),
		"iat":  time.Now().Unix(),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(h.cfg.JWTSecret))
}

// clientIP devolve o IP sem porta, para colunas do tipo inet (ex.: candidato_sessions.ip).
func clientIP(r *http.Request) string {
	if host, _, err := net.SplitHostPort(r.RemoteAddr); err == nil {
		return host
	}
	return r.RemoteAddr
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
		escopo       string
	)

	// tenant_id vem da membership — superadmins não têm membership (tenant_id = 0)
	err := h.db.QueryRow(r.Context(), `
		SELECT u.id, COALESCE(m.tenant_id, 0), u.nome, u.password_hash, u.estado, u.tipo, COALESCE(NULLIF(m.escopo, ''), 'erp')
		  FROM users u
		  LEFT JOIN auth.memberships m ON m.user_id = u.id AND m.ativo = true
		 WHERE u.email = LOWER($1)`,
		body.Email,
	).Scan(&userID, &tenantID, &nome, &passwordHash, &estado, &tipo, &escopo)

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
		nullInt(tenantID, tenantID > 0),
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
	switch tipo {
	case "aluno":
		h.loginAluno(w, r, userID, nome)
	case "encarregado":
		h.loginEncarregado(w, r, userID, nome)
	case "candidato":
		h.LoginCandidato(w, r, userID, nome)
	default:
		h.loginFuncionario(w, r, userID, tenantID, nome, body.Email, tipo, escopo)
	}
}

func (h *Handler) loginFuncionario(w http.ResponseWriter, r *http.Request, userID, tenantID int64, nome, email, tipo, escopo string) {
	h.issueFuncionarioTokens(w, r, &userIdentity{
		id:       userID,
		tenantID: tenantID,
		nome:     nome,
		email:    email,
		estado:   "ativo",
		tipo:     tipo,
		escopo:   escopo,
	})
}

func (h *Handler) loginAluno(w http.ResponseWriter, r *http.Request, userID int64, nome string) {
	var studentID, tenantID int64
	var codigo string
	if err := h.db.QueryRow(r.Context(), `
		SELECT id, tenant_id, codigo
		  FROM gestao_escolar.school_students
		 WHERE user_id = $1
		 LIMIT 1`,
		userID,
	).Scan(&studentID, &tenantID, &codigo); err != nil {
		jsonErr(w, "Aluno não encontrado", http.StatusForbidden)
		return
	}

	accessToken, err := h.signAlunoToken(studentID, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	refreshToken, err := h.signRefresh(userID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	expiresAt := time.Now().Add(portalJWTExpiry)
	_, err = h.db.Exec(r.Context(), `
		INSERT INTO gestao_escolar.portal_sessions
			(student_id, tenant_id, token_hash, ip_address, user_agent, expira_em)
		VALUES ($1, $2, $3, $4, $5, $6)`,
		studentID, tenantID, mw.HashToken(accessToken),
		r.RemoteAddr, r.Header.Get("User-Agent"), expiresAt,
	)
	if err != nil {
		jsonErr(w, "Erro ao criar sessão", http.StatusInternalServerError)
		return
	}

	h.db.Exec(r.Context(), `UPDATE users SET ultimo_login_em = NOW() WHERE id = $1`, userID)

	jsonOK(w, map[string]interface{}{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"token_type":    "Bearer",
		"expires_in":    int(portalJWTExpiry.Seconds()),
		"tipo":          "aluno",
		"escopo":        escoposPorTipoEscopo("aluno", ""),
		"aluno": map[string]interface{}{
			"id":     studentID,
			"nome":   nome,
			"codigo": codigo,
			"escopo": escoposPorTipoEscopo("aluno", ""),
		},
	}, http.StatusOK)
}

func (h *Handler) loginEncarregado(w http.ResponseWriter, r *http.Request, userID int64, nome string) {
	var tenantID int64
	var email string
	if err := h.db.QueryRow(r.Context(), `
		SELECT tenant_id, portal_email
		  FROM gestao_escolar.school_guardians
		 WHERE user_id = $1 AND portal_ativo = true
		 ORDER BY principal DESC
		 LIMIT 1`,
		userID,
	).Scan(&tenantID, &email); err != nil {
		jsonErr(w, "Portal do encarregado não activado", http.StatusForbidden)
		return
	}

	accessToken, err := h.signEncarregadoToken(email, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	refreshToken, err := h.signRefresh(userID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	expiresAt := time.Now().Add(encarregadoJWTExpiry)
	_, err = h.db.Exec(r.Context(), `
		INSERT INTO gestao_escolar.guardian_portal_sessions
			(guardian_email, tenant_id, token_hash, ip_address, user_agent, expira_em)
		VALUES ($1, $2, $3, $4, $5, $6)`,
		email, tenantID, mw.HashToken(accessToken),
		r.RemoteAddr, r.Header.Get("User-Agent"), expiresAt,
	)
	if err != nil {
		jsonErr(w, "Erro ao criar sessão", http.StatusInternalServerError)
		return
	}

	h.db.Exec(r.Context(), `UPDATE users SET ultimo_login_em = NOW() WHERE id = $1`, userID)

	jsonOK(w, map[string]interface{}{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"token_type":    "Bearer",
		"expires_in":    int(encarregadoJWTExpiry.Seconds()),
		"tipo":          "encarregado",
		"escopo":        escoposPorTipoEscopo("encarregado", ""),
		"encarregado": map[string]interface{}{
			"nome":      nome,
			"email":     email,
			"tenant_id": tenantID,
			"escopo":    escoposPorTipoEscopo("encarregado", ""),
		},
	}, http.StatusOK)
}

func (h *Handler) LoginCandidato(w http.ResponseWriter, r *http.Request, userID int64, nome string) {
	var candidatoID, tenantID int64
	var email string
	var ativo bool
	if err := h.db.QueryRow(r.Context(), `
		SELECT id, tenant_id, email, ativo
		  FROM recrutamento.candidatos
		 WHERE user_id = $1
		 ORDER BY updated_at DESC
		 LIMIT 1`,
		userID,
	).Scan(&candidatoID, &tenantID, &email, &ativo); err != nil {
		jsonErr(w, "Conta de candidato não encontrada", http.StatusForbidden)
		return
	}
	if !ativo {
		jsonErr(w, "Conta de candidato inactiva", http.StatusForbidden)
		return
	}

	accessToken, err := h.signCandidatoToken(candidatoID, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	refreshToken, err := h.signRefresh(userID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	expiresAt := time.Now().Add(candidatoJWTExpiry)
	_, err = h.db.Exec(r.Context(), `
		INSERT INTO recrutamento.candidato_sessions (candidato_id, token_hash, ip, user_agent, expira_em)
		VALUES ($1, $2, $3, $4, $5)`,
		candidatoID, mw.HashToken(accessToken), clientIP(r), r.Header.Get("User-Agent"), expiresAt,
	)
	if err != nil {
		jsonErr(w, "Erro ao criar sessão", http.StatusInternalServerError)
		return
	}

	h.db.Exec(r.Context(), `UPDATE users SET ultimo_login_em = NOW() WHERE id = $1`, userID)

	jsonOK(w, map[string]interface{}{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"token_type":    "Bearer",
		"expires_in":    int(candidatoJWTExpiry.Seconds()),
		"tipo":          "candidato",
		"escopo":        escoposPorTipoEscopo("candidato", ""),
		"candidato": map[string]interface{}{
			"id":        candidatoID,
			"nome":      nome,
			"email":     email,
			"tenant_id": tenantID,
			"escopo":    escoposPorTipoEscopo("candidato", ""),
		},
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
	var estado, tipo, escopo string
	err = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(m.tenant_id, 0), u.estado, u.tipo, COALESCE(NULLIF(m.escopo, ''), 'erp')
		  FROM users u LEFT JOIN auth.memberships m ON m.user_id = u.id AND m.ativo = true
		 WHERE u.id = $1`, userID).
		Scan(&tenantID, &estado, &tipo, &escopo)
	if err == pgx.ErrNoRows || estado != "ativo" {
		jsonErr(w, "Utilizador inactivo", http.StatusUnauthorized)
		return
	}

	switch tipo {
	case "aluno":
		h.refreshAluno(w, r, userID)
	case "encarregado":
		h.refreshEncarregado(w, r, userID)
	case "candidato":
		h.refreshCandidato(w, r, userID)
	default:
		accessToken, err := h.signAccess(userID, tenantID, tipo, escopo)
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
			"escopo":       escoposPorTipoEscopo(tipo, escopo),
		}, http.StatusOK)
	}
}

func (h *Handler) refreshAluno(w http.ResponseWriter, r *http.Request, userID int64) {
	var studentID, tenantID int64
	var nome, codigo string
	if err := h.db.QueryRow(r.Context(), `
		SELECT id, tenant_id, nome, codigo
		  FROM gestao_escolar.school_students
		 WHERE user_id = $1
		 LIMIT 1`,
		userID,
	).Scan(&studentID, &tenantID, &nome, &codigo); err != nil {
		jsonErr(w, "Aluno não encontrado", http.StatusForbidden)
		return
	}

	accessToken, err := h.signAlunoToken(studentID, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	expiresAt := time.Now().Add(portalJWTExpiry)
	_, err = h.db.Exec(r.Context(), `
		INSERT INTO gestao_escolar.portal_sessions
			(student_id, tenant_id, token_hash, ip_address, user_agent, expira_em)
		VALUES ($1, $2, $3, $4, $5, $6)`,
		studentID, tenantID, mw.HashToken(accessToken),
		r.RemoteAddr, r.Header.Get("User-Agent"), expiresAt,
	)
	if err != nil {
		jsonErr(w, "Erro ao criar sessão", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]interface{}{
		"access_token": accessToken,
		"token_type":   "Bearer",
		"expires_in":   int(portalJWTExpiry.Seconds()),
		"tipo":         "aluno",
		"escopo":       escoposPorTipoEscopo("aluno", ""),
		"aluno": map[string]interface{}{
			"id":     studentID,
			"nome":   nome,
			"codigo": codigo,
			"escopo": escoposPorTipoEscopo("aluno", ""),
		},
	}, http.StatusOK)
}

func (h *Handler) refreshEncarregado(w http.ResponseWriter, r *http.Request, userID int64) {
	var tenantID int64
	var nome, email string
	if err := h.db.QueryRow(r.Context(), `
		SELECT tenant_id, nome, portal_email
		  FROM gestao_escolar.school_guardians
		 WHERE user_id = $1 AND portal_ativo = true
		 ORDER BY principal DESC
		 LIMIT 1`,
		userID,
	).Scan(&tenantID, &nome, &email); err != nil {
		jsonErr(w, "Portal do encarregado não activado", http.StatusForbidden)
		return
	}

	accessToken, err := h.signEncarregadoToken(email, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	expiresAt := time.Now().Add(encarregadoJWTExpiry)
	_, err = h.db.Exec(r.Context(), `
		INSERT INTO gestao_escolar.guardian_portal_sessions
			(guardian_email, tenant_id, token_hash, ip_address, user_agent, expira_em)
		VALUES ($1, $2, $3, $4, $5, $6)`,
		email, tenantID, mw.HashToken(accessToken),
		r.RemoteAddr, r.Header.Get("User-Agent"), expiresAt,
	)
	if err != nil {
		jsonErr(w, "Erro ao criar sessão", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]interface{}{
		"access_token": accessToken,
		"token_type":   "Bearer",
		"expires_in":   int(encarregadoJWTExpiry.Seconds()),
		"tipo":         "encarregado",
		"escopo":       escoposPorTipoEscopo("encarregado", ""),
		"encarregado": map[string]interface{}{
			"nome":      nome,
			"email":     email,
			"tenant_id": tenantID,
			"escopo":    escoposPorTipoEscopo("encarregado", ""),
		},
	}, http.StatusOK)
}

func (h *Handler) refreshCandidato(w http.ResponseWriter, r *http.Request, userID int64) {
	var candidatoID, tenantID int64
	var nome, email string
	var ativo bool
	if err := h.db.QueryRow(r.Context(), `
		SELECT id, tenant_id, nome, email, ativo
		  FROM recrutamento.candidatos
		 WHERE user_id = $1
		 ORDER BY updated_at DESC
		 LIMIT 1`,
		userID,
	).Scan(&candidatoID, &tenantID, &nome, &email, &ativo); err != nil {
		jsonErr(w, "Conta de candidato não encontrada", http.StatusForbidden)
		return
	}
	if !ativo {
		jsonErr(w, "Conta de candidato inactiva", http.StatusForbidden)
		return
	}

	accessToken, err := h.signCandidatoToken(candidatoID, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	expiresAt := time.Now().Add(candidatoJWTExpiry)
	_, err = h.db.Exec(r.Context(), `
		INSERT INTO recrutamento.candidato_sessions (candidato_id, token_hash, ip, user_agent, expira_em)
		VALUES ($1, $2, $3, $4, $5)`,
		candidatoID, mw.HashToken(accessToken), clientIP(r), r.Header.Get("User-Agent"), expiresAt,
	)
	if err != nil {
		jsonErr(w, "Erro ao criar sessão", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]interface{}{
		"access_token": accessToken,
		"token_type":   "Bearer",
		"expires_in":   int(candidatoJWTExpiry.Seconds()),
		"tipo":         "candidato",
		"escopo":       escoposPorTipoEscopo("candidato", ""),
		"candidato": map[string]interface{}{
			"id":        candidatoID,
			"nome":      nome,
			"email":     email,
			"tenant_id": tenantID,
			"escopo":    escoposPorTipoEscopo("candidato", ""),
		},
	}, http.StatusOK)
}

// ── Me ────────────────────────────────────────────────────────────────────────

func (h *Handler) Me(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	row := h.db.QueryRow(r.Context(), `
		SELECT u.id, COALESCE(m.tenant_id, 0), u.nome, u.email, u.telefone,
		       u.estado, u.email_verificado, u.ultimo_login_em, u.created_at,
		       COALESCE(NULLIF(m.escopo, ''), 'erp')
		  FROM users u
		  LEFT JOIN auth.memberships m ON m.user_id = u.id AND m.ativo = true AND m.ativo = true
		 WHERE u.id = $1`, user.ID)

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
		Escopo          string     `json:"escopo"`
	}
	if err := row.Scan(&u.ID, &u.TenantID, &u.Nome, &u.Email, &u.Telefone,
		&u.Estado, &u.EmailVerificado, &u.UltimoLoginEm, &u.CreatedAt, &u.Escopo); err != nil {
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

// gatewayAppRole traduz a identidade ERP (tipo + permissões RBAC) para o
// vocabulário de role usado por consumidores externos de confiança (hoje só o
// FaceClock, via GET /api/auth/gateway/validate) — "ADMIN_SISTEMA"/"GESTOR_RH"/
// "COLABORADOR". O ERP não tem estes três roles como conceito nativo (só
// `tipo` + permissões RBAC finas), por isso este mapeamento vive aqui, não no
// consumidor: só o ERP sabe calcular permissões a partir de cargo/permissões
// diretas/tipo. GESTOR_RH é definido operacionalmente como "tem a permissão
// recursos-humanos.aprovar_ausencias" — a mesma que already protege
// POST /api/rh/ausencias/{id}/aprovar no router (não existe um role
// dedicado "gestor" na tabela auth.users.tipo).
func gatewayAppRole(ua *models.UserAccess) string {
	if ua.Tipo == "superadmin" {
		return "ADMIN_SISTEMA"
	}
	if ua.Can("recursos-humanos", "aprovar_ausencias") {
		return "GESTOR_RH"
	}
	return "COLABORADOR"
}

func (h *Handler) GatewayValidate(w http.ResponseWriter, r *http.Request) {
	user := mw.GetUser(r)
	var id, tenantID int64
	var nome, email, escopo, tipo string
	err := h.db.QueryRow(r.Context(), `
		SELECT u.id, COALESCE(m.tenant_id, 0), u.nome, u.email, COALESCE(NULLIF(m.escopo, ''), 'erp'), u.tipo
		  FROM users u LEFT JOIN auth.memberships m ON m.user_id = u.id AND m.ativo = true
		 WHERE u.id = $1`, user.ID).
		Scan(&id, &tenantID, &nome, &email, &escopo, &tipo)
	if err != nil {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}

	appRole := "COLABORADOR"
	if ua, err := models.LoadUserAccess(r.Context(), h.db, id); err == nil {
		appRole = gatewayAppRole(ua)
	}

	w.Header().Set("X-Auth-User-Id", itoa(id))
	w.Header().Set("X-Auth-Tenant-Id", itoa(tenantID))
	w.Header().Set("X-Auth-Session-Id", itoa(user.SessionID))
	w.Header().Set("X-Auth-User-Email", email)
	w.Header().Set("X-Auth-User-Name", nome)
	w.Header().Set("X-Auth-User-Scope", escopo)
	w.Header().Set("X-Auth-User-Role", appRole)
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

func randomJTI() (string, error) {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

func escoposPorTipoEscopo(tipo, escopo string) []string {
	switch tipo {
	case "superadmin":
		return []string{"superadmin"}
	case "aluno":
		return []string{"portal_aluno"}
	case "encarregado":
		return []string{"portal_encarregado"}
	case "candidato":
		return []string{"portal_candidato"}
	}
	switch escopo {
	case "escola":
		return []string{"escola"}
	case "portal_professor":
		return []string{"portal_professor"}
	default:
		return []string{"erp"}
	}
}
