package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
)

// ── POST /api/portal/encarregado/logout ──────────────────────────────────────

func (h *Handler) EncarregadoLogout(w http.ResponseWriter, r *http.Request) {
	if header := r.Header.Get("Authorization"); len(header) > 7 {
		_, _ = h.db.Exec(r.Context(), `
			UPDATE gestao_escolar.guardian_portal_sessions
			   SET ativa = false WHERE token_hash = $1`,
			mw.HashToken(header[7:]))
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// ── GET /api/portal/encarregado/me ───────────────────────────────────────────

func (h *Handler) EncarregadoMe(w http.ResponseWriter, r *http.Request) {
	u := mw.GetEncarregadoUser(r)

	// Todos os registos do encarregado (um por educando)
	var result any
	err := h.db.QueryRow(r.Context(), `
		SELECT jsonb_build_object(
			'email',    $1::text,
			'educandos', COALESCE((
				SELECT jsonb_agg(jsonb_build_object(
					'guardian_id',  g.id,
					'student_id',   s.id,
					'aluno_nome',   s.nome,
					'aluno_codigo', s.codigo,
					'parentesco',   g.parentesco,
					'principal',    g.principal,
					'matricula_activa', (
						SELECT to_jsonb(e) || jsonb_build_object(
							'turma',      c.nome,
							'nivel',      c.nivel,
							'ano_lectivo', y.nome
						)
						FROM gestao_escolar.school_enrollments e
						JOIN gestao_escolar.school_classes c ON c.id = e.class_id
						LEFT JOIN gestao_escolar.school_years y ON y.id = e.school_year_id
						WHERE e.student_id = s.id AND e.status = 'activa' LIMIT 1
					)
				) ORDER BY g.principal DESC, s.nome)
				FROM gestao_escolar.school_guardians g
				JOIN gestao_escolar.school_students s ON s.id = g.student_id
				WHERE LOWER(g.portal_email) = LOWER($1) AND g.tenant_id = $2
			), '[]')
		)`, u.Email, u.TenantID,
	).Scan(&result)

	if err != nil {
		jsonErr(w, "Erro ao obter dados", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── POST /api/portal/encarregado/definir-senha ───────────────────────────────

func (h *Handler) EncarregadoDefinirSenha(w http.ResponseWriter, r *http.Request) {
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
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	var guardianID int64
	var userID, pessoaID *int64
	var portalEmail, nome string
	err = h.db.QueryRow(r.Context(), `
		SELECT id, user_id, portal_email, nome, pessoa_id
		  FROM gestao_escolar.school_guardians
		 WHERE portal_invite_token = $1
		   AND portal_invite_expires_at > NOW()`,
		body.Token,
	).Scan(&guardianID, &userID, &portalEmail, &nome, &pessoaID)
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
		uid, err = h.upsertPortalUser(r.Context(), portalEmail, nome, "", string(hash), "encarregado", true, pessoaID)
		if err != nil {
			jsonErr(w, "Erro ao criar utilizador", http.StatusInternalServerError)
			return
		}
		_, _ = h.db.Exec(r.Context(), `
			UPDATE gestao_escolar.school_guardians SET user_id = $1 WHERE id = $2`,
			uid, guardianID)
	} else {
		uid = *userID
		if err := h.updatePortalUserPassword(r.Context(), uid, string(hash)); err != nil {
			jsonErr(w, "Erro ao definir senha", http.StatusInternalServerError)
			return
		}
	}

	// Sincronizar user_id em todos os guardians com o mesmo email no mesmo tenant
	_, _ = h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_guardians g
		   SET user_id = $1
		  FROM gestao_escolar.school_guardians g2
		 WHERE g2.id = $2
		   AND LOWER(g.portal_email) = LOWER(g2.portal_email)
		   AND g.tenant_id = g2.tenant_id`,
		uid, guardianID)

	tag, err := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_guardians
		   SET portal_ativo             = true,
		       portal_invite_token      = NULL,
		       portal_invite_expires_at = NULL
		 WHERE portal_invite_token = $1
		   AND portal_invite_expires_at > NOW()`,
		body.Token,
	)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Erro ao activar portal", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"ok": true, "mensagem": "Senha definida. Pode agora fazer login."}, http.StatusOK)
}

// ── POST /api/portal/encarregado/alterar-senha ───────────────────────────────

func (h *Handler) EncarregadoAlterarSenha(w http.ResponseWriter, r *http.Request) {
	u := mw.GetEncarregadoUser(r)
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
		  FROM auth.users u
		 WHERE LOWER(u.email) = LOWER($1) AND u.tipo = 'encarregado'`,
		u.Email,
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

// ── Admin: Convidar Encarregado ───────────────────────────────────────────────

func (h *Handler) EncarregadoConvidar(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var body struct {
		GuardianID int64  `json:"guardian_id"`
		Email      string `json:"email"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.GuardianID == 0 || body.Email == "" {
		jsonErr(w, "guardian_id e email são obrigatórios", http.StatusBadRequest)
		return
	}

	var nome string
	var pessoaID *int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT nome, pessoa_id FROM gestao_escolar.school_guardians WHERE id = $1 AND tenant_id = $2`,
		body.GuardianID, u.TenantID).Scan(&nome, &pessoaID); err != nil {
		jsonErr(w, "Encarregado não encontrado", http.StatusNotFound)
		return
	}

	// Criar utilizador pendente (sem senha) na tabela unificada
	userID, err := h.upsertPortalUser(r.Context(), body.Email, nome, "", "", "encarregado", false, pessoaID)
	if err != nil {
		jsonErr(w, "Email já em uso ou erro ao criar utilizador", http.StatusUnprocessableEntity)
		return
	}

	token, _ := generateInviteToken()
	expiresAt := time.Now().Add(72 * time.Hour)

	// Actualizar o registo específico e sincronizar user_id em todos com o mesmo email no tenant
	tag, err := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_guardians g
		   SET portal_email             = LOWER($1),
		       user_id                  = $2,
		       portal_invite_token      = $3,
		       portal_invite_expires_at = $4,
		       portal_ativo             = false
		 WHERE id = $5 AND tenant_id = $6`,
		body.Email, userID, token, expiresAt, body.GuardianID, u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Encarregado não encontrado", http.StatusNotFound)
		return
	}

	// Sincronizar user_id nos outros registos do mesmo email/tenant
	_, _ = h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_guardians
		   SET user_id = $1
		 WHERE LOWER(portal_email) = LOWER($2) AND tenant_id = $3 AND id <> $4`,
		userID, body.Email, u.TenantID, body.GuardianID)

	inviteURL := "/portal/encarregado/definir-senha?token=" + token
	jsonOK(w, map[string]any{
		"ok":         true,
		"invite_url": inviteURL,
		"expira_em":  expiresAt.Format(time.RFC3339),
		"mensagem":   "Convite gerado. Válido por 72 horas.",
	}, http.StatusOK)
}

// ── Admin: Reset senha do encarregado ────────────────────────────────────────

func (h *Handler) EncarregadoResetSenha(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var body struct {
		GuardianID int64  `json:"guardian_id"`
		Password   string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.GuardianID == 0 || len(body.Password) < 6 {
		jsonErr(w, "guardian_id e password (mín. 6 chars) são obrigatórios", http.StatusBadRequest)
		return
	}

	var userID *int64
	if err := h.db.QueryRow(r.Context(), `
		SELECT user_id FROM gestao_escolar.school_guardians WHERE id = $1 AND tenant_id = $2`,
		body.GuardianID, u.TenantID).Scan(&userID); err != nil {
		jsonErr(w, "Encarregado não encontrado", http.StatusNotFound)
		return
	}
	if userID == nil || *userID == 0 {
		jsonErr(w, "Encarregado ainda não foi convidado para o portal", http.StatusUnprocessableEntity)
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(body.Password), bcrypt.DefaultCost)
	if err != nil {
		jsonErr(w, "Erro ao processar password", http.StatusInternalServerError)
		return
	}
	if err := h.updatePortalUserPassword(r.Context(), *userID, string(hash)); err != nil {
		jsonErr(w, "Erro ao redefinir senha", http.StatusInternalServerError)
		return
	}

	_, _ = h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_guardians
		   SET portal_ativo = true
		 WHERE id = $1 AND tenant_id = $2`,
		body.GuardianID, u.TenantID)

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}
