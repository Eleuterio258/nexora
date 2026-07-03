package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"golang.org/x/crypto/bcrypt"

	mw "nexora/internal/middleware"
)

// professorID resolve o teacher_id a partir do user_id do JWT.
// Devolve (teacherID, tenantID, ok). Envia 404 se não encontrado.
func (h *Handler) professorID(w http.ResponseWriter, r *http.Request) (teacherID, tenantID int64, ok bool) {
	u := mw.GetUser(r)
	if u == nil || u.Escopo != "portal_professor" {
		jsonErr(w, "Acesso reservado a professores", http.StatusForbidden)
		return 0, 0, false
	}
	err := h.db.QueryRow(r.Context(), `
		SELECT id, tenant_id FROM gestao_escolar.school_teachers
		 WHERE user_id = $1 LIMIT 1`, u.ID).
		Scan(&teacherID, &tenantID)
	if err != nil {
		jsonErr(w, "Professor não encontrado", http.StatusNotFound)
		return 0, 0, false
	}
	return teacherID, tenantID, true
}

// ── GET /api/portal/professor/me ─────────────────────────────────────────────

func (h *Handler) ProfessorPortalMe(w http.ResponseWriter, r *http.Request) {
	tid, tenID, ok := h.professorID(w, r)
	if !ok {
		return
	}
	var result map[string]any
	err := h.db.QueryRow(r.Context(), `
		SELECT jsonb_build_object(
			'id',             t.id,
			'codigo',         t.codigo,
			'nome',           t.nome_completo,
			'email',          t.email,
			'telefone',       t.telefone,
			'especialidade',  t.especialidade,
			'fotografia_url', t.fotografia_url,
			'disciplinas', COALESCE((
				SELECT jsonb_agg(DISTINCT sub.nome ORDER BY sub.nome)
				  FROM gestao_escolar.school_timetable_slots sl
				  JOIN gestao_escolar.school_subjects sub ON sub.id = sl.subject_id
				 WHERE sl.teacher_id = t.id AND sl.tenant_id = t.tenant_id
			), '[]')
		)
		FROM gestao_escolar.school_teachers t
		WHERE t.id = $1 AND t.tenant_id = $2`, tid, tenID).
		Scan(&result)
	if err != nil {
		jsonErr(w, "Erro ao obter dados", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── GET /api/portal/professor/me/turmas ──────────────────────────────────────

func (h *Handler) ProfessorPortalTurmas(w http.ResponseWriter, r *http.Request) {
	tid, tenID, ok := h.professorID(w, r)
	if !ok {
		return
	}
	var result any
	err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(jsonb_build_object(
			'id',           c.id,
			'nome',         c.nome,
			'nivel',        c.nivel,
			'turno',        c.turno,
			'disciplina',   sub.nome,
			'subject_id',   sub.id,
			'ano_lectivo',  y.nome,
			'total_alunos', (SELECT COUNT(*) FROM gestao_escolar.school_enrollments e
			                  WHERE e.class_id = c.id AND e.status = 'activa')
		) ORDER BY c.nome), '[]')
		FROM (
			SELECT DISTINCT sl.class_id, sl.subject_id
			  FROM gestao_escolar.school_timetable_slots sl
			 WHERE sl.teacher_id = $1 AND sl.tenant_id = $2
		) x
		JOIN gestao_escolar.school_classes c ON c.id = x.class_id
		JOIN gestao_escolar.school_subjects sub ON sub.id = x.subject_id
		LEFT JOIN gestao_escolar.school_years y ON y.id = c.school_year_id`, tid, tenID).
		Scan(&result)
	if err != nil {
		jsonErr(w, "Erro ao obter turmas", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── GET /api/portal/professor/me/turmas/{id} ─────────────────────────────────

func (h *Handler) ProfessorPortalTurma(w http.ResponseWriter, r *http.Request) {
	tid, tenID, ok := h.professorID(w, r)
	if !ok {
		return
	}
	classID, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID inválido", http.StatusBadRequest)
		return
	}
	var result map[string]any
	err = h.db.QueryRow(r.Context(), `
		SELECT jsonb_build_object(
			'id',           c.id,
			'nome',         c.nome,
			'nivel',        c.nivel,
			'turno',        c.turno,
			'ano_lectivo',  y.nome,
			'total_alunos', (SELECT COUNT(*) FROM gestao_escolar.school_enrollments e
			                  WHERE e.class_id = c.id AND e.status = 'activa'),
			'disciplinas', COALESCE((
				SELECT jsonb_agg(DISTINCT sub.nome)
				  FROM gestao_escolar.school_timetable_slots sl
				  JOIN gestao_escolar.school_subjects sub ON sub.id = sl.subject_id
				 WHERE sl.teacher_id = $1 AND sl.class_id = c.id AND sl.tenant_id = $2
			), '[]')
		)
		FROM gestao_escolar.school_classes c
		LEFT JOIN gestao_escolar.school_years y ON y.id = c.school_year_id
		WHERE c.id = $3 AND c.tenant_id = $2`, tid, tenID, classID).
		Scan(&result)
	if err != nil {
		jsonErr(w, "Turma não encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── GET /api/portal/professor/me/turmas/{id}/alunos ──────────────────────────

func (h *Handler) ProfessorPortalTurmaAlunos(w http.ResponseWriter, r *http.Request) {
	_, tenID, ok := h.professorID(w, r)
	if !ok {
		return
	}
	classID, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID inválido", http.StatusBadRequest)
		return
	}
	var result any
	err = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(jsonb_build_object(
			'id',        s.id,
			'codigo',    s.codigo,
			'nome',      s.nome,
			'numero',    e.numero
		) ORDER BY s.nome), '[]')
		FROM gestao_escolar.school_enrollments e
		JOIN gestao_escolar.school_students s ON s.id = e.student_id
		WHERE e.class_id = $1 AND e.tenant_id = $2 AND e.status = 'activa'`,
		classID, tenID).
		Scan(&result)
	if err != nil {
		jsonErr(w, "Erro ao obter alunos", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── GET /api/portal/professor/me/horario ─────────────────────────────────────

func (h *Handler) ProfessorPortalHorario(w http.ResponseWriter, r *http.Request) {
	tid, tenID, ok := h.professorID(w, r)
	if !ok {
		return
	}
	var result any
	err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(jsonb_build_object(
			'id',           sl.id,
			'dia_semana',   sl.dia_semana,
			'hora_inicio',  sl.hora_inicio,
			'hora_fim',     sl.hora_fim,
			'turma',        c.nome,
			'class_id',     c.id,
			'disciplina',   sub.nome,
			'subject_id',   sub.id,
			'sala',         sl.sala
		) ORDER BY sl.dia_semana, sl.hora_inicio), '[]')
		FROM gestao_escolar.school_timetable_slots sl
		JOIN gestao_escolar.school_classes c ON c.id = sl.class_id
		JOIN gestao_escolar.school_subjects sub ON sub.id = sl.subject_id
		WHERE sl.teacher_id = $1 AND sl.tenant_id = $2`, tid, tenID).
		Scan(&result)
	if err != nil {
		jsonErr(w, "Erro ao obter horário", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── GET /api/portal/professor/me/presencas ────────────────────────────────────

func (h *Handler) ProfessorPortalGetPresencas(w http.ResponseWriter, r *http.Request) {
	tid, tenID, ok := h.professorID(w, r)
	if !ok {
		return
	}
	classID, _ := strconv.ParseInt(r.URL.Query().Get("turma_id"), 10, 64)
	data := r.URL.Query().Get("data")
	if data == "" {
		jsonErr(w, "Parâmetro 'data' é obrigatório", http.StatusBadRequest)
		return
	}

	// Verificar que o professor lecciona esta turma
	if classID > 0 {
		var belongs bool
		h.db.QueryRow(r.Context(), `
			SELECT EXISTS(SELECT 1 FROM gestao_escolar.school_timetable_slots
			 WHERE teacher_id=$1 AND class_id=$2 AND tenant_id=$3)`,
			tid, classID, tenID).Scan(&belongs)
		if !belongs {
			jsonErr(w, "Sem acesso a esta turma", http.StatusForbidden)
			return
		}
	}

	var result any
	err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(jsonb_build_object(
			'id',           p.id,
			'student_id',   p.student_id,
			'nome',         s.nome,
			'estado',       p.estado,
			'justificado',  p.justificado,
			'observacao',   p.observacao
		) ORDER BY s.nome), '[]')
		FROM gestao_escolar.school_attendance p
		JOIN gestao_escolar.school_students s ON s.id = p.student_id
		WHERE p.class_id = $1 AND p.data = $2 AND p.tenant_id = $3`,
		classID, data, tenID).
		Scan(&result)
	if err != nil {
		jsonErr(w, "Erro ao obter presenças", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── POST /api/portal/professor/me/presencas ───────────────────────────────────

func (h *Handler) ProfessorPortalSalvarPresencas(w http.ResponseWriter, r *http.Request) {
	tid, tenID, ok := h.professorID(w, r)
	if !ok {
		return
	}
	var body struct {
		ClassID   int64  `json:"turma_id"`
		Data      string `json:"data"`
		Presencas []struct {
			StudentID   int64  `json:"student_id"`
			Estado      string `json:"estado"`
			Justificado bool   `json:"justificado"`
			Observacao  string `json:"observacao"`
		} `json:"presencas"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ClassID == 0 || body.Data == "" {
		jsonErr(w, "turma_id e data são obrigatórios", http.StatusBadRequest)
		return
	}

	var belongs bool
	h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM gestao_escolar.school_timetable_slots
		 WHERE teacher_id=$1 AND class_id=$2 AND tenant_id=$3)`,
		tid, body.ClassID, tenID).Scan(&belongs)
	if !belongs {
		jsonErr(w, "Sem acesso a esta turma", http.StatusForbidden)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	for _, p := range body.Presencas {
		_, _ = tx.Exec(r.Context(), `
			INSERT INTO gestao_escolar.school_attendance
				(tenant_id, class_id, student_id, data, estado, justificado, observacao, registado_por)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
			ON CONFLICT (class_id, student_id, data) DO UPDATE
			   SET estado=$5, justificado=$6, observacao=$7, updated_at=NOW()`,
			tenID, body.ClassID, p.StudentID, body.Data,
			p.Estado, p.Justificado, p.Observacao, tid)
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro ao guardar presenças", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// ── GET /api/portal/professor/me/notas ───────────────────────────────────────

func (h *Handler) ProfessorPortalGetNotas(w http.ResponseWriter, r *http.Request) {
	tid, tenID, ok := h.professorID(w, r)
	if !ok {
		return
	}
	classID, _ := strconv.ParseInt(r.URL.Query().Get("turma_id"), 10, 64)
	subjectID, _ := strconv.ParseInt(r.URL.Query().Get("disciplina_id"), 10, 64)
	if classID == 0 {
		jsonErr(w, "turma_id é obrigatório", http.StatusBadRequest)
		return
	}

	var belongs bool
	h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM gestao_escolar.school_timetable_slots
		 WHERE teacher_id=$1 AND class_id=$2 AND tenant_id=$3)`,
		tid, classID, tenID).Scan(&belongs)
	if !belongs {
		jsonErr(w, "Sem acesso a esta turma", http.StatusForbidden)
		return
	}

	whereSubject := ""
	args := []any{classID, tenID}
	if subjectID > 0 {
		args = append(args, subjectID)
		whereSubject = " AND i.subject_id = $3"
	}

	var result any
	err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(jsonb_build_object(
			'student_id',  s.id,
			'nome',        s.nome,
			'numero',      e.numero,
			'notas', COALESCE((
				SELECT jsonb_agg(jsonb_build_object(
					'grade_item_id', g.grade_item_id,
					'item_nome',     i.nome,
					'periodo',       i.term_id,
					'nota',          g.nota
				) ORDER BY i.nome)
				FROM gestao_escolar.school_grades g
				JOIN gestao_escolar.school_grade_items i ON i.id = g.grade_item_id
				WHERE g.student_id = s.id AND g.class_id = $1 AND g.tenant_id = $2`+whereSubject+`
			), '[]')
		) ORDER BY s.nome), '[]')
		FROM gestao_escolar.school_enrollments e
		JOIN gestao_escolar.school_students s ON s.id = e.student_id
		WHERE e.class_id = $1 AND e.tenant_id = $2 AND e.status = 'activa'`, args...).
		Scan(&result)
	if err != nil {
		jsonErr(w, "Erro ao obter notas", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── POST /api/portal/professor/me/notas ──────────────────────────────────────

func (h *Handler) ProfessorPortalSalvarNotas(w http.ResponseWriter, r *http.Request) {
	tid, tenID, ok := h.professorID(w, r)
	if !ok {
		return
	}
	var body struct {
		ClassID int64 `json:"turma_id"`
		Notas   []struct {
			StudentID   int64   `json:"student_id"`
			GradeItemID int64   `json:"grade_item_id"`
			Nota        float64 `json:"nota"`
		} `json:"notas"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ClassID == 0 {
		jsonErr(w, "turma_id é obrigatório", http.StatusBadRequest)
		return
	}

	var belongs bool
	h.db.QueryRow(r.Context(), `
		SELECT EXISTS(SELECT 1 FROM gestao_escolar.school_timetable_slots
		 WHERE teacher_id=$1 AND class_id=$2 AND tenant_id=$3)`,
		tid, body.ClassID, tenID).Scan(&belongs)
	if !belongs {
		jsonErr(w, "Sem acesso a esta turma", http.StatusForbidden)
		return
	}

	tx, err := h.db.Begin(r.Context())
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback(r.Context())

	for _, n := range body.Notas {
		_, _ = tx.Exec(r.Context(), `
			INSERT INTO gestao_escolar.school_grades
				(tenant_id, class_id, student_id, grade_item_id, nota, lancado_por)
			VALUES ($1,$2,$3,$4,$5,$6)
			ON CONFLICT (class_id, student_id, grade_item_id) DO UPDATE
			   SET nota=$5, updated_at=NOW()`,
			tenID, body.ClassID, n.StudentID, n.GradeItemID, n.Nota, tid)
	}

	if err := tx.Commit(r.Context()); err != nil {
		jsonErr(w, "Erro ao guardar notas", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// ── GET /api/portal/professor/me/comunicacao ─────────────────────────────────

func (h *Handler) ProfessorPortalComunicacao(w http.ResponseWriter, r *http.Request) {
	_, tenID, ok := h.professorID(w, r)
	if !ok {
		return
	}
	u := mw.GetUser(r)
	var result any
	err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(jsonb_build_object(
			'id',         m.id,
			'assunto',    m.assunto,
			'corpo',      m.corpo,
			'remetente',  m.remetente_nome,
			'data',       m.created_at,
			'lida',       COALESCE((
				SELECT lida FROM gestao_escolar.school_message_reads
				 WHERE message_id = m.id AND user_id = $1
			), false)
		) ORDER BY m.created_at DESC), '[]')
		FROM gestao_escolar.school_messages m
		WHERE m.tenant_id = $2
		  AND (m.destinatario_tipo = 'todos'
		    OR m.destinatario_tipo = 'professores'
		    OR (m.destinatario_tipo = 'utilizador' AND m.destinatario_id = $1))
		LIMIT 50`, u.ID, tenID).
		Scan(&result)
	if err != nil {
		jsonErr(w, "Erro ao obter comunicações", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── POST /api/portal/professor/logout ────────────────────────────────────────

func (h *Handler) ProfessorPortalLogout(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	if u != nil {
		h.db.Exec(r.Context(), `
			UPDATE auth.sessions SET ativa=FALSE, encerrado_em=NOW()
			 WHERE user_id=$1 AND ativa=TRUE`, u.ID)
	}
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}

// ── POST /api/portal/professor/alterar-senha ─────────────────────────────────

func (h *Handler) ProfessorPortalAlterarSenha(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	if u == nil || u.Escopo != "portal_professor" {
		jsonErr(w, "Acesso negado", http.StatusForbidden)
		return
	}
	var body struct {
		SenhaActual string `json:"password_actual"`
		NovaSenha   string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.SenhaActual == "" || len(body.NovaSenha) < 6 {
		jsonErr(w, "password_actual e password (mín. 6 chars) são obrigatórios", http.StatusBadRequest)
		return
	}
	var currentHash string
	if err := h.db.QueryRow(r.Context(), `SELECT password_hash FROM auth.users WHERE id=$1`, u.ID).Scan(&currentHash); err != nil {
		jsonErr(w, "Utilizador não encontrado", http.StatusNotFound)
		return
	}
	if bcrypt.CompareHashAndPassword([]byte(currentHash), []byte(body.SenhaActual)) != nil {
		jsonErr(w, "Senha actual incorrecta", http.StatusUnauthorized)
		return
	}
	newHash, _ := bcrypt.GenerateFromPassword([]byte(body.NovaSenha), 12)
	h.db.Exec(r.Context(), `UPDATE auth.users SET password_hash=$1, updated_at=NOW() WHERE id=$2`, string(newHash), u.ID)
	jsonOK(w, map[string]any{"ok": true}, http.StatusOK)
}
