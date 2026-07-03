package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ── GET /api/portal/aluno/me/dashboard ────────────────────────────────────────
// Resumo académico consolidado para a Home do mobile: aulas hoje, média geral,
// faltas, ranking, atividades pendentes e próximos compromissos.

func (h *Handler) PortalDashboardAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)

	// Dados base da matrícula activa (turma e ano lectivo)
	var classID, schoolYearID int64
	err := h.db.QueryRow(r.Context(), `
		SELECT e.class_id, e.school_year_id
		  FROM gestao_escolar.school_enrollments e
		 WHERE e.student_id = $1 AND e.tenant_id = $2 AND e.status = 'activa'
		 LIMIT 1`, u.ID, u.TenantID,
	).Scan(&classID, &schoolYearID)
	if err != nil {
		jsonOK(w, map[string]any{
			"aulas_hoje":            0,
			"media_geral":             nil,
			"faltas":                  0,
			"faltas_permitidas":       30,
			"ranking":                 nil,
			"total_alunos_turma":      0,
			"atividades_pendentes":    0,
			"proximos_compromissos": []any{},
		}, http.StatusOK)
		return
	}

	// Aulas hoje (dia da semana: 1=domingo no Go, mas base de dados usa 1=segunda)
	today := time.Now().Weekday()
	weekdayDB := int64(today) // alinhado com school_timetable_entries.dia_semana (0=domingo ou 1=segunda depende do seed)
	if today == time.Sunday {
		weekdayDB = 0
	}

	var aulasHoje int64
	_ = h.db.QueryRow(r.Context(), `
		SELECT COUNT(*)
		  FROM gestao_escolar.school_timetable_entries te
		 WHERE te.class_id = $1 AND te.tenant_id = $2 AND te.dia_semana = $3 AND te.activo = true`,
		classID, u.TenantID, weekdayDB,
	).Scan(&aulasHoje)

	// Média geral (média das médias por disciplina, só avaliações publicadas)
	var mediaGeral *float64
	_ = h.db.QueryRow(r.Context(), `
		SELECT ROUND(AVG(disc_avg),2) FROM (
			SELECT SUM(g.nota*i.peso)/NULLIF(SUM(i.peso),0) disc_avg
			FROM gestao_escolar.school_grades g
			JOIN gestao_escolar.school_grade_items i ON i.id=g.grade_item_id AND i.publicado=TRUE
			WHERE g.student_id=$1 AND g.tenant_id=$2
			GROUP BY i.subject_id
		) x`, u.ID, u.TenantID,
	).Scan(&mediaGeral)

	// Faltas no ano lectivo
	var faltas int64
	_ = h.db.QueryRow(r.Context(), `
		SELECT COUNT(*)
		  FROM gestao_escolar.school_attendance a
		 WHERE a.student_id = $1 AND a.tenant_id = $2 AND a.estado = 'ausente'
		   AND a.class_id = $3`,
		u.ID, u.TenantID, classID,
	).Scan(&faltas)

	// Total de alunos da turma
	var totalAlunos int64
	_ = h.db.QueryRow(r.Context(), `
		SELECT COUNT(*)
		  FROM gestao_escolar.school_enrollments e
		 WHERE e.class_id = $1 AND e.tenant_id = $2 AND e.status = 'activa'`,
		classID, u.TenantID,
	).Scan(&totalAlunos)

	// Ranking do aluno na turma (baseado na média geral)
	var ranking *int64
	if mediaGeral != nil {
		_ = h.db.QueryRow(r.Context(), `
			SELECT posicao FROM (
				SELECT e.student_id,
					   RANK() OVER (ORDER BY COALESCE(media.media,0) DESC) posicao
				FROM gestao_escolar.school_enrollments e
				LEFT JOIN (
					SELECT g.student_id, AVG(disc_avg) media FROM (
						SELECT g.student_id, g.subject_id, SUM(g.nota*i.peso)/NULLIF(SUM(i.peso),0) disc_avg
						FROM gestao_escolar.school_grades g
						JOIN gestao_escolar.school_grade_items i ON i.id=g.grade_item_id AND i.publicado=TRUE
						WHERE g.tenant_id=$1
						GROUP BY g.student_id, g.subject_id
					) g GROUP BY g.student_id
				) media ON media.student_id=e.student_id
				WHERE e.class_id=$2 AND e.tenant_id=$1 AND e.status='activa'
			) r WHERE r.student_id=$3`,
			u.TenantID, classID, u.ID,
		).Scan(&ranking)
	}

	// Atividades pendentes (tarefas não concluídas para a turma + avaliações sem nota lançada)
	var atividadesPendentes int64
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(t.cnt,0) + COALESCE(a.cnt,0) FROM (
			SELECT COUNT(*) cnt
			FROM gestao_escolar.school_tasks t
			WHERE t.class_id=$1 AND t.tenant_id=$2 AND t.status='activa'
			  AND t.data_fim >= CURRENT_DATE
		) t,
		(
			SELECT COUNT(*) cnt
			FROM gestao_escolar.school_grade_items i
			WHERE i.class_id=$1 AND i.tenant_id=$2 AND i.publicado=TRUE
			  AND NOT EXISTS (
				  SELECT 1 FROM gestao_escolar.school_grades g
				  WHERE g.grade_item_id=i.id AND g.student_id=$3
			  )
		) a`,
		classID, u.TenantID, u.ID,
	).Scan(&atividadesPendentes)

	// Próximos compromissos (eventos + tarefas + avaliações nos próximos 30 dias)
	var compromissos any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(x ORDER BY x.data, x.hora),'[]') FROM (
			SELECT ce.titulo, ce.data_inicio::text AS data, NULL AS hora,
				   'evento' AS tipo, et.cor AS cor, et.nome AS categoria
			FROM gestao_escolar.school_calendar_events ce
			LEFT JOIN gestao_escolar.school_calendar_event_types et ON et.id=ce.event_type_id
			WHERE ce.tenant_id=$1
			  AND ce.data_inicio BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
			UNION ALL
			SELECT t.titulo, t.data_fim::text AS data, NULL AS hora,
				   'tarefa' AS tipo, '#00B87A' AS cor, 'Tarefa' AS categoria
			FROM gestao_escolar.school_tasks t
			WHERE t.tenant_id=$1 AND t.class_id=$2 AND t.status='activa'
			  AND t.data_fim BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
			UNION ALL
			SELECT i.nome AS titulo, i.data_avaliacao::text AS data, NULL AS hora,
				   'avaliacao' AS tipo, '#F59E0B' AS cor, i.tipo AS categoria
			FROM gestao_escolar.school_grade_items i
			WHERE i.tenant_id=$1 AND i.class_id=$2 AND i.publicado=TRUE
			  AND i.data_avaliacao BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
			ORDER BY data
			LIMIT 10
		) x`, u.TenantID, classID,
	).Scan(&compromissos)

	jsonOK(w, map[string]any{
		"aulas_hoje":            aulasHoje,
		"media_geral":             mediaGeral,
		"faltas":                  faltas,
		"faltas_permitidas":       30,
		"ranking":                 ranking,
		"total_alunos_turma":      totalAlunos,
		"atividades_pendentes":    atividadesPendentes,
		"proximos_compromissos": compromissos,
	}, http.StatusOK)
}

