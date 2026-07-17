package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ── GET /api/portal/aluno/me/boletim ─────────────────────────────────────────
// Resposta inteligente: o backend calcula tudo; o PHP apenas renderiza.

func (h *Handler) PortalBoletim(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	ctx := r.Context()

	// ── 1. Contexto do aluno (turma, nível, série, config de avaliação) ──────
	var (
		classID      int64
		levelID      *int64
		seriesID     *int64
		notaMinima   float64 = 10
		escalaMaxima float64 = 20
		sistema      string  = "0-20"
		nomePeriodo  string  = "Trimestre"
	)
	_ = h.db.QueryRow(ctx, `
		SELECT c.id, c.level_id, c.series_id,
		       COALESCE(sl.nota_minima_aprovacao, 10),
		       COALESCE(sl.escala_maxima, 20),
		       COALESCE(sl.sistema_avaliacao, '0-20'),
		       COALESCE(sl.nomenclatura_periodo, 'Trimestre')
		FROM gestao_escolar.school_enrollments e
		JOIN gestao_escolar.school_classes c ON c.id = e.class_id
		LEFT JOIN gestao_escolar.school_levels sl ON sl.id = c.level_id
		WHERE e.student_id=$1 AND e.tenant_id=$2 AND e.status='activa'
		LIMIT 1`,
		u.ID, u.TenantID,
	).Scan(&classID, &levelID, &seriesID, &notaMinima, &escalaMaxima, &sistema, &nomePeriodo)

	// ── 2. Anos lectivos nos quais o aluno esteve matriculado ────────────────
	anos := json.RawMessage("[]")
	_ = h.db.QueryRow(ctx, `
		SELECT COALESCE(jsonb_agg(to_jsonb(sy) ORDER BY sy.data_inicio DESC), '[]')
		FROM gestao_escolar.school_years sy
		JOIN gestao_escolar.school_enrollments e
		    ON e.school_year_id = sy.id AND e.student_id=$1 AND e.tenant_id=$2`,
		u.ID, u.TenantID,
	).Scan(&anos)

	// ── 3. Períodos relevantes: só com avaliações publicadas OU no currículo ─
	termos := json.RawMessage("[]")
	_ = h.db.QueryRow(ctx, `
		SELECT COALESCE(jsonb_agg(jsonb_build_object(
			'id',          t.id,
			'nome',        t.nome,
			'tipo',        t.tipo,
			'data_inicio', t.data_inicio,
			'data_fim',    t.data_fim,
			'ordem',       t.ordem,
			'ano_id',      sy.id,
			'ano_nome',    sy.nome,
			'ano_status',  sy.status
		) ORDER BY sy.data_inicio DESC, t.data_inicio), '[]')
		FROM gestao_escolar.school_terms t
		JOIN gestao_escolar.school_years sy ON sy.id = t.school_year_id
		WHERE t.level_id = $3
		AND (
			EXISTS (
				SELECT 1 FROM gestao_escolar.school_grade_items gi
				WHERE gi.class_id = $4 AND gi.term_id = t.id
				  AND gi.publicado = TRUE AND gi.tenant_id = $2
			)
			OR EXISTS (
				SELECT 1 FROM gestao_escolar.school_course_subject_terms cst
				JOIN gestao_escolar.school_course_subjects cs ON cs.id = cst.course_subject_id
				WHERE cst.term_id = t.id AND cs.tenant_id = $2
				  AND ($5::bigint IS NULL OR cs.series_id IS NULL OR cs.series_id = $5)
			)
		)`,
		u.ID, u.TenantID, levelID, classID, seriesID,
	).Scan(&termos)

	// ── 4. Período activo (data actual > primeiro com avaliações > primeiro) ─
	var activeTermID *int64
	_ = h.db.QueryRow(ctx, `
		SELECT t.id FROM gestao_escolar.school_terms t
		JOIN gestao_escolar.school_enrollments e
		    ON e.school_year_id = t.school_year_id
		   AND e.student_id=$1 AND e.tenant_id=$2
		WHERE t.level_id = $3
		ORDER BY
			CASE WHEN CURRENT_DATE BETWEEN t.data_inicio AND t.data_fim THEN 0 ELSE 1 END,
			EXISTS (
				SELECT 1 FROM gestao_escolar.school_grade_items gi
				JOIN gestao_escolar.school_enrollments e2
				    ON e2.class_id = gi.class_id AND e2.student_id=$1
				   AND e2.tenant_id=$2 AND e2.status='activa'
				WHERE gi.term_id = t.id AND gi.publicado = TRUE
			)::int DESC,
			t.data_inicio
		LIMIT 1`,
		u.ID, u.TenantID, levelID,
	).Scan(&activeTermID)

	// ── 5. Disciplinas com breakdown completo por período ────────────────────
	// Cada disciplina devolve:
	//   media, aprovado, faltas
	//   periodos[]: {term_id, nota, tem_exame, peso_exame, leccionada, tem_avaliacao}
	//
	// Disciplinas com grade_items sem term_id (anuais) aparecem na lista com periodos=[].
	// A query de subject_medias inclui ALL grade_items (com e sem term_id).
	// A query de active_pairs só inclui os que têm term_id (para o breakdown por período).
	disciplinas := json.RawMessage("[]")
	_ = h.db.QueryRow(ctx, `
		WITH
		-- Disciplinas com notas (independentemente de term_id)
		subjects_with_grades AS (
			SELECT DISTINCT gi.subject_id
			FROM gestao_escolar.school_grade_items gi
			WHERE gi.class_id=$3 AND gi.tenant_id=$2 AND gi.publicado=TRUE
		),
		-- Pares subject+term com avaliações publicadas (só com term_id)
		active_pairs AS (
			SELECT DISTINCT gi.subject_id, gi.term_id
			FROM gestao_escolar.school_grade_items gi
			WHERE gi.class_id=$3 AND gi.tenant_id=$2
			  AND gi.publicado=TRUE AND gi.term_id IS NOT NULL
		),
		-- Média ponderada por período
		period_avgs AS (
			SELECT gi.subject_id, gi.term_id,
			       ROUND((SUM(g.nota * gi.peso) / NULLIF(SUM(gi.peso),0))::numeric, 2) AS nota
			FROM gestao_escolar.school_grade_items gi
			LEFT JOIN gestao_escolar.school_grades g
			    ON g.grade_item_id=gi.id AND g.student_id=$1
			WHERE gi.class_id=$3 AND gi.tenant_id=$2
			  AND gi.publicado=TRUE AND gi.term_id IS NOT NULL
			GROUP BY gi.subject_id, gi.term_id
		),
		-- Média ponderada global por disciplina (inclui anuais sem term_id)
		subject_medias AS (
			SELECT gi.subject_id,
			       ROUND((SUM(g.nota * gi.peso) / NULLIF(SUM(gi.peso),0))::numeric, 2) AS media
			FROM gestao_escolar.school_grade_items gi
			LEFT JOIN gestao_escolar.school_grades g
			    ON g.grade_item_id=gi.id AND g.student_id=$1
			WHERE gi.class_id=$3 AND gi.tenant_id=$2 AND gi.publicado=TRUE
			GROUP BY gi.subject_id
		),
		-- Configuração do currículo por período
		curriculum AS (
			SELECT cs.subject_id, cst.term_id, cst.tem_exame, cst.peso_exame
			FROM gestao_escolar.school_course_subject_terms cst
			JOIN gestao_escolar.school_course_subjects cs ON cs.id=cst.course_subject_id
			WHERE cs.tenant_id=$2
			  AND ($4::bigint IS NULL OR cs.series_id IS NULL OR cs.series_id=$4)
		),
		-- Pares subject+term vindos de avaliações ou do currículo (para o breakdown)
		all_pairs AS (
			SELECT subject_id, term_id FROM active_pairs
			UNION
			SELECT subject_id, term_id FROM curriculum
		),
		-- Faltas por disciplina
		subject_faltas AS (
			SELECT a.subject_id, COUNT(*) AS faltas
			FROM gestao_escolar.school_attendance a
			WHERE a.student_id=$1 AND a.tenant_id=$2 AND a.status='falta'
			GROUP BY a.subject_id
		)
		SELECT COALESCE(jsonb_agg(jsonb_build_object(
			'subject_id', sub.id,
			'nome',       sub.nome,
			'media',      sm.media,
			'aprovado',   CASE WHEN sm.media IS NOT NULL THEN sm.media >= $5 ELSE NULL END,
			'faltas',     COALESCE(sf.faltas, 0),
			'periodos',   COALESCE((
				SELECT jsonb_agg(jsonb_build_object(
					'term_id',       ap2.term_id,
					'nota',          pa.nota,
					'tem_exame',     COALESCE(c.tem_exame, false),
					'peso_exame',    c.peso_exame,
					'leccionada',    (c.term_id IS NOT NULL OR act.term_id IS NOT NULL),
					'tem_avaliacao', act.term_id IS NOT NULL
				) ORDER BY ap2.term_id)
				FROM all_pairs ap2
				LEFT JOIN period_avgs pa   ON pa.subject_id=ap2.subject_id  AND pa.term_id=ap2.term_id
				LEFT JOIN curriculum c     ON c.subject_id=ap2.subject_id   AND c.term_id=ap2.term_id
				LEFT JOIN active_pairs act ON act.subject_id=ap2.subject_id AND act.term_id=ap2.term_id
				WHERE ap2.subject_id=sub.id
			), '[]'::jsonb)
		) ORDER BY sub.nome), '[]'::jsonb)
		-- Listar todas as disciplinas com notas OU no currículo
		FROM (
			SELECT subject_id FROM subjects_with_grades
			UNION
			SELECT subject_id FROM curriculum
		) dist
		JOIN gestao_escolar.school_subjects sub ON sub.id=dist.subject_id
		LEFT JOIN subject_medias sm ON sm.subject_id=sub.id
		LEFT JOIN subject_faltas sf ON sf.subject_id=sub.id`,
		u.ID, u.TenantID, classID, seriesID, notaMinima,
	).Scan(&disciplinas)

	// ── 6. Estatísticas globais ──────────────────────────────────────────────
	var mediaGeral *float64
	var totalDisc, aprovadas, reprovadas int64
	_ = h.db.QueryRow(ctx, `
		SELECT
			ROUND(AVG(media)::numeric, 2),
			COUNT(*) FILTER (WHERE media IS NOT NULL),
			COUNT(*) FILTER (WHERE media >= $3),
			COUNT(*) FILTER (WHERE media IS NOT NULL AND media < $3)
		FROM (
			SELECT gi.subject_id,
			       SUM(g.nota * gi.peso) / NULLIF(SUM(gi.peso), 0) AS media
			FROM gestao_escolar.school_grade_items gi
			LEFT JOIN gestao_escolar.school_grades g ON g.grade_item_id=gi.id AND g.student_id=$1
			WHERE gi.class_id=$2 AND gi.tenant_id=$4 AND gi.publicado=TRUE
			GROUP BY gi.subject_id
		) sm`,
		u.ID, classID, notaMinima, u.TenantID,
	).Scan(&mediaGeral, &totalDisc, &aprovadas, &reprovadas)

	var totalFaltas int64
	_ = h.db.QueryRow(ctx, `
		SELECT COUNT(*) FROM gestao_escolar.school_attendance
		WHERE student_id=$1 AND tenant_id=$2 AND status='falta'`,
		u.ID, u.TenantID,
	).Scan(&totalFaltas)

	jsonOK(w, map[string]any{
		"config": map[string]any{
			"nota_minima":          notaMinima,
			"escala_maxima":        escalaMaxima,
			"sistema_avaliacao":    sistema,
			"nomenclatura_periodo": nomePeriodo,
		},
		"active_term_id": activeTermID,
		"media":          mediaGeral,
		"stats": map[string]any{
			"total":      totalDisc,
			"aprovadas":  aprovadas,
			"reprovadas": reprovadas,
			"faltas":     totalFaltas,
		},
		"anos":        anos,
		"termos":      termos,
		"disciplinas": disciplinas,
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
				'slot',        to_jsonb(ts),
				'disciplina',  sub.nome,
				'subject_id',  sub.id,
				'cor',         sub.cor,
				'icone',       sub.icone,
				'professor',   COALESCE(t.nome_completo, '')
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
		"records":    records,
		"total":      total,
		"pagina":     page,
		"por_pagina": limit,
		"paginas":    (total + limit - 1) / limit,
	}, http.StatusOK)
}

