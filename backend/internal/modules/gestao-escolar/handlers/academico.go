package handlers

import (
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

func (h *Handler) listarCargosEscolares(w http.ResponseWriter, r *http.Request, table, owner string) {
	u := mw.GetUser(r)
	where := "x.tenant_id=$1"
	args := []any{u.TenantID}
	appendSchoolFilter(&where, &args, "x.activo", r.URL.Query().Get("activo"))
	appendSchoolFilter(&where, &args, "x."+owner, r.URL.Query().Get(owner))
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.created_at DESC),'[]')
		FROM gestao_escolar.`+table+` x WHERE `+where, args...)
}

func (h *Handler) ListarCargosAlunos(w http.ResponseWriter, r *http.Request) {
	h.listarCargosEscolares(w, r, "school_student_roles", "student_id")
}

func (h *Handler) AtribuirCargoAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolCreate(w, r, `INSERT INTO gestao_escolar.school_student_roles
		(tenant_id,student_id,class_id,cargo,data_inicio,data_fim,observacoes)
		SELECT $1,s.id,j.class_id,j.cargo,COALESCE(j.data_inicio,CURRENT_DATE),j.data_fim,j.observacoes
		FROM jsonb_to_record($2::jsonb) AS j(student_id bigint,class_id bigint,cargo text,data_inicio date,data_fim date,observacoes text)
		JOIN gestao_escolar.school_students s ON s.id=j.student_id AND s.tenant_id=$1
		WHERE j.cargo<>'' RETURNING school_student_roles.id`, u.TenantID, body)
}

func (h *Handler) ActualizarCargoAluno(w http.ResponseWriter, r *http.Request) {
	h.actualizarCargoEscolar(w, r, "school_student_roles")
}

func (h *Handler) RevogarCargoAluno(w http.ResponseWriter, r *http.Request) {
	h.revogarCargoEscolar(w, r, "school_student_roles")
}

func (h *Handler) ListarCargosProfessores(w http.ResponseWriter, r *http.Request) {
	h.listarCargosEscolares(w, r, "school_teacher_roles", "teacher_id")
}

func (h *Handler) AtribuirCargoProfessor(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolCreate(w, r, `INSERT INTO gestao_escolar.school_teacher_roles
		(tenant_id,teacher_id,cargo,school_year_id,data_inicio,data_fim,observacoes)
		SELECT $1,j.teacher_id,j.cargo,j.year_id,COALESCE(j.data_inicio,CURRENT_DATE),j.data_fim,j.observacoes
		FROM jsonb_to_record($2::jsonb) AS j(teacher_id bigint,cargo text,year_id bigint,data_inicio date,data_fim date,observacoes text)
		WHERE j.teacher_id>0 AND j.cargo<>'' RETURNING id`, u.TenantID, body)
}

func (h *Handler) ActualizarCargoProfessor(w http.ResponseWriter, r *http.Request) {
	h.actualizarCargoEscolar(w, r, "school_teacher_roles")
}

func (h *Handler) RevogarCargoProfessor(w http.ResponseWriter, r *http.Request) {
	h.revogarCargoEscolar(w, r, "school_teacher_roles")
}

func (h *Handler) actualizarCargoEscolar(w http.ResponseWriter, r *http.Request, table string) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolUpdate(w, r, `UPDATE gestao_escolar.`+table+` SET
		cargo=COALESCE(NULLIF($1::jsonb->>'cargo',''),cargo),
		data_inicio=COALESCE(($1::jsonb->>'data_inicio')::date,data_inicio),
		data_fim=COALESCE(($1::jsonb->>'data_fim')::date,data_fim),
		observacoes=COALESCE($1::jsonb->>'observacoes',observacoes),updated_at=NOW()
		WHERE id=$2 AND tenant_id=$3`, body, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) revogarCargoEscolar(w http.ResponseWriter, r *http.Request, table string) {
	u := mw.GetUser(r)
	h.schoolUpdate(w, r, `UPDATE gestao_escolar.`+table+`
		SET activo=false,data_fim=COALESCE(data_fim,CURRENT_DATE),updated_at=NOW()
		WHERE id=$1 AND tenant_id=$2 AND activo`, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) ListarFrequencias(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "a.tenant_id=$1"
	args := []any{u.TenantID}
	appendSchoolFilter(&where, &args, "a.class_id", r.URL.Query().Get("class_id"))
	appendSchoolFilter(&where, &args, "a.subject_id", r.URL.Query().Get("subject_id"))
	appendSchoolFilter(&where, &args, "a.attendance_date", r.URL.Query().Get("data"))
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.attendance_date DESC,x.aluno),'[]') FROM (
		SELECT a.*,s.nome aluno,c.nome turma,d.nome disciplina FROM gestao_escolar.school_attendance a
		JOIN gestao_escolar.school_students s ON s.id=a.student_id
		JOIN gestao_escolar.school_classes c ON c.id=a.class_id
		LEFT JOIN gestao_escolar.school_subjects d ON d.id=a.subject_id WHERE `+where+`) x`, args...)
}

