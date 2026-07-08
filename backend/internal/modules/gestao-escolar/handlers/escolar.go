package handlers

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/shared/contracts"
)

func schoolBody(r *http.Request) ([]byte, error) {
	raw, err := io.ReadAll(io.LimitReader(r.Body, 2<<20))
	if err != nil {
		return nil, err
	}
	if len(raw) == 0 || !json.Valid(raw) {
		return nil, errors.New("invalid JSON")
	}
	var object map[string]any
	if json.Unmarshal(raw, &object) != nil {
		return nil, io.ErrUnexpectedEOF
	}
	return raw, nil
}

func (h *Handler) schoolList(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	var raw []byte
	if err := h.db.QueryRow(r.Context(), query, args...).Scan(&raw); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func (h *Handler) schoolOne(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	var raw []byte
	err := h.db.QueryRow(r.Context(), query, args...).Scan(&raw)
	if err == pgx.ErrNoRows {
		jsonErr(w, "Registo nao encontrado", http.StatusNotFound)
		return
	}
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(raw)
}

func (h *Handler) schoolCreate(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	var id int64
	if err := h.db.QueryRow(r.Context(), query, args...).Scan(&id); err != nil {
		jsonErr(w, "Dados invalidos ou registo duplicado", http.StatusUnprocessableEntity)
		return
	}
	jsonOK(w, map[string]any{"id": id}, http.StatusCreated)
}

func (h *Handler) schoolUpdate(w http.ResponseWriter, r *http.Request, query string, args ...any) {
	tag, err := h.db.Exec(r.Context(), query, args...)
	if err != nil {
		jsonErr(w, "Dados invalidos", http.StatusUnprocessableEntity)
		return
	}
	if tag.RowsAffected() == 0 {
		jsonErr(w, "Registo nao encontrado", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func appendSchoolFilter(where *string, args *[]any, column, value string) {
	if value == "" {
		return
	}
	*args = append(*args, value)
	*where += " AND " + column + "=$" + strconv.Itoa(len(*args))
}

// Anos lectivos e periodos.
func (h *Handler) ListarPeriodosLectivos(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	yearID  := r.URL.Query().Get("year_id")
	levelID := r.URL.Query().Get("level_id")
	where := "t.tenant_id=$1"
	args := []any{u.TenantID}
	if yearID != "" {
		args = append(args, yearID)
		where += fmt.Sprintf(" AND t.school_year_id=$%d", len(args))
	}
	if levelID != "" {
		args = append(args, levelID)
		where += fmt.Sprintf(" AND t.level_id=$%d", len(args))
	}
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(jsonb_build_object(
		'id',t.id,'nome',t.nome,'tipo',t.tipo,'codigo',t.codigo,
		'data_inicio',t.data_inicio,'data_fim',t.data_fim,'peso',t.peso,'ordem',t.ordem,
		'school_year_id',t.school_year_id,'ano_nome',y.nome,
		'level_id',t.level_id,'level_nome',sl.nome
	) ORDER BY t.school_year_id,sl.nome,t.ordem),'[]')
	FROM gestao_escolar.school_terms t
	JOIN gestao_escolar.school_years y ON y.id=t.school_year_id
	JOIN gestao_escolar.school_levels sl ON sl.id=t.level_id
	WHERE `+where, args...)
}

func (h *Handler) ListarAnosLectivos(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.data_inicio DESC),'[]')
		FROM (SELECT y.*,(SELECT COUNT(*) FROM gestao_escolar.school_terms t WHERE t.school_year_id=y.id) periodos
		FROM gestao_escolar.school_years y WHERE tenant_id=$1) x`, u.TenantID)
}

func (h *Handler) CriarAnoLectivo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	h.schoolCreate(w, r, `INSERT INTO gestao_escolar.school_years(tenant_id,codigo,nome,data_inicio,data_fim)
		SELECT $1,j.codigo,j.nome,j.data_inicio,j.data_fim FROM jsonb_to_record($2::jsonb)
		AS j(codigo text,nome text,data_inicio date,data_fim date)
		WHERE j.codigo<>'' AND j.nome<>'' RETURNING id`, u.TenantID, body)
}

func (h *Handler) ObterAnoLectivo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolOne(w, r, `SELECT to_jsonb(y)||jsonb_build_object('periodos',
		COALESCE((SELECT jsonb_agg(to_jsonb(t) ORDER BY t.data_inicio) FROM gestao_escolar.school_terms t WHERE t.school_year_id=y.id),'[]'))
		FROM gestao_escolar.school_years y WHERE y.id=$1 AND y.tenant_id=$2`, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) ActualizarAnoLectivo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolUpdate(w, r, `UPDATE gestao_escolar.school_years SET
		codigo=COALESCE(NULLIF($1::jsonb->>'codigo',''),codigo),
		nome=COALESCE(NULLIF($1::jsonb->>'nome',''),nome),
		data_inicio=COALESCE(($1::jsonb->>'data_inicio')::date,data_inicio),
		data_fim=COALESCE(($1::jsonb->>'data_fim')::date,data_fim),updated_at=NOW()
		WHERE id=$2 AND tenant_id=$3`, body, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) ActivarAnoLectivo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	tx, _ := h.db.Begin(r.Context())
	defer tx.Rollback(r.Context())
	_, _ = tx.Exec(r.Context(), `UPDATE gestao_escolar.school_years SET status='rascunho',updated_at=NOW()
		WHERE tenant_id=$1 AND status='activo'`, u.TenantID)
	tag, err := tx.Exec(r.Context(), `UPDATE gestao_escolar.school_years SET status='activo',updated_at=NOW()
		WHERE id=$1 AND tenant_id=$2 AND status<>'encerrado'`, chi.URLParam(r, "id"), u.TenantID)
	if err != nil || tag.RowsAffected() == 0 || tx.Commit(r.Context()) != nil {
		jsonErr(w, "Ano lectivo nao encontrado ou encerrado", http.StatusConflict)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) EncerrarAnoLectivo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolUpdate(w, r, `UPDATE gestao_escolar.school_years SET status='encerrado',updated_at=NOW()
		WHERE id=$1 AND tenant_id=$2 AND status<>'encerrado'`, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) CriarPeriodoLectivo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	if body == nil || string(body) == "null" || !json.Valid(body) {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	var bmap map[string]any
	_ = json.Unmarshal(body, &bmap)
	if _, ok := bmap["level_id"]; !ok || bmap["level_id"] == nil || bmap["level_id"] == "" {
		jsonErr(w, "level_id obrigatório: cada período pertence a um nível de ensino", 422)
		return
	}
	h.schoolCreate(w, r, `INSERT INTO gestao_escolar.school_terms(tenant_id,school_year_id,codigo,nome,tipo,data_inicio,data_fim,peso,ordem,level_id)
		SELECT $1,y.id,j.codigo,j.nome,COALESCE(NULLIF(j.tipo,''),'trimestre'),j.data_inicio,j.data_fim,COALESCE(j.peso,1),
		       COALESCE(j.ordem,(SELECT COALESCE(MAX(t2.ordem),0)+1 FROM gestao_escolar.school_terms t2 WHERE t2.school_year_id=y.id)),
		       ($3::jsonb->>'level_id')::bigint
		FROM gestao_escolar.school_years y,jsonb_to_record($3::jsonb)
		AS j(codigo text,nome text,tipo text,data_inicio date,data_fim date,peso numeric,ordem int)
		WHERE y.id=$2 AND y.tenant_id=$1 AND j.codigo<>'' RETURNING school_terms.id`,
		u.TenantID, chi.URLParam(r, "id"), body)
}

func (h *Handler) ActualizarPeriodoLectivo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolUpdate(w, r, `UPDATE gestao_escolar.school_terms SET
		nome       = COALESCE(NULLIF($1::jsonb->>'nome',''), nome),
		tipo       = COALESCE(NULLIF($1::jsonb->>'tipo',''), tipo),
		codigo     = COALESCE(NULLIF($1::jsonb->>'codigo',''), codigo),
		data_inicio= COALESCE(($1::jsonb->>'data_inicio')::date, data_inicio),
		data_fim   = COALESCE(($1::jsonb->>'data_fim')::date, data_fim),
		peso       = COALESCE(($1::jsonb->>'peso')::numeric, peso),
		ordem      = COALESCE(($1::jsonb->>'ordem')::int, ordem),
		level_id   = CASE WHEN $1::jsonb ? 'level_id' AND ($1::jsonb->>'level_id') <> '' THEN ($1::jsonb->>'level_id')::bigint ELSE level_id END
		WHERE id=$2 AND tenant_id=$3`, body, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) EliminarPeriodoLectivo(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")
	var hasGrades bool
	_ = h.db.QueryRow(r.Context(),
		`SELECT EXISTS(SELECT 1 FROM gestao_escolar.school_grade_items gi WHERE gi.term_id=$1 AND gi.tenant_id=$2)`,
		id, u.TenantID).Scan(&hasGrades)
	if hasGrades {
		jsonErr(w, "Não é possível eliminar um período com avaliações lançadas", 409)
		return
	}
	tag, err := h.db.Exec(r.Context(),
		`DELETE FROM gestao_escolar.school_terms WHERE id=$1 AND tenant_id=$2`, id, u.TenantID)
	if err != nil || tag.RowsAffected() == 0 {
		jsonErr(w, "Período não encontrado", 404)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// Turmas, disciplinas e atribuicoes.
func (h *Handler) ListarTurmas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	q := r.URL.Query()
	where := "c.tenant_id=$1"
	args := []any{u.TenantID}
	appendSchoolFilter(&where, &args, "c.school_year_id", q.Get("year_id"))
	appendSchoolFilter(&where, &args, "c.activo", q.Get("activo"))
	appendSchoolFilter(&where, &args, "c.turno", q.Get("turno"))
	appendSchoolFilter(&where, &args, "c.level_id", q.Get("level_id"))

	porPagina := 25
	if pp, err := strconv.Atoi(q.Get("por_pagina")); err == nil && pp > 0 && pp <= 200 {
		porPagina = pp
	}
	pagina := 1
	if pg, err := strconv.Atoi(q.Get("pagina")); err == nil && pg > 0 {
		pagina = pg
	}
	offset := (pagina - 1) * porPagina

	var total int
	_ = h.db.QueryRow(r.Context(),
		`SELECT COUNT(*) FROM gestao_escolar.school_classes c WHERE `+where, args...).Scan(&total)

	dataArgs := append(append([]any{}, args...), porPagina, offset)
	ppIdx := strconv.Itoa(len(dataArgs) - 1)
	offIdx := strconv.Itoa(len(dataArgs))

	var raw []byte
	if err := h.db.QueryRow(r.Context(), `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome),'[]') FROM (
		SELECT c.*,y.nome ano_lectivo_nome,(SELECT COUNT(*) FROM gestao_escolar.school_enrollments e
		WHERE e.class_id=c.id AND e.status='activa') alunos FROM gestao_escolar.school_classes c
		LEFT JOIN gestao_escolar.school_years y ON y.id=c.school_year_id WHERE `+where+
		` LIMIT $`+ppIdx+` OFFSET $`+offIdx+`) x`, dataArgs...).Scan(&raw); err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	paginas := (total + porPagina - 1) / porPagina
	if paginas < 1 {
		paginas = 1
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"data":       json.RawMessage(raw),
		"total":      total,
		"pagina":     pagina,
		"por_pagina": porPagina,
		"paginas":    paginas,
	})
}

func (h *Handler) ObterTurma(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolOne(w, r, `SELECT to_jsonb(c)||jsonb_build_object(
		'alunos',COALESCE((SELECT jsonb_agg(jsonb_build_object('enrollment_id',e.id,'student_id',s.id,'codigo',s.codigo,'nome',s.nome))
		FROM gestao_escolar.school_enrollments e JOIN gestao_escolar.school_students s ON s.id=e.student_id
		WHERE e.class_id=c.id AND e.status='activa'),'[]'),
		'professores',COALESCE((SELECT jsonb_agg(to_jsonb(a)||jsonb_build_object('disciplina',d.nome))
		FROM gestao_escolar.school_teacher_assignments a JOIN gestao_escolar.school_subjects d ON d.id=a.subject_id
		WHERE a.class_id=c.id AND a.activo),'[]'))
		FROM gestao_escolar.school_classes c WHERE c.id=$1 AND c.tenant_id=$2`, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) AssociarProfessorDirector(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolUpdate(w, r, `UPDATE gestao_escolar.school_classes SET
		director_teacher_id=($1::jsonb->>'teacher_id')::bigint,updated_at=NOW()
		WHERE id=$2 AND tenant_id=$3 AND ($1::jsonb->>'teacher_id')::bigint>0`,
		body, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) ListarDisciplinas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(s) ORDER BY s.nome),'[]')
		FROM gestao_escolar.school_subjects s WHERE tenant_id=$1`, u.TenantID)
}

func (h *Handler) CriarDisciplina(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolCreate(w, r, `INSERT INTO gestao_escolar.school_subjects
		(tenant_id,codigo,nome,descricao,carga_horaria,nota_minima)
		SELECT $1,j.codigo,j.nome,j.descricao,j.carga_horaria,COALESCE(j.nota_minima,10)
		FROM jsonb_to_record($2::jsonb) AS j(codigo text,nome text,descricao text,carga_horaria int,nota_minima numeric)
		WHERE j.codigo<>'' AND j.nome<>'' RETURNING id`, u.TenantID, body)
}

func (h *Handler) ObterDisciplina(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolOne(w, r, `SELECT to_jsonb(s) FROM gestao_escolar.school_subjects s
		WHERE s.id=$1 AND s.tenant_id=$2`, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) ActualizarDisciplina(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolUpdate(w, r, `UPDATE gestao_escolar.school_subjects SET
		codigo=COALESCE(NULLIF($1::jsonb->>'codigo',''),codigo),
		nome=COALESCE(NULLIF($1::jsonb->>'nome',''),nome),
		descricao=COALESCE($1::jsonb->>'descricao',descricao),
		carga_horaria=COALESCE(($1::jsonb->>'carga_horaria')::int,carga_horaria),
		nota_minima=COALESCE(($1::jsonb->>'nota_minima')::numeric,nota_minima),
		activo=COALESCE(($1::jsonb->>'activo')::boolean,activo),
		updated_at=NOW()
		WHERE id=$2 AND tenant_id=$3`, body, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) RemoverDisciplina(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolUpdate(w, r, `DELETE FROM gestao_escolar.school_subjects WHERE id=$1 AND tenant_id=$2`,
		chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) AtribuirProfessor(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolCreate(w, r, `INSERT INTO gestao_escolar.school_teacher_assignments
		(tenant_id,school_year_id,class_id,subject_id,teacher_id,data_inicio,data_fim)
		SELECT $1,j.year_id,c.id,s.id,j.teacher_id,COALESCE(j.data_inicio,CURRENT_DATE),j.data_fim
		FROM jsonb_to_record($2::jsonb) AS j(year_id bigint,class_id bigint,subject_id bigint,teacher_id bigint,data_inicio date,data_fim date)
		JOIN gestao_escolar.school_classes c ON c.id=j.class_id AND c.tenant_id=$1
		JOIN gestao_escolar.school_subjects s ON s.id=j.subject_id AND s.tenant_id=$1
		WHERE j.teacher_id>0 RETURNING school_teacher_assignments.id`, u.TenantID, body)
}

// Alunos, encarregados e matriculas.
func (h *Handler) ListarAlunos(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "s.tenant_id=$1"
	args := []any{u.TenantID}
	appendSchoolFilter(&where, &args, "s.estado", r.URL.Query().Get("status"))
	if search := strings.TrimSpace(r.URL.Query().Get("search")); search != "" {
		args = append(args, "%"+search+"%")
		n := strconv.Itoa(len(args))
		where += " AND (s.nome ILIKE $" + n + " OR s.codigo ILIKE $" + n + " OR s.documento_numero ILIKE $" + n + ")"
	}
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.nome),'[]') FROM (
		SELECT s.*,e.id enrollment_id,e.class_id,c.nome turma_nome FROM gestao_escolar.school_students s
		LEFT JOIN gestao_escolar.school_enrollments e ON e.student_id=s.id AND e.status='activa'
		LEFT JOIN gestao_escolar.school_classes c ON c.id=e.class_id WHERE `+where+`) x`, args...)
}

