package handlers

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ── GET /api/portal/aluno/me/boletim ─────────────────────────────────────────
// Retorna médias por disciplina + lista de períodos para o selector.

func (h *Handler) PortalBoletim(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	termID, _ := strconv.ParseInt(r.URL.Query().Get("term_id"), 10, 64)

	gradeWhere := "g.student_id=$1 AND g.tenant_id=$2"
	gradeArgs := []any{u.ID, u.TenantID}
	if termID > 0 {
		gradeArgs = append(gradeArgs, termID)
		gradeWhere += " AND i.term_id=$3"
	}

	// Médias ponderadas por disciplina (só avaliações publicadas)
	var grades any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(jsonb_build_object(
			'subject_id', x.subject_id,
			'nome',       x.nome,
			'media',      ROUND(x.media,2),
			'avaliacoes', x.avaliacoes
		) ORDER BY x.nome), '[]')
		FROM (
			SELECT sub.id AS subject_id,
			       sub.nome,
			       SUM(g.nota*i.peso)/NULLIF(SUM(i.peso),0) AS media,
			       COUNT(g.id) AS avaliacoes
			FROM gestao_escolar.school_grades g
			JOIN gestao_escolar.school_grade_items i ON i.id=g.grade_item_id AND i.publicado=TRUE
			JOIN gestao_escolar.school_subjects sub ON sub.id=i.subject_id
			WHERE `+gradeWhere+`
			GROUP BY sub.id, sub.nome
		) x`, gradeArgs...,
	).Scan(&grades)

	// Média geral (média das médias por disciplina)
	var mediaGeral *float64
	_ = h.db.QueryRow(r.Context(), `
		SELECT ROUND(AVG(disc_avg),2) FROM (
			SELECT SUM(g.nota*i.peso)/NULLIF(SUM(i.peso),0) disc_avg
			FROM gestao_escolar.school_grades g
			JOIN gestao_escolar.school_grade_items i ON i.id=g.grade_item_id AND i.publicado=TRUE
			WHERE `+gradeWhere+` GROUP BY i.subject_id
		) x`, gradeArgs...,
	).Scan(&mediaGeral)

	// Períodos disponíveis para o selector
	var terms any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY t.data_inicio), '[]')
		FROM gestao_escolar.school_terms t
		JOIN gestao_escolar.school_enrollments e
		    ON e.school_year_id = t.school_year_id
		   AND e.student_id = $1 AND e.tenant_id = $2 AND e.status = 'activa'`,
		u.ID, u.TenantID,
	).Scan(&terms)

	jsonOK(w, map[string]any{
		"grades": grades,
		"media":  mediaGeral,
		"terms":  terms,
	}, http.StatusOK)
}

// ── GET /api/portal/aluno/me/notas ───────────────────────────────────────────
// Detalhe individual de cada avaliação (3.5).

