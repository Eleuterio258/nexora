package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
)

// ── Login único (PayCore Mobile): utilizador + terminal ──────────────────────
//
// Um só endpoint (POST /api/pos/login) para os dois momentos de login que já
// existem na app: o operador humano (tipo=utilizador, a cada turno) e o
// terminal/aparelho (tipo=terminal, uma vez, na configuração). O terminal é
// autenticado como uma conta de funcionário comum (ver CriarTerminal em
// pos/handlers/pos.go), com um cargo dedicado "Terminal POS" que só tem a
// permissão pos:operar_pos — por isso reaproveita toda a validação/emissão
// de token já usada para utilizadores, só com validade mais longa.
const terminalTokenExpiry = 30 * 24 * time.Hour

func (h *Handler) PosLogin(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Tipo           string `json:"tipo"`
		Email          string `json:"email"`
		Password       string `json:"password"`
		TenantSlug     string `json:"tenant_slug"`
		CodigoTerminal string `json:"codigo_terminal"`
		ActivationCode string `json:"activation_code"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Body inválido", http.StatusBadRequest)
		return
	}

	switch body.Tipo {
	case "utilizador":
		if body.Email == "" || body.Password == "" {
			jsonErr(w, "email e password são obrigatórios", http.StatusBadRequest)
			return
		}
		h.loginWithCredentials(w, r, body.Email, body.Password)
	case "terminal":
		if body.CodigoTerminal == "" || body.ActivationCode == "" {
			jsonErr(w, "codigo_terminal e activation_code são obrigatórios", http.StatusBadRequest)
			return
		}
		h.loginTerminalPOS(w, r, body.CodigoTerminal, body.ActivationCode)
	default:
		jsonErr(w, "tipo inválido: utilizador ou terminal", http.StatusBadRequest)
	}
}

func (h *Handler) PosRefresh(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Tipo          string `json:"tipo"`
		RefreshToken  string `json:"refresh_token"`
		TerminalToken string `json:"terminal_token"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "Body inválido", http.StatusBadRequest)
		return
	}

	switch body.Tipo {
	case "terminal":
		if body.RefreshToken == "" {
			jsonErr(w, "refresh_token é obrigatório", http.StatusBadRequest)
			return
		}
		h.refreshTerminalPOS(w, r, body.RefreshToken)
	default:
		// utilizador: mesmo contrato do endpoint já existente POST /api/auth/refresh
		if body.RefreshToken == "" {
			jsonErr(w, "refresh_token é obrigatório", http.StatusBadRequest)
			return
		}
		h.refreshWithToken(w, r, body.RefreshToken)
	}
}

// loginTerminalPOS resolve o terminal por código (que não é globalmente
// único, só por tenant — pos.pos_terminals UNIQUE(tenant_id, codigo)) e
// desambigua pelo activation_code, comparado por bcrypt contra cada
// candidato, tal como uma password normal.
func (h *Handler) loginTerminalPOS(w http.ResponseWriter, r *http.Request, codigoTerminal, activationCode string) {
	ctx := r.Context()
	rows, err := h.db.Query(ctx, `
		SELECT t.id, t.codigo, t.nome, t.activo, u.email
		  FROM pos.pos_terminals t
		  JOIN auth.users u ON u.id = t.user_id
		 WHERE t.codigo = $1`,
		codigoTerminal,
	)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	type candidate struct {
		terminalID int64
		codigo     string
		nome       string
		activo     bool
		email      string
	}
	var candidates []candidate
	for rows.Next() {
		var c candidate
		if rows.Scan(&c.terminalID, &c.codigo, &c.nome, &c.activo, &c.email) == nil {
			candidates = append(candidates, c)
		}
	}
	rows.Close()

	for _, c := range candidates {
		var passwordHash string
		if err := h.db.QueryRow(ctx, `SELECT password_hash FROM auth.users WHERE email = $1`, c.email).Scan(&passwordHash); err != nil {
			continue
		}
		if bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(activationCode)) != nil {
			continue
		}
		if !c.activo {
			jsonErr(w, "Terminal inativo", http.StatusForbidden)
			return
		}

		u, err := h.lookupUserByEmail(ctx, c.email)
		if err != nil || u.estado != "ativo" {
			jsonErr(w, "Credenciais inválidas", http.StatusUnauthorized)
			return
		}

		var tenantNome, tenantCodigo string
		h.db.QueryRow(ctx, `SELECT nome, codigo FROM saas.tenants WHERE id = $1`, u.tenantID).
			Scan(&tenantNome, &tenantCodigo)

		status := "INATIVO"
		if c.activo {
			status = "ATIVO"
		}
		h.issueTerminalTokens(w, r, u,
			map[string]interface{}{"id": c.terminalID, "codigo": c.codigo, "nome": c.nome, "status": status},
			map[string]interface{}{"id": u.tenantID, "name": tenantNome, "slug": tenantCodigo},
		)
		return
	}

	jsonErr(w, "Credenciais inválidas", http.StatusUnauthorized)
}