func (h *Handler) LancarFrequencia(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	var count int64
	err = h.db.QueryRow(r.Context(), `WITH input AS (
		SELECT ($2::jsonb->>'class_id')::bigint class_id,($2::jsonb->>'subject_id')::bigint subject_id,
		COALESCE(($2::jsonb->>'data')::date,CURRENT_DATE) data,$2::jsonb->'students' students
	), ins AS (
		INSERT INTO gestao_escolar.school_attendance(tenant_id,class_id,student_id,subject_id,attendance_date,estado,observacoes,created_by)
		SELECT $1,i.class_id,(x->>'student_id')::bigint,i.subject_id,i.data,x->>'estado',x->>'observacoes',$3
		FROM input i,jsonb_array_elements(i.students) x
		JOIN gestao_escolar.school_students s ON s.id=(x->>'student_id')::bigint AND s.tenant_id=$1
		ON CONFLICT(tenant_id,class_id,student_id,attendance_date,COALESCE(subject_id,0))
		DO UPDATE SET estado=EXCLUDED.estado,observacoes=EXCLUDED.observacoes,updated_at=NOW()
		RETURNING 1) SELECT COUNT(*) FROM ins`, u.TenantID, body, u.ID).Scan(&count)
	if err != nil || count == 0 {
		jsonErr(w, "Frequencias invalidas", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"registos": count}, http.StatusCreated)
}