// ── POST /api/portal/aluno/me/turma/presencas ────────────────────────────────
// Permite a um aluno com cargo autorizado na turma (ex.: delegado) marcar a
// presença dos colegas. Autorização vem de school_cargo_permissoes — não é
// RBAC de staff, é por cargo em school_student_roles, scoped à própria turma
// onde o aluno tem esse cargo activo.

// alunoTemPermissaoTurma confirma que o aluno autenticado tem, através de um
// cargo activo em school_student_roles para esta turma, a permissão indicada
// (registada em school_cargo_permissoes pela secretaria/admin).
func (h *Handler) alunoTemPermissaoTurma(r *http.Request, studentID, classID, tenantID int64, permissao string) bool {
	var ok bool
	_ = h.db.QueryRow(r.Context(), `
		SELECT EXISTS(
			SELECT 1 FROM gestao_escolar.school_student_roles sr
			JOIN gestao_escolar.school_cargo_permissoes cp
			  ON cp.tenant_id = sr.tenant_id AND cp.class_id = sr.class_id AND cp.cargo = sr.cargo
			 WHERE sr.student_id = $1 AND sr.class_id = $2 AND sr.tenant_id = $3
			   AND sr.activo = true AND cp.permissao = $4
			   AND (sr.data_fim IS NULL OR sr.data_fim >= CURRENT_DATE)
		)`, studentID, classID, tenantID, permissao,
	).Scan(&ok)
	return ok
}