// refreshTerminalPOS reemite os tokens de uma conta de terminal a partir do
// seu refresh token — confirma que o utilizador ainda está ligado a um
// pos_terminals ativo antes de reemitir (não basta o JWT ser válido).
func (h *Handler) refreshTerminalPOS(w http.ResponseWriter, r *http.Request, refreshToken string) {
	token, err := jwt.Parse(refreshToken, func(t *jwt.Token) (interface{}, error) {
		return []byte(h.cfg.JWTRefreshSecret), nil
	})
	if err != nil || !token.Valid {
		jsonErr(w, "refresh_token inválido ou expirado", http.StatusUnauthorized)
		return
	}
	claims, _ := token.Claims.(jwt.MapClaims)
	userID := int64(claims["sub"].(float64))

	ctx := r.Context()
	var terminalID int64
	var codigo, nome string
	var activo bool
	if err := h.db.QueryRow(ctx, `
		SELECT id, codigo, nome, activo FROM pos.pos_terminals WHERE user_id = $1`, userID,
	).Scan(&terminalID, &codigo, &nome, &activo); err != nil || !activo {
		jsonErr(w, "Conta de terminal não encontrada ou inativa", http.StatusForbidden)
		return
	}

	var u userIdentity
	u.id = userID
	err = h.db.QueryRow(ctx, `
		SELECT COALESCE(m.tenant_id, 0), COALESCE(m.id, 0), u.nome, u.email, u.estado, u.tipo, COALESCE(NULLIF(m.escopo, ''), 'erp')
		  FROM auth.users u
		  LEFT JOIN auth.memberships m ON m.user_id = u.id AND m.ativo = true
		 WHERE u.id = $1`, userID,
	).Scan(&u.tenantID, &u.membershipID, &u.nome, &u.email, &u.estado, &u.tipo, &u.escopo)
	if err != nil || u.estado != "ativo" {
		jsonErr(w, "Utilizador inactivo", http.StatusUnauthorized)
		return
	}

	var tenantNome, tenantCodigo string
	h.db.QueryRow(ctx, `SELECT nome, codigo FROM saas.tenants WHERE id = $1`, u.tenantID).
		Scan(&tenantNome, &tenantCodigo)

	h.issueTerminalTokens(w, r, &u,
		map[string]interface{}{"id": terminalID, "codigo": codigo, "nome": nome, "status": "ATIVO"},
		map[string]interface{}{"id": u.tenantID, "name": tenantNome, "slug": tenantCodigo},
	)
}

// issueTerminalTokens emite tokens de longa duração (30 dias) para uma conta
// de terminal — mesma mecânica de issueFuncionarioTokens, com expiry maior e
// envelope de resposta próprio (terminal_token em vez de access_token).
func (h *Handler) issueTerminalTokens(w http.ResponseWriter, r *http.Request, u *userIdentity, terminal, tenant map[string]interface{}) {
	accessToken, err := h.signAccessWithExpiry(u.id, u.tenantID, u.membershipID, u.tipo, u.escopo, terminalTokenExpiry)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	refreshToken, err := h.signRefreshWithExpiry(u.id, terminalTokenExpiry)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	expiresAt := time.Now().Add(terminalTokenExpiry)
	if err := h.insertSession(r, u.id, mw.HashToken(accessToken), expiresAt); err != nil {
		jsonErr(w, "Erro ao criar sessão", http.StatusInternalServerError)
		return
	}
	h.db.Exec(r.Context(), `UPDATE users SET ultimo_login_em = NOW() WHERE id = $1`, u.id)

	jsonOK(w, map[string]interface{}{
		"tipo":                   "terminal",
		"terminal_token":         accessToken,
		"terminal_refresh_token": refreshToken,
		"token_type":             "Bearer",
		"expires_in":             int(terminalTokenExpiry.Seconds()),
		"terminal":               terminal,
		"tenant":                 tenant,
	}, http.StatusOK)
}
