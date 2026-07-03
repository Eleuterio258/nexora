package handlers

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	mw "nexora/internal/middleware"
	"nexora/internal/modules/gestao-escolar/models"
	"nexora/internal/modules/gestao-escolar/services"
	"nexora/internal/shared/contracts"
)

func (h *Handler) gradeService() *services.GradeService {
	return services.NewGradeService(h.gradeRepo)
}

func (h *Handler) ListarAvaliacoesV2(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	q := r.URL.Query()
	classID, _ := strconv.ParseInt(q.Get("class_id"), 10, 64)
	subjectID, _ := strconv.ParseInt(q.Get("subject_id"), 10, 64)
	termID, _ := strconv.ParseInt(q.Get("term_id"), 10, 64)

	items, err := h.gradeService().ListItems(r.Context(), u.TenantID, classID, subjectID, termID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, items, http.StatusOK)
}

func (h *Handler) CriarAvaliacaoV2(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var input models.GradeItem
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	input.CreatedBy = &u.ID
	if err := h.gradeService().CreateItem(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrGradeInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, input, http.StatusCreated)
}

func (h *Handler) PublicarAvaliacao(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	var body struct {
		Publicado bool `json:"publicado"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	if err := h.gradeService().PublishItem(r.Context(), id, u.TenantID, body.Publicado); err != nil {
		if errors.Is(err, services.ErrGradeNotFound) {
			jsonErr(w, err.Error(), http.StatusNotFound)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}

	// Notificar alunos da turma quando avaliação é publicada
	if body.Publicado {
		tenantID, gradeItemID := u.TenantID, id
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
			defer cancel()

			var classID int64
			var disciplina, turma string
			_ = h.db.QueryRow(ctx, `
				SELECT g.class_id, COALESCE(s.nome,''), COALESCE(c.nome,'')
				FROM gestao_escolar.school_grade_items g
				LEFT JOIN gestao_escolar.school_subjects s ON s.id = g.subject_id
				LEFT JOIN gestao_escolar.school_classes c ON c.id = g.class_id
				WHERE g.id = $1 AND g.tenant_id = $2`, gradeItemID, tenantID,
			).Scan(&classID, &disciplina, &turma)

			if classID == 0 {
				return
			}

			// Notificar alunos e encarregados principais da turma
			rows, err := h.db.Query(ctx, `
				SELECT COALESCE(NULLIF(st.portal_email,''), u.email) email_aluno,
				       st.id student_id,
				       COALESCE(g.portal_email, '') email_enc
				  FROM gestao_escolar.school_enrollments e
				  JOIN gestao_escolar.school_students st ON st.id = e.student_id
				  LEFT JOIN auth.users u ON u.id = st.user_id
				  LEFT JOIN gestao_escolar.school_guardians g
				         ON g.student_id = st.id AND g.principal = true AND g.portal_ativo = true
				 WHERE e.class_id = $1 AND e.tenant_id = $2 AND e.status = 'activa'
				   AND COALESCE(NULLIF(st.portal_email,''), u.email) IS NOT NULL`,
				classID, tenantID)
			if err != nil {
				return
			}
			defer rows.Close()
			for rows.Next() {
				var emailAluno, emailEnc string
				var studentID int64
				if rows.Scan(&emailAluno, &studentID, &emailEnc) != nil || h.notification == nil {
					continue
				}
				sid := studentID
				corpo := fmt.Sprintf("As notas de %s foram publicadas para a turma %s. Aceda ao portal para consultar o boletim.", disciplina, turma)

				if emailAluno != "" {
					h.notification.Send(ctx, contracts.Notification{
						TenantID: tenantID, CanalTipo: "email", Destinatario: emailAluno,
						Assunto: fmt.Sprintf("Notas publicadas: %s", disciplina),
						Corpo:   corpo, ReferenciaTipo: "escolar.notas", ReferenciaID: &sid,
					})
				}
				if emailEnc != "" && emailEnc != emailAluno {
					h.notification.Send(ctx, contracts.Notification{
						TenantID: tenantID, CanalTipo: "email", Destinatario: emailEnc,
						Assunto: fmt.Sprintf("Notas do seu educando publicadas: %s", disciplina),
						Corpo:   "Encarregado, " + corpo, ReferenciaTipo: "escolar.notas", ReferenciaID: &sid,
					})
				}
			}
		}()
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) LancarNotasV2(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	var body struct {
		GradeItemID int64          `json:"grade_item_id"`
		Grades      []models.Grade `json:"grades"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}

	var count int
	for _, g := range body.Grades {
		g.TenantID = u.TenantID
		g.GradeItemID = body.GradeItemID
		g.LancadoPor = &u.ID
		if err := h.gradeService().UpsertGrade(r.Context(), &g); err != nil {
			if errors.Is(err, services.ErrGradeInvalidData) || errors.Is(err, services.ErrGradeOutOfRange) {
				jsonErr(w, err.Error(), http.StatusBadRequest)
				return
			}
			jsonErr(w, "Erro interno", http.StatusInternalServerError)
			return
		}
		count++
	}

	jsonOK(w, map[string]any{"registos": count}, http.StatusCreated)
}