func (h *Handler) CriarAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolCreate(w, r, `INSERT INTO gestao_escolar.school_students
		(tenant_id,codigo,nome,data_nascimento,genero,documento_tipo,documento_numero,nuit,telefone,email,endereco,fotografia_url)
		SELECT $1,j.codigo,j.nome,j.data_nascimento,j.genero,j.documento_tipo,j.documento_numero,j.nuit,j.telefone,j.email,j.endereco,j.fotografia_url
		FROM jsonb_to_record($2::jsonb) AS j(codigo text,nome text,data_nascimento date,genero text,
		documento_tipo text,documento_numero text,nuit text,telefone text,email text,endereco text,fotografia_url text)
		WHERE j.codigo<>'' AND j.nome<>'' RETURNING id`, u.TenantID, body)
}

func (h *Handler) ObterAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolOne(w, r, `SELECT to_jsonb(s)||jsonb_build_object(
		'encarregados',COALESCE((SELECT jsonb_agg(to_jsonb(g) ORDER BY g.principal DESC) FROM gestao_escolar.school_guardians g WHERE g.student_id=s.id),'[]'),
		'matriculas',COALESCE((SELECT jsonb_agg(to_jsonb(e)||jsonb_build_object('turma',c.nome) ORDER BY e.created_at DESC)
		FROM gestao_escolar.school_enrollments e JOIN gestao_escolar.school_classes c ON c.id=e.class_id WHERE e.student_id=s.id),'[]'))
		FROM gestao_escolar.school_students s WHERE s.id=$1 AND s.tenant_id=$2`, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) ActualizarAluno(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}
	h.schoolUpdate(w, r, `UPDATE gestao_escolar.school_students SET
		nome=COALESCE(NULLIF($1::jsonb->>'nome',''),nome),data_nascimento=COALESCE(($1::jsonb->>'data_nascimento')::date,data_nascimento),
		genero=COALESCE($1::jsonb->>'genero',genero),documento_tipo=COALESCE($1::jsonb->>'documento_tipo',documento_tipo),
		documento_numero=COALESCE($1::jsonb->>'documento_numero',documento_numero),nuit=COALESCE($1::jsonb->>'nuit',nuit),
		telefone=COALESCE($1::jsonb->>'telefone',telefone),email=COALESCE($1::jsonb->>'email',email),
		endereco=COALESCE($1::jsonb->>'endereco',endereco),estado=COALESCE($1::jsonb->>'estado',estado),updated_at=NOW()
		WHERE id=$2 AND tenant_id=$3`, body, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) AdicionarEncarregado(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON invalido", 400)
		return
	}

	var guardianID int64
	if err := h.db.QueryRow(r.Context(), `INSERT INTO gestao_escolar.school_guardians
		(tenant_id,student_id,nome,parentesco,telefone,email,nuit,endereco,principal,autorizado_recolher)
		SELECT $1,s.id,j.nome,j.parentesco,j.telefone,j.email,j.nuit,j.endereco,COALESCE(j.principal,false),COALESCE(j.autorizado_recolher,true)
		FROM gestao_escolar.school_students s,jsonb_to_record($3::jsonb)
		AS j(nome text,parentesco text,telefone text,email text,nuit text,endereco text,principal bool,autorizado_recolher bool)
		WHERE s.id=$2 AND s.tenant_id=$1 AND j.nome<>'' AND j.telefone<>'' RETURNING school_guardians.id`,
		u.TenantID, chi.URLParam(r, "id"), body,
	).Scan(&guardianID); err != nil {
		jsonErr(w, "Dados invalidos ou registo duplicado", http.StatusUnprocessableEntity)
		return
	}

	// Registar encarregado como cliente no módulo Gestão de Clientes (assíncrono)
	if h.client != nil {
		tenantID := u.TenantID
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
			defer cancel()

			var nome, email, telefone, nuit string
			_ = h.db.QueryRow(ctx, `
				SELECT nome, COALESCE(email,''), COALESCE(telefone,''), COALESCE(nuit,'')
				FROM gestao_escolar.school_guardians WHERE id=$1`, guardianID,
			).Scan(&nome, &email, &telefone, &nuit)

			if nome == "" {
				return
			}
			clientID, err := h.client.CreateClient(ctx, contracts.ClientData{
				TenantID: tenantID,
				Nome:     nome,
				Email:    email,
				Telefone: telefone,
				Nuit:     nuit,
				Tipo:     "encarregado",
			})
			if err != nil || clientID == 0 {
				return
			}
			_, _ = h.db.Exec(ctx, `
				UPDATE gestao_escolar.school_guardians
				SET client_id = $1 WHERE id = $2`, clientID, guardianID)
		}()
	}

	jsonOK(w, map[string]any{"id": guardianID}, http.StatusCreated)
}

