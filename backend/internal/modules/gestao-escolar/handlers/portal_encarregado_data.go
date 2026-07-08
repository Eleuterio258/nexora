package handlers

import (
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// helper: verifica se o encarregado está ligado ao student_id
func (h *Handler) encarregadoTemAcesso(r *http.Request, u *mw.EncarregadoUser, studentID string) bool {
	var exists bool
	_ = h.db.QueryRow(r.Context(), `
		SELECT EXISTS(
			SELECT 1 FROM gestao_escolar.school_guardians
			 WHERE LOWER(portal_email) = LOWER($1) AND student_id = $2 AND tenant_id = $3
		)`, u.Email, studentID, u.TenantID,
	).Scan(&exists)
	return exists
}

// ── GET /api/portal/encarregado/me/educandos/{id}/boletim ────────────────────

func (h *Handler) EncarregadoBoletim(w http.ResponseWriter, r *http.Request) {
	u := mw.GetEncarregadoUser(r)
	studentID := chi.URLParam(r, "id")
	if !h.encarregadoTemAcesso(r, u, studentID) {
		jsonErr(w, "Acesso negado", http.StatusForbidden)
		return
	}

	sid, _ := strconv.ParseInt(studentID, 10, 64)
	termID, _ := strconv.ParseInt(r.URL.Query().Get("term_id"), 10, 64)

	gradeWhere := "g.student_id=$1 AND g.tenant_id=$2"
	gradeArgs := []any{sid, u.TenantID}
	if termID > 0 {
		gradeArgs = append(gradeArgs, termID)
		gradeWhere += " AND i.term_id=$3"
	}

	var grades any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(jsonb_build_object(
			'subject_id', x.subject_id,
			'nome',       x.nome,
			'p1',         ROUND(x.p1,2),
			'p2',         ROUND(x.p2,2),
			'p3',         ROUND(x.p3,2),
			'exame',      ROUND(x.exame,2),
			'media',      ROUND(x.media,2),
			'avaliacoes', x.avaliacoes
		) ORDER BY x.nome), '[]')
		FROM (
			SELECT sub.id AS subject_id,
			       sub.nome,
			       AVG(g.nota) FILTER (
			           WHERE lower(COALESCE(i.tipo,'')) <> 'exame'
			             AND lower(COALESCE(i.nome,'')) NOT LIKE '%exame%'
			             AND (
			                 lower(COALESCE(t.codigo,'')) IN ('p1','t1','1')
			              OR lower(COALESCE(t.codigo,'')) LIKE '%t1'
			              OR lower(COALESCE(t.codigo,'')) LIKE '%-t1'
			              OR lower(COALESCE(t.nome,'')) LIKE '1%'
			              OR lower(COALESCE(t.nome,'')) LIKE '%primeir%'
			             )
			       ) AS p1,
			       AVG(g.nota) FILTER (
			           WHERE lower(COALESCE(i.tipo,'')) <> 'exame'
			             AND lower(COALESCE(i.nome,'')) NOT LIKE '%exame%'
			             AND (
			                 lower(COALESCE(t.codigo,'')) IN ('p2','t2','2')
			              OR lower(COALESCE(t.codigo,'')) LIKE '%t2'
			              OR lower(COALESCE(t.codigo,'')) LIKE '%-t2'
			              OR lower(COALESCE(t.nome,'')) LIKE '2%'
			              OR lower(COALESCE(t.nome,'')) LIKE '%segund%'
			             )
			       ) AS p2,
			       AVG(g.nota) FILTER (
			           WHERE lower(COALESCE(i.tipo,'')) <> 'exame'
			             AND lower(COALESCE(i.nome,'')) NOT LIKE '%exame%'
			             AND (
			                 lower(COALESCE(t.codigo,'')) IN ('p3','t3','3')
			              OR lower(COALESCE(t.codigo,'')) LIKE '%t3'
			              OR lower(COALESCE(t.codigo,'')) LIKE '%-t3'
			              OR lower(COALESCE(t.nome,'')) LIKE '3%'
			              OR lower(COALESCE(t.nome,'')) LIKE '%terceir%'
			             )
			       ) AS p3,
			       AVG(g.nota) FILTER (
			           WHERE lower(COALESCE(i.tipo,'')) = 'exame'
			              OR lower(COALESCE(i.nome,'')) LIKE '%exame%'
			       ) AS exame,
			       SUM(g.nota*i.peso)/NULLIF(SUM(i.peso),0) AS media,
			       COUNT(g.id) AS avaliacoes
			FROM gestao_escolar.school_grades g
			JOIN gestao_escolar.school_grade_items i ON i.id=g.grade_item_id AND i.publicado=TRUE
			LEFT JOIN gestao_escolar.school_terms t ON t.id=i.term_id
			JOIN gestao_escolar.school_subjects sub ON sub.id=i.subject_id
			WHERE `+gradeWhere+`
			GROUP BY sub.id, sub.nome
		) x`, gradeArgs...,
	).Scan(&grades)

	var media *float64
	_ = h.db.QueryRow(r.Context(), `
		SELECT ROUND(AVG(d),2) FROM (
			SELECT SUM(g.nota*i.peso)/NULLIF(SUM(i.peso),0) d
			FROM gestao_escolar.school_grades g
			JOIN gestao_escolar.school_grade_items i ON i.id=g.grade_item_id AND i.publicado=TRUE
			WHERE `+gradeWhere+` GROUP BY i.subject_id
		) x`, gradeArgs...,
	).Scan(&media)

	var terms any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY t.data_inicio), '[]')
		FROM gestao_escolar.school_terms t
		JOIN gestao_escolar.school_enrollments e ON e.school_year_id=t.school_year_id
		   AND e.student_id=$1 AND e.tenant_id=$2 AND e.status='activa'`,
		sid, u.TenantID,
	).Scan(&terms)

	jsonOK(w, map[string]any{"grades": grades, "media": media, "terms": terms}, http.StatusOK)
}

