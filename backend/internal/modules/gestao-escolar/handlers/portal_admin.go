package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
)

// ── POST /api/escolar/students/{id}/portal/activate ──────────────────────────
// Admin define email + senha e activa o portal para o aluno

func (h *Handler) PortalActivarAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	studentID := chi.URLParam(r, "id")

	var body struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Email == "" || len(body.Password) < 6 {
		jsonErr(w, "Email e password (mínimo 6 caracteres) são obrigatórios", http.StatusBadRequest)
		return
	}

	// Obter nome do aluno para criar o utilizador
	var nome string
	if err := h.db.QueryRow(r.Context(), `
		SELECT nome FROM gestao_escolar.school_students WHERE id = $1 AND tenant_id = $2`,
		studentID, u.TenantID).Scan(&nome); err != nil {
		jsonErr(w, "Aluno não encontrado", http.StatusNotFound)
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(body.Password), bcrypt.DefaultCost)
	if err != nil {
		jsonErr(w, "Erro ao processar password", http.StatusInternalServerError)
		return
	}

	// Criar/actualizar utilizador na tabela unificada
	userID, err := h.upsertPortalUser(r.Context(), body.Email, nome, "", string(hash), "aluno", true)
	if err != nil {
		jsonErr(w, "Email já em uso ou erro ao criar utilizador", http.StatusUnprocessableEntity)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_students
		   SET portal_email = LOWER($1),
		       user_id      = $2,
		       portal_ativo = true
		 WHERE id = $3 AND tenant_id = $4`,
		body.Email, userID, studentID, u.TenantID,
	)
	if err != nil {
		jsonErr(w, "Erro ao activar portal", http.StatusUnprocessableEntity)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Aluno não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, map[string]any{"ok": true, "mensagem": "Portal activado com sucesso."}, http.StatusOK)
}

// ── POST /api/escolar/students/{id}/portal/deactivate ────────────────────────

func (h *Handler) PortalDesactivarAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	studentID := chi.URLParam(r, "id")

	tag, _ := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_students
		   SET portal_ativo = false
		 WHERE id = $1 AND tenant_id = $2`, studentID, u.TenantID)

	if tag.RowsAffected() == 0 {
		jsonErr(w, "Aluno não encontrado", http.StatusNotFound)
		return
	}

	// Revogar sessões activas
	_, _ = h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.portal_sessions SET ativa = false
		WHERE student_id = $1`, studentID)

	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// ── POST /api/escolar/students/{id}/portal/invite ────────────────────────────
// Gera link de convite único para o aluno definir a sua própria senha

func (h *Handler) PortalConvidarAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	studentID := chi.URLParam(r, "id")

	var body struct {
		Email string `json:"email"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Email == "" {
		jsonErr(w, "Email é obrigatório", http.StatusBadRequest)
		return
	}

	var nome string
	if err := h.db.QueryRow(r.Context(), `
		SELECT nome FROM gestao_escolar.school_students WHERE id = $1 AND tenant_id = $2`,
		studentID, u.TenantID).Scan(&nome); err != nil {
		jsonErr(w, "Aluno não encontrado", http.StatusNotFound)
		return
	}

	// Criar utilizador pendente (sem senha) na tabela unificada
	userID, err := h.upsertPortalUser(r.Context(), body.Email, nome, "", "", "aluno", false)
	if err != nil {
		jsonErr(w, "Email já em uso ou erro ao criar utilizador", http.StatusUnprocessableEntity)
		return
	}

	token, err := generateInviteToken()
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	expiresAt := time.Now().Add(72 * time.Hour)

	tag, err := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_students
		   SET portal_email             = LOWER($1),
		       user_id                  = $2,
		       portal_invite_token      = $3,
		       portal_invite_expires_at = $4,
		       portal_ativo             = false
		 WHERE id = $5 AND tenant_id = $6`,
		body.Email, userID, token, expiresAt, studentID, u.TenantID,
	)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Aluno não encontrado", http.StatusUnprocessableEntity)
		return
	}

	inviteURL := fmt.Sprintf("/portal/aluno/definir-senha?token=%s", token)
	jsonOK(w, map[string]any{
		"ok":         true,
		"invite_url": inviteURL,
		"expira_em":  expiresAt.Format(time.RFC3339),
		"mensagem":   "Link de convite gerado. Válido por 72 horas.",
	}, http.StatusOK)
}

// ── POST /api/escolar/students/{id}/portal/reset-senha ───────────────────────
// Admin redefine directamente a senha do aluno

func (h *Handler) PortalResetSenhaAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	studentID := chi.URLParam(r, "id")

	var body struct {
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || len(body.Password) < 6 {
		jsonErr(w, "Password mínima de 6 caracteres", http.StatusBadRequest)
		return
	}

	var userID *int64
	var portalEmail string
	if err := h.db.QueryRow(r.Context(), `
		SELECT user_id, portal_email
		  FROM gestao_escolar.school_students
		 WHERE id = $1 AND tenant_id = $2`,
		studentID, u.TenantID).Scan(&userID, &portalEmail); err != nil {
		jsonErr(w, "Aluno não encontrado", http.StatusNotFound)
		return
	}
	if userID == nil || portalEmail == "" {
		jsonErr(w, "Portal do aluno ainda não foi activado", http.StatusUnprocessableEntity)
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
		UPDATE gestao_escolar.school_students
		   SET portal_ativo = true
		 WHERE id = $1 AND tenant_id = $2`,
		studentID, u.TenantID)

	jsonOK(w, map[string]any{"ok": true, "mensagem": "Senha redefinida com sucesso."}, http.StatusOK)
}