// ── GET /api/portal/aluno/me/turma ───────────────────────────────────────────
// Devolve os dados da turma do aluno: identificação, docentes, colegas e cargos.

func (h *Handler) PortalTurmaAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)

	var classID int64
	err := h.db.QueryRow(r.Context(), `
		SELECT e.class_id
		  FROM gestao_escolar.school_enrollments e
		 WHERE e.student_id = $1 AND e.tenant_id = $2 AND e.status = 'activa'
		 LIMIT 1`, u.ID, u.TenantID,
	).Scan(&classID)
	if err != nil {
		jsonErr(w, "Aluno sem matrícula activa", http.StatusNotFound)
		return
	}

	var turma any
	err = h.db.QueryRow(r.Context(), `
		SELECT to_jsonb(c) || jsonb_build_object(
			'nivel', COALESCE(l.nome, c.nivel),
			'serie', COALESCE(s.nome, ''),
			'curso', COALESCE(co.nome, ''),
			'ano_lectivo', COALESCE(y.nome, ''),
			'director_turma', COALESCE(t.nome_completo, '')
		)
		FROM gestao_escolar.school_classes c
		LEFT JOIN gestao_escolar.school_levels l ON l.id=c.level_id
		LEFT JOIN gestao_escolar.school_series s ON s.id=c.series_id
		LEFT JOIN gestao_escolar.school_courses co ON co.id=c.course_id
		LEFT JOIN gestao_escolar.school_years y ON y.id=c.school_year_id
		LEFT JOIN gestao_escolar.school_teachers t ON t.id=c.director_teacher_id
		WHERE c.id=$1 AND c.tenant_id=$2`, classID, u.TenantID,
	).Scan(&turma)
	if err != nil {
		jsonErr(w, "Turma não encontrada", http.StatusNotFound)
		return
	}

	var docentes any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(jsonb_build_object(
			'disciplina', sub.nome,
			'professor', COALESCE(t.nome_completo, '')
		) ORDER BY sub.nome), '[]')
		FROM gestao_escolar.school_teacher_assignments ta
		JOIN gestao_escolar.school_subjects sub ON sub.id=ta.subject_id
		LEFT JOIN gestao_escolar.school_teachers t ON t.id=ta.teacher_id
		WHERE ta.class_id=$1 AND ta.tenant_id=$2 AND ta.activo=true`,
		classID, u.TenantID,
	).Scan(&docentes)

	var alunos any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(jsonb_build_object(
			'id', s.id,
			'nome', s.nome,
			'codigo', s.codigo,
			'cargo', COALESCE((
				SELECT sr.cargo FROM gestao_escolar.school_student_roles sr
				WHERE sr.student_id=s.id AND sr.class_id=$1 AND sr.activo=true
				ORDER BY sr.data_inicio DESC LIMIT 1
			), '')
		) ORDER BY s.nome), '[]')
		FROM gestao_escolar.school_enrollments e
		JOIN gestao_escolar.school_students s ON s.id=e.student_id
		WHERE e.class_id=$1 AND e.tenant_id=$2 AND e.status='activa'`,
		classID, u.TenantID,
	).Scan(&alunos)

	jsonOK(w, map[string]any{
		"turma":    turma,
		"docentes": docentes,
		"alunos":   alunos,
	}, http.StatusOK)
}