func (h *Handler) CorrigirFrequencia(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolUpdate(w, r, `UPDATE gestao_escolar.school_attendance SET
		estado=COALESCE(NULLIF($1::jsonb->>'estado',''),estado),
		observacoes=COALESCE($1::jsonb->>'observacoes',observacoes),updated_at=NOW()
		WHERE id=$2 AND tenant_id=$3`, body, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) ListarAvaliacoes(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "g.tenant_id=$1"
	args := []any{u.TenantID}
	appendSchoolFilter(&where, &args, "g.class_id", r.URL.Query().Get("class_id"))
	appendSchoolFilter(&where, &args, "g.subject_id", r.URL.Query().Get("subject_id"))
	appendSchoolFilter(&where, &args, "g.term_id", r.URL.Query().Get("term_id"))
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.data_avaliacao DESC),'[]') FROM (
		SELECT g.*,c.nome turma,s.nome disciplina,t.nome periodo FROM gestao_escolar.school_grade_items g
		JOIN gestao_escolar.school_classes c ON c.id=g.class_id JOIN gestao_escolar.school_subjects s ON s.id=g.subject_id
		JOIN gestao_escolar.school_terms t ON t.id=g.term_id WHERE `+where+`) x`, args...)
}

func (h *Handler) CriarAvaliacao(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolCreate(w, r, `INSERT INTO gestao_escolar.school_grade_items
		(tenant_id,class_id,subject_id,term_id,nome,tipo,data_avaliacao,nota_maxima,peso,created_by)
		SELECT $1,c.id,s.id,j.term_id,j.nome,COALESCE(j.tipo,'teste'),j.data_avaliacao,
		COALESCE(j.nota_maxima,20),COALESCE(j.peso,1),$3
		FROM jsonb_to_record($2::jsonb) AS j(class_id bigint,subject_id bigint,term_id bigint,nome text,
		tipo text,data_avaliacao date,nota_maxima numeric,peso numeric)
		JOIN gestao_escolar.school_classes c ON c.id=j.class_id AND c.tenant_id=$1
		JOIN gestao_escolar.school_subjects s ON s.id=j.subject_id AND s.tenant_id=$1
		JOIN gestao_escolar.school_terms t ON t.id=j.term_id AND t.tenant_id=$1
		WHERE j.nome<>'' RETURNING school_grade_items.id`, u.TenantID, body, u.ID)
}

func (h *Handler) LancarNotas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	var count int64
	err = h.db.QueryRow(r.Context(), `WITH input AS (
		SELECT ($2::jsonb->>'grade_item_id')::bigint item,$2::jsonb->'grades' grades
	), ins AS (
		INSERT INTO gestao_escolar.school_grades(tenant_id,grade_item_id,student_id,enrollment_id,nota,observacoes,lancado_por)
		SELECT $1,i.item,(x->>'student_id')::bigint,(x->>'enrollment_id')::bigint,(x->>'nota')::numeric,x->>'observacoes',$3
		FROM input i,jsonb_array_elements(i.grades) x
		JOIN gestao_escolar.school_grade_items gi ON gi.id=i.item AND gi.tenant_id=$1
		JOIN gestao_escolar.school_students s ON s.id=(x->>'student_id')::bigint AND s.tenant_id=$1
		WHERE (x->>'nota')::numeric BETWEEN 0 AND gi.nota_maxima
		ON CONFLICT(tenant_id,grade_item_id,student_id) DO UPDATE SET
		nota=EXCLUDED.nota,observacoes=EXCLUDED.observacoes,lancado_por=EXCLUDED.lancado_por,updated_at=NOW()
		RETURNING 1) SELECT COUNT(*) FROM ins`, u.TenantID, body, u.ID).Scan(&count)
	if err != nil || count == 0 {
		jsonErr(w, "Notas invalidas", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"registos": count}, http.StatusCreated)
}

func (h *Handler) CorrigirNota(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolUpdate(w, r, `UPDATE gestao_escolar.school_grades g SET
		nota=COALESCE(($1::jsonb->>'nota')::numeric,nota),observacoes=COALESCE($1::jsonb->>'observacoes',observacoes),
		lancado_por=$4,updated_at=NOW() FROM gestao_escolar.school_grade_items i
		WHERE g.id=$2 AND g.tenant_id=$3 AND i.id=g.grade_item_id
		AND COALESCE(($1::jsonb->>'nota')::numeric,g.nota) BETWEEN 0 AND i.nota_maxima`,
		body, chi.URLParam(r, "id"), u.TenantID, u.ID)
}

func (h *Handler) ObterBoletim(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	term := r.URL.Query().Get("term_id")
	if term == "" {
		term = "0"
	}
	h.schoolOne(w, r, `SELECT jsonb_build_object('student',to_jsonb(s),'term_id',$3::bigint,
		'disciplinas',COALESCE((SELECT jsonb_agg(to_jsonb(x) ORDER BY x.disciplina) FROM (
		SELECT sub.id subject_id,sub.nome disciplina,ROUND(SUM(g.nota*i.peso)/NULLIF(SUM(i.peso),0),2) media,
		COUNT(g.id) avaliacoes,BOOL_AND(g.nota>=sub.nota_minima) aprovado
		FROM gestao_escolar.school_grades g JOIN gestao_escolar.school_grade_items i ON i.id=g.grade_item_id
		JOIN gestao_escolar.school_subjects sub ON sub.id=i.subject_id
		WHERE g.student_id=s.id AND i.term_id=$3 GROUP BY sub.id) x),'[]'))
		FROM gestao_escolar.school_students s WHERE s.id=$1 AND s.tenant_id=$2`,
		chi.URLParam(r, "student_id"), u.TenantID, term)
}

var _ = strconv.Itoa
