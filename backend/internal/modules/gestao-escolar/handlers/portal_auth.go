package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
)

const portalJWTExpiry = 8 * time.Hour

func (h *Handler) signAlunoToken(studentID, tenantID int64) (string, error) {
	jti, err := generateInviteToken()
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

// ── POST /api/portal/aluno/login ─────────────────────────────────────────────

const (
	loginMaxTentativas = 5
	loginBloqueio      = 30 * time.Minute
)

func (h *Handler) PortalLogin(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Email == "" || body.Password == "" {
		jsonErr(w, "Email e password são obrigatórios", http.StatusBadRequest)
		return
	}

	var userID int64
	var passwordHash string

	// Autenticar na tabela unificada de utilizadores
	err := h.db.QueryRow(r.Context(), `
		SELECT id, password_hash
		  FROM auth.users
		 WHERE LOWER(email) = LOWER($1) AND tipo = 'aluno' AND estado = 'ativo'`,
		body.Email,
	).Scan(&userID, &passwordHash)
	if err != nil {
		jsonErr(w, "Credenciais inválidas", http.StatusUnauthorized)
		return
	}

	var studentID, tenantID int64
	var nome, codigo string
	var portalAtivo bool
	var tentativas int
	var bloqueadoAte *time.Time

	err = h.db.QueryRow(r.Context(), `
		SELECT s.id, s.tenant_id, s.nome, s.codigo, s.portal_ativo,
		       s.portal_login_tentativas, s.portal_bloqueado_ate
		  FROM gestao_escolar.school_students s
		 WHERE s.user_id = $1`,
		userID,
	).Scan(&studentID, &tenantID, &nome, &codigo, &portalAtivo, &tentativas, &bloqueadoAte)
	if err != nil {
		jsonErr(w, "Aluno não encontrado no portal", http.StatusUnauthorized)
		return
	}

	// Verificar bloqueio temporário
	if bloqueadoAte != nil && bloqueadoAte.After(time.Now()) {
		jsonErr(w, "Conta temporariamente bloqueada por excesso de tentativas. Tente novamente mais tarde.", http.StatusTooManyRequests)
		return
	}

	if !portalAtivo {
		jsonErr(w, "Acesso ao portal não activado. Contacte a secretaria.", http.StatusForbidden)
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(body.Password)); err != nil {
		// Incrementar contador de tentativas falhadas
		tentativas++
		if tentativas >= loginMaxTentativas {
			_, _ = h.db.Exec(r.Context(), `
				UPDATE gestao_escolar.school_students
				   SET portal_login_tentativas = $1,
				       portal_bloqueado_ate    = NOW() + $2::interval
				 WHERE id = $3`,
				tentativas, loginBloqueio.String(), studentID)
		} else {
			_, _ = h.db.Exec(r.Context(), `
				UPDATE gestao_escolar.school_students
				   SET portal_login_tentativas = $1
				 WHERE id = $2`,
				tentativas, studentID)
		}
		jsonErr(w, "Credenciais inválidas", http.StatusUnauthorized)
		return
	}

	// Login bem sucedido: resetar contador e registar último acesso
	_, _ = h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_students
		   SET portal_login_tentativas = 0,
		       portal_bloqueado_ate    = NULL,
		       portal_ultimo_login     = NOW()
		 WHERE id = $1`, studentID)

	token, err := h.signAlunoToken(studentID, tenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	expiresAt := time.Now().Add(portalJWTExpiry)
	_, err = h.db.Exec(r.Context(), `
		INSERT INTO gestao_escolar.portal_sessions
			(student_id, tenant_id, token_hash, ip_address, user_agent, expira_em)
		VALUES ($1, $2, $3, $4, $5, $6)`,
		studentID, tenantID, mw.HashToken(token),
		r.RemoteAddr, r.Header.Get("User-Agent"), expiresAt,
	)
	if err != nil {
		jsonErr(w, "Erro ao criar sessão", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"access_token": token,
		"expires_in":   int(portalJWTExpiry.Seconds()),
		"aluno": map[string]any{
			"id":     studentID,
			"nome":   nome,
			"codigo": codigo,
		},
	}, http.StatusOK)
}

// ── POST /api/portal/aluno/logout ────────────────────────────────────────────

func (h *Handler) PortalLogout(w http.ResponseWriter, r *http.Request) {
	header := r.Header.Get("Authorization")
	if len(header) > 7 {
		rawToken := header[7:]
		_, _ = h.db.Exec(r.Context(), `
			UPDATE gestao_escolar.portal_sessions
			   SET ativa = false
			 WHERE token_hash = $1`, mw.HashToken(rawToken))
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// ── GET /api/portal/aluno/me ─────────────────────────────────────────────────
// Devolve apenas os dados relevantes para o aluno — sem campos internos do portal.

func (h *Handler) PortalMe(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	var result map[string]any

	err := h.db.QueryRow(r.Context(), `
		SELECT jsonb_build_object(
			'id',                s.id,
			'codigo',            s.codigo,
			'nome',              s.nome,
			'data_nascimento',   s.data_nascimento,
			'genero',            s.genero,
			'documento_tipo',    s.documento_tipo,
			'documento_numero',  s.documento_numero,
			'nuit',              s.nuit,
			'telefone',          s.telefone,
			'email',             s.email,
			'endereco',          s.endereco,
			'fotografia_url',    s.fotografia_url,
			'estado',            s.estado,
			'portal_email',      s.portal_email,
			'matricula_activa', (
				SELECT jsonb_build_object(
					'id',          e.id,
					'numero',      e.numero,
					'status',      e.status,
					'turma',       c.nome,
					'nivel',       c.nivel,
					'turno',       c.turno,
					'ano_lectivo', y.nome,
					'class_id',    e.class_id,
					'school_year_id', e.school_year_id
				)
				FROM gestao_escolar.school_enrollments e
				JOIN gestao_escolar.school_classes c ON c.id = e.class_id
				LEFT JOIN gestao_escolar.school_years y ON y.id = e.school_year_id
				WHERE e.student_id = s.id AND e.status = 'activa'
				LIMIT 1
			),
			'encarregados', COALESCE((
				SELECT jsonb_agg(jsonb_build_object(
					'id',                 g.id,
					'nome',               g.nome,
					'parentesco',         g.parentesco,
					'telefone',           g.telefone,
					'email',              g.email,
					'principal',          g.principal,
					'autorizado_recolher', g.autorizado_recolher
				) ORDER BY g.principal DESC)
				FROM gestao_escolar.school_guardians g
				WHERE g.student_id = s.id
			), '[]')
		)
		FROM gestao_escolar.school_students s
		WHERE s.id = $1 AND s.tenant_id = $2`,
		u.ID, u.TenantID,
	).Scan(&result)

	if err != nil {
		jsonErr(w, "Erro ao obter dados", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── POST /api/portal/aluno/definir-senha ─────────────────────────────────────
// Usado no primeiro acesso via link de convite (token único)

func (h *Handler) PortalDefinirSenha(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Token    string `json:"token"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Token == "" || len(body.Password) < 6 {
		jsonErr(w, "Token e password (mínimo 6 caracteres) são obrigatórios", http.StatusBadRequest)
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(body.Password), bcrypt.DefaultCost)
	if err != nil {
		jsonErr(w, "Erro ao processar password", http.StatusInternalServerError)
		return
	}

	var studentID int64
	var userID *int64
	var portalEmail, nome string
	err = h.db.QueryRow(r.Context(), `
		SELECT id, user_id, portal_email, nome
		  FROM gestao_escolar.school_students
		 WHERE portal_invite_token = $1
		   AND portal_invite_expires_at > NOW()`,
		body.Token,
	).Scan(&studentID, &userID, &portalEmail, &nome)
	if err != nil {
		jsonErr(w, "Link inválido ou expirado", http.StatusUnprocessableEntity)
		return
	}

	var uid int64
	if userID == nil || *userID == 0 {
		if portalEmail == "" {
			jsonErr(w, "Email do portal não configurado", http.StatusUnprocessableEntity)
			return
		}
		uid, err = h.upsertPortalUser(r.Context(), portalEmail, nome, "", string(hash), "aluno", true)
		if err != nil {
			jsonErr(w, "Erro ao criar utilizador", http.StatusInternalServerError)
			return
		}
		_, _ = h.db.Exec(r.Context(), `
			UPDATE gestao_escolar.school_students SET user_id = $1 WHERE id = $2`,
			uid, studentID)
	} else {
		uid = *userID
		if err := h.updatePortalUserPassword(r.Context(), uid, string(hash)); err != nil {
			jsonErr(w, "Erro ao definir senha", http.StatusInternalServerError)
			return
		}
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_students
		   SET portal_ativo             = true,
		       portal_invite_token      = NULL,
		       portal_invite_expires_at = NULL
		 WHERE id = $1`,
		studentID,
	)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Erro ao activar portal", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"ok": true, "mensagem": "Senha definida com sucesso. Pode agora fazer login."}, http.StatusOK)
}

// ── POST /api/portal/aluno/alterar-senha ─────────────────────────────────────
// Aluno autenticado altera a própria senha

func (h *Handler) PortalAlterarSenha(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	var body struct {
		SenhaActual string `json:"senha_actual"`
		NovaSenha   string `json:"nova_senha"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.SenhaActual == "" || len(body.NovaSenha) < 6 {
		jsonErr(w, "Dados inválidos", http.StatusBadRequest)
		return
	}

	var userID int64
	var currentHash string
	if err := h.db.QueryRow(r.Context(), `
		SELECT u.id, u.password_hash
		  FROM gestao_escolar.school_students s
		  JOIN auth.users u ON u.id = s.user_id
		 WHERE s.id = $1`, u.ID,
	).Scan(&userID, &currentHash); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	if err := bcrypt.CompareHashAndPassword([]byte(currentHash), []byte(body.SenhaActual)); err != nil {
		jsonErr(w, "Senha actual incorrecta", http.StatusUnauthorized)
		return
	}

	newHash, err := bcrypt.GenerateFromPassword([]byte(body.NovaSenha), bcrypt.DefaultCost)
	if err != nil {
		jsonErr(w, "Erro ao processar senha", http.StatusInternalServerError)
		return
	}
	if err := h.updatePortalUserPassword(r.Context(), userID, string(newHash)); err != nil {
		jsonErr(w, "Erro ao actualizar senha", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// ── helpers ──────────────────────────────────────────────────────────────────

func generateInviteToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