// ── POST /api/portal/aluno/me/presencas/{id}/justificar ──────────────────────
// O aluno justifica uma falta previamente registada. Atualiza o estado para
// 'justificado' e acrescenta o motivo às observações.

func (h *Handler) PortalJustificarFalta(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	attendanceID := chi.URLParam(r, "id")

	var body struct {
		Motivo    string `json:"motivo"`
		AnexoURL  string `json:"anexo_url"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}
	if body.Motivo == "" {
		jsonErr(w, "Motivo é obrigatório", http.StatusUnprocessableEntity)
		return
	}

	tag, err := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_attendance
		   SET estado = 'justificado',
		       observacoes = COALESCE(observacoes,'') || E'\nJustificação: ' || $1 ||
		                     CASE WHEN $2 <> '' THEN E'\nAnexo: ' || $2 ELSE '' END,
		       updated_at = NOW()
		 WHERE id = $3 AND student_id = $4 AND tenant_id = $5 AND estado = 'ausente'`,
		body.Motivo, body.AnexoURL, attendanceID, u.ID, u.TenantID,
	)
	if err != nil {
		jsonErr(w, "Erro ao justificar falta", http.StatusInternalServerError)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Falta não encontrada ou já não está como ausente", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ── PUT /api/portal/aluno/me ─────────────────────────────────────────────────
// Actualiza campos editáveis do perfil do aluno. Campos sensíveis (nome, código,
// documento, estado) não são alteráveis pelo portal.

func (h *Handler) PortalActualizarPerfil(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)

	var body struct {
		Telefone      string `json:"telefone"`
		Email         string `json:"email"`
		Endereco      string `json:"endereco"`
		FotografiaURL string `json:"fotografia_url"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	// Actualizar school_students
	_, err := h.db.Exec(r.Context(), `
		UPDATE gestao_escolar.school_students
		   SET telefone = COALESCE(NULLIF($1,''), telefone),
		       email = COALESCE(NULLIF($2,''), email),
		       endereco = COALESCE(NULLIF($3,''), endereco),
		       fotografia_url = COALESCE(NULLIF($4,''), fotografia_url),
		       updated_at = NOW()
		 WHERE id = $5 AND tenant_id = $6`,
		body.Telefone, body.Email, body.Endereco, body.FotografiaURL, u.ID, u.TenantID,
	)
	if err != nil {
		jsonErr(w, "Erro ao actualizar perfil", http.StatusInternalServerError)
		return
	}

	// Sincronizar email em auth.users se foi alterado
	if body.Email != "" {
		_, _ = h.db.Exec(r.Context(), `
			UPDATE auth.users u
			   SET email = LOWER($1),
			       updated_at = NOW()
			  FROM gestao_escolar.school_students s
			 WHERE s.user_id = u.id AND s.id = $2`,
			body.Email, u.ID)
	}

	w.WriteHeader(http.StatusNoContent)
}

// ── GET /api/portal/aluno/me/noticias ────────────────────────────────────────
// Feed de notícias/comunicados públicos visíveis pelo aluno.

func (h *Handler) PortalNoticias(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)

	var classID int64
	_ = h.db.QueryRow(r.Context(), `
		SELECT e.class_id
		  FROM gestao_escolar.school_enrollments e
		 WHERE e.student_id=$1 AND e.tenant_id=$2 AND e.status='activa'
		 LIMIT 1`, u.ID, u.TenantID,
	).Scan(&classID)

	page, _ := strconv.ParseInt(r.URL.Query().Get("page"), 10, 64)
	limit, _ := strconv.ParseInt(r.URL.Query().Get("limit"), 10, 64)
	if limit <= 0 || limit > 50 {
		limit = 20
	}
	if page <= 0 {
		page = 1
	}
	offset := (page - 1) * limit

	where := "m.tenant_id=$1 AND m.status='publicado' AND m.tipo IN ('noticia','comunicado') AND ("
	where += "m.audience_type='todos' OR (m.audience_type='turma' AND m.audience_id=$2))"
	args := []any{u.TenantID, classID}

	var total int64
	_ = h.db.QueryRow(r.Context(),
		"SELECT COUNT(*) FROM gestao_escolar.school_messages m WHERE "+where, args...,
	).Scan(&total)

	paginatedArgs := append(args, limit, offset)
	var noticias any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(to_jsonb(m) ORDER BY m.publicado_em DESC), '[]')
		FROM gestao_escolar.school_messages m
		WHERE `+where+` LIMIT $`+strconv.Itoa(len(paginatedArgs)-1)+` OFFSET $`+strconv.Itoa(len(paginatedArgs)),
		paginatedArgs...,
	).Scan(&noticias)

	jsonOK(w, map[string]any{
		"noticias":   noticias,
		"total":      total,
		"pagina":     page,
		"por_pagina": limit,
		"paginas":    (total + limit - 1) / limit,
	}, http.StatusOK)
}