func (h *Handler) ObterMatricula(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolOne(w, r, `SELECT to_jsonb(e)||jsonb_build_object('aluno',to_jsonb(s),'turma',to_jsonb(c),'ano_lectivo',to_jsonb(y))
		FROM gestao_escolar.school_enrollments e JOIN gestao_escolar.school_students s ON s.id=e.student_id
		JOIN gestao_escolar.school_classes c ON c.id=e.class_id
		LEFT JOIN gestao_escolar.school_years y ON y.id=e.school_year_id
		WHERE e.id=$1 AND e.tenant_id=$2`, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) ListarMatriculas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "e.tenant_id=$1"
	args := []any{u.TenantID}
	appendSchoolFilter(&where, &args, "e.class_id", r.URL.Query().Get("class_id"))
	appendSchoolFilter(&where, &args, "e.student_id", r.URL.Query().Get("student_id"))
	appendSchoolFilter(&where, &args, "e.status", r.URL.Query().Get("status"))
	appendSchoolFilter(&where, &args, "e.school_year_id", r.URL.Query().Get("year_id"))
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.created_at DESC),'[]') FROM (
		SELECT e.*,s.nome aluno,c.nome turma FROM gestao_escolar.school_enrollments e
		JOIN gestao_escolar.school_students s ON s.id=e.student_id
		JOIN gestao_escolar.school_classes c ON c.id=e.class_id WHERE `+where+`) x`, args...)
}