// ── GET /api/portal/encarregado/me/educandos/{id}/cobrancas ──────────────────

func (h *Handler) EncarregadoCobrancas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetEncarregadoUser(r)
	studentID := chi.URLParam(r, "id")
	if !h.encarregadoTemAcesso(r, u, studentID) {
		jsonErr(w, "Acesso negado", http.StatusForbidden)
		return
	}

	where := "f.student_id=$1 AND f.tenant_id=$2"
	args := []any{studentID, u.TenantID}
	if s := r.URL.Query().Get("status"); s != "" {
		args = append(args, s)
		where += " AND f.status=$" + strconv.Itoa(len(args))
	}

	var result any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(
			to_jsonb(f) || jsonb_build_object('saldo', GREATEST(f.valor_total-f.desconto-f.valor_pago,0))
			ORDER BY f.data_vencimento DESC
		), '[]')
		FROM gestao_escolar.school_fees f
		WHERE `+where, args...,
	).Scan(&result)

	jsonOK(w, result, http.StatusOK)
}

// ── GET /api/portal/encarregado/me/educandos/{id}/presencas ──────────────────

func (h *Handler) EncarregadoPresencas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetEncarregadoUser(r)
	studentID := chi.URLParam(r, "id")
	if !h.encarregadoTemAcesso(r, u, studentID) {
		jsonErr(w, "Acesso negado", http.StatusForbidden)
		return
	}

	where := "a.student_id=$1 AND a.tenant_id=$2"
	args := []any{studentID, u.TenantID}
	if mes := r.URL.Query().Get("mes"); mes != "" {
		args = append(args, mes)
		where += " AND to_char(a.data,'YYYY-MM')=$3"
	}

	var result any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(
			to_jsonb(a) || jsonb_build_object('disciplina', sub.nome)
			ORDER BY a.data DESC, sub.nome
		), '[]')
		FROM gestao_escolar.attendance_records a
		LEFT JOIN gestao_escolar.school_subjects sub ON sub.id = a.subject_id
		WHERE `+where, args...,
	).Scan(&result)

	jsonOK(w, result, http.StatusOK)
}

// ── GET /api/portal/encarregado/me/educandos/{id}/ocorrencias ────────────────

func (h *Handler) EncarregadoOcorrencias(w http.ResponseWriter, r *http.Request) {
	u := mw.GetEncarregadoUser(r)
	studentID := chi.URLParam(r, "id")
	if !h.encarregadoTemAcesso(r, u, studentID) {
		jsonErr(w, "Acesso negado", http.StatusForbidden)
		return
	}

	var incidentes, sancoes any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(
			to_jsonb(i) || jsonb_build_object('tipo', it.nome, 'gravidade', it.gravidade)
			ORDER BY i.data_ocorrencia DESC
		), '[]')
		FROM gestao_escolar.school_student_incidents i
		LEFT JOIN gestao_escolar.school_incident_types it ON it.id=i.incident_type_id
		WHERE i.student_id=$1 AND i.tenant_id=$2`, studentID, u.TenantID,
	).Scan(&incidentes)

	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(to_jsonb(s) ORDER BY s.data_inicio DESC), '[]')
		FROM gestao_escolar.school_student_sanctions s
		WHERE s.student_id=$1 AND s.tenant_id=$2`, studentID, u.TenantID,
	).Scan(&sancoes)

	jsonOK(w, map[string]any{"incidentes": incidentes, "sancoes": sancoes}, http.StatusOK)
}