func (h *Handler) CorrigirNotaV2(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	var input models.Grade
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		jsonErr(w, "JSON invalido", http.StatusBadRequest)
		return
	}
	input.TenantID = u.TenantID
	input.ID = id
	input.LancadoPor = &u.ID
	if err := h.gradeService().UpsertGrade(r.Context(), &input); err != nil {
		if errors.Is(err, services.ErrGradeOutOfRange) || errors.Is(err, services.ErrGradeInvalidData) {
			jsonErr(w, err.Error(), http.StatusBadRequest)
			return
		}
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListarNotas(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	where := "g.tenant_id=$1"
	args := []any{u.TenantID}
	appendSchoolFilter(&where, &args, "g.grade_item_id", r.URL.Query().Get("grade_item_id"))
	appendSchoolFilter(&where, &args, "g.student_id", r.URL.Query().Get("student_id"))
	h.schoolList(w, r, `SELECT COALESCE(jsonb_agg(to_jsonb(x) ORDER BY x.aluno),'[]') FROM (
		SELECT g.*,s.nome aluno,gi.nome avaliacao FROM gestao_escolar.school_grades g
		JOIN gestao_escolar.school_students s ON s.id=g.student_id
		JOIN gestao_escolar.school_grade_items gi ON gi.id=g.grade_item_id WHERE `+where+`) x`, args...)
}

func (h *Handler) ObterNota(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	h.schoolOne(w, r, `SELECT to_jsonb(x) FROM (
		SELECT g.*,s.nome aluno,gi.nome avaliacao FROM gestao_escolar.school_grades g
		JOIN gestao_escolar.school_students s ON s.id=g.student_id
		JOIN gestao_escolar.school_grade_items gi ON gi.id=g.grade_item_id
		WHERE g.id=$1 AND g.tenant_id=$2) x`, chi.URLParam(r, "id"), u.TenantID)
}

func (h *Handler) ObterBoletimV2(w http.ResponseWriter, r *http.Request) {
	u := mw.GetUser(r)
	studentID, err := strconv.ParseInt(chi.URLParam(r, "student_id"), 10, 64)
	if err != nil {
		jsonErr(w, "ID invalido", http.StatusBadRequest)
		return
	}
	termID, _ := strconv.ParseInt(r.URL.Query().Get("term_id"), 10, 64)

	report, err := h.gradeService().StudentReport(r.Context(), studentID, termID, u.TenantID)
	if err != nil {
		jsonErr(w, "Erro interno", http.StatusInternalServerError)
		return
	}
	jsonOK(w, report, http.StatusOK)
}
