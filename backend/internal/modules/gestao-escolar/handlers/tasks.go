package handlers

import (
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
)

// ── GET /api/escolar/tasks ───────────────────────────────────────────────────
// Lista tarefas escolares criadas por professores. Permite filtrar por professor,
// turma, disciplina e status.

func (h *Handler) ListarTarefasEscolares(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)

	where := "t.tenant_id=$1"
	args := []any{u.TenantID}

	if v := r.URL.Query().Get("teacher_id"); v != "" {
		args = append(args, v)
		where += " AND t.teacher_id=$" + strconv.Itoa(len(args))
	}
	if v := r.URL.Query().Get("class_id"); v != "" {
		args = append(args, v)
		where += " AND t.class_id=$" + strconv.Itoa(len(args))
	}
	if v := r.URL.Query().Get("subject_id"); v != "" {
		args = append(args, v)
		where += " AND t.subject_id=$" + strconv.Itoa(len(args))
	}
	if v := r.URL.Query().Get("status"); v != "" {
		args = append(args, v)
		where += " AND t.status=$" + strconv.Itoa(len(args))
	}

	page, _ := strconv.ParseInt(r.URL.Query().Get("page"), 10, 64)
	limit, _ := strconv.ParseInt(r.URL.Query().Get("limit"), 10, 64)
	if limit <= 0 || limit > 100 {
		limit = 30
	}
	if page <= 0 {
		page = 1
	}
	offset := (page - 1) * limit

	var total int64
	_ = h.db.QueryRow(r.Context(),
		"SELECT COUNT(*) FROM gestao_escolar.school_tasks t WHERE "+where, args...,
	).Scan(&total)

	paginatedArgs := append(args, limit, offset)
	var tarefas any
	_ = h.db.QueryRow(r.Context(), `
		SELECT COALESCE(jsonb_agg(
			to_jsonb(t) || jsonb_build_object(
				'professor', COALESCE(te.nome_completo, ''),
				'turma', COALESCE(c.nome, ''),
				'disciplina', COALESCE(s.nome, '')
			) ORDER BY t.data_fim ASC, t.created_at DESC
		), '[]')
		FROM gestao_escolar.school_tasks t
		LEFT JOIN gestao_escolar.school_teachers te ON te.id=t.teacher_id
		LEFT JOIN gestao_escolar.school_classes c ON c.id=t.class_id
		LEFT JOIN gestao_escolar.school_subjects s ON s.id=t.subject_id
		WHERE `+where+` LIMIT $`+strconv.Itoa(len(paginatedArgs)-1)+` OFFSET $`+strconv.Itoa(len(paginatedArgs)),
		paginatedArgs...,
	).Scan(&tarefas)

	jsonOK(w, map[string]any{
		"tarefas":    tarefas,
		"total":      total,
		"pagina":     page,
		"por_pagina": limit,
		"paginas":    (total + limit - 1) / limit,
	}, http.StatusOK)
}

// ── GET /api/escolar/tasks/{id} ──────────────────────────────────────────────
// Devolve os detalhes de uma tarefa escolar.

func (h *Handler) ObterTarefaEscolar(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id := chi.URLParam(r, "id")

	var tarefa any
	err := h.db.QueryRow(r.Context(), `
		SELECT to_jsonb(t) || jsonb_build_object(
			'professor', COALESCE(te.nome_completo, ''),
			'turma', COALESCE(c.nome, ''),
			'disciplina', COALESCE(s.nome, '')
		)
		FROM gestao_escolar.school_tasks t
		LEFT JOIN gestao_escolar.school_teachers te ON te.id=t.teacher_id
		LEFT JOIN gestao_escolar.school_classes c ON c.id=t.class_id
		LEFT JOIN gestao_escolar.school_subjects s ON s.id=t.subject_id
		WHERE t.id=$1 AND t.tenant_id=$2`, id, u.TenantID,
	).Scan(&tarefa)
	if err != nil {
		jsonErr(w, "Tarefa não encontrada", http.StatusNotFound)
		return
	}
	jsonOK(w, tarefa, http.StatusOK)
}

// ── POST /api/escolar/tasks ──────────────────────────────────────────────────
// Cria uma nova tarefa escolar associada a uma turma e disciplina.

func (h *Handler) CriarTarefaEscolar(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	body, err := schoolBody(r)
	if err != nil {
		jsonErr(w, "JSON inválido", http.StatusBadRequest)
		return
	}

	h.schoolCreate(w, r, `
		INSERT INTO gestao_escolar.school_tasks
			(tenant_id, school_year_id, class_id, subject_id, teacher_id,
			 titulo, descricao, tipo, data_inicio, data_fim, status, created_by)
		SELECT $1,
			   c.school_year_id,
			   j.class_id,
			   j.subject_id,
			   COALESCE(j.teacher_id, $3),
			   j.titulo,
			   j.descricao,
			   COALESCE(j.tipo,'tarefa'),
			   COALESCE(j.data_inicio::date, CURRENT_DATE),
			   j.data_fim::date,
			   COALESCE(j.status,'activa'),
			   $2
		FROM jsonb_to_record($4::jsonb) AS j(
			class_id bigint,
			subject_id bigint,
			teacher_id bigint,
			titulo text,
			descricao text,
			tipo text,
			data_inicio text,
			data_fim text,
			status text
		)
		JOIN gestao_escolar.school_classes c ON c.id=j.class_id
		WHERE j.class_id IS NOT NULL
		  AND j.titulo <> ''
		  AND j.data_fim IS NOT NULL
		RETURNING id`,
		u.TenantID, u.ID, u.ID, body)
}