func (h *Handler) PortalAlunoMarcarPresencas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetAlunoUser(r)
	var body struct {
		ClassID   int64  `json:"class_id"`
		Data      string `json:"data"`
		Presencas []struct {
			StudentID  int64  `json:"student_id"`
			Estado     string `json:"estado"`
			Observacao string `json:"observacao"`
		} `json:"presencas"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.ClassID == 0 || body.Data == "" {
		jsonErr(w, "class_id e data são obrigatórios", http.StatusBadRequest)
		return
	}
	if !h.alunoTemPermissaoTurma(r, u.ID, body.ClassID, u.TenantID, "marcar_presencas") {
		jsonErr(w, "Sem permissão para marcar presenças nesta turma", http.StatusForbidden)
		return
	}

	payload, err := json.Marshal(body.Presencas)
	if err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	var count int64
	err = h.db.QueryRow(r.Context(), `
		WITH ins AS (
			INSERT INTO gestao_escolar.school_attendance
				(tenant_id, class_id, student_id, attendance_date, estado, observacoes)
			SELECT $1, $2, (x->>'student_id')::bigint, $3::date, x->>'estado', NULLIF(x->>'observacao','')
			  FROM jsonb_array_elements($4::jsonb) x
			  JOIN gestao_escolar.school_students s
			    ON s.id = (x->>'student_id')::bigint AND s.tenant_id = $1
			 WHERE x->>'estado' IN ('presente','ausente','justificado','atrasado')
			ON CONFLICT ON CONSTRAINT uq_school_attendance_entry DO UPDATE
			   SET estado = EXCLUDED.estado, observacoes = EXCLUDED.observacoes, updated_at = NOW()
			RETURNING 1
		) SELECT COUNT(*) FROM ins`,
		u.TenantID, body.ClassID, body.Data, payload,
	).Scan(&count)
	if err != nil {
		jsonErr(w, "Erro ao guardar presenças", http.StatusInternalServerError)
		return
	}
	jsonOK(w, map[string]any{"registos": count}, http.StatusOK)
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
	if err := h.db.QueryRow(r.Context(),
		"SELECT COUNT(*) FROM gestao_escolar.school_library_loans l WHERE "+where, args...,
	).Scan(&total); err != nil {
		jsonErr(w, "Erro ao obter empréstimos", http.StatusInternalServerError)
		return
	}

	paginatedArgs := append(args, limit, offset)
	var records any
	err := h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(
			to_jsonb(l) || jsonb_build_object(
				'livro_titulo',    b.titulo,
				'livro_autor',     b.autor,
				'livro_isbn',      b.isbn,
				'livro_categoria', b.categoria
			) ORDER BY l.emprestado_em DESC
		), '[]')
		FROM gestao_escolar.school_library_loans l
		JOIN gestao_escolar.school_books b ON b.id = l.book_id
		WHERE `+where+fmt.Sprintf(` LIMIT $%d OFFSET $%d`, len(paginatedArgs)-1, len(paginatedArgs)),
		paginatedArgs...,
	).Scan(&records)
	if err != nil {
		jsonErr(w, "Erro ao obter empréstimos", http.StatusInternalServerError)
		return
	}

	jsonOK(w, map[string]any{
		"records":    records,
		"total":      total,
		"pagina":     page,
		"por_pagina": limit,
		"paginas":    (total + limit - 1) / limit,
	}, http.StatusOK)
}