// ── GET /api/escolar/portal/alunos ───────────────────────────────────────────
// Lista todos os alunos com estado do portal, último acesso e convite pendente.

func (h *Handler) PortalListarAlunos(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome), '[]') FROM (
			SELECT s.id, s.codigo, s.nome,
			       s.portal_ativo,
			       s.portal_email,
			       s.portal_ultimo_login,
			       u.password_hash IS NOT NULL AND LENGTH(u.password_hash) > 0          AS tem_senha,
			       s.portal_invite_token IS NOT NULL AND s.portal_invite_expires_at > NOW() AS convite_pendente,
			       s.portal_invite_expires_at,
			       s.portal_login_tentativas,
			       s.portal_bloqueado_ate,
			       (SELECT COUNT(*) FROM gestao_escolar.portal_sessions ps
			         WHERE ps.student_id = s.id AND ps.ativa = true AND ps.expira_em > NOW()) AS sessoes_activas
			FROM gestao_escolar.school_students s
			LEFT JOIN auth.users u ON u.id = s.user_id
			WHERE s.tenant_id = $1
		) x`, u.TenantID)
}

// ── GET /api/escolar/portal/sessions ─────────────────────────────────────────
// Relatório de acesso: sessões por aluno (últimos 30 dias).

func (h *Handler) PortalRelatorioSessoes(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolList(w, r, `
		SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.ultimo_acesso DESC NULLS LAST), '[]') FROM (
			SELECT s.id, s.codigo, s.nome, s.portal_ativo, s.portal_email,
			       s.portal_ultimo_login                                           AS ultimo_acesso,
			       COUNT(ps.id)                                                    AS total_sessoes,
			       COUNT(ps.id) FILTER (WHERE ps.ativa AND ps.expira_em > NOW())  AS sessoes_activas,
			       COUNT(DISTINCT ps.ip_address)                                   AS ips_distintos
			FROM gestao_escolar.school_students s
			LEFT JOIN gestao_escolar.portal_sessions ps
			       ON ps.student_id = s.id AND ps.criada_em >= NOW() - INTERVAL '30 days'
			WHERE s.tenant_id = $1
			GROUP BY s.id, s.codigo, s.nome, s.portal_ativo, s.portal_email, s.portal_ultimo_login
		) x`, u.TenantID)
}

// ── POST /api/escolar/classes/{id}/portal/invite-all ─────────────────────────
// Gera convites para todos os alunos activos de uma turma que ainda não têm portal.

func (h *Handler) PortalInvitarTurma(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	classID := chi.URLParam(r, "id")

	var body struct {
		EmailDomain string `json:"email_domain"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || strings.TrimSpace(body.EmailDomain) == "" {
		jsonErr(w, "email_domain é obrigatório (ex: escola.mz)", http.StatusBadRequest)
		return
	}
	domain := strings.ToLower(strings.TrimSpace(body.EmailDomain))

	// Buscar alunos activos da turma sem portal activado
	rows, err := h.db.Query(r.Context(), `
		SELECT s.id, LOWER(s.codigo) codigo
		  FROM gestao_escolar.school_enrollments e
		  JOIN gestao_escolar.school_students s ON s.id = e.student_id
		 WHERE e.class_id = $1 AND e.tenant_id = $2 AND e.status = 'activa'
		   AND s.portal_ativo = false`, classID, u.TenantID)
	if err != nil {
		jsonErr(w, "Erro ao obter alunos", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type student struct {
		id     int64
		codigo string
	}
	var students []student
	for rows.Next() {
		var s student
		if err := rows.Scan(&s.id, &s.codigo); err == nil {
			students = append(students, s)
		}
	}
	rows.Close()

	convidados := 0
	expiresAt := time.Now().Add(72 * time.Hour)
	for _, s := range students {
		token, err := generateInviteToken()
		if err != nil {
			continue
		}
		email := fmt.Sprintf("%s@%s", s.codigo, domain)

		// Criar utilizador pendente (sem senha) na tabela unificada
		userID, err := h.upsertPortalUser(r.Context(), email, s.codigo, "", "", "aluno", false)
		if err != nil {
			continue
		}

		tag, _ := h.db.Exec(r.Context(), `
			UPDATE gestao_escolar.school_students
			   SET portal_email             = $1,
			       user_id                  = $2,
			       portal_invite_token      = $3,
			       portal_invite_expires_at = $4
			 WHERE id = $5 AND tenant_id = $6 AND portal_ativo = false`,
			email, userID, token, expiresAt, s.id, u.TenantID)
		if tag.RowsAffected() > 0 {
			convidados++
		}
	}

	jsonOK(w, map[string]any{
		"convidados": convidados,
		"total":      len(students),
		"expira_em":  expiresAt.Format(time.RFC3339),
		"mensagem":   fmt.Sprintf("%d convites gerados. Válidos por 72 horas.", convidados),
	}, http.StatusOK)
}

// ── GET /api/escolar/students/{id}/portal/status ─────────────────────────────

func (h *Handler) PortalStatusAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	studentID := chi.URLParam(r, "id")

	var result map[string]any
	err := h.db.QueryRow(r.Context(), `
		SELECT jsonb_build_object(
			'portal_ativo',        s.portal_ativo,
			'portal_email',        s.portal_email,
			'portal_ultimo_login', s.portal_ultimo_login,
			'tem_senha',           u.password_hash IS NOT NULL AND LENGTH(u.password_hash) > 0,
			'convite_pendente',    s.portal_invite_token IS NOT NULL AND s.portal_invite_expires_at > NOW(),
			'convite_expira_em',   s.portal_invite_expires_at
		)
		FROM gestao_escolar.school_students s
		LEFT JOIN auth.users u ON u.id = s.user_id
		WHERE s.id = $1 AND s.tenant_id = $2`, studentID, u.TenantID,
	).Scan(&result)
	if err != nil {
		jsonErr(w, "Aluno não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, result, http.StatusOK)
}