func (h *Handler) PortalDetalhesNotas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)

	where := "g.student_id=$1 AND g.tenant_id=$2 AND i.publicado=TRUE"
	args := []any{u.ID, u.TenantID}

	if v := r.URL.Query().Get("term_id"); v != "" {
		args = append(args, v)
		where += " AND i.term_id=$" + strconv.Itoa(len(args))
	}
	if v := r.URL.Query().Get("subject_id"); v != "" {
		args = append(args, v)
		where += " AND i.subject_id=$" + strconv.Itoa(len(args))
	}

	var result any
	err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(jsonb_build_object(
			'avaliacao_id', i.id,
			'avaliacao',    i.nome,
			'tipo',         i.tipo,
			'data',         i.data_avaliacao,
			'nota_maxima',  i.nota_maxima,
			'nota',         g.nota,
			'observacoes',  g.observacoes,
			'peso',         i.peso,
			'disciplina',   sub.nome,
			'periodo',      t.nome
		) ORDER BY i.data_avaliacao DESC), '[]')
		FROM gestao_escolar.school_grades g
		JOIN gestao_escolar.school_grade_items i ON i.id=g.grade_item_id
		JOIN gestao_escolar.school_subjects sub ON sub.id=i.subject_id
		LEFT JOIN gestao_escolar.school_terms t ON t.id=i.term_id
		WHERE `+where, args...,
	).Scan(&result)
	if err != nil {
		jsonErr(w, "Erro ao obter notas", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── GET /api/portal/aluno/me/cobrancas ───────────────────────────────────────

func (h *Handler) PortalCobrancas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	status := r.URL.Query().Get("status")
	where := "tenant_id=$1 AND student_id=$2"
	args := []any{u.TenantID, u.ID}
	if status != "" {
		args = append(args, status)
		where += " AND status=$" + strconv.Itoa(len(args))
	}

	var result any
	err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(
			to_jsonb(f) || jsonb_build_object(
				'saldo', GREATEST(f.valor_total - COALESCE(f.desconto,0) - COALESCE(f.valor_pago,0), 0)
			) ORDER BY f.data_vencimento DESC
		), '[]')
		FROM gestao_escolar.school_fees f
		WHERE `+where, args...).Scan(&result)
	if err != nil {
		jsonErr(w, "Erro ao obter cobranças", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── GET /api/portal/aluno/me/cobrancas/{id}/recibo ───────────────────────────
// Retorna dados completos de uma cobrança (com pagamentos) para imprimir recibo (3.2).

func (h *Handler) PortalReciboCobranca(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	id := chi.URLParam(r, "id")

	var result any
	err := h.db.QueryRow(r.Context(), `
		SELECT to_jsonb(f) || jsonb_build_object(
			'aluno', jsonb_build_object(
				'id', s.id, 'nome', s.nome, 'codigo', s.codigo
			),
			'pagamentos', COALESCE((
				SELECT jsonb_agg(to_jsonb(p) ORDER BY p.pago_em DESC)
				FROM gestao_escolar.school_payments p
				WHERE p.school_fee_id = f.id AND p.status = 'confirmado'
			), '[]')
		)
		FROM gestao_escolar.school_fees f
		JOIN gestao_escolar.school_students s ON s.id = f.student_id
		WHERE f.id = $1 AND f.student_id = $2 AND f.tenant_id = $3`,
		id, u.ID, u.TenantID,
	).Scan(&result)
	if err != nil {
		jsonErr(w, "Recibo não encontrado", http.StatusNotFound)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── GET /api/portal/aluno/me/horario ─────────────────────────────────────────

func (h *Handler) PortalHorario(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)

	var classID int64
	err := h.db.QueryRow(r.Context(), `
		SELECT e.class_id
		  FROM gestao_escolar.school_enrollments e
		 WHERE e.student_id = $1 AND e.tenant_id = $2 AND e.status = 'activa'
		 LIMIT 1`, u.ID, u.TenantID,
	).Scan(&classID)
	if err != nil {
		jsonOK(w, []any{}, http.StatusOK)
		return
	}

	var result any
	err = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(
			to_jsonb(te) || jsonb_build_object(
				'slot', to_jsonb(ts),
				'disciplina', sub.nome,
				'professor', COALESCE(t.nome_completo, '')
			) ORDER BY te.dia_semana, ts.hora_inicio
		), '[]')
		FROM gestao_escolar.school_timetable_entries te
		JOIN gestao_escolar.school_time_slots ts ON ts.id = te.time_slot_id
		JOIN gestao_escolar.school_subjects sub ON sub.id = te.subject_id
		LEFT JOIN gestao_escolar.school_teachers t ON t.id = te.teacher_id
		WHERE te.class_id = $1 AND te.tenant_id = $2 AND te.activo = true`,
		classID, u.TenantID,
	).Scan(&result)
	if err != nil {
		jsonErr(w, "Erro ao obter horário", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── GET /api/portal/aluno/me/mensagens ───────────────────────────────────────

func (h *Handler) PortalMensagens(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)

	var classID int64
	_ = h.db.QueryRow(r.Context(), `
		SELECT e.class_id FROM gestao_escolar.school_enrollments e
		WHERE e.student_id=$1 AND e.tenant_id=$2 AND e.status='activa' LIMIT 1`,
		u.ID, u.TenantID,
	).Scan(&classID)

	var result any
	err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(to_jsonb(m) ORDER BY m.publicado_em DESC), '[]')
		FROM gestao_escolar.school_messages m
		WHERE m.tenant_id = $1
		  AND m.status = 'publicado'
		  AND (
		      m.audience_type = 'todos'
		   OR (m.audience_type = 'turma'   AND m.audience_id = $2)
		   OR (m.audience_type = 'aluno'   AND m.audience_id = $3)
		  )`,
		u.TenantID, classID, u.ID,
	).Scan(&result)
	if err != nil {
		jsonErr(w, "Erro ao obter mensagens", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── GET /api/portal/aluno/me/eventos ─────────────────────────────────────────

func (h *Handler) PortalEventos(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	var result any
	err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(
			to_jsonb(ce) || jsonb_build_object('tipo', et.nome, 'cor', et.cor)
			ORDER BY ce.data_inicio
		), '[]')
		FROM gestao_escolar.school_calendar_events ce
		LEFT JOIN gestao_escolar.school_calendar_event_types et ON et.id = ce.event_type_id
		WHERE ce.tenant_id = $1
		  AND ce.data_inicio >= CURRENT_DATE - INTERVAL '7 days'`, u.TenantID,
	).Scan(&result)
	if err != nil {
		jsonErr(w, "Erro ao obter eventos", http.StatusInternalServerError)
		return
	}
	jsonOK(w, result, http.StatusOK)
}

// ── GET /api/portal/aluno/me/presencas ───────────────────────────────────────
// Suporta paginação: ?page=1&limit=30&mes=YYYY-MM (3.4)

func (h *Handler) PortalPresencas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	mes := r.URL.Query().Get("mes")

	page, _ := strconv.ParseInt(r.URL.Query().Get("page"), 10, 64)
	limit, _ := strconv.ParseInt(r.URL.Query().Get("limit"), 10, 64)
	if limit <= 0 || limit > 100 {
		limit = 30
	}
	if page <= 0 {
		page = 1
	}
	offset := (page - 1) * limit

	where := "a.student_id=$1 AND a.tenant_id=$2"
	args := []any{u.ID, u.TenantID}
	if mes != "" {
		where += " AND to_char(a.attendance_date,'YYYY-MM')=$3"
		args = append(args, mes)
	}

	// Contar total
	var total int64
	_ = h.db.QueryRow(r.Context(),
		"SELECT COUNT(*) FROM gestao_escolar.school_attendance a WHERE "+where, args...,
	).Scan(&total)

	// Dados paginados
	paginatedArgs := append(args, limit, offset)
	var records any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(
			to_jsonb(a) || jsonb_build_object('disciplina', sub.nome)
			ORDER BY a.attendance_date DESC, sub.nome
		), '[]')
		FROM gestao_escolar.school_attendance a
		LEFT JOIN gestao_escolar.school_subjects sub ON sub.id = a.subject_id
		WHERE `+where+fmt.Sprintf(` LIMIT $%d OFFSET $%d`, len(paginatedArgs)-1, len(paginatedArgs)),
		paginatedArgs...,
	).Scan(&records)

	jsonOK(w, map[string]any{
		"records":  records,
		"total":    total,
		"pagina":   page,
		"por_pagina": limit,
		"paginas":  (total + limit - 1) / limit,
	}, http.StatusOK)
}

// ── GET /api/portal/aluno/me/ocorrencias ─────────────────────────────────────

func (h *Handler) PortalOcorrencias(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)

	var incidentes, sancoes, meritos any

	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(
			to_jsonb(i) || jsonb_build_object('tipo', it.nome, 'gravidade', it.gravidade)
			ORDER BY i.data_ocorrencia DESC
		), '[]')
		FROM gestao_escolar.school_student_incidents i
		LEFT JOIN gestao_escolar.school_incident_types it ON it.id = i.incident_type_id
		WHERE i.student_id = $1 AND i.tenant_id = $2`,
		u.ID, u.TenantID,
	).Scan(&incidentes)

	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(
			to_jsonb(s) || jsonb_build_object('tipo', st.nome)
			ORDER BY s.data_inicio DESC
		), '[]')
		FROM gestao_escolar.school_student_sanctions s
		LEFT JOIN gestao_escolar.school_sanction_types st ON st.id = s.sanction_type_id
		WHERE s.student_id = $1 AND s.tenant_id = $2`,
		u.ID, u.TenantID,
	).Scan(&sancoes)

	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(to_jsonb(m) ORDER BY m.data_merito DESC), '[]')
		FROM gestao_escolar.school_student_merits m
		WHERE m.student_id = $1 AND m.tenant_id = $2`,
		u.ID, u.TenantID,
	).Scan(&meritos)

	jsonOK(w, map[string]any{
		"incidentes": incidentes,
		"sancoes":    sancoes,
		"meritos":    meritos,
	}, http.StatusOK)
}

// ── GET /api/portal/aluno/me/biblioteca ──────────────────────────────────────
// Suporta paginação: ?page=1&limit=20&status=emprestado (3.4)

func (h *Handler) PortalBiblioteca(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	status := r.URL.Query().Get("status")

	page, _ := strconv.ParseInt(r.URL.Query().Get("page"), 10, 64)
	limit, _ := strconv.ParseInt(r.URL.Query().Get("limit"), 10, 64)
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	if page <= 0 {
		page = 1
	}
	offset := (page - 1) * limit

	where := "l.student_id = $1 AND l.tenant_id = $2"
	args := []any{u.ID, u.TenantID}
	if status != "" {
		args = append(args, status)
		where += " AND l.status = $" + strconv.Itoa(len(args))
	}

	var total int64
	_ = h.db.QueryRow(r.Context(),
		"SELECT COUNT(*) FROM gestao_escolar.school_library_loans l WHERE "+where, args...,
	).Scan(&total)

	paginatedArgs := append(args, limit, offset)
	var records any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(
			to_jsonb(l) || jsonb_build_object(
				'livro_titulo',    b.titulo,
				'livro_autor',     b.autor,
				'livro_isbn',      b.isbn,
				'livro_categoria', b.categoria,
				'capa_url',        b.capa_url
			) ORDER BY l.emprestado_em DESC
		), '[]')
		FROM gestao_escolar.school_library_loans l
		JOIN gestao_escolar.school_books b ON b.id = l.book_id
		WHERE `+where+fmt.Sprintf(` LIMIT $%d OFFSET $%d`, len(paginatedArgs)-1, len(paginatedArgs)),
		paginatedArgs...,
	).Scan(&records)

	jsonOK(w, map[string]any{
		"records":    records,
		"total":      total,
		"pagina":     page,
		"por_pagina": limit,
		"paginas":    (total + limit - 1) / limit,
	}, http.StatusOK)
}
