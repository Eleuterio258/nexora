package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"net/http"

	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
)

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
	var userID, pessoaID *int64
	var portalEmail, nome string
	err = h.db.QueryRow(r.Context(), `
		SELECT id, user_id, portal_email, nome, pessoa_id
		  FROM gestao_escolar.school_students
		 WHERE portal_invite_token = $1
		   AND portal_invite_expires_at > NOW()`,
		body.Token,
	).Scan(&studentID, &userID, &portalEmail, &nome, &pessoaID)
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
		uid, err = h.upsertPortalUser(r.Context(), portalEmail, nome, "", string(hash), "aluno", true, pessoaID)
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
